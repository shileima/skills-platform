# 验证字符串不匹配

- **指令标识**：`VerifyNotMatch`
- **指令类型**：通用指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/verifynotmatch/
- **说明**：该指令用于验证两个字符串不匹配，支持普通字符串匹配和正则表达式匹配，执行该指令后，系统将根据匹配模式进行比较，如果不匹配则返回true，否则返回false，结果保存到指定变量中
- **必填输入参数**：`待验证字符串`, `期望字符串`
- **必填输出参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 待验证字符串 | String | 是 | - | 需要进行匹配验证的字符串，待验证字符串不能为空, eg: hello world |
| 期望字符串 | String | 是 | - | 用于匹配比较的期望字符串或正则表达式，期望字符串不能为空, eg: hello |
| 是否正则表达式 | Boolean | 否 | false | 指定期望字符串是否为正则表达式，默认为 false （普通字符串匹配），可选值： true 、 false |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | - | 填写变量名称（ eg: notMatchResult ），保存验证结果（ true / false ） |

## XML 示例

```xml
<VerifyNotMatch    actualText="hello world"    expectedText="hello"    isRegex="false"    outKey="output"/>
```
