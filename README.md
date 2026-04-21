# my-vpn-kit

Свой VPN для разработчика в России — стабильный, без танцев с Hiddify/v2rayN, чтобы не слетал логин в Claude Code, Anthropic API, OpenAI и других сервисах.

> Публичные VPN периодически слетают и ломают авторизацию в AI-инструментах. Свой VPS + sing-box — один раз настроил и забыл. Стоит ≈670₽/месяц.

## Что внутри

Этот репозиторий — набор Claude Skills для настройки **клиентской части** VPN на всех ваших устройствах. Серверная часть ставится отдельно, через готовый скилл [AndyShaman/3x-ui-skill](https://github.com/AndyShaman/3x-ui-skill).

```
Сервер (VPS):         AndyShaman/3x-ui-skill  →  VLESS Reality
                              ↓
Клиенты (этот репо):
  ├─ windows/   →  sing-box как Windows Service, TUN режим
  ├─ macos/     →  sing-box через LaunchAgent, SOCKS на 1080
  └─ ios/       →  Shadowrocket с правильными настройками
```

## Быстрый старт

Что нужно: VPS с 3x-ui, ваша VLESS-ссылка.

### Windows

Открой PowerShell **от администратора** (Win+X → «Terminal (Administrator)») и выполни:

```powershell
iwr -useb https://raw.githubusercontent.com/DevKitRU/my-vpn-kit/main/windows/install.ps1 | iex
```

**Что делает эта команда:**
- `iwr -useb ...` — скачивает скрипт установки `install.ps1` из этого репозитория
- `| iex` — выполняет его

Скрипт спросит вашу VLESS-ссылку, установит sing-box как Windows Service, пропишет переменные среды для Claude Code, и поднимет TUN-интерфейс. Весь процесс — 1-2 минуты.

Скрипт можно посмотреть глазами до запуска: [windows/install.ps1](windows/install.ps1) — ничего скрытого, 100-150 строк PowerShell.

Если не доверяешь `| iex` — смотри [windows/README.md](windows/README.md), там пошаговая ручная инструкция.

### macOS

В терминале:

```bash
curl -fsSL https://raw.githubusercontent.com/DevKitRU/my-vpn-kit/main/macos/install.sh | bash
```

**Что делает:** аналогично Windows — скачивает и запускает скрипт установки, только для Mac (ставит sing-box через LaunchAgent).

Скрипт: [macos/install.sh](macos/install.sh). Ручная инструкция: [macos/README.md](macos/README.md).

### iOS (Shadowrocket)

Одного скрипта нет — у iOS настройки через приложение Shadowrocket (500₽ в App Store, покупать с аккаунта США/другой страны).

Пошаговая инструкция со скриншотами: [ios/README.md](ios/README.md).

## Особенности

- **Split-tunneling под российскую специфику.** Российские сервисы на иностранных TLD (STALCRAFT на `stalcraft.net`, Mail.ru Games, Сбер, Тинькофф, Xsolla) идут **напрямую с RU IP** — иначе они банят зарубежные IP и блокируют логин. Иностранные сервисы (Claude, OpenAI, GitHub, Discord) — через VPN.
- **Запускается как служба.** Sing-box стартует при включении компа (до логина), автоматический рестарт при крахе.
- **Три готовых пресета.** [configs/presets/](configs/presets/) — dev / gaming / minimalist. Выбирайте под свой сценарий.
- **Troubleshooting.** [docs/troubleshooting.md](docs/troubleshooting.md) — симптомы и фиксы из реального 9-часового разбора.

## Связка со скиллом сервера

1. Поднять VPS через [AndyShaman/3x-ui-skill](https://github.com/AndyShaman/3x-ui-skill)
2. Получить VLESS-ссылку от 3x-ui
3. Установить клиентский скилл на свою ОС (см. выше)
4. Вставить ссылку — всё

## Какой VPS взять

Sing-box потребляет минимум ресурсов (на моей машине ≈85 МБ RAM), поэтому подойдёт самый дешёвый VPS. Главное — **страна вне РФ**.

Я использую [**OVH Kimsufi**](https://kimsufi.com/) — дата-центр в Канаде, тариф примерно **8000₽/год (670₽/мес)**. Работает стабильно, Anthropic пускает без вопросов. Это единственный провайдер который я реально проверил.

Любой другой VPS тоже подойдёт — требования минимальные:
- 1 vCPU, 512 МБ RAM, 10 ГБ диск
- Трафик 100 ГБ/мес+
- IPv4

**Что точно не стоит брать:** российских провайдеров (Selectel, Timeweb, Reg.ru) — у них сервер физически в РФ, и с такого IP тоже работать не будет (весь смысл VPN теряется).

## Лицензия

[MIT](LICENSE) — используйте свободно.

## Дисклеймер

Проект предназначен для образовательных целей и обеспечения стабильного доступа к AI-сервисам для разработчиков. Используйте в соответствии с законодательством своей страны.
