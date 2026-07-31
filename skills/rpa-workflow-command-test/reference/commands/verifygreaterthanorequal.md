# 验证大于等于

- **指令标识**：`VerifyGreaterThanOrEqual`
- **指令类型**：通用指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/verifygreaterthanorequal/
- **说明**：该指令用于验证实际值是否大于等于期望值，支持整数和小数的大小比较验证
- **必填输入参数**：`实际值`, `期望值`
- **必填输出参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 实际值 | Double | 是 | - | 需要进行大于等于比较验证的实际数值，实际值不能为空，仅支持数字类型, eg: 10 |
| 期望值 | Double | 是 | - | 与实际值进行大于等于比较的期望数值，期望值不能为空，仅支持数字类型, eg: 10 |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | - | 填写变量名称（ eg: greaterOrEqualResult ），保存验证结果（ true / false ） |

## XML 示例

```xml
<VerifyGreaterThanOrEqual        actualNumber="8"        expectedNumber="8"        outKey="output"/>
```
