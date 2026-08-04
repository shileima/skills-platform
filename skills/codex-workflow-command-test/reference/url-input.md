# URL 输入规范（sky 自动化）

> **硬性规则**：凡含 `http://` 或 `https://` 的 URL，**禁止**用 `sky.type_text` 填写。

## 现象

配置「打开网页(web)」等指令时，用 `type_text` 填网址，结果常变成：

```
https//www.baidu.com    ← 冒号丢失
```

脚本里明明写了 `https://www.baidu.com`，但输入框实际缺少 `:`。

## 根因

macOS 上 `:` 需 **Shift+;** 组合键。`type_text` 逐键模拟，**无法可靠发送 Shift 修饰符**，导致 `https` 后的第一个 `:` 被吞掉。同类风险字符还包括 `@`、`#` 等需 Shift 的符号。

## 正确写法（按场景）

| 场景 | 推荐 API | 说明 |
|------|---------|------|
| Chrome **地址栏**导航 | `set_value` + `Return` | 见 `test-workflow.md` §1a |
| 指令弹框「**网址**」等表单字段 | `pbcopy` + `cmd+v` 粘贴 | **首选**；粘贴前 `cmd+a` 清空 |
| 表单字段（AX 支持 settable） | `set_value` | 可替代粘贴；填后必须 AX 验证 |
| 任何 URL 字符串 | ❌ **禁止** `type_text` | 会丢冒号，导致导航失败 |

## sky 自动化：填写「打开网页(web)」网址

每一步：**动作 → 全量 AX → 验证 → 下一步**（见 `ax-verify.md`）。

### Shell 侧（先复制 URL）

```bash
echo -n "https://www.baidu.com" | pbcopy
```

### Step 1：聚焦「网址」输入框 → 粘贴

```js
{
  const s0 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const lines0 = s0.text.split("\n");
  const urlIdx = parseInt(lines0.find(l =>
    l.includes("网址") && /settable|textfield|文本栏/i.test(l)
  )?.match(/^\s*(\d+)/)?.[1] ?? lines0.find(l =>
    l.includes("网址")
  )?.match(/^\s*(\d+)/)?.[1]);

  await sky.click({ app: "com.google.Chrome", element_index: urlIdx });
  await new Promise(r => setTimeout(r, 200));
  await sky.press_key({ app: "com.google.Chrome", key: "cmd+a" });
  await sky.press_key({ app: "com.google.Chrome", key: "cmd+v" });
  await new Promise(r => setTimeout(r, 300));

  const lines1 = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const urlOk = lines1.some(l => l.includes("https://www.baidu.com"));
  const colonMissing = lines1.some(l => /https\/\//.test(l));
  nodeRepl.write(JSON.stringify({ step: "url-paste", urlIdx, urlOk, colonMissing }));
  // urlOk === false 或 colonMissing === true → 重 pbcopy 再粘贴；禁止改用 type_text
}
```

### 备选：set_value（字段为 settable 时）

```js
{
  const s0 = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
  const urlIdx = parseInt(s0.text.split("\n").find(l =>
    l.includes("网址") && /settable/i.test(l)
  )?.match(/^\s*(\d+)/)?.[1]);

  await sky.set_value({
    app: "com.google.Chrome",
    element_index: urlIdx,
    value: "https://www.baidu.com"
  });

  const lines1 = (await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true })).text.split("\n");
  const urlOk = lines1.some(l => l.includes("https://www.baidu.com"));
  nodeRepl.write(JSON.stringify({ step: "url-set_value", urlIdx, urlOk }));
}
```

## 保存前必验

粘贴或 `set_value` 后，AX Tree 中须同时满足：

1. 含完整 `https://`（或 `http://`），**不能**出现 `https//`
2. 「网址」输入框**无红色边框**
3. 无「该字段是必填字段」提示

## 适用指令

凡带 URL 参数的 web 指令均遵循本规范，例如：

- [openurl.md](commands/openurl.md) — 字段「网址」
- [navigatetourl.md](commands/navigatetourl.md) — 字段「导航到的网址」
- [switchtowindowurl.md](commands/switchtowindowurl.md) — 字段「URL」
- [closepagebyurl.md](commands/closepagebyurl.md) — 字段「URL」

## 调试对照

| 现象 | 原因 | 修复 |
|------|------|------|
| 输入框显示 `https//...` | 用了 `type_text` | `pbcopy` + 重粘贴 |
| 导航失败 / 协议错误 | URL 缺冒号 | 按本页重填并 AX 验证 |
| 脚本有 `://` 但界面没有 | type_text 丢 Shift 键 | 改用粘贴或 set_value |
