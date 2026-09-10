---
name: codex-desk-rpa-generate
description: >
  Automan Desktop 客户端 RPA 工作流创建技能。当用户说「桌面新建 RPA 工作流」「Automan 里 codex 生成工作流」
  「自动化助手新建编排工作流」「desk rpa generate」「在 Automan 客户端创建工作流」等意图时激活。
  通过 cua-router-basic 的 replay 在 Automan Desktop 内：进入自动化助手 → 新建 → 填写名称 → 创建，
  并校验进入编排区。不负责 Chrome/rpa.sankuai.com 浏览器建流（见 codex-rpa-workflow-create），
  不负责粘贴节点或指令生成（见 codex-rpa-workflow-generate）。
---

# Automan Desktop 新建 RPA 编排工作流

在 **Automan Desktop**（`/Applications/Automan Desktop.app`）内复用录制验证过的桌面回放链路，创建空编排工作流并进入 **编排区**。

## 与相关技能的分工

| 技能 | 场景 |
|------|------|
| **本技能** | Automan **桌面客户端** → 自动化助手 → 新建工作流 |
| `codex-rpa-workflow-create` | **Chrome** 打开 rpa.sankuai.com 建空编排 |
| `codex-rpa-workflow-generate` | 已有空编排后 API/剪贴板批量生成节点 |
| `record-desk-basic` | 录制桌面操作；本技能为其「转技能」产物之一 |

## 触发判定

- 用户要在 **Automan 客户端** 新建 RPA / 编排工作流。
- 用户提到 `codex生成工作流`、桌面自动化助手、flow-rpa-agent 等。
- 用户未指定浏览器 RPA 站点时，若上下文是 Automan Desktop，优先本技能。

## 依赖

参照 `cua-router-basic`：执行前 `ensure-ready.sh` 输出 `ok` 后再调用 `replay.sh` / `exec.sh`。

```bash
CUA_ROOT="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic}"
[ -f "$CUA_ROOT/SKILL.md" ] || CUA_ROOT="${HOME}/.cursor/skills/cua-router-basic"
bash "$CUA_ROOT/scripts/ensure-ready.sh"
```

## 输入参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `工作流名称` | 新建弹窗「名称」字段全文 | `codex生成工作流-「date」` |
| `skip_nav` | 已在 RPA 页（含「我的工作流」）时跳过「自动化助手」步 | 由脚本自动检测 |

未提供名称时使用默认 `codex生成工作流-「date」`（字面包含「date」占位符，与录制一致；若需真实日期由用户指定名称）。

## 主流程

1. 解析工作流名称（缺省用默认值）。
2. 执行 `scripts/create-desk-workflow.sh "<名称>"`。
3. 脚本内部：必要时激活 Automan → 点「自动化助手」（若已在 RPA 则跳过）→ **动态定位**「我的工作流」区唯一「新建」→ 填名称 → 点弹窗「创建」。
4. 成功标准：AX 含工作流名称片段 + **「编排区」**（不用「创建中」，过渡太快易失败）。
5. 向用户返回 JSON：`ok`、`name`、`url`（若有）、`inEditor`。

## 稳定操作脚本

```bash
bash "./scripts/create-desk-workflow.sh" "我的工作流-测试"
```

成功时最后一行 JSON 示例：

```json
{"ok":true,"name":"我的工作流-测试","inEditor":true,"url":"automan://frontend/.../flow-rpa-agent"}
```

## AX 定位要点（必读）

详见 [references/replay-locate.md](references/replay-locate.md)。

- **应用路径**：用 `/Applications/Automan Desktop.app`，避免 bundleId 多副本 `activate_app_failed`。
- **「新建」按钮**：禁止仅用 `["按钮","新建"]`（会匹配「新建任务」等 7+ 处）；脚本用正则 `\d+ 按钮 新建` 且行尾无后缀。
- **「创建」按钮**：禁止仅用 `["按钮","创建"]`（含「手动创建/AI 创建」单选）；脚本用 `\d+ 按钮 创建` 且非「单选按钮」行。
- **输入**：优先 `set_value`，`paste` 在部分环境 `pbcopy` 失败。
- **verify**：动作前页面已存在 verify 关键词会 `invalid_verification`；已在 RPA 页时不要重复点自动化助手。

## 边界

- 不处理 SSO「正在跳转…」；未登录时停下请用户登录。
- 不添加编排节点、不调试运行、不发布工作流。
- 不替代 Chrome 版 RPA 创建。

## 失败处理

- `target_ambiguous` / `target_not_found`：刷新 AX 后重跑脚本；仍失败则把失败 step 与 `references/replay-locate.md` 给用户。
- `invalid_verification`：说明当前已在目标页，用 `--resume` 或脚本自动 skip 导航步重试。
