# 验证当前页面所有可访问链接

- **指令标识**：`VerifyPageAllLinksAccess`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/verifypagealllinksaccess/
- **说明**：验证当前页面上的所有链接均可访问
- **必填输出参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 包含外部链接 | Boolean | 否 | true | 是否包含外部链接，非当前域名的链接 |
| 排除链接 | List<String> | 否 | - | 排除的链接(URL)的列表，多个链接用逗号分隔，支持String数组类型 |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | - | 填写变量名称（ eg：linksAccess ），保存验证结果（ true / false ） |

## XML 示例

```xml
<VerifyPageAllLinksAccess    includedExternalLink="true"    outKey="output"/>
```
