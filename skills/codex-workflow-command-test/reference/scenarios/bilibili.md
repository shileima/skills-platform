# 场景 B：Bilibili 搜索（**默认场景**）

> **默认场景**：用户未指定测试场景或测试指令时，**禁止询问**，直接按本文件执行。

**目标**：打开 B 站 → 搜索框输入 `bilibili` → 点击搜索按钮 → 刷新网页

**工作流命名建议**：`Bilibili搜索测试-YYYYMMDD`（或用户指定名称）

## 指令节点

| 序号 | 指令 | reference | 关键配置 |
|------|------|-----------|---------|
| 1 | 打开网页 | [openurl.md](../commands/openurl.md) | 网址：`https://www.bilibili.com`（pbcopy 粘贴，见 [url-input.md](../url-input.md)） |
| 2 | 输入文本 | [filltext.md](../commands/filltext.md) | 待填充文本：`bilibili`（**纯 ASCII 用 `type_text`**，见 `sky-runtime.md` §fillAsciiField）；LLM 用 `configLLMScoped`，若 AX 失败可在当前 scoped 字段用 `set_value` 兜底后再校验 |
| 3 | 点击元素（推荐） | [clickelementmixed.md](../commands/clickelementmixed.md) | 见下方选择器 |
| 4 | 刷新网页 | [reloadpage.md](../commands/reloadpage.md) | 无必填参数，插入后**直接保存**；AX 搜索结果常为 `文本 刷新网页`（无 `(web)`），见 §实测黄金路径 |

## 实测黄金路径（2026-08-22 验证通过）

> Helper 与 exec 批次见 **`sky-runtime.md` §B 站四步黄金路径**。配置阶段**禁止点「调试」**。

### Canvas 终态（顺序 + 摘要）

```
开始 → 打开网页 url: https://www.bilibili.com
     → 元素中输入 bilibili
     → 点击 页面
     → 刷新网页
     → 结束
```

### 每条指令：锚点 · 搜索 · 验证

| # | 插入锚点（canvas 摘要关键词） | 搜索框 | LLM / 其它配置 | 保存后 canvas 摘要 |
|---|------------------------------|--------|----------------|-------------------|
| 1 | `开始` | `打开网页` | Shell pbcopy 网址 → 弹框 paste | `打开网页 url: https://www.bilibili.com` |
| 2 | `bilibili.com` | `输入文本` | pbcopy 搜索框描述 → LLM 确认；`type_text` 填 `bilibili` | `元素中输入 bilibili` |
| 3 | `元素中输入 bilibili` | `点击` | pbcopy 搜索按钮描述 → LLM 确认 | `点击 页面`（**禁止** `selectorId`） |
| 4 | `点击 页面` | `刷新网页` | 无必填；`dblclickWebResultLoose("刷新网页")` | `刷新网页` |

### LLM 自然语言（Shell pbcopy 前置）

| 元素 | 描述 |
|------|------|
| 搜索框 | `定位 Bilibili 首页顶部导航栏中间偏上的搜索输入框，用于输入搜索关键词` |
| 搜索按钮 | `定位 Bilibili 首页顶部导航栏搜索框右侧的搜索按钮，用于点击执行搜索` |

### 调试（全链路配置完成后 **仅 1 次**）

1. 顺序终检 + 点一次「检查」
2. 「调试 → 运行」（默认随机设备，不改弹框）
3. 四条业务指令均出现 `check-circle`：打开网页 ~3s、输入文本 ~15s、点击 ~14s、刷新 ~1.4s

> 聊天区可能残留早先误触调试的失败日志；以**最新时间戳**的 `check-circle` 为准，勿被历史 `selectorId` 报错误导。

### 常见修复

| 现象 | 修复 |
|------|------|
| 顺序错乱（如点击在输入前） | `reorderNodeCutPaste`（`insert-command.md` §剪切调序 sky 脚本） |
| canvas 显示 `点击 页面 selectorId` | 双击该节点 → `configLLMScoped` → 保存 |
| 搜「刷新网页」找不到 `(web)` | 用 `dblclickWebResultLoose("刷新网页")` |
| 「调试」「运行」按钮 disabled | 等「调试中」结束，或先点「断开」 |

## 元素选择器

B 站首页 DOM 会随版本变化，执行时 **默认先使用 `reference/element-selector.md` §方式 A：LLM 动态定位 / 新建 LLM** 进行语义定位；只有 LLM 保存后仍显示 `selectorId`、或调试报元素不存在时，才降级到 XPath 批量采集。

| 元素 | LLM 自然语言描述示例 | XPath 降级示例（仅供参考，以实测为准） |
|------|----------------------|--------------------------------|
| 顶部搜索框 | `定位 Bilibili 首页顶部导航栏中间偏上的搜索输入框，用于输入搜索关键词` | `//input[contains(@class,"nav-search-input")]` |
| 搜索按钮 | `定位 Bilibili 首页顶部导航栏搜索框右侧的搜索按钮，用于点击执行搜索` | 以 DevTools 输出中的 `id`/`class` 构造 |

> ⚠️ LLM 动态定位流程必须是：点击「新建 LLM」→ 填自然语言描述 → **点击「确认」** → 补其它必填项 → 保存。禁止填完描述后直接保存。
> XPath 仅作为降级方案；降级时需按 `element-selector.md` §批量采集（新建 Tab）一次性采集搜索框与搜索按钮 XPath。

## 执行步骤

1. `reference/platform-ops.md` §2.1 新建编排模式工作流
2. **按序插入指令**（`insert-command.md`）：锚点用 **canvas 摘要关键词**（如 `bilibili.com`、`元素中输入 bilibili`）；每条保存后核对顺序；**配置阶段禁止点「调试」**
3. **配置元素选择器**：输入文本 + 点击 → LLM 动态定位；保存后摘要不得含 `selectorId`
4. 全部指令保存后 → 一次「检查」→ 顺序终检
5. **一次性**「调试 → 运行」（见 §实测黄金路径）

## 与场景 A（百度）的差异

| 对比项 | 百度 | Bilibili |
|--------|------|----------|
| URL | `https://www.baidu.com` | `https://www.bilibili.com` |
| 搜索词 | `baidu` | `bilibili` |
| 选择器 | 已有实测 XPath，可直接用 | **默认 LLM 动态定位**（实测 2026-08-22）；XPath 为降级 |
| 页面特点 | textarea 搜索框 | 导航栏 input，结构随版本变化 |

## 元素选择器写入策略

配置「输入文本」「点击元素」等含「元素选择器」字段的指令时，按以下优先级写入 XPath：

| 优先级 | 方式 | 说明 | 何时用 |
|--------|------|------|--------|
| **1（默认）** | **[方式 C：pbcopy + Cmd+V 粘贴 XPath + Enter](../element-selector.md#方式-cpbcopy--cmdv-粘贴-xpath--enter默认策略)** | Shell 侧 pbcopy → 组合框 Cmd+V → Enter 让 AntD Select 落库 | 已通过批量采集 / locators 拿到 XPath 时**始终首选** |
| **2（退而求其次）** | **[方式 B：平台捕获](../element-selector.md#方式-b平台捕获按钮退而求其次)** | 云浏览器 VNC 点选目标元素 | 方式 C 连续失败 3 次 / XPath 含非 ASCII 时 |

> **Bilibili 场景提示**：B 站配置弹框的「元素选择器」是 AntD Select 组件；粘贴 XPath 后**必须紧接着按 Enter**，否则保存报「该字段是必填字段」。XPath 从批量采集结果取（`locators/bilibili.elements.json` 或上方「元素选择器」表）。
