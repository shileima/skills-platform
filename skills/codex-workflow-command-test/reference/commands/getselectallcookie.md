# 获取所有Cookie信息

- **指令标识**：`GetSelectAllCookie`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/getselectallcookie/
- **说明**：获取指定URL的所有Cookie信息
- **必填输入参数**：`URL`
- **必填输出参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| URL | String | 是 | - | 填写完整的URL地址 eg：https://www.meituan.com |
| 筛选name | String | 否 | - | Cookie的名称，用于标识特定的Cookie eg：sessionId、userToken等 ，用于筛选具有指定名称的Cookie |
| 筛选domain | String | 否 | - | Cookie的域名，如 .sankuai.com ，用于筛选指定域名的Cookie |
| 筛选path | String | 否 | - | Cookie的路径参数，指定Cookie在网站中的有效路径范围，如 / 表示整个网站， /admin 表示仅在admin路径下有效 |
| 筛选安全cookie | Boolean | 否 | false | 选择 开启 则筛选 secure cookie 集合（仅HTTPS发送的cookie集合），否则获取非 secure cookie 集合（可能包含HTTP和HTTPS发送的cookie集合） |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | - | 填写变量名称（ eg：cookies ），保存获取到的Cookie信息，返回Cookie对象数组 |

## XML 示例

```xml
<GetSelectAllCookie    value="https://meituan.com"    cookieOptions="{'secure':false}"    outKey="output"/>
```
