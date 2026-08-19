---
name: codex-workbuddy-workbench-create
description: "将录制的 WorkBuddy 桌面操作封装为可复用流程：打开 WorkBuddy，先点击左侧「新建任务」，进入日常办公的个人工作台，并提交工作台需求。"
---

# WorkBuddy 个人工作台执行技能

当用户需要复用“打开 WorkBuddy → 点击左侧新建任务 → 选择日常办公场景 → 选择个人工作台 → 输入需求 → 发送执行”的桌面操作时，使用本技能。

## 依赖

参照 `cua-router-basic` 的 `references/install.md` 与 `references/runtime-exec.md`。
执行 sky 操作前必须启动 `daemon.sh start` 并用 `nodeRepl.write("ok")` 验证。

## 输入参数

| 参数 | 说明 | 默认值 |
|---|---|---|
| `工作台需求` | 要填写到 WorkBuddy 输入区的自然语言需求 | `个人财物助手工作台` |

如果用户没有显式提供 `工作台需求`，直接使用默认值 `个人财物助手工作台`，不要再询问。

## 回放步骤

严格按录制链路回放，每步都要完成“定位 → 交互 → 校验”。

1. 打开或激活 WorkBuddy 桌面应用。
   - 目标应用：`com.workbuddy.workbuddy`。
   - 如果 WorkBuddy 已打开，则切换到当前 WorkBuddy 窗口。
   - 如果出现登录页、更新弹窗或权限确认，先停下并向用户说明需要处理。

2. 点击左侧菜单「新建任务」。
   - 打开应用后第一步必须点击左侧导航里的「新建任务」。
   - 点击后用 AX tree 校验「新建任务」处于选中状态，或主区域出现 WorkBuddy 输入区。
   - 这一步不可跳过，即使当前页面看起来已经在新建任务页。

3. 选择「日常办公」场景。
   - 在主区域场景切换位置定位「日常办公」。
   - 点击后校验「日常办公」为选中状态。

4. 选择「个人工作台」。
   - 在「日常办公」场景下定位「个人工作台 个人工作台」按钮。
   - 点击后校验输入区中出现「个人工作台」上下文，或出现「工作台搭建师」。

5. 定位需求输入区。
   - 优先定位包含「今天帮你做些什么？ @ 引用对话文件，/ 调用技能与指令」的 `文本输入区`。
   - 点击聚焦输入区后重新 `ax.get(app, { refresh: true })` 校验焦点。

6. 填写 `工作台需求`。
   - 目标控件是 Electron / Web 文本输入区，优先使用系统剪贴板粘贴：`/usr/bin/pbcopy` + `Command+A` + `Command+V`。
   - 粘贴后必须刷新 AX tree，校验输入区文本包含 `工作台需求`。
   - 默认需求是 `个人财物助手工作台`。

7. 点击发送 / 执行按钮。
   - 粘贴需求后重新定位输入区右侧的发送按钮。
   - 优先查找「发送」「执行」「提交」等语义按钮；如果按钮无文案，则使用输入区右侧相邻无名按钮。
   - 不要用 Return 代替发送。

8. 校验进入执行状态。
   - 先确认出现执行态文案，再确认输入内容已提交、输入框已清空或发送按钮已不可点击。
   - 成功信号包括出现「正在准备执行」「Agent 正在接手并进入工作状态」「内容由 AI 生成，请核实重要信息」或任务卡片进入生成状态。
   - 如果未进入执行状态，检查按钮是否不可用、需求是否未填入、是否未登录或网络异常。

## 参考回放代码片段

```bash
SKILL_ROOT="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic}"
[ -f "$SKILL_ROOT/SKILL.md" ] || SKILL_ROOT="${HOME}/.automan/skills/cua-router-basic"
[ -f "$SKILL_ROOT/SKILL.md" ] || SKILL_ROOT="${HOME}/.cursor/skills/cua-router-basic"
bash "$SKILL_ROOT/scripts/daemon.sh" start
bash "$SKILL_ROOT/scripts/exec.sh" 'nodeRepl.write("ok")'

export REQUEST="${1:-个人财物助手工作台}"
open -a WorkBuddy
printf '%s' "$REQUEST" | /usr/bin/pbcopy

bash "$SKILL_ROOT/scripts/exec.sh" -t 120000 '
const app = "com.workbuddy.workbuddy";
const wait = ms => new Promise(r => setTimeout(r, ms));
let s = await ax.get(app, { refresh: true });

let newTaskIdx = ax.findIdx(s.text, "新建任务");
if (newTaskIdx == null) throw new Error("未找到左侧菜单新建任务");
await sky.click({ app, element_index: newTaskIdx });
await wait(800);
s = await ax.get(app, { refresh: true });

let dailyIdx = ax.findIdx(s.text, "日常办公");
if (dailyIdx == null) throw new Error("未找到日常办公场景");
await sky.click({ app, element_index: dailyIdx });
await wait(800);
s = await ax.get(app, { refresh: true });

let workbenchIdx = ax.findIdx(s.text, "个人工作台", "个人工作台");
if (workbenchIdx == null) workbenchIdx = ax.findIdx(s.text, "个人工作台");
if (workbenchIdx == null) throw new Error("未找到个人工作台入口");
await sky.click({ app, element_index: workbenchIdx });
await wait(1000);
s = await ax.get(app, { refresh: true });

let inputIdx = ax.findIdx(s.text, "今天帮你做些什么");
if (inputIdx == null) inputIdx = ax.findIdx(s.text, "文本输入区");
if (inputIdx == null) throw new Error("未找到需求输入区");
await sky.click({ app, element_index: inputIdx });
await wait(200);
await sky.press_key({ app, key: "Command+a" });
await wait(200);
await sky.press_key({ app, key: "Command+v" });
await wait(800);
s = await ax.get(app, { refresh: true });

const request = process.env.REQUEST;
if (!s.text.includes(request)) throw new Error("需求未成功填入");

let sendIdx = ax.findIdx(s.text, "发送");
if (sendIdx == null) sendIdx = ax.findIdx(s.text, "执行");
if (sendIdx == null) {
  const candidates = ax.findAllIdx(s.text, "按钮").map(x => x.idx).filter(idx => idx >= 100);
  sendIdx = candidates[candidates.length - 1];
}
if (sendIdx == null) throw new Error("未找到发送按钮");
await sky.click({ app, element_index: sendIdx });
await wait(2500);

s = await ax.get(app, { refresh: true });
const hasRunningState = /正在准备执行|Agent 正在接手|进入工作状态|内容由 AI 生成/.test(s.text);
const requestStillInInput = s.text.includes(request);
const ok = hasRunningState && !requestStillInInput;
nodeRepl.write(JSON.stringify({ ok, hasRunningState, requestStillInInput }));
'
```

## 注意事项

- 不要擅自改写用户的工作台需求，除非用户要求优化措辞。
- 未提供需求时不要追问，直接使用默认值 `个人财物助手工作台`。
- 点击发送前必须重新定位发送按钮，不要复用旧的 element index。
- 如果 WorkBuddy 弹出权限、更新、登录、确认等对话框，应停止并让用户确认。

## 成功标准

- WorkBuddy 已打开。
- 已点击左侧「新建任务」。
- 已进入「日常办公」场景。
- 已选择「个人工作台」。
- 已填入工作台需求。
- 已点击发送并进入执行或处理中状态。
