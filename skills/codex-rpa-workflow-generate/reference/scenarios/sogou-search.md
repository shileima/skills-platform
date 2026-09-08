# 场景：搜狗搜索（导航到URL 版）

用户若指定「导航到url」而非「打开网页」，使用 `NavigateToUrl`。

## instructionPlan

```json
{
  "workflowName": "搜狗搜索测试",
  "targetUrl": "https://www.sogou.com/",
  "instructionPlan": [
    {
      "unionId": "NavigateToUrl",
      "params": { "url": "https://www.sogou.com/" }
    },
    {
      "unionId": "FillText",
      "params": {
        "text": "codex",
        "selector": { "alias": "定位搜狗首页搜索输入框，用于输入搜索关键词" }
      }
    },
    {
      "unionId": "ClickElementMixed",
      "params": {
        "selector": { "alias": "定位搜狗首页搜索按钮，用于点击执行搜索" }
      }
    }
  ]
}
```

用户未提「刷新网页」时**不追加** ReloadPage。
