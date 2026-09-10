# Automan Desktop RPA 新建 — AX 定位说明

本技能通过 `cua-router-basic` 的 `replay.sh` 执行；每步在**刷新 AX** 后按关键词定位同一行元素。

## 应用

- 使用路径：`/Applications/Automan Desktop.app`
- 避免仅用 bundleId 激活（多副本时可能 `activate_app_failed`）

## 「新建」按钮（工作流列表）

- **禁止**仅用 `["按钮","新建"]`：会匹配「新建任务」等 7+ 处。
- **规则**：AX 文本行满足 `^\s*\d+\s+按钮 新建\s*$`（行尾无后缀）。
- 脚本在 part1 前 `probe_ax`，要求**恰好 1 行**；`target` 使用该整行 trim 后的字符串。

## 「创建」按钮（弹窗）

- **禁止**仅用 `["按钮","创建"]`：会匹配「手动创建 / AI 创建」等单选。
- **规则**：`^\s*\d+\s+按钮 创建\s*$`。
- **必须在弹窗打开后**再 probe（part2）；列表页 probe 会得到 0 或多条错误候选。

## 名称输入

- `target`：`["文本栏", "例如：自动登录签到、批量表单填写"]`
- `strategies`：`set_value` 优先，`type_text` 降级（部分环境 `paste`/`pbcopy` 失败）
- verify 用名称前 8 字，避免与「新建工作流」标题冲突导致 `invalid_verification`

## 成功校验

- 最终 verify：**「编排区」**
- 不用「创建中」：过渡太快易 flaky

## 导航跳过

- 若 AX 已含「我的工作流」或 URL 含 `flow-rpa-agent`，跳过「自动化助手」点击
- 第二参数 `--resume` 强制跳过导航步

## 两阶段 replay

| 阶段 | 内容 |
|------|------|
| part1 | 激活 →（可选）自动化助手 → 唯一「新建」→ 填名称 |
| part2 | 弹窗内 probe 唯一「创建」→ 点击 → 校验编排区 |
