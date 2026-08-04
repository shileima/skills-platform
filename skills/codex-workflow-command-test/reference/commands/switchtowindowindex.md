# 切换到指定索引网页

- **指令标识**：`SwitchToWindowIndex`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/switchtowindowindex/
- **说明**：根据窗口索引切换到指定的浏览器窗口，索引从0开始计数
- **必填输入参数**：`索引`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 索引 | Integer | 是 | - | 要切换到的窗口索引，不能为空，索引从 0 开始计数 |

## XML 示例

```xml
<SwitchToWindowIndex    index="0"/>
```
