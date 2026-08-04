---
name: codex-rpa-workflow-create
description: >
  RPA / Bots 工作流创建技能。当用户表达“新建一个工作流”“创建 RPA 工作流”“在 rpa.sankuai.com 新建编排模式工作流”
  “创建 bots 编排工作流”“新建空编排工作流”“新建名称为 XXX 的工作流”“create RPA workflow”
  “create bots workflow”“create orchestration workflow”等意图时激活。本技能只负责进入 RPA 首页、点击左侧工作流、
  新建一个可视化编排/编排模式的空工作流、填写名称、创建后验证画布仅包含开始节点和结束节点。
  不负责给工作流添加指令、配置元素选择器、调试运行、修复节点报错；这些属于 codex-workflow-command-test。
  不适用于普通代码仓库 workflow 文件、GitHub Actions、CI/CD pipeline 或数据构造 workflow。
---

# RPA 工作流创建

在 rpa.sankuai.com 创建一个空的可视化编排工作流，并验证创建结果。

## 触发判定

- 用户要求“新建/创建 RPA 工作流、bots 工作流、编排模式工作流、空编排工作流”时使用。
- 用户给出工作流名称，例如“新建一个名称为「自动化测试-移动端普通指令」的工作流”时使用。
- 只做工作流创建与空画布校验；如果用户还要添加指令或调试，创建完成后交给 `codex-workflow-command-test`。
- 不处理本地 XML / YAML / GitHub Actions / CI pipeline 这类代码工程工作流。

## 依赖

参照 `cua-router-basic` 技能的依赖说明和启动方式。所有浏览器自动化通过 `sky.*` API 执行。

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

## 主流程

1. 获取用户指定的工作流名称；若名称缺失，先询问。
2. 打开 RPA 首页 `https://rpa.sankuai.com/rpa/chat`，禁止直接访问 `/rpa/workflow`。
3. 点击左侧导航「工作流」，进入工作流列表页。
4. 点击「新建工作流」。
5. 在弹框中保持默认「手动创建」与「可视化编排」，在「名称」字段填入用户给定名称。
6. 确认「创建工作流」按钮可用后点击创建。
7. 进入配置页后验证：标题包含工作流名称，画布存在「编辑器容器」，且仅包含「开始节点」「结束节点」，没有业务指令节点。
8. 向用户返回创建成功、空编排校验结果和当前 URL。

## 稳定操作脚本

优先直接执行脚本，参数为工作流名称：

```bash
bash "./scripts/create-workflow.sh" "<工作流名称>"
```

示例：

```bash
bash ./scripts/create-workflow.sh "自动化测试-移动端普通指令"
```

脚本成功时最后一行输出 JSON：

```json
{"ok":true,"name":"自动化测试-移动端普通指令","emptyWorkflow":true,"url":"rpa.sankuai.com/.../workflow-xxx/config?subType=2"}
```

## 操作规范

- 每一次 click / set_value / press_key 后都必须重新 `get_app_state({ disableDiff: true })` 验证状态。
- Chrome URL 导航必须使用地址栏 `set_value` + `Return`，禁止 `type_text`。
- AX idx 每次从最新 AX Tree 重新获取，禁止复用旧 idx。
- 弹框按钮要通过完整 AX Tree 文案定位，不按固定 idx。
- 如果创建后没有进入画布，返回当前 AX 关键行并停止，不要盲目连点。

## 边界

- 不添加任何业务指令。
- 不配置节点表单。
- 不执行调试运行。
- 不发布工作流。
- 不创建非可视化编排/代码模式工作流，除非用户明确要求并确认。
