# 编排工作流自动生成 — 场景规划规则

## 输入 → 输出

**输入**：用户自然语言场景，或显式指令列表。

**输出**：`instruction-plan.json`，供 `scripts/generate-workflow.sh --plan` 使用。

```json
{
  "workflowName": "场景名-YYYYMMDD",
  "targetUrl": "https://...",
  "instructionPlan": [
    { "unionId": "OpenUrl", "params": { "url": "https://..." } },
    { "unionId": "FillText", "params": { "text": "关键词", "selector": { "alias": "定位..." } } },
    { "unionId": "ClickElementMixed", "params": { "selector": { "alias": "定位..." } } }
  ]
}
```

## 规划优先级

1. 用户消息中**显式指定的指令名**（最高）
2. 用户指定的站点 / URL
3. 内置场景模板（`reference/scenarios/`）
4. 默认：B 站四步（`examples/bilibili-plan.json`）

用户显式指令映射见 `codex-workflow-command-test` 的 `reference/user-intent.md`（导航到URL vs 打开网页等）。

## Web 自动化基本顺序

```
OpenUrl / NavigateToUrl
  → FillText（可选）
  → ClickElementMixed（可选）
  → Wait* / GetText / Verify*（可选）
  → ReloadPage（可选，用户未提则不追加）
```

## 元素 LLM 描述格式

**位置 + 目标元素 + 操作意图**：

```
定位 {站点} {页面位置} 的 {元素名称}，用于 {操作意图}
```

示例：

| 元素 | alias |
|------|-------|
| B 站搜索框 | `定位 Bilibili 首页顶部导航栏中间偏上的搜索输入框，用于输入搜索关键词` |
| B 站搜索按钮 | `定位 Bilibili 首页顶部导航栏搜索框右侧的搜索按钮，用于点击执行搜索` |

## 内置场景模板

| 用户关键词 | 模板文件 |
|-----------|---------|
| bilibili / B站 / 未指定场景 | `examples/bilibili-plan.json` |
| 携程 / 机票 | `scenarios/ctrip-flights.md` |
| 比价 / 天猫 / 京东 | `scenarios/price-compare.md` · `examples/jd-tmall-iphone17-plan.json` |
| sogou / 搜狗 | `scenarios/sogou-search.md` |
| GitHub / codex / issues 汇总 | `scenarios/github-codex-issues.md` |

## 一期支持的 unionId

见 `scripts/lib/build-nodes.mjs` 中 `ALLOWED_UNION_IDS`。不含 LoopElements、UploadFile、移动端指令。

## Agent 执行步骤

1. 解析用户意图 → 写出 `instruction-plan.json`（可放 `/tmp/` 或技能 `reference/examples/`）
2. **组装 JSON 并粘贴**（首次生成强制，禁止 UI 逐条插入）：
   - 纯 rpaNode：`bash scripts/generate-workflow.sh --plan <plan.json>`
   - 含 IF/ELSE 等容器：`node scripts/build-composite-workflow.mjs <composite-plan.json>` → `wrap-clipboard.mjs` → `paste-workflow.sh` 或 `generate-workflow.sh --no-create`
3. 验证 canvas 摘要顺序与节点数量
4. **必须**激活 `codex-workflow-command-test` 完成检查与调试
5. 调试后修复：优先改 plan → `--clear-and-paste`；单点定位/表单问题才用 command-test UI（双击节点、新建 LLM、此处开始调试）

## 生成路线 vs 修复路线

| | 首次生成 | 调试后修复 |
|---|---------|-----------|
| **主路径** | JSON 组装 + 剪贴板粘贴 | `--clear-and-paste` 重贴 |
| **辅路径** | — | command-test UI 单点改节点 |
| **禁止** | command-test `insertAfterAnchor` 逐条插入 | 为修一点而 UI 全量重建 |

