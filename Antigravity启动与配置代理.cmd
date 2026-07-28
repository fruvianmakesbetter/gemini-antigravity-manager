@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title Antigravity 启动与配置代理
REM ============================================================
REM  Antigravity Launch & Set Proxy Script (Isolated Process)
REM  Last updated: 2026-07-27
REM ============================================================

echo ========================================================
echo     Antigravity 启动与登录工具 (脱离独立启动版)
echo ========================================================
echo;

set "USER_DIR=%USERPROFILE%"
set "AG_EXE=%USER_DIR%\AppData\Local\Programs\antigravity\Antigravity.exe"
set "BRIDGE_DIR=%USER_DIR%\.cli-proxy-api"
set "START_AG_VBS=%BRIDGE_DIR%\start_ag.vbs"

REM === 1. 检查主程序 ===
if not exist "%AG_EXE%" (
    echo [X] 未找到 Antigravity 主程序！
    pause
    exit /b 1
)

REM === 2. 检查 Google 网络连通性 ===
echo [1/3] 检查 Google 网络连通性...
where curl >nul 2>&1
if errorlevel 1 (
    echo [X] 未找到 curl 命令，无法检测网络连通性！
    echo     请确认系统已包含 curl.exe。
    echo;
    pause
    exit /b 1
)

curl -s --max-time 10 --proxy http://127.0.0.1:7890 https://www.google.com/generate_204 >nul 2>&1
if errorlevel 1 (
    echo [X] 无法通过代理连接 Google！
    (
    echo MsgBox "网络检测失败：无法通过代理端口 7890 连接 Google！" ^& vbCrLf ^& vbCrLf ^& "请检查：" ^& vbCrLf ^& "1. 代理软件（如 FlClash 等）是否正在运行" ^& vbCrLf ^& "2. 代理端口是否设置为 7890" ^& vbCrLf ^& "3. 当前 VPN 节点是否支持访问 Google", 16, "网络连接失败"
    ) > "%TEMP%\proxy_err.vbs"
    wscript "%TEMP%\proxy_err.vbs"
    del "%TEMP%\proxy_err.vbs" >nul 2>&1
    
    echo     请确认已开启 VPN/代理软件并设置 HTTP 端口为 7890。
    echo     检查项：
    echo       1. 代理/VPN 软件是否正在运行
    echo       2. 代理端口是否为 7890
    echo       3. 当前 VPN 节点是否能正常访问 Google
    echo;
    pause
    exit /b 1
)
echo [v] Google 连通性正常，代理工作正常。

REM === 3. 关闭旧实例 ===
echo;
echo [2/3] 重置已有 Antigravity 实例...
taskkill /F /IM Antigravity.exe >nul 2>&1
taskkill /F /IM language_server.exe >nul 2>&1
timeout /t 2 >nul

REM === 4. 确保 VBS 启动脚本存在 ===
if not exist "%BRIDGE_DIR%" mkdir "%BRIDGE_DIR%"
(
echo Set WshShell = CreateObject("WScript.Shell")
echo Set WshEnv = WshShell.Environment("Process")
echo WshEnv.Item("HTTPS_PROXY") = "http://127.0.0.1:7890"
echo WshEnv.Item("HTTP_PROXY") = "http://127.0.0.1:7890"
echo WshEnv.Item("NO_PROXY") = "127.0.0.1,localhost,::1,<-loopback>"
echo userProfile = WshShell.ExpandEnvironmentStrings("%USERPROFILE%"^)
echo agExe = userProfile ^& "\AppData\Local\Programs\antigravity\Antigravity.exe"
echo WshShell.Run """" ^& agExe ^& """", 1, False
) > "%START_AG_VBS%"

REM === 5. 通过独立的 VBScript 进程启动 Antigravity ===
echo;
echo [3/3] 正在以独立代理环境启动 Antigravity...
wscript "%START_AG_VBS%"

echo;
echo ========================================================
echo  [v] 启动命令已发出！
echo;
echo  说明：
echo  1. Antigravity 已作为纯独立后台进程启动，
echo     你现在可以放心关闭本 CMD 脚本窗口，软件绝不会随之关闭。
echo  2. 代理环境变量仅注入给 Antigravity 本身，
echo     全局注册表没有任何残留，不会影响电脑上其他任何软件！
echo  3. 请在弹出的 Antigravity 窗口中完成 Google OAuth 登录即可。
echo ========================================================
echo;
timeout /t 5
endlocal
exit /b 0
