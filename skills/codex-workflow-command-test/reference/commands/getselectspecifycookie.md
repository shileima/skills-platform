# 获取指定Cookie信息

- **指令标识**：`GetSelectSpecifyCookie`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/getselectspecifycookie/
- **说明**：获取指定URL网页下指定名称的Cookie信息
- **必填输入参数**：`URL`, `Cookie名称`
- **必填输出参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| URL | String | 是 | - | 填写完整的URL地址，例如： https://www.meituan.com |
| Cookie名称 | String | 是 | - | Cookie的名称，用于标识特定的Cookie eg：sessionId、userToken等 ，用于筛选具有指定名称的Cookie |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | - | 填写变量名称（ eg：cookieInfo ），保存获取到的Cookie对象，如果Cookie不存在则返回 null |

## XML 示例

```xml
<GetSelectSpecifyCookie    value="https://meituan.com"    cookieName="sessionId"    outKey="output"/>
```
