# 获取当前网页标题

- **指令标识**：`GetWindowTitle`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/getwindowtitle/
- **说明**：获取当前活动窗口页面的标题内容，即HTML页面的title标签内容
- **必填输入参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | - | 填写变量名称（例如：windowTitle），保存获取到的当前窗口标题 |

## XML 示例

```xml
<GetWindowTitle    outKey="output"/>
```
