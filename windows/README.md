# Windows — sing-box как Windows Service

Установка sing-box на Windows 10/11 с TUN-режимом (весь системный трафик через VPN) и split-tunneling (РФ-сервисы direct, зарубежные — через VPN).

## Результат после установки

- sing-box работает как **Windows Service** (автозапуск при старте компа, до логина)
- Виртуальный TUN-интерфейс `singbox1` перехватывает весь трафик
- Переменная `HTTPS_PROXY` прописана для Claude Code / CLI-инструментов
- В браузере, Telegram, Discord, Steam, играх — всё работает без доп. настроек
- Автоматический рестарт если что-то упадёт

## Что потребуется

1. **Windows 10 или 11** (Home/Pro — обе подходят)
2. **Права администратора** — `sing-box` использует TUN-драйвер, Windows пускает только от админа. При работе службы права дадутся автоматически (служба стартует от `LocalSystem`), но **при установке** PowerShell должен быть запущен «от имени администратора» (Win+X → «Terminal (Administrator)»)
3. **VPS с 3x-ui** уже поднят (если нет — [AndyShaman/3x-ui-skill](https://github.com/AndyShaman/3x-ui-skill))
4. **VLESS-ссылка** из 3x-ui панели — строка вида `vless://UUID@IP:443?security=reality&...`

## Быстрый способ — один скрипт

Открой PowerShell **от администратора** и выполни:

```powershell
iwr -useb https://raw.githubusercontent.com/DevKitRU/my-vpn-kit/main/windows/install.ps1 | iex
```

Скрипт:
1. Спросит VLESS-ссылку (вставь из буфера — Ctrl+V)
2. Скачает sing-box и WinSW в `C:\ProgramData\sing-box\`
3. Сгенерирует конфиг с твоей VLESS и шаблоном РФ-маршрутизации
4. Установит и запустит Windows Service
5. Пропишет `HTTPS_PROXY=http://127.0.0.1:1080` для новых процессов
6. Проверит — TUN поднят, интернет через VPN

1-2 минуты, всё автоматически.

## Если не доверяешь `iwr | iex` — ручная установка

### Шаг 1. Скачать sing-box и WinSW

```powershell
mkdir C:\ProgramData\sing-box
cd C:\ProgramData\sing-box

# sing-box
iwr -useb https://github.com/SagerNet/sing-box/releases/download/v1.13.8/sing-box-1.13.8-windows-amd64.zip -OutFile singbox.zip
Expand-Archive singbox.zip -DestinationPath .
Move-Item .\sing-box-1.13.8-windows-amd64\sing-box.exe .
Remove-Item -Recurse .\sing-box-1.13.8-windows-amd64, singbox.zip

# WinSW (для запуска как Windows Service)
iwr -useb https://github.com/winsw/winsw/releases/download/v2.12.0/WinSW-x64.exe -OutFile sing-box-service.exe
```

### Шаг 2. Создать конфиг sing-box

Скачай шаблон и заполни своей VLESS:

```powershell
iwr -useb https://raw.githubusercontent.com/DevKitRU/my-vpn-kit/main/shared/singbox-template.json -OutFile singbox.json
```

Открой `C:\ProgramData\sing-box\singbox.json` в Блокноте, найди секцию `"vless-out"` и замени **четыре значения** на свои из VLESS-ссылки:
- `server` — IP твоего VPS
- `uuid` — UUID из VLESS
- `tls.reality.public_key` — `pbk=`
- `tls.reality.short_id` — `sid=`

(автоматический парсер VLESS — в `install.ps1`; если делаешь руками, проще один раз прогнать парсер)

### Шаг 3. Создать XML для WinSW

Создай файл `C:\ProgramData\sing-box\sing-box-service.xml`:

```xml
<service>
  <id>sing-box</id>
  <name>sing-box VPN</name>
  <description>sing-box VPN proxy with TUN mode</description>
  <executable>C:\ProgramData\sing-box\sing-box.exe</executable>
  <arguments>run -c "C:\ProgramData\sing-box\singbox.json"</arguments>
  <workingdirectory>C:\ProgramData\sing-box</workingdirectory>
  <logpath>C:\ProgramData\sing-box\logs</logpath>
  <log mode="roll-by-size">
    <sizeThreshold>10240</sizeThreshold>
    <keepFiles>2</keepFiles>
  </log>
  <startmode>Automatic</startmode>
  <onfailure action="restart" delay="10 sec"/>
</service>
```

### Шаг 4. Установить и запустить службу

```powershell
cd C:\ProgramData\sing-box
.\sing-box-service.exe install
Start-Service sing-box
```

### Шаг 5. Прописать переменные среды для Claude Code

```powershell
[Environment]::SetEnvironmentVariable("HTTPS_PROXY", "http://127.0.0.1:1080", "User")
[Environment]::SetEnvironmentVariable("HTTP_PROXY",  "http://127.0.0.1:1080", "User")
[Environment]::SetEnvironmentVariable("https_proxy", "http://127.0.0.1:1080", "User")
[Environment]::SetEnvironmentVariable("http_proxy",  "http://127.0.0.1:1080", "User")
```

После этого **перезапусти VSCode** чтобы Claude Code подхватил новые переменные.

### Шаг 6. Проверить

```powershell
# Служба запущена?
Get-Service sing-box
# Должно быть Status: Running

# TUN-интерфейс поднят?
Get-NetAdapter | Where-Object InterfaceDescription -match 'sing-tun'
# Должен быть singbox1, Status: Up

# Выходной IP через VPN
curl.exe -x http://127.0.0.1:1080 https://api.ipify.org
# Покажет IP вашего VPS, не ваш домашний
```

## Управление службой

```powershell
Get-Service sing-box               # статус
Restart-Service sing-box           # перечитать конфиг после правок
Stop-Service sing-box              # остановить (VPN отключится)
Start-Service sing-box             # включить обратно

# Посмотреть логи (иногда помогает при проблемах)
Get-Content C:\ProgramData\sing-box\logs\sing-box.err.log -Tail 30
```

## Смена VLESS-ссылки (если сменил сервер или ключи)

1. Открой `C:\ProgramData\sing-box\singbox.json`
2. Обнови `server`, `uuid`, `public_key`, `short_id` в секции `vless-out`
3. Перезапусти: `Restart-Service sing-box`

## Удаление

```powershell
cd C:\ProgramData\sing-box
.\sing-box-service.exe uninstall
Remove-Item -Recurse C:\ProgramData\sing-box

# Снести переменные среды
[Environment]::SetEnvironmentVariable("HTTPS_PROXY", $null, "User")
[Environment]::SetEnvironmentVariable("HTTP_PROXY",  $null, "User")
[Environment]::SetEnvironmentVariable("https_proxy", $null, "User")
[Environment]::SetEnvironmentVariable("http_proxy",  $null, "User")
```

## Частые проблемы

Если что-то пошло не так — [docs/troubleshooting.md](../docs/troubleshooting.md).

Основные симптомы:
- **Интернета нет, ничего не открывается** → вероятно служба не стартанула. `Get-Service sing-box` и логи
- **Claude Code выдаёт 403** → env `HTTPS_PROXY` не подхватился. Перезапусти VSCode
- **Telegram/Discord работают, но игры в не-том регионе** → проверить что нужные домены в `domain_suffix` direct-списке (см. [shared/presets/](../shared/presets/))
- **Mini App в Telegram Desktop не грузится** → специфика WebView2. Решение — добавить домен mini app в VPN-route (`outbound: vless-out`)
