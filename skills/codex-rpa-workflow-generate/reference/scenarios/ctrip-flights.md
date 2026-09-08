# 场景：携程杭州特价机票

**目标**：打开携程 → 输入出发/到达城市 → 搜索机票

## instructionPlan 示例

```json
{
  "workflowName": "携程杭州机票查询",
  "targetUrl": "https://www.ctrip.com",
  "instructionPlan": [
    {
      "unionId": "OpenUrl",
      "params": { "url": "https://www.ctrip.com" }
    },
    {
      "unionId": "FillText",
      "params": {
        "text": "杭州",
        "selector": { "alias": "定位携程首页机票搜索区域出发城市输入框，用于输入出发城市" }
      }
    },
    {
      "unionId": "FillText",
      "params": {
        "text": "上海",
        "selector": { "alias": "定位携程首页机票搜索区域到达城市输入框，用于输入到达城市" }
      }
    },
    {
      "unionId": "ClickElementMixed",
      "params": {
        "selector": { "alias": "定位携程首页机票搜索按钮，用于点击搜索机票" }
      }
    },
    {
      "unionId": "WaitForElementPresent",
      "params": {
        "selector": { "alias": "定位携程机票搜索结果列表区域，用于确认结果已加载" }
      }
    }
  ]
}
```

用户若指定不同城市，替换 `text` 与 `alias` 中的城市名即可。
