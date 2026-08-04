# 网页后退

- **指令标识**：`BackPage`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/backpage/
- **说明**：模拟浏览器的后退操作，导航到浏览器历史记录中的上一页

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 超时时间 | Double | 否 | 30000 | 网页后退超时时间，单位为毫秒 |
| 成功状态 | Enum | 否 | LOAD | 何时认为操作成功，默认为「加载完成」。可选值： - 加载完成 - 构建DOM树之后、样式加载完成之前 - 网络空闲 - 浏览器收到请求并开始渲染 |

## XML 示例

```xml
<BackPage    goBackOptions='{"timeout":30000,"waitUntil":"LOAD"}'/>
```
