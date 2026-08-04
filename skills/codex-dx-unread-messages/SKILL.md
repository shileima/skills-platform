---
name: codex-dx-unread-messages
description: >
  大象 App 消息汇总发送技能。当用户说“汇总大象消息”“总结大象未读”“把大象消息发给我本人”
  “汇总下大象app消息，发送给我本人”等意图时激活。技能读取大象桌面客户端当前可见的未读/近期消息列表，
  提取重点消息、告警、审批和群聊未读内容，整理为 Markdown 摘要，并发送到用户本人的大象单聊会话。
---

# codex-dx-unread-messages — 大象消息汇总并发送本人

读取大象桌面客户端 (`cn.neixin.pc`) 当前可见的未读/近期消息，整理为简洁摘要，并发送给用户本人（默认“马世磊”）的大象单聊。

## 依赖

参照 `cua-router-basic` 技能的依赖说明和启动方式。所有桌面自动化通过 `sky.*` API 执行。

执行前必须验证：

```bash
SKILL_ROOT="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/skills/cua-router-basic}"
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  SKILL_ROOT="${HOME}/.cursor/skills/cua-router-basic"
fi
bash "$SKILL_ROOT/scripts/daemon.sh" start
bash "$SKILL_ROOT/scripts/exec.sh" 'nodeRepl.write("ok")'
```

输出 `ok` 后才允许继续调用 `sky.*`。

## 触发判定

用户表达以下意图时使用：

- “汇总大象消息”
- “总结大象未读消息”
- “把大象 App 消息摘要发给我”
- “汇总下大象app消息，发送给我本人”
- “看看大象里有什么重要消息并发我本人”

## 一键执行

优先直接执行脚本：

```bash
bash "./scripts/summarize-and-send.sh"
```

可指定接收人和摘要时间标签：

```bash
bash "./scripts/summarize-and-send.sh" "马世磊" "2026-08-03 21:55左右"
```

脚本成功时最后一行输出 JSON：

```json
{"ok":true,"receiver":"马世磊","inputIdx":210,"sentLikely":true}
```

## 稳定流程

1. 启动并验证 `cua-router-basic`：`daemon.sh start` + `exec.sh 'nodeRepl.write("ok")'`。
2. 先将大象 App 窗口放大到可用的大尺寸，再读取任何消息或定位元素：优先通过 `System Events` 设置 `process "大象"` 的 `window 1` 位置为 `{0, 33}`、尺寸为 `{1512, 850}`；如系统权限导致失败，必须明确报错并提示用户放大窗口后重试，不要在小窗口状态下继续发送。
3. 获取大象 App 状态：`sky.get_app_state({ app: "cn.neixin.pc", disableDiff: true })`。
4. 确认大象可访问：窗口标题包含 `大象`，左侧导航包含 `消息`。
5. 从完整 AX Tree 中优先提取左侧消息列表区域（通常 idx 80～240）的当前可见消息，避免右侧本人会话里的历史摘要污染；不要按低 idx 主导航区取数：
   - 会话名称：`文本 <会话名>` 或 `container <会话名>`
   - 时间：如 `21:53`、`20:45`
   - 未读数：如 `[ 5条 ]`、`未读 5`
   - 内容预览：消息文本、告警文本、审批卡片、群聊提示
5. 重点保留以下类型：
   - PR / Code 仓库通知
   - P0/P1/P2/P3 告警和恢复
   - Talos 发布结果
   - 审批待办
   - 工作相关群聊高未读数
   - HR / 打卡提醒
6. 组织为 Markdown 中文摘要，必须按分段输出：`未读概览`、`代码 / PR`、`告警`、`发布 / 部署`、`审批 / 待办`、`提醒`、`群聊未读`。每段使用 `- ` 列表，单条不超过约 150 字；同一分组下有多个项目时，项目之间必须插入一行 `------------------------------------------------`，长度需接近聊天气泡宽度且避免换行；每条消息的来源（群名称、系统会话名）必须加粗，例如 `**大前端**：57条未读；...`。
7. 摘要生成前必须去噪：过滤历史 `大象消息汇总`、AX 类型前缀（`文本`/`text`/`container`）、纯时间、纯数字、导航项和过长链接，避免旧摘要被再次吸入。
8. 摘要生成前必须去噪：过滤历史 `大象消息汇总`、AX 类型前缀（`文本`/`text`/`container`）、纯时间、纯数字、导航项和过长链接，避免旧摘要被再次吸入。
9. 点击左侧本人单聊（默认 `马世磊`），操作后重新 `get_app_state({ disableDiff: true })`。
10. 进入本人会话后不要先输入、不要粘贴、不要点击全屏输入。
11. 再次确认大象窗口仍处于放大后的可用尺寸；如尺寸被手动改小，必须重新放大并重新读取 AX Tree。
12. 放大尺寸后必须重新 `get_app_state({ disableDiff: true })`，在 AX Tree 中定位底部输入框 `文本输入区` / `说点什么...`，再在输入框前方工具栏附近优先查找 `按钮 `（实测为 Markdown 入口）；不要复用未放大前的 `按钮 ` / `...` 流程。
13. 点击 `按钮 ` 后必须重新读取 AX Tree：若已打开 `Markdown编辑器`，继续写入；若出现浮层，则在浮层中查找并点击 `发送 Markdown 消息`。
14. 打开 `Markdown编辑器` 弹框后，必须使用 AX Tree 定位左侧 `文本输入区 (settable, string) 请输入内容`，并通过 `sky.set_value({ app, element_index, value: summary })` 直接写入 Markdown 摘要；不要使用剪贴板、`pbcopy`、`Command+V` 或普通 `type_text`。
15. 写入后重新读取状态，确认 `请输入内容` 区域有摘要内容（如包含 `大象消息汇总`、`未读概览`），且左下角发送人是目标接收人（默认 `马世磊`），再点击弹框右下角 `发送`；发送后重新读取状态，校验 AX Tree 中包含摘要关键词。

## 关键实现片段

### 探测大象 app id

优先使用 `cn.neixin.pc`：

```js
{
  const s = await sky.get_app_state({ app: "cn.neixin.pc", disableDiff: true });
  nodeRepl.write(JSON.stringify({ textLen: s.text.length, preview: s.text.slice(0, 1200) }));
}
```

### 提取可见消息关键行

```js
{
  const s = await sky.get_app_state({ app: "cn.neixin.pc", disableDiff: true });
  const lines = s.text.split("\n").filter(l =>
    /文本|按钮|文本栏|图片|未读|消息|马世磊|群|分钟前|今天|昨天|周|:\d\d|\d+条/.test(l)
  );
  nodeRepl.write(JSON.stringify({ textLen: s.text.length, lines: lines.slice(0, 240) }));
}
```

### 打开本人单聊

```js
{
  const receiver = "马世磊";
  const s = await sky.get_app_state({ app: "cn.neixin.pc", disableDiff: true });
  const line = s.text.split("\n").find(l => l.includes(`container ${receiver}`))
    || s.text.split("\n").find(l => l.includes(`文本 ${receiver}`));
  if (!line) {
    nodeRepl.write(JSON.stringify({ error: "receiver not found", receiver }));
  } else {
    const idx = parseInt(line.match(/^\s*(\d+)/)[1]);
    await sky.click({ app: "cn.neixin.pc", element_index: idx });
    await new Promise(r => setTimeout(r, 1000));
    const s2 = await sky.get_app_state({ app: "cn.neixin.pc", disableDiff: true });
    nodeRepl.write(JSON.stringify({ receiver, clickedIdx: idx, hasInput: /文本输入区.*说点什么/.test(s2.text) }));
  }
}
```

### 触发 Markdown 弹框并发送

```js
{
  const msg = "【大象消息汇总】\n...";
  const app = "cn.neixin.pc";

  // 先进入本人会话；不要在普通输入框里输入或粘贴。
  // 必须先用系统窗口属性拉到全屏尺寸，双击标题栏/顶部空白区域在大象中可能无效。
  const { execFileSync } = await import("node:child_process");
  execFileSync("/usr/bin/osascript", [
    "-e", 'tell application "System Events" to tell process "大象" to set position of window 1 to {0, 33}',
    "-e", 'tell application "System Events" to tell process "大象" to set size of window 1 to {1512, 850}'
  ]);
  await new Promise(r => setTimeout(r, 1000));

  const latestBeforeMarkdown = await sky.get_app_state({ app, disableDiff: true });
  const latestLines = latestBeforeMarkdown.text.split("\n");
  const inputLine = latestLines.find(l => /文本输入区/.test(l) && /说点什么/.test(l));
  const inputIdx = inputLine ? parseInt(inputLine.match(/^\s*(\d+)/)[1]) : null;
  const markdownButtonLine = inputIdx === null ? null : latestLines.filter(l => {
    const m = l.match(/^\s*(\d+)/);
    const idx = m ? parseInt(m[1]) : null;
    return idx !== null && idx < inputIdx && idx >= inputIdx - 120 && /^\s*\d+\s+按钮\s+/.test(l);
  }).pop();
  if (!markdownButtonLine) {
    nodeRepl.write(JSON.stringify({ error: "markdown button not found", preview: latestBeforeMarkdown.text.slice(0, 1000) }));
  } else {
    const markdownIdx = parseInt(markdownButtonLine.match(/^\s*(\d+)/)[1]);
    await sky.click({ app, element_index: markdownIdx });
    await new Promise(r => setTimeout(r, 800));

    let editorState = await sky.get_app_state({ app, disableDiff: true });
    let editorLines = editorState.text.split("\n");
    const markdownMenuLine = editorLines.find(l => /发送\s*Markdown\s*消息/.test(l));
    if (markdownMenuLine && !/Markdown编辑器/.test(editorState.text)) {
      await sky.click({ app, element_index: parseInt(markdownMenuLine.match(/^\s*(\d+)/)[1]) });
      await new Promise(r => setTimeout(r, 800));
      editorState = await sky.get_app_state({ app, disableDiff: true });
      editorLines = editorState.text.split("\n");
    }

    const inputLine = editorLines.find(l => /文本输入区/.test(l) && /请输入内容/.test(l));
    if (!inputLine) {
      nodeRepl.write(JSON.stringify({ error: "markdown input not found", preview: editorState.text.slice(0, 1000) }));
    } else {
      const inputIdx = parseInt(inputLine.match(/^\s*(\d+)/)[1]);
      await sky.set_value({ app, element_index: inputIdx, value: msg });
      await new Promise(r => setTimeout(r, 500));

      const filledState = await sky.get_app_state({ app, disableDiff: true });
      const hasContent = /大象消息汇总|未读概览/.test(filledState.text);
      const hasReceiver = filledState.text.includes("马世磊");
      const sendLine = filledState.text.split("\n").find(l => /^\s*\d+\s+按钮\s+发送/.test(l));
      if (!hasContent || !hasReceiver || !sendLine) {
        nodeRepl.write(JSON.stringify({ error: "markdown editor not ready", hasContent, hasReceiver, hasSend: !!sendLine, preview: filledState.text.slice(0, 1000) }));
      } else {
        await sky.click({ app, element_index: parseInt(sendLine.match(/^\s*(\d+)/)[1]) });
      }
    }
  }
}
```

## 摘要格式规范

发送内容必须使用如下结构，避免把多个来源揉成一条长句：

```text
【大象消息汇总｜YYYY-MM-DD HH:mm左右】

未读概览：未读标记：未读 15、未读 5；会话未读：5条、57条、12条

【代码 / PR】
- Code PR：feat: Enhance brand configuration handling with alias fallback；bugfix-cj-0717 -> master

【告警】
- P3故障：com.sankuai.fst.qa.fe 504 告警，持续 47 分钟

【发布 / 部署】
- **Talos** 发布：项目 xgpt，状态 success
------------------------------------------------
- **外卖环境管理**：16条未读；test 骨干部署成功

【审批 / 待办】
- 待审批：申请人 蔡竞，类型 xgpt 发布审批，项目 xgpt(33400)

【提醒】
- **移动HR**：今天工作辛苦了，记得打卡哦～

【群聊未读】
- **08.03-发布群-Automan**：5条
------------------------------------------------
- **大前端**：57条
```

强制要求：

- 不输出 AX 前缀：`文本`、`text`、`container`、`按钮`。
- 不把历史摘要内容再次纳入本次摘要。
- 不输出纯时间、纯数字、导航项。
- 链接只保留为“链接”或直接省略。
- 每个分段最多保留 3～5 条，每条截断在约 120～170 字。

## 避坑清单

| 陷阱 | 现象 | 解决 |
|------|------|------|
| 使用错误 app id | `Invalid app` | 大象桌面客户端使用 `cn.neixin.pc` |
| 复用输入框 idx | 大象刷新后报 “user changed app” 或写错位置 | 每次发送前重新 `get_app_state` 并动态查找输入框 |
| 直接 `type_text`/剪贴板粘贴中文摘要 | 中文、标点、换行可能丢失，`pbcopy`/权限环境可能失败 | 只用 `sky.set_value` 写入 Markdown 编辑器的 `文本输入区` |
| 直接 Return 发送 | 消息按普通文本发送，Markdown 不渲染 | 先用 `System Events` 把大象窗口拉到全屏尺寸，再从最大化后的 AX Tree 中点击 `按钮 ` 打开 `Markdown编辑器` |
| 双击标题栏/顶部空白区最大化 | 大象窗口可能不响应双击，AX Tree 中找不到 `发送 Markdown 消息` | 不依赖双击；用系统窗口属性设置 `position {0,33}` 和 `size {1512,850}` |
| 误点聊天内容工具栏 / 右侧栏 | 找不到 Markdown 发送项或打开错误菜单 | 最大化后使用输入框前方工具栏里的 `按钮 `，不是未最大化状态下的 `按钮 ` |
| 操作后不重取 AX Tree | 读到旧状态，校验不准 | 每次 click / set_value 后重新获取 `disableDiff:true` |
| 只扫低 idx | 漏掉当前会话、输入框或浮层 | 始终在完整 `s.text` 上搜索 |
| 发送到群聊 | 当前会话未切到本人 | 先点击左侧 `文本 马世磊`，再确认标题或输入框存在 |
| 发送失败后盲目重发 | 可能重复消息 | 先重新读取状态，确认摘要是否已出现在会话中 |

## 输出要求

完成后向用户说明：

- 已读取并汇总大象当前可见未读/近期消息；
- 已发送到本人会话；
- 若 `sentLikely` 为 `false`，返回当前错误和建议用户确认大象窗口是否被手动切换。

## 边界

- 只汇总当前大象窗口可见的未读/近期消息列表和当前会话内容，不滚动读取全部历史。
- 不打开外部链接、不处理 PR、不审批、不处理告警，只做摘要转发。
- 默认接收人为“马世磊”；用户指定其他接收人时才改用其它会话。
