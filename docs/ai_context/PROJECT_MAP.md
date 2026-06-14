# PROJECT_MAP

Короткая карта `my-vpn-kit` для Codex, Claude и других AI-агентов.

Это роутер, а не архив.

## Что это за проект

Публичный DevKitRU kit для настройки sing-box клиентов:

- Windows: sing-box как Windows Service с TUN.
- macOS: sing-box через LaunchAgent и локальный proxy.
- iOS: ручная настройка Shadowrocket.
- Shared: шаблон sing-box и routing presets.

Проект помогает разработчику настроить свой VPN-клиент под VLESS Reality, split routing и доступ к AI/dev-сервисам.

## Быстрый вход

1. Прочитай этот файл.
2. Если задача касается установщиков, VPN-конфигов, routing или публичной инструкции, прочитай `DANGER_ZONES.md`.
3. Открой только нужную платформенную папку.
4. Перед финалом смотри `VERIFICATION.md`.

## Карта файлов

| Путь | Роль | Читать когда |
| --- | --- | --- |
| `README.md` | Главная витрина проекта | Меняем общую подачу или quickstart |
| `docs/first-time-setup.md` | Путь новичка с нуля | Меняем beginner onboarding |
| `docs/troubleshooting.md` | Частые поломки | Добавляем диагностику |
| `windows/install.ps1` | Windows installer | Меняем Windows runtime/install behavior |
| `windows/README.md` | Windows ручная инструкция | Меняем Windows docs |
| `macos/install.sh` | macOS installer | Меняем macOS runtime/install behavior |
| `macos/README.md` | macOS ручная инструкция | Меняем macOS docs |
| `ios/README.md` | Shadowrocket инструкция | Меняем iOS docs |
| `shared/singbox-template.json` | Default sing-box config | Меняем общий config |
| `shared/presets/*.json` | Routing presets | Меняем routing policy |

## Главные потоки

- User gets VLESS Reality link -> chooses OS -> installer parses link -> writes sing-box config -> validates -> starts service/agent -> checks proxy.
- Beginner path -> VPS and VLESS server are prepared elsewhere -> this repo configures local clients.
- Public docs -> no private server values, real VLESS links, tokens, personal IPs, or private payment details.

## Точки поиска

```bash
rg -n "VLESS|sing-box|TUN|LaunchAgent|WinSW|preset|route|proxy" .
rg -n "configs/presets|shared/presets|SECRET|TOKEN|PRIVATE|IP_ТВОЕГО|your-vps" .
```

## Правило контекста

Не читать весь проект без причины.

Сначала карта. Потом danger zones. Потом конкретная платформа.
