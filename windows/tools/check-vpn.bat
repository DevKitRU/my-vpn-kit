@echo off
rem check-vpn.bat — диагностика VPN-схемы my-vpn-kit на Windows
rem Показывает все ключевые точки одним окном:
rem   - служба sing-box
rem   - TUN интерфейс
rem   - слушающие порты
rem   - реальный IP через прокси и без
rem   - 4 типовых сайта: RU direct / VPN

chcp 65001 >nul
cls
echo ============================================
echo   my-vpn-kit VPN check
echo ============================================
echo.

echo [1] Service sing-box:
powershell -NoProfile -Command "Get-Service sing-box -ErrorAction SilentlyContinue | Format-Table Name, Status, StartType -AutoSize"

echo [2] TUN interface:
powershell -NoProfile -Command "Get-NetAdapter | Where-Object InterfaceDescription -match 'sing-tun' | Format-Table Name, Status, InterfaceDescription -AutoSize"

echo [3] Port 1080 listening:
netstat -an | findstr LISTENING | findstr "127.0.0.1:1080"
if errorlevel 1 echo    PORT DOWN - sing-box not listening on 1080
echo.

echo [4] IP direct (no proxy):
curl.exe -s --max-time 5 --noproxy "*" https://api.ipify.org
echo.

echo [5] IP via sing-box (should be your VPS IP):
curl.exe -s --max-time 8 -x http://127.0.0.1:1080 https://api.ipify.org
echo.
echo.

echo [6] anthropic.com (should go via VPN):
curl.exe -sI --max-time 8 -x http://127.0.0.1:1080 https://api.anthropic.com/ -o NUL -w "    http=%%{http_code} time=%%{time_total}s\n"

echo [7] yandex.ru (should go direct by rule):
curl.exe -sI --max-time 5 -x http://127.0.0.1:1080 https://yandex.ru/ -o NUL -w "    http=%%{http_code} time=%%{time_total}s\n"

echo [8] Registry system proxy:
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer 2>nul | findstr ProxyServer
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable 2>nul | findstr ProxyEnable

echo [9] Env HTTPS_PROXY (user level):
powershell -NoProfile -Command "[Environment]::GetEnvironmentVariable('HTTPS_PROXY', 'User')"

echo.
echo ============================================
echo   Service management:
echo     Restart-Service sing-box    (reload config)
echo     Get-Service sing-box        (status)
echo     tail logs C:\ProgramData\sing-box\logs\
echo ============================================
pause
