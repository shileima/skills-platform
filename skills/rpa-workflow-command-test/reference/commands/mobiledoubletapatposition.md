# 双击坐标

- **指令标识**：`MobileDoubleTapAtPosition`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/mobiledoubletapatposition/
- **说明**：在指定坐标上执行双击操作
- **必填输入参数**：`x坐标`, `y坐标`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| x坐标 | Integer | 是 | - | 双击坐标的X轴值，不能为空 |
| y坐标 | Integer | 是 | - | 双击坐标的Y轴值，不能为空 |

## XML 示例

```xml
<MobileDoubleTapAtPosition x="500" y="500"/>
```
