# DANGER_ZONES

Куда агенту нельзя лезть без явной причины.

## Секреты и реальные VPN-данные

- Не добавлять реальные VLESS-ссылки.
- Не добавлять реальные IP личных VPS.
- Не добавлять UUID, private key, shortId, public key, SNI с личных серверов.
- Не печатать пользовательские VPN configs или clipboard data.
- В документации использовать placeholders: `<your-vps>`, `<uuid>`, `<public-key>`.

## Установщики

- `windows/install.ps1` меняет Windows Service, TUN, `C:\ProgramData\sing-box`, env vars и скачивает бинарники.
- `macos/install.sh` меняет LaunchAgent, `~/.config/sing-box`, `~/.zshrc`, system proxy hints и создает restore script.
- Не менять runtime behavior установщиков без проверки синтаксиса и smoke-пути на уровне docs.
- Не запускать установщики на этой машине как проверку, если задача только документальная.

## Публичные инструкции

- Не обещать поддержку платформы, которая не проверялась.
- Не писать, что конкретный VPS/payment/provider точно лучший для всех.
- Отделять личный опыт автора от универсальной рекомендации.
- Не добавлять обходные инструкции, которые нарушают правила сервиса или закон страны пользователя.

## Routing presets

- `shared/singbox-template.json` и `shared/presets/*.json` влияют на трафик пользователя.
- Ошибка в routing может сломать интернет, игры, банки, Telegram или AI-сервисы.
- Перед изменением presets проверь JSON и явно объясни, что поменялось.
