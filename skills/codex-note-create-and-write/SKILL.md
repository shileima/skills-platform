---
name: codex-note-create-and-write
description: >
  macOS 「备忘录」App (`com.apple.Notes`) 桌面自动化：新建一条备忘录并写入指定内容。
  当用户说「新建备忘录写入 X」「在备忘录里记一下 X」「备忘录写一首诗」「Notes 新建笔记」等意图时激活。
  用户未提供内容时，默认写入白居易《琵琶行》（首句「浔阳江头夜送客」）。
---

# codex-note-create-and-write — 备忘录新建并写入内容

在 macOS 「备忘录」客户端 (`com.apple.Notes`) 新建一条备忘录并写入指定文本。优先使用 Notes AppleScript 接口后台创建 note，不占用桌面、不移动鼠标、不依赖当前窗口焦点；如果后台写入失败，再切换到前台 AX Tree 精确点击「新建备忘录」按钮并粘贴内容。

## 依赖

参照 `cua-router-basic` 的 `references/install.md` 与 `references/runtime-exec.md`。正常情况下优先走 AppleScript 后台流程；仅当后台写入失败并进入 AX fallback 时，必须 `daemon.sh start` 并用 `nodeRepl.write("ok")` 验证。

## 何时激活

用户表达以下意图之一：

- 「新建一个备忘录，写入 X」
- 「在 Notes 里记一下 X」
- 「打开备忘录，写一首诗 / 一段话 / 一份清单」
- 「备忘录里记录 X」
- 只说「新建备忘录」而未指定内容 —— 走**默认内容**流程

## 输入约定

| 参数 | 是否必需 | 说明 |
|------|----------|------|
| `content` | 否 | 要写入备忘录的完整文本，支持多行；未提供时使用默认《琵琶行》全文 |

**默认内容**：白居易《琵琶行》全篇。首行为标题「琵琶行」，备忘录会自动把首行渲染为标题。

## 一键执行

```bash
bash "./scripts/create-and-write.sh" "[content]"
```

示例：

```bash
# 1) 指定内容（多行请用 $'...\n...' 或 heredoc）
bash ./scripts/create-and-write.sh "$(printf '静夜思\n——[唐] 李白\n\n床前明月光，疑是地上霜。\n举头望明月，低头思故乡。')"

# 2) 从文件读入
bash ./scripts/create-and-write.sh "$(cat mynote.txt)"

# 3) 不传参 → 默认写入《琵琶行》
bash ./scripts/create-and-write.sh
```

脚本会：

1. 读取用户传入的 `content`；未传入时使用内置《琵琶行》全篇
2. 将首行转为 Notes 标题 `<h1>`，其余内容按段落转为 HTML
3. 优先通过 `osascript` 调用 Notes AppleScript 接口：`make new note at folder "Notes" of default account with properties {body: htmlContent}`
4. 如果 AppleScript 后台写入失败，自动切换到前台 AX fallback：
   - 启动 `cua-router` daemon 并验证 `nodeRepl.write("ok")`
   - `open -a Notes` 打开备忘录
   - `sky.get_app_state({ disableDiff: true })` 获取完整 AX Tree
   - 用 `findIdx(s.text, "按钮", "新建备忘录")` 定位工具栏 icon 按钮并点击
   - 定位 `文本输入区 ID: Note Body Text View`
   - 通过 `pbcopy` + `Command+v` 粘贴内容，避免中文 `type_text` 丢字
5. 成功时返回新建 note 的 `id` 或 AX fallback 的 JSON 结果

成功时输出类似：

```text
note id x-coredata://.../ICNote/...
```

## 关键流程与避坑

| 陷阱 | 现象 | 解决 |
|------|------|------|
| `sky.launch_app` | 不存在此 API | 走 `open -a Notes` |
| AppleScript 后台写入失败 | Notes 脚本权限、默认账户/文件夹异常 | 自动切换到前台 AX 点击「新建备忘录」按钮流程 |
| 前台 AX fallback 未找到按钮 | 工具栏按钮位置随窗口尺寸/侧栏变化 | 用 `findIdx(s.text, "按钮", "新建备忘录")` 精确拿 `element_index`，不点固定坐标 |
| `sky.click({ idx })` | 报 `coordinate must include finite x and y coordinates` | 参数名是 `element_index`，不是 `idx` |
| 新建后 `set_value` 写文本输入区 | 报 `Cannot set a value for an element that is not settable` | 用「剪贴板 + Cmd+V」 |
| `sky.press_key({ key: "v", modifiers: ["cmd"] })` | `modifiers` 被忽略，`av` 被当作字面量输入 | 组合键必须写 `Command+a` / `Command+v` 单字符串（见 `cua-router-basic/references/input-keyboard.md`） |
| `sky.type_text(中文)` | IME 吞字，只剩标点和 `****` 残留 | 禁用 `type_text` 输入中文，全部走剪贴板 |
| `printf ... \| pbcopy` 写多行中文 | 某些 shell / sandbox 下 `pbpaste` 为空 | 改用 `osascript -e 'set the clipboard to "..."'`（脚本已通过临时文件 + AppleScript 处理换行和引号转义） |
| 新建后立刻粘贴 | 编辑器还没获得焦点，Cmd+V 落到列表 | 粘贴前显式 `click({ element_index: 文本输入区 idx })` |

## AX Tree 定位辅助函数

```js
function findIdx(axText, ...keywords) {
  const line = axText.split("\n").find(l => keywords.every(k => l.includes(k)));
  if (!line) return null;
  return parseInt(line.match(/^\s*(\d+)/)[1]);
}

function findFocusedIdx(axText) {
  const line = axText.split("\n").find(l => /focused UI element is/.test(l));
  return line ? parseInt(line.match(/\b(\d+)\b/)?.[1]) : null;
}
```

- 「新建备忘录」按钮：`findIdx(text, "按钮", "新建备忘录")`
- 文本输入区：`findIdx(text, "文本输入区", "Note Body Text View")` 或点击新建按钮后从 `findFocusedIdx` 拿

## 默认内容 —— 白居易《琵琶行》

首行 `琵琶行` 会被备忘录识别为标题；第二行标注作者；空行后进入正文。完整默认文本内置在 `scripts/create-and-write.sh` 的 `DEFAULT_CONTENT` 变量中。

## 操作规范

遵循 `cua-router-basic` 主文件的核心操作规范：
- `disableDiff: true` 每次取全新 AX Tree
- 组合键写完整 `Command+X` 字符串
- 中文 / URL / 多行文本一律 `osascript 剪贴板 + Command+V`
- 写入后必须重新 `get_app_state` 校验 `Value` 命中
