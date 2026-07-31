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

> ⚠️ **定位插入点**：若目标位置是「某行后面」，而**该行后面没有空行**，须 **选中该行 → 按 `Enter` 空出一行 → 再粘贴或输入 `/`**。不要直接在无空行的行末粘贴或搜指令。

### 插入位置约束（追加式 · 禁止插队）

**核心规则**：新指令必须**追加在已有指令链末尾**（最后一条指令之后、结束节点之前），**禁止**在开始节点后、已有指令之前、或两条已有指令之间插入。

| 错误做法 ❌ | 正确做法 ✅ |
|-----------|-----------|
| 已有「打开网页」后，在开始节点下方空行插入「输入文本」 | 在「打开网页」**下方**、结束节点**上方**的空行插入「输入文本」 |
| 批量连续插入多条后再统一配置 | 每插入一条 → 立即配置保存 → 再插下一条 |
| 光标停在第 2 步位置就插入第 3 步 | 选中**最后一条已保存指令** → Enter 空出一行 → 再粘贴或 `/` |
| 某行后面没有空行就直接粘贴或 `/` | 选中该行 → **Enter** 空出一行 → 再粘贴或 `/` |

**场景顺序依赖**（Web 自动化通用，不可违反）：

```
打开网页 → 输入文本 → 点击元素
```

| 待插入指令 | canvas 中必须已存在的前置指令 |
|-----------|------------------------------|
| 打开网页 | （无，通常是第一条业务指令） |
| 输入文本 | **打开网页**（必须先有页面才能填元素） |
| 点击元素 | **打开网页**；搜索类场景建议已有**输入文本** |

> 如图常见错误：「输入文本」排在「打开网页」之前 → **顺序非法**，调试必然失败。**首选**用 **§2.3a 剪切→粘贴** 移到正确位置（保留已填配置）；剪切失败或节点异常时再删后重插。

### 2.3a 右键菜单调整指令顺序（顺序错误时首选）

若编排区指令顺序乱了（如「输入文本」排在「打开网页」之前），**不要先删除**——已配置的 XPath、文本会随节点保留，用**剪切→粘贴**即可：

```
1. 单击选中需要移动的指令行（如「输入文本」，该行高亮）
2. 在该行上右击 → 选择「剪切」（Ctrl+X / Cmd+X）
3. 单击目标锚点行（如「打开网页」）→ 按 Enter 在其下方创建空行
4. 光标位于该空行 → 粘贴（Ctrl+V / Cmd+V）或右击「粘贴」
5. 目视确认顺序符合场景（如 开始 → 打开网页 → 输入文本 → 点击 → 结束）
6. 若剪切/粘贴后节点配置异常，再回退为「删除 + 末尾重插」
```

**示例**（「输入文本」误插在「打开网页」之前）：

| 步骤 | 操作 |
|------|------|
| 1 | 选中「输入文本」→ 右击 → **剪切** |
| 2 | 选中「打开网页」→ 按 **Enter** 在其下方创建空行 |
| 3 | 在该空行 **粘贴** → 顺序变为：开始 → 打开网页 → 输入文本 → … |

| 菜单项 | 快捷键 | 用途 |
|--------|--------|------|
| **剪切** | Ctrl+X / Cmd+X | **调序首选**：移走节点，配置保留，待粘贴到目标位置 |
| 复制 | Ctrl+C | 复制节点（一般不用于调序） |
| **粘贴** | Ctrl+V / Cmd+V | 将剪切的节点插入到当前光标/空行处 |
| 删除节点 | Delete | 仅当剪切/粘贴失败或节点损坏时使用 |

> ⚠️ 移动后仍需校验顺序依赖（§2.3 场景顺序依赖表）。**禁止**在错误顺序下继续配置或调试。

### 定位正确插入点（粘贴 / `/` 插入前必做）

**通用规则**：插入位置 = **某行后面**。若该行后面**已有空行**，光标移入空行即可；若**没有空行**，须 **选中该行 → Enter 空出一行 → 再粘贴或输入 `/`**。

```
1. 全量抓 AX Tree，在 canvas 区域读取当前节点顺序（开始 → … → 结束）
2. 确定锚点行：要插入到哪一行后面（通常为最后一条已保存指令；调序时为正确位置的上一条）
3. 检查锚点行下方是否已有空行：
   - 有 → 光标移入该空行
   - 无 → 选中锚点行 → 按 Enter → 在其下方空出一行
4. 光标位于空行后：
   - 粘贴剪切/复制的指令（Ctrl+V / Cmd+V），或
   - 输入 `/` 弹出浮层搜索新指令
5. 禁止在「开始节点」与第一条指令之间的空行插入第 2、3 条指令（该位置仅用于第一条业务指令）
```

**sky 自动化：读取 canvas 节点顺序 → 确认追加插入点**

```js
{
  const s = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const lines = s.text.split("\n");
  const canvasStart = lines.findIndex(l => l.includes("编辑器容器"));
  const canvasArea = lines.slice(canvasStart, canvasStart + 120);

  // 提取 canvas 内带编号的指令行（编号 + 文本 + 指令摘要）
  const nodeLines = canvasArea.filter(l =>
    /^\s+\d+\s+文本\s+\d+\s*$/.test(l) ||
    (l.includes("文本") && /打开网页|输入文本|点击|开始节点|结束节点/.test(l))
  );

  // 从相邻行拼出节点摘要（平台 AX 结构：编号行下方常有指令描述）
  const summaries = [];
  for (let i = 0; i < canvasArea.length; i++) {
    const m = canvasArea[i].match(/^\s+(\d+)\s+文本\s+\d+\s*$/);
    if (!m) continue;
    const desc = (canvasArea[i + 1] || "") + (canvasArea[i + 2] || "");
    summaries.push({ num: parseInt(m[1]), desc });
  }

  const orderOk = (() => {
    const texts = summaries.map(s => s.desc).join("|");
    if (texts.includes("输入文本") && !texts.includes("打开网页")) return false;
    if (texts.includes("输入文本") && texts.indexOf("输入文本") < texts.indexOf("打开网页")) return false;
    return true;
  })();

  nodeRepl.write(JSON.stringify({
    step: "insert-point-check",
    nodes: summaries,
    orderOk,
    hint: orderOk
      ? "选中最后一条指令→Enter 空出一行（若无空行）→ 粘贴或 /"
      : "顺序错误：选中错位节点→剪切→选中锚点行→Enter 空出一行→粘贴（§2.3a）"
  }));
}
```

### 插入指令规范（五步）

输入 `/` 后会弹出指令选择浮层（含「指令 / 工具 / 工作流」Tab 和搜索框 **「请输入」**）。**不要**在 canvas 里继续打字搜指令，必须：

```
0. 选中锚点行（最后一条指令或目标上一条）→ Enter 创建空行（见上节）
1. 光标位于该空行，输入 `/`         → 弹出下拉浮层
2. 点击浮层内搜索框（placeholder「请输入」）
3. 在搜索框输入中文指令名称       → 如「打开网页」「输入文本」「点击」
4. 点击列表中与名称最匹配的一条   → 指令插入编排区
5. 插入后立即校验 canvas 顺序（见 ax-verify.md §插入后顺序校验）
```

> ⚠️ 确认浮层 Tab 在「**指令**」（默认），不要在「工具」或「工作流」Tab 下搜。

### 常用指令中文搜索名

| 平台指令名 | 搜索框输入（中文） | reference |
|---------|----------------|---------|
| 打开网页 | `打开网页` | `commands/openurl.md` |
| 输入文本 | `输入文本` | `commands/filltext.md` |
| 点击元素（推荐） | `点击` 或 `点击元素` | `commands/clickelementmixed.md` |

完整指令列表见 `reference/commands/index.md`。

### sky 自动化示例：插入「打开网页」（逐步验证）

> 完整「输入文本(web)」配置示例见 `ax-verify.md` §示例。

**第 1 步**：在插入点按 `/` → 验证浮层

```js
{
  const s0 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  // ... 从 s0 找插入点 idx ...
  await sky.click({ app: "com.google.Chrome", element_index: <插入点> });
  await sky.press_key({ app: "com.google.Chrome", key: "Return" });
  await sky.press_key({ app: "com.google.Chrome", key: "/" });
  await new Promise(r => setTimeout(r, 800));

  const s1 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const panelOpen = s1.text.includes("请输入");
  nodeRepl.write(JSON.stringify({ step: "insert-1", panelOpen }));
}
```

**第 2 步**：搜「打开网页」→ 验证列表

```js
{
  const s0 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const searchIdx = parseInt(s0.text.split("\n").find(l =>
    l.includes("请输入") && /settable|textfield/i.test(l)
  )?.match(/^\s*(\d+)/)?.[1]);
  await sky.click({ app: "com.google.Chrome", element_index: searchIdx });
  // echo -n "打开网页" | pbcopy
  await sky.press_key({ app: "com.google.Chrome", key: "cmd+v" });
  await new Promise(r => setTimeout(r, 800));

  const s1 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const hasResult = s1.text.includes("打开网页");
  nodeRepl.write(JSON.stringify({ step: "insert-2", hasResult }));
}
```

**第 3 步**：点匹配项 → 验证节点插入 **且顺序正确**

```js
{
  const s0 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const itemIdx = parseInt(s0.text.split("\n").find(l =>
    l.includes("打开网页") && !l.includes("请输入") && /按钮|链接/i.test(l)
  )?.match(/^\s*(\d+)/)?.[1]);
  await sky.click({ app: "com.google.Chrome", element_index: itemIdx });

  const s1 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const lines = s1.text.split("\n");
  const canvasStart = lines.findIndex(l => l.includes("编辑器容器"));
  const canvasText = lines.slice(canvasStart, canvasStart + 120).join("\n");

  const inserted = canvasText.includes("打开网页") && !s1.text.includes("请输入");
  // 「输入文本」不得出现在「打开网页」之前
  const orderOk = !canvasText.includes("输入文本") ||
    (canvasText.indexOf("打开网页") !== -1 &&
     canvasText.indexOf("打开网页") < canvasText.indexOf("输入文本"));

  nodeRepl.write(JSON.stringify({ step: "insert-3", inserted, orderOk }));
  // orderOk === false → §2.3a 选中错位节点→剪切→在正确位置粘贴
}
```

> 若列表有多条相似结果，优先点**名称完全匹配**的那条（如「打开网页」而非「打开网页(web)」的父级分类）。点错可 `Escape` 关闭浮层重来。

> ⚠️ **插入后顺序校验失败**：优先 **§2.3a 剪切→粘贴** 调整位置；若移动后节点异常，则选中错位节点 → `Delete` 删除 → 定位到**最后一条正确指令下方**空行 → 重新 `/` 插入。**禁止**在错误位置继续配置或调试。

配置指令参数时，**读取对应 `reference/commands/<指令>.md`**。

> ⚠️ 配置「打开网页」的「网址」时，**禁止** `type_text`（会丢冒号）。须 `pbcopy+paste` 或 `set_value`，见 **`url-input.md`**。

## 2.5 调试前场景顺序终检（必做）

全部指令配置保存完毕后、**点击「调试」之前**，必须对照 `reference/scenarios/<场景>.md`「指令节点」表，确认编排区 canvas 指令的**数量、类型、顺序**与场景设计一致。

```
1. Read scenarios/<场景>.md → 记录应有指令链（如：打开网页 → 输入文本 → 点击）
2. 目视 canvas 或抓 AX Tree，列出实际顺序（开始 → … → 结束）
3. 逐条对比场景表；全部匹配 → 方可调试
4. 不匹配 → **§2.3a 剪切→粘贴**（首选）；剪切失败再删后重插 → 再终检
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

## 2.4 指令弹框保存前校验（必做）

双击节点打开指令配置弹框（如「打开网页(web)」「延迟」）后，在「**常规**」Tab 的「**输入参数**」区填写参数。

> ⚠️ **硬性规则**：点击右下角「**保存**」前，**必须先验证所有必填项已填写**。**任一必填项为空 → 禁止点保存**，先补全再继续。

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
3. 元素选择器类字段：粘贴 XPath → 等 1s → 点「以 //xxx 为定位器」（见 `element-selector.md` C1）→ 若「未找到匹配结果」点 close icon
4. 全量抓 AX Tree：确认无「该字段是必填字段」类报错文案
5. 以上全部通过 → 再点弹框右下角「保存」
```

> ⚠️ **禁止**在必填项仍为空、仍标红、或 AX 中仍有必填报错时点击「保存」——保存会失败或落盘不完整，后续调试必然报错。

### 常见必填项（测试场景）

| 指令 | 必填字段（弹框 label 前带 `*`） |
|------|-------------------------------|
| 打开网页 | `网址` |
| 输入文本 | `元素选择器`、`待填充文本` |
| 点击元素（推荐） | `元素选择器` |
| 延迟 | `延迟时间` |

完整必填列表见 `reference/commands/index.md` 第三列，或单条 `reference/commands/<slug>.md`。

### sky 自动化：保存前自检 → 保存 → 验证关闭

> 自动化时同样遵循：**canSave === false 时不得 click 保存按钮**。

```js
{
  // 按当前指令替换 requiredLabels，须与 commands/<slug>.md 及弹框 * 字段一致
  const requiredLabels = ["延迟时间"]; // 例：延迟；打开网页用 ["网址"]；输入文本用 ["元素选择器","待填充文本"]

  const s0 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const panel = s0.text.split("\n");
  const hasPanel = panel.some(l => /打开网页|输入文本|点击元素|延迟/.test(l));
  const hasRequiredError = panel.some(l => l.includes("该字段是必填字段"));

  // 粗略校验：必填 label 附近应有非空 settable/value（具体 idx 因弹框结构而异，失败则目视补全）
  const missingRequired = requiredLabels.filter(label => {
    const labelLine = panel.find(l => l.includes(label));
    if (!labelLine) return true;
    const labelIdx = panel.indexOf(labelLine);
    const nearby = panel.slice(labelIdx, labelIdx + 6).join("\n");
    const hasValue = /value|settable.*[^\s]/.test(nearby) && !/value:\s*$/.test(nearby);
    return !hasValue;
  });

  const canSave = hasPanel && !hasRequiredError && missingRequired.length === 0;
  nodeRepl.write(JSON.stringify({ step: "save-check", canSave, missingRequired, hasRequiredError }));

  if (!canSave) {
    nodeRepl.write(JSON.stringify({ step: "save-blocked", reason: "必填项未填完，禁止点保存" }));
  } else {
    // axButtonIdx 见 ax-verify.md §分析辅助函数（兼容「保 存」）
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
