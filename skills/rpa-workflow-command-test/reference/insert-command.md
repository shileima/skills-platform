# 插入指令模块

> **模块定位**：本模块是**独立可复用的「在编排区 canvas 中插入指令」完整流程**，供技能内部各模块调用。任何需要在 RPA 平台编排工作流 canvas 中追加指令的场景，都应 Read 本模块执行，不要自行内联插入流程。
>
> **调用方**：`platform-ops.md`、`test-workflow.md`、`ax-verify.md`、`debug.md`、`scenarios/<场景>.md`、`commands/index.md`、`SKILL.md`。
>
> **前置条件**：
> - 已按 `platform-ops.md` §2.1 创建空编排工作流（canvas 仅有开始+结束节点）
> - 遵循 `ax-verify.md` 动作-验证循环：**每步动作后全量抓 AX Tree 验证**

## 插入位置约束（追加式 · 禁止插队）

**核心规则**：新指令必须**追加在已有指令链末尾**（最后一条指令之后、结束节点之前），**禁止**在开始节点后、已有指令之前、或两条已有指令之间插入。

> 🚫🚫🚫 **强制铁律（非首条指令必读，反复出错的高危步骤）**：
>
> **除第一条业务指令外，任何一条新指令插入前，都必须先「单击最后一条已保存指令那一行 → 按 Enter 键」，在其正下方空出一个新行，光标停在这个新空行里，才能继续搜索/双击插入下一条指令。**
>
> - **点谁**：canvas 中**当前最后一条已保存指令**的文本行（例如已有「打开网页」，就点「打开网页」这一行；已有「打开网页→输入文本」，就点「输入文本」这一行——永远点**最下面**那条）
> - **按什么键**：`Return`/`Enter`
> - **空出的行在哪**：紧跟在被选中指令的**下方**（这是唯一合法的新插入点）
> - **绝不能**：把光标停在开始节点下方、第一条指令上方，或任意两条已有指令**之间**再按 Enter/唤起搜索——那样插入的新指令会排到已有指令**前面**，顺序即刻非法

**光标定位规则**：
- **首条指令**（canvas 只有开始+结束节点）：单击 canvas 里「通过输入或者从指令列表拖拽添加指令」提示行让光标进入编辑区
- **第 2 条及以后每一条指令**（**必须执行，不可省略**）：
  1. 单击 canvas 中**最后一条已保存指令**的文本行（如「打开网页 https://...」）
  2. 按 `Return`/`Enter` 键 → 该指令**正下方**出现一个新空行
  3. 全量抓 AX Tree **验证空行已生成**且光标在新空行内（见下方 sky 验证片段）
  4. 确认无误后再继续「搜索框输入指令名 → 双击结果」

| 错误做法 ❌ | 正确做法 ✅ |
|-----------|-----------|
| 已有「打开网页」后，在开始节点下方空行插入「输入文本」（导致「输入文本」排在「打开网页」前面） | 单击「打开网页」这一行 → **Return** → 光标落在「打开网页」**下方**新空行 → 再插入「输入文本」 |
| 批量连续插入多条后再统一配置 | 每插入一条 → 立即配置保存 → 再插下一条 |
| 光标停在第 2 步位置就插入第 3 步 | 选中**最后一条已保存指令** → **Return** 空出一行 → 再插第 3 步 |
| 拖拽指令项到 canvas / 输入 `/` 唤起浮层 | 只用右侧「指令」Tab 搜索框 + 双击结果 |
| 插入后不校验就直接配表单 | 插入后**立即**核对新节点编号顺序在锚点指令**之后**（见 §插入后强制核对） |

**场景顺序依赖**（Web 自动化通用，不可违反）：

```
打开网页 → 输入文本 → 点击元素
```

| 待插入指令 | canvas 中必须已存在的前置指令 |
|-----------|------------------------------|
| 打开网页 | （无，通常是第一条业务指令） |
| 输入文本 | **打开网页**（必须先有页面才能填元素） |
| 点击元素 | **打开网页**；搜索类场景建议已有**输入文本** |

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
| 输入文本 | `输入文本` | 网页自动化 | `commands/filltext.md` |
| 点击元素（推荐） | `点击` 或 `点击元素` | 网页自动化 | `commands/clickelementmixed.md` |
| 验证元素存在 | `验证元素存在` | 网页自动化 | `commands/verifyelementpresent.md` |
| 验证元素可见 | `验证元素可见` | 网页自动化 | `commands/verifyelementvisible.md` |

完整指令列表见 `reference/commands/index.md`。

> ⚠️ 搜索结果常有同名多条：`(web)` vs `（mobile）`（Web 场景选 `(web)`），以及「我的收藏」分组 vs「网页自动化」分组（**只选后者**，前者行为不稳定）。

## 定位正确插入点（搜索+双击前必做）

**通用规则**：插入位置永远是「已有指令链末尾」。**非首条指令必须先单击最后一条已保存指令行 → 按 Enter 空出新行**，光标落入该新行后再搜索+双击，平台才会把新节点插入到正确位置（锚点指令下方、结束节点上方）。

```
1. 全量抓 AX Tree，在 canvas 区域读取当前节点顺序（开始 → … → 结束）
2. 光标定位（🚫 二选一，禁止混用）：
   - 首条业务指令：单击 canvas「通过输入或者从指令列表拖拽添加指令」提示行
   - 非首条指令（强制铁律）：单击 canvas 中**最后一条已保存指令**的文本行（如「打开网页 https://...」）→ 按 **Enter** 键 → 该行**正下方**出现新空行 → 全量抓 AX 验证空行已生成
3. 单击右侧「指令」Tab 搜索框（placeholder 为「请输入」）→ set_value 中文指令名
4. 等 ~1.2s 让搜索结果刷新
5. 在结果中双击「网页自动化」分组下匹配的 `xxx (web)` 项
6. 平台在 canvas 末尾插入新节点，并自动弹出配置弹框
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
    if (texts.includes("输入文本") && !texts.includes("打开网页")) return false;
    if (texts.includes("输入文本") && texts.indexOf("输入文本") < texts.indexOf("打开网页")) return false;
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
  const hintLine = s.text.split("\n").find(l => /文本\s+通过输入或者从指令列表拖拽添加指令/.test(l));
  const hintIdx = hintLine ? parseInt(hintLine.match(/^\s*(\d+)/)[1]) : null;
  await sky.click({ app: "com.google.Chrome", element_index: hintIdx });
  await new Promise(r => setTimeout(r, 400));
  nodeRepl.write(JSON.stringify({ step: "insert-1a-first-instruction", hintIdx }));
}
```

**1b. 第 2 条及以后每一条指令**（**必须执行，禁止省略或跳过**）：

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

> ⚠️ **禁止**用 1a 分支处理非首条指令——1a 点的是「通过输入或者从指令列表拖拽添加指令」提示行，该提示行在有指令后已不存在或位置已变化，误用会导致光标落点不可控，新指令极易插到错误位置（如插到已有指令**前面**）。

**第 2 步**：搜索框 set_value 中文指令名

```js
{
  const s = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const searchLine = s.text.split("\n").find(l =>
    /settable, string/.test(l) && /Placeholder: 请输入/.test(l)
  );
  const searchIdx = searchLine ? parseInt(searchLine.match(/^\s*(\d+)/)[1]) : null;
  await sky.set_value({ app: "com.google.Chrome", element_index: searchIdx, value: "打开网页" });
  await new Promise(r => setTimeout(r, 1200));
  const s1 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const hasResult = /打开网页\s*\(web\)/.test(s1.text);
  nodeRepl.write(JSON.stringify({ step: "search", searchIdx, hasResult }));
}
```

**第 3 步**：双击「网页自动化」分组下的 `xxx (web)` 项 → 验证 canvas 追加

```js
{
  const s = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const lines = s.text.split("\n");
  let resultIdx = null;
  for (let i = 0; i < lines.length; i++) {
    if (/text\s+打开网页\s*\(web\)/.test(lines[i])) {
      const above = lines.slice(Math.max(0, i - 5), i).join("\n");
      if (/网页自动化/.test(above) && !/我的收藏/.test(above)) {
        resultIdx = parseInt(lines[i].match(/^\s*(\d+)/)[1]);
        break;
      }
    }
  }
  await sky.click({ app: "com.google.Chrome", element_index: resultIdx, click_count: 2 });
  await new Promise(r => setTimeout(r, 1500));

  const s1 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  // 双击后弹出配置弹框 —— canvas 已在其下，需从头部 header 判断
  const dialogOpened = /打开网页\(web\).*复制.*帮助/.test(s1.text);
  // 关闭弹框（若只追加不配置）：header 里「帮助」link 之后紧邻的空文本 `\d+ 文本 ` 单独一行
  const headerIdx = s1.text.split("\n").findIndex(l => /container.*打开网页\(web\).*复制.*帮助/.test(l));
  let closeIdx = null;
  if (headerIdx >= 0) {
    for (let i = headerIdx; i < headerIdx + 30 && i < s1.text.split("\n").length; i++) {
      const line = s1.text.split("\n")[i];
      if (/^\s*\d+\s+文本\s*$/.test(line) && i > headerIdx + 5) {
        closeIdx = parseInt(line.match(/^\s*(\d+)/)[1]);
        break;
      }
    }
  }
  nodeRepl.write(JSON.stringify({ step: "dblclick", resultIdx, dialogOpened, closeIdx }));
  // 如需继续追加下一条：await sky.click({ app: "com.google.Chrome", element_index: closeIdx });
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
| 1a 首条光标定位 | 焦点在 canvas 编辑器；`focused UI element` 指向 canvas 内元素 | 焦点仍在别处 | 重新点击提示行 |
| 1b 单击锚点行 | 该行高亮/获焦 | 点空了或点到其他节点 | 重新定位锚点行 |
| 1b 按 Enter 空行 | 锚点行**正下方**出现新空行；canvas 节点行数增加 | 无新行；仍是原节点数 | 重新单击锚点行再按 Enter，**禁止**跳过直接搜索 |
| 2 搜索框 set_value | 右侧「指令」面板出现 `xxx (web)` 结果行；含「网页自动化」分组 | 无结果；仍在旧搜索词 | 重新 set_value |
| 3 双击结果 | canvas 出现新节点编号；同时弹出配置弹框 | canvas 未变；无弹框 | 重试双击 |
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
