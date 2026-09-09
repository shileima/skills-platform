# 复合工作流（IF / Else / ElseIf + rpaNode）组装规范

含条件分支时，用 `composite-plan.json` + `scripts/build-composite-workflow.mjs` 组装 JSON，再 `wrap-clipboard.mjs` → 粘贴。**禁止** UI 逐条插入逻辑节点。

## 核心铁律：通用流程提取到最外层

> 🚫🚫🚫 **若 IF、Else、ElseIf 各分支在汇合后都要执行同一套步骤，必须把这套「通用流程」放在分支块之外（最外层），禁止在每个分支内重复粘贴。**

| 步骤类型 | 放置位置 | 示例 |
|---------|---------|------|
| **分支独有** | 对应分支 `content` 内 | IF：登录表单填写；Else：滚动侧栏 + 验证文案 |
| **分支共享（通用）** | `postSteps`，输出在 if/else/elseif **块之后** | 点击「店铺活动」→ 创建折扣 → 添加商品 → 确认创建 |
| **滚动（汇合后都要滚）** | `postSteps` | 表单内 `ScrollToPosition` 滚到底部找「请设置」——两分支汇合后执行 |
| **滚动（仅某分支前置）** | 对应分支内 | Else 路径：侧栏滚 600px 才看得到「店铺活动」（登录后不需要） |

### 正确 vs 错误

```
✅ 正确（通用流程在最外层）

preSteps: 打开网页 → 探测登录框
ifNode.content:     仅登录步骤
elseNode.content:   仅「无登录框」前置（滚动 + 验证）
postSteps:          创建折扣活动全流程（两分支汇合后执行）

❌ 错误（通用流程重复进每个分支）

ifNode.content:     登录 + 创建折扣…（21 步）
elseNode.content:   滚动 + 验证 + 创建折扣…（21 步重复）
```

### 执行语义

编排引擎在**某一条件分支执行完毕**后，继续执行该分支块**之后的同级节点**。因此 `postSteps` 作为 if/else 的**兄弟节点**排在后面，即可保证「无论走哪条分支，汇合后都跑通用流程」。

### TipTap JSON 层级

`ifNode` 与 `elseNode`（及多个 `elseifNode`）必须是**同级兄弟**，`elseNode` **禁止**嵌在 `ifNode.content` 内。

```json
[
  { "type": "rpaNode", "attrs": { "tag": "OpenUrl", "...": "..." } },
  { "type": "rpaNode", "attrs": { "tag": "WaitForElementPresent", "...": "..." } },
  {
    "type": "ifNode",
    "attrs": { "data": { "conditions": [{ "left": "${nodeId.outKey}", "comparisonOperator": "=", "right": "true" }] } },
    "content": [ /* 仅 true 分支独有 rpaNode */ ]
  },
  {
    "type": "elseNode",
    "attrs": { "data": { "title": "Else" } },
    "content": [ /* 仅 false 分支独有 rpaNode */ ]
  },
  { "type": "rpaNode", "...": "通用步骤 1" },
  { "type": "rpaNode", "...": "通用步骤 2" }
]
```

## composite-plan.json 结构

```json
{
  "workflowName": "场景名-YYYYMMDD",
  "targetUrl": "https://...",
  "preSteps": [
    { "unionId": "OpenUrl", "params": { "url": "https://..." } }
  ],
  "ifElse": {
    "conditionVar": "hasLoginForm",
    "ifBranch": [ /* 分支独有 */ ],
    "elseBranch": [ /* 分支独有；无 Else 时可省略 */ ]
  },
  "postSteps": [ /* 各分支汇合后的通用流程 */ ]
}
```

| 字段 | 说明 |
|------|------|
| `preSteps` | 条件判断之前的步骤（打开网页、Wait* 探测等） |
| `ifElse.conditionVar` | 条件变量名，默认取 preSteps 中带 `outKey` 的节点 |
| `ifElse.ifBranch` | **仅**条件为 true 时执行的步骤 |
| `ifElse.elseBranch` | **仅**条件为 false 时的**独有**步骤；无独有步骤时可省略（不生成 Else 节点） |
| `postSteps` | **通用流程**，组装时输出到 if/else **块之后** |

### 仅 IF、无 Else（常见：可选登录）

仅「有登录框才登录」、其余全部通用时：**不要** Else 节点，只保留 `ifBranch` + `postSteps`。

```
preSteps → ifNode（仅登录）→ postSteps（通用流程）
无登录框：跳过 IF 内容，直接 postSteps
```

### ElseIf 场景

多个 `elseifNode` 时，每个 `elseifNode.content` 同样**只放该分支独有步骤**；全部条件分支块结束后，再排 `postSteps` 通用节点。

手写 JSON 顺序：`ifNode` → `elseifNode`* → `elseNode`? → 通用 rpaNode*

## 构建前确认（强制）

> 🚫🚫🚫 **写出 plan 后、构建 JSON 前**，必须运行 `preview-plan.mjs`，将简洁流程树**展示给用户确认**。用户确认或明确说「继续/开始生成」后方可 build。

```bash
node "$SKILL_ROOT/scripts/preview-plan.mjs" /tmp/composite-plan.json
```

输出示例：

```
打开网页（e.shangou.test.sankuai.com） → 等待元素存在（→ hasLoginForm）
├─ IF（有登录框）：输入文本 → … → 等待页面加载 → 通用流程（21 步）
└─ Else（无登录框）：滚动（600px） → 验证文本存在（"店铺活动"） → 通用流程（21 步）

通用流程（postSteps，21 步）：
点击元素 → … → 确认创建
```

脚本会校验常见 plan 错误（通用流程重复进分支、滚动类指令放错层级等）。有 ⚠️ 警告时 Agent 应先修正 plan 再请用户确认。

**例外**：用户未指定场景、走默认 B 站四步线性 plan 时可跳过确认（见 SKILL.md §默认场景）。

## 构建命令

```bash
SKILL_ROOT="${HOME}/.cursor/skills/codex-rpa-workflow-generate"
PLAN=/tmp/composite-plan.json

# 1. 预览 + 用户确认（见上）
node "$SKILL_ROOT/scripts/preview-plan.mjs" "$PLAN"

# 2. 确认后再构建
node "$SKILL_ROOT/scripts/build-composite-workflow.mjs" "$PLAN" /tmp/workflow.nodes.json
node "$SKILL_ROOT/scripts/wrap-clipboard.mjs" /tmp/workflow.nodes.json /tmp/workflow.clipboard.txt

# 首次：create-empty-workflow.sh + paste-workflow.sh
# 修复：repaste-workflow.sh / generate-workflow.sh --clear-and-paste（需自行先 build composite）
```

纯 rpaNode 线性场景仍用 `generate-workflow.sh --plan`（内部 `build-nodes.mjs`）。

## 示例：闪购折扣活动（登录分叉 + 通用创建）

见 [examples/shangou-discount-plan.json](examples/shangou-discount-plan.json)：

- **IF**：有登录框 → 填账号密码、勾选协议、登录
- **Else**：无登录框 → 侧栏滚动 600px、验证「店铺活动」
- **postSteps**（最外层）：点击店铺活动 → 创建折扣 → 添加门店/商品 → 确认创建

## Agent 规划检查清单

1. 列出用户步骤，标出「仅某分支」vs「分支后都要做」
2. 分支独有 → `ifBranch` / `elseBranch` / elseif 对应数组
3. 汇合后共享 → **只写一次** `postSteps`，**不要**复制进各分支
4. `build-composite-workflow.mjs` 组装 → 粘贴 → 交接 `codex-workflow-command-test`
