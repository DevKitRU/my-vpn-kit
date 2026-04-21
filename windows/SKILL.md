---
name: my-vpn-kit-windows
description: Устанавливает и настраивает sing-box VPN как Windows Service на
  Windows 10/11. Парсит VLESS-ссылку пользователя, поднимает TUN-режим, прописывает
  переменные среды для Claude Code. Split-tunneling настроен под РФ — российские
  сервисы direct, зарубежные через VPN. Использовать когда пользователь на Windows
  просит настроить свой VPN через sing-box.
---

# Windows sing-box setup skill

Цель: поднять sing-box как Windows Service на машине пользователя, чтобы:
- Весь системный трафик шёл через TUN-интерфейс
- Заблокированные в РФ сервисы (Claude, OpenAI, GitHub, Discord, YouTube) — через VPN
- Российские сервисы на любых TLD (sberbank.com, vk.com, stalcraft.net) — direct с RU IP
- Claude Code CLI работал через env `HTTPS_PROXY=http://127.0.0.1:1080`
- Служба стартовала автоматически при включении компа, до логина

## Предусловия

Прежде чем начинать, проверить:

1. **ОС**: Windows 10 или 11 (`winver` в PowerShell)
2. **Права**: Администратор (выполнить `net session` — не должно быть ошибки)
3. **VLESS-ссылка от пользователя**: спросить, она должна быть в формате
   `vless://UUID@HOST:PORT?security=reality&pbk=...&sid=...#name`
4. **Интернет работает** (может быть через чужой VPN/прокси — ок, мы свой поставим поверх)

Если пользователь не знает что такое VLESS-ссылка — направить его на
[AndyShaman/3x-ui-skill](https://github.com/AndyShaman/3x-ui-skill) для настройки VPS.

## Входные данные от пользователя

Один параметр — VLESS URI в формате:

```
vless://<UUID>@<HOST>:<PORT>?security=reality&pbk=<PUBLIC_KEY>&sid=<SHORT_ID>&sni=<SNI>&flow=xtls-rprx-vision&fp=chrome#<NAME>
```

Пример для примера (dummy-значения, не рабочая ссылка):
```
vless://aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee@1.2.3.4:443?security=reality&pbk=DUMMY_PUBKEY&sid=0011223344&sni=www.example.com&flow=xtls-rprx-vision&fp=chrome#my-vpn
```

Из него нужно извлечь:
- `uuid` — между `vless://` и `@`
- `server` — после `@` до `:`
- `server_port` — после `:` до `?`
- `security` — параметр `security` (должен быть `reality`, иначе не наш кейс)
- `public_key` — параметр `pbk`
- `short_id` — параметр `sid`
- `sni` — параметр `sni` (`server_name`)
- `flow` — параметр `flow` (обычно `xtls-rprx-vision`)
- `fingerprint` — параметр `fp` (обычно `chrome`)

## Пошаговое выполнение

### Шаг 1 — Создать рабочую директорию

```powershell
$workDir = "C:\ProgramData\sing-box"
New-Item -Path $workDir -ItemType Directory -Force | Out-Null
Set-Location $workDir
```

### Шаг 2 — Скачать sing-box v1.13.8

```powershell
$sbUrl = "https://github.com/SagerNet/sing-box/releases/download/v1.13.8/sing-box-1.13.8-windows-amd64.zip"
Invoke-WebRequest -Uri $sbUrl -OutFile "$workDir\singbox.zip"
Expand-Archive -Path "$workDir\singbox.zip" -DestinationPath $workDir -Force
Move-Item -Path "$workDir\sing-box-1.13.8-windows-amd64\sing-box.exe" -Destination $workDir -Force
Remove-Item -Recurse -Path "$workDir\sing-box-1.13.8-windows-amd64"
Remove-Item -Path "$workDir\singbox.zip"
```

Если сеть не тянет GitHub напрямую из РФ — использовать прокси (Hiddify/v2rayN/...) на время скачивания.

### Шаг 3 — Скачать WinSW v2.12.0

```powershell
$winswUrl = "https://github.com/winsw/winsw/releases/download/v2.12.0/WinSW-x64.exe"
Invoke-WebRequest -Uri $winswUrl -OutFile "$workDir\sing-box-service.exe"
```

### Шаг 4 — Сгенерировать конфиг

Взять шаблон из репо:

```powershell
$tplUrl = "https://raw.githubusercontent.com/DevKitRU/my-vpn-kit/main/shared/singbox-template.json"
$config = (Invoke-WebRequest -Uri $tplUrl).Content
```

Подставить значения из VLESS-ссылки в шаблон (в шаблоне плейсхолдеры
`{{UUID}}`, `{{SERVER}}`, `{{SERVER_PORT}}`, `{{PUBLIC_KEY}}`, `{{SHORT_ID}}`,
`{{SNI}}`, `{{FLOW}}`, `{{FINGERPRINT}}`):

```powershell
$config = $config.Replace("{{UUID}}", $uuid)
# ... и так для всех полей
$config | Set-Content "$workDir\singbox.json" -Encoding UTF8
```

Проверить что конфиг валиден:

```powershell
& "$workDir\sing-box.exe" check -c "$workDir\singbox.json"
```

Если `FATAL` — остановиться и разобраться (скорее всего VLESS-ссылка парсилась кривой).

### Шаг 5 — Создать XML для WinSW

```powershell
@"
<service>
  <id>sing-box</id>
  <name>sing-box VPN</name>
  <description>sing-box VPN with TUN mode</description>
  <executable>$workDir\sing-box.exe</executable>
  <arguments>run -c "$workDir\singbox.json"</arguments>
  <workingdirectory>$workDir</workingdirectory>
  <logpath>$workDir\logs</logpath>
  <log mode="roll-by-size">
    <sizeThreshold>10240</sizeThreshold>
    <keepFiles>2</keepFiles>
  </log>
  <startmode>Automatic</startmode>
  <onfailure action="restart" delay="10 sec"/>
</service>
"@ | Set-Content "$workDir\sing-box-service.xml" -Encoding UTF8
```

### Шаг 6 — Установить и запустить службу

```powershell
& "$workDir\sing-box-service.exe" install
Start-Service sing-box
```

Проверить статус:

```powershell
Get-Service sing-box
# Status должен быть Running
```

### Шаг 7 — Прописать переменные среды

```powershell
foreach ($var in "HTTPS_PROXY","HTTP_PROXY","https_proxy","http_proxy") {
    [Environment]::SetEnvironmentVariable($var, "http://127.0.0.1:1080", "User")
}
```

Сообщить пользователю что **нужен рестарт VSCode** чтобы Claude Code подхватил новые переменные.

### Шаг 8 — Верификация

```powershell
# 1. Служба жива
Get-Service sing-box  # Running ?

# 2. TUN поднят
Get-NetAdapter | Where-Object InterfaceDescription -match 'sing-tun'
# Должен быть singbox1, Up

# 3. Порт 1080 слушает
Test-NetConnection -ComputerName 127.0.0.1 -Port 1080

# 4. Трафик идёт через VPN (IP вашего VPS)
$vpnIp = (Invoke-WebRequest -Proxy "http://127.0.0.1:1080" -Uri "https://api.ipify.org").Content
Write-Host "VPN exit IP: $vpnIp"
```

Если IP совпадает с IP VPS → всё работает.

## Critical checkpoints

1. **Не отключать текущий VPN пользователя (Hiddify/v2rayN) до того как служба sing-box
   подтверждено Running** — иначе Claude Code отвалится (работает через прокси локально).
   См. `feedback_claude_needs_vpn_alive.md` в памяти.

2. **VLESS-ссылку с UUID и ключами НИКОГДА не логировать в чат и файлы памяти**
   которые идут в публичный git. Только в локальный `singbox.json` (в `.gitignore`).

3. **Перезапуск VSCode** — новые env-переменные подхватываются только новыми
   процессами. Текущий Claude-процесс работает со старыми env до рестарта.

## Error handling

**Ошибка: "Access denied" при install**
→ PowerShell не от администратора. Попросить пользователя открыть Terminal как Admin.

**Ошибка: "FATAL decode config"**
→ VLESS-ссылка парсилась неправильно. Показать пользователю JSON, найти поле с плейсхолдером `{{...}}` которое не заменилось.

**Служба стартует но IP не через VPN**
→ Проверить `Get-Content logs/sing-box.err.log -Tail 30`. Обычно ошибка подключения к серверу (сервер недоступен или ключи не совпадают).

**TUN интерфейс не появился**
→ Проверить Windows Defender — иногда блокирует wintun driver. Временно отключить real-time protection и перезапустить службу.

## После успешной установки

Рассказать пользователю:
- Служба запускается автоматически при старте Windows
- Для смены VLESS — отредактировать `C:\ProgramData\sing-box\singbox.json` и `Restart-Service sing-box`
- Логи: `C:\ProgramData\sing-box\logs\`
- Если что — см. `windows/docs/troubleshooting.md` в репо

## Связанные файлы

- [README.md](README.md) — человеческая инструкция (для пользователя напрямую без Claude)
- [install.ps1](install.ps1) — автоматизация всех шагов выше в один скрипт
- [../shared/singbox-template.json](../shared/singbox-template.json) — шаблон конфига
- [../shared/presets/](../shared/presets/) — 3 готовых пресета routing (dev/gaming/minimalist)
- [../docs/troubleshooting.md](../docs/troubleshooting.md) — симптомы и фиксы
