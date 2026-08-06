---
name: codex-dx-unread-messages
description: >
  大象 App 消息汇总发送技能。当用户说“汇总大象消息”“总结大象未读”“把大象消息发给我本人”
  “汇总下大象app消息，发送给我本人”等意图时激活。技能读取大象桌面客户端当前可见的未读/近期消息列表，
  提取重点消息、告警、审批和群聊未读内容，整理为 Markdown 摘要，并发送到用户本人的大象单聊会话。
  读取策略：窗口放大后先切到「未读」Tab，对有未读数的会话逐一点开并汇总最近 N 条消息（N 为未读条数）。
---

# codex-dx-unread-messages — 大象消息汇总并发送本人

读取大象桌面客户端 (`cn.neixin.pc`) **「未读」Tab** 下的未读会话（列表预览 + 逐会话打开读取最近 N 条，N 为未读数），整理为简洁摘要，并发送到接收人的大象单聊。

接收人不再写死默认值，按下列优先级解析：

1. 命令行显式传入（`bash scripts/summarize-and-send.sh <接收人>`）；
2. 本地 automan 客户端登录人：读取 `~/Library/Preferences/automan/config.json` 的 `operator` 字段；
3. 两者都拿不到时，脚本会退出并输出 `receiver_required` 错误，Agent 必须向用户询问「发送给谁」后再执行。

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

直接执行脚本，它会自动从 automan 本地登录人读取接收人：

```bash
bash "./scripts/summarize-and-send.sh"
```

若本地未登录 automan，或需要发送给其他人，显式传入接收人和摘要时间标签：

```bash
bash "./scripts/summarize-and-send.sh" "<接收人姓名>" "2026-08-03 21:55左右"
```

脚本成功时最后一行输出 JSON（`receiver` 字段回显实际使用的接收人）：

```json
{"ok":true,"receiver":"mashilei","inputIdx":210,"sentLikely":true}
```

若解析不到接收人，脚本会先退出并输出：

```json
{"ok":false,"error":"receiver_required","hint":"未指定接收人..."}
```

此时 Agent 必须向用户询问「发送给谁」后再重试。

## 稳定流程

1. 启动并验证 `cua-router-basic`：`daemon.sh start` + `exec.sh 'nodeRepl.write("ok")'`。
2. 先将大象 App 窗口放大到可用的大尺寸，再读取任何消息或定位元素：优先通过 `System Events` 设置 `process "大象"` 的 `window 1` 位置为 `{0, 33}`、尺寸为 `{1512, 850}`；如系统权限导致失败，必须明确报错并提示用户放大窗口后重试，不要在小窗口状态下继续发送。
3. 获取大象 App 状态：`sky.get_app_state({ app: "cn.neixin.pc", disableDiff: true })`。
4. 确认大象可访问：窗口标题包含 `大象`，左侧导航包含 `消息`。
5. **必须先切换到「未读」Tab**：在 AX Tree 中查找 `按钮 未读`（或 `文本 未读`），`sky.click` 后重新 `get_app_state({ disableDiff: true })`；找不到则报错并提示用户手动点「未读」后重试。
6. 在「未读」列表区（通常 idx 80～240）解析会话与未读数，并保留列表预览；勿从右侧聊天区或低 idx 导航取数：
   - 会话名称：`文本 <会话名>` 或 `container <会话名>`
   - 未读数：`[ N条 ]`、`N条未读`、`未读 N`（解析整数 N）
7. **逐会话下钻**：对每个 N > 0 的可见未读会话（单次建议最多 8～10 个）：
   - 点击列表中该会话行（每次重新解析 idx）
   - 等待约 900ms 后读取右侧聊天区（输入框 `说点什么` 之上）；聊天区是虚拟列表，首次打开可能只暴露最后一条，必须从消息区向上逐页滚动、每次重新读取 AX Tree 并去重，直到汇总**最近 N 条**有效消息或已无更多内容（单会话 N 上限建议 20）
   - 素材带来源名，如 `**群名**：正文…`
   - 再点「未读」Tab 回到列表，处理下一个
8. 重点保留以下类型：
   - PR / Code 仓库通知
   - P0/P1/P2/P3 告警和恢复
   - Talos 发布结果
   - 审批待办
   - 工作相关群聊高未读数
   - HR / 打卡提醒
6. 组织为 Markdown 中文摘要：`未读概览` + 扁平未读列表（不分组、不分类）。每个未读会话一项，使用 `- ` 列表；会话内最近 N 条消息用 `；` 分隔，单条消息截断至约 120 字，但不得因会话总长度限制而只保留最后一条；多个会话之间插入一行 `------------------------------------------------`；每条消息的来源（群名称、系统会话名）必须加粗，例如 `**大前端**：57条未读；...`；同一会话只保留一项，不重复展示。
7. 摘要生成前必须去噪：过滤历史 `大象消息汇总`、AX 类型前缀（`文本`/`text`/`container`）、纯时间、纯数字、导航项和过长链接，避免旧摘要被再次吸入。
8. 摘要生成前必须去噪：过滤历史 `大象消息汇总`、AX 类型前缀（`文本`/`text`/`container`）、纯时间、纯数字、导航项和过长链接，避免旧摘要被再次吸入。
9. 调用公共模块 `dx-send-markdown` 发送摘要（`skill.json` 声明 `"modules": ["dx-send-markdown"]`，安装后在 `modules/dx-send-markdown/scripts/send-markdown.sh`）：

```bash
printf '%s' "$summary" | bash "$SKILL_DIR/modules/dx-send-markdown/scripts/send-markdown.sh" \
  "$RECEIVER" --all-tab --marker "大象消息汇总|未读概览"
```

发送细节见 `modules/dx-send-markdown/MODULE.md`（最大化窗口、Markdown 编辑器、`set_value` 写入等）。

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

- **08.03-发布群-Automan**：5条未读；Talos Robot: Automan 开始发布
------------------------------------------------
- **大前端**：57条未读；…
------------------------------------------------
- Code PR：feat: Enhance brand configuration handling with alias fallback；bugfix-cj-0717 -> master
------------------------------------------------
- P3故障：com.sankuai.fst.qa.fe 504 告警，持续 47 分钟
```

强制要求：

- 不输出 AX 前缀：`文本`、`text`、`container`、`按钮`。
- 不把历史摘要内容再次纳入本次摘要。
- 不输出纯时间、纯数字、导航项。
- 链接只保留为“链接”或直接省略。
- 未读列表最多保留 10 个会话；每个会话必须尽量保留最近 N 条有效消息（N 为未读数，最多 20），每条消息可截断至约 120 字；同一会话只出现一次。

## 避坑清单

| 陷阱 | 现象 | 解决 |
|------|------|------|
| 使用错误 app id | `Invalid app` | 大象桌面客户端使用 `cn.neixin.pc` |
| 复用输入框 idx | 大象刷新后报 “user changed app” 或写错位置 | 每次发送前重新 `get_app_state` 并动态查找输入框 |
| 直接 `type_text`/剪贴板粘贴中文摘要 | 中文、标点、换行可能丢失，`pbcopy`/权限环境可能失败 | 只用 `sky.set_value` 写入 Markdown 编辑器的 `文本输入区` |
| 直接 Return 发送 | 消息按普通文本发送，Markdown 不渲染 | 先用 `System Events` 把大象窗口拉到全屏尺寸，再从最大化后的 AX Tree 中点击 `按钮 ` 打开 `Markdown编辑器` |
| 双击标题栏/顶部空白区最大化 | 大象窗口可能不响应双击，AX Tree 中找不到 `发送 Markdown 消息` | 不依赖双击；用系统窗口属性设置 `position {0,33}` 和 `size {1512,850}` |
| 误点聊天内容工具栏 / 右侧栏 | 找不到 Markdown 发送项或打开错误菜单 | 最大化后使用输入框前方工具栏里的 `按钮 `，不是未最大化状态下的 `按钮 ` |
| 首次打开会话只读取到最后一条 | 大象聊天区使用虚拟列表，较早未读消息尚未进入 AX Tree | 以聊天正文节点为滚动目标向上逐页滚动，每页重新读取并合并去重，直到达到未读数 N 或内容不再变化 |
| 操作后不重取 AX Tree | 读到旧状态，校验不准 | 每次 click / set_value 后重新获取 `disableDiff:true` |
| 只扫低 idx | 漏掉当前会话、输入框或浮层 | 始终在完整 `s.text` 上搜索 |
| 发送到群聊 | 当前会话未切到接收人本人 | 先点击左侧 `文本 <接收人>`（`send-markdown.sh` 会用解析后的姓名搜索），再确认标题或输入框存在 |
| 发送失败后盲目重发 | 可能重复消息 | 先重新读取状态，确认摘要是否已出现在会话中 |

## 输出要求

完成后向用户说明：

- 已读取并汇总大象当前可见未读/近期消息；
- 已发送到本人会话；
- 若 `sentLikely` 为 `false`，返回当前错误和建议用户确认大象窗口是否被手动切换。

## 边界

- 只汇总当前大象窗口可见的未读/近期消息列表和当前会话内容，不滚动读取全部历史。
- 不打开外部链接、不处理 PR、不审批、不处理告警，只做摘要转发。
- 接收人无写死默认值：优先取用户显式传入，其次读取 automan 客户端登录人（`~/Library/Preferences/automan/config.json.operator`），都拿不到时以 `receiver_required` 报错并要求 Agent 询问用户。
