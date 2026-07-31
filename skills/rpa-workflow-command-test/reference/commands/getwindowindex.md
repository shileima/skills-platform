# 获取当前网页索引

- **指令标识**：`GetWindowIndex`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/getwindowindex/
- **说明**：获取当前活动窗口在所有打开窗口中的索引位置，索引从0开始计数
- **必填输入参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | - | 填写变量名称（例如：windowIndex），保存获取到的当前窗口索引 |

## XML 示例

```xml
<GetWindowIndex    outKey="output"/>
```
