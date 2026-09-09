# 场景：GitHub Codex 近一周 Issues 汇总（兼容登录/未登录）

**目标**：通过 GitHub 网页 UI **逐步点击/输入**（不走 API、不用 NavigateToUrl 跳深链），搜索并进入 `openai/codex` 仓库，进入 Issues 页筛选近 7 天 open issues，抓取列表文本，翻译为中文并通过「发送消息-SSE」输出。

**日期基准**：近 7 天筛选 `updated:>YYYY-MM-DD`（按执行日减 7 天更新 plan 中日期，如 2026-09-09 → `2026-09-02`）

## 登录状态探测

| 状态 | 探测信号 | 搜索路径 |
|------|---------|---------|
| **未登录** | 顶部导航栏可见 **Sign in** 按钮 | 先点击**搜索图标（放大镜）** → 弹出搜索框 → 输入 `openai/codex` → 回车 |
| **已登录** | 无 Sign in，顶部有常驻搜索输入框 | 直接在顶部搜索框输入 `openai/codex` → 回车 |

使用 `WaitForElementPresent` + `outKey: isLoggedOut` + `failOptions: continue` 探测 Sign in；条件为 true 走 IF 分支（未登录），false 走 Else 分支（已登录）。

## 自动化路径

```
打开 github.com → 等待加载 → 探测 Sign in（isLoggedOut）
├─ IF（未登录）：点击搜索图标 → 等待搜索框 → 输入 openai/codex → 回车
└─ Else（已登录）：顶部搜索框输入 openai/codex → 回车
→ 汇合后通用流程（纯 UI 操作）：
  等待加载 → 点击搜索结果 openai/codex 仓库链接
  → 等待加载 → 点击 Issues 标签
  → 等待加载 → Search issues 输入 is:open updated:>日期 → 回车
  → 等待列表 → 滚动 → GetText(weeklyIssuesText)
  → 大模型翻译 → 发送消息-SSE
```

> 🚫 **禁止**在 postSteps 使用 `NavigateToUrl` 直达 Issues 深链 URL；必须走点击仓库 → 点击 Issues → 输入筛选 的 UI 路径。

## Plan 文件

| 类型 | 文件 |
|------|------|
| 复合 plan（推荐，含登录分叉） | [github-codex-issues-composite-plan.json](../examples/github-codex-issues-composite-plan.json) |
| 线性 plan（旧版） | [github-codex-issues-plan.json](../examples/github-codex-issues-plan.json) |

## 输出变量

| outKey | 含义 |
|--------|------|
| `isLoggedOut` | 是否未登录（Sign in 可见） |
| `weeklyIssuesText` | 近 7 天 open issues 列表文本 |

## 调试经验

| 现象 | 处理 |
|------|------|
| 未登录页无顶部搜索框 | IF 分支先点放大镜再 FillText |
| 点击搜索结果仓库链接超时 | 加长 `findTimeout`；检查 LLM 描述是否含 openai/codex 仓库名 |
| 点击 Issues 标签失败 | 重写 alias（仓库页顶部 Code/Issues/Pull requests 导航栏） |
| Issues 筛选无结果 | 确认 Search issues 输入 `is:open updated:>日期` 后已 SendKeys Return |
| 元素定位超时 | plan 中 `findTimeout: "15000"`~`"25000"` |
| WaitPageState timeout 报错 | 使用 `waitForLoadStateOptions.timeout`，禁止顶层 `timeout` |
