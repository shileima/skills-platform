# 复合工作流（IF / Else / ElseIf + rpaNode）组装规范

含条件分支时，用 `composite-plan.json` + `scripts/build-composite-workflow.mjs` 组装 JSON，再 `wrap-clipboard.mjs` → 粘贴。**禁止** UI 逐条插入逻辑节点。

## 变量引用铁律（强制）

> 🚫🚫🚫 **布尔探测「保存至本节点」：`formData.outKey = ""` + `outKeyType: "Boolean"`；IF 引用 `${nodeId}`。禁止写 nodeId 字符串到 outKey（会出现 `{nodeId}.xxx` String 子项）。**
>
> 完整规范见 **[boolean-outkey-self-node.md](boolean-outkey-self-node.md)**（唯一事实来源，Agent 必读）。

### 两条必须同时满足

| # | 位置 | 要求 | 典型错误 |
|---|------|------|---------|
| 1 | **探测节点** formData | `outKey: ""` + `data.outKeyType: "Boolean"`（本节点） | `outKey: nodeId` 或自定义名 → 变量列表出现 `{nodeId}.xxx` |
| 2 | **ifNode** conditions[].left | `${<探测节点nodeId>}`（无 `.xxx` 后缀） | `${nodeId.field}`、`${hasLoginForm}` → IF 输出 false |

### 闪购登录 IF 正确示例

```
preSteps[1] WaitForElementPresent（params.probeForIf: true）
  attrs.nodeId      = "HzhsAQrsEbE0LPOqRcxz4"
  formData.outKey   = ""                        ← 空 = 本节点
  data.outKeyType   = "Boolean"

ifNode.conditions[0].left = "${HzhsAQrsEbE0LPOqRcxz4}"   ← 仅 nodeId，无 .xxx
ifNode.conditions[0].comparisonOperator = "="
ifNode.conditions[0].right = "true"
```

编辑器 UI 可能显示为「${等待元素存在}」（指令标题），JSON 底层仍是 `${nodeId}`。

### 错误示例与运行时表现

```json
// ❌ outKey 写成 nodeId 字符串（最常见回归）
{ "formData": { "outKey": "cWRpqnSneO7pWLnSwegvB" }, ... }
// → 变量选择器出现 {nodeId}.xxx String 子项；canvas 显示「保存至 cWRpqn...」

// ❌ 自定义变量名
{ "formData": { "outKey": "hasLoginForm" }, ... }
{ "left": "${hasLoginForm}", ... }

// ❌ 错误 dot 后缀
{ "left": "${HzhsAQrsEbE0LPOqRcxz4.hasLoginForm}", ... }
```

**表现**：探测步输出 `true`，IF 节点 ✅，**ifBranch 内步骤全部跳过**，直接 postSteps。

### plan → 构建约定

| plan 字段 | 用途 |
|-----------|------|
| `preSteps[].params.probeForIf` | 标记供 IF 引用的探测步（推荐） |
| `ifElse.conditionPreStepIndex` | 或指定 preSteps 下标 |
| （构建产物） | `bindProbeOutputToSelf()` → `outKey = ""` + `outKeyType: Boolean`；IF → `${nodeId}` |

**禁止** Agent 手写 IF 条件 left 或自定义探测 outKey；由 `build-composite-workflow.mjs` 绑定。

### 粘贴后终检（调试前必做）

| canvas 摘要 | 通过 |
|-------------|------|
| 等待元素存在 … **保存至 本节点**（非 nodeId 字符串、无 `{nodeId}.xxx` 子项） | ✅ |
| IF … **`${<同 nodeId>}`** = true | ✅ |
| IF … **`${hasLoginForm}`** 或 **`.hasLoginForm}`** | ❌ 需重构建重贴 |

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
    "attrs": { "data": { "conditions": [{ "left": "${probeNodeId}", "comparisonOperator": "=", "right": "true" }] } },
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
    "conditionPreStepIndex": 1,
    "ifBranch": [ /* 分支独有 */ ],
    "elseBranch": [ /* 分支独有；无 Else 时可省略 */ ]
  },
  "postSteps": [ /* 各分支汇合后的通用流程 */ ]
}
```

| 字段 | 说明 |
|------|------|
| `preSteps` | 条件判断之前的步骤（打开网页、Wait* 探测等） |
| `preSteps[].params.probeForIf` | 标记 IF 探测步；构建时 `outKey=""` + `outKeyType: Boolean` |
| `ifElse.conditionPreStepIndex` | 可选，指定 preSteps 下标 |
| `ifElse.ifBranch` | **仅**条件为 true 时执行的步骤 |
| `ifElse.elseBranch` | **仅**条件为 false 时的**独有**步骤；无独有步骤时可省略（不生成 Else 节点） |
| `postSteps` | **通用流程**，组装时输出到 if/else **块之后** |

### postSteps 内联 IF（探测 + 条件滚动等）

通用流程中间若需「先探测再按条件执行」，在 `postSteps` 插入内联块（**不要**拆成顶层第二个 ifElse）：

```json
{
  "block": "ifElse",
  "probeStep": {
    "unionId": "WaitForElementPresent",
    "params": {
      "timeout": "5000",
      "failOptions": { "failureHandling": "continue" },
      "selector": { "alias": "…用于判断某按钮是否已出现" }
    }
  },
  "ifBranch": [],
  "elseBranch": [
    { "unionId": "ScrollToPosition", "params": { "x": "0", "y": "300", "selector": { "alias": "…" } } }
  ]
}
```

- 探测步由 `bindProbeOutputToSelf()` 绑定（`outKey=""` + `outKeyType: Boolean`）
- IF `${probeNodeId}=true` → `ifBranch`；false → `elseBranch`
- 示例：闪购「添加商品按钮未出现则滚 300px」→ [scenarios/shangou-discount.md](scenarios/shangou-discount.md)
- **推荐**：元素点击类步骤用 `params.selfHealScroll: true`（**每档偏移后探测，可见即停**），见 [self-heal-scroll.md](self-heal-scroll.md)

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
打开网页（e.shangou.test.sankuai.com） → 等待元素存在（→ 本节点 IF 探测）
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

见 [scenarios/shangou-discount.md](scenarios/shangou-discount.md)（Agent 按自然语言规格推理写出 plan）：

- **IF**：有登录框 → 填账号密码、勾选协议、登录
- **Else**：无登录框 → 侧栏滚动 600px、验证「店铺活动」
- **postSteps**（最外层）：点击店铺活动 → 创建折扣 → 添加门店/商品 → 确认创建

## Agent 规划检查清单

1. 列出用户步骤，标出「仅某分支」vs「分支后都要做」
2. 分支独有 → `ifBranch` / `elseBranch` / elseif 对应数组
3. 汇合后共享 → **只写一次** `postSteps`，**不要**复制进各分支
4. `build-composite-workflow.mjs` 组装 → 粘贴 → 交接 `codex-workflow-command-test`
