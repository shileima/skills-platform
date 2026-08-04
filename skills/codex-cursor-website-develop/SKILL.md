---
name: codex-cursor-website-develop
description: >
  Cursor 桌面客户端网站开发技能。通过 Cursor 的 New Agents Window 新建独立 Agent 窗口，选择或创建本地项目文件夹，
  默认让 Cursor Agent 新建一个简洁功能版社区站点前端工程。当用户说“用 Cursor 新建网站/前端工程/社区站点/website develop”、
  “打开 Cursor Agent 创建项目”“在 Cursor 里新建一个前端社区站点”等意图时激活。
---

# codex-cursor-website-develop — Cursor 网站开发技能

在本地 Cursor 应用中打开 `New Agents Window`，新建项目目录并向 Cursor Agent 发送建站需求。默认需求为：

> 帮我新建一个前端工程，功能为简洁功能社区站点

## 依赖

参照 `cua-router-basic` 技能的依赖说明和启动方式。所有桌面操作优先通过 `sky.*`、macOS 菜单和 Accessibility 执行。

执行前必须验证：

```bash
SKILL_ROOT="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/skills/cua-router-basic}"
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  SKILL_ROOT="${HOME}/.cursor/skills/cua-router-basic"
fi
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  SKILL_ROOT="${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic"
fi
bash "$SKILL_ROOT/scripts/daemon.sh" start
bash "$SKILL_ROOT/scripts/exec.sh" 'nodeRepl.write("ok")'
```

输出 `ok` 后才继续操作 Cursor。

## 何时激活

用户要求在 Cursor 中：

- 新建网站、前端工程、前端项目
- 新建社区站点、功能社区站点、简洁社区站点
- 打开 Cursor Agent / Agents Window 开发项目
- 指定项目目录名并要求 Cursor Agent 开始实现

## 一键执行

```bash
bash "./scripts/create-community-site.sh" "[项目名称]" "[需求描述]"
```

示例：

```bash
bash ./scripts/create-community-site.sh
bash ./scripts/create-community-site.sh "new-curor-project" "帮我新建一个前端工程，功能为简洁功能社区站点"
```

默认参数：

- 项目名称：`new-curor-project`
- 需求描述：`帮我新建一个前端工程，功能为简洁功能社区站点`

如果项目名称已存在，脚本必须取消覆盖，并依次尝试 `new-curor-project-1`、`new-curor-project-2`、`new-curor-project-3` 等可用名称，禁止点击「替换」。

成功时输出 JSON，例如：

```json
{"ok":true,"project":"new-curor-project-1","prompt":"帮我新建一个前端工程，功能为简洁功能社区站点","status":"sent"}
```

## 稳定流程

1. 启动并验证 `cua-router-basic`：`daemon.sh start` + `nodeRepl.write("ok")`。
2. 使用 `open -a "Cursor"` 打开本地 Cursor。
3. 使用 macOS 菜单选择：顶部菜单「文件」→ `New Agents Window`。优先走 AppleScript 菜单项，不通过命令面板搜索；如果菜单项不存在或不可点，但当前已在 `Cursor Agents` 旧会话中，则点击顶部 `New Agent` 按钮进入新建聊天页。
4. 等待窗口标题变为 `Cursor Agents`，确认聊天输入框出现。新建聊天页通常包含 `Plan, Build, / for skills, @ for context`；旧会话可能只显示 `Send follow-up`，此时必须先点 `New Agent`，不要把需求发到旧会话。
5. 点击聊天左上角项目下拉（当前项目名，如 `waimai-qa-aie-fe`）。
6. 在下拉菜单点击 `New Folder`。
7. 在系统保存面板中输入项目名并创建。
8. 如果出现“项目已存在，是否替换”警告：
   - 必须点击「取消」或按 `Escape`
   - 不允许点击「替换」
   - 重新选择 `New Folder`，使用下一个后缀名称，例如 `new-curor-project-1`、`new-curor-project-2`
9. 确认左上角项目下拉显示最终项目名。
10. 将需求描述粘贴到聊天输入框。中文输入必须使用剪贴板粘贴，不要使用 `type_text` 直接输入中文。
11. 直接发送消息，无需再次询问用户。
12. 验证聊天区出现用户消息，并出现 `Planning next moves`、`Stop generation` 或类似生成状态。

## 关键实现约定

- Cursor app bundle id 通常为 `com.todesktop.230313mzl4w4u92`，窗口名为 `Cursor Agents`。
- `sky.type_text` 输入中文可能丢字，中文提示词必须用：
  ```bash
  osascript -e 'set the clipboard to "..."'
  ```
  然后 `Command+A`、`Command+V`。
- `sky.set_value` 不同版本参数名可能不一致，遇到 `elementIndex must be an integer` 时不要继续重试，改用剪贴板粘贴。
- 每次用户或系统改变 Cursor 状态后，先重新 `get_app_state({ disableDiff: true })`，避免触发 `The user changed '/Applications/Cursor.app'`。
- 不要只用 `Plan, Build` 判断失败：旧会话、生成中或发送后的输入框可能显示 `Send follow-up`。如果打开后停在旧聊天，先点 `New Agent`，直到出现新建输入框再创建项目。
- AppleScript 菜单项 `New Agents Window` 可能因当前菜单语言/窗口状态不可获得；菜单失败时不要终止，应在当前 `Cursor Agents` 窗口中用 Swift + Accessibility 定位并坐标点击顶部 `New Agent` 按钮。
- `sky.click({ text: "New Agent" })` 可能报 `coordinate must include finite x and y coordinates`，遇到该错误不要反复重试，改用 Swift + Accessibility 读取按钮坐标后 CoreGraphics 点击。
- 点击 `New Folder`、项目下拉等 Electron/HTML 内元素时，AX index 可能不能直接 `sky.click`；可用 Swift + Accessibility 获取元素坐标后通过 CoreGraphics 点击。
- 任何已存在目录冲突都要取消并递增后缀，避免覆盖用户已有项目。

## 边界

- 本技能只负责打开 Cursor Agent、创建/选择项目目录、发送开发需求。
- 不直接在文件系统中生成网站代码；代码实现由 Cursor Agent 完成。
- 不覆盖已有项目目录。
- 不负责等待 Cursor Agent 完整开发结束，除非用户明确要求继续跟进。
