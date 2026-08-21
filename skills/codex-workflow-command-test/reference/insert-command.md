# 插入指令模块

> **模块定位**：本模块是**独立可复用的「在编排区 canvas 中插入指令」完整流程**，供技能内部各模块调用。任何需要在 RPA 平台编排工作流 canvas 中追加指令的场景，都应 Read 本模块执行，不要自行内联插入流程。
>
> **调用方**：`platform-ops.md`、`test-workflow.md`、`ax-verify.md`、`debug.md`、`scenarios/<场景>.md`、`commands/index.md`、`SKILL.md`。
>
> **前置条件**：
> - 已按 `platform-ops.md` §2.1 创建空编排工作流（canvas 仅有开始+结束节点）
> - 遵循 `ax-verify.md` 动作-验证循环：**每步动作后全量抓 AX Tree 验证**

## 插入位置约束（Enter 空行 · 从开始节点下方起建）

**起点变更（废弃旧流程）**：指令链从 **开始节点下方** 起建。**禁止**以结束节点上方、选中结束节点、或「拖拽添加指令」提示行作为首条/追加插入起点。

**Enter 键空行规则（统一模型）**：

| 意图 | 选中谁 | 按 Enter 后空行位置 |
|------|--------|-------------------|
| **首条业务指令** | **开始节点** | 开始节点正下方 |
| **向后追加**（在指令 A 之后插入） | **指令 A**（锚点 / 当前最后一条） | 指令 A 正下方 |
| **向前插入**（在指令 B 之前插入） | **指令 B 的上一条** | 上一条正下方（即 B 之前） |

> 🚫🚫🚫 **强制铁律**：
>
> 1. **首条**：canvas 仅有开始+结束节点时 → **单击「开始节点」行 → Enter** → 在开始节点**正下方**空出新行 → 再搜索/双击插入。
> 2. **向后追加**（按场景顺序逐条加指令）：**单击当前锚点指令行（通常是最后一条已保存指令）→ Enter** → 在其**正下方**空出新行 → 再搜索/双击插入。
> 3. **向前插入**（调序或在中间补插）：**单击目标位置的上一条指令 → Enter** → 空出新行 → 再搜索/双击或粘贴。
> 4. **绝不能**：不选锚点就搜索插入；在结束节点上按 Enter 作为起点；在任意两条已有指令**之间**无锚点乱按 Enter——新指令会排到错误位置，顺序即刻非法。

**光标定位规则**：
- **首条指令**（canvas 只有开始+结束节点）：单击 **开始节点** → `Return`/`Enter` → 开始节点**正下方**出现新空行 → 验证后搜索+双击
- **向后追加**（第 2 条及以后，场景顺序构建）：单击 **锚点指令**（要在其后面插入时，选该条；顺序构建时即最后一条已保存指令）→ `Return`/`Enter` → 锚点**正下方**新空行 → 验证后搜索+双击
- **向前插入**：单击 **目标指令的上一条** → `Return`/`Enter` → 空出新行 → 搜索+双击或粘贴

| 错误做法 ❌ | 正确做法 ✅ |
|-----------|-----------|
| 从**结束节点上方**起建首条指令（旧流程，已废弃） | **选中开始节点 → Enter** → 在开始节点下方插入首条 |
| 首条时点「拖拽添加指令」提示行（已废弃） | **选中开始节点 → Enter** |
| 已有「打开网页」后，在开始节点上按 Enter 直接插「输入文本」（导致顺序错乱） | **选中「打开网页」→ Enter** → 在其下方空行 → 再插「输入文本」 |
| 要在「输入文本」前插入，却选中「输入文本」本身 Enter | **选中「打开网页」（上一条）→ Enter** → 空行 → 插入或粘贴 |
| 批量连续插入多条后再统一配置 | 每插入一条 → 立即配置保存 → 再插下一条 |
| 拖拽 / 输入 `/` 唤起浮层 | 只用右侧「指令」Tab 搜索框 + 双击结果 |
| 插入后不校验就直接配表单 | 插入后**立即**核对新节点在锚点**之后**（见 §插入后强制核对） |

**场景顺序依赖**（Web 自动化通用，不可违反）：

```
打开网页 / 导航到URL → 输入文本 → 点击元素
```

| 待插入指令 | canvas 中必须已存在的前置指令 |
|-----------|------------------------------|
| 打开网页 / **导航到URL** | （无，通常是第一条业务指令） |
| 输入文本 | **打开网页** 或 **导航到URL**（必须先有页面才能填元素） |
| 点击元素 | **打开网页** 或 **导航到URL**；搜索类场景建议已有**输入文本** |

> 如图常见错误：「输入文本」排在「打开网页」之前 → **顺序非法**，调试必然失败。**首选**用 **§右键菜单调整指令顺序** 移到正确位置（保留已填配置）；剪切失败或节点异常时再删后重插。

## 右键菜单调整指令顺序（顺序错误时首选）

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

> ⚠️ 移动后仍需校验顺序依赖（§场景顺序依赖表）。**禁止**在错误顺序下继续配置或调试。

## 常用指令中文搜索名

在右侧「指令」Tab 搜索框输入以下中文名 → 匹配「网页自动化」分组下 `(web)` 结果 → 双击插入：

| 平台指令名 | 搜索框输入（中文） | 分组 | reference |
|---------|----------------|------|---------|
| 打开网页 | `打开网页` | 网页自动化 | `commands/openurl.md` |
| **导航到URL** | **`导航到URL`** | 网页自动化 | `commands/navigatetourl.md` |
| 输入文本 | `输入文本` | 网页自动化 | `commands/filltext.md` |
| 点击元素（推荐） | `点击` 或 `点击元素` | 网页自动化 | `commands/clickelementmixed.md` |
| 验证元素存在 | `验证元素存在` | 网页自动化 | `commands/verifyelementpresent.md` |
| 验证元素可见 | `验证元素可见` | 网页自动化 | `commands/verifyelementvisible.md` |

完整指令列表见 `reference/commands/index.md`。

> 🚫 **搜索词来源**：`set_value` 到搜索框的中文名必须来自 **`user-intent.md` 解析的 `instructionPlan[i].searchName`**。用户明确说「导航到url」→ 搜 **`导航到URL`**，**禁止**因场景默认是「打开网页」就搜「打开网页」。见 `user-intent.md` §优先级。

> ⚠️ 搜索结果常有同名多条：`(web)` vs `（mobile）`（Web 场景选 `(web)`），以及「我的收藏」分组 vs「网页自动化」分组（**只选后者**，前者行为不稳定）。

## 定位正确插入点（搜索+双击前必做）

**通用规则**：按 **Enter 空行规则** 定位插入点——首条选**开始节点**；向后追加选**锚点指令**；向前插入选**目标上一条**。空行生成并验证后，再搜索+双击。

```
1. 全量抓 AX Tree，在 canvas 区域读取当前节点顺序（开始 → … → 结束）
2. 光标定位（三选一，禁止混用）：
   - **首条业务指令**：单击 **开始节点** → 按 **Enter** → 开始节点**正下方**出现新空行 → 全量抓 AX 验证
   - **向后追加**：单击 **锚点指令**（要在其后面插入的那条；顺序构建时为最后一条已保存指令）→ 按 **Enter** → 锚点**正下方**新空行 → 验证
   - **向前插入**：单击 **目标指令的上一条** → 按 **Enter** → 空出新行 → 验证
3. 单击右侧「指令」Tab 搜索框（placeholder 为「请输入」）→ set_value 中文指令名
4. 等 ~1.2s 让搜索结果刷新
5. 在结果中双击「网页自动化」分组下匹配的 `xxx (web)` 项
6. 平台在空行处插入新节点，并自动弹出配置弹框
7. **插入后强制核对**：全量抓 AX Tree，确认新节点排在锚点指令**之后**（见 §插入后强制核对），核对通过才继续配表单
```

**sky 自动化：读取 canvas 节点顺序 → 确认追加插入点**

```js
{
  const s = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const lines = s.text.split("\n");
  const canvasStart = lines.findIndex(l => l.includes("编辑器容器"));
  const canvasArea = lines.slice(canvasStart, canvasStart + 120);

  // 提取 canvas 内带编号的指令行（编号 + 文本 + 指令摘要）
  const summaries = [];
  for (let i = 0; i < canvasArea.length; i++) {
    const m = canvasArea[i].match(/^\s+(\d+)\s+文本\s+\d+\s*$/);
    if (!m) continue;
    const desc = (canvasArea[i + 1] || "") + (canvasArea[i + 2] || "");
    summaries.push({ num: parseInt(m[1]), desc });
  }

  const orderOk = (() => {
    const texts = summaries.map(s => s.desc).join("|");
    const hasPageOpen = /打开网页|导航到URL/.test(texts);
    if (texts.includes("输入文本") && !hasPageOpen) return false;
    const pageIdx = Math.min(
      texts.includes("打开网页") ? texts.indexOf("打开网页") : Infinity,
      texts.includes("导航到URL") ? texts.indexOf("导航到URL") : Infinity
    );
    if (texts.includes("输入文本") && pageIdx !== Infinity && texts.indexOf("输入文本") < pageIdx) return false;
    return true;
  })();

  nodeRepl.write(JSON.stringify({
    step: "insert-point-check",
    nodes: summaries,
    orderOk,
    hint: orderOk
      ? "光标定位后：右侧搜索框 set_value 指令名 → 双击「网页自动化」分组下的 (web) 项"
      : "顺序错误：选中错位节点→剪切→选中锚点行→Enter 空出一行→粘贴（§右键菜单调整指令顺序）"
  }));
}
```

## sky 自动化模板：搜索框 + 双击结果（唯一添加方式）

**第 1 步：光标定位到 canvas 编辑区**（⚠️ 两个分支互斥，先判断 canvas 是否已有业务指令，再执行**对应**分支——非首条分支**不可跳过**，是本模块反复出错的高危点）

**1a. 首条业务指令**（canvas 仅有开始+结束节点，无其他业务指令）：

```js
{
  const s = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const startLine = s.text.split("\n").find(l => /开始节点/.test(l));
  const startIdx = startLine ? parseInt(startLine.match(/^\s*(\d+)/)[1]) : null;
  await sky.click({ app: "com.google.Chrome", element_index: startIdx });
  await new Promise(r => setTimeout(r, 300));
  await sky.press_key({ app: "com.google.Chrome", key: "Return" });
  await new Promise(r => setTimeout(r, 400));
  const s1 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  nodeRepl.write(JSON.stringify({ step: "insert-1a-first-instruction", startIdx, afterStartEnter: /开始节点/.test(s1.text) }));
}
```

**1b. 向后追加**（第 2 条及以后，在锚点指令之后插入 · **必须执行，禁止省略**）：

> 🚫 判断依据：canvas 中「编辑器容器」区域内，除开始/结束节点外**已存在至少一条**业务指令 → 走本分支，**不得**走 1a。

```js
{
  // Step 1：全量抓 AX Tree，在 canvas 区域内找到当前"最后一条"已保存指令的文本行
  const s0 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const lines0 = s0.text.split("\n");
  const canvasStart = lines0.findIndex(l => l.includes("编辑器容器"));
  const canvasArea = lines0.slice(canvasStart, canvasStart + 150);

  // 已知指令关键词按插入顺序匹配，取"最后出现"的那一条作为锚点
  const knownCmds = ["验证元素存在", "验证元素可见", "点击", "输入文本", "打开网页"]; // 按需扩展
  let anchorLine = null, anchorLineIdxInArea = -1;
  for (let i = canvasArea.length - 1; i >= 0; i--) {
    if (knownCmds.some(k => canvasArea[i].includes(k)) && /^\s*\d+\s+文本/.test(canvasArea[i])) {
      anchorLine = canvasArea[i];
      anchorLineIdxInArea = i;
      break;
    }
  }
  const anchorIdx = anchorLine ? parseInt(anchorLine.match(/^\s*(\d+)/)[1]) : null;

  if (!anchorIdx) {
    nodeRepl.write(JSON.stringify({ step: "insert-1b-error", error: "未找到锚点指令行，禁止继续插入" }));
  } else {
    // Step 2：单击该锚点行（最后一条已保存指令）
    await sky.click({ app: "com.google.Chrome", element_index: anchorIdx });
    await new Promise(r => setTimeout(r, 300));

    // Step 3：按 Enter/Return，在锚点行正下方空出新行
    await sky.press_key({ app: "com.google.Chrome", key: "Return" });
    await new Promise(r => setTimeout(r, 400));

    // Step 4：验证 —— canvas 节点总行数应增加（新空行已生成），且新空行紧跟锚点行之后
    const s1 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
    const lines1 = s1.text.split("\n");
    const canvasStart1 = lines1.findIndex(l => l.includes("编辑器容器"));
    const canvasArea1 = lines1.slice(canvasStart1, canvasStart1 + 150);
    const newLineCreated = canvasArea1.length >= canvasArea.length; // 粗校验：结构未减少/已扩展

    nodeRepl.write(JSON.stringify({
      step: "insert-1b-anchor-enter",
      anchorLine,
      anchorIdx,
      newLineCreated,
      action: newLineCreated ? "proceed-to-search-command" : "retry-click-anchor-and-enter"
    }));
    // newLineCreated === false → 重新单击锚点行 → 再按 Return，禁止直接跳到搜索步骤
  }
}
```

> ⚠️ **禁止**用 1a 分支处理非首条指令——1a 只用于**开始节点 → Enter**。有业务指令后必须走 1b（向后追加）或选中目标上一条（向前插入），误用会导致新指令插到错误位置。

**1c. 向前插入**（在已有指令 B 之前插入）：单击 **B 的上一条指令** → Enter → 空出新行 → 搜索+双击或粘贴。

## 平台 UI 实测踩坑（2026-08 · 必读）

> 以下来自 WF3「网页操作基础」批量插入时的真实失败复盘。**禁止**再依赖旧 AX 模式或「一条 exec 包到底」。

### 0. 必须先激活「指令」Tab，否则没有搜索框

右侧面板默认可能是 **Chat**。只有 AX 中出现 `文本 指令` 且已选中后，才会出现指令搜索框。

```js
{
  const app = "com.google.Chrome";
  const parseIdx = (l) => parseInt((l.match(/^\s*(\d+)/) || [])[1]);
  let s = await sky.get_app_state({ app, disableDiff: true });
  const cmdTab = s.text.split("\n").find(l => /\d+\s+文本\s+指令/.test(l));
  if (cmdTab) {
    await sky.click({ app, element_index: parseIdx(cmdTab) });
    await new Promise(r => setTimeout(r, 600));
  }
}
```

**失败信号**：全树找不到 `请输入` 搜索框 → 99% 是未点「指令」Tab 或按了 `Escape` 把面板关掉。

### 1. 搜索框 AX 模式已变（勿再用旧正则）

| 状态 | AX 形态 | 能否命中 |
|------|---------|----------|
| ❌ 旧文档（已失效） | `settable, string` + `Placeholder: 请输入` | 2026-08 实测**命不中** |
| ✅ 当前平台 | `文本栏 (settable) 请输入` 或 `文本栏 (settable) Value: xxx, Placeholder: 请输入` | **用这个** |

```js
function findInstructionSearchIdx(lines) {
  const line = lines.find(l =>
    /文本栏\s+\(settable\)/.test(l) &&
    (/Placeholder:\s*请输入/.test(l) || /\b请输入\b/.test(l)) &&
    !/地址和搜索栏/.test(l)
  );
  return line ? parseInt(line.match(/^\s*(\d+)/)[1]) : null;
}
```

### 2. 搜索必须用 click + pbcopy + Cmd+V，禁止 set_value

`set_value` 写入搜索框后 Value 会变，但**右侧结果列表不出现**，后续无法双击。

```
Shell: printf '%s' '导航到URL' | pbcopy   ← 在 exec 外或 execFileSync 内设剪贴板
exec 内: click 搜索框 → Cmd+A → Cmd+V → 等 2s → 再抓 AX 找结果行
```

### 3. 双击目标：`(web)` 后缀不是必要条件

实测结果行常为 **`293 文本 导航到URL`**，**没有** `(web)`，role 是 `文本` 而非 `text`。

匹配优先级（从高到低）：

1. `text\s+{platformName}\s*\(web\)` 且上方 5 行含 `网页自动化`
2. `^\s+\d+\s+文本\s+{platformName}\s*$` 且上方含 `网页自动化`
3. 任意含 `{platformName}` 的 `文本`/`text` 行（在「网页自动化」分组下）

**禁止**仅因找不到 `(web)` 就报 `no result` 并跳过双击——这是 WF3 多轮「看似没双击」的主因。

```js
function findWebAutomationResultIdx(lines, platformName) {
  const parseIdx = (l) => parseInt((l.match(/^\s*(\d+)/) || [])[1]);
  const esc = platformName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  for (let i = 0; i < lines.length; i++) {
    const webGroup = lines.slice(Math.max(0, i - 8), i).join("\n");
    if (!/网页自动化/.test(webGroup) || /我的收藏/.test(webGroup)) continue;
    if (new RegExp(`text\\s+${esc}\\s*\\(web\\)`).test(lines[i])) return parseIdx(lines[i]);
    if (new RegExp(`^\\s+\\d+\\s+文本\\s+${esc}\\s*$`).test(lines[i])) return parseIdx(lines[i]);
  }
  return null;
}
```

### 4. 锚点 Enter 非必须；坐标失败时立即降级

锚点行（如 `text 打开网页 url:`）偶发 `coordinate must include finite x and y coordinates`。**不要**因此放弃整轮插入。

**降级路径（推荐默认）**：

```
点「指令」Tab → click 搜索框 → pbcopy + Cmd+V → 双击结果 → 配表保存
```

canvas 会在**当前选中插入点**或**最后一条指令下方**追加；插入后做 §插入后强制核对 即可。

### 5. 拆分 exec，禁止「搜索+双击+配表+保存」一条包到底

任一步失败会导致整段退出，表象像「从未双击」。推荐：

| exec | 内容 |
|------|------|
| A | 点指令 Tab → 搜索 → 返回 `resultIdx` |
| B | 双击 `resultIdx` → 填表 → 保存 |
| C | §插入后强制核对 |

### 6. 推荐最小路径（单条指令 · 已验证）

```js
{
  const { execFileSync } = await import("node:child_process");
  const app = "com.google.Chrome";
  const platformName = "导航到URL"; // 来自 instructionPlan[i].platformName
  const parseIdx = (l) => parseInt((l.match(/^\s*(\d+)/) || [])[1]);

  let s = await sky.get_app_state({ app, disableDiff: true });
  let lines = s.text.split("\n");
  const cmdTab = lines.find(l => /\d+\s+文本\s+指令/.test(l));
  if (cmdTab) { await sky.click({ app, element_index: parseIdx(cmdTab) }); await new Promise(r => setTimeout(r, 600)); }

  s = await sky.get_app_state({ app, disableDiff: true });
  lines = s.text.split("\n");
  const searchIdx = findInstructionSearchIdx(lines);
  execFileSync("/usr/bin/pbcopy", { input: platformName });
  await sky.click({ app, element_index: searchIdx });
  await sky.press_key({ app, key: "Command+a" });
  await sky.press_key({ app, key: "Command+v" });
  await new Promise(r => setTimeout(r, 2000));

  s = await sky.get_app_state({ app, disableDiff: true });
  lines = s.text.split("\n");
  const resultIdx = findWebAutomationResultIdx(lines, platformName);
  if (!resultIdx) throw new Error("no result after search — check 指令 Tab and pbcopy");

  await sky.click({ app, element_index: resultIdx, click_count: 2 });
  await new Promise(r => setTimeout(r, 1500));
  // → 弹框打开后转 platform-ops §2.4 / url-input.md 配表
}
```

**第 2 步**：搜索框稳定粘贴中文指令名

> `query` **必须**取自 `user-intent.md` → `instructionPlan[i].searchName`，**禁止**写死 `"打开网页"`。

```js
{
  const { execFileSync } = await import("node:child_process");
  const app = "com.google.Chrome";
  // 来自 user-intent.md 解析；示例：用户说「导航到url」→ query = "导航到URL"
  const instructionPlan = [{ searchName: "导航到URL", platformName: "导航到URL" }];
  const i = 0;
  const query = instructionPlan[i].searchName;
  const s = await sky.get_app_state({ app, disableDiff: true });
  let lines = s.text.split("\n");
  const cmdTab = lines.find(l => /\d+\s+文本\s+指令/.test(l));
  if (cmdTab) {
    await sky.click({ app, element_index: parseInt(cmdTab.match(/^\s*(\d+)/)[1]) });
    await new Promise(r => setTimeout(r, 600));
    lines = (await sky.get_app_state({ app, disableDiff: true })).text.split("\n");
  }
  const searchLine = lines.find(l =>
    /文本栏\s+\(settable\)/.test(l) &&
    (/Placeholder:\s*请输入/.test(l) || /\b请输入\b/.test(l)) &&
    !/地址和搜索栏/.test(l)
  );
  const searchIdx = searchLine ? parseInt(searchLine.match(/^\s*(\d+)/)[1]) : null;
  execFileSync("/usr/bin/pbcopy", { input: query });
  await sky.click({ app, element_index: searchIdx });
  await new Promise(r => setTimeout(r, 300));
  await sky.press_key({ app, key: "Command+a" });
  await sky.press_key({ app, key: "Command+v" });
  await new Promise(r => setTimeout(r, 1200));
  const s1 = await sky.get_app_state({ app, disableDiff: true });
  const platformName = instructionPlan[i].platformName;
  const esc = platformName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const hasResult = new RegExp(`(${esc}\\s*\\(web\\)|文本\\s+${esc})`).test(s1.text);
  nodeRepl.write(JSON.stringify({ step: "search", query, searchIdx, pasted: s1.text.includes(query), hasResult }));
}
```

**第 3 步**：双击「网页自动化」分组下的 `xxx (web)` 项 → 验证 canvas 追加

```js
{
  const instructionPlan = [{ searchName: "导航到URL", platformName: "导航到URL" }];
  const platformName = instructionPlan[0].platformName;
  const s = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const lines = s.text.split("\n");
  let resultIdx = null;
  const esc = platformName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  for (let i = 0; i < lines.length; i++) {
    const above = lines.slice(Math.max(0, i - 8), i).join("\n");
    if (!/网页自动化/.test(above) || /我的收藏/.test(above)) continue;
    if (new RegExp(`text\\s+${esc}\\s*\\(web\\)`).test(lines[i]) ||
        new RegExp(`^\\s+\\d+\\s+文本\\s+${esc}\\s*$`).test(lines[i])) {
      resultIdx = parseInt(lines[i].match(/^\s*(\d+)/)[1]);
      break;
    }
  }
  await sky.click({ app: "com.google.Chrome", element_index: resultIdx, click_count: 2 });
  await new Promise(r => setTimeout(r, 1500));

  const s1 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const dialogOpened = new RegExp(`${platformName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\(web\\)`).test(s1.text);
  nodeRepl.write(JSON.stringify({ step: "dblclick", platformName, resultIdx, dialogOpened }));
}
```

> 若列表有多条相似结果，优先双击**名称完全匹配**且属于**网页自动化**分组的那条。双击错项 → 关弹框 → 单击错项 → `Delete` 删除 → 重新走搜索+双击流程。

> ⚠️ **插入后顺序校验失败**：优先 **§右键菜单调整指令顺序** 剪切→粘贴调整位置；若移动后节点异常，则选中错位节点 → `Delete` 删除 → 定位到**最后一条正确指令下方**空行 → 重新走搜索+双击流程。**禁止**在错误位置继续配置或调试。

## 插入后强制核对（每插入一条 · 不可跳过）

> 🚫 **本节是防线的最后一道保险**：即便前面「1b 光标定位」已验证空行生成，仍必须在双击插入完成后**再核对一次**新节点在 canvas 中的实际编号位置——防止空行位置判断错误导致新指令排到锚点指令**前面**。

```js
{
  // 关闭弹框后（或从弹框 header 判断即可，无需关闭）执行本核对
  const s = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const lines = s.text.split("\n");
  const canvasStart = lines.findIndex(l => l.includes("编辑器容器"));
  const canvasArea = lines.slice(canvasStart, canvasStart + 150);

  // 按 canvas 内出现顺序提取业务指令关键词序列（保留出现顺序，不去重）
  const knownCmds = ["打开网页", "输入文本", "点击", "验证元素存在", "验证元素可见"]; // 按场景实际用到的指令扩展
  const seq = [];
  for (const line of canvasArea) {
    for (const k of knownCmds) {
      if (line.includes(k) && /^\s*\d+\s+文本/.test(line)) { seq.push(k); break; }
    }
  }

  // 本次插入的指令名（替换为实际值，如"输入文本"）
  const justInserted = "输入文本";
  // 锚点指令名（本次插入前 canvas 中最后一条已保存指令，如"打开网页"）
  const anchorCmd = "打开网页";

  const insertedIdxInSeq = seq.lastIndexOf(justInserted);
  const anchorIdxInSeq = seq.lastIndexOf(anchorCmd);
  const positionOk = insertedIdxInSeq > anchorIdxInSeq;

  nodeRepl.write(JSON.stringify({
    step: "post-insert-order-audit",
    seq,
    justInserted,
    anchorCmd,
    positionOk,
    action: positionOk
      ? "order-correct-continue-config"
      : "ORDER-WRONG-must-fix-via-right-click-cut-paste-before-any-further-config"
  }));
  // positionOk === false → 立即停止配置该节点，按 §右键菜单调整指令顺序 剪切→粘贴 修正到锚点指令下方，再继续
}
```

**核对判定标准**：

| 结果 | 含义 | 下一步 |
|------|------|--------|
| `positionOk: true` | 新插入指令在 canvas 序列中确实排在锚点指令**之后** | 继续为该节点配置表单参数 |
| `positionOk: false` | 新指令被插到了锚点指令**之前**（如图中「验证元素存在」排在「打开网页」前） | **立即停止**，禁止继续配表单；按 `§右键菜单调整指令顺序` 剪切新节点 → 粘贴到锚点指令下方 → 重新核对 |

## AX 验证信号汇总

| 步骤 | 成功信号 | 失败信号 | 下一步 |
|------|---------|---------|--------|
| 1a 首条：选中开始节点 + Enter | 开始节点**正下方**出现新空行 | 无新行 | 重新单击开始节点再 Enter |
| 1b 向后追加：选中锚点 + Enter | 锚点**正下方**出现新空行 | 无新行 | 重新单击锚点再 Enter |
| 0 点「指令」Tab | AX 出现 `文本栏 (settable) 请输入` 搜索框 | 全树无 `请输入` | 点 `文本 指令` Tab，勿按 Escape |
| 2 搜索框 pbcopy+Cmd+V | 出现 `文本 {指令名}` 或 `text {指令名} (web)`；上方有「网页自动化」 | Value 变但无结果行 | **禁止 set_value**；改 click+paste |
| 3 双击结果 | canvas 出现新节点编号；同时弹出配置弹框 | canvas 未变；无弹框 | 用 §3 降级匹配 `文本 导航到URL` 再双击 |
| **插入后顺序核对** | 新节点在**锚点指令之后**、结束节点之前；依赖顺序满足 | 新指令排在锚点指令**前面** → **立即停止配表单** | §右键菜单调整指令顺序 剪切→粘贴 修正 |

## 与其他模块的调用关系

| 调用方 | 调用时机 | 本模块返回 |
|--------|---------|-----------|
| `platform-ops.md` | 需在编排区 canvas 中追加指令 | 新节点已插入 canvas 正确位置（锚点指令之后、结束节点之前） |
| `test-workflow.md` | 测试流程第 2 步「编排区按顺序添加指令」 | 同上 |
| `ax-verify.md` | 插入后顺序校验、光标定位验证 | 同上 |
| `debug.md` | 顺序错误修复（剪切→粘贴） | 同上 |
| `scenarios/<场景>.md` | 场景执行步骤中追加指令 | 同上 |
| `commands/index.md` | 指令插入方式说明 | 同上 |

> **调用约定**：调用方负责确保前置条件满足（空工作流已创建、canvas 可见），然后 Read 本模块从 §插入位置约束 开始执行。本模块不负责工作流创建（见 `platform-ops.md` §2.1）、表单配置（见 `platform-ops.md` §2.4）或调试运行（见 `debug.md`）。
