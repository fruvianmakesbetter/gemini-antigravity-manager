@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title Gemini Universal Config & Launcher
REM ============================================================
REM  Gemini Bridge Universal Setup & Launcher v1.2
REM  Last updated: 2026-07-27
REM  Usage: Double-click to run. Requires FlClash VPN on port 7890.
REM ============================================================

echo ========================================================
echo     Gemini 桥接服务【通用版】一键登录/配置与启动工具
echo ========================================================
echo;

REM === 1. 动态获取当前用户根目录与相关路径 ===
set "USER_DIR=%USERPROFILE%"
set "BRIDGE_DIR=%USER_DIR%\.cli-proxy-api"
set "WORKBUDDY_DIR=%USER_DIR%\.workbuddy"
set "BIN_DIR=%USER_DIR%\.local\share\workbuddy-gpt-gemini-bridge\bin"
set "EXE_PATH=%BIN_DIR%\cli-proxy-api.exe"

REM === 定位 CLIProxyAPI 主程序（支持循环重检）===
:DETECT_EXE
REM 优先使用脚本同级目录的 exe，其次默认安装目录
if exist "%~dp0cli-proxy-api.exe" (
    set "EXE_PATH=%~dp0cli-proxy-api.exe"
    goto EXE_FOUND
)
if exist "%EXE_PATH%" goto EXE_FOUND

REM === 未找到主程序：首次进入则创建目录并打开文件夹引导 ===
if not defined BIN_GUIDED (
    echo [!] 未检测到 cli-proxy-api.exe，正在为目标目录做准备...
    if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
    echo [v] 已创建目录: %BIN_DIR%
    explorer "%BIN_DIR%"
    set "BIN_GUIDED=1"
)
echo;
echo [!] 请将 cli-proxy-api.exe 放入: %BIN_DIR%
echo     或放在本脚本同级目录下，脚本会自动识别。
echo     放好后按任意键重新检测（关闭本窗口可取消）...
pause >nul
goto DETECT_EXE

:EXE_FOUND
echo [v] CLIProxyAPI 主程序就绪: %EXE_PATH%

REM === 2. 检查 curl 是否可用 ===
where curl >nul 2>&1
if errorlevel 1 (
    echo [X] 未找到 curl 命令！
    echo     本脚本依赖 curl 进行网络检测，请确认系统已包含 curl.exe。
    echo;
    pause
    exit /b 1
)

REM === 3. 检查 Google 连通性 (通过代理 127.0.0.1:7890) ===
echo [1/6] 检查 Google 网络连通性...
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

REM === 4. 自动生成配置文件与 VBS 后台启动器 ===
echo;
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
echo;
echo [3/6] 检查 Google / Antigravity 账号登录状态...
set "LOGGED_IN=0"
for %%f in ("%BRIDGE_DIR%\*.json") do (
    if exist "%%f" set "LOGGED_IN=1"
)

if "!LOGGED_IN!"=="0" goto NEED_LOGIN
echo [v] 已检测到有效的 Google 账号授权凭证。
goto LOGIN_DONE

:NEED_LOGIN
echo;
echo [!] 未检测到已被授权的 Google 账号凭证！
echo [!] 准备拉起浏览器进行 OAuth 登录授权...
echo     请在弹出的浏览器窗口中完成 Google 账号登录与授权。
echo;

REM 设置环境变量走代理拉起 OAuth 登录窗口（setlocal 保证不会泄漏）
set "HTTPS_PROXY=http://127.0.0.1:7890"
set "HTTP_PROXY=http://127.0.0.1:7890"
"%EXE_PATH%" -antigravity-login --config "%BRIDGE_DIR%\config.yaml"
set "LOGIN_EXIT=!errorlevel!"

echo;
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
echo;
echo [4/6] 自动同步 WorkBuddy 模型列表...
if not exist "%WORKBUDDY_DIR%" mkdir "%WORKBUDDY_DIR%"

REM 安全保护：写入前备份已有 models.json
if exist "%WORKBUDDY_DIR%\models.json" (
    copy /Y "%WORKBUDDY_DIR%\models.json" "%WORKBUDDY_DIR%\models.json.bak" >nul 2>&1
    echo [i] 已备份原有 models.json
)

REM 将 PowerShell 脚本写入临时文件后执行，采用无 BOM 的 UTF-8 编码输出
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
echo if ($json -and $json.Contains('id'^)^) {
echo     $utf8NoBom = New-Object System.Text.UTF8Encoding $false
echo     [System.IO.File]::WriteAllText($path, $json, $utf8NoBom^)
echo     exit 0
echo } else {
echo     exit 1
echo }
) > "%PS_SCRIPT%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
set "PS_EXIT=!errorlevel!"
del "%PS_SCRIPT%" >nul 2>&1

if "!PS_EXIT!"=="0" (
    echo [v] WorkBuddy 12 个 Gemini/Claude/GPT 模型定义已自动配置绑定。
) else (
    echo [!] models.json 写入验证失败！正在恢复备份...
    if exist "%WORKBUDDY_DIR%\models.json.bak" (
        copy /Y "%WORKBUDDY_DIR%\models.json.bak" "%WORKBUDDY_DIR%\models.json" >nul 2>&1
        echo [v] 已恢复备份，原有模型配置未受影响。
    ) else (
        echo [X] 无备份可用，请手动检查 models.json！
    )
)

REM === 7. 智能检测与管理后台桥接服务 ===
echo;
echo [5/6] 智能检测并管理后台桥接服务...

REM 先检查已有服务是否正常响应，能复用就不重启
curl -s --max-time 3 -o "%TEMP%\cli_models.tmp" http://127.0.0.1:8317/v1/models -H "Authorization: Bearer 3027a8b32e176da4c6a6bb9697fd1154e39aa3df106e74e15d9565157822d7fe" 2>nul
findstr /C:"id" "%TEMP%\cli_models.tmp" >nul 2>&1
if not errorlevel 1 (
    del "%TEMP%\cli_models.tmp" >nul 2>&1
    echo [v] 桥接服务已在运行且响应正常，跳过重启。
    goto SKIP_RESTART
)
del "%TEMP%\cli_models.tmp" >nul 2>&1

echo [i] 桥接服务未正常响应，执行重启...
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

:SKIP_RESTART

REM === 8. 真实 API 发包测试与节点地区拦截 ===
echo;
echo [6/6] 测试 Gemini API 发包及 VPN 地区支持...

REM 提前写好干净标准的 JSON 请求体，避免 CMD 命令行转义导致 JSON 损坏
(
echo {
echo   "model": "gemini-3-flash",
echo   "messages": [{"role": "user", "content": "ping"}],
echo   "max_tokens": 1
echo }
) > "%TEMP%\gemini_req.json"

set "CHAT_TRIES=0"
:test_chat_loop
set /a CHAT_TRIES+=1
curl -s --max-time 15 http://127.0.0.1:8317/v1/chat/completions -H "Authorization: Bearer 3027a8b32e176da4c6a6bb9697fd1154e39aa3df106e74e15d9565157822d7fe" -H "Content-Type: application/json" -d @"%TEMP%\gemini_req.json" > "%TEMP%\gemini_chat_test.tmp" 2>&1

findstr /I /C:"User location is not supported" "%TEMP%\gemini_chat_test.tmp" >nul 2>&1
if not errorlevel 1 goto REGION_BLOCKED

findstr /I /C:"choices" "%TEMP%\gemini_chat_test.tmp" >nul 2>&1
if not errorlevel 1 goto CHAT_SUCCESS

findstr /I /C:"unknown provider" "%TEMP%\gemini_chat_test.tmp" >nul 2>&1
if not errorlevel 1 (
    if !CHAT_TRIES! lss 4 (
        echo     ...正在等待账号凭证加载 (!CHAT_TRIES!/3)
        timeout /t 2 >nul
        goto test_chat_loop
    )
)

goto CHAT_FAILED

:CHAT_SUCCESS
del "%TEMP%\gemini_req.json" >nul 2>&1
del "%TEMP%\gemini_chat_test.tmp" >nul 2>&1
echo [v] 节点地区检测合格！Gemini API 测试发包成功。

echo;
echo ========================================================
echo  [v] 全流程一键配置与启动成功！
echo  当前电脑已完成：账号登录 + WorkBuddy 模型配置 + 桥接启动
echo  请在 WorkBuddy 模型菜单中直接选择 Gemini / Claude 对话。
echo ========================================================
echo;
pause
endlocal
exit /b 0

:REGION_BLOCKED
echo;
echo [X] 地区被 Google 拦截！
echo     Google API 返回错误: "User location is not supported for the API use."
echo;
echo     当前切换的 VPN 节点（如香港、大陆节点）不在支持范围内。
echo     请将 FlClash 节点切换至 美国、日本、新加坡或中国台湾，然后重新运行本脚本。
echo;
del "%TEMP%\gemini_req.json" >nul 2>&1
del "%TEMP%\gemini_chat_test.tmp" >nul 2>&1
pause
endlocal
exit /b 1

:CHAT_FAILED
echo;
echo [X] 测试对话请求失败！错误信息如下：
echo;
type "%TEMP%\gemini_chat_test.tmp"
echo;
del "%TEMP%\gemini_req.json" >nul 2>&1
del "%TEMP%\gemini_chat_test.tmp" >nul 2>&1
pause
endlocal
exit /b 1

:INITIALIZE_FAILED
echo;
echo [X] 桥接服务初始化超时（超过 30 秒未能响应请求）。
echo     排查建议：
echo       1. 当前节点网络延迟过高，请在 VPN/代理软件中尝试切换至更稳定的节点（如美/日/台）
echo       2. 若刚完成 OAuth 授权，可尝试重新双击运行本脚本以刷新后台凭证
echo       3. 确认 FlClash 代理端口设置为 7890，且代理软件正常联网
echo;
del "%TEMP%\cli_models.tmp" >nul 2>&1
pause
endlocal
exit /b 1
