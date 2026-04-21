# Первая установка с нуля — порядок действий

Это гайд для тех кто начинает с нуля: нет VPS, нет VPN, нет работающего Claude Code локально.

## Проблема курицы и яйца

Claude Code из РФ **не логинится без VPN** — Anthropic возвращает `403 Forbidden` для запросов с российских IP. А чтобы Claude помог тебе настроить VPN, он должен быть уже рабочим. Плюс на локальной машине (Windows) Claude Code может быть даже не установлен — а поставить npm-пакет без прокси из РФ не получится.

Платные публичные VPN для решения этой проблемы работают плохо: они кривые, падают, меняют IP, ломают авторизацию Anthropic.

## Правильный способ — Claude на VPS

Ставим Claude Code **сразу на VPS** (Anthropic пропускает запросы с non-RU IP без вопросов), оттуда Claude ведёт тебя по командам для локальной машины. Никакой временный VPN на локальной машине не нужен.

**Этот способ использовал автор репозитория. Работает даже с iPhone** — если нет ноутбука, через SSH-клиент Termius можно настроить всю инфраструктуру прямо с телефона.

### Что потребуется

- **VPS на non-RU IP** ([OVH Kimsufi](https://kimsufi.com/) ~670₽/мес и т.п.)
- **SSH-клиент**:
  - ПК/Mac — встроенный терминал (`ssh`) или [Termius](https://termius.com/) (удобнее, с синхронизацией ключей)
  - iPhone/Android — **Termius** (бесплатный, красивый, работает идеально)
- **Подписка Claude Pro** или API-ключ
- Оплата из РФ — [@platipomiru_sup_bot](https://t.me/platipomiru_sup_bot) для виртуальной карты (см. README)

### Шаги

1. **Арендуй VPS** с non-RU IP (Canada/Germany).

2. **SSH на VPS** — с ПК или с телефона через Termius:
   ```bash
   ssh root@IP_ТВОЕГО_VPS
   ```

3. **Поставь Claude Code на VPS** (Ubuntu/Debian):
   ```bash
   # Node.js если нет
   curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
   apt install -y nodejs
   # Claude Code
   npm install -g @anthropic-ai/claude-code
   ```

4. **Залогинься** прямо на VPS:
   ```bash
   claude auth login
   ```
   OAuth-ссылку открывай в любом браузере на любой машине — Anthropic проверяет IP **сервера** который делает API-запрос (это VPS, с non-RU IP → пропускает).

5. **Попроси Claude на VPS поднять 3x-ui** — он выполнит скилл [AndyShaman/3x-ui-skill](https://github.com/AndyShaman/3x-ui-skill), поднимет VLESS Reality сервер на этом же VPS. Получишь VLESS-ссылку.

6. **Попроси Claude на VPS дать команду для твоей локальной Windows/Mac.** Он покажет:
   ```powershell
   # Windows (PowerShell от администратора)
   iwr -useb https://raw.githubusercontent.com/DevKitRU/my-vpn-kit/main/windows/install.ps1 | iex
   ```
   или:
   ```bash
   # macOS (Terminal)
   curl -fsSL https://raw.githubusercontent.com/DevKitRU/my-vpn-kit/main/macos/install.sh | bash
   ```

7. **Выполни на локальной машине.** Скрипт попросит VLESS-ссылку из шага 5 — вставляй.

8. **Перезапусти VSCode на локальной машине** (если пользуешься Claude Code локально). Локальный Claude Code подхватит `HTTPS_PROXY=http://127.0.0.1:1080`.

### Почему это работает

- Anthropic блокирует по IP отправителя API-запроса. VPS в Канаде — IP легальный, блокировок нет.
- Оплату Claude Pro делаешь один раз — через любой способ (@platipomiru_sup_bot, карта знакомого и т.п.).
- Termius на iPhone позволяет настроить всю инфраструктуру прямо с телефона — ни ноутбук, ни Windows не нужны пока не поставишь клиент на них.

### Совет: SSH с VPS на локальную машину (для продвинутых)

Если хочешь совсем без копипаста — можешь включить **OpenSSH Server на локальной Windows/Mac**, тогда Claude на VPS через `ssh` выполняет команды у тебя сам. Сценарий:

1. На Windows: `Settings → Apps → Optional Features → Add → OpenSSH Server → Install`, затем `Start-Service sshd` и `Set-Service -Name sshd -StartupType Automatic`
2. На Mac: `System Settings → Sharing → Remote Login → On`
3. С VPS — настроить обратный SSH-туннель через тот же VPS (VPS имеет публичный IP) или использовать Tailscale/ZeroTier для mesh-соединения
4. Claude на VPS: `ssh user@твоя_локалка "powershell ..."` — и он сам всё выполняет

Это удобно если настраиваешь несколько машин подряд, но для одноразовой установки my-vpn-kit **копипаст через буфер Termius** проще.

Для копирования файлов между VPS и локальной машиной — в Termius встроенный **SFTP** (вкладка рядом с SSH). Можно тащить конфиги туда-сюда мышкой.

### Что делать если Claude Code на локальной машине тоже нужен

После шагов 1-7 ты получил:
- Свой VPS с VLESS ✓
- sing-box на локальной Windows/Mac ✓
- Переменные `HTTPS_PROXY=http://127.0.0.1:1080` в системе ✓

Чтобы поставить Claude Code локально:
```powershell
# Windows
npm install -g @anthropic-ai/claude-code
claude auth login
```
```bash
# Mac
npm install -g @anthropic-ai/claude-code
claude auth login
```

npm пойдёт через sing-box (env HTTPS_PROXY подхватывается), Anthropic увидит IP твоего VPS → залогинится без вопросов.

## Если нужен только VPN (без Claude Code)

Если тебе нужен VPN для браузера / Telegram / игр:

1. Поднять VPS + 3x-ui (через скилл AndyShaman или вручную)
2. Получить VLESS
3. Установить my-vpn-kit на свою платформу

В этом сценарии Claude Code на VPS тоже полезен (он всё настроит за тебя), но не обязателен. Можно руками по документации.

## Сколько это стоит

| Компонент | Цена |
|---|---|
| VPS (OVH Kimsufi, например) | ~670₽/мес |
| Shadowrocket (iOS) | $2.99 один раз (US App Store) |
| sing-box, WinSW, my-vpn-kit | бесплатно |

Итого: **около 670₽/месяц** за собственный VPN. Публичные VPN-подписки дороже (~500-1500₽/мес) и ломаются регулярно.

### Оплата зарубежных сервисов из РФ

Российские карты Visa/Mastercard за границей не работают. Для оплаты VPS OVH, подписки Claude Pro и прочего нужен обходной путь.

Я пользуюсь ботом **[@platipomiru_sup_bot](https://t.me/platipomiru_sup_bot)** в Telegram:

1. Говоришь сумму
2. Тебе выпускают виртуальную карту Visa/Mastercard на один платёж
3. Оплачиваешь зарубежный сервис обычным способом
4. Рубли списываются у бота по курсу + небольшая комиссия

Использовал много раз — OVH, Claude Pro, App Store. Работает. Другие сервисы (Easy Pay, Getsby, ВКоины) — не тестировал.

Апгрейд Shadowrocket в US App Store проще купить через знакомого/родственника с US-аккаунтом — одноразовая покупка $2.99.

## Если что-то пошло не так

- [troubleshooting.md](troubleshooting.md) — список известных симптомов и фиксов
- [github.com/DevKitRU/my-vpn-kit/issues](https://github.com/DevKitRU/my-vpn-kit/issues) — issue tracker
