# 验证元素存在

- **指令标识**：`VerifyElementPresent`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/verifyelementpresent/
- **说明**：验证指定页面元素是否存在于DOM中，不关心元素的可见性状态
- **必填输入参数**：`元素选择器`
- **必填输出参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 元素选择器 | String | 是 | - | 用于定位的页面元素的选择器，选择器不能为空，支持从元素库选择元素或手动填写XPath等定位器值 |
| iframe页面定位器 | String | 否 | - | iframe的XPath，非必填，如果目标元素在iframe中则需要填写 eg：//html/iframe |
| 查找元素高级配置 | String | 否 | {“timeout”: “5000”} | 元素定位的配置选项，JSON格式，包含超时时间等参数，单位 毫秒 ，默认值 5000ms 。设置为 0 表示不等待 |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | output | 填写变量名称（例如：verifyResult），存储验证结果，返回Boolean类型，true表示DOM中存在匹配的元素，false表示未找到匹配的元素 |

## XML 示例

```xml
<VerifyElementPresent    selector="//*[@id='__next']/div[2]/div[2]/section/div[1]/h1"    findElementOptions="{&quot;timeout&quot;: 5000}"    outKey="verifyResult"/>
```
