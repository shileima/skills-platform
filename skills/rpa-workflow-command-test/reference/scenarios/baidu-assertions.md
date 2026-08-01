# 场景 C：百度首页 9 条网页断言指令批量测试

**目标**：在同一工作流内批量测试**「网页自动化 → 网页断言」分组下所有 9 条断言指令**是否能正常添加、配置、保存、调试运行。

**工作流命名建议**：`断言指令测试-YYYYMMDD`

## 测试范围（9 条 · 覆盖平台"网页断言"分组全部）

| # | 平台指令名 | 指令标识 | reference |
|---|-----------|---------|-----------|
| 1 | 验证元素存在(web) | `VerifyElementPresent` | [verifyelementpresent.md](../commands/verifyelementpresent.md) |
| 2 | 验证元素可见(web) | `VerifyElementVisible` | [verifyelementvisible.md](../commands/verifyelementvisible.md) |
| 3 | 验证元素具有属性(web) | `VerifyElementHasAttribute` | [verifyelementhasattribute.md](../commands/verifyelementhasattribute.md) |
| 4 | 验证元素属性值(web) | `VerifyElementAttributeValue` | [verifyelementattributevalue.md](../commands/verifyelementattributevalue.md) |
| 5 | 验证元素不存在(web) | `VerifyElementNotPresent` | [verifyelementnotpresent.md](../commands/verifyelementnotpresent.md) |
| 6 | 验证元素没有属性(web) | `VerifyElementNotHasAttribute` | [verifyelementnothasattribute.md](../commands/verifyelementnothasattribute.md) |
| 7 | 验证元素不可见(web) | `VerifyElementNotVisible` | [verifyelementnotvisible.md](../commands/verifyelementnotvisible.md) |
| 8 | **验证文本存在** | `VerifyTextPresent` | [verifytextpresent.md](../commands/verifytextpresent.md) |
| 9 | **验证文本不存在** | `VerifyTextNotPresent` | [verifytextnotpresent.md](../commands/verifytextnotpresent.md) |

> ⚠️ 「验证文本存在」「验证文本不存在」**平台指令名不含 `(web)` 后缀**（右侧搜索时也只匹配单条结果 `文本 验证文本存在`，不是 `text 验证文本存在 (web)`），但它们**归属"网页自动化 → 网页断言"分组**。搜索/双击匹配时判据要与其它 7 条断言区分：`^\s*\d+\s+文本\s+验证文本(不)?存在$`。

## 指令节点顺序（10 条）

```
开始节点
  1  打开网页        (https://www.baidu.com)
  2  验证元素存在(web)          XPath=//*[@id="wrapper"]
  3  验证元素可见(web)          XPath=//*[@id="wrapper"]
  4  验证元素具有属性(web)      XPath=//*[@id="wrapper"], 属性名=id
  5  验证元素属性值(web)        XPath=//*[@id="wrapper"], 属性名=id, 属性值=wrapper
  6  验证元素不存在(web)        XPath=//*[@id="not-exist-abc-xyz"]
  7  验证元素没有属性(web)      XPath=//*[@id="wrapper"], 属性名=disabled
  8  验证元素不可见(web)        XPath=//meta[1]（DOM 存在但视觉不可见）
  9  验证文本存在              待验证文本=Baidu（百度首页版权栏含此文本）
  10 验证文本不存在            待验证文本=NotExistText123XYZ
结束节点
```

> 全部前置元素来自百度首页 `//*[@id="wrapper"]`（页面根 div，两种 UI 版本均存在），无需 XPath 采集，避开百度 A/B UI 差异（`element-selector.md` §百度搜索框探测）。

## 每条指令参数

### 1. 打开网页
- 网址：`https://www.baidu.com`（**pbcopy 粘贴 或 set_value**，禁止 type_text）

### 2. 验证元素存在(web)
- 元素选择器：`//*[@id="wrapper"]`

### 3. 验证元素可见(web)
- 元素选择器：`//*[@id="wrapper"]`

### 4. 验证元素具有属性(web)
- 元素选择器：`//*[@id="wrapper"]`
- 属性名称：`id`（type_text 填写，ASCII）

### 5. 验证元素属性值(web)
- 元素选择器：`//*[@id="wrapper"]`
- 属性名称：`id`
- 属性值：`wrapper`

> ⚠️ **易踩坑**：本指令有 3 个必填字段。粘贴 XPath 后**必须**紧接着 Enter 才让 AntD Select 落库；否则保存关闭后 canvas 节点显示为 `selectorId 元素的 id 属性值为 wrapper`（`selectorId` 是变量名占位符）—— 说明 XPath 未落库。修复见 `debug.md` §canvas 节点 selectorId 占位符判定。

### 6. 验证元素不存在(web)
- 元素选择器：`//*[@id="not-exist-abc-xyz"]`（DOM 中不存在的元素）

### 7. 验证元素没有属性(web)
- 元素选择器：`//*[@id="wrapper"]`
- 属性名称：`disabled`（wrapper div 不含 disabled 属性）

### 8. 验证元素不可见(web)
- 元素选择器：`//meta[1]`

> ⚠️ **语义边界**：本指令严格要求"元素**存在于 DOM 但对用户不可见**"。若填一个 DOM 里根本没有的 XPath（如 `//*[@id="not-visible-xyz"]`），平台会因元素定位失败判为**断言失败**（`check-circle 断言失败`），而不是"通过"。填 `//meta[1]`、`//title`、`//script[1]` 等 DOM 存在但 CSS `display:none` 的元素才可能通过；受平台实现影响，个别版本仍可能判失败——本条最稳妥的是用一个 `style="display:none"` 的可见元素。

### 9. 验证文本存在
- 待验证文本：`Baidu`（百度首页版权行 `©2026 Baidu`）

> ⚠️ **字段类型 = 文本输入区（Monaco 类）**，`set_value` 与 `Cmd+V` **中文**都可能失败；用 `type_text` 输入 ASCII 是最稳的方式。中文文本需要时先 pbcopy → 强制 Chrome 置顶 → Cmd+V，或者选择百度首页里稳定存在的英文串（如 `Baidu`）。

### 10. 验证文本不存在
- 待验证文本：`NotExistText123XYZ`（百度首页无此字符串）

## 关键操作流程（顺序追加）

按 [test-workflow.md](../test-workflow.md) 标准流程，插入操作遵循 `insert-command.md`，**每一条新指令**都要严格执行：

```
1. 光标定位（insert-command.md §插入位置约束）：
   - 首条：点 canvas「拖拽添加指令」提示行
   - 非首条：点 canvas 上"最后一条已保存节点的末尾 text 行" → Enter 空出新行
2. 若右侧 Tab 已切回 Chat（首次调试后常见）→ 点"指令" Tab
3. 搜索框 set_value 中文指令名（无 (web) 后缀，如"验证元素可见"）
4. 双击"网页断言"分组下匹配结果
5. 弹框内按参数表填字段：
   - 元素选择器 → **方式 C**：click 组合框 → Cmd+V → Enter → 校验 `text //...` 独立行出现
   - 属性名称/属性值 → click 输入区 → Cmd+V（ASCII 可靠）或 type_text
   - 待验证文本 → type_text ASCII（中文时需 pbcopy+Cmd+V 且 Chrome 保持前台）
6. 点保存 → 校验 canvas 上新节点末尾 text（应含 XPath 和"保存至 本节点"）
7. 插入后强制核对（insert-command.md §插入后强制核对）：新节点排在锚点指令之后
8. 关键校验：新节点的第二行文本必须是完整 XPath（如 `//*[@id="wrapper"]`），若显示 `selectorId` 或变量名占位 → **XPath 未落库**，双击节点重开弹框重填
```

## 调试与预期

- **所有 9 条断言**：`check-circle` 图标 + 有耗时（无 `close-circle` 表示指令本身工作正常）
- **8 条业务断言通过**：canvas 节点仅显示 `check-circle`
- **验证元素不可见(web)**：可能显示 `check-circle 断言失败`——指令执行正常，只是业务预期与实际不符（受平台对"元素不存在"是否等价于"不可见"的实现差异影响）

## 常见问题速查

| 现象 | 原因 | 处理 |
|------|------|------|
| canvas 上节点显示 `selectorId 元素的...` | XPath 未粘贴生效 | 双击重开弹框，方式 C 重填 |
| 中文粘贴不入"待验证文本" | 文本输入区（Monaco 类） + Cmd+V IME 冲突 | 改用 type_text + ASCII；或强制 Chrome 前台后重试 Cmd+V |
| Chrome 报 `cgWindowNotFound` | 焦点被系统抢走 | `osascript -e 'tell application "System Events" to set frontmost of application process "Google Chrome" to true'` + `sleep 2` |
| 修改已有 XPath tag 时 Backspace 无效 | AntD Select tag 无法用键盘删除 | click 组合框 → Cmd+A → Cmd+V（新值替换）→ Enter |
| 保存后右侧切回 Chat Tab | 平台默认行为 | 每次追加新指令前先 click "指令" Tab（idx 会变，用 `文本 指令` 精确匹配） |

## 复用价值

该场景是**任何"网页断言分组"回归测试**的模板：修改指令列表和 XPath 参数即可套用到其他站点。所有断言指令的必填字段都被覆盖（元素选择器 / 属性名称 / 属性值 / 待验证文本 / 输出变量）。
