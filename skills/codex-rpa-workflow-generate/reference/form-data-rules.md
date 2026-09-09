# formData 字段规范（经调试沉淀）

构建节点 JSON 时，`formData` 的 key **必须**与 `getCommandDetail.paramInfo.xbotJson.input[].paramsName` 一致，禁止臆造顶层字段。

## 常见错误

| 指令 | 错误写法 | 正确写法 |
|------|---------|---------|
| WaitPageState | `timeout: "30000"` | `waitForLoadStateOptions: { timeout: "30000" }` |
| OpenUrl | `timeout` 只写 `newPageOptions.defaultTimeout` | `navigateOptions: { timeout: "120000", waitUntil: "LOAD" }`（导航超时默认 30s） |
| NavigateToUrl | `url: "..."` | `rawUrl: "..."`, 可选 `navigateOptions: { timeout, waitUntil }` |
| SendKeys | `sendKeys: "Return"` | `keys: "Return"` |
| Delay | `delay: "1000"` | `second: "1"`, `timeUnit: "SECOND"` |
| TakeScreenshot | 仅 `outKey` | `screenshotOption: { fullPage: true }` + `outKey` |

## WaitPageState（调试报错根因）

引擎 XML：

```xml
<WaitPageState loadState="LOAD" waitForLoadStateOptions='{"timeout":30000}'/>
```

**不支持**顶层 `timeout` 属性 → 报错：`WaitPageState doesn't support the "timeout" attribute`

## LLM 元素选择器节点的异常处理

凡 `formData` 含 `selectorId`（由 `buildSelectorId()` 生成的 LLM 动态定位），默认写入：

```json
{
  "failOptions": {
    "failureHandling": "retry",
    "retryOptions": { "maxRetryCount": 3, "retryInterval": 1000 },
    "retryFailOptions": { "retryFailHandling": "stop" }
  }
}
```

对应编辑器「异常处理 → 处理方式：异常重试 → 最大重试次数：3」。

- plan 中显式传 `params.failOptions` 时优先使用（如 `WaitForElementPresent` 的 `continue`）
- 无元素选择器的指令（`OpenUrl`、`VerifyTextPresent` 等）仍为 `failureHandling: "stop"`

## 校验

构建后运行：

```bash
node scripts/validate-built-nodes.mjs reference/examples/github-codex-issues-plan.json
```
