# Gemini / Antigravity 配置工具箱

将Gemini模型桥接进 WorkBuddy 的一键配置与启动工具集。
配套的图形界面 `GeminiAntigravitytools.exe` 是把下面这些脚本封装成按钮的 GUI 版本。

---

## 一、它能做什么

- **Gemini 桥接服务**：拉起本地代理桥（`cli-proxy-api`），把 Gemini / Claude / GPT 模型通过自定义协议接入 WorkBuddy。
- **Antigravity 桌面端**：以「系统级代理注入」方式启动 Antigravity（Google 官方桌面 AI 客户端），解决内网端口被代理误拦导致的 `ERR_TIMED_OUT`。
- **环境清理**：用完一键移除全局代理环境变量，避免影响其他软件联网。

---

## 二、前置条件

| 项目 | 要求 |
|------|------|
| 代理 / VPN | 已运行 **FlClash** 等代理软件，HTTP 端口必须为 **7890** |
| 节点 | 需为 **美国 / 日本 / 新加坡 / 中国台湾**；大陆、香港节点会被 Google 地区拦截 |
| 命令依赖 | 系统自带 `curl.exe`（Win10 1803+ 已内置） |
| 桥接主程序 | `cli-proxy-api.exe`（放脚本同级目录，或 `%USERPROFILE%\.local\share\workbuddy-gpt-gemini-bridge\bin\`） |
| 权限 | 普通用户权限即可；脚本只写 `HKCU\Environment`（当前用户），不碰系统级 |

> 关键端口：代理 **7890** · 桥接 **8317** · Antigravity 内部 Electron 端口 **10229**

---

## 三、目录结构

```
GeminiManagerApp/
├── main.py                              # GUI 主程序（内嵌三段脚本源码）
├── GeminiAntigravitytools.exe           # PyInstaller 打包后的图形界面
├── 重新打包.cmd                          # 本地一键重新编译 main.py → exe
├── cmdfiles/                            # 独立可双击运行的脚本（与 GUI 内嵌版一致）
│   ├── Gemini通用一键配置与登录启动.cmd
│   ├── Antigravity启动与配置代理.cmd
│   └── 清理系统全局代理.cmd
└── files/                               # 安装包附带版本（同上，内容一致）
    ├── Gemini通用一键配置与登录启动.cmd
    ├── Antigravity启动与配置代理.cmd
    └── 清理代理环境变量.cmd
```

> `cmdfiles/` 与 `files/` 的同名脚本内容一致，区别仅在打包时拷贝到不同位置。

---

## 四、脚本说明

### 1. `Gemini通用一键配置与登录启动.cmd`
Gemini 桥接服务【通用版】一键登录 / 配置与启动工具（6 步流程）：

1. **检测主程序**：优先用脚本同级目录的 `cli-proxy-api.exe`，其次默认安装目录；找不到则自动打开目录引导你放入。
2. **连通性检测**：通过 `127.0.0.1:7890` 探测 Google `generate_204`，不通则提示检查代理。
3. **配置目录与文件**：三级目录回退写入（`%USERPROFILE%\.cli-proxy-api` → `%LOCALAPPDATA%\cli-proxy-api` → `%TEMP%\cli-proxy-api`），并生成 `config.yaml` + 隐形启动 `start_bridge.vbs`。
4. **OAuth 登录**：无凭证时拉起浏览器完成 Google 授权，写入 `BRIDGE_DIR` 下的 `*json` 凭证。
5. **同步 WorkBuddy 模型**：将 12 个 Gemini / Claude / GPT 模型定义写入 `~/.workbuddy/models.json`（写入前自动备份 `models.json.bak`）。
6. **桥接服务管理 + 发包测试**：复用或重启后台桥接，最后真实发包验证节点地区是否合格。

### 2. `Antigravity启动与配置代理.cmd`
Antigravity 启动与登录工具（**系统级代理注入版**，4 步流程）：

1. **检查主程序**：确认 `Antigravity.exe` 存在于 `%LOCALAPPDATA%\Programs\antigravity\`。
2. **连通性检测**：同上，依赖 7890 代理可访问 Google。
3. **关闭旧实例**：`taskkill` 掉 `Antigravity.exe` 与 `language_server.exe`，等待 2 秒。
4. **系统级注入 + 启动**：
   - 用 `[Environment]::SetEnvironmentVariable(..., 'User')` 写入
     `HKCU\Environment` 的 `HTTPS_PROXY` / `HTTP_PROXY` / `NO_PROXY`，**并自动广播 `WM_SETTINGCHANGE`** 让新进程即时生效；
   - `NO_PROXY` 含 `127.0.0.1,localhost,::1,<-loopback>,127.0.0.0/8,*.local`，其中 `<-loopback>` 是 Chromium 专用 token，确保 Electron 内部端口 `127.0.0.1:10229` 绕过代理，修复 `ERR_TIMED_OUT`；
   - 通过精简 `start_ag.vbs` 脱离启动 Antigravity（VBS 写入失败自动降级到 `%TEMP%`）。

### 3. `清理系统全局代理.cmd` / `清理代理环境变量.cmd`
彻底移除 `HKCU\Environment` 中的 `HTTPS_PROXY` / `HTTP_PROXY` / `NO_PROXY` 并广播刷新。
**每次用完 Antigravity 或结束桥接后务必运行一次**，否则残留代理会导致 WorkBuddy 及其他软件无法联网。

### 4. `重新打包.cmd`
本地一键重新编译：`清理 build/dist` → `PyInstaller --clean --noconfirm` → 自动用通配符定位 `.spec` 与 `dist\*.exe` → 复制为 `GeminiAntigravitytools.exe`。
纯英文界面，避免中文路径 / 编码污染。需本机已存在 WorkBuddy 管理的 Python 3.13.12。

---

## 五、图形界面（GeminiAntigravitytools.exe）

`main.py` 封装了三个按钮，分别对应内嵌的 `SCRIPT_GEMINI` / `SCRIPT_AG` / `SCRIPT_CLEAN`：

| 按钮 | 作用 | 对应脚本 |
|------|------|----------|
| **Gemini 一键配置** | 桥接配置 + 登录 + 模型同步 | `SCRIPT_GEMINI` |
| **Antigravity 启动代理** | 系统级代理注入并启动 | `SCRIPT_AG` |
| **清理代理环境变量** | 移除全局代理 | `SCRIPT_CLEAN` |

> 修改 `main.py` 内嵌脚本后，必须重新运行 `重新打包.cmd` 才能进 exe 生效。

---

## 六、重要注意事项

1. **⚠️ 系统级代理污染**：Antigravity 脚本会把代理写入注册表 `HKCU\Environment`（对所有新进程全局生效）。**关掉 VPN 前先跑「清理系统全局代理」**，否则全系统联网中断。

2. **NO_PROXY 必须放行回环地址**：Antigravity 的 `ERR_TIMED_OUT` 几乎都是因为内部端口 `127.0.0.1:10229` 被代理误转发。脚本已内置 `<-loopback>` 白名单，不要手动删掉此项。

3. **地区拦截**：若 API 返回 `User location is not supported`，把 VPN 节点切到 美 / 日 / 新 / 台 再重跑脚本。

4. **杀软拦截 VBS**：若提示无法写入 / 运行 `*.vbs`，多为安全软件拦截。脚本已做 `BRIDGE_DIR → %TEMP%` 自动降级写入；仍失败可临时放行或手动将 `cli-proxy-api.exe` 加入信任。

---

## 七、常见故障排查

| 现象 | 原因 | 解决 |
|------|------|------|
| `electron: Failed to load URL ... 10229 ... ERR_TIMED_OUT` | 内部端口被代理转发 | 确认 `NO_PROXY` 含 `<-loopback>`；重跑脚本 |
| 脚本双击秒退 / "不是内部或外部命令" | 括号转义错误（旧版） | 使用本版（已改用 `.NET SetEnvironmentVariable` + 顶层 `>` 重定向，避开 `( )` 块） |
| 找不到 `start_bridge.vbs` | 目标目录不可写 / 杀软拦截 | 脚本已三级目录回退 + 降级到 `%TEMP%` |
| 无法连接 Google | 代理未开 / 端口非 7890 / 节点受限 | 检查 FlClash，端口设为 7890 |
| 关 VPN 后其他软件断网 | 全局代理残留 | 运行「清理系统全局代理」 |

---

## 八、更新记录

- **2026-07-29**：Antigravity 脚本重构为系统级代理注入（`.NET SetEnvironmentVariable` + `WM_SETTINGCHANGE` 广播），修复 `( )` 块括号转义导致的秒退，新增 `<-loopback>` 放行内部端口修复 `ERR_TIMED_OUT`；`main.py` 与 `files/`、`cmdfiles/` 三处同步并重打包 exe。
- **2026-07-28**：Gemini 通用一键脚本增加三级目录回退写入与 `start_bridge.vbs` 隐形拉起校验。
