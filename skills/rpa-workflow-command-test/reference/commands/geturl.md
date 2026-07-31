# 获取当前网页URL

- **指令标识**：`GetUrl`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/geturl/
- **说明**：获取当前活动窗口页面的完整URL地址，无需额外参数配置
- **必填输入参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | - | 填写变量名称（例如：currentUrl），保存获取到的当前页面URL地址，返回字符串类型 |

## XML 示例

```xml
<GetUrl    outKey="output"/>
```
