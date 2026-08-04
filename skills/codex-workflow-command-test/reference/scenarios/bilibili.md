# 场景 B：Bilibili 搜索（**默认场景**）

> **默认场景**：用户未指定测试场景或测试指令时，**禁止询问**，直接按本文件执行。

**目标**：打开 B 站 → 搜索框输入 `bilibili` → 点击搜索按钮 → 刷新网页

**工作流命名建议**：`Bilibili搜索测试-YYYYMMDD`（或用户指定名称）

## 指令节点

| 序号 | 指令 | reference | 关键配置 |
|------|------|-----------|---------|
| 1 | 打开网页 | [openurl.md](../commands/openurl.md) | 网址：`https://www.bilibili.com`（pbcopy 粘贴，见 [url-input.md](../url-input.md)） |
| 2 | 输入文本 | [filltext.md](../commands/filltext.md) | 待填充文本：`bilibili` |
| 3 | 点击元素（推荐） | [clickelementmixed.md](../commands/clickelementmixed.md) | 见下方选择器 |
| 4 | 刷新网页 | [reloadpage.md](../commands/reloadpage.md) | 无必填参数，直接保存 |

## 元素选择器

B 站首页 DOM 会随版本变化，执行前 **必须** 按 `reference/element-selector.md` **§批量采集（新建 Tab）** 一次性采集搜索框与搜索按钮 XPath。

| 元素 | 采集提示 | XPath 示例（仅供参考，以实测为准） |
|------|---------|--------------------------------|
| 顶部搜索框 | 找 `INPUT`/`TEXTAREA`，通常在导航栏 | `//input[contains(@class,"nav-search-input")]` |
| 搜索按钮 | 找搜索框旁的 `BUTTON` 或提交控件 | 以 DevTools 输出中的 `id`/`class` 构造 |

> ⚠️ 上表 XPath 仅为常见结构参考。**保存前必须用 DevTools 验证**，或在云浏览器中捕获确认。

## 执行步骤

1. `reference/platform-ops.md` §2.1 新建编排模式工作流
2. **按序插入指令**（`insert-command.md`）：**首条**选中**开始节点 → Enter**；之后每条选中**上一条/锚点指令 → Enter** 创建空行 → 右侧搜索框分别搜「打开网页」「输入文本」「点击元素」「刷新网页」→ 双击 (web) 结果 → 插入后校验顺序
3. **批量采集选择器**（配置表单前）：`element-selector.md` §批量采集 → **Cmd+T 新建 Tab** 打开 bilibili.com → DevTools **一次性**采集搜索框 + 搜索按钮 XPath → 切回工作流 Tab
4. 逐条配置并保存表单（保存前确认必填项无红色边框）
5. **调试前场景顺序终检**（`test-workflow.md` §调试前场景顺序终检）：对照本文件「指令节点」表，确认 canvas 顺序为 `开始 → 打开网页 → 输入文本 → 点击 → 刷新网页 → 结束`
6. 终检与「检查」均无报错 → **直接** `reference/debug.md` 调试运行（禁止询问用户），直到 4 条业务指令全部 ✅

## 与场景 A（百度）的差异

| 对比项 | 百度 | Bilibili |
|--------|------|----------|
| URL | `https://www.baidu.com` | `https://www.bilibili.com` |
| 搜索词 | `baidu` | `bilibili` |
| 选择器 | 已有实测 XPath，可直接用 | **必须先 DevTools 采集** |
| 页面特点 | textarea 搜索框 | 导航栏 input，结构随版本变化 |

## 元素选择器写入策略

配置「输入文本」「点击元素」等含「元素选择器」字段的指令时，按以下优先级写入 XPath：

| 优先级 | 方式 | 说明 | 何时用 |
|--------|------|------|--------|
| **1（默认）** | **[方式 C：pbcopy + Cmd+V 粘贴 XPath + Enter](../element-selector.md#方式-cpbcopy--cmdv-粘贴-xpath--enter默认策略)** | Shell 侧 pbcopy → 组合框 Cmd+V → Enter 让 AntD Select 落库 | 已通过批量采集 / locators 拿到 XPath 时**始终首选** |
| **2（退而求其次）** | **[方式 B：平台捕获](../element-selector.md#方式-b平台捕获按钮退而求其次)** | 云浏览器 VNC 点选目标元素 | 方式 C 连续失败 3 次 / XPath 含非 ASCII 时 |

> **Bilibili 场景提示**：B 站配置弹框的「元素选择器」是 AntD Select 组件；粘贴 XPath 后**必须紧接着按 Enter**，否则保存报「该字段是必填字段」。XPath 从批量采集结果取（`locators/bilibili.elements.json` 或上方「元素选择器」表）。
