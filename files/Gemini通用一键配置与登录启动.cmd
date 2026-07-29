@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title Gemini Universal Config & Launcher
REM ============================================================
REM  Gemini Bridge Universal Setup & Launcher v1.0
REM  Last updated: 2026-07-27
REM  Usage: Double-click to run. Requires FlClash VPN on port 7890.
REM ============================================================

echo ========================================================
echo     Gemini 桥接服务【通用版】一键登录/配置与启动工具
echo ========================================================
echo.

REM === 1. 动态获取当前用户根目录与相关路径 ===
set "USER_DIR=%USERPROFILE%"
set "BRIDGE_DIR=%USER_DIR%\.cli-proxy-api"
set "WORKBUDDY_DIR=%USER_DIR%\.workbuddy"
set "EXE_PATH=%USER_DIR%\.local\share\workbuddy-gpt-gemini-bridge\bin\cli-proxy-api.exe"

REM 如果当前目录下有二进制文件，优先使用当前目录的 exe
if exist "%~dp0cli-proxy-api.exe" (
    set "EXE_PATH=%~dp0cli-proxy-api.exe"
)

if not exist "%EXE_PATH%" (
    echo [X] 未找到 CLIProxyAPI 主程序！
    echo     预期路径: !EXE_PATH!
    echo     请确认是否已安装 workbuddy-gpt-gemini-bridge 插件
    echo     或将 cli-proxy-api.exe 放在本脚本同级目录下。
    echo.
    pause
    exit /b 1
)

REM === 2. 检查 curl 是否可用 ===
where curl >nul 2>&1
if errorlevel 1 (
    echo [X] 未找到 curl 命令！
    echo     本脚本依赖 curl 进行网络检测，请确认系统已包含 curl.exe。
    echo.
    pause
    exit /b 1
)

REM === 3. 检查 VPN 进程 (FlClash) ===
echo [1/6] 检查 VPN 代理状态...
tasklist /FI "IMAGENAME eq FlClash.exe" 2>nul | find /I "FlClash.exe" >nul 2>&1
if errorlevel 1 (
    echo [X] 未检测到 FlClash VPN 进程运行！
    echo     请先开启 FlClash VPN 代理（建议端口 7890）后再运行本脚本。
    echo.
    pause
    exit /b 1
)
echo [v] VPN 进程正在运行。

REM === 4. 自动生成配置文件与 VBS 后台启动器 ===
echo.
echo [2/6] 检查/补全配置文件与后台组件...
if not exist "%BRIDGE_DIR%" mkdir "%BRIDGE_DIR%"

REM 写入 config.yaml（用 echo; 代替 echo. 确保空行输出的跨版本兼容性）
(
echo host: "127.0.0.1"
echo port: 8317
echo;
echo remote-management:
echo   allow-remote: false
echo   secret-key: ""
echo   disable-control-panel: true
echo;
echo auth-dir: "~/.cli-proxy-api"
echo;
echo api-keys:
echo   - "3027a8b32e176da4c6a6bb9697fd1154e39aa3df106e74e15d9565157822d7fe"
echo;
echo debug: false
echo request-log: false
echo logging-to-file: true
echo usage-statistics-enabled: false
echo request-retry: 3
) > "%BRIDGE_DIR%\config.yaml"

REM 写入 start_bridge.vbs — VBS 中反斜杠是字面量，无需转义
(
echo Set WshShell = CreateObject("WScript.Shell")
echo Set WshEnv = WshShell.Environment("Process")
echo WshEnv.Item("HTTPS_PROXY") = "http://127.0.0.1:7890"
echo WshEnv.Item("HTTP_PROXY") = "http://127.0.0.1:7890"
echo WshEnv.Item("NO_PROXY") = "localhost,127.0.0.1"
echo WshShell.Run """%EXE_PATH%"" --config ""%BRIDGE_DIR%\config.yaml""", 0, False
) > "%BRIDGE_DIR%\start_bridge.vbs"

echo [v] 基础配置文件及后台启动器就绪。

REM === 5. 检查账号授权凭证，无凭证时自动唤起浏览器登录 ===
echo.
echo [3/6] 检查 Google / Antigravity 账号登录状态...
set "LOGGED_IN=0"
for %%f in ("%BRIDGE_DIR%\*.json") do (
    if exist "%%f" set "LOGGED_IN=1"
)

if "!LOGGED_IN!"=="0" goto NEED_LOGIN
echo [v] 已检测到有效的 Google 账号授权凭证。
goto LOGIN_DONE

:NEED_LOGIN
echo.
echo [!] 未检测到已被授权的 Google 账号凭证！
echo [!] 准备拉起浏览器进行 OAuth 登录授权...
echo     请在弹出的浏览器窗口中完成 Google 账号登录与授权。
echo.

REM 设置环境变量走代理拉起 OAuth 登录窗口（setlocal 保证不会泄漏）
set "HTTPS_PROXY=http://127.0.0.1:7890"
set "HTTP_PROXY=http://127.0.0.1:7890"
"%EXE_PATH%" -antigravity-login --config "%BRIDGE_DIR%\config.yaml"
set "LOGIN_EXIT=!errorlevel!"

echo.
echo [i] 登录流程结束 (退出码: !LOGIN_EXIT!)，重新检查凭证...
set "LOGGED_IN=0"
for %%f in ("%BRIDGE_DIR%\*.json") do (
    if exist "%%f" set "LOGGED_IN=1"
)
if "!LOGGED_IN!"=="0" (
    echo [X] 登录未成功完成或取消了授权，请重新运行脚本尝试登录。
    pause
    exit /b 1
)
echo [v] 登录成功，已检测到有效的 Google 账号授权凭证。

:LOGIN_DONE

REM === 6. 自动向 WorkBuddy 写入模型配置 (models.json) ===
echo.
echo [4/6] 自动同步 WorkBuddy 模型列表...
if not exist "%WORKBUDDY_DIR%" mkdir "%WORKBUDDY_DIR%"

REM 将 PowerShell 脚本写入临时文件后执行，避免超长单行命令的引号嵌套脆弱性
set "PS_SCRIPT=%TEMP%\wb_models_sync.ps1"
(
echo $path = [System.IO.Path]::Combine($env:USERPROFILE, '.workbuddy', 'models.json'^)
echo $apiKey = '3027a8b32e176da4c6a6bb9697fd1154e39aa3df106e74e15d9565157822d7fe'
echo $url = 'http://127.0.0.1:8317/v1/chat/completions'
echo $models = @(
echo   @{id='gemini-3.6-flash-high'; name='gemini-3.6-flash-high'; vendor='Custom'; url=$url; apiKey=$apiKey; supportsToolCall=$true; supportsImages=$true; supportsReasoning=$true; useCustomProtocol=$true; onlyReasoning=$false}
echo   @{id='gemini-3-flash'; name='gemini-3-flash'; vendor='Custom'; url=$url; apiKey=$apiKey; supportsToolCall=$true; supportsImages=$true; supportsReasoning=$true; useCustomProtocol=$true; onlyReasoning=$false}
echo   @{id='gemini-3-flash-agent'; name='gemini-3-flash-agent'; vendor='Custom'; url=$url; apiKey=$apiKey; supportsToolCall=$true; supportsImages=$true; supportsReasoning=$true; useCustomProtocol=$true; onlyReasoning=$false}
echo   @{id='gemini-3.1-flash-image'; name='gemini-3.1-flash-image'; vendor='Custom'; url=$url; apiKey=$apiKey; supportsToolCall=$false; supportsImages=$true; supportsReasoning=$true; useCustomProtocol=$true; onlyReasoning=$false}
echo   @{id='gemini-3.1-flash-lite'; name='gemini-3.1-flash-lite'; vendor='Custom'; url=$url; apiKey=$apiKey; supportsToolCall=$true; supportsImages=$true; supportsReasoning=$true; useCustomProtocol=$true; onlyReasoning=$false}
echo   @{id='gemini-3.5-flash-low'; name='gemini-3.5-flash-low'; vendor='Custom'; url=$url; apiKey=$apiKey; supportsToolCall=$true; supportsImages=$true; supportsReasoning=$true; useCustomProtocol=$true; onlyReasoning=$false}
echo   @{id='gemini-3.5-flash-extra-low'; name='gemini-3.5-flash-extra-low'; vendor='Custom'; url=$url; apiKey=$apiKey; supportsToolCall=$true; supportsImages=$true; supportsReasoning=$true; useCustomProtocol=$true; onlyReasoning=$false}
echo   @{id='gemini-pro-agent'; name='gemini-pro-agent'; vendor='Custom'; url=$url; apiKey=$apiKey; supportsToolCall=$true; supportsImages=$true; supportsReasoning=$true; useCustomProtocol=$true; onlyReasoning=$false}
echo   @{id='gemini-3.1-pro-low'; name='gemini-3.1-pro-low'; vendor='Custom'; url=$url; apiKey=$apiKey; supportsToolCall=$true; supportsImages=$true; supportsReasoning=$true; useCustomProtocol=$true; onlyReasoning=$false}
echo   @{id='claude-sonnet-4-6'; name='claude-sonnet-4-6'; vendor='Custom'; url=$url; apiKey=$apiKey; supportsToolCall=$true; supportsImages=$true; supportsReasoning=$true; useCustomProtocol=$true; onlyReasoning=$false}
echo   @{id='claude-opus-4-6-thinking'; name='claude-opus-4-6-thinking'; vendor='Custom'; url=$url; apiKey=$apiKey; supportsToolCall=$true; supportsImages=$true; supportsReasoning=$true; useCustomProtocol=$true; onlyReasoning=$false}
echo   @{id='gpt-oss-120b-medium'; name='gpt-oss-120b-medium'; vendor='Custom'; url=$url; apiKey=$apiKey; supportsToolCall=$true; supportsImages=$true; supportsReasoning=$true; useCustomProtocol=$true; onlyReasoning=$false}
echo ^)
echo $json = $models ^| ConvertTo-Json -Depth 5
echo [System.IO.File]::WriteAllText($path, $json, [System.Text.Encoding]::UTF8^)
) > "%PS_SCRIPT%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
del "%PS_SCRIPT%" >nul 2>&1

echo [v] WorkBuddy 12 个 Gemini/Claude/GPT 模型定义已自动配置绑定。

REM === 7. 拉起后台桥接服务 ===
echo.
echo [5/6] 启动后台桥接服务...
tasklist /FI "IMAGENAME eq cli-proxy-api.exe" 2>nul | find /I "cli-proxy-api.exe" >nul 2>&1
if not errorlevel 1 (
    echo [i] 正在重置已有旧实例...
    taskkill /F /IM cli-proxy-api.exe >nul 2>&1
    timeout /t 2 >nul
)

wscript "%BRIDGE_DIR%\start_bridge.vbs"
echo [i] 已通过隐形后台拉起服务，等待端口 8317 响应...

set tries=0
:check_init
set /a tries+=1
timeout /t 2 >nul
curl -s --max-time 5 -o "%TEMP%\cli_models.tmp" http://127.0.0.1:8317/v1/models -H "Authorization: Bearer 3027a8b32e176da4c6a6bb9697fd1154e39aa3df106e74e15d9565157822d7fe" 2>nul
findstr /C:"id" "%TEMP%\cli_models.tmp" >nul 2>&1
if errorlevel 1 (
    if !tries! lss 15 (
        echo     ...服务初始化中 (!tries!/15)
        goto check_init
    )
    goto INITIALIZE_FAILED
)
del "%TEMP%\cli_models.tmp" >nul 2>&1
echo [v] 桥接端口打通，服务响应正常。

REM === 8. 真实 API 发包测试与节点地区拦截 ===
echo.
echo [6/6] 测试 Gemini API 发包及 VPN 地区支持...
curl -s --max-time 15 http://127.0.0.1:8317/v1/chat/completions -H "Authorization: Bearer 3027a8b32e176da4c6a6bb9697fd1154e39aa3df106e74e15d9565157822d7fe" -H "Content-Type: application/json" -d "{\"model\":\"gemini-3-flash\",\"messages\":[{\"role\":\"user\",\"content\":\"ping\"}],\"max_tokens\":1}" > "%TEMP%\gemini_chat_test.tmp" 2>&1

findstr /I /C:"User location is not supported" "%TEMP%\gemini_chat_test.tmp" >nul 2>&1
if not errorlevel 1 goto REGION_BLOCKED

findstr /I /C:"choices" "%TEMP%\gemini_chat_test.tmp" >nul 2>&1
if errorlevel 1 goto CHAT_FAILED

del "%TEMP%\gemini_chat_test.tmp" >nul 2>&1
echo [v] 节点地区检测合格！Gemini API 测试发包成功。

echo.
echo ========================================================
echo  [v] 全流程一键配置与启动成功！
echo  当前电脑已完成：账号登录 + WorkBuddy 模型配置 + 桥接启动
echo  请在 WorkBuddy 模型菜单中直接选择 Gemini / Claude 对话。
echo ========================================================
echo.
pause
endlocal
exit /b 0

:REGION_BLOCKED
echo.
echo [X] 地区被 Google 拦截！
echo     Google API 返回错误: "User location is not supported for the API use."
echo.
echo     当前切换的 VPN 节点（如香港、大陆节点）不在支持范围内。
echo     请将 FlClash 节点切换至 美国、日本、新加坡或中国台湾，然后重新运行本脚本。
echo.
del "%TEMP%\gemini_chat_test.tmp" >nul 2>&1
pause
endlocal
exit /b 1

:CHAT_FAILED
echo.
echo [X] 测试对话请求失败！错误信息如下：
echo.
type "%TEMP%\gemini_chat_test.tmp"
echo.
del "%TEMP%\gemini_chat_test.tmp" >nul 2>&1
pause
endlocal
exit /b 1

:INITIALIZE_FAILED
echo.
echo [X] 桥接服务超时未能启动（超过 30 秒）。
echo     可能原因：
echo       1. FlClash VPN 网络连接超时或未正常联网
echo       2. 端口 8317 被其他程序占用
echo.
del "%TEMP%\cli_models.tmp" >nul 2>&1
pause
endlocal
exit /b 1
