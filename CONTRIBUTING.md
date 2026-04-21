# Contributing

Спасибо за интерес к проекту. Эта страница — как быстро помочь.

## Самое ценное — добавление РФ-платформ в direct-списки

Если нашёл российский сервис который:
- На иностранном TLD (`.com`, `.net`, `.io`, …)
- Банит VPN-IP / показывает ошибку / кикает с сервера
- Но работает с обычного РФ-IP

→ Открой issue по шаблону [«Добавить РФ-платформу»](https://github.com/DevKitRU/my-vpn-kit/issues/new?template=add-ru-platform.md) или сразу PR.

**Куда добавлять:**
- `shared/singbox-template.json` — в массив `domain_suffix` правила с `"outbound": "direct"`
- `shared/presets/gaming.json` — если это игровой сервис
- Если нужен для AI/dev сценария — `shared/presets/dev.json`

## Bug reports

Любой симптом — issue по шаблону [«Баг / не работает»](https://github.com/DevKitRU/my-vpn-kit/issues/new?template=bug-report.md). Чем больше контекста, тем быстрее найдём причину.

## Pull requests

- Без крупных изменений без обсуждения — сначала issue
- В коммитах указывай что именно поменял в одной строке
- Если меняешь скрипты (install.ps1 / install.sh) — прогони у себя сначала
- Если меняешь sing-box конфиг — проверь `sing-box check -c file.json` перед PR

## Структура репо

```
windows/     — клиент для Windows (sing-box + WinSW Windows Service)
macos/       — клиент для macOS (sing-box + LaunchAgent)
ios/         — инструкция для iOS (Shadowrocket, без скрипта)
shared/      — общее для всех клиентов
  ├ singbox-template.json       — базовый шаблон
  └ presets/                    — dev / gaming / minimalist
docs/        — troubleshooting и общая документация
```

## Правила честности

Если пишешь в README / SKILL / статью — **никаких выдуманных фактов**. Только то что реально проверил:
- Цифры — измерены
- Скорости — измерены
- Рекомендации провайдеров — только те которыми реально пользовался
- Симптомы и фиксы — из реального опыта или подтверждённого источника

Аудитория проекта — инженеры. Они замечают придуманное, и доверие теряется быстро.

## Серверная часть

Этот репо — только клиенты. Для настройки серверной части VLESS Reality есть отдельный скилл: [AndyShaman/3x-ui-skill](https://github.com/AndyShaman/3x-ui-skill). Если у тебя улучшение для серверной части — туда.

## Связь

Issues — основной канал. Сделать коммерческое внедрение / консультацию — писать в DM владельцу [github.com/DevKitRU](https://github.com/DevKitRU).
