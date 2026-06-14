# VERIFICATION

Что проверить перед финалом.

## Docs-only

```bash
git diff --check
./scripts/check-ai-context.sh .
```

## Shell

```bash
bash -n macos/install.sh
```

## PowerShell

Если `pwsh` установлен:

```bash
pwsh -NoProfile -Command '$null = [System.Management.Automation.PSParser]::Tokenize((Get-Content -Raw windows/install.ps1), [ref]$null)'
```

Если `pwsh` не установлен, не утверждай что Windows installer проверен полностью.

## JSON configs

Raw templates contain unquoted `{{SERVER_PORT}}`, so validate after substituting safe dummy values:

```bash
python3 - <<'PY'
import json
from pathlib import Path

values = {
    "{{UUID}}": "00000000-0000-0000-0000-000000000000",
    "{{SERVER}}": "example.com",
    "{{SERVER_PORT}}": "443",
    "{{FLOW}}": "xtls-rprx-vision",
    "{{SNI}}": "example.com",
    "{{FINGERPRINT}}": "chrome",
    "{{PUBLIC_KEY}}": "placeholder-public-key",
    "{{SHORT_ID}}": "",
}

for path in [
    Path("shared/singbox-template.json"),
    Path("shared/presets/dev.json"),
    Path("shared/presets/gaming.json"),
    Path("shared/presets/minimalist.json"),
]:
    text = path.read_text(encoding="utf-8")
    for old, new in values.items():
        text = text.replace(old, new)
    json.loads(text)
    print(f"ok {path}")
PY
```

## Safety checklist

- Реальные VLESS-ссылки, IP, UUID, keys не попали в diff.
- Установщики не запускались как побочный эффект docs-задачи.
- Если менялись presets, объяснено влияние на routing.
- В `SESSION_SUMMARY.md` записано, что изменилось.
