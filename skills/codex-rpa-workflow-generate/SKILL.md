---
name: codex-rpa-workflow-generate
description: >
  RPA 编排工作流自动生成技能。当用户表达「生成编排工作流」「自动生成 bots 工作流指令」
  「根据场景编写空编排工作流」「B站/携程/比价工作流自动生成」「测试打开网页输入文本点击刷新」
  「workflow generate」「auto build rpa workflow」「paste workflow nodes」等意图时激活。
  根据用户场景或指令计划，调用 digitalgateway API 构建 rpaNode JSON，
  通过编辑器剪贴板协议批量粘贴到空编排工作流（可自动创建空工作流）。
  生成完成后交给 codex-workflow-command-test 做检查与调试。
  不适用于 GitHub Actions、CI pipeline、本地代码 workflow 文件。
---

# RPA 编排工作流自动生成

根据用户场景或指令计划，**构建节点 JSON → 剪贴板粘贴**到空编排工作流，跳过逐条搜索插入。

## 重要规范（强制）

> 🚫🚫🚫 **首次生成必须走「组装 JSON → 剪贴板粘贴」，禁止走 UI 逐条插入。**

| 阶段 | 允许路径 | 禁止路径 |
|------|---------|---------|
| **首次生成** | 写 plan → `build-nodes.mjs` / `build-composite-workflow.mjs` 组装 JSON → `wrap-clipboard.mjs` → `generate-workflow.sh` 粘贴 | 激活 command-test 用「指令 Tab 搜索 + 双击」逐条插入节点 |
| **调试后修复** | 优先 `--clear-and-paste` 重贴修正后的 JSON；单节点定位/表单微调可走 command-test UI | 首次生成阶段提前用 UI 插节点 |
| **单点修复** | 双击节点 → 「新建 LLM」改定位 → 保存；或右击「此处开始调试」 | 为修一个节点而清空重走 UI 全量插入 |

**铁律**：

1. **第一次**往空编排 canvas 写业务节点，**只能**通过剪贴板协议（`__JSON_DATA__...__JSON_DATA__`）批量粘贴；含 IF/ELSE 等容器节点时，用 `build-composite-workflow.mjs` 组装完整 JSON 再粘贴，**不得**改用 UI 搜索插入逻辑节点。
2. **粘贴完成并验证 canvas 摘要后**，才激活 `codex-workflow-command-test` 做检查 → 调试 → 修复。
3. **调试报错后的修复**：优先改 plan / formData → `--clear-and-paste` 重贴；仅当 JSON 无法表达（如 LLM 定位微调、单字段条件必填）时，才在 command-test 里用 UI 双击节点、新建 LLM、保存。
4. **禁止**在首次生成阶段以「IF/ELSE 复杂」「指令搜不到」等理由跳过 JSON 路线——应扩展 plan、扩展 `ALLOWED_UNION_IDS` 或写 composite 组装脚本，仍走粘贴。

```
首次生成：plan.json → build JSON → clipboard → paste → canvas 验证
调试修复：command-test 检查/调试 → 改 JSON 重贴 或 UI 单点修复
```

## 与相关技能的分工

| 技能 | 职责 |
|------|------|
| **本技能** | 场景规划 → API 构建节点 → 剪贴板批量粘贴 |
| `codex-rpa-workflow-create` | 创建空工作流（本技能可自动调用） |
| `codex-workflow-command-test` | 粘贴后 **检查 → 调试 → 修复**（必须交接） |

## 触发判定

- 用户提供自动化场景：「查携程杭州机票」「天猫京东比价 iPhone」
- 用户指定测试指令：「生成打开网页、输入文本、点击、刷新四步工作流」
- 用户已在空编排页，要求批量写入节点
- **不处理**：工作流发布、LoopElements/UploadFile/移动端指令（一期不支持）

## 依赖

- `cua-router-basic`：粘贴阶段的 Chrome 自动化
- Automan 本地鉴权：`~/Library/Preferences/automan/config.json` → `xcAuth`
- 可选：`codex-rpa-workflow-create`（自动建空工作流）

执行前：

```bash
SKILL_ROOT="${HOME}/.cursor/skills/codex-rpa-workflow-generate"
bash "$SKILL_ROOT/scripts/ensure-ready.sh"   # 输出 ok
```

## 主流程

```
1. Read reference/scenario-planner.md → 解析用户意图
2. 写出 instruction-plan.json（见 reference/examples/bilibili-plan.json）
3. bash scripts/generate-workflow.sh --plan instruction-plan.json（内含 validate-built-nodes 校验）
4. 验证粘贴结果（canvas 摘要顺序）
5. 激活 codex-workflow-command-test → 检查 → 调试 → 修复
6. **修复迭代**：用 `--clear-and-paste` 清空 canvas 后重贴，**禁止**每次新建工作流；调试失败时展开聊天区 **「更多详情」** 或 **「展开详情」** 读 `rootExceptionMessage`（见 command-test `debug.md`）

> 步骤 3 的 `--clear-and-paste` 仍属 **JSON 粘贴路线**；步骤 5 之后的单点 UI 修复见上文 §重要规范。

清空 canvas 策略见 [reference/clear-canvas.md](reference/clear-canvas.md)：**选中开始节点 → Control+a → Delete** 批量清空；残留节点 **hover 行 → 点右侧删除图标** 逐条删除。
```

调试若遇 `WaitPageState doesn't support the "timeout" attribute`，见 [reference/form-data-rules.md](reference/form-data-rules.md)。

### 步骤 1：场景规划（Agent 推理）

从用户消息提取 `instructionPlan`：

- 指令 `unionId`：OpenUrl、NavigateToUrl、FillText、ClickElementMixed、ReloadPage、GetText、Verify*、Wait* 等（一期 Web 原子指令）
- 每条 `params`：url、text、selector.alias（LLM 自然语言定位）
- 用户显式指令名优先于场景默认（见 `codex-workflow-command-test/reference/user-intent.md`）

元素 alias 格式：**位置 + 目标元素 + 操作意图**

### 步骤 2：构建 + 粘贴

```bash
SKILL_ROOT="${HOME}/.cursor/skills/codex-rpa-workflow-generate"

# 完整流程（自动建空工作流 + 粘贴）
bash "$SKILL_ROOT/scripts/generate-workflow.sh" \
  --plan /tmp/instruction-plan.json \
  --workflow-name "Bilibili搜索-自动生成"

# 仅构建 JSON（不粘贴）
bash "$SKILL_ROOT/scripts/generate-workflow.sh" \
  --plan /tmp/instruction-plan.json \
  --build-only

# 已在空编排页，跳过创建
bash "$SKILL_ROOT/scripts/generate-workflow.sh" \
  --plan /tmp/instruction-plan.json \
  --no-create

# 修复迭代：清空 canvas 业务节点后重贴（不新建工作流）
bash "$SKILL_ROOT/scripts/generate-workflow.sh" \
  --plan /tmp/instruction-plan.json \
  --clear-and-paste
```

### 步骤 3：交接调试（强制）

粘贴成功后 **必须** 激活 `codex-workflow-command-test`：

1. 点「检查」→ 无配置异常
2. 顺序终检 + 配置 icon 终检
3. 「调试 → 运行」→ 四处扫描报错 → 修复

本技能**不负责**调试运行；JSON 粘贴后节点 `nodeConfigState: done`，但平台仍可能因 LLM 定位/运行时环境报错，需 command-test 收口。

## Reference 索引

| 模块 | 文件 | 何时 Read |
|------|------|----------|
| 场景规划 | [reference/scenario-planner.md](reference/scenario-planner.md) | **每次执行最先** |
| 编辑器节点全集 | [reference/editor-nodes.md](reference/editor-nodes.md) | 理解节点 type/tag/字段/容器结构 |
| 节点 JSON | [reference/node-schema.md](reference/node-schema.md) | 理解 rpaNode 构建格式 |
| API 鉴权 | [reference/command-api.md](reference/command-api.md) | API 异常时 |
| formData 字段 | [reference/form-data-rules.md](reference/form-data-rules.md) | 构建/调试 formData 报错时 |
| 清空 canvas | [reference/clear-canvas.md](reference/clear-canvas.md) | `--clear-and-paste` 或修复重贴前 |
| 复合节点组装 | `scripts/build-composite-workflow.mjs` | IF/ELSE 等容器 + rpaNode 首次生成 |
| B 站示例 plan | [reference/examples/bilibili-plan.json](reference/examples/bilibili-plan.json) | 默认场景 |
| 携程机票 | [reference/scenarios/ctrip-flights.md](reference/scenarios/ctrip-flights.md) | 用户说携程/机票 |
| 跨站比价 | [reference/scenarios/price-compare.md](reference/scenarios/price-compare.md) | 天猫/京东比价 |
| 搜狗 | [reference/scenarios/sogou-search.md](reference/scenarios/sogou-search.md) | sogou + 导航到URL |

## 技术要点

### 剪贴板协议

编辑器使用 `__JSON_DATA__{json}__JSON_DATA__` 格式（见 waimai-qa-aie-fe `clipboard.ts`）。粘贴时自动重写 `nodeId`。

### 元素定位（不入库）

`workflowElementId` 无需平台注册；`elementSourceType: "elementAdd"` + LLM 内联 JSON。构建见 `scripts/lib/build-nodes.mjs`。

### API

- 列表：`GET /platform/api/v1/command/listAll?source=1`
- 详情：`GET /platform/api/commandManage/getCommandDetail?commandId={id}`
- 鉴权头：`xc-auth: {config.json xcAuth}`

## 边界

- 一期仅 Web 原子指令（见 `ALLOWED_UNION_IDS`）
- 不发布工作流
- 不替代 command-test 的调试修复
- 粘贴失败时：检查是否在编排配置页、开始节点是否已选中 Enter 出空行

## 默认场景

用户未指定场景时，使用 `reference/examples/bilibili-plan.json` 四步，**禁止询问**。
