# Sky 运行时（速度 + 准确率 · 每次执行必读）

> **定位**：本模块是**所有 sky `/exec` 脚本的共享运行时**——helper 只维护一处，插入/配表/调试模块引用本文件，禁止各模块各自复制变体。
>
> **调用方**：`insert-command.md`、`platform-ops.md`、`test-workflow.md`、`element-selector.md`、`url-input.md`、`debug.md`。
>
> **目标**：更少 exec 往返、更短等待、更高 idx 命中率、更少 canvas 污染。

## 执行前：Chrome 前台（Shell · 每个 exec 批次前）

> 🚫 **禁止**在 `cgWindowNotFound` 时盲目 `daemon.sh restart`——优先走本节；仅当 `nodeRepl.write("ok")` 也失败时才 restart。

```bash
osascript <<'AS'
tell application "Google Chrome"
  activate
  if (count of windows) = 0 then make new window
end tell
delay 1
tell application "System Events" to set frontmost of process "Google Chrome" to true
delay 1
AS
```

**工作流页已存在时**（失焦恢复 · 禁止用地址栏导航离开当前 Tab 再回来）：

```bash
WORKFLOW_URL="https://rpa.sankuai.com/space/<spaceId>/workflow/<workflowId>/config?subType=2"
osascript -e "tell application \"Google Chrome\" to activate" -e "tell application \"Google Chrome\" to set URL of active tab of front window to \"$WORKFLOW_URL\""
sleep 5
osascript -e 'tell application "System Events" to set frontmost of process "Google Chrome" to true'
sleep 2
```

每个 `/exec` 块**第一行必须是** `await sky.get_app_state({ app, disableDiff: true })`（满足 Computer Use 激活要求）。

## Exec 批次策略（速度）

| 策略 | ✅ 推荐 | ❌ 禁止 |
|------|--------|--------|
| 批次粒度 | **一条指令 = 一次 exec**：`insert → 配表 → 保存 → canvas 验证` | 每条指令拆成 5+ 次 exec |
| 全场景 | 4 步场景 ≤ **6 次 exec**（前置 1 + 每指令 1 + 终检**+一次性调试** 1） | 每指令 exec 后点「调试」；配置未完成就运行 |
| 等待 | **轮询 AX**（350ms × ≤6） | 固定 `sleep(2000)` 盲等 |
| 「检查」 | **全部指令保存后** 点一次 | 每保存一条都点「检查」 |
| 「调试」 | **终检通过后** 一次性「调试 → 运行」 | **每条指令插入/保存后调试**；配置阶段任何时刻点「调试」 |
| 剪贴板 | **Shell** `printf '%s' '…' \| /usr/bin/pbcopy`，再进 exec paste；若 paste 后 AX 未出现目标文本，仅对当前 scoped 字段 `set_value` 兜底 | `execFileSync('pbcopy')` 在 nodeRepl 内（实测会失败）；未验证就保存 |
| 导航 | **钉在工作流 Tab**；XPath 采集用 **Cmd+T 新 Tab** | 工作流 Tab 地址栏打开目标站（丢 canvas） |
| idx | **同 exec 内**动态解析；下一步 exec 重新抓树 | 跨 exec 复用 `element_index` |
| 失败 | 同指令 **2 次**仍失败 → 删节点原位重插 | 同位置连点 4+ 次 |

## 共享 Helper 包（每个 exec 块开头复制）

```js
{
  const app = "com.google.Chrome";
  const sleep = (ms) => new Promise(r => setTimeout(r, ms));

  const mustIdx = (n, label) => {
    if (!Number.isInteger(n) || n < 0) throw new Error(`${label} invalid: ${n}`);
    return n;
  };

  const linesOf = (s) => s.text.split("\n");

  const findAllIdx = (text, sub) => {
    const out = [];
    text.split("\n").forEach((line) => {
      if (line.includes(sub)) out.push({ idx: parseInt(line.match(/^\s*(\d+)/)?.[1]), line });
    });
    return out;
  };

  const findIdx = (text, sub) => {
    const h = findAllIdx(text, sub);
    return h.length ? h[0].idx : -1;
  };

  const axHasLabel = (line, label) => new RegExp(label.split("").join("\\s*")).test(line);

  const axButtonIdx = (lines, label) => {
    const line = lines.find(l => axHasLabel(l, label) && l.includes("按钮") && !/disabled/.test(l));
    return line ? parseInt(line.match(/^\s*(\d+)/)?.[1]) : null;
  };

  // 面板内 Tab「指令」，不是右侧边栏图标
  const findCmdTab = (text) => mustIdx(
    findAllIdx(text, "文本 指令").find(m =>
      /^\s*\d+\s+文本\s+指令\s*$/.test(m.line.replace(/\t/g, " ").trim())
    )?.idx,
    "cmdTab"
  );

  const findSearchIdx = (text) => {
    let idx = findIdx(text, "Placeholder: 请输入");
    if (idx >= 0) return idx;
    const hit = findAllIdx(text, "文本栏").find(m =>
      /请输入/.test(m.line) && !/地址|编辑器|环境|发送/.test(m.line)
    );
    return hit?.idx ?? -1;
  };

  const waitSearchIdx = async () => {
    for (let i = 0; i < 6; i++) {
      const s = await sky.get_app_state({ app, disableDiff: true });
      const idx = findSearchIdx(s.text);
      if (idx >= 0) return idx;
      await sky.click({ app, element_index: findCmdTab(s.text) });
      await sleep(350);
    }
    throw new Error("searchIdx timeout after 指令 Tab");
  };

  // canvas 失焦：点「编排区」Tab + Escape。**禁止**点「调试」按钮（会打开调试面板）
  const defocusCanvas = async () => {
    const s = await sky.get_app_state({ app, disableDiff: true });
    const orch =
      linesOf(s).find(l => axHasLabel(l, "编排区") && l.includes("按钮")) ||
      linesOf(s).find(l => /按钮/.test(l) && l.includes("编排区"));
    const idx = orch ? parseInt(orch.match(/^\s*(\d+)/)?.[1]) : null;
    if (idx != null) {
      await sky.click({ app, element_index: idx });
      await sleep(200);
    }
    await sky.press_key({ app, key: "Escape" });
    await sleep(300);
  };

  // canvas 节点行：AX 可能是 text 或 文本
  const findCanvasNode = (text, keyword) =>
    text.split("\n").find(l =>
      l.includes(keyword) && /^\s*\d+\s+(text|文本)/.test(l.replace(/\t/g, " "))
    );

  const listCanvasNodes = (text) =>
    text.split("\n").filter(l =>
      /^\s*\d+\s+(text|文本)/.test(l.replace(/\t/g, " ")) &&
      /开始|打开|输入|bilibili|点击|刷新|结束|url|selectorId/.test(l) &&
      !/开始时间|失败节点|小助手|Placeholder/.test(l)
    );

  const dblclickWebResult = async (platformRe) => {
    const s = await sky.get_app_state({ app, disableDiff: true });
    const lines = linesOf(s);
    for (let i = 0; i < lines.length; i++) {
      if (!platformRe.test(lines[i])) continue;
      const above = lines.slice(Math.max(0, i - 5), i).join("\n");
      if (/网页自动化/.test(above) && !/我的收藏/.test(above)) {
        const rIdx = parseInt(lines[i].match(/^\s*(\d+)/)[1]);
        await sky.click({ app, element_index: rIdx, click_count: 2 });
        await sleep(1200);
        return rIdx;
      }
    }
    throw new Error("web result not found: " + platformRe);
  };

  // 「刷新网页」等指令在 AX 中常无 (web) 后缀，仅「文本 刷新网页」+ 上方「网页自动化」
  const dblclickWebResultLoose = async (name) => {
    const re = new RegExp(`(?:text|文本)\\s+${name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`);
    return dblclickWebResult(re);
  };

  // 顺序错乱首选：剪切错位节点 → 锚点 Enter 空行 → 粘贴（配置保留）
  const reorderNodeCutPaste = async (moveKeyword, afterKeyword) => {
    await defocusCanvas();
    const s0 = await sky.get_app_state({ app, disableDiff: true });
    const moveNode = findCanvasNode(s0.text, moveKeyword);
    const afterNode = findCanvasNode(s0.text, afterKeyword);
    if (!moveNode || !afterNode) throw new Error(`reorder: move=${moveKeyword} after=${afterKeyword}`);
    await sky.click({ app, element_index: parseInt(moveNode.match(/^\s*(\d+)/)[1]) });
    await sleep(300);
    await sky.press_key({ app, key: "cmd+x" });
    await sleep(500);
    await sky.click({ app, element_index: parseInt(afterNode.match(/^\s*(\d+)/)[1]) });
    await sleep(300);
    await sky.press_key({ app, key: "Return" });
    await sleep(400);
    await sky.press_key({ app, key: "cmd+v" });
    await sleep(800);
  };

  // canvas 摘要仍含 selectorId：双击节点 → configLLMScoped → 保存
  const fixClickNodeLLM = async () => {
    await defocusCanvas();
    const s0 = await sky.get_app_state({ app, disableDiff: true });
    const bad = findCanvasNode(s0.text, "selectorId");
    if (!bad) return { fixed: false, reason: "no selectorId node" };
    await sky.click({ app, element_index: parseInt(bad.match(/^\s*(\d+)/)[1]), click_count: 2 });
    await sleep(1500);
    const llm = await configLLMScoped();
    if (!llm.ok) throw new Error("LLM confirm failed: " + JSON.stringify(llm));
    await saveDialog();
    const s1 = await sky.get_app_state({ app, disableDiff: true });
    const line = findCanvasNode(s1.text, "点击");
    return { fixed: true, stillSelectorId: /selectorId/.test(line || ""), summary: line?.trim() };
  };

  // 锚点 → Enter → 搜索 → 双击 (web)
  const insertAfterAnchor = async (anchorKeyword, searchName, platformRe) => {
    await defocusCanvas();
    const s0 = await sky.get_app_state({ app, disableDiff: true });
    const anchor = findCanvasNode(s0.text, anchorKeyword);
    if (!anchor) throw new Error(`anchor not found: ${anchorKeyword}`);
    const aIdx = mustIdx(parseInt(anchor.match(/^\s*(\d+)/)?.[1]), "anchor");
    await sky.click({ app, element_index: aIdx });
    await sleep(300);
    await sky.press_key({ app, key: "Return" });
    await sleep(400);
    const searchIdx = await waitSearchIdx();
    await sky.set_value({ app, element_index: searchIdx, value: searchName });
    await sleep(500);
    const rIdx = await dblclickWebResult(platformRe);
    return { aIdx, searchIdx, rIdx };
  };

  const saveDialog = async () => {
    const s = await sky.get_app_state({ app, disableDiff: true });
    const saveIdx = axButtonIdx(linesOf(s), "保存");
    mustIdx(saveIdx, "save");
    await sky.click({ app, element_index: saveIdx });
    await sleep(1500);
    await defocusCanvas();
  };

  // LLM 确认必须在「LLM动态定位」slice 内找「确 认」，禁止全局第一个确认按钮
  const configLLMScoped = async (naturalLangDesc) => {
    const s0 = await sky.get_app_state({ app, disableDiff: true });
    const llmBtn = linesOf(s0).find(l => /新建 LLM/.test(l) && l.includes("按钮"));
    mustIdx(parseInt(llmBtn.match(/^\s*(\d+)/)?.[1]), "llmBtn");
    await sky.click({ app, element_index: parseInt(llmBtn.match(/^\s*(\d+)/)[1]) });
    await sleep(800);
    const s1 = await sky.get_app_state({ app, disableDiff: true });
    const lines1 = linesOf(s1);
    const llmStart = lines1.findIndex(l => /LLM动态定位/.test(l));
    if (llmStart < 0) throw new Error("LLM tab not open");
    const descField = lines1.slice(llmStart, llmStart + 12).find(l => /文本输入区 \(settable\)/.test(l));
    const descIdx = mustIdx(parseInt(descField.match(/^\s*(\d+)/)?.[1]), "desc");
    await sky.click({ app, element_index: descIdx });
    await sleep(200);
    // 描述已在 Shell pbcopy；此处 Cmd+V
    await sky.press_key({ app, key: "cmd+a" });
    await sky.press_key({ app, key: "cmd+v" });
    await sleep(400);
    const s2 = await sky.get_app_state({ app, disableDiff: true });
    const lines2 = linesOf(s2);
    const start2 = lines2.findIndex(l => /LLM动态定位/.test(l));
    const confirmBtn = lines2.slice(start2, start2 + 20).find(l => l.includes("按钮") && axHasLabel(l, "确认"));
    const confirmIdx = mustIdx(parseInt(confirmBtn.match(/^\s*(\d+)/)?.[1]), "confirmScoped");
    await sky.click({ app, element_index: confirmIdx });
    await sleep(800);
    const s3 = await sky.get_app_state({ app, disableDiff: true });
    const selStart = linesOf(s3).findIndex(l => /text\s+\*\s+元素选择器/.test(l));
    const selSlice = selStart >= 0 ? linesOf(s3).slice(selStart, selStart + 15).join("\n") : "";
    const ok = /LLM/.test(selSlice) && !/该字段是必填字段/.test(selSlice);
    return { confirmIdx, ok, selSlicePreview: selSlice.slice(0, 120) };
  };

  const fillAsciiField = async (labelRe, value) => {
    const s0 = await sky.get_app_state({ app, disableDiff: true });
    const lines = linesOf(s0);
    const labelIdx = lines.findIndex(l => labelRe.test(l));
    const field = lines.slice(labelIdx, labelIdx + 8).find(l => /文本输入区 \(settable\)|文本栏 \(settable\)/.test(l));
    const fIdx = mustIdx(parseInt(field.match(/^\s*(\d+)/)?.[1]), "field");
    await sky.click({ app, element_index: fIdx });
    await sleep(200);
    if (/^[ -~]+$/.test(value)) {
      await sky.type_text({ app, text: value });
    } else {
      await sky.press_key({ app, key: "cmd+a" });
      await sky.press_key({ app, key: "cmd+v" });
    }
    await sleep(300);
  };

  nodeRepl.write(JSON.stringify({ step: "runtime-ready", app }));
}
```

## 单条 Web 指令标准 exec 模板

> **Shell 前置**（URL / LLM 描述 / XPath）：`printf '%s' '…' | /usr/bin/pbcopy`

```js
{
  // … 复制上方 Helper 包 …
  const app = "com.google.Chrome";
  await sky.get_app_state({ app, disableDiff: true });

  // 示例：在第 1 条「打开网页」之后插入「输入文本」
  const { aIdx, rIdx } = await insertAfterAnchor(
    "打开网页",
    "输入文本",
    /text\s+输入文本\s*\(web\)/
  );

  await configLLMScoped("定位 Bilibili 首页顶部导航栏中间偏上的搜索输入框，用于输入搜索关键词");
  await fillAsciiField(/text\s+\*\s+待填充文本/, "bilibili");
  await saveDialog();

  const s = await sky.get_app_state({ app, disableDiff: true });
  const onCanvas = /元素中输入 bilibili|输入文本/.test(s.text);
  nodeRepl.write(JSON.stringify({ step: "filltext-done", aIdx, rIdx, onCanvas, strategy: "ax:insert+llm+type" }));
}
```

## 等待时间表（优化后）

| 动作 | 等待 | 验证 |
|------|------|------|
| canvas 单击 / Enter | 300–400ms | 锚点/空行仍在 |
| 指令 Tab + 搜索框 | `waitSearchIdx()` | `请输入` 出现 |
| set_value 搜索词 | 500–800ms | 网页自动化分组下出现结果行 |
| 双击搜索结果 | 1200ms | 配置弹框信号；「刷新网页」可无 `(web)` 后缀 |
| 剪切调序 Cmd+X/V | 500–800ms | canvas 顺序符合场景表 |
| LLM 确认 | 800ms | 选择器 slice 含 `LLM` |
| ASCII 待填充文本 | `type_text` + 300ms | slice 含目标文本 |
| 保存 | 1500ms | 弹框关闭 / canvas 摘要更新 |
| 页面导航（仅平台入口） | 2000ms | URL 含目标路径 |

## 准确率铁律

1. **保存前**：弹框 slice 必含已填值；`canSave === false` 禁止点保存（`ax-verify.md` §assertCanSave）。
2. **保存后**：读 canvas 节点摘要行（如 `打开网页 url:`、`元素中输入 bilibili`），**不对**则当场重开弹框，禁止继续插下一条。
3. **LLM「确认」**：只用 `configLLMScoped` slice 内按钮；全局 `确 认`（如 idx 61）会误关其他弹层。
4. **顺序**：插入后 canvas 序列必须 `锚点 < 新节点 < 结束`；错乱 → 剪切粘贴（`insert-command.md` §右键菜单），**禁止**带错顺序继续配表。
5. **canvas 污染**：同指令失败 2 次 → **Delete 错节点** 或 **新建工作流**，不要在脏 canvas 上堆节点。
6. **禁止用「调试」失焦**：`defocusCanvas` 只点「编排区」+ Escape；点「调试」会开面板并在聊天区留失败日志。
7. **聊天区历史**：早先误调试的失败条目会残留；判 PASS 只看**最新一轮**各步骤 `check-circle` 与时间戳。

## B 站四步黄金路径（实测 · 2026-08-22）

> 默认场景完整参数见 `scenarios/bilibili.md` §实测黄金路径。配置阶段**零次**点「调试」。

| Exec # | Shell 前置 pbcopy | 动作 | canvas 摘要验证 |
|--------|-------------------|------|----------------|
| 1 | `https://www.bilibili.com` | 开始 → 插入「打开网页」→ 弹框 paste 网址 → 保存 | `打开网页 url: https://www.bilibili.com` |
| 2 | 搜索框 LLM 描述 | 锚点 `bilibili.com` → 插入「输入文本」→ LLM + `type_text bilibili` → 保存 | `元素中输入 bilibili` |
| 3 | 搜索按钮 LLM 描述 | 锚点 `元素中输入 bilibili` → 插入「点击」→ LLM → 保存 | `点击 页面`（非 `selectorId`） |
| 4 | — | 锚点 `点击 页面` → 搜「刷新网页」→ `dblclickWebResultLoose("刷新网页")` → 保存 | `刷新网页` |
| 5 | — | 顺序终检 + 点一次「检查」 | 无「节点配置不完整」 |
| 6 | — | **唯一一次**「调试 → 运行」→ 等 `check-circle` | 4 步均 ✅ |

**顺序错乱实测修复**（如「点击」排在「输入文本」前）：`reorderNodeCutPaste("点击", "元素中输入 bilibili")` 或 `reorderNodeCutPaste("元素中输入 bilibili", "bilibili.com")`。

**platformRe 参考**：

| 指令 | 搜索框 | dblclick 匹配 |
|------|--------|--------------|
| 打开网页 | `打开网页` | `/text\s+打开网页\s*\(web\)/` |
| 输入文本 | `输入文本` | `/text\s+输入文本\s*\(web\)/` |
| 点击 | `点击` | `/点击\s*\(web\)\|点击元素\s*\(web\)/` |
| 刷新网页 | `刷新网页` | **`dblclickWebResultLoose("刷新网页")`**（无 `(web)`） |

## 一次性调试（终检后唯一允许点「调试」）

```js
{
  // … Helper 包 …
  const debugRunOnce = async () => {
    let s = await sky.get_app_state({ app, disableDiff: true });
    let lines = linesOf(s);
    const disc = lines.find(l => /断开/.test(l) && l.includes("按钮") && !/disabled/.test(l));
    if (disc) {
      await sky.click({ app, element_index: parseInt(disc.match(/^\s*(\d+)/)[1]) });
      await sleep(3000);
    }
    s = await sky.get_app_state({ app, disableDiff: true });
    lines = linesOf(s);
    const debugIdx = axButtonIdx(lines, "调试");
    if (debugIdx == null) throw new Error("debug disabled — wait or disconnect");
    await sky.click({ app, element_index: debugIdx });
    await sleep(2000);
    s = await sky.get_app_state({ app, disableDiff: true });
    const runIdx = axButtonIdx(linesOf(s), "运行");
    if (runIdx == null) throw new Error("run btn missing");
    await sky.click({ app, element_index: runIdx });
    for (let i = 0; i < 12; i++) {
      await sleep(10000);
      s = await sky.get_app_state({ app, disableDiff: true });
      if (!/调试中/.test(s.text)) break;
    }
    const tail = linesOf(s).filter(l => /check-circle|失败节点|小助手出错了/.test(l)).slice(-12);
    nodeRepl.write(JSON.stringify({ step: "debug-run-once", tail }));
  };
  await debugRunOnce();
}
```

## cgWindowNotFound 恢复顺序

```
1. Shell ensureChrome（本节 §执行前）
2. 若仍失败：AppleScript 设工作流 URL + sleep 5
3. 若仍失败：daemon.sh stop && daemon.sh start → nodeRepl.write("ok")
4. 禁止在未恢复时连发多个 exec
```

详见 `debug.md` §Chrome 报 cgWindowNotFound。

## 与其他模块关系

| 模块 | 使用本运行时 |
|------|-------------|
| `insert-command.md` | `waitSearchIdx` / `insertAfterAnchor` / `dblclickWebResult` |
| `element-selector.md` | `configLLMScoped` |
| `url-input.md` | Shell pbcopy + scoped paste（弹框字段 idx 仍用 url-input 的 findModalUrlFieldIdx） |
| `test-workflow.md` | exec 批次策略、延迟「检查」、一次性调试 |
| `debug.md` | `debugRunOnce`、断开重试、聊天区历史判读 |
| `platform-ops.md` | 新建工作流 sky 脚本、defocusCanvas（编排区，禁止调试） |
