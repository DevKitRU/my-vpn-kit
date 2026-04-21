# Пресеты конфигов sing-box

Готовые варианты routing-таблицы под разные сценарии. Выбираешь один, ставишь через установщик с флагом `-Preset <name>`:

```powershell
# Windows
iwr -useb https://.../install.ps1 | iex
# → при запросе выбери dev / gaming / minimalist
```

Во всех пресетах идентичная структура — меняются только правила `route.rules` (что через VPN, что direct).

## dev.json — для разработчика

**Что через VPN (заблокированное в РФ, нужно для работы):**
- Anthropic, Claude, OpenAI, ChatGPT
- GitHub (github.com, githubusercontent.com, Copilot)
- HuggingFace, Docker Hub
- Cloudflare, Cloudflare Access
- Google Gemini, Google AI Studio
- Perplexity, Vercel, Notion

**Что direct:**
- Всё остальное — российские сайты, Steam, соцсети, YouTube и т.д.

**Кому подходит:** основное время работаешь с AI API и западными dev-инструментами, в остальное время нужен обычный интернет с твоим реальным РФ IP (минимум задержки, русские сайты работают моментально).

## gaming.json — для геймера

**Что direct (чтобы регион был РФ):**
- Все `.ru/.рф/.su`
- `stalcraft.net`, `mail.ru`, `my.games`, `my.com`
- ВК (`vk.com`, `userapi.com`)
- Gaijin, Warface, War Thunder
- Xsolla
- Steam (`steampowered.com`, `steamcommunity.com`, CDN)
- Банки (`sberbank.com`, `tinkoff.com`, `alfabank.com`)
- Маркетплейсы (`ozon.com`, `wildberries.com`, `avito.com`)
- Госуслуги, Налог

**Что через VPN:**
- Всё остальное — Discord, YouTube, зарубежные сервисы

**Кому подходит:** играешь в STALCRAFT / Warface / игры Mail.ru или ВК, хочешь Steam-регион Россия, параллельно используешь Discord / YouTube / Twitch без замедления провайдера.

## minimalist.json — минимум вмешательства

**Что через VPN:**
- Только `anthropic.com`, `claude.ai`, `openai.com`, `chatgpt.com`

**Что direct:**
- Всё остальное (браузер, Telegram, игры, работа — идёт с твоего реального IP)

**Кому подходит:** VPN нужен только чтобы Claude Code не отваливался и ChatGPT работал. Хочешь максимальную скорость для всего остального и минимум вмешательства в трафик.

## Плейсхолдеры

Все пресеты содержат плейсхолдеры, которые подставляются при установке:

| Плейсхолдер | Откуда |
|---|---|
| `{{UUID}}` | UUID из VLESS-ссылки |
| `{{SERVER}}` | IP или домен VPS |
| `{{SERVER_PORT}}` | Порт (обычно 443) |
| `{{FLOW}}` | `flow` параметр (обычно `xtls-rprx-vision`) |
| `{{SNI}}` | `sni` параметр (обычно `www.yahoo.com`) |
| `{{FINGERPRINT}}` | `fp` параметр (обычно `chrome`) |
| `{{PUBLIC_KEY}}` | `pbk` параметр |
| `{{SHORT_ID}}` | `sid` параметр |

Установщик (`windows/install.ps1`, `macos/install.sh`) парсит твою VLESS-ссылку и подставляет значения автоматически.

## Как добавить свой домен в direct или VPN

1. Открой соответствующий пресет
2. Найди секцию `route.rules` — там есть массивы `domain_suffix` для `direct` и `vless-out`
3. Добавь свой домен в нужный массив
4. Сохрани файл
5. Перезапусти службу:
   ```powershell
   Restart-Service sing-box   # Windows
   launchctl kickstart -k gui/$(id -u)/com.singbox.vpn   # macOS
   ```

## Проверить конфиг перед запуском

```powershell
sing-box.exe check -c путь\к\конфигу.json
```
Если выходит `OK` без FATAL — конфиг валиден.
