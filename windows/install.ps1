# my-vpn-kit — Windows installer for sing-box
# https://github.com/DevKitRU/my-vpn-kit
#
# Использование:
#   iwr -useb https://raw.githubusercontent.com/DevKitRU/my-vpn-kit/main/windows/install.ps1 | iex
#   → спросит какой пресет использовать: default / dev / gaming / minimalist

param(
    [ValidateSet("default","dev","gaming","minimalist","")]
    [string]$Preset = ""
)

#Requires -Version 5.1

$ErrorActionPreference = "Stop"

# ──────────────────────────────────────────
# 0. Admin rights check
# ──────────────────────────────────────────
$principal = [Security.Principal.WindowsPrincipal]::new(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[!] sing-box TUN требует права администратора." -ForegroundColor Yellow
    Write-Host "Перезапускаю скрипт через UAC..." -ForegroundColor Yellow
    $installUrl = "https://raw.githubusercontent.com/DevKitRU/my-vpn-kit/main/windows/install.ps1"
    if ($PSCommandPath) {
        $relaunchArgs = @("-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"")
        if ($Preset) { $relaunchArgs += @("-Preset", $Preset) }
    } else {
        if ($Preset) {
            $command = "& ([scriptblock]::Create((irm '$installUrl'))) -Preset '$Preset'"
        } else {
            $command = "irm '$installUrl' | iex"
        }
        $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
        $relaunchArgs = @("-NoExit", "-ExecutionPolicy", "Bypass", "-EncodedCommand", $encodedCommand)
    }
    Start-Process powershell -Verb RunAs -ArgumentList $relaunchArgs
    exit
}

Write-Host "`n╔══════════════════════════════════════════╗"
Write-Host "║   my-vpn-kit — sing-box Windows setup    ║"
Write-Host "╚══════════════════════════════════════════╝`n"

# ──────────────────────────────────────────
# 0.5. Preflight — предупредить о других VPN
# ──────────────────────────────────────────
$conflictingVpn = @()
foreach ($name in @("Hiddify","v2rayN","xray","sing-box")) {
    if (Get-Process -Name $name -ErrorAction SilentlyContinue) {
        $conflictingVpn += $name
    }
}
# Kaspersky VPN — отдельно, по имени адаптера
$kavpn = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object InterfaceDescription -match "Kaspersky VPN"
if ($kavpn) { $conflictingVpn += "Kaspersky VPN" }

if ($conflictingVpn.Count -gt 0) {
    Write-Host "[!] Обнаружены работающие VPN-клиенты:" -ForegroundColor Yellow
    foreach ($v in $conflictingVpn) { Write-Host "    - $v" -ForegroundColor Yellow }
    Write-Host ""
    Write-Host "    sing-box может конфликтовать по портам и TUN-интерфейсу." -ForegroundColor Yellow
    Write-Host "    Рекомендую: закрой другие VPN (оставь хотя бы один активным)," -ForegroundColor Yellow
    Write-Host "    дождись установки sing-box, потом убери старые." -ForegroundColor Yellow
    Write-Host ""
    $answer = Read-Host "Продолжить установку sing-box параллельно? [y/N]"
    if ($answer -ne 'y') {
        Write-Host "Остановлено. Закрой другие VPN и запусти скрипт заново." -ForegroundColor Cyan
        exit 0
    }
}

# ──────────────────────────────────────────
# 1. Get VLESS from user
# ──────────────────────────────────────────
Write-Host "Вставь твою VLESS-ссылку из 3x-ui (начинается с vless://)" -ForegroundColor Cyan
Write-Host "Пример: vless://abc-def-123@1.2.3.4:443?security=reality&pbk=...&sid=...#name`n"
$vless = Read-Host "VLESS"

# Очистка от whitespace и CR/LF (частая причина ошибок парсинга при копипасте)
$vless = $vless.Trim() -replace "`r", "" -replace "`n", "" -replace "`t", ""

if (-not $vless.StartsWith("vless://")) {
    Write-Host "[x] Это не VLESS-ссылка. Должна начинаться с vless://" -ForegroundColor Red
    exit 1
}

# ──────────────────────────────────────────
# 2. Parse VLESS URI
# ──────────────────────────────────────────
# Формат: vless://UUID@HOST:PORT?param1=val1&param2=val2#name
$parsed = @{}

if ($vless -match '^vless://([^@]+)@([^:]+):(\d+)\?([^#]+)') {
    $parsed.uuid         = $matches[1]
    $parsed.server       = $matches[2]
    $parsed.server_port  = [int]$matches[3]
    $queryString         = $matches[4]
} else {
    Write-Host "[x] Не смог распарсить VLESS-ссылку. Проверь формат." -ForegroundColor Red
    exit 1
}

foreach ($pair in $queryString.Split('&')) {
    $kv = $pair.Split('=', 2)
    if ($kv.Length -eq 2) {
        $parsed[$kv[0]] = [System.Net.WebUtility]::UrlDecode($kv[1])
    }
}

# Проверяем что это Reality VLESS
if ($parsed.security -ne 'reality') {
    Write-Host "[x] Этот скилл рассчитан на VLESS Reality (security=reality)." -ForegroundColor Red
    Write-Host "    У тебя security=$($parsed.security). Если это TLS — скилл для Reality не подойдёт." -ForegroundColor Red
    exit 1
}

foreach ($key in @("uuid", "server", "server_port", "pbk", "sni")) {
    if (-not $parsed[$key]) {
        Write-Host "[x] В VLESS-ссылке не хватает параметра: $key" -ForegroundColor Red
        exit 1
    }
}
if (-not $parsed.flow) { $parsed.flow = "xtls-rprx-vision" }
if (-not $parsed.fp)   { $parsed.fp = "chrome" }
if (-not $parsed.sid)  { $parsed.sid = "" }

Write-Host "[+] VLESS распарсен:" -ForegroundColor Green
Write-Host "    server: $($parsed.server):$($parsed.server_port)"
Write-Host "    sni:    $($parsed.sni)"
Write-Host "    flow:   $($parsed.flow)`n"

# ──────────────────────────────────────────
# 3. Workdir + download sing-box + WinSW
# ──────────────────────────────────────────
$workDir = "C:\ProgramData\sing-box"
if (Test-Path $workDir) {
    Write-Host "[!] Папка $workDir уже есть. Если это предыдущая установка — удали и запусти снова." -ForegroundColor Yellow
    $answer = Read-Host "Продолжить (перезапишет файлы)? [y/N]"
    if ($answer -ne 'y') { exit }
} else {
    New-Item -Path $workDir -ItemType Directory -Force | Out-Null
}
Set-Location $workDir

# sing-box
$sbVersion = "1.13.8"
Write-Host "[.] Качаю sing-box $sbVersion..." -NoNewline
$sbUrl = "https://github.com/SagerNet/sing-box/releases/download/v$sbVersion/sing-box-$sbVersion-windows-amd64.zip"
Invoke-WebRequest -Uri $sbUrl -OutFile "$workDir\singbox.zip" -UseBasicParsing
Expand-Archive -Path "$workDir\singbox.zip" -DestinationPath $workDir -Force
Move-Item -Path "$workDir\sing-box-$sbVersion-windows-amd64\sing-box.exe" -Destination $workDir -Force
Remove-Item -Recurse -Path "$workDir\sing-box-$sbVersion-windows-amd64"
Remove-Item -Path "$workDir\singbox.zip"
Write-Host " OK" -ForegroundColor Green

# WinSW
$winswVersion = "2.12.0"
Write-Host "[.] Качаю WinSW $winswVersion..." -NoNewline
$winswUrl = "https://github.com/winsw/winsw/releases/download/v$winswVersion/WinSW-x64.exe"
Invoke-WebRequest -Uri $winswUrl -OutFile "$workDir\sing-box-service.exe" -UseBasicParsing
Write-Host " OK" -ForegroundColor Green

# ──────────────────────────────────────────
# 4. Select preset + download + substitute
# ──────────────────────────────────────────
if (-not $Preset) {
    Write-Host ""
    Write-Host "Какой пресет маршрутизации использовать?" -ForegroundColor Cyan
    Write-Host "  default      — стандартный split: РФ direct, остальное через VPN"
    Write-Host "  dev          — только AI и dev-сервисы (Claude, OpenAI, GitHub) через VPN"
    Write-Host "  gaming       — РФ-игры direct, зарубежное через VPN"
    Write-Host "  minimalist   — только Anthropic+OpenAI через VPN, всё остальное direct"
    $Preset = (Read-Host "Пресет [default/dev/gaming/minimalist] (default)").ToLower()
    if (-not $Preset) { $Preset = "default" }
}

$presetFile = if ($Preset -eq "default") { "singbox-template.json" } else { "presets/$Preset.json" }
$tplUrl = "https://raw.githubusercontent.com/DevKitRU/my-vpn-kit/main/shared/$presetFile"

Write-Host "[.] Генерирую конфиг из пресета '$Preset'..." -NoNewline
$config = (Invoke-WebRequest -Uri $tplUrl -UseBasicParsing).Content

$config = $config.Replace("{{UUID}}",        $parsed.uuid)
$config = $config.Replace("{{SERVER}}",      $parsed.server)
$config = $config.Replace("{{SERVER_PORT}}", "$($parsed.server_port)")
$config = $config.Replace("{{PUBLIC_KEY}}",  $parsed.pbk)
$config = $config.Replace("{{SHORT_ID}}",    $parsed.sid)
$config = $config.Replace("{{SNI}}",         $parsed.sni)
$config = $config.Replace("{{FLOW}}",        $parsed.flow)
$config = $config.Replace("{{FINGERPRINT}}", $parsed.fp)

$config | Set-Content "$workDir\singbox.json" -Encoding UTF8

# Валидация
& "$workDir\sing-box.exe" check -c "$workDir\singbox.json" 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host " FAIL" -ForegroundColor Red
    Write-Host "    Конфиг sing-box не прошёл проверку. Запусти вручную и смотри ошибку:" -ForegroundColor Red
    Write-Host "    & `"$workDir\sing-box.exe`" check -c `"$workDir\singbox.json`"" -ForegroundColor Red
    exit 1
}
Write-Host " OK" -ForegroundColor Green

# ──────────────────────────────────────────
# 5. WinSW XML
# ──────────────────────────────────────────
$xml = @"
<service>
  <id>sing-box</id>
  <name>sing-box VPN</name>
  <description>sing-box VPN with TUN mode (my-vpn-kit)</description>
  <executable>$workDir\sing-box.exe</executable>
  <arguments>run -c "$workDir\singbox.json"</arguments>
  <workingdirectory>$workDir</workingdirectory>
  <logpath>$workDir\logs</logpath>
  <log mode="roll-by-size">
    <sizeThreshold>10240</sizeThreshold>
    <keepFiles>2</keepFiles>
  </log>
  <startmode>Automatic</startmode>
  <onfailure action="restart" delay="10 sec"/>
</service>
"@
$xml | Set-Content "$workDir\sing-box-service.xml" -Encoding UTF8

# ──────────────────────────────────────────
# 6. Install + start service
# ──────────────────────────────────────────
Write-Host "[.] Устанавливаю Windows Service..." -NoNewline

# Если служба уже есть — удалить
if (Get-Service -Name "sing-box" -ErrorAction SilentlyContinue) {
    Stop-Service -Name "sing-box" -Force -ErrorAction SilentlyContinue
    & "$workDir\sing-box-service.exe" uninstall | Out-Null
    Start-Sleep -Seconds 2
}

& "$workDir\sing-box-service.exe" install | Out-Null
Start-Service -Name "sing-box"
Start-Sleep -Seconds 3
Write-Host " OK" -ForegroundColor Green

# ──────────────────────────────────────────
# 7. Env vars for Claude Code
# ──────────────────────────────────────────
foreach ($var in "HTTPS_PROXY","HTTP_PROXY","https_proxy","http_proxy") {
    [Environment]::SetEnvironmentVariable($var, "http://127.0.0.1:1080", "User")
}
Write-Host "[+] HTTPS_PROXY=http://127.0.0.1:1080 (для Claude Code)`n" -ForegroundColor Green

# ──────────────────────────────────────────
# 8. Verify
# ──────────────────────────────────────────
Write-Host "╔══════════════════════════════════════════╗"
Write-Host "║   Проверка                                ║"
Write-Host "╚══════════════════════════════════════════╝`n"

# Service
$svc = Get-Service -Name "sing-box"
Write-Host "Служба sing-box: $($svc.Status)" -ForegroundColor $(if ($svc.Status -eq "Running") { "Green" } else { "Red" })

# TUN
$tun = Get-NetAdapter | Where-Object { $_.InterfaceDescription -match 'sing-tun' } | Select-Object -First 1
if ($tun) {
    Write-Host "TUN интерфейс: $($tun.Name) ($($tun.Status))" -ForegroundColor Green
} else {
    Write-Host "TUN интерфейс: не поднялся" -ForegroundColor Red
}

# Real traffic test
try {
    $myIp = (Invoke-WebRequest -Uri "https://api.ipify.org" -Proxy "http://127.0.0.1:1080" -UseBasicParsing -TimeoutSec 10).Content.Trim()
    Write-Host "Выходной IP через VPN: $myIp" -ForegroundColor Green
    if ($myIp -eq $parsed.server) {
        Write-Host "→ IP совпадает с сервером VLESS. Всё работает." -ForegroundColor Green
    }
} catch {
    Write-Host "[!] Не удалось проверить IP — смотри логи: $workDir\logs\sing-box.err.log" -ForegroundColor Yellow
}

# ──────────────────────────────────────────
# 9. Final message
# ──────────────────────────────────────────
Write-Host "`n╔══════════════════════════════════════════╗"
Write-Host "║   Готово                                  ║"
Write-Host "╚══════════════════════════════════════════╝`n"

Write-Host "!!! ВАЖНО для Claude Code: закрой VSCode ПОЛНОСТЬЮ (не просто окно, а File → Exit) и открой заново." -ForegroundColor Yellow
Write-Host "    Переменные среды HTTPS_PROXY читаются процессом ТОЛЬКО при старте — текущий Claude Code их не увидит." -ForegroundColor Yellow
Write-Host ""

Write-Host "Что дальше:"
Write-Host "  1. Рестарт VSCode (см. выше, красный текст)"
Write-Host "  2. Если пользовался Hiddify/v2rayN — можешь их закрыть, больше не нужны"
Write-Host "  3. Служба sing-box стартует автоматически при включении компа"
Write-Host "  4. Логи: $workDir\logs\"
Write-Host "  5. Диагностика: скачай windows/tools/check-vpn.bat из репо"
Write-Host ""
Write-Host "Управление:"
Write-Host "  Get-Service sing-box       # статус"
Write-Host "  Restart-Service sing-box   # перечитать конфиг"
Write-Host "  Stop-Service sing-box      # временно выключить"
Write-Host ""
Write-Host "Если что-то не работает — https://github.com/DevKitRU/my-vpn-kit/blob/main/docs/troubleshooting.md"
Write-Host ""
