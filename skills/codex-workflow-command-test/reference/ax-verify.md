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

// ── 保存前门控（点击「保存」前必调）──
// canSave === false → 绝对禁止 click 保存按钮；须先补全必填项再重新 assertCanSave
function axRequiredFieldSlice(lines, label) {
  const labelIdx = lines.findIndex(l =>
    (l.includes(`* ${label}`) || l.includes(`*${label}`)) && /text|静态文本|标签/i.test(l)
  );
  if (labelIdx < 0) return [];
  return lines.slice(labelIdx, labelIdx + 15);
}

function axFieldSliceLooksEmpty(sliceText) {
  return (
    /输入.*插入上游节点变量/.test(sliceText) ||
    /placeholder|占位/.test(sliceText) ||
    (/settable|textfield|文本栏/i.test(sliceText) && !/value:\s*\S/.test(sliceText) && !/https?:\/\//.test(sliceText))
  );
}

function assertCanSave(lines, requiredLabels, validators = {}) {
  const hasRequiredErr = lines.some(l => l.includes("该字段是必填字段"));
  const missing = [];
  const details = {};

  for (const label of requiredLabels) {
    const slice = axRequiredFieldSlice(lines, label);
    const sliceText = slice.join("\n");
    if (slice.length === 0) {
      missing.push(label);
      details[label] = { ok: false, reason: "label-not-found" };
      continue;
    }
    const emptyLike = axFieldSliceLooksEmpty(sliceText);
    const customOk = validators[label]
      ? validators[label](sliceText)
      : !emptyLike && (/value:\s*\S/.test(sliceText) || /\/\/\S/.test(sliceText) || /text\s+[^\s].{2,}/.test(sliceText));
    if (!customOk || emptyLike) {
      missing.push(label);
      details[label] = { ok: false, emptyLike, slicePreview: sliceText.slice(0, 120) };
    } else {
      details[label] = { ok: true };
    }
  }

  const canSave = !hasRequiredErr && missing.length === 0;
  return { canSave, missing, hasRequiredErr, details };
}

// 打开网页(web) 专用：网址须在弹框 slice 内且含 ://
function assertCanSaveOpenUrl(lines) {
  return assertCanSave(lines, ["网址"], {
    网址: (t) => /https?:\/\//.test(t) && !/https\/\//.test(t) && !/输入.*插入上游节点变量/.test(t),
  });
}
```

## 指令 Tab + 搜索框：操作前/后核验（必读）

> 与 `insert-command.md` §指令 Tab + 搜索框、`sky-runtime.md` 配套。

### 四类高危根因（实测）

| # | 根因 | 典型失败表现 | 修复策略 |
|---|------|-------------|---------|
| ① | 仅用 `Placeholder: 请输入` 定位搜索框 | `findIdx` 返回 -1；`set_value` 打到错误元素 | `findSearchIdx` 双形态匹配（见下） |
| ② | 点「指令」Tab 后未 `refresh` | Tab 已切换但 AX 仍是旧树，搜索框不存在 | 点 Tab 后 **`ax.get({ refresh: true })`**，确认含 `请输入` |
| ③ | canvas Enter 后 Chat 抢焦点 | 右侧无搜索框；误向 Chat 输入 | `waitSearchIdx()` 轮询 + 必要时 **重点** 面板内「指令」Tab |
| ④ | 硬编码 idx / 点错 Tab | 点到右侧边栏「指令」图标而非面板内 Tab | `findCmdTab` 匹配独立行 `N 文本 指令`；**禁止**跨 exec 复用 idx |

### 共享 helper（每个 `/exec` 块开头复制）

**完整 Helper 包**（含 `insertAfterAnchor`、`configLLMScoped`、`saveDialog`）见 **`sky-runtime.md`**。以下为最小搜索框子集：

```js
{
  const app = "com.google.Chrome";
  const mustIdx = (n, label) => {
    if (!Number.isInteger(n) || n < 0) throw new Error(`${label} invalid: ${n}`);
    return n;
  };
  const findCmdTab = (text) => mustIdx(
    ax.findAllIdx(text, "文本 指令").find(m =>
      /^\s*\d+\s+文本\s+指令\s*$/.test(m.line.replace(/\t/g, " ").trim())
    )?.idx,
    "cmdTab"
  );
  const findSearchIdx = (text) => {
    let idx = ax.findIdx(text, "Placeholder: 请输入");
    if (idx >= 0) return idx;
    const hit = ax.findAllIdx(text, "文本栏").find(m =>
      /请输入/.test(m.line) && !/地址|编辑器|环境/.test(m.line)
    );
    return hit?.idx ?? -1;
  };
  const waitSearchIdx = async () => {
    for (let i = 0; i < 6; i++) {
      const s = await ax.get(app, { refresh: i === 0 });
      const idx = findSearchIdx(s.text);
      if (idx >= 0) return idx;
      await sky.click({ app, element_index: findCmdTab(s.text) });
      await new Promise(r => setTimeout(r, 350));
    }
    throw new Error("searchIdx timeout after 指令 Tab");
  };
}
```

### 轮询 vs 盲 sleep

| 场景 | ❌ 禁止 | ✅ 必须 |
|------|--------|--------|
| Enter 后等搜索框 | 固定 `sleep(400)` 后直接 `set_value` | `waitSearchIdx()`：350ms × 最多 6 次，每轮 **全量 AX** 查 `请输入` |
| 点「指令」Tab 后 | 沿用 Enter 前的 AX Tree | 点 Tab → 350ms → **`refresh: true`** → 验证搜索框 idx |
| set_value 后等结果 | 只 sleep 不查树 | sleep 500ms → `ax.get` → 无 `(web)` 则 **`refresh: true`** 再查 |

### 逐步核验清单（搜索+双击前）

```
□ canvas Enter 后：AX 确认空行/锚点仍在（300–400ms 后可 refresh）
□ click 面板内「指令」Tab（findCmdTab，非边栏图标）
□ ax.get({ refresh: true }) → findSearchIdx ≥ 0（否则 waitSearchIdx）
□ set_value(searchIdx, searchName) → AX 含「网页自动化」+ `xxx (web)`
□ 双击 text … (web) → AX 含配置弹框信号或 canvas 新节点
□ 插入后顺序核对（§插入后顺序校验）
```

### sky 验证模板：Enter 后搜索框是否就绪

```js
{
  const app = "com.google.Chrome";
  // … 复制上方 findCmdTab / findSearchIdx / waitSearchIdx …
  const searchIdx = await waitSearchIdx();
  const s = await ax.get(app);
  nodeRepl.write(JSON.stringify({
    step: "verify-search-ready",
    searchIdx,
    searchLine: s.text.split("\n")[searchIdx] ?? null,
    ok: /请输入/.test(s.text.split("\n")[searchIdx] ?? ""),
  }));
}
```

> ⚠️ **按钮标签匹配**：调试弹框内按钮用 `axHasLabel(l, "运行")` / `axButtonIdx(lines, "运行")`，**禁止**仅用 `l.includes("运行")`——弹框内 Ant Design 按钮 AX 标签为「运 行」「重 置」，无空格写法会漏匹配。

## AX → OCR → 坐标扫描三级定位

当目标元素视觉可见但 AX Tree 找不到时，必须按以下顺序降级，禁止直接放弃或只点单个硬编码坐标：

1. **AX Tree 找元素**
   - 每次操作前重新 `sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })`。
   - 在完整 `s.text` 上用结构性信号、`axHasLabel`、`axButtonIdx`、关键词全文搜索定位。
   - 命中后使用 `element_index`，不要复用旧 idx。

2. **截图 OCR 定位**
   - AX 未命中但截图可见时，读取 `s.screenshot.url`。
   - 用 macOS Vision OCR / 视觉识别目标文案、按钮文字或图标 bounding box。
   - 点击识别框中心坐标，并立即重新抓 AX Tree 验证。

3. **固定坐标扫描**
   - OCR 也失败时，才使用已校准的 `coordCandidates`。
   - 候选坐标必须是数组，按最可能热区到次要热区依次尝试。
   - 每次 attempt 后都验证业务结果，成功即停止。

所有执行结果必须输出定位字段：

```json
{
  "attempts": ["ax:...", "ocr:...@x,y", "coord-scan:x,y"],
  "successAttempt": "ocr:确定@512,360",
  "successX": 512,
  "successY": 360,
  "strategy": "ax | ocr | coord-scan"
}
```

若已处于目标状态，可以返回 `strategy: "already-done"`，但仍要设置 `successAttempt` 说明短路原因。

## 常见动作 → 成功信号

| 上一步动作 | AX Tree 成功信号 | 失败 / 需重试信号 |
|-----------|-----------------|------------------|
| 导航 URL | 地址栏含目标 URL；页面出现预期标题/导航 | 仍停留在旧 URL；404/空白 |
| 点「工作流」 | URL 含 `/rpa/workflow`；列表或「新建工作流」可见 | 仍在 chat 页 |
| 光标定位到 canvas（**首条指令**） | **选中开始节点 → Enter**；开始节点**正下方**出现新空行 | 无新行 → 重新单击开始节点再 Enter |
| **选中锚点指令行**（向后追加，⚠️ 高危步骤） | 该行高亮/获焦 | 点空了或点到其他节点 → 重新按 §插入位置约束 定位 |
| **按 Enter 空出新行**（**紧接选中锚点/开始节点**） | 锚点行**正下方**出现新空行；canvas 节点行数增加 | 无新行 → 重新单击再 Enter，**禁止**跳过直接搜索 |
| **点面板内「指令」Tab + refresh** | AX 含 `文本栏 … 请输入`（`findSearchIdx ≥ 0`） | 无 `请输入`（Enter 后 Chat 抢焦点）→ `waitSearchIdx()` 重点 Tab；**禁止**盲 sleep 后 set_value |
| 搜索框 set_value 指令中文名 | 右侧「指令」面板出现 `xxx (web)` 结果行；含「网页自动化」分组 | 无结果；仍在旧搜索词 → refresh 再查；仍失败 → 重新 `waitSearchIdx()` + set_value |
| 双击「网页自动化」分组下 `xxx (web)` | canvas 出现新节点编号；同时弹出配置弹框 | canvas 未变；无弹框 |
| **插入后顺序校验**（最后一道保险，不可跳过） | 新节点在**锚点指令之后**、结束节点之前；依赖顺序满足 | 新指令排在锚点指令**前面** → **立即停止配表单**，走 `insert-command.md` §右键菜单调整指令顺序 剪切→粘贴 修正 |
| 双击开配置弹框 | **结构性多信号**：有「捕获」按钮 `/\d+ 按钮\s+捕\s*获/` **OR** 有「元素选择器」字段 **OR** 有「保存」按钮 | 无弹框；三个信号均无 |
| 粘贴 XPath（Cmd+V） | 组合框 Value 含 `//`；「该字段是必填字段」可能仍显示（需下一步 Enter） | 输入框仍空 |
| 按 Enter（**方式 C 核心**） | 组合框旁出现 `\d+ text //...` 独立行 + 「该字段是必填字段」消失 | 红字仍在 → 重新聚焦 Cmd+V 再 Enter；重试仍失败 → 转方式 B（捕获） |
| 填「待填充文本」 | 输入框含目标文本 | 仍空、仍红框 |
| 填「网址」/ URL 字段 | **弹框**「* 网址」label 下方 slice 含 `https://`（非 `https//`） | 冒号丢失；仍空、仍红框；**URL 仅出现在 Chrome 地址栏** |
| **保存前总检** | 所有 label 前带 `*` 的字段已填；无红框；无「该字段是必填字段」 | 任一必填为空；输入框红框 → **禁止点保存** |
| 点「保存」 | 弹框关闭；canvas 节点保留 | 弹框仍在；「该字段是必填字段」 |
| 点顶部「调试」 | 右侧弹出调试面板；「选择我的浏览器环境」= **随机设备** | 弹框未出现 |
| 弹框点「运行」（**不改弹框表单**） | 执行中状态；聊天区出现日志 | 按钮灰；无日志；**误改设备/点重置**；**`includes("运行")` 漏匹配「运 行」**；**未做场景顺序终检即调试** |

## 插入后顺序校验（加指令后必做）

> 🚫 **插入前铁律**（详见 `insert-command.md` §Enter 空行规则）：**首条**选中开始节点 → Enter；**向后追加**选中锚点指令 → Enter；**向前插入**选中目标上一条 → Enter。**绝不能**无锚点搜索插入或从结束节点上方起建。

每次搜索+双击插入指令到 canvas 后，**必须**全量抓 AX Tree 校验编排区顺序，再打开配置弹框填参数。

> **canvas 节点行 AX 类型**：可能是 `text` 或 `文本`（如 `81 文本 刷新网页`）。匹配时用 `/^\s*\d+\s+(text|文本)/`（见 `sky-runtime.md` §`findCanvasNode`）。

> **锚点关键词**：向后追加时 `findCanvasNode` 应使用 canvas **摘要唯一子串**（如 `bilibili.com`、`元素中输入 bilibili`），禁止泛搜 `点击`/`输入`。

### 校验规则

1. **追加位置**：新节点必须排在**锚点指令（插入前最后一条已保存指令）之后**、「结束节点」之前
2. **依赖顺序**（Web 场景）：
   - 插入「输入文本」前，canvas 中已有 **页面类指令**（`打开网页` 或 `导航到URL`）且在其**上方**
   - 插入「点击」前，canvas 中已有 **页面类指令**
   - 插入「验证元素存在/可见」等断言类指令前，canvas 中已有 **页面类指令**
3. **非法示例**：`开始 → 验证元素存在 → 打开网页 → 结束`（新指令误插到锚点指令前面）→ 选中「验证元素存在」→ 右击 **剪切** → 选中「打开网页」→ **Enter** 创建空行 → **粘贴**（`insert-command.md` §右键菜单调整指令顺序，**不必先删除**）
4. **发现顺序错误 → 立即停止**：**禁止**在错误顺序下继续为新节点配置表单参数，先修正顺序再配置

### sky 自动化

```js
{
  const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const canvasStart = lines.findIndex(l => l.includes("编辑器容器"));
  const canvasText = lines.slice(canvasStart, canvasStart + 150).join("\n");

  const idxOf = (k) => canvasText.indexOf(k);
  const pageOpenKeys = ["打开网页", "导航到URL"];
  const hasPageOpen = pageOpenKeys.some(k => canvasText.includes(k));
  const pageOpenIdx = Math.min(...pageOpenKeys.map(k => canvasText.includes(k) ? canvasText.indexOf(k) : Infinity));
  const hasFillText = canvasText.includes("输入文本");
  const hasClick = canvasText.includes("点击");
  const hasVerifyExist = canvasText.includes("验证元素存在");
  const hasVerifyVisible = canvasText.includes("验证元素可见");

  const pageOpenFirst = !hasPageOpen || [hasFillText, hasClick, hasVerifyExist, hasVerifyVisible]
    .every((present, i) => {
      const k = ["输入文本", "点击", "验证元素存在", "验证元素可见"][i];
      return !present || (pageOpenIdx !== Infinity && pageOpenIdx < canvasText.indexOf(k));
    });

  const orderOk =
    pageOpenFirst &&
    (!hasFillText || (hasPageOpen && pageOpenIdx < canvasText.indexOf("输入文本"))) &&
    (!hasClick || hasPageOpen);

  nodeRepl.write(JSON.stringify({
    step: "order-verify",
    orderOk,
    hasPageOpen, pageOpenKeys: pageOpenKeys.filter(k => canvasText.includes(k)),
    hasFillText, hasClick, hasVerifyExist, hasVerifyVisible,
    action: orderOk ? "continue-config" : "STOP-cut-node-and-paste-at-correct-position-via-2.3a"
  }));
  // orderOk === false → 立即停止配表单，走 insert-command.md §右键菜单调整指令顺序 剪切→粘贴 修正后再校验
}
```

## 调试前场景顺序终检（点「调试」前必做）

单条指令插入后的顺序校验（§插入后顺序校验）只能保证**当时**追加正确。全部配置保存完毕、**点击「调试」之前**，还必须做一次**全场景终检**：对照 `reference/scenarios/<场景>.md`「指令节点」表，确认编排区 canvas 中业务指令的**数量、类型、先后顺序**与场景设计完全一致。

### 终检清单

```
□ 已 Read 当前场景文件，明确应有 N 条业务指令及顺序
□ canvas 中「开始节点」在最上、「结束节点」在最下
□ 中间业务指令条数 = 场景表行数
□ 每条指令类型与 **instructionPlan** / 场景表对应序号一致
□ 通用依赖仍成立：**页面类指令**（打开网页 / 导航到URL）在「输入文本」之前（若有）
□ 终检通过 → 才点「调试」；未通过 → 修正顺序后重新终检
```

### 与「插入后顺序校验」的区别

| 时机 | 目的 |
|------|------|
| 插入后顺序校验 | 每加一条指令后立即确认追加位置与依赖顺序 |
| **调试前场景顺序终检** | 全部保存后、调试前，对照场景表做**整链**最终确认 |

sky 自动化示例见 `test-workflow.md` §调试前场景顺序终检。

## 失败时的决策

1. **idx 找不到目标** → 重新全量抓取，换结构性信号/关键词在完整 AX Tree 重搜；仍找不到但截图可见 → 用 OCR 定位中心坐标；OCR 失败 → 坐标扫描候选数组；禁止盲点旧 idx 或单个硬编码坐标
2. **浮层/弹框状态不对** → `Escape` → 全量抓取确认关闭 → 从该步重来
3. **canvas 处于编辑态**（双击失败）→ 点**编排区** Tab 失焦 + `Escape` → 再双击（**禁止**点「调试」失焦）
4. **同一动作连续 2 次验证仍失败** → 停止连点，报告当前 AX 关键行，换策略
5. **插入后顺序校验失败** → 选中错位节点 → 右击 **剪切** → 选中锚点行 → **Enter** 创建空行 → **粘贴**（`insert-command.md` §右键菜单调整指令顺序）→ 再校验；剪切失败时再删后重插
6. **搜索框 set_value 连续 2 次无 `(web)` 结果** → 停止连点；`waitSearchIdx()` 确认搜索框 idx → 再 set_value；仍失败 → 报告 AX 中「指令」Tab 附近关键行（是否误点边栏图标、是否仅有 `Placeholder` 无 `文本栏`）

## 示例：配置「输入文本(web)」逐步验证

以下每一步都是：**动作 → 全量 AX → 判断 → 才进入下一步**。

> 配置弹框 URL 字段时，**禁止** `type_text`，**默认** scoped + 剪贴板 + paste（见 **`url-input.md` §执行顺序铁律**）。set_value 仅 paste 重试 2 次仍失败后的最后手段。

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

### Step B：pbcopy + 粘贴网址 → 验证弹框内含 `https://`（禁止误填地址栏）

> 🚫 弹框打开时**禁止**对 Chrome 地址栏（`/地址/` settable）做 set_value 或粘贴。完整 scoped 定位见 **`url-input.md`**。

```js
{
  // echo -n "https://www.baidu.com" | pbcopy
  const TARGET = "https://www.baidu.com";
  const s0 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const lines0 = s0.text.split("\n");

  const labelIdx = lines0.findIndex(l => /text\s+\*\s+网址/.test(l));
  const inputLine = labelIdx >= 0
    ? lines0.slice(labelIdx, labelIdx + 15).find(l =>
        /settable|textfield|文本栏/i.test(l) &&
        !(/settable, string/.test(l) && /地址/.test(l) && !/网址/.test(l))
      )
    : null;
  const urlIdx = inputLine ? parseInt(inputLine.match(/^\s*(\d+)/)[1]) : null;

  if (urlIdx == null) {
    nodeRepl.write(JSON.stringify({ step: "openurl-B", ok: false, reason: "modal-url-field-not-found" }));
    throw new Error("modal-url-field-not-found");
  }

  await sky.click({ app: "com.google.Chrome", element_index: urlIdx });
  await sky.press_key({ app: "com.google.Chrome", key: "cmd+a" });
  await sky.press_key({ app: "com.google.Chrome", key: "cmd+v" });

  const lines1 = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const modalSlice = labelIdx >= 0 ? lines1.slice(labelIdx, labelIdx + 15).join("\n") : "";
  const urlInModal = modalSlice.includes(TARGET);
  const colonMissing = lines1.some(l => /https\/\//.test(l));
  nodeRepl.write(JSON.stringify({ step: "openurl-B", urlIdx, urlInModal, colonMissing }));
  // urlInModal === false → 可能误填地址栏，按 url-input.md §误填地址栏后的修复 重试
}
```

### Step C：保存前总检（canSave 为 true 才允许点保存）

> 🚫 **硬性门控**：须先 `assertCanSaveOpenUrl(lines)`；`canSave === false` 时**绝对禁止** click「保存」。网址仍空、仍占位符、仍「该字段是必填字段」→ 回到 Step B 补填。

```js
{
  function axHasLabel(line, label) {
    return new RegExp(label.split("").join("\\s*")).test(line);
  }
  function axButtonIdx(lines, label) {
    const line = lines.find(l => axHasLabel(l, label) && l.includes("按钮"));
    return line ? parseInt(line.match(/^\s*(\d+)/)?.[1]) : null;
  }
  function axRequiredFieldSlice(lines, label) {
    const labelIdx = lines.findIndex(l =>
      (l.includes(`* ${label}`) || l.includes(`*${label}`)) && /text|静态文本|标签/i.test(l)
    );
    return labelIdx >= 0 ? lines.slice(labelIdx, labelIdx + 15) : [];
  }
  function assertCanSaveOpenUrl(lines) {
    const sliceText = axRequiredFieldSlice(lines, "网址").join("\n");
    const hasRequiredErr = lines.some(l => l.includes("该字段是必填字段"));
    const hasPlaceholder = /输入.*插入上游节点变量/.test(sliceText);
    const hasUrl = /https?:\/\//.test(sliceText) && !/https\/\//.test(sliceText);
    const canSave = hasUrl && !hasPlaceholder && !hasRequiredErr;
    return { canSave, hasUrl, hasPlaceholder, hasRequiredErr };
  }

  const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const check = assertCanSaveOpenUrl(lines);
  nodeRepl.write(JSON.stringify({ step: "openurl-C", ...check }));

  if (!check.canSave) {
    nodeRepl.write(JSON.stringify({
      step: "save-blocked",
      reason: "网址必填项未填完，禁止点保存",
      action: "回到 Step B 补填弹框「网址」后再 assertCanSaveOpenUrl"
    }));
  } else {
    const saveIdx = axButtonIdx(lines, "保存");
    await sky.click({ app: "com.google.Chrome", element_index: saveIdx });
    const lines2 = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
    const saved = !lines2.some(l => axHasLabel(l, "保存") && l.includes("按钮"));
    nodeRepl.write(JSON.stringify({ step: "openurl-C-verify", saved }));
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
