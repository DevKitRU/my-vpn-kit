# macOS — sing-box через LaunchAgent

Установка sing-box на macOS с автозапуском через LaunchAgent и SOCKS-прокси на `127.0.0.1:1080`.

## Результат после установки

- sing-box работает как фоновый процесс через `launchd` (автозапуск при логине)
- SOCKS/HTTP прокси слушает `127.0.0.1:1080` (mixed режим)
- Системный прокси macOS указывает на 1080 (можно при желании — см. ниже)
- Переменные `HTTPS_PROXY` прописаны в `~/.zshrc` для CLI-инструментов (Claude Code, curl, gh)
- Автоматический перезапуск если процесс упал (`KeepAlive=true`)

## Что потребуется

1. **macOS** (Intel или Apple Silicon)
2. **Homebrew** установлен (`brew --version`). Если нет — [brew.sh](https://brew.sh)
3. **VPS с 3x-ui** (если нет — [AndyShaman/3x-ui-skill](https://github.com/AndyShaman/3x-ui-skill))
4. **VLESS-ссылка** из 3x-ui панели

## Быстрый старт — один скрипт

В Терминале:

```bash
curl -fsSL https://raw.githubusercontent.com/DevKitRU/my-vpn-kit/main/macos/install.sh | bash
```

Скрипт:
1. Проверит что установлен Homebrew
2. Установит sing-box: `brew install sing-box`
3. Спросит VLESS-ссылку и пресет
4. Сгенерирует конфиг в `~/.config/sing-box/config.json`
5. Создаст LaunchAgent `~/Library/LaunchAgents/com.singbox.vpn.plist`
6. Загрузит его через `launchctl`
7. Пропишет env-переменные в `~/.zshrc`
8. Создаст аварийный скрипт отката на Desktop

1-2 минуты.

## Ручная установка

### Шаг 1. Установить sing-box

```bash
brew install sing-box
sing-box version   # должно показать 1.13.x
```

### Шаг 2. Сгенерировать конфиг

```bash
mkdir -p ~/.config/sing-box
curl -fsSL https://raw.githubusercontent.com/DevKitRU/my-vpn-kit/main/shared/singbox-template.json \
  -o ~/.config/sing-box/config.json
```

Открой `~/.config/sing-box/config.json` и замени **8 плейсхолдеров** своими значениями из VLESS-ссылки:
- `{{UUID}}`, `{{SERVER}}`, `{{SERVER_PORT}}`, `{{FLOW}}`
- `{{SNI}}`, `{{FINGERPRINT}}`, `{{PUBLIC_KEY}}`, `{{SHORT_ID}}`

Проверь конфиг:
```bash
sing-box check -c ~/.config/sing-box/config.json
```

### Шаг 3. LaunchAgent для автозапуска

Создай файл `~/Library/LaunchAgents/com.singbox.vpn.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.singbox.vpn</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/sing-box</string>
        <string>run</string>
        <string>-c</string>
        <string>/Users/ВАШ_USER/.config/sing-box/config.json</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/singbox.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/singbox.err.log</string>
</dict>
</plist>
```

Замени `ВАШ_USER` на своё имя пользователя (узнать: `whoami`).
Для Intel Mac путь к бинарю: `/usr/local/bin/sing-box` вместо `/opt/homebrew/bin/sing-box`.

Загрузи:
```bash
launchctl load ~/Library/LaunchAgents/com.singbox.vpn.plist
```

Проверь:
```bash
launchctl list | grep singbox    # должна быть строка с PID
lsof -iTCP:1080 -sTCP:LISTEN     # должен слушать sing-box
```

### Шаг 4. Переменные среды для Claude Code

Добавь в `~/.zshrc`:

```bash
export http_proxy=http://127.0.0.1:1080
export https_proxy=http://127.0.0.1:1080
export HTTP_PROXY=http://127.0.0.1:1080
export HTTPS_PROXY=http://127.0.0.1:1080
```

Перечитай:
```bash
source ~/.zshrc
```

### Шаг 5. Системный прокси macOS (опционально)

Для приложений которые не читают `HTTPS_PROXY` env (браузеры, Telegram) — включить системный SOCKS:

**GUI:** Системные настройки → Сеть → твой Wi-Fi → Подробнее → Прокси → включить **SOCKS-прокси** → `127.0.0.1` порт `1080` → Применить.

**CLI:**
```bash
networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 1080
networksetup -setsocksfirewallproxystate "Wi-Fi" on
```

Отключить:
```bash
networksetup -setsocksfirewallproxystate "Wi-Fi" off
```

### Шаг 6. Проверить

```bash
# LaunchAgent активен?
launchctl list | grep singbox

# Порт 1080 слушает?
lsof -iTCP:1080 -sTCP:LISTEN

# Выходной IP через VPN (должен совпадать с IP VPS)
curl -x http://127.0.0.1:1080 https://api.ipify.org
```

## Управление

```bash
# Остановить
launchctl unload ~/Library/LaunchAgents/com.singbox.vpn.plist

# Запустить
launchctl load ~/Library/LaunchAgents/com.singbox.vpn.plist

# Перезапустить после правки конфига
launchctl kickstart -k gui/$(id -u)/com.singbox.vpn

# Логи
tail -f /tmp/singbox.log
tail -f /tmp/singbox.err.log
```

## Telegram на Mac

Нативный Telegram.app **не читает env-переменные прокси**. Два способа:
1. **Системный SOCKS** (шаг 5 выше) — работает для всех GUI-приложений сразу
2. **В самом Telegram:** Настройки → Данные и память → Прокси → SOCKS5 `127.0.0.1:1080`

## Смена VLESS-ссылки

1. Открой `~/.config/sing-box/config.json`
2. Обнови `server`, `uuid`, `public_key`, `short_id`, `sni` в секции `vless-out`
3. Перезапусти: `launchctl kickstart -k gui/$(id -u)/com.singbox.vpn`

## Аварийный откат

При первой установке автоматически создаётся `~/Desktop/restore-vpn.sh` — простой скрипт который отключает sing-box и возвращает системный прокси. Запустить если VPN сломался и интернет пропал:

```bash
~/Desktop/restore-vpn.sh
```

## Удаление

```bash
launchctl unload ~/Library/LaunchAgents/com.singbox.vpn.plist
rm ~/Library/LaunchAgents/com.singbox.vpn.plist
rm -rf ~/.config/sing-box
brew uninstall sing-box

# Убрать env из .zshrc — руками удали строки с *_proxy из ~/.zshrc
# Отключить системный SOCKS (если включал)
networksetup -setsocksfirewallproxystate "Wi-Fi" off
```

## Частые проблемы

- **sing-box не запускается, KeepAlive зациклился в restart** → `sing-box check -c ~/.config/sing-box/config.json` покажет ошибку конфига
- **Claude Code не видит прокси** → нужен рестарт терминала / VSCode после правки `.zshrc`
- **`ALL_PROXY=socks5://...` не работает с Node.js** → использовать `http_proxy` со схемой `http://`, а не `socks5://`
- **`"detour": "direct"` у DNS-сервера ломает sing-box** — эта ошибка не ловится `sing-box check`, всплывает только в рантайме ([feedback_singbox_split_tunnel](https://github.com/DevKitRU/my-vpn-kit/blob/main/docs/troubleshooting.md))

Подробнее — [docs/troubleshooting.md](../docs/troubleshooting.md).
