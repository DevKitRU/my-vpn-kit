# my-vpn-kit

Скрипты и конфиги для своего VPN на sing-box.

Я собирал этот набор для своей рабочей схемы: Claude Code и dev-сервисы идут через VPS, российские сайты, игры и банки идут напрямую. Так не приходится вручную прыгать между серверами в VPN-клиенте.

Что проверял лично:

- Windows 10 Pro с sing-box как службой.
- macOS с LaunchAgent.
- iPhone через Shadowrocket.
- VPS OVH Kimsufi, около 670 рублей в месяц.

## Что внутри

Этот репозиторий закрывает клиентскую часть. Серверную часть я поднимал отдельно через [AndyShaman/3x-ui-skill](https://github.com/AndyShaman/3x-ui-skill).

```
Сервер (VPS):         AndyShaman/3x-ui-skill  ->  VLESS Reality
                              ↓
Клиенты (этот репо):
  ├─ windows/   ->  sing-box как Windows Service, TUN режим
  ├─ macos/     ->  sing-box через LaunchAgent, SOCKS на 1080
  └─ ios/       ->  Shadowrocket
```

## Быстрый старт

Что нужно: VPS с 3x-ui, ваша VLESS-ссылка.

Если Claude Code из РФ уже ловит 403, сначала нужен временный рабочий доступ: Hiddify, v2rayN, публичный VPN или Claude на VPS. Потом ставишь клиент из этого репозитория и убираешь временный вариант.

Подробный путь для первого запуска: [docs/first-time-setup.md](docs/first-time-setup.md).

### Windows

Открой PowerShell **от администратора** через Win+X, затем «Terminal (Administrator)», и выполни:

```powershell
iwr -useb https://raw.githubusercontent.com/DevKitRU/my-vpn-kit/main/windows/install.ps1 | iex
```

Что делает эта команда:
- `iwr -useb ...` скачивает `install.ps1` из этого репозитория.
- `| iex` запускает скрипт.

Скрипт спросит VLESS-ссылку, установит sing-box как Windows Service, пропишет переменные среды для Claude Code и поднимет TUN-интерфейс.

Скрипт перед запуском лучше посмотреть: [windows/install.ps1](windows/install.ps1).

Если не доверяешь `| iex`, смотри [windows/README.md](windows/README.md). Там ручная инструкция.

### macOS

В терминале:

```bash
curl -fsSL https://raw.githubusercontent.com/DevKitRU/my-vpn-kit/main/macos/install.sh | bash
```

Что делает: скачивает и запускает скрипт установки для Mac. Он ставит sing-box через LaunchAgent.

Скрипт: [macos/install.sh](macos/install.sh). Ручная инструкция: [macos/README.md](macos/README.md).

### iOS (Shadowrocket)

iOS я настраивал через Shadowrocket. Одного установочного скрипта нет.

Пошаговая инструкция со скриншотами: [ios/README.md](ios/README.md).

## Особенности

- **Split routing под РФ.** STALCRAFT, Mail.ru Games, Сбер, Тинькофф и Xsolla идут напрямую с RU IP. Claude, OpenAI, GitHub и другие внешние сервисы идут через VPN.
- **Windows Service.** sing-box стартует при включении компьютера и поднимает TUN до входа пользователя.
- **Пресеты.** [configs/presets/](configs/presets/) содержит dev, gaming и minimalist.
- **Troubleshooting.** [docs/troubleshooting.md](docs/troubleshooting.md) собран по ошибкам, которые я ловил сам.

## Связка со скиллом сервера

1. Поднять VPS через [AndyShaman/3x-ui-skill](https://github.com/AndyShaman/3x-ui-skill)
2. Получить VLESS-ссылку от 3x-ui
3. Установить клиентский скилл на свою ОС (см. выше)
4. Вставить ссылку и проверить маршруты.

## Какой VPS взять

Sing-box потребляет мало ресурсов. На моей машине было около 85 МБ RAM. Подойдёт дешёвый VPS. Главное: страна вне РФ.

Я использую [OVH Kimsufi](https://kimsufi.com/). Дата-центр в Канаде, тариф около 8000 рублей в год. Это примерно 670 рублей в месяц. Это единственный провайдер, который я проверял долго.

Как оплатить из РФ: я покупал OVH и Claude Pro через бот [@platipomiru_sup_bot](https://t.me/platipomiru_sup_bot) в Telegram. Он выпускает виртуальную карту под платёж. Альтернативы не тестировал.

Любой другой VPS тоже подойдёт. Требования минимальные:
- 1 vCPU, 512 МБ RAM, 10 ГБ диск
- Трафик 100 ГБ/мес+
- IPv4

Российский VPS для этой задачи не подойдёт. Если сервер физически в РФ, Claude Code всё равно будет видеть российский IP.

## Статус тестирования

- **Windows 10 Pro**: протестировано на реальной системе автором, включая несколько перезагрузок. Windows Service стартует до логина, TUN поднимается автоматически, split-tunneling работает.
- **macOS**: базируется на проверенной конфигурации из ежедневного использования автора.
- **iOS Shadowrocket**: инструкция основана на реальных инцидентах и разборе настроек.
- **Чистая Windows 11 / VM**: не проверено. Windows Sandbox конфликтует с Kaspersky, а чистой машины без Касперского под рукой не было.

Если повторяешь установку, начни с одной машины. Потом добавляй телефон, Windows и свои direct-домены.

## Лицензия

[MIT](LICENSE).

## Дисклеймер

Проект предназначен для образовательных целей и обеспечения стабильного доступа к AI-сервисам для разработчиков. Используйте в соответствии с законодательством своей страны.
