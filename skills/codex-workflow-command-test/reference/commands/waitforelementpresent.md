# 等待元素存在

- **指令标识**：`WaitForElementPresent`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/waitforelementpresent/
- **说明**：等待指定页面元素在DOM中出现，支持动态内容的等待检测
- **必填输入参数**：`元素选择器`
- **必填输出参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 元素选择器 | String | 是 | - | 用于定位的页面元素的选择器，选择器不能为空，支持从元素库选择元素或手动填写XPath等定位器值 |
| iframe页面定位器 | String | 否 | - | iframe的XPath，非必填，如果目标元素在iframe中则需要填写， eg：//html/iframe |
| 定位超时 | Double | 否 | 10000 | 等待操作的最大超时时间，单位为 毫秒 ，超时后将停止等待，最小值为 0 ，默认为 10000ms |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | - | 填写变量名称（ eg：present ），保存等待结果（ true / false ） |

## XML 示例

```xml
<WaitForElementPresent    selector="//*[@id='root']/div/div/div[2]/div[2]"    timeout="10000"    outKey="output"/>
```
