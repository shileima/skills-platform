# 清除文本

- **指令标识**：`MobileClearText`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/mobilecleartext/
- **说明**：在移动设备上清除指定文本输入框的内容
- **必填输入参数**：`元素选择器`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 元素选择器 | String | 是 | - | 元素定位方式 eg：id、xpath、text、accessibilityId 等 ，不能为空 |
| 超时时间 | Double | 否 | 10000 | 指令最大等待时间（毫秒）， >0 时 Controller 会根据该值计算重试次数 |

## XML 示例

```xml
<MobileClearText    selector="//*[@resource-id='search_input']"    timeout="10000"/>
```
