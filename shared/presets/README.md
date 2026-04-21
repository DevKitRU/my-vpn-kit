# Пресеты конфигов sing-box

Готовые варианты routing-таблицы под разные сценарии использования. Выбери один, скачай и подставь свою VLESS через `install.ps1 -Preset <name>`.

> **Статус:** в работе. Сейчас доступен только базовый [../singbox-template.json](../singbox-template.json) — split-tunneling с РФ-bypass (универсальный вариант).

## Планируемые пресеты

- **dev.json** — только заблокированные в РФ AI/dev-сервисы (Claude, OpenAI, GitHub, Docker Hub) через VPN, остальное direct
- **gaming.json** — РФ-игры (STALCRAFT, Mail.ru Games, ВК Игры) direct, зарубежные сервисы (Steam Community, Discord, YouTube) через VPN
- **minimalist.json** — только Anthropic и OpenAI через VPN, всё остальное direct

Если нужен какой-то конкретный пресет — открой issue.
