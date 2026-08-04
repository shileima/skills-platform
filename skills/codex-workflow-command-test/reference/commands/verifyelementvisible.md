# 验证元素可见

- **指令标识**：`VerifyElementVisible`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/verifyelementvisible/
- **说明**：验证指定页面元素是否对用户可见，包括元素存在且未被隐藏
- **必填输入参数**：`元素选择器`
- **必填输出参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 元素选择器 | String | 是 | - | 用于定位的页面元素的选择器，选择器不能为空，支持从元素库选择元素或手动填写XPath等定位器值 |
| iframe页面定位器 | String | 否 | - | iframe的XPath，非必填，如果目标元素在iframe中则需要填写， eg：//html/iframe |
| 定位超时 | Double | 否 | 5000 | 元素定位的最大等待时间，单位 毫秒 ，默认值 5000ms 。设置为 0 表示不等待 |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | - | 填写变量名称（ eg：isVisible ），保存验证结果（ true / false ） |

## XML 示例

```xml
<VerifyElementVisible    selector="//*[@id='__next']/div[2]/div[2]/section/div[1]/h1"    findElementOptions="{'timeout':5000}"    outKey="output"/>
```
