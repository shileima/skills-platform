# 平台操作

> 进入本模块前，**必须已完成** `reference/prerequisites.md`，且 `exec.sh` 验证输出 `ok`。

> ⚠️ **步骤衔接**：每一次 click / 输入 / 粘贴后，**必须**全量抓取 AX Tree 验证上一步是否成功，再决定下一步。详见 **`reference/ax-verify.md`**。

## 2.0 动作-验证循环（必读）

```
单次 UI 动作 → get_app_state({ disableDiff: true }) → 分析成功信号 → 下一步
```

- **禁止**在一个代码块里连点多个元素而不中间验证
- element_index **每次**从最新 AX Tree 重新查找，禁止复用旧 idx
- 验证失败：`Escape` 重置 → 重新抓取 → 从失败步重来

常见成功信号表见 `ax-verify.md` §常见动作 → 成功信号。

## 2.1 进入首页 → 点击「工作流」→ 新建空工作流

> 测试前提：在**空工作流**编排区按序加指令。完整流程见 `reference/test-workflow.md`。

> ⚠️ **禁止**地址栏直达 `https://rpa.sankuai.com/rpa/workflow`。必须：**首页** → 左侧点「**工作流**」→ 再新建。

### 2.1a 打开 RPA 首页

```js
{
  const s0 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const addrLine = s0.text.split("\n").find(l => /settable, string/.test(l) && /地址/.test(l));
  const addrIdx = parseInt((addrLine || "10 ").match(/^\s*(\d+)/)[1]);
  await sky.set_value({ app: "com.google.Chrome", element_index: addrIdx, value: "https://rpa.sankuai.com/rpa/chat" });
  await sky.press_key({ app: "com.google.Chrome", key: "Return" });
  await new Promise(r => setTimeout(r, 2000));

  const s1 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const navigated = s1.text.includes("rpa.sankuai.com");
  nodeRepl.write(JSON.stringify({ step: "1a", navigated }));
  // navigated === false → 重填地址栏
}
```

### 2.1b 点击左侧「工作流」

```js
{
  const s0 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const line = s0.text.split("\n").find(l => l.includes("工作流") && /链接|按钮|link|button/i.test(l));
  const wfIdx = parseInt((line || "").match(/^\s*(\d+)/)?.[1]);
  await sky.click({ app: "com.google.Chrome", element_index: wfIdx });
  await new Promise(r => setTimeout(r, 1500));

  const s1 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const onWorkflow = s1.text.includes("/rpa/workflow") || s1.text.includes("新建工作流");
  nodeRepl.write(JSON.stringify({ step: "1b", wfIdx, onWorkflow }));
}
```

### 2.1c 新建编排模式空工作流

1. 点击「**+ 新建工作流**」→ 选择「**编排模式**」→ 命名（如 `指令测试-YYYYMMDD`）并保存
2. 确认编排区**仅有开始节点 + 结束节点**，中间无指令

### 备选：bots.sankuai.com 入口

```js
echo -n "https://bots.sankuai.com" | pbcopy
// set_value 地址栏 + Return
```

进入空间 →「新建工作流」→「编排模式」→ 命名保存。

## 2.2 打开/重新打开节点配置面板（双击）

> ⚠️ **核心坑：canvas 是 `contenteditable` 富文本编辑器。** 只要 canvas 处于文本编辑模式，任何 `sky.click` 都被浏览器消费为光标定位，React 的 `onDoubleClick` 永远不会触发。

**正确双击流程（三步缺一不可）：**

**第一步：先使 canvas 失焦**
```js
await sky.click({ app: "com.google.Chrome", element_index: <调试按钮idx> });
await new Promise(r => setTimeout(r, 300));
await sky.press_key({ app: "com.google.Chrome", key: "Escape" });
await new Promise(r => setTimeout(r, 500));
```

**第二步：精确找到目标节点的「编号文本」idx**

> ⚠️ **必须在 canvas 范围内查找**，canvas 外（如设备列表分页）也有 "1"/"2"/"3" 数字，会错误匹配。

```js
const s = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
const lines = s.text.split("\n");
const canvasLine = lines.findIndex(l => l.includes("编辑器容器"));
const canvasArea = lines.slice(canvasLine, canvasLine + 100);
const target = canvasArea.find(l => /^\s+\d+\s+文本\s+3\s*$/.test(l));
const targetIdx = parseInt((target || "").match(/^\s*(\d+)/)?.[1]);
```

**第三步：用 `click_count: 2` 双击 → 验证弹框**

```js
await sky.click({ app: "com.google.Chrome", element_index: targetIdx, click_count: 2 });
await new Promise(r => setTimeout(r, 1500));
const s2 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
const opened = s2.text.split("\n").some(l => l.includes("捕获") && l.includes("按钮"));
nodeRepl.write(JSON.stringify({ step: "2.2-dblclick", opened }));
// opened === false → Escape 失焦后重试 §2.2 第一步
```

## 2.3 在编排区按顺序添加指令

> ⚠️ **测试顺序不可打乱**。按场景定义顺序逐条添加；**每加一条立即配置保存**，不要批量添加后再配。

> ⚠️ **唯一添加方式**：右侧「指令」Tab 的**搜索框输入中文指令名 → 双击匹配的搜索结果**（网页自动化分组下的 `xxx (web)` 项）。禁止其他添加方式（含 `/` 唤起浮层、拖拽、复制粘贴现有节点作为新指令等）。

> **完整插入流程已抽取为独立模块 `reference/insert-command.md`**，包含：插入位置约束铁律、光标定位规则（首条/非首条分支）、右键菜单调序（剪切→粘贴）、常用指令搜索名表、定位插入点步骤、sky 自动化模板（1a/1b + 搜索 + 双击）、插入后强制核对。**需要添加指令时，Read `insert-command.md` 执行，不要自行内联插入流程。**

**快速摘要**（核心规则，详见 `insert-command.md`）：

- **首条**：选中**开始节点 → Enter** → 在开始节点下方空行插入（**禁止**从结束节点上方或拖拽提示行起建）
- **向后追加**：选中**锚点指令** → **Enter** → 在其正下方空行 → 搜索+双击
- **向前插入**：选中**目标指令的上一条** → **Enter** → 空行 → 搜索+双击或粘贴
- 插入后**必须**核对顺序：`insert-command.md` §插入后强制核对
- 顺序错误时首选：选中错位节点 → 右击**剪切** → 选中锚点行 → **Enter** 创建空行 → **粘贴**（`insert-command.md` §右键菜单调整指令顺序）

配置指令参数时，**读取对应 `reference/commands/<指令>.md`**。

> ⚠️ 配置「打开网页」的「网址」时，**禁止** `type_text`（会丢冒号）。**默认** scoped 定位 + 剪贴板 + 弹框内 paste，见 **`url-input.md` §执行顺序铁律**（**禁止** pbcopy 失败就改 set_value）。
>
> 🚫 **弹框打开时禁止操作 Chrome 地址栏**：「网址」是弹框内「输入参数」字段，不是窗口顶部地址栏。误填地址栏时弹框仍空/仍红框——须 scoped 重填弹框字段，见 `url-input.md` §弹框网址 vs Chrome 地址栏。
>
> 🚫🚫🚫 **元素选择器写入铁律**：**首选** `pbcopy` + `Cmd+V` 粘贴 XPath → **紧接 Enter** 落库（`element-selector.md` §方式 C）；**退而求其次**点击弹框「捕获」按钮（§方式 B）。**禁止**其他写入方式。

## 2.4 指令弹框保存前校验（必做）

双击节点打开指令配置弹框（如「打开网页(web)」「延迟」）后，在「**常规**」Tab 的「**输入参数**」区填写参数。

> 🚫🚫🚫 **保存前校验铁律（反复出错的高危步骤，不可跳过、不可例外）**：
>
> 1. 点击右下角「**保存**」**之前**，必须先完成 §保存前检查清单 全部步骤，并逐项确认所有必填项已填写且校验通过。
> 2. **任一**必填项为空、输入框仍带**红色边框**、或 AX Tree 中仍出现「该字段是必填字段」→ **绝对禁止点保存**；须先补全/修正 → 重新自检 → 全部通过后再保存。
> 3. **禁止**凭感觉、猜默认值、或「先保存试试」绕过校验。**跳过校验直接点保存 = 流程违规**——保存会失败或落盘不完整，后续调试必然报错，且须重新打开弹框从头配置。

### 识别必填项（看 label 前的红色 `*`）

弹框「输入参数」区，**字段 label 文字前面**若出现**红色星号 `*`**，表示该字段为**必填**；无 `*` 的字段（如下拉、开关）通常有默认值，可不填。

| 视觉信号 | 含义 | 能否保存 |
|---------|------|---------|
| label 前有红色 `*`（如 `* 延迟时间`、`* 网址`） | 必填字段 | 须填完才可保存 |
| label 前**无** `*`（如 `时间单位`、`是否发送消息`） | 非必填，常有默认值 | 不影响保存 |
| 必填项输入框**为空** | 未满足校验 | **禁止保存** |
| 必填项输入框**红色边框** | 未填或校验未通过 | **禁止保存** |
| 必填项输入框正常边框 + 已有有效内容 | 已通过 | 可保存 |

**示例（延迟指令）**：

```
* 延迟时间     ← 必填（label 前有红色 *），为空时禁止保存
  时间单位     ← 非必填，默认「秒」
  是否发送消息 ← 非必填，开关默认开
```

> 如图：「延迟时间」label 前有红色 `*`；该输入框为空时呈红色边框。**必须先填入有效值（如 `1`），红框消失后，再点「保存」。**

### 保存前检查清单（逐条执行，不可跳过）

```
0. Read reference/commands/<指令>.md → 记下「必填输入参数」列表（与弹框 * 字段对照）
1. 逐项填写「输入参数」区所有 label 前带红色 * 的字段
2. 目视扫描弹框：任一必填输入框仍为空或带红色边框 → 停止，补全后再继续
3. 元素选择器类字段：**pbcopy → click 组合框 → Cmd+V 粘贴 → Enter**（见 `element-selector.md` §方式 C）；连续失败 3 次再转 §方式 B 捕获
4. 全量抓 AX Tree：确认无「该字段是必填字段」类报错文案
5. 以上全部通过 → 再点弹框右下角「保存」
```

> ⚠️ 违反 §保存前校验铁律：必填项仍为空、仍标红、或 AX 中仍有必填报错时点击「保存」——等同流程违规，保存会失败或落盘不完整，后续调试必然报错。

### 常见必填项（测试场景）

| 指令 | 必填字段（弹框 label 前带 `*`） |
|------|-------------------------------|
| 打开网页 | `网址` |
| 输入文本 | `元素选择器`、`待填充文本` |
| 点击元素（推荐） | `元素选择器` |
| 延迟 | `延迟时间` |

完整必填列表见 `reference/commands/index.md` 第三列，或单条 `reference/commands/<slug>.md`。

### sky 自动化：保存前自检 → 保存 → 验证关闭

> 自动化时同样遵循 §保存前校验铁律：**canSave === false 时绝对不得 click 保存按钮**。
>
> 通用 helper 见 `ax-verify.md` §分析辅助函数 → `assertCanSave` / `assertCanSaveOpenUrl`。

```js
{
  // ── 保存前门控 helper（与 ax-verify.md 保持一致）──
  function axRequiredFieldSlice(lines, label) {
    const labelIdx = lines.findIndex(l =>
      (l.includes(`* ${label}`) || l.includes(`*${label}`)) && /text|静态文本|标签/i.test(l)
    );
    return labelIdx >= 0 ? lines.slice(labelIdx, labelIdx + 15) : [];
  }
  function axFieldSliceLooksEmpty(sliceText) {
    return (
      /输入.*插入上游节点变量/.test(sliceText) ||
      (/settable|textfield|文本栏/i.test(sliceText) && !/value:\s*\S/.test(sliceText) && !/https?:\/\//.test(sliceText))
    );
  }
  function assertCanSave(lines, requiredLabels, validators = {}) {
    const hasRequiredErr = lines.some(l => l.includes("该字段是必填字段"));
    const missing = [];
    for (const label of requiredLabels) {
      const sliceText = axRequiredFieldSlice(lines, label).join("\n");
      if (sliceText.length === 0) { missing.push(label); continue; }
      const emptyLike = axFieldSliceLooksEmpty(sliceText);
      const ok = validators[label]
        ? validators[label](sliceText)
        : !emptyLike && (/value:\s*\S/.test(sliceText) || /\/\/\S/.test(sliceText));
      if (!ok || emptyLike) missing.push(label);
    }
    return { canSave: !hasRequiredErr && missing.length === 0, missing, hasRequiredError: hasRequiredErr };
  }

  // 按当前指令替换 requiredLabels / validators
  const requiredLabels = ["网址"]; // 打开网页；延迟用 ["延迟时间"]；输入文本用 ["元素选择器","待填充文本"]
  const validators = {
    网址: (t) => /https?:\/\//.test(t) && !/https\/\//.test(t) && !/输入.*插入上游节点变量/.test(t),
  };

  const s0 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const panel = s0.text.split("\n");
  const hasPanel = panel.some(l => /打开网页|输入文本|点击元素|延迟/.test(l));
  const { canSave, missing, hasRequiredError } = assertCanSave(panel, requiredLabels, validators);

  nodeRepl.write(JSON.stringify({ step: "save-check", hasPanel, canSave, missing, hasRequiredError }));

  if (!canSave) {
    nodeRepl.write(JSON.stringify({
      step: "save-blocked",
      reason: "必填项未填完，禁止点保存",
      missing,
      action: "补全 missing 所列字段 → 全量 AX → 重新 assertCanSave → canSave 为 true 后再保存"
    }));
  } else {
    function axHasLabel(line, label) {
      return new RegExp(label.split("").join("\\s*")).test(line);
    }
    function axButtonIdx(lines, label) {
      const line = lines.find(l => axHasLabel(l, label) && l.includes("按钮"));
      return line ? parseInt(line.match(/^\s*(\d+)/)?.[1]) : null;
    }
    const saveIdx = axButtonIdx(panel, "保存");
    await sky.click({ app: "com.google.Chrome", element_index: saveIdx });
    const s1 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
    const saved = !s1.text.split("\n").some(l => axHasLabel(l, "保存") && l.includes("按钮") && hasPanel);
    nodeRepl.write(JSON.stringify({ step: "save-verify", saved }));
  }
}
```

**打开网页(web) 典型失败**（如图：「网址」仍空、仍占位符「输入'/'插入上游节点变量」、节点右侧出现配置警示 ⓘ）：

```
assertCanSave → canSave: false, missing: ["网址"]
→ 禁止 click「保存」
→ 按 url-input.md Step 1 补填弹框「网址」
→ 重新 assertCanSave → canSave: true 后再保存
```

## 2.5 调试前场景顺序终检（必做）

全部指令配置保存完毕后、**点击「调试」之前**，必须对照 `reference/scenarios/<场景>.md`「指令节点」表，确认编排区 canvas 指令的**数量、类型、顺序**与场景设计一致。

```
1. Read scenarios/<场景>.md → 记录应有指令链（如：打开网页 → 输入文本 → 点击）
2. 目视 canvas 或抓 AX Tree，列出实际顺序（开始 → … → 结束）
3. 逐条对比场景表；全部匹配 → 方可调试
4. 不匹配 → **`insert-command.md` §右键菜单调整指令顺序** 剪切→粘贴（首选）；剪切失败再删后重插 → 再终检
```

> ⚠️ **禁止**跳过终检直接调试。顺序错误时调试必然失败，应先修正再运行。

终检 sky 脚本与示例见 `test-workflow.md` §调试前场景顺序终检、`ax-verify.md` §调试前场景顺序终检。

## 2.6 调试运行（无需配置弹框）

**前置**：§2.5 场景顺序终检已通过，全部指令已保存。

```
1. 点页面顶部「调试」按钮 → 右侧弹出调试面板
2. 直接点橙色「运行」→ 开始执行
3. 等待执行结束 → 查聊天区日志 + 编排区节点 icon
```

> ⚠️ **弹框无需配置**：「选择我的浏览器环境」默认已是「**随机设备**」。**禁止** Agent 在弹框里改设备、改环境或点「重置」，除非用户明确要求指定设备。

| 错误做法 ❌ | 正确做法 ✅ |
|-----------|-----------|
| 打开调试弹框后改浏览器环境、点重置 | 打开弹框 → **直接点运行** |
| 等待用户选设备 | 默认随机设备，无需等待 |
| 配置「云手机环境」 | Web 场景忽略，不填 |

sky 自动化与 `debug.md` §调试运行 相同：点顶部「调试」→ 验证弹框出现 → 点「运行」→ 验证执行中状态。

> ⚠️ **AX 按钮匹配**：调试弹框内 Ant Design 按钮标签带半角空格（「运 行」「重 置」），须用 `axHasLabel` / `axButtonIdx`（见 `ax-verify.md` §分析辅助函数），**禁止**仅用 `includes("运行")`。
