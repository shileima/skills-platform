# 捕获元素模块

> **模块定位**：本模块是**独立可复用的捕获元素功能**，供其他模块调用。任何需要在 RPA 平台上通过「捕获」按钮采集元素 XPath 的场景，都应 Read 本模块执行，不要自行内联捕获流程。
>
> **调用方**：`element-selector.md` §方式 B、`commands/<指令>.md` 中涉及元素选择器的指令、任何需在弹框中点击「捕获」采集元素的场景。

## 前置条件

- 已双击指令节点，配置弹框已打开
- 云浏览器已连接（设备区显示 Chrome 在线）
- 遵循 `ax-verify.md` 动作-验证循环：**每步动作后全量抓 AX Tree 验证**

## 判据设计原则（来自实战经验）

> ⚠️ **禁止使用单一精确字符串匹配**作为弹框/按钮判据。AX Tree 中的空格可能是 tab/nbsp（U+00A0）而非普通空格（U+0020），`includes` 对不可见字符零容忍，极易假阴性。

**正确做法 — 结构性多信号交叉验证**：

| 判定目标 | ❌ 错误判据（脆弱） | ✅ 正确判据（结构性信号） |
|---------|-------------------|------------------------|
| 配置弹框已打开 | `s.text.includes("验证元素存在(web)  验证元素存在(web)")` | 有「捕获」按钮 **OR** 有「元素选择器」字段 **OR** 有「保存」按钮 |
| 捕获按钮存在 | `l.includes("捕获")` | `/\d+ 按钮\s+捕\s*获/.test(l)` |
| 采集中状态 | `l.includes("采集中")` | `l.includes("采集中") OR l.includes("capturing") OR 有元素选择器字段且 value 含 //` |
| 保存成功 | 标题字符串消失 | 「保存」按钮消失 **AND** 弹框关闭（canvas 节点保留） |

**核心规则**：用**结构性信号**（按钮/字段/标签的存在性）而非**精确重复标题字符串**做多信号 OR 判定。

## 完整流程

```
第 1 步：验证配置弹框已打开（多信号交叉验证）
第 2 步：点击弹框内「捕获」按钮 → 等待采集中状态
第 3 步：在云浏览器中点击目标元素 → 验证 XPath 回填
第 4 步：点击保存 → 验证弹框关闭
第 5 步：回到编排区验证元素是否回显在指令上
第 6 步：若未捕获成功，刷新页面重新进入流程（循环）
```

### 第 1 步：验证配置弹框已打开（多信号交叉验证）

> ⚠️ **禁止**用标题字符串精确匹配判断弹框状态。必须用以下结构性信号做多信号 OR 判定。

```js
{
  const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");

  // ✅ 结构性信号判定（多信号 OR）
  const hasCaptureBtn = lines.some(l => /\d+\s+按钮\s+捕\s*获/.test(l));
  const hasElementSelector = lines.some(l => l.includes("元素选择器") && /settable|textfield|文本栏/i.test(l));
  const hasSaveBtn = lines.some(l => /\d+\s+按钮\s+保\s*存/.test(l));
  const dialogOpen = hasCaptureBtn || hasElementSelector || hasSaveBtn;

  nodeRepl.write(JSON.stringify({
    step: "capture-step1-verify-dialog",
    dialogOpen,
    signals: { hasCaptureBtn, hasElementSelector, hasSaveBtn }
  }));

  // dialogOpen === false → 回到 platform-ops.md §2.2 重新双击打开弹框
  if (!dialogOpen) {
    nodeRepl.write(JSON.stringify({ action: "reopen-dialog-via-platform-ops-2.2" }));
  }
}
```

### 第 2 步：点击「捕获」按钮 → 等待采集中状态

```js
{
  const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");

  // 用结构性信号定位捕获按钮
  const captureLine = lines.find(l => /\d+\s+按钮\s+捕\s*获/.test(l));
  const captureIdx = captureLine ? parseInt(captureLine.match(/^\s*(\d+)/)?.[1]) : null;

  if (!captureIdx) {
    nodeRepl.write(JSON.stringify({ step: "capture-step2", error: "未找到捕获按钮", action: "verify-dialog-open-or-reopen" }));
  } else {
    await sky.click({ app: "com.google.Chrome", element_index: captureIdx });
    await new Promise(r => setTimeout(r, 800));

    const lines2 = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
    // 多信号判定采集中状态
    const capturing = lines2.some(l => l.includes("采集中") || l.includes("capturing"));
    const selectorHasValue = lines2.some(l => l.includes("元素选择器") && /value.*\/\//.test(l));

    nodeRepl.write(JSON.stringify({
      step: "capture-step2-click-capture",
      captureIdx,
      capturing,
      selectorHasValue,
      action: capturing ? "proceed-to-click-element" : "retry-capture-or-check-cloud-browser"
    }));
  }
}
```

> ⚠️ 若 `capturing === false`：检查云浏览器是否已连接；若无 hover 高亮，关闭弹框重新双击节点再点「捕获」。

### 第 3 步：在云浏览器中点击目标元素 → 验证 XPath 回填

> 此步骤需要用户在 VNC 中操作，或由 sky 在云浏览器中点击目标元素。

**3a. 用户在 VNC 中操作（推荐）**：

1. 用户在 VNC 云浏览器中导航到目标页面
2. **悬停**目标元素 → 出现 hover 高亮框
3. **点击**目标元素
4. 验证 XPath 已回填（见 3b 验证）

**3b. sky 验证 XPath 回填**：

```js
{
  // 等待用户点击元素后验证
  await new Promise(r => setTimeout(r, 1500));

  const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");

  // 多信号判定 XPath 已回填
  const hasXpathValue = lines.some(l => /\/\/.*\[@?/.test(l) && /value|settable/i.test(l));
  const selectorFieldFilled = lines.some(l =>
    l.includes("元素选择器") && /\/\/\//.test(l)
  );
  const xpathCaptured = hasXpathValue || selectorFieldFilled;

  nodeRepl.write(JSON.stringify({
    step: "capture-step3-verify-xpath",
    xpathCaptured,
    hasXpathValue,
    selectorFieldFilled,
    action: xpathCaptured ? "proceed-to-save" : "wait-and-recheck-or-adjust"
  }));

  // xpathCaptured === false →
  //   用户可能需要：重选 / 大选区 / 缩小选取 icon 来调整
  //   等待后再验证，或让用户重新点击元素
}
```

**3c. XPath 不正确时的调整操作**：

若 XPath 回填但不正确，用户可在 VNC 中：
- 点击**重选**按钮重新选择元素
- 点击**大选区** icon 扩大选择范围
- 点击**缩小选取** icon 缩小选择范围
- 调整后重新点击目标元素

调整后重新执行 3b 验证，直至 XPath 正确。

### 第 4 步：点击保存 → 验证弹框关闭

```js
{
  const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");

  // 保存前校验：元素选择器已有值且无必填错误
  const hasSelectorValue = lines.some(l => /\/\/\//.test(l) && /value|settable/i.test(l));
  const hasRequiredErr = lines.some(l => l.includes("该字段是必填字段"));

  if (!hasSelectorValue || hasRequiredErr) {
    nodeRepl.write(JSON.stringify({
      step: "capture-step4-precheck",
      canSave: false,
      hasSelectorValue,
      hasRequiredErr,
      action: "fix-before-save"
    }));
  } else {
    // 找保存按钮（兼容 Ant Design 半角空格「保 存」）
    function axHasLabel(line, label) {
      return new RegExp(label.split("").join("\\s*")).test(line);
    }
    const saveLine = lines.find(l => axHasLabel(l, "保存") && l.includes("按钮"));
    const saveIdx = saveLine ? parseInt(saveLine.match(/^\s*(\d+)/)?.[1]) : null;

    if (saveIdx) {
      await sky.click({ app: "com.google.Chrome", element_index: saveIdx });
      await new Promise(r => setTimeout(r, 1000));

      const lines2 = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
      // 保存成功 = 弹框关闭（保存按钮消失）
      const saved = !lines2.some(l => axHasLabel(l, "保存") && l.includes("按钮") && lines2.some(l2 => l2.includes("元素选择器")));

      nodeRepl.write(JSON.stringify({
        step: "capture-step4-save",
        saved,
        action: saved ? "proceed-to-verify-in-canvas" : "check-required-fields-and-retry"
      }));
    }
  }
}
```

### 第 5 步：回到编排区验证元素是否回显在指令上

```js
{
  // 点击「编排区」Tab 或切换回编排视图
  const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");

  // 查找「编排区」标签
  const editorTabLine = lines.find(l => l.includes("编排区") && /tab|标签/i.test(l));
  const editorTabIdx = editorTabLine ? parseInt(editorTabLine.match(/^\s*(\d+)/)?.[1]) : null;

  if (editorTabIdx) {
    await sky.click({ app: "com.google.Chrome", element_index: editorTabIdx });
    await new Promise(r => setTimeout(r, 500));
  }

  // 验证指令节点上是否回显了元素 XPath
  const lines2 = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const canvasStart = lines2.findIndex(l => l.includes("编辑器容器"));
  const canvasArea = lines2.slice(canvasStart, canvasStart + 120);

  // 检查目标指令节点行是否包含 xpath 或元素选择器信息
  const elementVisible = canvasArea.some(l => /\/\/\//.test(l) || /元素选择器/.test(l));

  nodeRepl.write(JSON.stringify({
    step: "capture-step5-verify-canvas",
    elementVisible,
    action: elementVisible ? "capture-success" : "retry-capture"
  }));
}
```

### 第 6 步：未捕获成功时的循环处理

若第 5 步验证 `elementVisible === false`，表示捕获未成功回显，需循环重试：

```js
{
  // 刷新页面
  await sky.press_key({ app: "com.google.Chrome", key: "cmd+r" });
  await new Promise(r => setTimeout(r, 2000));

  // 回到编辑器，重新双击指令打开弹框
  // 按 platform-ops.md §2.2 执行双击流程
  // 重新从第 1 步开始捕获流程

  nodeRepl.write(JSON.stringify({
    step: "capture-step6-retry",
    action: "refresh-and-restart-capture-from-step1"
  }));
}
```

> ⚠️ **循环上限**：连续 3 次捕获失败后，应暂停并报告当前 AX 状态，请用户确认云浏览器连接状态，不要无限制重试。

## AX 验证信号汇总

| 步骤 | 成功信号 | 失败信号 | 下一步 |
|------|---------|---------|--------|
| 1 验证弹框 | 有捕获按钮 OR 有元素选择器 OR 有保存按钮 | 三个信号均无 | 重新双击节点（`platform-ops.md` §2.2） |
| 2 点击捕获 | AX 含「采集中」/「capturing」 | 无采集中状态 | 检查云浏览器连接；重试点击捕获 |
| 3 点击元素 | 元素选择器 value 含 `//` | value 仍为空 | 用户重新点击元素 / 调整选取范围 |
| 4 点击保存 | 弹框关闭，保存按钮消失 | 仍显示必填错误 | 补全必填项后重试保存 |
| 5 编排区验证 | 指令节点回显 XPath | 节点无 XPath 信息 | 刷新页面 → 重新捕获（第 6 步） |
| 6 循环重试 | 重新走第 1 步成功 | 连续 3 次失败 | 暂停，报告 AX 状态 |

## 与其他模块的调用关系

| 调用方 | 调用时机 | 本模块返回 |
|--------|---------|-----------|
| `element-selector.md` §方式 B | 需通过平台「捕获」按钮采集元素 | XPath 已回填到元素选择器字段 |
| `commands/<指令>.md` | 任何含元素选择器的指令需要捕获 | 同上 |
| 自定义流程 | 用户主动要求「捕获元素」 | 同上 |

> **调用约定**：调用方负责打开配置弹框（双击节点），然后 Read 本模块从第 1 步执行。本模块不负责打开/关闭弹框之外的状态管理。
