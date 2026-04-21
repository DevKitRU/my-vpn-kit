# Первая установка с нуля — порядок действий

Это гайд для тех кто **начинает с нуля**: нет VPS, нет VPN, нет работающего Claude Code. Цель — за вечер сделать полностью свою инфраструктуру.

## Проблема курицы и яйца

Claude Code из РФ **не логинится без VPN** — Anthropic возвращает `403 Forbidden` для запросов с российских IP. А чтобы Claude Code помог тебе настроить VPN, он должен быть уже рабочим. Вот вариант решения:

## Правильный порядок

### Шаг 1 — временный публичный VPN

Чтобы установить Claude Code и залогиниться, нужен **любой рабочий прокси** сейчас. Варианты:

- **Временная подписка на платный VPN** (Hiddify / v2rayN с купленной подпиской) — хватает пары дней
- **Бесплатный публичный прокси** — нестабильно, но на логин может хватить
- **Коллега дал VLESS-ссылку на свой VPS** — самый быстрый путь

Важно: для работы Claude Code в РФ нужно **не просто VPN**, а чтобы **прокси был в OVH/датацентровом IP + Chrome TLS fingerprint** (это умеет sing-box/v2rayN/Hiddify через VLESS Reality).

### Шаг 2 — `claude auth login`

Запусти Claude Code через прокси из шага 1:

```bash
# Установи env для сессии
export HTTPS_PROXY=http://127.0.0.1:PORT_твоего_VPN
export HTTP_PROXY=http://127.0.0.1:PORT_твоего_VPN

# Логин
claude auth login
```

Anthropic через браузер откроет OAuth, нажми **«Authorize» ОДИН РАЗ** (второй клик инвалидирует код — известный баг).

Если видишь `SSL certificate verification failed` — значит временный VPN ставит свой root CA (подменяет сертификаты). Вырубить такую фичу в настройках VPN.

### Шаг 3 — свой VPS и VLESS

Теперь у тебя работающий Claude Code. Поднимай собственную инфраструктуру:

- Арендуй VPS ([OVH Kimsufi](https://kimsufi.com/), [Hetzner](https://www.hetzner.com/cloud) — любой с non-RU IP)
- Поставь 3x-ui через скилл [AndyShaman/3x-ui-skill](https://github.com/AndyShaman/3x-ui-skill) — попроси Claude Code выполнить этот скилл, он сам поднимет сервер
- Получи свою VLESS-ссылку из 3x-ui панели

### Шаг 4 — my-vpn-kit (этот репо)

Теперь ставим клиента на свою ОС:

**Windows:**
```powershell
iwr -useb https://raw.githubusercontent.com/DevKitRU/my-vpn-kit/main/windows/install.ps1 | iex
```

**macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/DevKitRU/my-vpn-kit/main/macos/install.sh | bash
```

Скрипт попросит VLESS-ссылку из шага 3 и подставит её. Установит sing-box как службу с автозапуском.

### Шаг 5 — рестарт VSCode + проверка

После того как `install.sh/install.ps1` отработал — **закрой и открой VSCode** (не просто окно, а весь процесс). Иначе текущий Claude Code продолжит идти через временный VPN из шага 1.

После рестарта Claude Code подхватит новый `HTTPS_PROXY=http://127.0.0.1:1080` (sing-box). Проверь:

```bash
# Должен показать IP твоего VPS
curl -x http://127.0.0.1:1080 https://api.ipify.org
```

### Шаг 6 — убрать временный VPN из шага 1

Теперь можно:
- Отменить подписку на платный публичный VPN
- Закрыть / удалить Hiddify / v2rayN — если ставил только ради Claude Code

Твоя инфраструктура — только ты и твой VPS.

## Если Claude Code не был нужен — обратный порядок

Если тебе **не нужен Claude Code** (только VPN для браузера / Telegram / игр), пропусти шаги 1-2. Просто:

1. Поднять VPS (скилл 3x-ui-skill)
2. Получить VLESS
3. Установить my-vpn-kit

Для ручной установки без Claude Code — см. README соответствующей платформы (`windows/README.md`, `macos/README.md`), там есть пошаговые инструкции без автоматизации.

## Сколько это стоит

| Компонент | Цена |
|---|---|
| VPS (OVH Kimsufi, например) | ~670₽/мес |
| Shadowrocket (iOS) | $2.99 один раз (US App Store) |
| sing-box, WinSW, my-vpn-kit | бесплатно |

Итого: **около 670₽/месяц** за собственный VPN. Публичные VPN-подписки дороже (~500-1500₽/мес) и ломаются регулярно.

## Если что-то пошло не так

- [troubleshooting.md](troubleshooting.md) — список известных симптомов и фиксов
- [github.com/DevKitRU/my-vpn-kit/issues](https://github.com/DevKitRU/my-vpn-kit/issues) — issue tracker
