---
name: my-vpn-kit-macos
description: Устанавливает sing-box на macOS (Intel и Apple Silicon) через
  Homebrew с автозапуском как LaunchAgent. SOCKS/HTTP прокси на 127.0.0.1:1080,
  env-переменные для Claude Code в ~/.zshrc. Split-tunneling под РФ —
  российские сервисы direct, зарубежные через VPN. Использовать когда
  пользователь на macOS просит настроить свой VPN через sing-box.
---

# macOS sing-box setup skill

Цель: поднять sing-box на macOS как LaunchAgent (автозапуск, перезапуск при крахе), настроить SOCKS-прокси на порту 1080, прописать env-переменные для Claude Code и CLI-утилит.

## Предусловия

1. **Homebrew установлен**: `brew --version` → должно выдать версию
2. **VLESS-ссылка** от пользователя (формат `vless://UUID@HOST:PORT?...`)
3. **macOS 11+** (Big Sur или новее) — более старые версии не тестировались

Если Homebrew нет — направить на [brew.sh](https://brew.sh):
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Входные данные

VLESS URI (формат как в Windows SKILL — см. `windows/SKILL.md`).

## Пошаговое выполнение

### Шаг 1 — Установить sing-box

```bash
brew install sing-box
# Проверить версию — должна быть 1.13.x
sing-box version
```

### Шаг 2 — Определить путь к бинарнику

На Apple Silicon: `/opt/homebrew/bin/sing-box`
На Intel: `/usr/local/bin/sing-box`

```bash
SING_BOX=$(which sing-box)
```

### Шаг 3 — Сгенерировать конфиг

Скачать шаблон, парсить VLESS, подставить:

```bash
mkdir -p ~/.config/sing-box
curl -fsSL https://raw.githubusercontent.com/DevKitRU/my-vpn-kit/main/shared/singbox-template.json \
  -o ~/.config/sing-box/config.json

# Парсинг VLESS-ссылки (в install.sh есть готовая функция)
# Подставить 8 значений из ссылки: UUID, SERVER, SERVER_PORT, FLOW, SNI, FP, PBK, SID
```

Проверить валидность:
```bash
sing-box check -c ~/.config/sing-box/config.json
```

### Шаг 4 — LaunchAgent plist

Создать `~/Library/LaunchAgents/com.singbox.vpn.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>com.singbox.vpn</string>
    <key>ProgramArguments</key>
    <array>
        <string>${SING_BOX}</string>
        <string>run</string>
        <string>-c</string>
        <string>${HOME}/.config/sing-box/config.json</string>
    </array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
    <key>StandardOutPath</key><string>/tmp/singbox.log</string>
    <key>StandardErrorPath</key><string>/tmp/singbox.err.log</string>
</dict>
</plist>
```

### Шаг 5 — Загрузить LaunchAgent

```bash
launchctl load ~/Library/LaunchAgents/com.singbox.vpn.plist

# Проверить
launchctl list | grep singbox
lsof -iTCP:1080 -sTCP:LISTEN
```

### Шаг 6 — Env в ~/.zshrc

Добавить идемпотентно (если ещё нет):

```bash
if ! grep -q "HTTPS_PROXY=http://127.0.0.1:1080" ~/.zshrc; then
cat >> ~/.zshrc <<'EOF'

# my-vpn-kit (sing-box)
export http_proxy=http://127.0.0.1:1080
export https_proxy=http://127.0.0.1:1080
export HTTP_PROXY=http://127.0.0.1:1080
export HTTPS_PROXY=http://127.0.0.1:1080
EOF
fi
```

Сообщить пользователю что **для текущего терминала нужен `source ~/.zshrc`**, а для VSCode — рестарт.

### Шаг 7 — Аварийный откат на Desktop

Создать `~/Desktop/restore-vpn.sh`:

```bash
#!/bin/bash
# Отключение VPN если что-то сломалось
launchctl unload ~/Library/LaunchAgents/com.singbox.vpn.plist 2>/dev/null
networksetup -setsocksfirewallproxystate "Wi-Fi" off 2>/dev/null
echo "VPN остановлен. Интернет должен вернуться."
echo "Чтобы включить обратно: launchctl load ~/Library/LaunchAgents/com.singbox.vpn.plist"
```

```bash
chmod +x ~/Desktop/restore-vpn.sh
```

### Шаг 8 — Верификация

```bash
# Процесс жив
launchctl list | grep singbox

# Порт слушает
lsof -iTCP:1080 -sTCP:LISTEN | grep sing-box

# Трафик идёт через VPN
curl -x http://127.0.0.1:1080 https://api.ipify.org
# Должен показать IP VPS
```

## Critical checkpoints

1. **НИКОГДА не ставить `"detour": "direct"` у DNS-сервера** в конфиге sing-box 1.13+. Это приводит к FATAL на старте и `sing-box check` эту ошибку не ловит, она появляется только в рантайме. См. `feedback_singbox_split_tunnel.md` в памяти.

2. **`ALL_PROXY=socks5://...` не работает с Node.js fetch/https** — Claude Code не подхватит. Использовать именно `http_proxy`/`HTTPS_PROXY` со схемой `http://` на mixed-порт.

3. **`default_domain_resolver` обязателен** в sing-box 1.12+. Без него — FATAL "missing route.default_domain_resolver".

4. **Remote rule_set (`geoip-ru.srs`)** требует доступа в интернет при первом запуске. Если VPS ещё не поднят и sing-box стартует — rule_set не скачается. Либо поднимать VPS раньше, либо закомментировать правило с `rule_set` на первый запуск.

## Error handling

**Ошибка: `sing-box: command not found` после brew install**
→ PATH. Для Apple Silicon добавить в `~/.zshrc`: `export PATH="/opt/homebrew/bin:$PATH"`

**Ошибка: LaunchAgent грузится но процесс сразу падает**
→ `sing-box check` проходит, но в `/tmp/singbox.err.log` FATAL → ошибка runtime (DNS detour, legacy format). Смотри `docs/troubleshooting.md`.

**Ошибка: Claude Code отдаёт 403 после установки env**
→ Не подхватил env. `echo $HTTPS_PROXY` в терминале должен показать `http://127.0.0.1:1080`. Если нет — `source ~/.zshrc` + рестарт VSCode.

## Связанные файлы

- [README.md](README.md) — инструкция для пользователя
- [install.sh](install.sh) — автоматизация всех шагов
- [../shared/singbox-template.json](../shared/singbox-template.json) — шаблон конфига
- [../shared/presets/](../shared/presets/) — 3 готовых пресета (dev/gaming/minimalist)
- [../docs/troubleshooting.md](../docs/troubleshooting.md) — разбор частых проблем
