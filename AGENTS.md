# THub V3 — 代理指南

## 项目

Roblox 脚本执行器功能集合 (Lua/Luau)。Fork 自 [ChronixHub V3](https://atomgit.com/Furrycalin/ChronixHub)。
远程仓库：`git@github.com:wjm13206/THub.git`

## 执行模型

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/main.lua"))()
```

**推送到 `main` 即立即部署** — 所有文件从 GitHub raw URL 获取。无构建/打包/部署步骤。

## 加载顺序（`main.lua`）

1. `src/services.lua` — 通过 `cloneref` 引用 Roblox 服务，注入全局
2. `modules/AsyncFileFetcher.lua` — HTTP 获取器（仅在 `src/config.lua` 中用于 3 个外部 API 调用，不参与模块加载）
3. `require()` 加载 ~55 个模块（遍历 `moduleList`，路径如 `modules/FlyModule.lua` → `modules.FlyModule`）
4. `src/config.lua` — 全局 `data` 表（玩家信息、游戏配置、执行器信息、外部 API 异步加载）
5. `src/utils.lua` — 工具函数
6. `src/ui.lua` — ChronixUI 定义（约 2100 行，17+ 标签页）
7. `src/events.lua` — 事件处理器（防挂机、重生监听、反踢、锁属性等）
8. `src/unload.lua` — 清理（`unloadTHub()` 逐一卸载所有模块）

## 目录

| 路径 | 内容 |
|---|---|
| `src/` | 核心：services, config, utils, ui, events, unload |
| `modules/` | ~70 个功能模块（飞行、ESP、自瞄、传送等） |
| `modules/icons/` | 7 个图标包（craft/geist/gravity/lucide/other/sfsymbols/solar） |

## 约定

- **文件 pragma**：每个 `.lua` 文件以 `--!native` 和 `--!optimize 2` 开头（`modules/` 下部分文件可能缺失，核心 `src/` 文件必须遵守）
- **`cloneref` 回退链**：`cloneref = cloneref or clonereference or function(obj) return obj end` — 每个文件自行定义，不依赖全局
- **模块模式**：返回包含 `enable()`/`disable()`（或 `Enable()`/`Disable()`）和 `unload()`/`Unload()` 方法的表
- **守卫全局变量**：`_G.THubisLoaded`（已加载）和 `_G.THubLoading`（加载中）；`main.lua:5-6` 做防重复执行检查
- **配置持久化**：`ConfigModule.createconfig()` / `ConfigModule.setmain()` — 写本地文件
- **提交信息**：中文 conventional-commit 风格（`feat`、`fix`、`refactor` 等）

## UI 框架

**ChronixUI**（fork v4.3.0，`modules/ChronixUI Lib.lua`，约 2234 行）。自定义 Roblox GUI 库，支持 7 个图标包（`rbxassetid://` 常量）。`require("modules.UIParticleSystem")` 可选粒子系统。

## 注意

- 无 CI、测试、linter 或格式化工具 — 编辑后直接 `git commit` + `git push origin main`
- `.gitignore` 仅忽略临时文件（`*.tmp`, `*.temp`, `*.log`, `Thumbs.db`, `.DS_Store`）— 避免提交密钥或 API 令牌
- `modules/icons/solar/Icons.lua` 由 "Tree Hub CLI" 自动生成 — **请勿手动编辑**
- 外部 API：GitHub raw（模块托管）、weao.xyz（执行器状态）、52vmy.cn（语录）、Roblox API

## 工作流程

1. 编辑 `src/` 或 `modules/` 中的 `.lua` 文件
2. 确保文件 pragma 正确、模块方法签名匹配 `unload.lua` 中的调用
3. `git add` + `git commit -m "<type>(<scope>): <中文描述>"`
4. `git push origin main` — 立即部署给所有用户
