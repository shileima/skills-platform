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
| 输入 `/` | 浮层可见「请输入」；Tab「指令」选中 | 无浮层；canvas 内多了 `/` 字符 |
| 浮层搜指令 | 列表出现目标指令名（如「打开网页」） | 列表为空或 Tab 不对 |
| 选中指令插入 | canvas 出现新节点编号；浮层关闭 | 浮层仍开；节点未增加 |
| **插入后顺序校验** | 新节点在**最后一条已有指令之后**、结束节点之前；依赖顺序满足（如「打开网页」在「输入文本」前） | 「输入文本」排在「打开网页」前；新节点插在开始节点下方而非末尾 |
| 双击开配置弹框 | 标题含指令名（如「输入文本(web)」）；「捕获」按钮可见 | 无弹框；仍在 canvas 编辑态 |
| 粘贴 XPath | 输入框 value 含 `//` | 输入框仍空 |
| 等 1s 后 | 下拉含「以 //xxx 为定位器」 | 仍无「为定位器」→ 再等或重粘贴 |
| 出现「未找到匹配结果」 | 下拉含该文案 | — → 点 close icon |
| 点「为定位器」 | 下拉关闭；选择器红框消失或 value 保留 | 仍红框；仍显示必填错误 |
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

```js
{
  const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const opened = lines.some(l => l.includes("输入文本") && (l.includes("web") || l.includes("捕获")));
  nodeRepl.write(JSON.stringify({ step: "A", panelOpen: opened }));
  // opened === false → 回到 platform-ops.md §2.2 重新双击
}
```

### Step B：粘贴元素选择器 XPath

```js
{
  // echo -n '//input[@id="kw"]' | pbcopy
  const s0 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const lines0 = s0.text.split("\n");
  const selIdx = parseInt(lines0.find(l =>
    l.includes("元素选择器") || (l.includes("settable") && l.includes("//"))
  )?.match(/^\s*(\d+)/)?.[1] ?? lines0.find(l =>
    l.includes("settable") && /文本栏|textfield/i.test(l)
  )?.match(/^\s*(\d+)/)?.[1]);

  await sky.click({ app: "com.google.Chrome", element_index: selIdx });
  await sky.press_key({ app: "com.google.Chrome", key: "cmd+a" });
  await sky.press_key({ app: "com.google.Chrome", key: "cmd+v" });

  const lines1 = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const pasted = lines1.some(l => l.includes('//input[@id="kw"]') || l.includes("//input"));
  nodeRepl.write(JSON.stringify({ step: "B", selIdx, pasted }));
  // pasted === false → 重找 selIdx 或重粘贴
}
```

### Step C：处理「未找到匹配结果」

```js
{
  const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const noMatch = lines.some(l => l.includes("未找到匹配结果"));
  if (noMatch) {
    const closeIdx = parseInt(lines.find(l =>
      (/关闭|close|清除|×/i.test(l) || (l.includes("按钮") && l.includes("×"))) &&
      !l.includes("未找到匹配结果")
    )?.match(/^\s*(\d+)/)?.[1]);
    if (closeIdx) await sky.click({ app: "com.google.Chrome", element_index: closeIdx });
  }
  const lines2 = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const stillNoMatch = lines2.some(l => l.includes("未找到匹配结果"));
  nodeRepl.write(JSON.stringify({ step: "C", noMatch, stillNoMatch }));
  // stillNoMatch === true → 重找 close icon
}
```

### Step D：等 1s → 点「为定位器」

```js
{
  await new Promise(r => setTimeout(r, 1000));
  const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const hintLine = lines.find(l => l.includes("为定位器"));
  const hintIdx = parseInt(hintLine?.match(/^\s*(\d+)/)?.[1]);
  nodeRepl.write(JSON.stringify({ step: "D", hasLocatorHint: !!hintLine, hintIdx }));
  if (!hintIdx) { /* 再等 1s 或重粘贴 XPath */ }
  else await sky.click({ app: "com.google.Chrome", element_index: hintIdx });

  const lines2 = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const locatorOk = lines2.some(l => l.includes('//input[@id="kw"]')) &&
    !lines2.some(l => l.includes("该字段是必填字段"));
  nodeRepl.write(JSON.stringify({ step: "D-verify", locatorOk }));
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
  const opened = lines.some(l => l.includes("打开网页") && (l.includes("web") || l.includes("网址")));
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
| `element-selector.md` C1 | 粘贴 → 验证 → close → 验证 → 等 1s → 验证 → 点定位器 → 验证 |
| `url-input.md` | 填网址：pbcopy 粘贴或 set_value → 验证含 `https://` → 保存 |
| `test-workflow.md` | 全流程遵循本模块循环 |
| `debug.md` | 调试前后各抓一次 AX，对比节点 icon 与聊天区 |
