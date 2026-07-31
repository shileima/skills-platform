# 按偏移量滚动

- **指令标识**：`ScrollToPosition`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/scrolltoposition/
- **说明**：按指定横纵偏移量滚动页面
- **必填输入参数**：`起点横坐标`, `起点纵坐标`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 起点横坐标 | Integer | 是 | - | 横向滚动偏移量（X 轴），单位为像素，例如：0、100 |
| 起点纵坐标 | Integer | 是 | - | 纵向滚动偏移量（Y 轴），单位为像素，例如：500、1000 |

## XML 示例

```xml
<ScrollToPosition    x="0"    y="500"/>
```
