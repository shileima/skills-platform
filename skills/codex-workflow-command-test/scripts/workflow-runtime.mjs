/**
 * Bots 工作流指令测试 — sky 共享运行时。
 * 通过 cua-router /exec 注入的 sky.* 执行自动化步骤。
 */
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/** @param {unknown} payload */
export function emitResult(payload) {
  const text = typeof payload === "string" ? payload : JSON.stringify(payload);
  if (globalThis.nodeRepl && typeof globalThis.nodeRepl.write === "function") {
    globalThis.nodeRepl.write(text);
    return;
  }
  console.log(text);
}

/**
 * @param {Record<string, (...args: any[]) => Promise<any>>} sky
 */
export function createWorkflowRuntime(sky) {
  const app = "com.google.Chrome";
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

  const mustIdx = (n, label) => {
    if (!Number.isInteger(n) || n < 0) throw new Error(`${label} invalid: ${n}`);
    return n;
  };

  /**
   * 安全点击：封装 sky.click，在遇到 `coordinate must include finite x and y coordinates`
   * 时不抛错中断整个 exec 步骤，而是返回结构化降级结果。
   *
   * 根因：该错误通常因为 AX 节点存在但无 AXPosition/AXSize（Electron 虚拟列表、
   * React Flow canvas 节点、隐藏/折叠元素），或 element_index 解析为 NaN。
   * 此时需要走 AX → OCR → 坐标扫描三级降级（见 ax-verify.md §三级定位）。
   *
   * @param {{ element_index?: number, click_count?: number, coordinate?: { x: number, y: number } }} opts
   * @param {{ label?: string, ocrCandidates?: Array<{x:number,y:number}>, coordCandidates?: Array<{x:number,y:number}> }} [meta]
   * @returns {Promise<{ ok: boolean, strategy: string, successAttempt?: string, successX?: number, successY?: number, error?: string, attempts?: string[] }>}
   */
  const safeClick = async (opts, meta = {}) => {
    const { label = "element", ocrCandidates = [], coordCandidates = [] } = meta;
    const attempts = [];

    // 策略 1：AX element_index 点击
    if (opts.element_index != null && Number.isFinite(opts.element_index)) {
      attempts.push(`ax:${label}@idx:${opts.element_index}`);
      try {
        await sky.click({ app, ...opts });
        return { ok: true, strategy: "ax", successAttempt: attempts[attempts.length - 1], attempts };
      } catch (e) {
        const msg = String(e?.message || e);
        // coordinate must include finite x and y coordinates → AX 节点无几何框，降级
        if (!/coordinate must include finite|finite x and y/i.test(msg)) {
          // 其它错误直接抛出，不降级
          throw e;
        }
        attempts.push(`ax-failed:${msg.slice(0, 60)}`);
      }
    }

    // 策略 2：OCR 坐标点击（候选坐标由调用方提供，通常来自截图识别）
    for (const c of ocrCandidates) {
      const tag = `ocr:${label}@${c.x},${c.y}`;
      attempts.push(tag);
      try {
        await sky.click({ app, coordinate: { x: c.x, y: c.y }, click_count: opts.click_count });
        return { ok: true, strategy: "ocr", successAttempt: tag, successX: c.x, successY: c.y, attempts };
      } catch (e) {
        attempts.push(`ocr-failed:${String(e?.message || e).slice(0, 60)}`);
      }
    }

    // 策略 3：固定坐标扫描
    for (const c of coordCandidates) {
      const tag = `coord-scan:${label}@${c.x},${c.y}`;
      attempts.push(tag);
      try {
        await sky.click({ app, coordinate: { x: c.x, y: c.y }, click_count: opts.click_count });
        return { ok: true, strategy: "coord-scan", successAttempt: tag, successX: c.x, successY: c.y, attempts };
      } catch (e) {
        attempts.push(`coord-failed:${String(e?.message || e).slice(0, 60)}`);
      }
    }

    return { ok: false, strategy: "failed", error: `safeClick exhausted all strategies for ${label}`, attempts };
  };

  const linesOf = (s) => s.text.split("\n");

  const findAllIdx = (text, sub) => {
    const out = [];
    text.split("\n").forEach((line) => {
      if (line.includes(sub)) out.push({ idx: parseInt(line.match(/^\s*(\d+)/)?.[1], 10), line });
    });
    return out;
  };

  const findIdx = (text, sub) => {
    const h = findAllIdx(text, sub);
    return h.length ? h[0].idx : -1;
  };

  const axHasLabel = (line, label) => new RegExp(label.split("").join("\\s*")).test(line);

  /** 按钮无障碍名称：去空白。「  26 按钮 调 试」→「调试」；无名齿轮 → "" */
  const axButtonAccessibleName = (line) => {
    const m = String(line)
      .replace(/\t/g, " ")
      .match(/^\s*\d+\s+按钮\s*(.*)$/);
    return (m ? m[1] : "").replace(/\s+/g, "").replace(/,.*$/, "").trim();
  };

  /**
   * 精确匹配按钮名称（去空白后全等）。
   * 禁止用「运行」启动调试：那会命中顶部「运行」或其右侧无名「运行配置」齿轮。
   */
  const axButtonIdx = (lines, label) => {
    const target = String(label).replace(/\s+/g, "");
    const line = lines.find((l) => {
      if (!l.includes("按钮") || /disabled/.test(l)) return false;
      return axButtonAccessibleName(l) === target;
    });
    return line ? parseInt(line.match(/^\s*(\d+)/)?.[1], 10) : null;
  };

  const isRunConfigOpen = (text) =>
    /运行配置/.test(text) && (/仅保存/.test(text) || /保存并运行/.test(text) || /hook事件/.test(text));

  const isDebugPanelOpen = (text) => /随机设备/.test(text) || /选择我的浏览器环境/.test(text);

  const closeRunConfigIfOpen = async () => {
    let s = await sky.get_app_state({ app, disableDiff: true });
    if (!isRunConfigOpen(s.text)) return { closed: false, stillOpen: false };
    await sky.press_key({ app, key: "Escape" });
    await sleep(400);
    s = await sky.get_app_state({ app, disableDiff: true });
    if (isRunConfigOpen(s.text)) {
      const closeBtn = linesOf(s).find((l) => /关闭/.test(l) && l.includes("按钮") && !/disabled/.test(l));
      if (closeBtn) {
        await safeClick(
          { element_index: parseInt(closeBtn.match(/^\s*(\d+)/)[1], 10) },
          { label: "关闭运行配置" },
        );
        await sleep(400);
        s = await sky.get_app_state({ app, disableDiff: true });
      }
    }
    return { closed: true, stillOpen: isRunConfigOpen(s.text) };
  };

  /** 调试弹框内的橙色「运行」：只在「随机设备」切片里精确匹配，禁止 axButtonIdx("运行") */
  const debugPanelRunIdx = (lines) => {
    const start = lines.findIndex((l) => /随机设备|选择我的浏览器环境/.test(l));
    if (start < 0) return null;
    const line = lines.slice(start).find((l) => {
      if (!l.includes("按钮") || /disabled/.test(l)) return false;
      return axButtonAccessibleName(l) === "运行";
    });
    return line ? parseInt(line.match(/^\s*(\d+)/)?.[1], 10) : null;
  };

  const findCmdTab = (text) =>
    mustIdx(
      findAllIdx(text, "文本 指令").find((m) =>
        /^\s*\d+\s+文本\s+指令\s*$/.test(m.line.replace(/\t/g, " ").trim()),
      )?.idx,
      "cmdTab",
    );

  const findSearchIdx = (text) => {
    let idx = findIdx(text, "Placeholder: 请输入");
    if (idx >= 0) return idx;
    const hit = findAllIdx(text, "文本栏").find(
      (m) => /请输入/.test(m.line) && !/地址|编辑器|环境|发送/.test(m.line),
    );
    return hit?.idx ?? -1;
  };

  const waitSearchIdx = async () => {
    for (let i = 0; i < 6; i++) {
      const s = await sky.get_app_state({ app, disableDiff: true });
      const idx = findSearchIdx(s.text);
      if (idx >= 0) return idx;
      const tabRes = await safeClick({ element_index: findCmdTab(s.text) }, { label: "cmdTab" });
      await sleep(350);
    }
    throw new Error("searchIdx timeout after 指令 Tab");
  };

  const defocusCanvas = async () => {
    const s = await sky.get_app_state({ app, disableDiff: true });
    const orch =
      linesOf(s).find((l) => axHasLabel(l, "编排区") && l.includes("按钮")) ||
      linesOf(s).find((l) => /按钮/.test(l) && l.includes("编排区"));
    const idx = orch ? parseInt(orch.match(/^\s*(\d+)/)?.[1], 10) : null;
    if (idx != null && Number.isFinite(idx)) {
      // safeClick 降级：编排区按钮偶发无 AXPosition
      const r = await safeClick({ element_index: idx }, { label: "编排区" });
      if (!r.ok) {
        // 降级失败也不中断——Escape 仍可执行
      }
      await sleep(200);
    }
    await sky.press_key({ app, key: "Escape" });
    await sleep(300);
  };

  const findCanvasNode = (text, keyword) =>
    text.split("\n").find(
      (l) => l.includes(keyword) && /^\s*\d+\s+(text|文本)/.test(l.replace(/\t/g, " ")),
    );

  const listCanvasNodes = (text) =>
    text.split("\n").filter(
      (l) =>
        /^\s*\d+\s+(text|文本)/.test(l.replace(/\t/g, " ")) &&
        /开始|打开|输入|bilibili|点击|刷新|结束|url|selectorId/.test(l) &&
        !/开始时间|失败节点|小助手|Placeholder/.test(l),
    );

  const dblclickWebResult = async (platformRe) => {
    const s = await sky.get_app_state({ app, disableDiff: true });
    const lines = linesOf(s);
    for (let i = 0; i < lines.length; i++) {
      if (!platformRe.test(lines[i])) continue;
      const above = lines.slice(Math.max(0, i - 5), i).join("\n");
      if (/网页自动化/.test(above) && !/我的收藏/.test(above)) {
        const rIdx = parseInt(lines[i].match(/^\s*(\d+)/)[1], 10);
        // safeClick 降级：搜索结果行在虚拟列表中可能无几何框
        const r = await safeClick(
          { element_index: rIdx, click_count: 2 },
          { label: `web-result:${platformRe}` }
        );
        if (!r.ok) throw new Error(`dblclickWebResult failed: ${r.error} attempts=${JSON.stringify(r.attempts)}`);
        await sleep(1200);
        return { rIdx, ...r };
      }
    }
    throw new Error(`web result not found: ${platformRe}`);
  };

  const dblclickWebResultLoose = async (name) => {
    const re = new RegExp(`(?:text|文本)\\s+${name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`);
    return dblclickWebResult(re);
  };

  const reorderNodeCutPaste = async (moveKeyword, afterKeyword) => {
    await defocusCanvas();
    const s0 = await sky.get_app_state({ app, disableDiff: true });
    const moveNode = findCanvasNode(s0.text, moveKeyword);
    const afterNode = findCanvasNode(s0.text, afterKeyword);
    if (!moveNode || !afterNode) throw new Error(`reorder: move=${moveKeyword} after=${afterKeyword}`);
    const moveRes = await safeClick(
      { element_index: parseInt(moveNode.match(/^\s*(\d+)/)[1], 10) },
      { label: `reorder:move:${moveKeyword}` },
    );
    if (!moveRes.ok) throw new Error(`reorderNodeCutPaste: move click failed: ${moveRes.error}`);
    await sleep(300);
    await sky.press_key({ app, key: "cmd+x" });
    await sleep(500);
    const afterRes = await safeClick(
      { element_index: parseInt(afterNode.match(/^\s*(\d+)/)[1], 10) },
      { label: `reorder:after:${afterKeyword}` },
    );
    if (!afterRes.ok) throw new Error(`reorderNodeCutPaste: after click failed: ${afterRes.error}`);
    await sleep(300);
    await sky.press_key({ app, key: "Return" });
    await sleep(400);
    await sky.press_key({ app, key: "cmd+v" });
    await sleep(800);
  };

  const saveDialog = async () => {
    const s = await sky.get_app_state({ app, disableDiff: true });
    const saveIdx = axButtonIdx(linesOf(s), "保存");
    mustIdx(saveIdx, "save");
    const saveRes = await safeClick({ element_index: saveIdx }, { label: "保存" });
    if (!saveRes.ok) throw new Error(`saveDialog: save click failed: ${saveRes.error}`);
    await sleep(1500);
    await defocusCanvas();
  };

  const configLLMScoped = async () => {
    const s0 = await sky.get_app_state({ app, disableDiff: true });
    const llmBtn = linesOf(s0).find((l) => /新建 LLM/.test(l) && l.includes("按钮"));
    mustIdx(parseInt(llmBtn.match(/^\s*(\d+)/)?.[1], 10), "llmBtn");
    const llmRes = await safeClick(
      { element_index: parseInt(llmBtn.match(/^\s*(\d+)/)[1], 10) },
      { label: "新建LLM" },
    );
    if (!llmRes.ok) throw new Error(`configLLMScoped: llmBtn click failed: ${llmRes.error}`);
    await sleep(800);
    const s1 = await sky.get_app_state({ app, disableDiff: true });
    const lines1 = linesOf(s1);
    const llmStart = lines1.findIndex((l) => /LLM动态定位/.test(l));
    if (llmStart < 0) throw new Error("LLM tab not open");
    const descField = lines1.slice(llmStart, llmStart + 12).find((l) => /文本输入区 \(settable\)/.test(l));
    const descIdx = mustIdx(parseInt(descField.match(/^\s*(\d+)/)?.[1], 10), "desc");
    const descRes = await safeClick({ element_index: descIdx }, { label: "descField" });
    if (!descRes.ok) throw new Error(`configLLMScoped: desc click failed: ${descRes.error}`);
    await sleep(200);
    await sky.press_key({ app, key: "cmd+a" });
    await sky.press_key({ app, key: "cmd+v" });
    await sleep(400);
    const s2 = await sky.get_app_state({ app, disableDiff: true });
    const lines2 = linesOf(s2);
    const start2 = lines2.findIndex((l) => /LLM动态定位/.test(l));
    const confirmBtn = lines2.slice(start2, start2 + 20).find((l) => l.includes("按钮") && axHasLabel(l, "确认"));
    const confirmIdx = mustIdx(parseInt(confirmBtn.match(/^\s*(\d+)/)?.[1], 10), "confirmScoped");
    const confirmRes = await safeClick({ element_index: confirmIdx }, { label: "确认LLM" });
    if (!confirmRes.ok) throw new Error(`configLLMScoped: confirm click failed: ${confirmRes.error}`);
    await sleep(800);
    const s3 = await sky.get_app_state({ app, disableDiff: true });
    const selStart = linesOf(s3).findIndex((l) => /text\s+\*\s+元素选择器/.test(l));
    const selSlice = selStart >= 0 ? linesOf(s3).slice(selStart, selStart + 15).join("\n") : "";
    const ok = /LLM/.test(selSlice) && !/该字段是必填字段/.test(selSlice);
    return { confirmIdx, ok, selSlicePreview: selSlice.slice(0, 120) };
  };

  const fillAsciiField = async (labelRe, value) => {
    const s0 = await sky.get_app_state({ app, disableDiff: true });
    const lines = linesOf(s0);
    const labelIdx = lines.findIndex((l) => labelRe.test(l));
    const field = lines
      .slice(labelIdx, labelIdx + 8)
      .find((l) => /文本输入区 \(settable\)|文本栏 \(settable\)/.test(l));
    const fIdx = mustIdx(parseInt(field.match(/^\s*(\d+)/)?.[1], 10), "field");
    const fieldRes = await safeClick({ element_index: fIdx }, { label: `field:${labelRe}` });
    if (!fieldRes.ok) throw new Error(`fillAsciiField: field click failed: ${fieldRes.error}`);
    await sleep(200);
    if (/^[ -~]+$/.test(value)) {
      await sky.type_text({ app, text: value });
    } else {
      await sky.press_key({ app, key: "cmd+a" });
      await sky.press_key({ app, key: "cmd+v" });
    }
    await sleep(300);
  };

  const fixClickNodeLLM = async () => {
    await defocusCanvas();
    const s0 = await sky.get_app_state({ app, disableDiff: true });
    const bad = findCanvasNode(s0.text, "selectorId");
    if (!bad) return { fixed: false, reason: "no selectorId node" };
    const badRes = await safeClick(
      { element_index: parseInt(bad.match(/^\s*(\d+)/)[1], 10), click_count: 2 },
      { label: "fixClickNode:selectorId" },
    );
    if (!badRes.ok) throw new Error(`fixClickNodeLLM: bad node click failed: ${badRes.error}`);
    await sleep(1500);
    const llm = await configLLMScoped();
    if (!llm.ok) throw new Error(`LLM confirm failed: ${JSON.stringify(llm)}`);
    await saveDialog();
    const s1 = await sky.get_app_state({ app, disableDiff: true });
    const line = findCanvasNode(s1.text, "点击");
    return { fixed: true, stillSelectorId: /selectorId/.test(line || ""), summary: line?.trim() };
  };

  const insertAfterAnchor = async (anchorKeyword, searchName, platformRe) => {
    await defocusCanvas();
    const s0 = await sky.get_app_state({ app, disableDiff: true });
    const anchor = findCanvasNode(s0.text, anchorKeyword);
    if (!anchor) throw new Error(`anchor not found: ${anchorKeyword}`);
    const aIdx = mustIdx(parseInt(anchor.match(/^\s*(\d+)/)?.[1], 10), "anchor");
    // safeClick 降级：canvas 内 React Flow 节点可能无 AXPosition
    const clickRes = await safeClick({ element_index: aIdx }, { label: `anchor:${anchorKeyword}` });
    if (!clickRes.ok) throw new Error(`insertAfterAnchor: anchor click failed: ${clickRes.error}`);
    await sleep(300);
    await sky.press_key({ app, key: "Return" });
    await sleep(400);
    const searchIdx = await waitSearchIdx();
    await sky.set_value({ app, element_index: searchIdx, value: searchName });
    await sleep(500);
    const rIdx = await dblclickWebResult(platformRe);
    return { aIdx, searchIdx, rIdx, clickStrategy: clickRes.strategy };
  };

  const debugRunOnce = async () => {
    await closeRunConfigIfOpen();
    let s = await sky.get_app_state({ app, disableDiff: true });
    let lines = linesOf(s);
    const disc = lines.find((l) => /断开/.test(l) && l.includes("按钮") && !/disabled/.test(l));
    if (disc) {
      const discIdx = parseInt(disc.match(/^\s*(\d+)/)[1], 10);
      await safeClick({ element_index: discIdx }, { label: "断开" });
      await sleep(3000);
    }

    let debugRes = null;
    let debugIdx = null;
    for (let attempt = 0; attempt < 3; attempt++) {
      await closeRunConfigIfOpen();
      s = await sky.get_app_state({ app, disableDiff: true });
      lines = linesOf(s);
      // 只点顶部「调试」。禁止 axButtonIdx("运行")、禁止点「运行」右侧无名齿轮。
      debugIdx = axButtonIdx(lines, "调试");
      if (debugIdx == null) throw new Error("debug disabled — wait or disconnect");
      debugRes = await safeClick({ element_index: debugIdx }, { label: "调试" });
      if (!debugRes.ok) throw new Error(`debugRunOnce: debug click failed: ${debugRes.error}`);
      await sleep(1200);
      s = await sky.get_app_state({ app, disableDiff: true });
      if (isRunConfigOpen(s.text)) {
        await closeRunConfigIfOpen();
        continue;
      }
      if (isDebugPanelOpen(s.text)) break;
      await sleep(800);
      s = await sky.get_app_state({ app, disableDiff: true });
      if (isDebugPanelOpen(s.text)) break;
    }
    if (isRunConfigOpen(s.text)) {
      throw new Error("clicked 运行配置 instead of 调试 — close dialog and retry axButtonIdx(调试)");
    }
    if (!isDebugPanelOpen(s.text)) throw new Error("debug panel missing after 调试");

    const runIdx = debugPanelRunIdx(linesOf(s));
    if (runIdx == null) throw new Error("debug-panel run btn missing (do not use toolbar 运行)");
    const runRes = await safeClick({ element_index: runIdx }, { label: "调试弹框-运行" });
    if (!runRes.ok) throw new Error(`debugRunOnce: panel run click failed: ${runRes.error}`);
    for (let i = 0; i < 12; i++) {
      await sleep(10000);
      s = await sky.get_app_state({ app, disableDiff: true });
      if (!/调试中/.test(s.text)) break;
    }
    const tail = linesOf(s).filter((l) => /check-circle|失败节点|小助手出错了/.test(l)).slice(-12);
    return {
      step: "debug-run-once",
      debugIdx,
      tail,
      debugStrategy: debugRes?.strategy,
      runStrategy: runRes.strategy,
    };
  };

  const axRequiredFieldSlice = (lines, label) => {
    const labelIdx = lines.findIndex(
      (l) => (l.includes(`* ${label}`) || l.includes(`*${label}`)) && /text|静态文本|标签/i.test(l),
    );
    if (labelIdx < 0) return [];
    return lines.slice(labelIdx, labelIdx + 15);
  };

  const axFieldSliceLooksEmpty = (sliceText) =>
    /输入.*插入上游节点变量/.test(sliceText) ||
    /placeholder|占位/.test(sliceText) ||
    (/settable|textfield|文本栏/i.test(sliceText) &&
      !/value:\s*\S/.test(sliceText) &&
      !/https?:\/\//.test(sliceText));

  const assertCanSave = (lines, requiredLabels, validators = {}) => {
    const hasRequiredErr = lines.some((l) => l.includes("该字段是必填字段"));
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
        : !emptyLike &&
          (/value:\s*\S/.test(sliceText) ||
            /\/\/\S/.test(sliceText) ||
            /text\s+[^\s].{2,}/.test(sliceText));
      if (!customOk || emptyLike) {
        missing.push(label);
        details[label] = { ok: false, emptyLike, slicePreview: sliceText.slice(0, 120) };
      } else {
        details[label] = { ok: true };
      }
    }

    const canSave = !hasRequiredErr && missing.length === 0;
    return { canSave, missing, hasRequiredErr, details };
  };

  const assertCanSaveOpenUrl = (lines) =>
    assertCanSave(lines, ["网址"], {
      网址: (t) => /https?:\/\//.test(t) && !/https\/\//.test(t) && !/输入.*插入上游节点变量/.test(t),
    });

  return {
    sky,
    app,
    sleep,
    mustIdx,
    safeClick,
    linesOf,
    findAllIdx,
    findIdx,
    axHasLabel,
    axButtonAccessibleName,
    axButtonIdx,
    isRunConfigOpen,
    isDebugPanelOpen,
    closeRunConfigIfOpen,
    debugPanelRunIdx,
    findCmdTab,
    findSearchIdx,
    waitSearchIdx,
    defocusCanvas,
    findCanvasNode,
    listCanvasNodes,
    dblclickWebResult,
    dblclickWebResultLoose,
    reorderNodeCutPaste,
    fixClickNodeLLM,
    insertAfterAnchor,
    saveDialog,
    configLLMScoped,
    fillAsciiField,
    debugRunOnce,
    axRequiredFieldSlice,
    axFieldSliceLooksEmpty,
    assertCanSave,
    assertCanSaveOpenUrl,
    emitResult,
  };
}

/**
 * 使用 cua-router /exec 注入到全局的 sky 创建工作流运行时。
 * @param {{ globals?: typeof globalThis }} [options]
 */
export function setupWorkflowRuntime(options = {}) {
  const { globals = globalThis } = options;
  if (!globals.sky) throw new Error("sky runtime unavailable; run this module through cua-router scripts/exec.sh");
  return createWorkflowRuntime(globals.sky);
}

export const WORKFLOW_RUNTIME_PATH = path.join(__dirname, "workflow-runtime.mjs");
