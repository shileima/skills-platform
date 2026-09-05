---
name: codex-update-codex-skills
description: >
  将 skills-platform 源码目录中的 codex 技能打包为 zip 并上传到 xgpt.sankuai.com 更新已有 Skill。
  当用户说「更新 codex 技能」「上传技能到 xgpt」「发布 skill 到 XGPT/Bots 平台」「更新 skills-platform 里的技能」
  「把 codex-xxx 技能同步到 xgpt」「xgpt 更新技能」「发布 Skill 到专家空间」等意图时激活。
  技能源码默认位于 skills-platform 仓库的 skills/<name>/ 目录，例如 skills/codex-catdesk-new-task。
  不负责新建 Skill（见 codex-xgpt-skill-add）；只负责打包已有源码并覆盖更新平台上同名 Skill。
---

# 更新 Codex 技能到 XGPT 平台

将 `skills-platform` 中的 codex 技能打包为 zip，上传到 xgpt.sankuai.com 并发布。

## 触发判定

- 用户要求更新/上传/发布某个 codex 技能到 xgpt / XGPT / Bots 平台。
- 用户给出技能目录名（如 `codex-catdesk-new-task`）或路径 `skills/<name>/`。
- 只做「打包 → 上传 → 发布」；新建 Skill 交给 `codex-xgpt-skill-add`。
- 不修改源码、不 bump 版本（除非用户另行要求）。

## 依赖

参照 `cua-router-basic`。执行前：

```bash
SKILL_ROOT="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic}"
[ -f "$SKILL_ROOT/SKILL.md" ] || SKILL_ROOT="${HOME}/.cursor/skills/cua-router-basic"
bash "$SKILL_ROOT/scripts/ensure-ready.sh"
```

输出 `ok` 后才继续。

## 稳定执行入口

**优先直接跑一键脚本**，不要手写逐步 sky 操作：

```bash
bash "./scripts/update-skill-on-xgpt.sh" "<skill_name>"
```

示例：

```bash
bash ./scripts/update-skill-on-xgpt.sh codex-catdesk-new-task
```

仅打包到桌面：

```bash
bash ./scripts/pack-to-desktop.sh codex-catdesk-new-task
```

成功时最后一行 JSON：

```json
{"ok":true,"step":"done","skillName":"codex-catdesk-new-task","zipPath":"/Users/shilei/Desktop/codex-catdesk-new-task_0.0.1.zip","published":true,"version":"…当前展示为最新版本：v 0.0.2"}
```

## 实测稳定流程（codex-catdesk-new-task 已验证）

0. `skilldev pack` → zip 复制到 `~/Desktop/`
1. 打开 `https://xgpt.sankuai.com/space/SP57785706e8f74b84/agent/skills`
2. 点击清单页卡片 `按钮 <skillName> 技能`（**不要** hover 编辑 icon）
3. 详情页点击 `按钮 编辑` → 进入 `/config` 配置页
4. 配置页工具栏点击「**导入**」icon（向上箭头，AI 助手右侧；**不是** AI 助手 robot icon）→「创建Skill」弹层
5. 在弹层切换到「**上传**」tab → 点击「立即上传」
6. macOS「打开」对话框：侧边栏「桌面」→ ListView 点击 → `type_text` zip 前缀 → 点「打开」
7. 右上角「发布」→ 弹层「发布Skill」

详细 AX 信号、失败对照见 [reference/stable-flow.md](reference/stable-flow.md)。

## 输入参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `skill_name` | `skills-platform/skills/<name>/` 目录名 | 必填 |
| `zip_path` | 已打包 zip 绝对路径 | 自动 pack-to-desktop |
| `space_id` | XGPT 空间 ID | `SP57785706e8f74b84` |

`skill_name` 须与 `skill.json` 的 `name` 及平台卡片名一致。

## 操作规范（强制）

| 操作 | 正确 | 禁止 |
|------|------|------|
| 进入配置 | 卡片 → 详情 → `按钮 编辑` | hover + 编辑 icon；`perform_secondary_action`（Invalid params） |
| 导入 | 工具栏**导入↑ icon**（`下架/上架` 前第 2 个无 label 按钮，≈ shelf−5；**不是** AI 助手） | 点到 AI 助手 |
| 选 zip | ListView + type-ahead + OKButton | `osascript` Cmd+Shift+G（-10827）；双击 zip 行 |
| 每步 sky 动作前 | `ax.get(..., { refresh: true })` | 复用旧 idx |
| URL 导航 | 地址栏 `set_value` + Return | `type_text` 写地址栏 |
| 失败 | 读 JSON 的 `step` + `hints`，查 reference | 盲目连点 |

## 打包

- `SKILLS_PLATFORM_ROOT` 默认 `~/code/skills-platform`
- zip 命名：`<automan.metaName>_<version>.zip` → `~/Desktop/`

## 边界

- 不新建 Skill（见 `codex-xgpt-skill-add`）
- 不修改源码 / 不 bump 版本（除非用户要求）
- 不上传含密钥的 zip
