# 布尔输出「保存至本节点」规范（强制）

> **唯一事实来源**：凡 `WaitForElementPresent` / `VerifyElementPresent` 等**布尔探测步**供 IF 判断，必须遵守本文。违反会导致变量选择器出现 `{nodeId}.xxx` 子项，或 IF 静默跳过 ifBranch。

## 平台语义

「将结果保存至 **本节点**」≠ 把 `formData.outKey` 写成 nodeId 字符串。

| 字段 | 正确值 | UI / 运行时效果 |
|------|--------|----------------|
| `formData.outKey` | **`""`（空字符串）** | 编辑器显示「本节点」；序列化后 XML `outKey` 属性 = nodeId |
| `data.outKeyType` | **`"Boolean"`**（来自指令 API `xbotJson.outKeyType`） | 布尔输出；变量选择器**无** `{nodeId}.xxx` 子项 |
| IF `conditions[].left` | **`${<探测节点 nodeId>}`** | 点节点**标题**插入；禁止 `.xxx` 后缀 |

plan 侧只写 `params.probeForIf: true`，**禁止**在 plan 里写 `params.outKey` 或 `ifElse.conditionVar`。

## 正确 JSON 片段

```json
{
  "type": "rpaNode",
  "attrs": {
    "nodeId": "HzhsAQrsEbE0LPOqRcxz4",
    "data": {
      "unionId": "WaitForElementPresent",
      "formData": {
        "outKey": ""
      },
      "outKeyType": "Boolean"
    }
  }
}
```

```json
{
  "type": "ifNode",
  "attrs": {
    "data": {
      "conditions": [{
        "left": "${HzhsAQrsEbE0LPOqRcxz4}",
        "comparisonOperator": "=",
        "right": "true"
      }]
    }
  }
}
```

编辑器 UI 可能渲染为「${等待元素存在} = true」，底层 JSON 仍是 `${nodeId}`。

## 三种典型错误（禁止）

| 错误写法 | 变量选择器表现 | 运行时表现 |
|---------|---------------|-----------|
| `outKey: "cWRpqnSneO7p..."`（nodeId 字符串） | 出现 `{nodeId}.xxx` 子项，类型 **String** | IF 可能 false，ifBranch 跳过 |
| `outKey: "hasLoginForm"`（自定义名） | 出现 `{nodeId}.hasLoginForm` | IF 引用 `${hasLoginForm}` 无法解析 |
| IF `left: "${nodeId.hasLoginForm}"` | — | 探测 true 但 IF false |

**表现共性**：等待元素存在输出 `true`，IF 节点 ✅ 但耗时极短（~6ms），**ifBranch 内步骤全部跳过**，直接 postSteps。

## 构建约定（Agent 禁止手写）

1. plan：`preSteps[].params.probeForIf: true`（见 [scenarios/shangou-discount.md](scenarios/shangou-discount.md)）
2. 构建：`build-composite-workflow.mjs` → `bindProbeOutputToSelf()` 自动设 `outKey=""`、`outKeyType` 来自 API
3. IF 条件：构建脚本自动写 `${probeNodeId}`，**禁止** Agent 改 left
4. `build-nodes.mjs`：**禁止**在 `WaitForElementPresent` 等探测指令上写 `params.outKey`

构建后 `validateCompositeVariableRefs()` 会校验；违反直接抛错。

## 粘贴后终检（调试前必做）

| 检查项 | 通过 | 失败 → 重构建重贴 |
|--------|------|-------------------|
| canvas「等待元素存在」 | **保存至 本节点** | 保存至 `cWRpqn...` 等 nodeId 字符串 |
| IF 条件左值 | `${nodeId}` 或 UI「${等待元素存在}」 | `${hasLoginForm}` 或 `${nodeId.xxx}` |
| 变量选择器 | 点节点标题 → `${nodeId}`，无子项 | 出现 `{nodeId}.xxx` String 子项 |
| 调试 IF 耗时 | 有登录框时 >>10ms（走 ifBranch） | ~6ms 且 segmented control false |

## 与普通 outKey 的区别

| 场景 | outKey | 下游引用 |
|------|--------|---------|
| IF 布尔探测（本节点） | `""` + `outKeyType: Boolean` | `${nodeId}` |
| GetText / GetUrl / 截图 | 自定义名如 `tmallPrice` | `${tmallPrice}` 或 `${nodeId.tmallPrice}` |

二者**不可混用**：IF 探测步不要用自定义 outKey 名。

## 相关文件

- 构建：`scripts/build-composite-workflow.mjs` → `bindProbeOutputToSelf()`
- 复合 plan：[composite-workflow.md](composite-workflow.md)
- formData：[form-data-rules.md](form-data-rules.md) §outKey
- 示例 plan：[examples/shangou-discount-plan.json](examples/shangou-discount-plan.json)
