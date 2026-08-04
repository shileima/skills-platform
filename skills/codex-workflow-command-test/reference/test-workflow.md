# 指令测试标准流程

本技能的核心目标：**在 RPA 平台空工作流中，按顺序添加待测指令，配好表单后调试运行，根据报错修复，直到全部通过。**

> 进入本模块前，**必须已完成** `reference/prerequisites.md`。

> ⚠️ **sky 自动化硬性规则**：每一次 click / 输入 / 粘贴后，**全量抓取 AX Tree**（`disableDiff: true`），验证上一步成功再执行下一步。详见 **`reference/ax-verify.md`**。

## 测试前提

1. 打开 **rpa.sankuai.com 首页**（`https://rpa.sankuai.com/rpa/chat`），**禁止**直达 `/rpa/workflow`；左侧点击「**工作流**」进入
2. **新建一个工作流**（编排模式），得到仅含「开始节点」「结束节点」的空工作流
3. 在**编排区**按测试场景规定的**顺序**插入待测指令（不可打乱顺序）
4. 每条指令：**完善表单配置** → **保存** → **点「检查」确认无配置异常**；保存时报错则当场修复
5. 全部指令配置完成后：**调试前场景顺序终检** + **编排区右侧配置警示终检** → **调试** → 弹框点 **运行**，执行工作流
6. 执行结束后检查**四处**报错来源：聊天区日志、编排区左侧执行 icon、编排区右侧配置 icon、「检查」面板（见 §第 5 步）
7. 根据报错修复；若同一指令多次修复仍失败，**删除该指令并在原位置重新插入、重新配置**

## 完整流程

```
新建空工作流
  → 编排区按序添加指令（/ → 浮层搜索框输入中文名）
  → 逐条打开配置面板、填写表单、保存 → 点「检查」确认无配置异常
  → 调试前场景顺序终检 + 编排区右侧配置警示终检
  → 调试 → 运行
  → 读聊天区 + 编排区左侧执行 icon + 右侧配置 icon + 「检查」面板
  → 修复 → 再调试
  → （必要时）删指令 → 原位重插 → 重配表单
  → 直到无配置/执行警示且「检查」无异常
```

## 第 1 步：进入首页 → 点击「工作流」→ 新建空工作流

> ⚠️ **禁止**在地址栏直接打开 `https://rpa.sankuai.com/rpa/workflow`。必须先进入**首页**，再通过左侧导航点击「工作流」进入。

### 1a. 打开 RPA 首页

```js
{
  const s = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const addrLine = s.text.split("\n").find(l => /settable, string/.test(l) && /地址/.test(l));
  const addrIdx = parseInt((addrLine || "10 ").match(/^\s*(\d+)/)[1]);
  await sky.set_value({ app: "com.google.Chrome", element_index: addrIdx, value: "https://rpa.sankuai.com/rpa/chat" });
  await sky.press_key({ app: "com.google.Chrome", key: "Return" });
  await new Promise(r => setTimeout(r, 2000));
}
```

> URL 导航必须用 `set_value` + `Return`，**不能用** `type_text`（会污染地址栏）。

### 1b. 点击左侧导航「工作流」

```js
{
  const s = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const line = s.text.split("\n").find(l => l.includes("工作流") && /链接|按钮|link|button/i.test(l));
  const wfIdx = parseInt((line || "").match(/^\s*(\d+)/)?.[1]);
  nodeRepl.write("工作流 idx: " + wfIdx);
  await sky.click({ app: "com.google.Chrome", element_index: wfIdx });
  await new Promise(r => setTimeout(r, 1500));
}
```

成功后 URL 变为 `.../rpa/workflow`，页面显示工作流列表。

### 1c. 新建编排模式空工作流

1. 点击「**+ 新建工作流**」
2. 选择「**编排模式**」，填写名称（如 `指令测试-YYYYMMDD`）并保存
3. 确认编排区仅有 **开始节点** 和 **结束节点**，中间无其他指令

> 若 rpa 入口不可用，可改走 bots 空间：`https://bots.sankuai.com` → 新建编排模式工作流（见 `platform-ops.md` §2.1）。

## 第 2 步：编排区按顺序添加指令

在**开始节点下方**起建，按场景顺序依次插入指令（如：打开网页 → 输入文本 → 点击 → 刷新网页）。

> ⚠️ **Enter 空行插入**（详见 `insert-command.md` §插入位置约束）：
> - **首条**：选中**开始节点 → Enter** → 在开始节点下方空行插入
> - **向后追加**：选中**锚点指令**（要在其后面插入的那条；顺序构建时为最后一条）→ **Enter** → 空行 → 搜索+双击
> - **向前插入**：选中**目标指令的上一条** → **Enter** → 空行 → 搜索+双击或粘贴
> - **禁止**：从结束节点上方起建（旧流程）、无锚点搜索插入、在结束节点上按 Enter 作为起点

操作要点（详见 `insert-command.md`）：

- **先定位插入点**：首条 → **开始节点 + Enter**；向后追加 → **锚点指令 + Enter**；向前插入 → **目标上一条 + Enter** → 全量抓 AX 验证空行已生成
- 在右侧「指令」Tab 搜索框（placeholder「请输入」）**set_value 中文指令名**，如「打开网页」「输入文本」「点击」「验证元素存在」「验证元素可见」
- **双击**「网页自动化」分组下匹配的 `xxx (web)` 结果——平台自动在 canvas 末尾追加节点并弹出配置弹框
- **禁止**其他添加方式：输入 `/` 唤起浮层、拖拽指令项、复制现有节点、直接在 canvas 敲字搜索
- **插入后立即强制校验顺序**（`ax-verify.md` §插入后顺序校验、`insert-command.md` §插入后强制核对）：确认新指令确实排在锚点指令**之后**（如「打开网页」必须在「输入文本」之前），不符合则**立即停止**不得继续配表单
- **严格按场景顺序**逐条添加；每加一条立即配置保存

### 正确 vs 错误顺序示例（百度搜索）

| 编排区顺序 | 判定 |
|-----------|------|
| 开始 → **打开网页** → **输入文本** → **点击** → 结束 | ✅ 正确 |
| 开始 → **输入文本** → **打开网页** → 结束 | ❌ 错误：选中「输入文本」→ 右击 **剪切** → 选中「打开网页」→ 按 **Enter** 创建空行 → **粘贴**（见 `insert-command.md` §右键菜单调整指令顺序，不必先删除） |

## 第 3 步：完善表单并保存

> **前置（需 XPath 时）**：配置任何「元素选择器」之前，先按 `element-selector.md` **§批量采集（新建 Tab）**——**Cmd+T 新建 Tab** 打开目标页，DevTools **一次性采齐本任务全部 XPath**，切回工作流 Tab 后再填表。禁止在工作流 Tab 地址栏导航探测。

1. **双击**指令节点打开配置弹框（见 `platform-ops.md` §2.2 双击规范）
2. 在「**常规**」Tab 按 `reference/commands/<指令>.md` 填写参数
3. 需要元素选择器时：优先用 §批量采集 得到的 XPath 清单；或 Read `reference/locators/<site>.elements.json`
4. **保存前校验**（见 `platform-ops.md` §2.4，**必做、不可跳过**）：
   - Read `commands/<指令>.md`，对照弹框「输入参数」区 **label 前的红色 `*`** 识别必填项
   - **条件必填**（规则 3）：对照 `commands/<指令>.md` 参数表「说明」列——当某 Enum（如「设置方式」）取特定值时，另一字段变为必填（如 SetCookie：`根据指定Domain和path设置Cookie` → **Domain 必填**；`根据URL设置Cookie` → **URL 必填**）。**禁止**把 Domain 的值误填进 Path 等相邻字段
   - 所有带 `*` 的必填项已填写且**不为空**
   - 弹框内**无任何必填输入框仍带红色边框**
   - 元素选择器：**首选** `pbcopy` + `Cmd+V` 粘贴 XPath → **Enter**（`element-selector.md` §方式 C）；连续失败 3 次转 **方式 B（捕获）**——**禁止**其他方式
   - **任一必填项未填 → 禁止点「保存」**，先补全再保存
5. 校验全部通过后，点弹框右下角「**保存**」
6. **保存后立即做配置校验**（规则 1，见 §保存后配置校验）：点顶部「检查」，确认下拉无「节点配置不完整」
7. **保存阶段仍报错**（如「该字段是必填字段」）→ 说明保存前校验遗漏，当场修复，**不得**带错进入调试

常见保存报错：

| 现象 | 处理 |
|------|------|
| 必填项输入框红色边框 / 「该字段是必填字段」 | 补全字段；元素选择器 XPath：Cmd+V 粘贴后 **按 Enter**（`element-selector.md` §方式 C） |
| 元素选择器为空 | 按 `element-selector.md` §批量采集（新建 Tab）重采，或从 locators 缓存复制 |
| URL 未生效 / 显示 `https//` | 用 pbcopy + cmd+v 粘贴或 set_value，**禁止** type_text（见 `url-input.md`） |
| 「检查」下拉出现「节点配置不完整」 | 双击该节点重开弹框，按 `commands/<slug>.md` 补全**条件必填**（如 SetCookie 的 Domain），保存后再点「检查」 |

### 条件必填示例（SetCookie）

| 设置方式 | 额外必填 | 常见误填 |
|---------|---------|---------|
| 根据 URL 设置 Cookie | `URL` | 只填 Name/Value，漏 URL |
| 根据指定 Domain 和 path 设置 Cookie | `Domain` | 把 `.example.com` 填进 **Path** 而 Domain 留空 |

## 保存后配置校验（必做 · 规则 1 · 每条保存后）

弹框保存关闭后，**必须**点页面顶部「**检查**」按钮，读取下拉面板内容。这与调试无关——**未调试时**也可能出现配置异常。

| 视觉信号 | 含义 | Agent 操作 |
|---------|------|-----------|
| 「检查」按钮右上角**红色数字 badge**（如 `1`） | 存在配置异常节点 | 点开「检查」，读下拉列表 |
| 下拉标题「**配置异常节点**」 | 配置校验面板已打开 | 读取每一行节点名 + 右侧红色「节点配置不完整」 |
| 下拉内「**节点配置不完整**」 | 该节点落盘不完整或条件必填未满足 | 双击该节点 → 按 `commands/<slug>.md` 修复 → 保存 → **再点「检查」** |

> ⚠️ **禁止**在「检查」仍有 badge 或下拉仍列出异常节点时进入调试。

### sky 自动化：保存后点「检查」读面板

```js
{
  function axHasLabel(line, label) {
    return new RegExp(label.split("").join("\\s*")).test(line);
  }
  function axButtonIdx(lines, label) {
    const line = lines.find(l => axHasLabel(l, label) && l.includes("按钮"));
    return line ? parseInt(line.match(/^\s*(\d+)/)?.[1]) : null;
  }

  const s0 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const lines0 = s0.text.split("\n");
  const checkIdx = axButtonIdx(lines0, "检查");
  if (!checkIdx) {
    nodeRepl.write(JSON.stringify({ step: "config-check-panel", error: "未找到「检查」按钮" }));
  } else {
    await sky.click({ app: "com.google.Chrome", element_index: checkIdx });
    await new Promise(r => setTimeout(r, 600));

    const s1 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
    const lines1 = s1.text.split("\n");
    const panelOpen = lines1.some(l => l.includes("配置异常节点"));
    const incompleteLines = lines1.filter(l => l.includes("节点配置不完整"));
    const anomalyLines = lines1.filter(l =>
      panelOpen && /设置|打开网页|输入文本|点击|Cookie|延迟|删除/.test(l) &&
      lines1[lines1.indexOf(l) + 1]?.includes("节点配置不完整")
    );

    nodeRepl.write(JSON.stringify({
      step: "config-check-panel",
      panelOpen,
      configOk: incompleteLines.length === 0 && !panelOpen,
      incompleteLines: incompleteLines.slice(0, 10),
      action: incompleteLines.length === 0 ? "continue" : "fix-node-and-recheck"
    }));
  }
}
```

## 调试前场景顺序终检（必做 · 点「调试」前）

全部指令保存成功后、**点击「调试」之前**，必须对照当前测试场景的 `reference/scenarios/<场景>.md` 中「指令节点」表，逐条核对编排区 canvas 中的**指令类型与先后顺序**。

> ⚠️ **禁止**在顺序未通过终检时点击「调试」——顺序错误会导致 FillText/导航等必然失败，浪费调试轮次。

### 终检步骤

```
1. Read 当前场景文件（如 scenarios/baidu.md）→ 记下「指令节点」表的序号与指令类型
2. 目视编排区 canvas，或全量抓 AX Tree，列出实际顺序：开始 → … → 结束
3. 逐条对比：指令数量、类型、顺序是否与场景表一致
4. 全部匹配 → 方可进入「调试 → 运行」
5. 任一不匹配 → 按 `insert-command.md` §右键菜单调整指令顺序 **剪切→粘贴**（首选）；剪切失败再删后重插 → 再终检
```

### 以百度搜索为例

| 场景表（baidu.md） | 编排区 canvas 应有顺序 |
|-------------------|----------------------|
| 1 打开网页 | 开始 → **打开网页** → … |
| 2 输入文本 | … → **输入文本** → … |
| 3 点击元素 | … → **点击** → 结束 |

**通过示例**：`开始 → 打开网页 → 输入文本 → 点击 → 结束` ✅

**失败示例**：`开始 → 输入文本 → 打开网页 → 点击 → 结束` ❌ → 修正后再调试

### sky 自动化：调试前顺序终检

```js
{
  const scenario = ["打开网页", "输入文本", "点击"]; // 按当前场景 scenarios/*.md 填写
  const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const canvasStart = lines.findIndex(l => l.includes("编辑器容器"));
  const canvasText = lines.slice(canvasStart, canvasStart + 120).join("\n");

  const actual = scenario.filter(k => canvasText.includes(k));
  const orderOk = scenario.every((k, i) => {
    const idx = canvasText.indexOf(k);
    if (idx === -1) return false;
    if (i === 0) return true;
    return idx > canvasText.indexOf(scenario[i - 1]);
  });
  const countOk = scenario.every(k => canvasText.includes(k));

  nodeRepl.write(JSON.stringify({
    step: "pre-debug-order-check",
    scenario,
    countOk,
    orderOk,
    readyForDebug: countOk && orderOk,
    action: countOk && orderOk ? "click-debug" : "fix-order-first"
  }));
}
```

> 详细校验规则与插入后校验见 `ax-verify.md` §插入后顺序校验、§调试前场景顺序终检。

## 调试前配置终检（必做 · 规则 2 · 点「调试」前）

场景顺序终检通过后、**点击「调试」之前**，必须确认编排区**无静态配置警示**。

平台有两套 icon，**不可混淆**：

| 位置 | 含义 | 何时出现 |
|------|------|---------|
| 指令行**左侧** | ✅ 执行通过 / ❌ 调试失败 | 调试运行**之后** |
| 指令行**右侧** | 红色 ⓘ「**节点配置不完整**」 | 配置未满足平台规则（**可不调试就出现**） |

> ⚠️ 左侧全绿 ✅ **不能**代表配置完整；必须单独扫**右侧**配置警示，并配合「检查」面板（规则 1）双重确认。

### 终检步骤

```
1. 全量抓 AX Tree，在「编辑器容器」区域内搜索「节点配置不完整」
2. 目视编排区：任一指令行右侧有红色 ⓘ → 禁止调试，先修复该节点
3. 点「检查」→ 下拉无异常（可与 §保存后配置校验 同一脚本复用）
4. 以上全部通过 → 方可点「调试」
```

### sky 自动化：编排区配置 + 执行状态扫描

```js
{
  function axHasLabel(line, label) {
    return new RegExp(label.split("").join("\\s*")).test(line);
  }
  function axButtonIdx(lines, label) {
    const line = lines.find(l => axHasLabel(l, label) && l.includes("按钮"));
    return line ? parseInt(line.match(/^\s*(\d+)/)?.[1]) : null;
  }

  const s = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const lines = s.text.split("\n");
  const canvasLine = lines.findIndex(l => l.includes("编辑器容器"));
  const area = lines.slice(canvasLine, canvasLine + 150);

  // 规则 2：静态配置警示（右侧 icon 在 AX 中常体现为同行「节点配置不完整」文案）
  const configIncomplete = area.filter(l => l.includes("节点配置不完整"));
  // 调试后执行失败（左侧 close-circle 等）
  const execErrors = area.filter(l => /close-circle|执行失败|运行失败/i.test(l));

  // 规则 1 补充：点「检查」读面板
  const checkIdx = axButtonIdx(lines, "检查");
  let checkPanelOk = true;
  let incompleteFromPanel = [];
  if (checkIdx) {
    await sky.click({ app: "com.google.Chrome", element_index: checkIdx });
    await new Promise(r => setTimeout(r, 600));
    const s2 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
    incompleteFromPanel = s2.text.split("\n").filter(l => l.includes("节点配置不完整"));
    checkPanelOk = incompleteFromPanel.length === 0;
  }

  const readyForDebug = configIncomplete.length === 0 && checkPanelOk;

  nodeRepl.write(JSON.stringify({
    step: "pre-debug-config-check",
    configIncomplete: configIncomplete.slice(0, 10),
    incompleteFromPanel: incompleteFromPanel.slice(0, 10),
    execErrors: execErrors.slice(0, 10),
    readyForDebug,
    action: readyForDebug ? "click-debug" : "fix-config-first"
  }));
}
```

## 第 4 步：调试运行

**前置**：§调试前场景顺序终检 **且** §调试前配置终检 均已通过。

全部指令保存成功后：

1. 点页面顶部「**调试**」按钮
2. 弹框中**直接**点「**运行**」（**无需配置弹框表单**，「选择我的浏览器环境」默认已是「**随机设备**」）
3. 等待执行结束

```js
{
  // axHasLabel / axButtonIdx 见 ax-verify.md §分析辅助函数（兼容 Ant Design「运 行」）
  function axHasLabel(line, label) {
    return new RegExp(label.split("").join("\\s*")).test(line);
  }
  function axButtonIdx(lines, label) {
    const line = lines.find(l => axHasLabel(l, label) && l.includes("按钮"));
    return line ? parseInt(line.match(/^\s*(\d+)/)?.[1]) : null;
  }

  const s = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const lines = s.text.split("\n");
  await sky.click({ app: "com.google.Chrome", element_index: axButtonIdx(lines, "调试") });
  const s2 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  await sky.click({ app: "com.google.Chrome", element_index: axButtonIdx(s2.text.split("\n"), "运行") });
}
```

> 调试结束后「调试」按钮变灰 → 先点「**断开**」再重新调试。

## 第 5 步：检查报错（四处必看）

执行完成后，**必须同时检查**以下四个位置：

### A. 聊天区调试日志

- 位置：页面右侧或底部 **Chat / 调试输出 / 聊天区**
- 内容：每条指令的执行日志、异常堆栈、FillText/导航失败等文字报错
- 操作：滚动读取完整日志，记录**第一条失败指令**的错误码与描述

### B. 编排区指令左侧 — 执行结果 icon

- 位置：编排区每条指令**左侧**状态 icon
- ✅ 绿色 check-circle：该节点**本次调试**执行通过
- ❌ **红色 close-circle / 报错 icon**：该节点**本次调试**执行失败
- 操作：从第一个失败节点开始修复，不要跳过

### C. 编排区指令右侧 — 配置警示 icon（规则 2）

- 位置：编排区每条指令**右侧**
- 红色 ⓘ +「**节点配置不完整**」：配置仍不完整（与是否刚跑完调试无关）
- 操作：双击该节点 → 按 `commands/<slug>.md` 补全条件必填 → 保存 → 点「检查」确认

### D. 顶部「检查」面板（规则 1）

- 点「检查」→ 下拉无「配置异常节点」列表、无「节点配置不完整」文案、按钮无红色 badge

### sky 自动化：执行后四处扫描

```js
{
  function axHasLabel(line, label) {
    return new RegExp(label.split("").join("\\s*")).test(line);
  }
  function axButtonIdx(lines, label) {
    const line = lines.find(l => axHasLabel(l, label) && l.includes("按钮"));
    return line ? parseInt(line.match(/^\s*(\d+)/)?.[1]) : null;
  }

  const s0 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const lines0 = s0.text.split("\n");
  const canvasLine = lines0.findIndex(l => l.includes("编辑器容器"));
  const area = lines0.slice(canvasLine, canvasLine + 150);
  const fullText = lines0.join("\n");

  // B：左侧执行失败
  const execErrors = area.filter(l => /close-circle|执行失败|运行失败/i.test(l));
  // C：右侧配置不完整
  const configIncomplete = area.filter(l => l.includes("节点配置不完整"));
  // A：聊天区（粗略；仍建议滚动目视）
  const chatErrors = lines0.filter(l =>
    /FillText|导航失败|元素不存在|异常|error|失败/i.test(l) &&
    /聊天|Chat|调试输出|消息/.test(lines0[Math.max(0, lines0.indexOf(l) - 3)] || "")
  );

  // D：检查面板
  const checkIdx = axButtonIdx(lines0, "检查");
  let incompleteFromPanel = [];
  if (checkIdx) {
    await sky.click({ app: "com.google.Chrome", element_index: checkIdx });
    await new Promise(r => setTimeout(r, 600));
    const s1 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
    incompleteFromPanel = s1.text.split("\n").filter(l => l.includes("节点配置不完整"));
  }

  const allOk =
    execErrors.length === 0 &&
    configIncomplete.length === 0 &&
    incompleteFromPanel.length === 0 &&
    !/error|失败|异常/i.test(fullText.split("编辑器容器")[0] || ""); // 聊天区粗检，失败则目视补查

  nodeRepl.write(JSON.stringify({
    step: "post-debug-four-way-check",
    execErrors: execErrors.slice(0, 10),
    configIncomplete: configIncomplete.slice(0, 10),
    incompleteFromPanel: incompleteFromPanel.slice(0, 10),
    chatErrorHints: chatErrors.slice(0, 10),
    allOk,
    action: allOk ? "test-pass" : "fix-and-rerun"
  }));
}
```

**判定通过**：聊天区无报错日志；编排区**左侧**全部 ✅；**右侧**无配置警示；「检查」面板无异常。

## 第 6 步：根据报错修复

按 `reference/debug.md` 错误对照表修复，常见路径：

| 报错 | 修复 |
|------|------|
| 元素不存在 / FillText 失败 | 更新 locators 缓存或重新采集 XPath |
| 导航失败 | 检查 URL，pbcopy 重填 |
| 选择器指向 div 容器 | 换精确 XPath（textarea/input/button） |
| 云浏览器断线 | 重新连接设备后再调试 |
| 「节点配置不完整」/ SetCookie Domain 为空 | 双击节点 → 按 `commands/setcookie.md` 补 Domain（勿把域名填进 Path）→ 保存 → 点「检查」 |

修复后：**保存** → **点「检查」** → **断开**（若需要）→ **再调试 → 运行** → 回到第 5 步。

## 第 7 步：多次失败 — 删指令原位重插

同一指令**修复 2～3 次仍失败**时，不要继续在脏状态上改：

1. **选中**该指令节点，按 `Delete` / `Backspace` 删除
2. 在**原位置**（选中锚点指令 → Enter 空行，保持顺序）重新走搜索+双击流程（右侧「指令」Tab 搜索框 → 双击「网页自动化」分组下 `xxx (web)` 结果）
3. **从零填写**配置表单（元素选择器、URL 等全部重填，不要复制旧配置）
4. 保存 → 调试 → 运行 → 回到第 5 步

> 重插适用于：选择器状态异常、保存未真正生效、canvas 节点状态损坏等「配了但不生效」的情况。

## 完成标准

- [ ] 空工作流中已按场景顺序添加全部指令
- [ ] 每条指令表单已保存，保存前必填项与**条件必填**均已满足，且无校验报错
- [ ] 每条保存后「检查」面板无「节点配置不完整」、按钮无红色 badge
- [ ] **调试前场景顺序终检已通过**（对照 scenarios 表，canvas 顺序与场景设计一致）
- [ ] **调试前配置终检已通过**（编排区右侧无配置警示 icon）
- [ ] 调试运行完成
- [ ] 聊天区调试日志无错误
- [ ] 编排区所有指令节点**左侧**为绿色通过 icon（无执行失败）
- [ ] 编排区所有指令节点**右侧**无「节点配置不完整」警示
- [ ] 「检查」面板最终无配置异常
