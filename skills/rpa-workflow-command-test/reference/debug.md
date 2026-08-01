# 调试与错误修复

> 标准测试流程见 `reference/test-workflow.md`。本节详述调试执行与报错修复。

## 配置校验三条硬规则（调试相关）

平台有两套独立警示，**不可只查左侧执行 icon**：

| # | 时机 | 检查什么 | 通过标准 |
|---|------|---------|---------|
| 1 | **每条指令保存后** | 点顶部「检查」→ 读下拉 | 无「配置异常节点」、无「节点配置不完整」；按钮无红色数字 badge |
| 2 | **点「调试」前** | 编排区每条指令**右侧** | 无红色 ⓘ /「节点配置不完整」（与左侧 ✅/❌ 无关） |
| 3 | **保存前（条件必填）** | Read `commands/<slug>.md` | 按「设置方式」等枚举核对条件必填（如 SetCookie 的 Domain/URL） |

详细步骤与 sky 脚本见 `test-workflow.md` §保存后配置校验、§调试前配置终检、§第 5 步；本节 §配置校验 sky 脚本 提供可复用片段。

## 调试前置

前置（**全部满足**方可点「调试」）：

1. 编排区全部指令已**保存成功**，弹框内必填项无红色边框、无表单校验报错；**条件必填**已按 `commands/<slug>.md` 核对（规则 3）
2. **每条保存后**已点「检查」，下拉无「节点配置不完整」（规则 1）
3. **调试前场景顺序终检已通过**：编排区指令类型与顺序与 `reference/scenarios/<场景>.md`「指令节点」表一致（见 `test-workflow.md` §调试前场景顺序终检、`ax-verify.md` §调试前场景顺序终检）
4. **调试前配置终检已通过**：编排区**右侧**无配置警示 icon；「检查」面板无异常（规则 2，见 `test-workflow.md` §调试前配置终检）

> ⚠️ 顺序终检或配置终检未通过时**禁止调试**；先修正顺序（剪切→粘贴）或补全节点配置（双击 → 保存 → 再点「检查」），再终检，再调试。

## 调试运行

### 操作步骤（无需配置弹框）

1. 点页面顶部「**调试**」按钮（打开右侧调试面板）
2. 弹框中**直接**点橙色「**运行**」——**无需修改弹框内任何表单项**
3. 等待云浏览器执行完毕

> ⚠️ **调试弹框无需配置**：「选择我的浏览器环境」默认已是「**随机设备**」，「是否开启自动断开设备」等开关保持默认即可。**禁止**在弹框里改设备、改环境或点「重置」后再运行，除非用户明确要求指定设备。

| 弹框字段 | 默认行为 | Agent 操作 |
|---------|---------|-----------|
| 选择我的浏览器环境 | **随机设备** | **不修改**，直接运行 |
| 是否开启自动断开设备 | 默认开启 | 不修改 |
| 是否开启 UI 异常处理全局配置 | 默认关闭 | 不修改 |
| 选择我的云手机环境 | 空 | 不修改（Web 场景不用） |

```js
{
  // axHasLabel / axButtonIdx 见 ax-verify.md §分析辅助函数（兼容 Ant Design「运 行」「重 置」）
  function axHasLabel(line, label) {
    return new RegExp(label.split("").join("\\s*")).test(line);
  }
  function axButtonIdx(lines, label) {
    const line = lines.find(l => axHasLabel(l, label) && l.includes("按钮"));
    return line ? parseInt(line.match(/^\s*(\d+)/)?.[1]) : null;
  }

  const s = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const lines = s.text.split("\n");
  const debugIdx = axButtonIdx(lines, "调试");
  await sky.click({ app: "com.google.Chrome", element_index: debugIdx });
  const s2 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const lines2 = s2.text.split("\n");
  const panelOpen = lines2.some(l => l.includes("随机设备") || l.includes("选择我的浏览器环境"));
  const runIdx = axButtonIdx(lines2, "运行");
  nodeRepl.write(JSON.stringify({ step: "debug-run", panelOpen, runIdx }));
  await sky.click({ app: "com.google.Chrome", element_index: runIdx });
}
```

> ⚠️ 调试结束后按钮可能变灰 → 先点「**断开**」断开设备连接，再重新调试。

## 配置校验 sky 脚本

以下脚本与 `test-workflow.md` 对应，调试流程中按需复用。

### 规则 1：保存后点「检查」读面板

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

### 规则 2：调试前编排区 + 「检查」双重扫描

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

  const configIncomplete = area.filter(l => l.includes("节点配置不完整"));
  const execErrors = area.filter(l => /close-circle|执行失败|运行失败/i.test(l));

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

### 规则 3：保存前条件必填自检（SetCookie 示例）

> 通用流程：Read `commands/<slug>.md` → 根据弹框当前「设置方式」等 Enum 值，确认对应条件字段已在 AX 中有有效 value。以下以 SetCookie 为例。

```js
{
  const s0 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const panel = s0.text.split("\n");
  const text = panel.join("\n");

  const methodUrl = /根据\s*URL\s*设置/i.test(text) || /method.*URL/i.test(text);
  const methodDomain = /根据指定\s*Domain/i.test(text) || /Domain\s*和\s*path/i.test(text);

  function fieldHasValue(label) {
    const idx = panel.findIndex(l => l.includes(label));
    if (idx === -1) return false;
    const nearby = panel.slice(idx, idx + 8).join("\n");
    return /value:\s*\S/.test(nearby) && !/value:\s*$/.test(nearby);
  }

  const missing = [];
  if (methodUrl && !fieldHasValue("URL") && !fieldHasValue("网址")) missing.push("URL");
  if (methodDomain && !fieldHasValue("Domain")) missing.push("Domain");
  if (!fieldHasValue("Name") && !fieldHasValue("CookieName")) missing.push("Name");

  const canSave = missing.length === 0;
  nodeRepl.write(JSON.stringify({
    step: "conditional-required-check",
    methodUrl,
    methodDomain,
    missing,
    canSave,
    action: canSave ? "click-save" : "fill-conditional-required-first"
  }));
}
```

## 执行后必查：四处报错来源

| 检查位置 | 看什么 | 说明 |
|---------|--------|------|
| **聊天区**（Chat / 调试输出） | 文字日志、错误码、堆栈 | 定位失败原因细节，如 FillText 10120036 |
| **编排区指令左侧 icon** | 红色 close-circle = **执行失败** | 快速定位**哪一条**指令本次调试未通过 |
| **编排区指令右侧 icon** | 红色 ⓘ「**节点配置不完整**」 | **静态配置**未满足；左侧全绿也可能仍有此警示 |
| **顶部「检查」面板** | 「配置异常节点」列表 | 与保存后规则 1 相同；修复后须再点「检查」确认 |

四处需**同时确认**。常见误判：

- 左侧全绿 ✅ 但右侧仍有 ⓘ → **配置不完整**，禁止标记通过，先双击修复
- 聊天区无错但左侧有红 → 断开后重跑，或修复执行失败项
- 「检查」仍有 badge → 以「检查」面板为准，逐项修复

### sky 自动化：执行后四处扫描

完整脚本见 `test-workflow.md` §第 5 步「sky 自动化：执行后四处扫描」（`step: "post-debug-four-way-check"`）。

## 常见环境级异常（sky 侧）

### Chrome 报 `cgWindowNotFound` / 长时间 timeout

**现象**：`sky.get_app_state` 或 `sky.click` 返回 `Computer Use server error -10005: cgWindowNotFound`；或 `/exec` 长时间 timeout。表现为 Chrome 窗口"看得见但拿不到"。

**原因**：Chrome 不是最前台进程（哪怕 Cmd+Tab 显示它可见，`System Events` 的 `frontmost` 属性可能仍是别的 App，例如 IDE、Automan Desktop）。

**修复**：

```bash
osascript -e 'tell application "Google Chrome" to activate'
osascript -e 'tell application "System Events" to set frontmost of application process "Google Chrome" to true'
sleep 2
```

之后再重试 sky 调用即可。**不要**因为 timeout 就 `daemon.sh restart`——重启 daemon 会丢掉 sky bootstrap 状态（首次 `/exec` 后会自动重 bootstrap，但期间脚本会 timeout）。只有 `nodeRepl.write("ok")` 也返回失败时才考虑 restart。

### canvas 节点显示 `selectorId 元素的...`（XPath 未落库判定）

**现象**：某"验证元素…"节点保存关闭后，canvas 上该节点第二行不是 `//*[@id="..."]` 完整 XPath，而是 `selectorId` 之类的变量名占位。

**原因**：Cmd+V 粘贴 XPath 到 AntD Select 组合框时未紧接 Enter，或粘贴时 Chrome 焦点被系统抢走（见上一节 `cgWindowNotFound`），React state 没接受粘贴文本作为 tag。

**判定脚本**：

```js
{
  const st = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const nodeTails = st.text.split("\n").filter(l => /^\s*\d+\s+text\s.*保存至\s+本节点/.test(l));
  const anyBadPlaceholder = st.text.split("\n").some(l =>
    /^\s*\d+\s+text\s+验证.*\bselectorId\b/.test(l) ||
    // 兜底：节点末尾行含 selectorId 而非 XPath
    /^\s*\d+\s+text\s.*selectorId.*属性值/.test(l)
  );
  nodeRepl.write(JSON.stringify({ anyBadPlaceholder, tails: nodeTails.slice(-3) }));
}
```

**修复**：Escape → 双击该 canvas 节点重开弹框 → 走 `element-selector.md` §方式 C 重填（Cmd+V + Enter）→ 校验 AX 中出现独立行 `\d+ text //*[@id="..."]` → 保存 → 再校验 canvas 节点第二行是 XPath。

### 「文本输入区（Monaco 类）」中文粘贴 filled=false

**现象**：`验证文本存在/不存在`、`打印日志`、`FillText` 等含"文本输入区（settable, string）"的字段，用 `set_value` 或 `Cmd+V` 粘贴**中文**后 AX Tree 仍是空的。

**原因**：底层是 Monaco/CodeMirror 类富文本编辑器 —— `set_value` 只写 AXValue 不触发编辑器 model 更新；`Cmd+V` 中文时和系统 IME 存在冲突，Chrome 不在最前台就会丢字。

**决策**：

| 场景 | 推荐 |
|------|------|
| 内容是 ASCII（英文、数字、常见符号） | `type_text` 直接输入（最稳） |
| 内容必须是中文 | `pbcopy` → `osascript` 强制 Chrome 前台 + `sleep 2` → `sky.click(fieldIdx)` → `press_key("Cmd+V")` |
| 中文粘贴反复失败 | 改用等价 ASCII 替代（如百度首页版权栏含 `Baidu`，可替代中文断言） |

**验证脚本**：粘贴/输入后重新抓 AX，`region.some(l => l.includes(text))` 为 true 才算成功；否则不要点保存，先修复。



| 错误类型 | 原因 | 修复方式 |
|---------|------|---------|
| FillText / 页面元素不存在 | XPath 与真实 DOM 不符 | `element-selector.md` §批量采集（新建 Tab）重采全部相关 XPath，或更新 locators |
| FillText 10120036 | 选择器指向容器 div 而非 input | 精确 XPath：`//textarea[@id="xxx"]` |
| 元素未找到 | selector 不精确或页面改版 | 重新采集，勿沿用旧 XPath |
| 导航失败 | URL 格式错误 | pbcopy+paste 重填 |
| 网址显示 `https//`（缺冒号） | 用了 `type_text` 填 URL | 见 `url-input.md`：`pbcopy` + 粘贴或 `set_value`，禁止 type_text |
| 调试按钮灰色 | 上次调试未断开 | 点「断开」后重试 |
| 保存时报「该字段是必填字段」 | 必填项未填 / 元素选择器粘贴后未按 Enter | 元素选择器：Cmd+V 粘贴 XPath **紧接着按 Enter** 让 AntD Select 接受为定位器（`element-selector.md` §方式 C）；其它必填按 `commands/<slug>.md` 补全 |
| **「节点配置不完整」**（检查面板 / 编排区右侧 ⓘ） | 条件必填未满足（如 SetCookie Domain 为空、域名误填 Path） | 双击节点 → Read `commands/<slug>.md` 补全 → 保存 → 点「检查」确认无异常 |
| 配置改了但不生效 | 节点状态脏 / 保存未落盘 | **删指令 → 原位重插 → 重配表单**（见下） |
| **指令顺序错误**（如「输入文本」在「打开网页」前） | 添加时未先单击最后一条已保存指令行按 Enter 空行，导致光标落在错误位置（如已有指令上方/之间）就插入了新指令 | **首选**：选中错位节点 → 右击 **剪切** → 选中锚点行（最后一条正确指令）→ 按 **Enter** 创建空行 → **粘贴**（`insert-command.md` §右键菜单调整指令顺序，保留已填配置）；剪切失败再删后重插 |

修复流程：`修复 → 保存 → 点「检查」→ 断开(如需) → 调试 → 运行 → 再查四处报错`

> sky 自动化：调试前跑 `pre-debug-config-check`；调试后跑 `post-debug-four-way-check`。见 `test-workflow.md`、`ax-verify.md`。

循环直到：聊天区无报错 **且** 编排区左侧全部 ✅ **且** 右侧无配置警示 **且** 「检查」无异常。

## 多次修复失败：删指令原位重插

同一指令连续 **2～3 次**修复仍失败时：

1. 选中该指令节点 → `Delete` 删除
2. 在**原顺序位置**（结束节点上方）重新走搜索+双击流程（右侧「指令」Tab 搜索框 → 双击「网页自动化」分组下 `xxx (web)` 结果）
3. **从零配置**表单（不要复制旧 XPath/URL；条件必填按 `commands/<slug>.md` 重填）
4. 保存 → 点「检查」→ 调试 → 运行

适用场景：选择器粘贴未生效、节点配置面板状态异常、canvas 节点损坏。

## 完成判定

- 编排区每条指令**左侧**：**绿色 check-circle** ✅（无执行失败）
- 编排区每条指令**右侧**：无「**节点配置不完整**」配置警示
- 顶部「**检查**」：无配置异常节点、无红色 badge
- 聊天区调试日志：**无 error / 失败 / 异常** 输出
- 不满足任一条 → 继续修复循环，不得标记测试通过
