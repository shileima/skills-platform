# 拖拽到元素

- **指令标识**：`MobileDragAndDrop`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/mobiledraganddrop/
- **说明**：拖动指定元素到目标元素位置
- **必填输入参数**：`源元素选择器`, `目标元素选择器`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 源元素选择器 | String | 是 | - | 选择要拖拽的源元素，可直接填写 xpath / 元素prompt 或从元素库选择 元素id |
| 目标元素选择器 | String | 是 | - | 结束元素定位方式， eg：xpath |
| 超时时间 | Double | 否 | 10000 | 查找元素超时时间 （ms，毫秒） |

## XML 示例

```xml
<MobileDragAndDrop  sourceSelector="//*[@text='直播中' and @content-desc='直播中']"  targetSelector="//*[@text='首页' and @content-desc='首页']"  timeout="10000"/>
```
