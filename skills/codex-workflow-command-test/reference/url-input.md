# URL 输入规范（sky 自动化）

> **硬性规则**：凡含 `http://` 或 `https://` 的 URL，**禁止**用 `sky.type_text` 填写。

> 🚫🚫🚫 **弹框网址 vs Chrome 地址栏（反复出错的高危混淆，不可跳过）**：
>
> - **Chrome 地址栏**（窗口最顶部）：仅用于**平台导航**（如打开 `rpa.sankuai.com/rpa/chat`），见 `test-workflow.md` §1a、`platform-ops.md` §2.1a。
> - **指令弹框「网址」输入框**（「打开网页(web)」配置弹框内「输入参数」区）：用于填写**工作流指令参数**。
> - **配置弹框已打开时，绝对禁止**对 Chrome 地址栏做 `set_value`、`type_text`、`cmd+v` 粘贴或按 `Return` 导航。
> - 误填地址栏的典型现象：弹框「网址」仍为空/仍红框/仍显示占位符「输入'/'插入上游节点变量」，而 Chrome 顶部地址栏出现 `https://www.sogou.com/` 等目标 URL。
> - 误填后**禁止**按 `Return` 导航离开工作流页；须先聚焦弹框内「网址」字段重填，再 AX 验证弹框内已含完整 URL。

## 现象

### 现象 A：冒号丢失

配置「打开网页(web)」等指令时，用 `type_text` 填网址，结果常变成：

```
https//www.baidu.com    ← 冒号丢失
```

### 现象 B：填错位置（地址栏 vs 弹框）

智能体把 URL 写进 **Chrome 地址栏**，弹框内「网址」仍为空：

```
Chrome 地址栏：  https://www.sogou.com/     ← 错误位置
弹框「网址」：   （空 / 占位符 / 红色边框）   ← 应填此处
```

## 根因

| 问题 | 根因 |
|------|------|
| 冒号丢失 | macOS 上 `:` 需 **Shift+;**。`type_text` 无法可靠发送 Shift 修饰符 |
| 填错地址栏 | 复用了 `test-workflow.md` 的地址栏 `set_value` 模板；或未确认弹框打开就粘贴；或全局搜索「网址」/settable 命中错误元素 |

## 正确写法（按场景）

| 场景 | 推荐 API | 说明 |
|------|---------|------|
| Chrome **地址栏**导航（**仅**平台入口、XPath 批量采集新建 Tab） | `set_value` + `Return` | 见 `test-workflow.md` §1a；**弹框打开时禁用** |
| 指令弹框「**网址**」等表单字段 | `pbcopy` + `cmd+v` 粘贴 | **首选**；粘贴前 `cmd+a` 清空；须 scoped 定位弹框内字段 |
| 表单字段（弹框内、AX 支持 settable） | `set_value` | 可替代粘贴；**必须** scoped 定位 + AX 验证在弹框 slice 内 |
| 任何 URL 字符串 | ❌ **禁止** `type_text` | 会丢冒号，导致导航失败 |

## sky 自动化：填写「打开网页(web)」网址

每一步：**动作 → 全量 AX → 验证 → 下一步**（见 `ax-verify.md`）。

### 辅助：scoped 定位弹框内「网址」字段（禁止全局 find）

```js
// 在 nodeRepl / sky.exec 内复用
function findChromeAddressBarIdx(lines) {
  const line = lines.find(l => /settable, string/.test(l) && /地址/.test(l) && !/网址/.test(l));
  return line ? parseInt(line.match(/^\s*(\d+)/)[1]) : null;
}

function findModalUrlFieldIdx(lines) {
  // 1) 弹框须已打开（结构性信号）
  const hasSaveBtn = lines.some(l => /\d+\s+按钮\s+保\s*存/.test(l));
  if (!hasSaveBtn) return { urlIdx: null, reason: "modal-not-open" };

  // 2) 在「* 网址」label 下方 scoped 搜索（禁止全局 find 第一个 settable）
  const labelIdx = lines.findIndex(l =>
    /text\s+\*\s+网址/.test(l) || (/text\s+网址/.test(l) && /输入参数|常规/.test(lines.slice(Math.max(0, lines.indexOf(l) - 8), lines.indexOf(l)).join("\n")))
  );
  if (labelIdx < 0) return { urlIdx: null, reason: "url-label-not-found" };

  const slice = lines.slice(labelIdx, labelIdx + 15);
  const inputLine = slice.find(l =>
    /settable|textfield|文本栏/i.test(l) &&
    !(/settable, string/.test(l) && /地址/.test(l) && !/网址/.test(l))
  );
  const urlIdx = inputLine ? parseInt(inputLine.match(/^\s*(\d+)/)[1]) : null;
  const addrIdx = findChromeAddressBarIdx(lines);
  if (urlIdx != null && urlIdx === addrIdx) return { urlIdx: null, reason: "idx-collides-with-address-bar" };
  return { urlIdx, labelIdx, addrIdx, reason: urlIdx == null ? "url-input-not-found" : "ok" };
}

function verifyUrlInModal(lines, targetUrl, labelIdx) {
  const start = labelIdx >= 0 ? labelIdx : lines.findIndex(l => /text\s+\*\s+网址/.test(l));
  const modalSlice = start >= 0 ? lines.slice(start, start + 15).join("\n") : "";
  return modalSlice.includes(targetUrl);
}
```

### Shell 侧（先复制 URL）

```bash
echo -n "https://www.baidu.com" | pbcopy
```

### Step 0：确认配置弹框已打开（前置门控）

```js
{
  const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const hasSaveBtn = lines.some(l => /\d+\s+按钮\s+保\s*存/.test(l));
  const hasUrlLabel = lines.some(l => /text\s+\*\s+网址/.test(l));
  const panelOpen = hasSaveBtn && hasUrlLabel;
  nodeRepl.write(JSON.stringify({ step: "url-step0", panelOpen, hasSaveBtn, hasUrlLabel }));
  // panelOpen === false → 回到 platform-ops.md §2.2 双击节点重开弹框；禁止在此状态下操作地址栏
}
```

### Step 1：scoped 聚焦弹框「网址」→ 粘贴 → 双端验证

```js
{
  const TARGET = "https://www.baidu.com"; // 与 pbcopy 一致
  const s0 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const lines0 = s0.text.split("\n");

  const { urlIdx, labelIdx, addrIdx, reason } = findModalUrlFieldIdx(lines0);
  if (urlIdx == null) {
    nodeRepl.write(JSON.stringify({ step: "url-step1", ok: false, reason }));
    throw new Error("modal-url-field-not-found: " + reason);
  }

  // 🚫 禁止对 addrIdx 做任何 set_value / paste / Return
  await sky.click({ app: "com.google.Chrome", element_index: urlIdx });
  await new Promise(r => setTimeout(r, 200));
  await sky.press_key({ app: "com.google.Chrome", key: "cmd+a" });
  await sky.press_key({ app: "com.google.Chrome", key: "cmd+v" });
  await new Promise(r => setTimeout(r, 300));

  const lines1 = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const urlInModal = verifyUrlInModal(lines1, TARGET, labelIdx);
  const colonMissing = lines1.some(l => /https\/\//.test(l));
  const addrLine = addrIdx != null ? lines1.find(l => new RegExp(`^\\s*${addrIdx}\\s`).test(l)) : null;
  const hostFragment = TARGET.replace(/^https?:\/\//, "").split("/")[0];
  const addrPolluted = addrLine && hostFragment && addrLine.includes(hostFragment) && !urlInModal;

  nodeRepl.write(JSON.stringify({
    step: "url-step1",
    urlIdx,
    labelIdx,
    addrIdx,
    urlInModal,
    colonMissing,
    addrPolluted,
    ok: urlInModal && !colonMissing && !addrPolluted
  }));
  // ok === false → 若 addrPolluted：Escape 失焦地址栏 → 重开弹框 → scoped 重填；禁止 Return 导航
}
```

### 备选：set_value（仅弹框内 scoped idx）

```js
{
  const TARGET = "https://www.baidu.com";
  const lines0 = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const { urlIdx, labelIdx, reason } = findModalUrlFieldIdx(lines0);
  if (urlIdx == null) {
    nodeRepl.write(JSON.stringify({ step: "url-set_value", ok: false, reason }));
    throw new Error("modal-url-field-not-found");
  }

  await sky.set_value({ app: "com.google.Chrome", element_index: urlIdx, value: TARGET });

  const lines1 = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const urlInModal = verifyUrlInModal(lines1, TARGET, labelIdx);
  nodeRepl.write(JSON.stringify({ step: "url-set_value", urlIdx, urlInModal, ok: urlInModal }));
}
```

## 保存前必验

粘贴或 `set_value` 后，AX Tree 中须**同时**满足：

1. **弹框「* 网址」label 下方 15 行 slice 内**含完整 `https://`（或 `http://`），**不能**仅出现在 Chrome 地址栏行
2. **不能**出现 `https//`
3. 「网址」输入框**无红色边框**
4. 无「该字段是必填字段」提示
5. Chrome 地址栏**未**因误操作变成工作流目标 URL（如 sogou/baidu/bilibili）
6. **不能**仍为占位符「输入'/'插入上游节点变量」——仍显示占位符 = 必填未填，**禁止点保存**

### Step 2：保存前门控（canSave 为 true 才允许点「保存」）

```js
{
  const lines = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const labelIdx = lines.findIndex(l => /text\s+\*\s+网址/.test(l));
  const sliceText = labelIdx >= 0 ? lines.slice(labelIdx, labelIdx + 15).join("\n") : "";
  const hasPlaceholder = /输入.*插入上游节点变量/.test(sliceText);
  const hasRequiredErr = lines.some(l => l.includes("该字段是必填字段"));
  const hasUrl = /https?:\/\//.test(sliceText) && !/https\/\//.test(sliceText);
  const canSave = hasUrl && !hasPlaceholder && !hasRequiredErr;

  nodeRepl.write(JSON.stringify({ step: "url-save-gate", canSave, hasUrl, hasPlaceholder, hasRequiredErr }));

  if (!canSave) {
    nodeRepl.write(JSON.stringify({ step: "save-blocked", reason: "网址未填完，禁止点保存" }));
    // 回到 Step 1 补填，禁止 click 保存按钮
  }
  // canSave === true → 再执行 platform-ops.md §2.4 assertCanSave → click「保存」
}
```

完整通用 helper 见 `ax-verify.md` §`assertCanSaveOpenUrl`、`platform-ops.md` §2.4 sky 自动化。

## 误填地址栏后的修复

```
1. 禁止按 Return（避免离开工作流编辑页）
2. Escape 一次 → 全量 AX：弹框仍在则继续；弹框关闭则 platform-ops.md §2.2 双击节点重开
3. pbcopy 目标 URL → 按本页 Step 0–1 scoped 重填弹框「网址」
4. AX 验证 urlInModal === true → **assertCanSaveOpenUrl(canSave===true)** 后再点「保存」
```

## 适用指令

凡带 URL 参数的 web 指令均遵循本规范，例如：

- [openurl.md](commands/openurl.md) — 字段「网址」
- [navigatetourl.md](commands/navigatetourl.md) — 字段「导航到的网址」
- [switchtowindowurl.md](commands/switchtowindowurl.md) — 字段「URL」
- [closepagebyurl.md](commands/closepagebyurl.md) — 字段「URL」

> 「导航到的网址」等同理：在对应 label（如 `* 导航到的网址`）下方 scoped 找输入框，**禁止**用地址栏。

## 调试对照

| 现象 | 原因 | 修复 |
|------|------|------|
| Chrome 地址栏出现目标 URL，弹框「网址」仍空 | 误用地址栏 `set_value` 或未 scoped 定位 | Step 0 确认弹框 → scoped 重填弹框字段；禁止 Return |
| 输入框显示 `https//...` | 用了 `type_text` | `pbcopy` + 重粘贴到**弹框内**字段 |
| 导航失败 / 协议错误 | URL 缺冒号 | 按本页重填并 AX 验证弹框 slice |
| 脚本有 `://` 但弹框没有 | type_text 丢 Shift 或填错位置 | 改用 scoped 粘贴/set_value + verifyUrlInModal |
