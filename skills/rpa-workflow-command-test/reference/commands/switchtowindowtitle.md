# 切换到指定标题网页

- **指令标识**：`SwitchToWindowTitle`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/switchtowindowtitle/
- **说明**：根据窗口标题切换到匹配的浏览器窗口，标题需要完全匹配
- **必填输入参数**：`标题`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 标题 | String | 是 | - | 要切换到的窗口标题，不能为空 |

## XML 示例

```xml
<SwitchToWindowTitle    title="新闻中心 - 美团"/>
```
