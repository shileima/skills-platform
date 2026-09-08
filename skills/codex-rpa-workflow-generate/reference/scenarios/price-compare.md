# 场景：跨站商品比价（天猫 vs 京东）

**目标**：分别在天猫、京东搜索同一商品并获取价格文本。

## instructionPlan 示例

```json
{
  "workflowName": "天猫京东比价",
  "instructionPlan": [
    {
      "unionId": "OpenUrl",
      "params": { "url": "https://www.tmall.com" }
    },
    {
      "unionId": "FillText",
      "params": {
        "text": "iPhone 16",
        "selector": { "alias": "定位天猫首页顶部搜索输入框，用于输入商品关键词" }
      }
    },
    {
      "unionId": "ClickElementMixed",
      "params": {
        "selector": { "alias": "定位天猫首页搜索按钮，用于点击搜索商品" }
      }
    },
    {
      "unionId": "GetText",
      "params": {
        "selector": { "alias": "定位天猫搜索结果页第一个商品价格元素，用于获取价格" },
        "outKey": "tmallPrice"
      }
    },
    {
      "unionId": "OpenUrl",
      "params": { "url": "https://www.jd.com" }
    },
    {
      "unionId": "FillText",
      "params": {
        "text": "iPhone 16",
        "selector": { "alias": "定位京东首页顶部搜索输入框，用于输入商品关键词" }
      }
    },
    {
      "unionId": "ClickElementMixed",
      "params": {
        "selector": { "alias": "定位京东首页搜索按钮，用于点击搜索商品" }
      }
    },
    {
      "unionId": "GetText",
      "params": {
        "selector": { "alias": "定位京东搜索结果页第一个商品价格元素，用于获取价格" },
        "outKey": "jdPrice"
      }
    }
  ]
}
```

将 `iPhone 16` 替换为用户指定的商品名。
