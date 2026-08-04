# 鼠标悬停偏移

- **指令标识**：`MouseOverOffset`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/mouseoveroffset/
- **说明**：模拟鼠标悬停在指定元素相对位置的操作，可以精确控制悬停的坐标偏移
- **必填输入参数**：`元素选择器`, `偏移X`, `偏移Y`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 元素选择器 | String | 是 | - | 需要鼠标悬停的页面元素的选择器，选择器不能为空，支持从元素库选择元素或手动填写XPath定位器值 |
| 偏移X | Integer | 是 | - | 距元素中心点的水平偏移量，正值向右偏移，负值向左偏移，单位为 像素 |
| 偏移Y | Integer | 是 | - | 距元素中心点的垂直偏移量，正值向下偏移，负值向上偏移，单位为 像素 |
| iframe页面定位器 | String | 否 | - | iframe的XPath，非必填，如果目标元素在iframe中则需要填写 eg：//html/iframe |
| 定位超时 | Double | 否 | 5000 | 元素定位的最大等待时间，单位 毫秒 ，默认值 5000ms 。设置为 0 表示禁用超时 |

## XML 示例

```xml
<MouseOverOffset    selector="//*[@id='__next']/div[1]/nav/ul/li[1]/a/span/span[1]"    offsetX="10"    offsetY="5"    findElementOptions="{'timeout':5000}"/>
```
