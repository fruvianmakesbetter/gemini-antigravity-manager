@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title Antigravity 启动与配置代理
REM ============================================================
REM  Antigravity Launch & Set Proxy Script (System-Level Inject)
REM  Last updated: 2026-07-29
REM ============================================================

echo ========================================================
echo     Antigravity 启动与登录工具 (系统级代理注入版)
echo ========================================================
echo;

set "USER_DIR=%USERPROFILE%"
set "AG_EXE=%USER_DIR%\AppData\Local\Programs\antigravity\Antigravity.exe"
set "BRIDGE_DIR=%USER_DIR%\.cli-proxy-api"
set "START_AG_VBS=%BRIDGE_DIR%\start_ag.vbs"
set "PROXY_URL=http://127.0.0.1:7890"
set "NO_PROXY_VAL=127.0.0.1,localhost,::1,<-loopback>,127.0.0.0/8,*.local"

REM === 1. 检查主程序 ===
if not exist "%AG_EXE%" (
    echo [X] 未找到 Antigravity 主程序！
    pause
    exit /b 1
)

REM === 2. 检查 Google 网络连通性 ===
echo [1/4] 检查 Google 网络连通性...
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
    echo [X] 无法通过代理 7890 连接 Google！
    (
    echo MsgBox "网络检测失败：无法通过代理端口 7890 连接 Google！" ^& vbCrLf ^& vbCrLf ^& "请检查：" ^& vbCrLf ^& "1. 代理软件（如 FlClash 等）是否正在运行" ^& vbCrLf ^& "2. 代理端口是否设置为 7890" ^& vbCrLf ^& "3. 当前 VPN 节点是否支持访问 Google", 16, "网络连接失败"
    ) > "%TEMP%\proxy_err.vbs"
    wscript "%TEMP%\proxy_err.vbs"
    del "%TEMP%\proxy_err.vbs" >nul 2>&1
    echo     请确认已开启 VPN/代理软件并设置 HTTP 端口为 7890。
    echo;
    pause
    exit /b 1
)
echo [v] Google 连通性正常，代理工作正常。

REM === 3. 关闭旧实例 ===
echo;
echo [2/4] 关闭已有 Antigravity 实例...
taskkill /F /IM Antigravity.exe >nul 2>&1
taskkill /F /IM language_server.exe >nul 2>&1
timeout /t 2 >nul

REM === 4. 系统级注入代理环境变量 (写注册表 + 广播 WM_SETTINGCHANGE) ===
echo;
echo [3/4] 注入系统级代理环境变量 (HKCU\Environment)...
powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('HTTPS_PROXY','%PROXY_URL%','User'); [Environment]::SetEnvironmentVariable('HTTP_PROXY','%PROXY_URL%','User'); [Environment]::SetEnvironmentVariable('NO_PROXY','%NO_PROXY_VAL%','User')" >nul 2>&1

REM 同时在当前进程设置，确保 VBS 拉起的 Antigravity 立即继承
set "HTTPS_PROXY=%PROXY_URL%"
set "HTTP_PROXY=%PROXY_URL%"
set "NO_PROXY=%NO_PROXY_VAL%"
timeout /t 1 >nul
echo [v] 系统级代理注入完成。

REM === 5. 通过精简 VBS 脱离启动 Antigravity ===
echo;
echo [4/4] 启动 Antigravity...
if not exist "%BRIDGE_DIR%\" mkdir "%BRIDGE_DIR%" >nul 2>&1
set "AG_VBS_PATH=%START_AG_VBS%"
> "%AG_VBS_PATH%" echo CreateObject("WScript.Shell").Run WScript.Arguments(0), 1, False 2>nul
if exist "%AG_VBS_PATH%" goto :DO_LAUNCH
REM 降级：BRIDGE_DIR 写入失败则写到 TEMP
set "AG_VBS_PATH=%TEMP%\start_ag.vbs"
> "%AG_VBS_PATH%" echo CreateObject("WScript.Shell").Run WScript.Arguments(0), 1, False 2>nul
:DO_LAUNCH
if exist "%AG_VBS_PATH%" (
    wscript "%AG_VBS_PATH%" "%AG_EXE%"
) else (
    echo [X] VBS 脚本写入失败，正在直接启动...
    "%AG_EXE%"
)

echo;
echo ========================================================
echo  [v] 启动完成！
echo;
echo  Antigravity 已作为独立后台进程启动，可关闭本窗口。
echo  代理已注入系统级环境变量（含 NO_PROXY 放行内部端口）。
echo;
echo  注意：使用完毕后请运行"清理系统全局代理"脚本，
echo  否则关闭 VPN 后可能影响其他软件联网。
echo ========================================================
echo;
timeout /t 5
endlocal
exit /b 0
