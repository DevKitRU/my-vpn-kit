#!/bin/bash
# my-vpn-kit — macOS installer for sing-box
# https://github.com/DevKitRU/my-vpn-kit
#
# Использование:
#   curl -fsSL https://raw.githubusercontent.com/DevKitRU/my-vpn-kit/main/macos/install.sh | bash

set -euo pipefail

# Цвета
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[.]${NC} $*"; }
ok()    { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
err()   { echo -e "${RED}[x]${NC} $*"; }

# ──────────────────────────────────────────
# 0. Preflight checks
# ──────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   my-vpn-kit — sing-box macOS setup       ║"
echo "╚══════════════════════════════════════════╝"
echo ""

if ! command -v brew &> /dev/null; then
    err "Homebrew не установлен. Установи сначала: https://brew.sh"
    exit 1
fi

if [[ "$(uname)" != "Darwin" ]]; then
    err "Этот скрипт только для macOS. У вас: $(uname)"
    exit 1
fi

# ──────────────────────────────────────────
# 1. VLESS ссылка
# ──────────────────────────────────────────
echo -e "${CYAN}Вставь твою VLESS-ссылку из 3x-ui (начинается с vless://):${NC}"
read -r VLESS
if [[ ! "$VLESS" =~ ^vless:// ]]; then
    err "Это не VLESS-ссылка"
    exit 1
fi

# ──────────────────────────────────────────
# 2. Парсинг VLESS
# ──────────────────────────────────────────
# Формат: vless://UUID@HOST:PORT?params#name

# Срезать "vless://" и потом всё до '#' (имя)
STRIPPED="${VLESS#vless://}"
STRIPPED="${STRIPPED%%#*}"

USER_HOST_PORT="${STRIPPED%%\?*}"
QUERY="${STRIPPED#*\?}"

UUID="${USER_HOST_PORT%%@*}"
HOST_PORT="${USER_HOST_PORT#*@}"
SERVER="${HOST_PORT%:*}"
SERVER_PORT="${HOST_PORT##*:}"

# Парсим query-параметры
declare -A params
IFS='&' read -ra pairs <<< "$QUERY"
for pair in "${pairs[@]}"; do
    k="${pair%%=*}"
    v="${pair#*=}"
    # URL-decode (только %XX)
    v=$(printf '%b' "${v//%/\\x}")
    params[$k]="$v"
done

if [[ "${params[security]:-}" != "reality" ]]; then
    err "Этот скилл рассчитан на VLESS Reality (security=reality)."
    err "У тебя security=${params[security]:-none}"
    exit 1
fi

ok "VLESS распарсен: $SERVER:$SERVER_PORT (sni=${params[sni]})"

# ──────────────────────────────────────────
# 3. Выбор пресета
# ──────────────────────────────────────────
echo ""
echo -e "${CYAN}Какой пресет маршрутизации использовать?${NC}"
echo "  default      — РФ direct, остальное через VPN"
echo "  dev          — только AI/dev-сервисы через VPN"
echo "  gaming       — РФ-игры direct, зарубежное через VPN"
echo "  minimalist   — только Anthropic+OpenAI через VPN"
read -r -p "Пресет [default/dev/gaming/minimalist] (default): " PRESET
PRESET="${PRESET:-default}"

case "$PRESET" in
    default)    TEMPLATE_PATH="singbox-template.json" ;;
    dev|gaming|minimalist) TEMPLATE_PATH="presets/$PRESET.json" ;;
    *)          err "Неизвестный пресет: $PRESET"; exit 1 ;;
esac

# ──────────────────────────────────────────
# 4. Установить sing-box
# ──────────────────────────────────────────
if ! command -v sing-box &> /dev/null; then
    info "Ставлю sing-box через Homebrew..."
    brew install sing-box
else
    info "sing-box уже установлен ($(sing-box version | head -1))"
fi

SING_BOX_BIN=$(which sing-box)

# ──────────────────────────────────────────
# 5. Сгенерировать конфиг
# ──────────────────────────────────────────
info "Генерирую конфиг из пресета '$PRESET'..."
mkdir -p ~/.config/sing-box

CONFIG=$(curl -fsSL "https://raw.githubusercontent.com/DevKitRU/my-vpn-kit/main/shared/$TEMPLATE_PATH")

CONFIG="${CONFIG//\{\{UUID\}\}/$UUID}"
CONFIG="${CONFIG//\{\{SERVER\}\}/$SERVER}"
CONFIG="${CONFIG//\{\{SERVER_PORT\}\}/$SERVER_PORT}"
CONFIG="${CONFIG//\{\{FLOW\}\}/${params[flow]:-xtls-rprx-vision}}"
CONFIG="${CONFIG//\{\{SNI\}\}/${params[sni]}}"
CONFIG="${CONFIG//\{\{FINGERPRINT\}\}/${params[fp]:-chrome}}"
CONFIG="${CONFIG//\{\{PUBLIC_KEY\}\}/${params[pbk]}}"
CONFIG="${CONFIG//\{\{SHORT_ID\}\}/${params[sid]}}"

echo "$CONFIG" > ~/.config/sing-box/config.json

# Валидация
if ! sing-box check -c ~/.config/sing-box/config.json; then
    err "Конфиг не прошёл проверку. Смотри ошибку выше."
    exit 1
fi
ok "Конфиг валиден"

# ──────────────────────────────────────────
# 6. LaunchAgent
# ──────────────────────────────────────────
info "Создаю LaunchAgent..."
PLIST="$HOME/Library/LaunchAgents/com.singbox.vpn.plist"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>com.singbox.vpn</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SING_BOX_BIN</string>
        <string>run</string>
        <string>-c</string>
        <string>$HOME/.config/sing-box/config.json</string>
    </array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
    <key>StandardOutPath</key><string>/tmp/singbox.log</string>
    <key>StandardErrorPath</key><string>/tmp/singbox.err.log</string>
</dict>
</plist>
EOF

# Выгружаем если уже был
launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"

sleep 2

if launchctl list | grep -q "com.singbox.vpn"; then
    ok "LaunchAgent загружен"
else
    err "LaunchAgent не загрузился. Смотри /tmp/singbox.err.log"
    exit 1
fi

# ──────────────────────────────────────────
# 7. ENV в ~/.zshrc
# ──────────────────────────────────────────
ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"
if ! grep -q "HTTPS_PROXY=http://127.0.0.1:1080" "$ZSHRC"; then
    cat >> "$ZSHRC" <<'EOF'

# my-vpn-kit (sing-box)
export http_proxy=http://127.0.0.1:1080
export https_proxy=http://127.0.0.1:1080
export HTTP_PROXY=http://127.0.0.1:1080
export HTTPS_PROXY=http://127.0.0.1:1080
EOF
    ok "Env переменные добавлены в ~/.zshrc"
else
    info "Env переменные уже в ~/.zshrc"
fi

# ──────────────────────────────────────────
# 8. Restore script on Desktop
# ──────────────────────────────────────────
RESTORE="$HOME/Desktop/restore-vpn.sh"
cat > "$RESTORE" <<'EOF'
#!/bin/bash
# Аварийное отключение VPN
launchctl unload ~/Library/LaunchAgents/com.singbox.vpn.plist 2>/dev/null
networksetup -setsocksfirewallproxystate "Wi-Fi" off 2>/dev/null
echo "VPN остановлен. Интернет должен вернуться."
echo "Чтобы включить обратно: launchctl load ~/Library/LaunchAgents/com.singbox.vpn.plist"
EOF
chmod +x "$RESTORE"

# ──────────────────────────────────────────
# 9. Verification
# ──────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Проверка                                ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Port
if lsof -iTCP:1080 -sTCP:LISTEN &> /dev/null; then
    ok "Порт 1080 слушает"
else
    err "Порт 1080 не занят — проверь /tmp/singbox.err.log"
fi

# Real traffic
sleep 1
VPN_IP=$(curl -s -x http://127.0.0.1:1080 --max-time 10 https://api.ipify.org 2>/dev/null || echo "")
if [[ -n "$VPN_IP" ]]; then
    ok "Выходной IP через VPN: $VPN_IP"
    if [[ "$VPN_IP" == "$SERVER" ]]; then
        ok "IP совпадает с сервером VLESS → всё работает"
    fi
else
    warn "Не удалось проверить IP — смотри /tmp/singbox.err.log"
fi

# ──────────────────────────────────────────
# 10. Final
# ──────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Готово                                  ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Что дальше:"
echo "  1. source ~/.zshrc  (чтобы подхватить env в текущем терминале)"
echo "  2. Перезапусти VSCode — Claude Code возьмёт HTTPS_PROXY"
echo "  3. LaunchAgent стартует автоматически при логине"
echo ""
echo "Для браузера / Telegram включи системный SOCKS:"
echo "  networksetup -setsocksfirewallproxy \"Wi-Fi\" 127.0.0.1 1080"
echo "  networksetup -setsocksfirewallproxystate \"Wi-Fi\" on"
echo ""
echo "Аварийный откат: ~/Desktop/restore-vpn.sh"
echo "Логи: /tmp/singbox.log, /tmp/singbox.err.log"
echo ""
