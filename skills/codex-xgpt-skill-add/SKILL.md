---
name: codex-xgpt-skill-add
description: >
  在 macOS 上通过 cua-router-basic 在 xgpt.sankuai.com 创建 Skill 并进入配置页。
  触发词：「新建 XGPT Skill」「xgpt 新建技能」「在 Bots 创建 Skill」「创建技能对象」。
---

# codex-xgpt-skill-add

在 XGPT/Bots 平台 Chrome 桌面端创建新的 Skill 对象，并等待进入配置页。

## 依赖

参照 `cua-router-basic` 的 `references/install.md` 与 `references/runtime-exec.md`。
执行前必须 `daemon.sh start` 且 `ensure-ready.sh` 输出 `ok`。

## 稳定操作脚本（优先）

```bash
bash "./scripts/create-skill.sh" "<skill-name>" ["<skill-description>"] ["<space-id>"]
```

示例：

```bash
bash ./scripts/create-skill.sh "skill-test-20260907" "test"
```

脚本成功时最后一行输出 JSON，例如：

```json
{"ok":true,"skillName":"skill-test-20260907","url":"xgpt.sankuai.com/space/SP57785706e8f74b84/agent/skills/cskill-xxx/config"}
```

## 输入参数

| 参数 | 说明 | 默认值 |
|---|---|---|
| `skill_name` | Skill 名称 | `skill-test-<YYYYMMDDHHMMSS>` |
| `skill_description` | Skill 简介 | `test` |
| `space_id` | 空间 ID | `SP57785706e8f74b84` |

## 主流程

1. 确保进入技能清单页 `/space/{space_id}/agent/skills`（若已在配置页则点左侧「Skill 技能」返回；若在首页则点「专家」→「Skill 技能」）。
2. 点击右侧「按钮 新建」，等待「创建Skill」弹层出现。
3. 填写「* Skill名称」：扫描定位 → 点击 → `set_value` → **`Tab` 失焦** → 刷新 AX 校验。
4. 填写「* Skill简介」：同上（`set_value` + **`Tab` 失焦**）。
5. **点击「确 定」前必须重扫 AX**：
   - 记录填写前/填写后「确 定」按钮 idx（检测是否因弹层滚动而偏移）；
   - `ax.get({ refresh: true })` 后 `findAllIdx("确","定","按钮")`；
   - 若定位失败，先 scroll 弹层再重扫；
   - 用**最新 idx** 点击，禁止复用填写前的缓存 index。
6. 等待 URL 包含 `/config`，或页面出现新 Skill 名称。

## 语义定位关键词

| 目标 | 关键词组 | 说明 |
|---|---|---|
| 主导航「专家」 | `["按钮", " 专家"]` | 空格+专家，避免命中「设计专家」 |
| 左侧「Skill 技能」 | `["Skill 技能"]` | |
| 右侧「新建」 | `["按钮 新建"]` | 单行精确匹配，避免列表项误命中 |
| 名称输入框 | `["* Skill名称", "文本栏"]` | |
| 简介输入区 | `["* Skill简介", "文本"]` | |
| 「确 定」 | `["确", "定", "按钮"]` | 点击前必须重扫 |

## 关键稳定策略

### 1. React 表单：`set_value` 后必须 `Tab` 失焦

仅 `set_value` 会让 AX 树显示 `Value:`，但 React 内部 state 可能未同步，导致点「确定」后弹层关闭却不创建 Skill。
**每个字段写入后必须 `press_key(Tab)` 触发 blur/onChange。**

### 2. 确定按钮：填写后重扫 AX

填简介时弹层可能滚动，「确 定」的 `element_index` 会从 64 漂移到 65/66。
**点击确定前强制 `refresh: true` 并重新语义定位，必要时 scroll 后再扫。**

### 3. 每步刷新，禁止复用 idx

所有 click / set_value / press_key 的目标 idx 必须来自**当前** AX 树，不得跨步骤缓存。

## 操作规范

遵循 `cua-router-basic` 主文件核心操作规范；Web 表单输入优先 `set_value` + `Tab` 失焦，Electron/WebView 不稳定时再降级 paste。

- 禁止用最终 config URL 直跳替代页面内点击和表单提交。
- 禁止跨轮次复用 `observationId` 或旧 `element_index`。
- 确定按钮是高风险动作：重扫 → 单步点击 → 刷新验证，结果不明时不重复点击。

## 失败处理

- 未登录、无权限或空间不存在：停止并报告 AX 可见错误文本。
- 语义定位不到目标：刷新 AX 重试；仍失败时输出缺失目标名与当前 URL。
- 弹层关闭但未进入 `/config`：报告名称/简介字段 AX 值、最后一次 URL、确定按钮扫描结果。

## 成功判定

- 最终 URL 包含 `/agent/skills/<id>/config`。
- 页面可见提交的 `skill_name`。
- 名称与简介已按参数写入并提交。
