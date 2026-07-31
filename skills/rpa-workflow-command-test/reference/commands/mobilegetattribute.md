# 获取元素属性

- **指令标识**：`MobileGetAttribute`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/mobilegetattribute/
- **说明**：获取指定页面元素的属性值
- **必填输入参数**：`元素选择器`, `元素属性名`
- **必填输出参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 元素选择器 | String | 是 | - | 元素定位方式 eg：id、xpath、text、accessibilityId 等 ，不能为空 |
| 元素属性名 | String | 是 | - | 需要获取的属性名称， eg：text、value、checked、enabled、selected、resource-id 等 |
| 超时时间 | Double | 否 | 10000 | 指令最大等待时间（毫秒）， >0 时 Controller 会根据该值计算重试次数 |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | - | 填写变量名称（ eg：output ），保存获取到的元素属性 |

## XML 示例

```xml
<MobileGetAttribute    selector="//*[@resource-id='search_input']"    attribute="text"    timeout="10000"    outKey="output"/>
```
