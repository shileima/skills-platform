# 切换到指定URL网页

- **指令标识**：`SwitchToWindowUrl`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/switchtowindowurl/
- **说明**：根据窗口URL地址切换到匹配的浏览器窗口，URL需要完全匹配
- **必填输入参数**：`URL`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| URL | String | 是 | - | 要切换到的窗口URL地址，不能为空 |

## XML 示例

```xml
<SwitchToWindowUrl    url="https://www.meituan.com/news"/>
```
