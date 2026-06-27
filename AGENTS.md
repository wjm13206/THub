# THub V3 — 代理指南

## 项目

Roblox 脚本执行器功能集合 (Lua/Luau)。Fork 自 [ChronixHub V3](https://atomgit.com/Furrycalin/ChronixHub)。
远程仓库：`git@github.com:wjm13206/THub.git`

## 执行模型

脚本通过以下方式在运行时加载：
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/main.lua"))()
```
**所有文件均从 `main` 分支的 GitHub raw URL 获取** — 推送到 `main` 即立即部署给用户。无构建、打包或部署步骤。

## 架构（`main.lua` 加载顺序）

1. `src/services.lua` — 通过 `cloneref` 引用 Roblox 服务
2. `modules/AsyncFileFetcher.lua` — 并发 HTTP 获取器
3. `AsyncFileFetcher.fetchMultiple()` 并发加载约 55 个功能模块
4. `src/config.lua` — 全局 `data` 表（玩家信息、游戏配置、执行器信息）
5. `src/utils.lua` — 工具函数
6. `src/ui.lua` — ChronixUI 定义（约 1900 行，17 个标签页）
7. `src/events.lua` — 事件处理器（防挂机、重生、反踢等）
8. `src/unload.lua` — 清理

## 目录

| 路径 | 内容 |
|---|---|
| `src/` | 核心：services、config、utils、UI、events、unload |
| `modules/` | 功能模块（飞行、ESP、自瞄、传送等） |
| `modules/icons/` | 7 个图标包（`craft/`、`geist/`、`gravity/`、`lucide/`、`other/`、`sfsymbols/`、`solar/`） |

## 约定

- **文件 pragma**：每个 `.lua` 文件必须以 `--!native` 和 `--!optimize 2` 开头
- **Roblox 服务引用**：使用 `cloneref`（依次回退到 `clonereference` 然后恒等函数）
- **模块模式**：返回包含 `enable()`/`disable()`（或 `Enable()`/`Disable()`）和 `unload()` 方法的表
- **守卫全局变量**：`_G.THubisLoaded`（已加载）和 `_G.THubLoading`（加载中）
- **配置持久化**：`ConfigModule.createconfig()` / `ConfigModule.setmain()`
- **提交信息**：使用中文 conventional-commit 风格（`feat`、`fix`、`refactor` 等）

## UI 框架

**ChronixUI**（fork v4.3.0，`modules/ChronixUI Lib.lua`，约 2250 行）。自定义 Roblox GUI 库，支持多图标包。7 个图标包存储为 `rbxassetid://...` 常量。

## 注意

- 没有 `.gitignore` — 避免提交密钥或 API 令牌
- 没有 CI、测试、linter 或格式化工具
- `modules/icons/solar/Icons.lua` 由 "Tree Hub CLI" 自动生成 — 请勿手动编辑
- 外部 API：GitHub raw（模块托管）、weao.xyz（执行器状态）、52vmy.cn（语录）、Roblox API

## 工作流程

1. 编辑 `src/` 或 `modules/` 中的 `.lua` 文件
2. `git add` + `git commit -m "<type>(<scope>): <中文描述>"`
3. `git push origin main` — 立即部署
