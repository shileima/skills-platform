# 验证元素属性值

- **指令标识**：`MobileVerifyElementAttributeValue`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/mobileverifyelementattributevalue/
- **说明**：验证手机当前屏幕中的UI元素的指定属性值是否正确，输出验证结果（True或False）
- **必填输入参数**：`元素选择器`, `属性名称`, `属性值`
- **必填输出参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 元素选择器 | String | 是 | - | 元素定位方式， eg：xpath |
| 属性名称 | String | 是 | - | 要验证的属性的名称 |
| 属性值 | String | 是 | - | 要验证的属性的值 |
| 超时时间 | Double | 否 | 10000 | 查找元素超时时间，指令最大等待时间（ 毫秒 ）， >0 时 Controller 会根据该值计算重试次数 |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | - | 输出指令的结果， True 表示属性值符合预期， False 表示属性值不符合预期 |

## XML 示例

```xml
<MobileVerifyElementAttributeValue    selector="//*[@content-desc='我的']"    attributeName="enabled"    attributeValue="true"    timeout="10000"    outKey="output"/>
```
