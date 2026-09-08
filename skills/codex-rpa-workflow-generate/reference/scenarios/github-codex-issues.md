# 场景：GitHub Codex 近一周 Issues 汇总

**目标**：通过 GitHub 网页 UI 逐步操作（不走 API），打开 `openai/codex` 仓库，筛选近一周 issues 并抓取列表文本。

**日期基准**：近一周筛选 `updated:>2026-09-01`（按执行日更新 plan 中日期）

## 自动化路径（经调试优化）

GitHub 顶部 **Commits / Issues 标签 LLM 点击不稳定**（易报 `ClickElementMixed 页面元素不存在`），改用 **NavigateToUrl** 进入子页，仍属浏览器 UI 导航，非 API：

```
打开 openai/codex
  → 等待加载
  → 导航到 /commits
  → 等待 + 等待元素存在
  → 获取提交列表 (recentCommitsText)
  → 导航到 /issues
  → 等待 + 在 Search issues 输入筛选 → 回车
  → 等待结果列表
  → 获取 issues 文本 (weeklyIssuesText)
  → 截图
```

## instructionPlan

见 [github-codex-issues-plan.json](../examples/github-codex-issues-plan.json)

## 输出变量

| outKey | 含义 |
|--------|------|
| `recentCommitsText` | Commits 页提交记录文本 |
| `weeklyIssuesText` | 近一周 issues 列表文本 |
| `issuesSummaryScreenshot` | 最终页面截图 |

## 调试经验

| 现象 | 处理 |
|------|------|
| 点击 Commits/Issues 标签失败 | 改用 `NavigateToUrl` 打开 `/commits`、`/issues` |
| 元素定位超时 | plan 中 `findTimeout: "15000"`，build-nodes 默认 10s |
| WaitPageState timeout 报错 | 使用 `waitForLoadStateOptions.timeout`，禁止顶层 `timeout` |
