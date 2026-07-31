# 跳转到scheme页面

- **指令标识**：`NavigateToScheme`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/navigatetoscheme/
- **说明**：跳转到APP的指定scheme页面
- **必填输入参数**：`app中的url链接`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| app中的url链接 | String | 是 | - | 要跳转的scheme url地址 |

## XML 示例

```xml
<NavigateToScheme    url="imeituan://www.meituan.com/home"/>
```
