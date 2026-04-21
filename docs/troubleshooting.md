# Troubleshooting — разбор частых проблем

Симптомы и проверенные решения. Всё из реального опыта настройки (и наших собственных граблей).

---

## Общие (любая ОС)

### Claude Code / API Anthropic возвращает `403 Forbidden`

**Причина:** прокси не подхватился или не работает для текущего процесса.

**Диагностика:**
```bash
# macOS/Linux
echo $HTTPS_PROXY
curl -x $HTTPS_PROXY https://api.anthropic.com/ -I

# Windows
echo $env:HTTPS_PROXY
curl.exe -x $env:HTTPS_PROXY https://api.anthropic.com/ -I
```

**Решение:**
- Если `HTTPS_PROXY` пустой → переменная не установлена или не подхвачена. Перезапусти терминал / VSCode.
- Если прокси установлен но `curl` таймаутит → sing-box лежит. Проверь статус службы.
- Если `curl` проходит но Claude Code всё равно 403 → **рестарт VSCode** (env читается только при старте процесса).

### Прокси работает, но некоторые приложения игнорируют его

**Причина:** разные приложения по-разному читают настройки прокси:

| Приложение | Что читает |
|---|---|
| Claude Code (CLI), curl, Node.js fetch (с `--use-proxy`) | env `HTTPS_PROXY` |
| Chrome, Edge, Opera | System proxy (реестр Windows / macOS Network Prefs) |
| Telegram Desktop | System proxy ИЛИ собственный прокси в Settings |
| Telegram Mini App (WebView2 / WKWebView) | Только system proxy |
| Discord Desktop (Electron) | `--proxy-server` флаг + system proxy (с оговорками) |
| Steam клиент | Игнорирует system proxy (идёт напрямую) |
| Игры через Steam | Зависит от движка — обычно напрямую |
| Firefox | Свои настройки в `about:preferences` |

**Решение:** если нужно чтобы всё шло через VPN — использовать **TUN-режим** в sing-box (Windows). На macOS — системный SOCKS через Network Preferences.

### `ALL_PROXY=socks5://...` не работает с Node.js

**Причина:** Node.js fetch/https не понимают `ALL_PROXY` со схемой `socks5://`.

**Решение:** использовать `HTTPS_PROXY=http://127.0.0.1:1080` (схема `http://`, не `socks5://`) — sing-box mixed-режим принимает HTTP CONNECT на том же порту.

---

## Windows

### Служба `sing-box` в Stopped, не стартует

```powershell
Get-Service sing-box
Restart-Service sing-box
Get-Content C:\ProgramData\sing-box\logs\sing-box.err.log -Tail 30
```

Что смотреть в логах:
- `FATAL ... decode config` → конфиг битый. Запустить вручную: `sing-box.exe check -c путь\к\singbox.json`
- `FATAL ... detour to an empty direct outbound` → в DNS-сервере `"detour": "direct"`. Убрать.
- `FATAL ... missing route.default_domain_resolver` → sing-box 1.12+ требует это поле в `route`. Добавить `"default_domain_resolver": "dns-direct"`.
- `listen tcp 127.0.0.1:1080: bind: Only one usage...` → порт 1080 занят (другой sing-box/Hiddify/v2rayN). Остановить или поменять порт в конфиге.

### TUN-интерфейс `singbox1` не появляется

**Причина 1:** Windows Defender блокирует wintun-драйвер.
**Решение:** временно выключить real-time protection, запустить службу, включить обратно. Если помогло — добавить `C:\ProgramData\sing-box\` в исключения Defender.

**Причина 2:** Служба стартует не от LocalSystem.
**Решение:** проверить XML для WinSW — там не должно быть `<serviceaccount>`. По умолчанию WinSW ставит от LocalSystem, у которого есть admin-права для TUN.

### Telegram Mini App висит на «Загрузка...»

**Причина:** Mini App использует WebView2 который читает system proxy. Если твой mini app на `*.ru` и пропущен через `.ru → direct` — Cloudflare иногда режет RU-IP.

**Решение:** добавить конкретный домен mini app в правило **перед** `.ru → direct`:

```json
{
  "domain_suffix": ["bot.твоёимя.ru"],
  "action": "route",
  "outbound": "vless-out"
}
```

Потом `Restart-Service sing-box`.

### Discord Desktop зависает на «Starting...»

**Причина:** Electron + системный прокси HTTP конфликтуют. Discord пытается QUIC (UDP) через HTTP-прокси → таймаут.

**Решения (по порядку):**

1. **Через TUN-режим** (рекомендуется) — TUN перехватывает весь трафик прозрачно, Discord не заметит что идёт через VPN. Должно работать из коробки.

2. **Через флаги запуска Discord:**
   ```powershell
   Start-Process "C:\Users\USER\AppData\Local\Discord\app-*\Discord.exe" `
     -ArgumentList '--proxy-server=socks5://127.0.0.1:1080', '--disable-quic', '--no-sandbox'
   ```
   (Подставить свой путь к `Discord.exe` и имя пользователя)

3. **Если ничего не помогает — Discord Web** в браузере: `https://discord.com/channels/@me`. Работает всегда.

### Steam показывает регион Канада / США

**Причина:** Steam клиент идёт через TUN вместе со всеми, видит канадский IP.

**Решение:** добавить Steam-домены в direct-список чтобы они шли напрямую с RU IP:

```json
{
  "domain_suffix": [
    "steampowered.com", "steamcommunity.com", "steam-chat.com",
    "steamgames.com", "steamstatic.com", "steamcontent.com",
    "steamserver.net"
  ],
  "action": "route",
  "outbound": "direct"
}
```

Эти правила уже включены в `gaming.json` пресет.

### STALCRAFT / Mail.ru Games не логинятся

**Причина:** российские сервисы на иностранных TLD (`stalcraft.net`, `mail.ru`, `my.games`) идут через VPN по default, Mail.ru банит не-RU IP → отказ авторизации.

**Решение:** в `domain_suffix` direct-списка добавить:

```
"stalcraft.net", "mail.ru", "my.games", "my.com", "xsolla.com", "gaijin.net"
```

Эти правила уже включены в `gaming.json` пресет.

---

## macOS

### LaunchAgent загружен, но sing-box сразу падает

**Симптом:** `launchctl list | grep singbox` показывает `"PID" = "-"` и exit code не 0.

**Диагностика:**
```bash
tail -30 /tmp/singbox.err.log
```

Частые причины:
- `FATAL start dns/udp[local-dns]: detour to an empty direct outbound` → у DNS-сервера стоит `"detour": "direct"`. Убрать.
- `missing route.default_domain_resolver` → sing-box 1.12+ требует в route. Добавить.
- `invalid public_key` → ключ Reality битый. Проверь что скопировал целиком без переносов.

### `sing-box: command not found` после `brew install`

**Причина:** PATH не включает brew-пути.

**Решение** для Apple Silicon — добавь в `~/.zshrc`:
```bash
export PATH="/opt/homebrew/bin:$PATH"
```
Потом `source ~/.zshrc`.

Для Intel Mac — `/usr/local/bin/sing-box` и PATH обычно уже настроен.

### Telegram не читает env `HTTPS_PROXY`

**Причина:** Нативные Mac-приложения не читают env-переменные (только CLI-утилиты).

**Решения:**
1. Включить **системный SOCKS** через System Preferences → Network → Wi-Fi → Advanced → Proxies → SOCKS `127.0.0.1:1080`.
2. Или прописать прокси в самом Telegram: Настройки → Данные и память → Прокси.

### Интернет пропал, не могу открыть ничего

**План восстановления:**

1. Запусти `~/Desktop/restore-vpn.sh` — он отключит sing-box и системный SOCKS.
2. Проверь браузер — должен работать.
3. Дальше разбирайся с sing-box логами (`/tmp/singbox.err.log`), причина не в сети — в конфиге.

---

## iOS / Shadowrocket

### SSL certificate verification failed на всех сайтах

**Причина:** включены **Модули** (Общее → Модули) или **Force All Networks** (Тоннели → Туннель).

**Решение:**
1. Настройки → Сброс → Сброс (сервера остаются)
2. Дальше не включай модули и Force All Networks.

Подробнее: [ios/README.md](../ios/README.md).

### Shadowrocket вылетает при запуске

**Причина:** обычно после включения опасной настройки (модули / Force All / цепь прокси).

**Решение:** Настройки → Сброс → Сброс.

---

## Выбор VPS

### Сервер с VPN работает, но medium/slow скорость

**Диагностика:**
```bash
# На Mac
curl -x http://127.0.0.1:1080 -w "@-" -o /dev/null -s https://speed.cloudflare.com/__down?bytes=10000000 <<'EOF'
    time_total:  %{time_total}s
    speed:       %{speed_download} B/s
EOF
```

**Причины и решения:**
- Сервер далеко (США при тебе в РФ) → выбрать ближе (Европа, Канада)
- Перегружен процессор VPS → `top` на сервере
- Провайдер РФ замедляет TCP → Reality с TLS 1.3 обычно не замедляется, но бывает

### Сервер лежит, VPN не работает

**Проверка с VPS напрямую (без клиента):**
```bash
ssh sergey@твой_VPS_IP
systemctl status x-ui    # 3x-ui сервис
tail -f /usr/local/x-ui/x-ui.log
```

Если x-ui не запущен — `systemctl restart x-ui`.

---

## Не нашёл свою проблему

- Поищи в issues репозитория (когда будет): `github.com/DevKitRU/my-vpn-kit/issues`
- Проверь свежие логи sing-box — там обычно сразу видно что не так
- Не забудь что **один из VPN должен быть жив** пока ты настраиваешь — иначе Claude Code не поможет дебажить
