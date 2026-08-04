# 拖拽到元素

- **指令标识**：`DragAndDropByObject`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/draganddropbyobject/
- **说明**：实现将源元素拖拽到目标元素的位置
- **必填输入参数**：`源元素选择器`, `目标元素选择器`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 源元素选择器 | String | 是 | - | 需要拖拽的源元素选择器，选择器不能为空，支持 CSS 、 XPath 等多种定位方式 |
| 源iframe定位器 | String | 否 | - | 针对于iframe内的源元素，需要先定位到iframe内部的选择器 |
| 定位超时 | Double | 否 | 5000 | 元素定位的最大等待时间，单位 毫秒 ，默认值 5000ms 。设置为 0 表示不等待 |
| 目标元素选择器 | String | 是 | - | 拖拽目标位置的元素选择器，选择器不能为空，支持 CSS 、 XPath 等多种定位方式 |
| 目标iframe定位器 | String | 否 | - | 针对于iframe内的目标元素，需要先定位到iframe内部的选择器 |
| 定位超时 | Double | 否 | 5000 | 元素定位的最大等待时间，单位 毫秒 ，默认值 5000ms 。设置为 0 表示不等待 |

## XML 示例

```xml
<DragAndDropByObject  sourceSelector="//*[@id='draggable-item']"  findElementOptions="{'timeout':5000}"  targetSelector="//*[@id='drop-zone']"  findElementOptions="{'timeout':5000}"/>
```
