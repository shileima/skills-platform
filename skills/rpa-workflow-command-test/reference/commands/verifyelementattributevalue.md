# 验证元素属性值

- **指令标识**：`VerifyElementAttributeValue`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/verifyelementattributevalue/
- **说明**：验证指定页面元素的某个HTML属性值是否等于期望值，进行精确匹配验证
- **必填输入参数**：`元素选择器`, `属性名称`, `属性值`
- **必填输出参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 元素选择器 | String | 是 | - | 用于定位的页面元素的选择器，选择器不能为空，支持从元素库选择元素或手动填写XPath等定位器值 |
| 属性名称 | String | 是 | - | 要检查的HTML属性名称，属性名称不能为空， eg：class、id、name、value、title、placeholder |
| 属性值 | String | 是 | - | 期望的属性值内容，属性值不能为空，必须与实际属性值完全匹配， eg：submit、hidden、example-class |
| iframe页面定位器 | String | 否 | - | iframe的XPath，非必填，如果目标元素在iframe中则需要填写， eg：//html/iframe |
| 定位超时 | Double | 否 | 5000 | 元素定位的最大等待时间，单位 毫秒 ，默认值 5000ms 。设置为 0 表示不等待 |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | - | 填写变量名称（ eg：attributeValue ），保存获取到的元素属性值 |

## XML 示例

```xml
<VerifyElementAttributeValue    selector="//*[@id='__next']/div[2]/div[2]/section/div[1]/h1"    attributeName="class"    attributeValue="cj mt-font"    findElementOptions="{'timeout':5000}"    outKey="output"/>
```
