# 元素不可见 · 滚动自愈（通用）

> 调试报错 **`10120031` / `页面元素不存在`** 时，除重采 selector 外，优先检查目标是否在视窗外——构建时可启用 `selfHealScroll` 自动插入探测与**逐步滚动再探测**。

## 适用错误

| 错误码 | 含义 | 自愈策略 |
|--------|------|---------|
| `10120031` | `ClickElementMixed` 等元素指令：页面元素不存在 | 逐步滚动 + 每步探测；仍失败再改 selector |
| 执行日志 | `Task execution failed after 3 retries` | 同上（平台已重试 3 次仍找不到元素） |

## 核心逻辑（强制）

> **每改变一次偏移量，验证一次元素是否已存在；若存在则跳出 IF/Else，不再执行后续偏移，直接进入下一步。**

```
WaitForElementPresent（初始探测）
├─ IF 已可见 → 跳过全部滚动
└─ Else
     滚动 offset[0]（如 y=300）
     WaitForElementPresent（再探测）
     ├─ IF 已可见 → 停止，不再滚 600/900…
     └─ Else
          滚动 offset[1]（如 y=600）
          WaitForElementPresent
          ├─ IF 已可见 → 停止
          └─ Else → … 直至阶梯用尽
→ 原 ClickElementMixed / FillText 等步骤
```

**禁止**在单个 Else 内无探测地连续执行多档 `ScrollToPosition`（元素在中间某档已出现时仍会空滚）。

## plan 用法

在**含 selector** 的步骤上设 `params.selfHealScroll: true`：

```json
{
  "unionId": "ClickElementMixed",
  "params": {
    "selfHealScroll": true,
    "selector": {
      "alias": "定位闪购折扣活动表单中的添加商品按钮，用于打开添加商品弹框"
    }
  }
}
```

### 可选参数

| 字段 | 默认 | 说明 |
|------|------|------|
| `selfHealScrollContainer.alias` | `定位页面主内容滚动区域，用于自愈滚动以寻找…` | 滚动容器 LLM 描述 |
| `selfHealScrollLadder` | 见 `scripts/lib/self-heal-scroll.mjs` `DEFAULT_SCROLL_LADDER` | 自定义 `{x,y}` 偏移序列 |
| `selfHealProbeTimeout` | `"3000"` | 每次探测等待毫秒 |

默认偏移阶梯：下 300 → 下 600 → 下 900 → 回顶(0) → 右 300 → 右 600。

### 支持的 unionId

`ClickElementMixed`、`FillText`、`MouseOver`、`ScrollToElement`、`VerifyElementPresent`、`VerifyElementVisible`

## 构建约定

- 链式 Else：`scripts/lib/self-heal-scroll.mjs` → `buildChainedScrollElseBranch()`
- 构建前：`expandPlanSteps()` 由 `build-composite-workflow.mjs` 自动调用
- 探测步：`outKey=""` + `outKeyType: Boolean`（与 [boolean-outkey-self-node.md](boolean-outkey-self-node.md) 一致）
- **禁止**手写「Else 内连续 6 条滚动」替代本展开

## 粘贴后终检

| canvas 表现 | 通过 |
|-------------|------|
| Else 内「滚动 → 等待元素存在 → IF」**成对重复** | ✅ 链式自愈 |
| Else 内连续多条滚动、中间无「等待元素存在」 | ❌ 旧版平铺，需重构建 |

## 调试侧（command-test）

见 `codex-workflow-command-test/reference/debug.md` §元素不存在 · 滚动自愈。

修复顺序：

1. 确认报错为 `10120031` / 元素不存在
2. plan 加 `selfHealScroll: true` → 重构建 → 重贴
3. 仍失败：按 `element-selector.md` 重采 selector；或调整 `selfHealScrollLadder`

## 禁止

- **禁止**对无 selector 的指令设 `selfHealScroll`
- **禁止**与手写 ifElse 探测块重复包裹同一步
