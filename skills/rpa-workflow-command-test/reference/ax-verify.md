# 步骤衔接验证（AX Tree）

> **硬性规则**：每一次 `click` / `press_key` / `set_value` / `type_text` / 粘贴 之后，**必须**重新全量抓取 AX Tree，分析上一步是否成功，**再决定**下一步操作。
>
> **禁止**在一个代码块里连续执行多个 UI 动作而不中间验证。

## 基本循环

```
动作 → sky.get_app_state({ disableDiff: true }) → 分析 AX 文本 → 成功则下一步 / 失败则修复或重试
```

### 全量抓取（固定写法）

```js
const s = await sky.get_app_state({
  app: "com.google.Chrome",
  disableDiff: true   // 必须 true，拿完整 AX Tree，不用 diff
});
const lines = s.text.split("\n");
nodeRepl.write(JSON.stringify({ lineCount: lines.length, preview: lines.slice(0, 5) }));
```

> idx 来自**当前** AX Tree。上一步 UI 变化后 idx 会漂移，**禁止**复用上一步的 element_index。

### 分析辅助函数（可复制）

```js
// Ant Design Button autoInsertSpaceInButton：两字中文按钮 AX 标签可能带半角空格
// 例：「运行」→「运 行」，「重置」→「重 置」；顶部工具栏按钮可能无空格
function axHasLabel(line, label) {
  const re = new RegExp(label.split("").join("\\s*"));
  return re.test(line);
}
function axFindButton(lines, label) {
  return lines.find(l => axHasLabel(l, label) && l.includes("按钮"));
}
function axButtonIdx(lines, label) {
  const line = axFindButton(lines, label);
  return line ? parseInt(line.match(/^\s*(\d+)/)?.[1]) : null;
}

function axAnalyze(lines, checks) {
  const text = lines.join("\n");
  const find = (pred) => lines.find(pred);
  const findAll = (pred) => lines.filter(pred);
  const has = (substr) => lines.some(l => l.includes(substr));
  const idxOf = (pred) => {
    const line = find(pred);
    return line ? parseInt(line.match(/^\s*(\d+)/)?.[1]) : null;
  };
  return { text, find, findAll, has, idxOf, axHasLabel, axFindButton, axButtonIdx, ...checks };
}
```

> ⚠️ **按钮标签匹配**：调试弹框内按钮用 `axHasLabel(l, "运行")` / `axButtonIdx(lines, "运行")`，**禁止**仅用 `l.includes("运行")`——弹框内 Ant Design 按钮 AX 标签为「运 行」「重 置」，无空格写法会漏匹配。

## 常见动作 → 成功信号

| 上一步动作 | AX Tree 成功信号 | 失败 / 需重试信号 |
|-----------|-----------------|------------------|
| 导航 URL | 地址栏含目标 URL；页面出现预期标题/导航 | 仍停留在旧 URL；404/空白 |
| 点「工作流」 | URL 含 `/rpa/workflow`；列表或「新建工作流」可见 | 仍在 chat 页 |
| 光标定位到 canvas | 焦点在 canvas 编辑器；`focused UI element` 指向 canvas 内元素 | 焦点仍在别处（提示行/搜索框） |
| 搜索框 set_value 指令中文名 | 右侧「指令」面板出现 `xxx (web)` 结果行；含「网页自动化」分组 | 无结果；仍在旧搜索词 |
| 双击「网页自动化」分组下 `xxx (web)` | canvas 出现新节点编号；同时弹出配置弹框 | canvas 未变；无弹框 |
| **插入后顺序校验** | 新节点在**最后一条已有指令之后**、结束节点之前；依赖顺序满足（如「打开网页」在「输入文本」前） | 「输入文本」排在「打开网页」前；新节点插在开始节点下方而非末尾 |
| 双击开配置弹框 | **结构性多信号**：有「捕获」按钮 `/\d+ 按钮\s+捕\s*获/` **OR** 有「元素选择器」字段 **OR** 有「保存」按钮 | 无弹框；三个信号均无 |
| 粘贴 XPath（Cmd+V） | 组合框 Value 含 `//`；「该字段是必填字段」可能仍显示（需下一步 Enter） | 输入框仍空 |
| 按 Enter（**方式 C 核心**） | 组合框旁出现 `\d+ text //...` 独立行 + 「该字段是必填字段」消失 | 红字仍在 → 重新聚焦 Cmd+V 再 Enter；重试仍失败 → 转方式 B（捕获） |
| 填「待填充文本」 | 输入框含目标文本 | 仍空、仍红框 |
| 填「网址」/ URL 字段 | 输入框含 `https://`（非 `https//`） | 冒号丢失；仍空、仍红框 |
| **保存前总检** | 所有 label 前带 `*` 的字段已填；无红框；无「该字段是必填字段」 | 任一必填为空；输入框红框 → **禁止点保存** |
| 点「保存」 | 弹框关闭；canvas 节点保留 | 弹框仍在；「该字段是必填字段」 |
| 点顶部「调试」 | 右侧弹出调试面板；「选择我的浏览器环境」= **随机设备** | 弹框未出现 |
| 弹框点「运行」（**不改弹框表单**） | 执行中状态；聊天区出现日志 | 按钮灰；无日志；**误改设备/点重置**；**`includes("运行")` 漏匹配「运 行」**；**未做场景顺序终检即调试** |

## 插入后顺序校验（加指令后必做）

每次从浮层选中指令插入 canvas 后，**必须**全量抓 AX Tree 校验编排区顺序，再打开配置弹框。

### 校验规则

1. **追加位置**：新节点编号 = 当前业务指令最大编号 + 1，且位于「结束节点」之前
2. **依赖顺序**（Web 场景）：
   - 插入「输入文本」前，canvas 中已有「打开网页」且在其**上方**（编号更小）
   - 插入「点击」前，canvas 中已有「打开网页」
3. **非法示例**：`开始 → 输入文本 → 打开网页 → 结束` → 选中「输入文本」→ 右击 **剪切** → 选中「打开网页」→ **Enter** 创建空行 → **粘贴**（§2.3a，**不必先删除**）

### sky 自动化

```js
{
  const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const canvasStart = lines.findIndex(l => l.includes("编辑器容器"));
  const canvasText = lines.slice(canvasStart, canvasStart + 120).join("\n");

  const hasOpenUrl = canvasText.includes("打开网页");
  const hasFillText = canvasText.includes("输入文本");
  const hasClick = canvasText.includes("点击");

  const orderOk =
    (!hasFillText || (hasOpenUrl && canvasText.indexOf("打开网页") < canvasText.indexOf("输入文本"))) &&
    (!hasClick || hasOpenUrl);

  nodeRepl.write(JSON.stringify({
    step: "order-verify",
    orderOk,
    hasOpenUrl, hasFillText, hasClick,
    action: orderOk ? "continue-config" : "cut-node-and-paste-at-correct-position"
  }));
}
```

## 调试前场景顺序终检（点「调试」前必做）

单条指令插入后的顺序校验（§插入后顺序校验）只能保证**当时**追加正确。全部配置保存完毕、**点击「调试」之前**，还必须做一次**全场景终检**：对照 `reference/scenarios/<场景>.md`「指令节点」表，确认编排区 canvas 中业务指令的**数量、类型、先后顺序**与场景设计完全一致。

### 终检清单

```
□ 已 Read 当前场景文件，明确应有 N 条业务指令及顺序
□ canvas 中「开始节点」在最上、「结束节点」在最下
□ 中间业务指令条数 = 场景表行数
□ 每条指令类型与场景表对应序号一致（如 1=打开网页、2=输入文本、3=点击）
□ 通用依赖仍成立：「打开网页」在「输入文本」之前（若有）
□ 终检通过 → 才点「调试」；未通过 → 修正顺序后重新终检
```

### 与「插入后顺序校验」的区别

| 时机 | 目的 |
|------|------|
| 插入后顺序校验 | 每加一条指令后立即确认追加位置与依赖顺序 |
| **调试前场景顺序终检** | 全部保存后、调试前，对照场景表做**整链**最终确认 |

sky 自动化示例见 `test-workflow.md` §调试前场景顺序终检。

## 失败时的决策

1. **idx 找不到目标** → 重新全量抓取，换选择器重搜（不要盲点旧 idx）
2. **浮层/弹框状态不对** → `Escape` → 全量抓取确认关闭 → 从该步重来
3. **canvas 处于编辑态**（双击失败）→ 点调试区失焦 + `Escape` → 再双击
4. **同一动作连续 2 次验证仍失败** → 停止连点，报告当前 AX 关键行，换策略
5. **插入后顺序校验失败** → 选中错位节点 → 右击 **剪切** → 选中锚点行 → **Enter** 创建空行 → **粘贴**（`platform-ops.md` §2.3a）→ 再校验；剪切失败时再删后重插

## 示例：配置「输入文本(web)」逐步验证

以下每一步都是：**动作 → 全量 AX → 判断 → 才进入下一步**。

> 配置「**打开网页(web)**」的「网址」字段时，**禁止** `type_text`，须用 `pbcopy+paste` 或 `set_value`。完整示例见 **`url-input.md`**。

### Step A：确认配置弹框已打开

> ⚠️ **判据规范**：禁止用标题字符串精确匹配判断弹框状态。AX Tree 中的空格可能是 tab/nbsp（U+00A0）而非普通空格（U+0020），`includes` 对不可见字符零容忍，极易假阴性。必须用**结构性信号**做多信号 OR 判定。

```js
{
  const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");

  // ✅ 结构性多信号交叉验证（判据优先级从高到低）
  const hasCaptureBtn = lines.some(l => /\d+\s+按钮\s+捕\s*获/.test(l));
  const hasElementSelector = lines.some(l => l.includes("元素选择器") && /settable|textfield|文本栏/i.test(l));
  const hasSaveBtn = lines.some(l => /\d+\s+按钮\s+保\s*存/.test(l));
  const opened = hasCaptureBtn || hasElementSelector || hasSaveBtn;

  nodeRepl.write(JSON.stringify({
    step: "A",
    panelOpen: opened,
    signals: { hasCaptureBtn, hasElementSelector, hasSaveBtn }
  }));
  // opened === false → 回到 platform-ops.md §2.2 重新双击
  // 详细的捕获流程判据见 capture-element.md §判据设计原则
}
```

### AntD Select 阻断信号决策表

> 适用时机：Step B 完成后（Cmd+V 粘贴 XPath），全量抓 AX Tree 发现以下情况时进入本决策表。

| 粘贴后 AX 现象 | 下一步 |
|---|---|
| 组合框 Value 已含 `//` | **按 Enter**（Step D）——AntD Select confirm-input 逻辑会把粘贴文本作为 tag 提交给 React |
| Enter 后组合框旁出现 `\d+ text //...` 行 + 无「该字段是必填字段」 | 通过——直接进入 Step F 保存 |
| Enter 后仍有「该字段是必填字段」 | 重新 click 组合框 → Cmd+V → Enter（**三步紧凑，中间不要抓 AX 分心**） |
| 重试仍失败 | 转 `element-selector.md` §方式 B（云浏览器捕获） |
| Value 未粘贴进去（仍为空） | 重找 comboIdx 或检查剪贴板；或转方式 B |

```js
// axSelectStillRequired helper 示例：
// 返回 true 表示 AntD Select 阻断信号仍存在
const axSelectStillRequired = (lines) =>
  lines.some(l => l.includes('该字段是必填字段'));

// 用法：
const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
if (axSelectStillRequired(lines)) {
  // 只要仍为必填错误 → 按 Enter 再验；连续失败 3 次转方式 B（捕获）
  nodeRepl.write(JSON.stringify({ step: "antd-select-blocked", action: "press-Enter-again-or-fallback-to-capture" }));
}
```

### Step B：粘贴元素选择器 XPath 到 AntD Select 组合框

```js
{
  // echo -n '//input[@id="kw"]' | pbcopy
  const s0 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const lines0 = s0.text.split("\n");
  // 定位「* 元素选择器」标签，然后在下方 20 行内找组合框
  const labelIdx = lines0.findIndex(l => /text\s+\*\s+元素选择器/.test(l));
  const comboLine = lines0.slice(labelIdx, labelIdx + 20)
    .find(l => /组合框\s+\(settable, string\)/.test(l));
  const comboIdx = comboLine ? parseInt(comboLine.match(/^\s*(\d+)/)[1]) : null;

  await sky.click({ app: "com.google.Chrome", element_index: comboIdx });
  await new Promise(r => setTimeout(r, 400));
  await sky.press_key({ app: "com.google.Chrome", key: "Command+v" });
  await new Promise(r => setTimeout(r, 1200));

  const lines1 = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const pasted = lines1.some(l => /组合框.*settable.*\/\/input/.test(l));
  nodeRepl.write(JSON.stringify({ step: "B", comboIdx, pasted }));
  // pasted === false → 重找 comboIdx 或重粘贴
}
```

### Step D：按 Enter → 让 AntD Select 接受为定位器

```js
{
  await sky.press_key({ app: "com.google.Chrome", key: "Return" });
  await new Promise(r => setTimeout(r, 1500));

  const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const hasErr = lines.some(l => l.includes("该字段是必填字段"));
  const hasValue = lines.some(l => /text\s+\/\/input/.test(l) || /组合框.*settable.*\/\/input/.test(l));
  const locatorOk = hasValue && !hasErr;
  nodeRepl.write(JSON.stringify({ step: "D", hasErr, hasValue, locatorOk }));
  // locatorOk === false → 重新 click 组合框 → Cmd+V → Return（三步紧凑）
}
```

### Step E：填写「待填充文本」

```js
{
  // echo -n "baidu" | pbcopy
  const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const textIdx = parseInt(lines.find(l =>
    l.includes("待填充文本") || (l.includes("请输入文本") && l.includes("settable"))
  )?.match(/^\s*(\d+)/)?.[1]);
  await sky.click({ app: "com.google.Chrome", element_index: textIdx });
  await sky.press_key({ app: "com.google.Chrome", key: "cmd+v" });

  const lines2 = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const filled = lines2.some(l => l.includes("baidu"));
  nodeRepl.write(JSON.stringify({ step: "E", textIdx, filled }));
}
```

### Step F：保存前总检 → 点保存

```js
{
  const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const hasRequiredErr = lines.some(l => l.includes("该字段是必填字段"));
  const hasSelector = lines.some(l => l.includes('//input[@id="kw"]'));
  const hasText = lines.some(l => l.includes("baidu"));
  const canSave = hasSelector && hasText && !hasRequiredErr;
  nodeRepl.write(JSON.stringify({ step: "F", canSave, hasRequiredErr }));

  if (canSave) {
    const saveIdx = axButtonIdx(lines, "保存");
    await sky.click({ app: "com.google.Chrome", element_index: saveIdx });
    const lines2 = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
    const saved = !lines2.some(l => l.includes("输入文本") && l.includes("web") && axHasLabel(l, "保存"));
    nodeRepl.write(JSON.stringify({ step: "F-verify", saved }));
  }
}
```

## 示例：配置「打开网页(web)」网址字段

> ⚠️ **禁止** `type_text` — macOS 会丢失 `https` 后的冒号。详见 `url-input.md`。

### Step A：确认弹框已打开

```js
{
  const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");

  // ✅ 结构性多信号交叉验证
  const hasSaveBtn = lines.some(l => /\d+\s+按钮\s+保\s*存/.test(l));
  const hasUrlField = lines.some(l => l.includes("网址") && /settable|textfield|文本栏/i.test(l));
  const opened = hasSaveBtn || hasUrlField;

  nodeRepl.write(JSON.stringify({ step: "openurl-A", panelOpen: opened }));
}
```

### Step B：pbcopy + 粘贴网址 → 验证含 `https://`

```js
{
  // echo -n "https://www.baidu.com" | pbcopy
  const s0 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const urlIdx = parseInt(s0.text.split("\n").find(l =>
    l.includes("网址") && /settable|textfield/i.test(l)
  )?.match(/^\s*(\d+)/)?.[1]);

  await sky.click({ app: "com.google.Chrome", element_index: urlIdx });
  await sky.press_key({ app: "com.google.Chrome", key: "cmd+a" });
  await sky.press_key({ app: "com.google.Chrome", key: "cmd+v" });

  const lines1 = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const urlOk = lines1.some(l => l.includes("https://www.baidu.com"));
  const colonMissing = lines1.some(l => /https\/\//.test(l));
  nodeRepl.write(JSON.stringify({ step: "openurl-B", urlIdx, urlOk, colonMissing }));
  // colonMissing === true → 禁止 type_text 补救，重新 pbcopy 再粘贴
}
```

### Step C：保存前总检 → 点保存

```js
{
  const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const hasUrl = lines.some(l => l.includes("https://"));
  const hasRequiredErr = lines.some(l => l.includes("该字段是必填字段"));
  const canSave = hasUrl && !hasRequiredErr && !lines.some(l => /https\/\//.test(l));
  nodeRepl.write(JSON.stringify({ step: "openurl-C", canSave }));

  if (canSave) {
    const saveIdx = axButtonIdx(lines, "保存");
    await sky.click({ app: "com.google.Chrome", element_index: saveIdx });
  }
}
```

## 与其他模块的关系

| 模块 | 衔接验证要点 |
|------|-------------|
| `platform-ops.md` | 导航、加指令、开弹框、保存 — 每步后验证 |
| `capture-element.md` | 捕获元素 6 步流程 — 每步后用多信号交叉验证 |
| `element-selector.md` C1 | 粘贴 → 验证 → close → 验证 → 等 1s → 验证 → 点定位器 → 验证 |
| `url-input.md` | 填网址：pbcopy 粘贴或 set_value → 验证含 `https://` → 保存 |
| `test-workflow.md` | 全流程遵循本模块循环 |
| `debug.md` | 调试前后各抓一次 AX，对比节点 icon 与聊天区 |
