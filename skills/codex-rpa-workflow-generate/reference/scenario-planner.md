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
| GitHub / codex / issues 汇总 | `scenarios/github-codex-issues.md` · `examples/github-codex-issues-composite-plan.json` |
| 闪购 / 折扣活动 / shangou | `scenarios/shangou-discount.md` · `examples/shangou-discount-plan.json` |

## 一期支持的 unionId

见 `scripts/lib/build-nodes.mjs` 中 `ALLOWED_UNION_IDS`。不含 LoopElements、UploadFile、移动端指令。

## 复合 plan（含 IF / Else / ElseIf）

线性场景用 `instructionPlan`；含条件分支时用 `composite-plan.json`（`preSteps` + `ifElse` + `postSteps`）。

> 🚫 **通用流程提取到最外层**：IF、Else、ElseIf 汇合后都要执行的步骤 → **只写** `postSteps`，输出在分支块**之外**；各分支内**禁止**重复粘贴同一套通用节点。详见 [composite-workflow.md](composite-workflow.md)。

> 🚫 **布尔 outKey 本节点**：preSteps 写 `params.probeForIf: true`；构建时 `outKey=""` + `outKeyType: Boolean`；IF `${nodeId}`。**禁止** `outKey=nodeId 字符串`。详见 [boolean-outkey-self-node.md](boolean-outkey-self-node.md)。

> **滚动自愈**：元素不存在时步骤加 `selfHealScroll: true`；构建为「滚一档 → 探测 → 可见则停」，禁止 Else 内连续多档滚动。详见 [self-heal-scroll.md](self-heal-scroll.md)。

```bash
node scripts/build-composite-workflow.mjs reference/examples/shangou-discount-plan.json
node scripts/wrap-clipboard.mjs reference/examples/shangou-discount-plan.nodes.json /tmp/clipboard.txt
bash scripts/paste-workflow.sh /tmp/clipboard.txt   # 或 repaste-workflow.sh
```

## 构建前预览确认（强制）

写出 plan 后、构建 JSON **之前**：

```bash
node scripts/preview-plan.mjs /tmp/your-plan.json
```

将输出的流程树展示给用户，**等待确认**后再 build。复合 plan 示例：

```
打开网页 → 等待登录框
├─ IF（有登录框）：登录 → 通用流程（21 步）
└─ Else（无登录框）：滚动600px → 验证「店铺活动」→ 通用流程（21 步）
```

`preview-plan.mjs` 会警告：通用流程误写在分支内、滚动类指令层级放错等。**默认 B 站四步线性场景可跳过确认**。

## Agent 执行步骤

1. 解析用户意图 → 写出 plan（线性 `instruction-plan.json` 或复合 `composite-plan.json`）
2. **`preview-plan.mjs` → 展示流程树 → 用户确认**
3. 构建 JSON 并粘贴：
   - 纯 rpaNode：`bash scripts/generate-workflow.sh --plan <plan.json>`
   - 含 IF/Else：`build-composite-workflow.mjs` → `wrap-clipboard.mjs` → `paste-workflow.sh`
4. 粘贴成功后，**必须**激活 `codex-workflow-command-test` 完成检查与调试
