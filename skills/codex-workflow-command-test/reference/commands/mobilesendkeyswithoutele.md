# 模拟键盘输入

- **指令标识**：`MobileSendKeysWithoutEle`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/mobilesendkeyswithoutele/
- **说明**：在设备上直接模拟键盘输入指定文本，无需传入元素信息
- **必填输入参数**：`输入内容`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 输入内容 | String | 是 | - | 需要输入的内容 |

## XML 示例

```xml
<MobileSendKeysWithoutEle keyword="美团外卖"/>
```
