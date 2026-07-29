@echo off
title Clean Proxy Env

echo ========================================
echo   Clean Proxy Environment Variables
echo ========================================
echo.

"C:\Users\dongdong\.workbuddy\binaries\python\versions\3.13.12\python.exe" "C:\Users\dongdong\.cli-proxy-api\proxy_env.py" clean
if errorlevel 1 (
    echo [!] Python failed, trying reg delete...
    reg delete "HKCU\Environment" /v HTTPS_PROXY /f >nul 2>&1
    reg delete "HKCU\Environment" /v HTTP_PROXY /f >nul 2>&1
    reg delete "HKCU\Environment" /v NO_PROXY /f >nul 2>&1
    echo       Done
)

echo.
echo ========================================
echo  [OK] Proxy env vars cleaned!
echo ========================================
echo.
pause
