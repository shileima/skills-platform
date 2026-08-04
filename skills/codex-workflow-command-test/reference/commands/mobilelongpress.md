# 长按坐标

- **指令标识**：`MobileLongPress`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/mobilelongpress/
- **说明**：在指定坐标上执行长按操作
- **必填输入参数**：`x坐标`, `y坐标`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| x坐标 | Integer | 是 | - | 长按坐标的X轴值，不能为空 |
| y坐标 | Integer | 是 | - | 长按坐标的Y轴值，不能为空 |
| 长按时长 | Integer | 否 | 10000 | 单位： 毫秒(ms) |

## XML 示例

```xml
<MobileLongPress pressX="156" pressY="980" pressTime="600"/>
```
