@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title 彻底清理用户级系统代理
REM ============================================================
REM  Clean Proxy Environment Script
REM  Last updated: 2026-07-27
REM ============================================================

echo ========================================================
echo     彻底清理系统/用户环境变量代理
echo ========================================================
echo;

set "USER_DIR=%USERPROFILE%"
set "BRIDGE_DIR=%USER_DIR%\.cli-proxy-api"
set "PYTHON_EXE=%USER_DIR%\.workbuddy\binaries\python\versions\3.13.12\python.exe"
set "ENV_PY=%BRIDGE_DIR%\proxy_env.py"

echo [!] 正在清理注册表中的环境变量并广播...

if exist "%PYTHON_EXE%" (
    if exist "%ENV_PY%" (
        "%PYTHON_EXE%" "%ENV_PY%" clean
    ) else (
        call :CLEAN_REG_ENV
    )
) else (
    call :CLEAN_REG_ENV
)

echo;
echo ========================================================
echo  [v] 清理完成！
echo;
echo  HTTPS_PROXY / HTTP_PROXY / NO_PROXY 已被彻底移除。
echo  系统环境已恢复干净，不会影响 WorkBuddy 和其他应用的联网。
echo ========================================================
echo;
pause
endlocal
exit /b 0

:CLEAN_REG_ENV
reg delete "HKCU\Environment" /v HTTPS_PROXY /f >nul 2>&1
reg delete "HKCU\Environment" /v HTTP_PROXY /f >nul 2>&1
reg delete "HKCU\Environment" /v NO_PROXY /f >nul 2>&1
call :BROADCAST_ENV
echo [v] 注册表代理键值删除完毕。
exit /b 0

:BROADCAST_ENV
set "PS_SCRIPT=%TEMP%\broadcast_env.ps1"
(
echo $code = '[DllImport("user32.dll", SetLastError = true)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);'
echo $type = Add-Type -MemberDefinition $code -Name 'Win32' -Namespace 'Native' -PassThru
echo $result = [UIntPtr]::Zero
echo $type::SendMessageTimeout([IntPtr]0xffff, 0x001A, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$result^)
) > "%PS_SCRIPT%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" >nul 2>&1
del "%PS_SCRIPT%" >nul 2>&1
exit /b 0