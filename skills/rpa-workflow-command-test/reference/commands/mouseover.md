# 鼠标悬停

- **指令标识**：`MouseOver`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/mouseover/
- **说明**：模拟鼠标悬停在指定元素上的操作，会将鼠标移动到元素中心位置
- **必填输入参数**：`元素选择器`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 元素选择器 | String | 是 | - | 需要鼠标悬停的页面元素的选择器，选择器不能为空，支持从元素库选择元素或手动填写XPath定位器值 |
| iframe页面定位器 | String | 否 | - | iframe的XPath，非必填，如果目标元素在iframe中则需要填写， eg：//html/iframe |
| 定位超时 | Double | 否 | 5000 | 元素定位的最大等待时间，单位 毫秒 ，默认值 5000ms 。设置为 0 表示不等待 |

## XML 示例

```xml
<MouseOver    selector="//*[@id='switcher_plogin']"    frameSelector="//html/iframe"    findElementOptions="{'timeout':5000}"/>
```
