# XGPT Skill 更新 — 实测稳定流程

基于 `codex-catdesk-new-task` 同步成功（v 0.0.2）沉淀。Agent 执行脚本时不必读本文件；排查失败步骤时再 Read。

## 页面状态机

```
技能清单 /agent/skills
  → 点击「按钮 <skillName> 技能」
详情页 /agent/skills/cskill-xxx
  → 点击「按钮 编辑」
配置页 /agent/skills/cskill-xxx/config
  → 工具栏「导入」→「创建Skill」弹层 →「上传」tab →「立即上传」
  → macOS「打开」对话框 → 选 zip → 回到 config
  → 「按钮 发布」→「发布配置」→「按钮 发布Skill」
详情页（发布成功后可能跳回，含「当前展示为最新版本：v x.y.z」）
```

已在 `/config` 时可跳过清单导航；已在目标 Skill 详情页且 AX 含 `skillName` 时只需点「编辑」。

## AX 定位要点

| 目标 | 稳定信号 | 禁止 |
|------|----------|------|
| 技能卡片 | `按钮 <skillName> 技能` | hover + 编辑 icon（无 hover API；swift 在 exec 环境不稳定） |
| 进入配置 | `按钮 编辑` → URL 含 `/config` | `perform_secondary_action`（报 Invalid params） |
| 导入 icon | `下架/上架` 前工具栏第 2 个无 label `按钮`（≈ shelf−5；第 1 个是 AI 助手） | 点到 AI 助手 |
| 弹层上传 tab | `单选按钮 上传` | 与工具栏「导入 icon」混淆 |
| 上传 tab | `单选按钮 上传` | — |
| 选 zip | ListView 点击 → `type_text` 前缀 → `OKButton` 非 disabled | `osascript` Cmd+Shift+G（-10827）；双击 zip 行（会进入 zip 内部） |
| 发布 | `按钮 发布` → `按钮 … 发布Skill` | 点击 container「发布配置」 |

## 文件选择框（macOS Open Panel）

1. 侧边栏 `row (selectable) 桌面`（若列表中尚无 zip）
2. 点击 `ListView` / `列表视图`
3. `type_text` 输入 zip 前缀（如 `codex-catdesk-new-task`）
4. 确认 `row (selected)` 含目标 `.zip` 且 `OKButton` 非 disabled
5. 点击「打开」

## 失败步骤对照

| step | 常见原因 |
|------|----------|
| `open-skills-page` | 未登录、无空间权限 |
| `find-skill-card` | 平台无同名 Skill → 先用 `codex-xgpt-skill-add` 新建 |
| `find-import-button` | 不在编辑视图；检查是否有「标签 (selected) 编辑」 |
| `select-zip-file` | zip 未在桌面；pack 失败；type-ahead 前缀不匹配 |
| `publish-verify` | 版本号冲突；弹层未关闭 |

## 脚本输出

成功 JSON 示例：

```json
{
  "ok": true,
  "step": "done",
  "skillName": "codex-catdesk-new-task",
  "zipPath": "/Users/shilei/Desktop/codex-catdesk-new-task_0.0.1.zip",
  "url": "xgpt.sankuai.com/space/SP57785706e8f74b84/agent/skills/cskill-082f6ca9-f",
  "published": true,
  "version": "\t\t\t\t\t\t68 text 私有  当前展示为最新版本：v 0.0.2"
}
```
