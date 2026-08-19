# 场景：搜狗搜索（打开网页 / 导航到URL / 输入文本 / 点击 / 刷新）

**目标**：打开 [搜狗首页](https://www.sogou.com/) → 搜索框输入 `sogou` → 点击「搜索」→ （可选）刷新网页

**工作流命名建议**：`搜狗指令测试-YYYYMMDD`（或用户指定名称）

> ⚠️ **用户意图优先**（`user-intent.md`）：用户明确说「**导航到url / 导航到URL**」时，第 1 步必须用 **`导航到URL`**（`navigatetourl.md`），**禁止**用本表默认的「打开网页」。用户只列 3 条指令时**不要**擅自加「刷新网页」。

## 元素选择器（已验证 DOM）

| 元素 | XPath |
|------|-------|
| 搜索框 | `//*[@id="query"]` |
| 搜索按钮 | `//*[@id="stb"]` |

> 首页表单：`input#query` + `input#stb`（value="搜索"）。配置前可用 Cmd+T 打开 `https://www.sogou.com/` 在 DevTools 快速验证 visible。

## 指令节点

### 默认（用户未指定指令名时）

| 序号 | 指令 | reference | 关键配置 |
|------|------|-----------|---------|
| 1 | 打开网页 | [openurl.md](../commands/openurl.md) | 网址：`https://www.sogou.com/`（pbcopy 粘贴，见 [url-input.md](../url-input.md)） |
| 2 | 输入文本 | [filltext.md](../commands/filltext.md) | 元素：`//*[@id="query"]`；待填充文本：`sogou` |
| 3 | 点击元素（推荐） | [clickelementmixed.md](../commands/clickelementmixed.md) | 元素：`//*[@id="stb"]` |
| 4 | 刷新网页 | [reloadpage.md](../commands/reloadpage.md) | 无必填参数，直接保存 |

### 用户指定「导航到url」时（覆盖第 1 步）

| 序号 | 指令 | reference | 关键配置 |
|------|------|-----------|---------|
| 1 | **导航到URL** | [navigatetourl.md](../commands/navigatetourl.md) | **导航到的网址**：`https://www.sogou.com/`（pbcopy 粘贴，见 [url-input.md](../url-input.md)） |
| 2 | 输入文本 | [filltext.md](../commands/filltext.md) | 同上 |
| 3 | 点击元素（推荐） | [clickelementmixed.md](../commands/clickelementmixed.md) | 同上 |

> 用户消息示例：`以 sogou.com 测试导航到url，输入文本、点击元素` → 仅上表 3 行，**不含**刷新。

## 执行步骤

1. **`user-intent.md`** 解析 instructionPlan → 再 Read 本文件取 URL/XPath
2. `reference/platform-ops.md` §2.1 新建编排模式工作流
3. **按 instructionPlan 顺序插入**（`insert-command.md`）：搜索名用 plan 中的 `searchName`，**禁止**默认搜「打开网页」
4. **批量采集**（可选）：新建 Tab 打开 sogou.com 验证 `#query` / `#stb`
5. 逐条配置保存 → 每条保存后点「检查」
6. 调试前终检通过且无报错 → **直接调试运行**（`test-workflow.md` §无报错即调试门控）
7. 四处扫描全部通过 → 完成；有失败 → `debug.md` 修复后再调试

## 元素选择器写入

粘贴 XPath 后**必须按 Enter**（`element-selector.md` §方式 C）。canvas 显示 `元素库` / `selectorId` 表示未落库，须双击重配。

## 调试预期

| 节点 | 预期 |
|------|------|
| 打开网页 / 导航到URL | 云浏览器打开搜狗首页 |
| 输入文本 | `#query` 出现 `sogou` |
| 点击 | 进入搜索结果页 |
| 刷新网页 | 页面 reload（仅用户要求或默认四步时） |
