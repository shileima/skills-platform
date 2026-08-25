---
name: codex-catdesk-new-task
description: >
  CatDesk 桌面客户端新建任务技能：按录制链路打开/激活 CatDesk，点击「新任务」，选择 Max 模型，
  在聊天输入框输入需求并点击发送。由 record-desk-basic 录制生成，依赖 cua-router-basic / sky Computer Use
  逐步回放。用户说「CatDesk 新建任务」「在 CatDesk 提交需求」「用 CatDesk 问 X」「执行 CatDesk 任务 X」时激活。
---

# codex-catdesk-new-task — CatDesk 新建任务并发送需求

本技能复用一次真实桌面录制，将 CatDesk (`com.catpaw.cowork`) 中“点击 Dock 的 CatDesk → 点击新任务 → 打开模型选择 → 选择 Max → 输入需求 → 点击发送”的操作封装为可复用流程。

## 依赖

参照 `cua-router-basic` 的 `references/install.md`、`references/runtime-exec.md` 与 `references/input-keyboard.md`。
执行前必须启动 cua-router：

```bash
SKILL_ROOT="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic}"
[ -f "$SKILL_ROOT/SKILL.md" ] || SKILL_ROOT="${HOME}/.automan/skills/cua-router-basic"
[ -f "$SKILL_ROOT/SKILL.md" ] || SKILL_ROOT="${HOME}/.cursor/skills/cua-router-basic"
bash "$SKILL_ROOT/scripts/ensure-ready.sh"
```

输出 `ok` 后才继续调用 `sky.*` / `ax.*`。

## 触发判定

当用户表达以下意图时使用：

- 「CatDesk 新建任务」
- 「在 CatDesk 提交需求」
- 「用 CatDesk 问一下 X」
- 「打开 CatDesk，输入 X 并发送」
- 「复用刚才 CatDesk 录制」

## 输入参数

| 参数 | 是否必需 | 默认值 | 说明 |
|---|---:|---|---|
| `prompt` | 否 | `北京降雨分时` | 要发送到 CatDesk 聊天输入框的任务内容 |

## 一键执行

```bash
bash "./scripts/run-catdesk-new-task.sh" "北京降雨分时"
```

不传参数时使用录制默认值：

```bash
bash "./scripts/run-catdesk-new-task.sh"
```

脚本成功时输出 JSON，包含 `ok: true`、`prompt` 和逐步回放日志。

## 录制动作时间线

录制会话：`D385E209-02CA-4935-BB8B-6F9F60C7EC70`。

| 顺序 | 录制事件 | 回放要求 |
|---:|---|---|
| 1 | 点击程序坞里的 `CatDesk` | 必须先在 Dock AX Tree 中定位 `CatDesk` 并点击；不要假设 CatDesk 已在前台 |
| 2 | 点击 CatDesk 内的 `新任务` 按钮 | 操作前取 CatDesk AX Tree；定位 `按钮 新任务`；点击后验证出现 `聊天输入框` |
| 3 | 点击页面区域打开模型选择列表 | 定位模型弹出式按钮（如 `LongCat-2.0` / `Max`），点击后验证列表出现 `Lite` / `Pro` / `Max` |
| 4 | 点击页面区域选择 `Max` | 定位 `Max 适合超复杂任务`，点击后验证模型区域为 `Max` |
| 5 | 在 `聊天输入框` 输入录制文本 | 将录制默认值抽成 `prompt` 参数；定位 `聊天输入框` 后写入并验证 AX Tree 出现 prompt |
| 6 | 点击发送按钮 | 重新取树定位发送按钮；点击后验证消息区出现 prompt，且页面进入思考/回复/输入框清空状态 |

## 回放执行纪律

每个 action 必须执行完整闭环，禁止跳步：

1. **操作前**：`ax.get(app, { refresh: true })` 审视最新 AX Tree，记录目标节点的 role、文案和 `element_index`。
2. **执行**：只做当前录制动作对应的一个交互；不合并下一步。
3. **操作后**：再次 `ax.get(app, { refresh: true })` 验证上一步生效。
4. **规划下一步**：基于最新 AX Tree 重新定位，不复用旧 `element_index`。

不得用最终状态替代中间 UI 操作；例如不能因为最终能发送消息，就跳过「新任务」或「选择 Max」这两个录制动作。

## 稳定脚本流程

`./scripts/run-catdesk-new-task.sh` 内部使用 `cua-router-basic/scripts/exec.sh -f` 执行确定性 JS 状态机：

1. 解析并启动 `cua-router-basic`。
2. 使用 `/usr/bin/open -a CatDesk` 激活 CatDesk，并轮询最新 AX Tree，直到看到 `新任务`。
3. 读取 CatDesk AX Tree，定位并点击 `新任务`。
4. 定位模型弹出式按钮，点击打开模型列表。
5. 定位 `Max` 选项，点击选择；若无法确认 Max，必须停止并返回错误，不得继续发送。
6. 定位可写的 `聊天输入框`，通过 `/usr/bin/pbcopy` + `Command+a` / `Command+v` 稳定粘贴 `prompt`。
7. 重新定位发送按钮并点击。
8. 校验页面中存在本次 `prompt`。

## 失败处理

- Dock 中找不到 `CatDesk`：停止并提示用户确认 CatDesk 已安装且可从 Dock 激活；不要静默改用其他应用。
- 点击 `新任务` 后未出现 `聊天输入框`：停止并返回 AX 关键行，避免继续误发。
- 模型列表没有 `Max`：停止，提示 UI 或权限状态与录制不一致。
- 写入后 AX Tree 没有出现 `prompt`：停止，不点击发送。
- 点击发送后没有消息、思考、回复、停止生成、重新生成或输入框清空等发送后证据：停止，不重复点击发送按钮，避免重复提交。

## 成功标准

- CatDesk 已激活。
- 已点击 `新任务`。
- 模型为 `Max`。
- 已将 `prompt` 写入聊天输入框。
- 已点击发送。
- 消息区出现本次 `prompt`，并出现思考、回复、停止生成、重新生成或输入框清空等发送后证据。
