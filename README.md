NOTICE:一定要在使用完antigravity脚本后点击清理代理环境变量!否则在关闭代理后其他应用无法使用！
NOTICE:(Be sure to click "Clean Up Proxy Environment Variables" after using the Antigravity script! Otherwise, other apps will not work after closing the proxy.）
# Gemini & Antigravity Manager

一键完成 **Gemini 桥接服务**的登录、模型同步、后台启动，以及 **Antigravity** 的独立代理启动与系统代理清理。

> 本项目面向 Windows 用户，依赖本机已安装的 [WorkBuddy](https://www.codebuddy.cn/)、`cli-proxy-api` 桥接组件与第三方代理/VPN 软件（默认 FlClash，端口 `7890`）。

---

## ✨ 功能概览

打包后的单文件程序 `GeminiAntigravitytools.exe` 是一个基于 Python `tkinter` 的 GUI 工具箱，内含 **三个按钮**，分别对应三个独立的批处理脚本：

| 按钮 | 对应脚本 | 作用 |
|------|----------|------|
| 🚀 **Gemini 通用一键配置与登录启动** | `Gemini通用一键配置与登录启动.cmd` | 全流程：连通性检测 → OAuth 登录 → 写入 WorkBuddy 模型 → 拉起桥接服务 → API 测试 |
| 🔑 **Antigravity 启动与配置代理** | `Antigravity启动与配置代理.cmd` | 以独立代理环境拉起 Antigravity 完成 Google OAuth 登录（不影响系统其他软件） |
| 🧹 **清理代理环境变量** | `清理系统全局代理.cmd` | 彻底清除注册表中残留的 `HTTPS_PROXY/HTTP_PROXY/NO_PROXY` 并广播刷新 |

---

## 🔧 功能详解

### 1. Gemini 通用一键配置与登录启动（6 步流程）

双击运行后自动执行：
| **检测主程序** | 自动定位 `cli-proxy-api.exe`（用户目录或脚本同级），未找到时弹出目录引导用户放置 |
1. **Google 连通性检测** — 通过 `127.0.0.1:7890` 代理探测 `https://www.google.com/generate_204`，失败则弹出原生 VBScript 对话框提示开启代理。
2. **补全配置文件** — 自动生成 `~/.cli-proxy-api/config.yaml` 与隐形后台启动器 `start_bridge.vbs`。
3. **账号登录状态检查** — 检测 `~/.cli-proxy-api/*.json` 凭证；缺失时自动唤起浏览器完成 Google / Antigravity 的 OAuth 授权。
4. **同步 WorkBuddy 模型** — 向 `~/.workbuddy/models.json` 写入 **12 个模型定义**（Gemini / Claude / GPT-OSS），并做：
   - 写入前自动备份 `models.json.bak`；
   - 使用 **无 BOM 的 UTF-8** 编码（避免 WorkBuddy 解析失败）；
   - 写入失败自动回滚备份。
5. **智能管理桥接服务** — 先探测 `127.0.0.1:8317` 是否已有正常实例，**能复用就跳过重启**，否则重启 `cli-proxy-api` 并等待就绪（最长 30 秒）。
6. **真实 API 发包测试** — 以干净 JSON 文件方式向桥接服务发送测试对话，校验节点地区是否被 Google 拦截（`User location is not supported`）以及账号凭证是否加载完成（含自动重试）。

### 2. Antigravity 启动与配置代理（独立进程隔离）

- 检测 Google 连通性（失败弹窗提示）。
- 关闭已有的 Antigravity / `language_server` 旧实例。
- 通过 `start_ag.vbs` 向所有进程注入系统级代理环境变量，确保antigravity程序正常运行。
- 以 `wscript` 完全脱离控制台的方式拉起，因此 **关闭脚本窗口 / 工具箱后 Antigravity 不会被关闭**。
- 避免了 Electron 加载本地回环端口 `https://127.0.0.1:5283/` 时出现的 `ERR_TIMED_OUT` 黑屏问题。

### 3. 清理代理环境变量

- 优先调用 `~/.cli-proxy-api/proxy_env.py clean` 删除注册表 `HKCU\Environment` 下的代理键值。
- 若 Python 不可用，则直接 `reg delete` 兜底。
- 通过 Win32 `SendMessageTimeout` 广播 `WM_SETTINGCHANGE`，通知系统刷新环境变量，恢复干净网络。

> ⚠️ **重要**：使用 Antigravity 脚本登录完成后，必须点击「清理代理环境变量」
---

## 📋 前置要求

- **Windows 10/11**
- 已安装 **WorkBuddy**（含 `~/.workbuddy` 目录与 `models.json`）
- 已安装 `cli-proxy-api`（桥接主程序 `cli-proxy-api.exe`，默认路径 `~/.local/share/workbuddy-gpt-gemini-bridge/bin/`）
- 代理 / VPN 软件运行中，**HTTP 代理端口为 `7890`**（如 FlClash）
- 系统自带 `curl.exe`（Windows 10+ 默认自带）

---

## 🚀 使用方式

### 方式一：直接使用 EXE（推荐）

1. 确保 FlClash（或同类代理）已运行且端口为 `7890`。
2. 双击 `GeminiAntigravitytools.exe`。
3. 按需求点击对应按钮，按提示完成登录即可。

### 方式二：直接运行批处理脚本

进入 `cmdfiles/` 目录，双击对应 `.cmd` 文件：

```text
cmdfiles/
├── Gemini通用一键配置与登录启动.cmd
├── Antigravity启动与配置代理.cmd
└── 清理系统全局代理.cmd
```

---

## 🗂️ 项目结构

```text
GeminiManagerApp/
├── main.py                        # tkinter GUI 源码，内嵌 3 个脚本
├── Gemini与Antigravity配置工具箱.spec  # PyInstaller 打包配置
├── GeminiAntigravitytools.exe     # 已打包的单文件程序（≈10 MB）
├── cmdfiles/                      # 三个独立批处理脚本（可直接运行）
│   ├── Gemini通用一键配置与登录启动.cmd
│   ├── Antigravity启动与配置代理.cmd
│   └── 清理系统全局代理.cmd
├── build/  dist/  files/          # PyInstaller 构建产物
└── README.md
```

---

## 🛠️ 自行构建（可选）

需要 Python 3.13 + PyInstaller：

```bash
pip install pyinstaller
pyinstaller --noconsole --onefile --clean main.py -n "GeminiAntigravitytools"
```

生成的单文件 EXE 位于 `dist/`。

> 💡 提示：建议将编译好的 `GeminiAntigravitytools.exe` 通过 **GitHub Releases** 发布，而非直接提交进 Git 仓库（避免仓库体积膨胀）。

---

## ❓ 常见问题（FAQ）

**Q：提示「端口 8317 被其他程序占用」？**
A：当前版本已改为智能探测——若发现 `127.0.0.1:8317` 已有正常响应实例会直接复用，不再误报占用。若仍初始化超时，通常是 VPN 节点延迟过高或 OAuth 凭证未刷新，请切换稳定节点或重新运行脚本。

**Q：WorkBuddy 里看不到模型？**
A：旧版脚本写入的 `models.json` 带 UTF-8 BOM 导致解析失败。当前版本已强制使用无 BOM 编码；若曾受影响，重启 WorkBuddy 即可重新读取。

**Q：运行测试时报 `unknown provider for model`？**
A：这是账号凭证还在异步加载中。脚本已内置自动重试（最多 3 次）；若持续失败，请确认 OAuth 登录已成功完成。

**Q：Antigravity 提示 `ERR_TIMED_OUT` 加载 `127.0.0.1:5283/` 失败？**
A：旧版把代理写进了系统注册表，导致 Electron 把本地回环流量也发往代理。当前版本改为进程级注入并豁免回环地址，已解决该问题。

---

## ⚖️ 免责声明

本项目仅用于个人本地环境自动化配置，不涉及任何破解、绕过付费或违反服务条款的行为。账号授权请使用你本人合法的 Google / Antigravity 账号。使用代理 / VPN 请遵守所在地区法律法规。
