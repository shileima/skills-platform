# 设置Cookie信息

- **指令标识**：`SetCookie`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/setcookie/
- **说明**：在浏览器中设置 Cookie，支持设置 Cookie 的各种属性，包括名称、值、域名、路径、过期时间、安全性参数等。用于实现绕过登录、保持会话状态等功能。
- **必填输入参数**：`设置方式`, `Name`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 设置方式 | Enum | 是 | URL | 两种设置Cookie的方式： 根据URL设置Cookie 、 根据指定Domain和path设置Cookie |
| URL | String | 否 | - | 填写完整的URL地址，例如： https://www.meituan.com 。在 根据URL设置Cookie 设置方式下，该参数为 必填 |
| Name | String | 是 | - | Cookie的键名，用于标识特定的Cookie，如 sessionId 、 userToken 等 |
| Value | String | 否 | - | 注入新的、有效的会话值，实现绕过登录。为空表示设置值为空的cookie |
| Domain | String | 否 | - | 实现跨子域登录，将 Cookie 作用域扩大到父域。必须由底层浏览器 API 严格校验，防止设置非当前域或父域以外的域名。在 根据指定Domain和path设置Cookie 设置方式下，该参数为 必填 |
| Path | String | 否 | / | 限制 Cookie 仅在网站的特定子路径下生效 |
| 有效期 | java.util.Date | 否 | - | 用于持久化登录状态或测试会话过期逻辑。为空：会话Cookie，关闭浏览器失效。 |
| SameSite | Enum | 否 | None | SameSite属性，可选值： Strict 、 Lax 、 None |
| HttpOnly | Boolean | 否 | false | 勾选时，防止 XSS 攻击窃取会话 Cookie。开启httpOnly 后，该 Cookie 将无法通过浏览器端的 JavaScript 代码（例如 document.cookie）进行读取、修改或删除。它只能在 HTTP 请求/响应中由服务器访问 |
| Secure | Boolean | 否 | true | 勾选时，确保 Cookie 只能通过 HTTPS 协议发送。必须与 SameSite=None 的校验逻辑联动。开启后：只有在请求是通过 HTTPS（安全协议）发送时，浏览器才会携带并发送该 Cookie |

## XML 示例

```xml
<SetCookie    method="URL"    name="meituan"    value="meituan123"    expires="2025-11-10 00:00:00"    sameSite="NONE"    secure="true"    httpOnly="false"    url="https://www.meituan.com/"/>
```

## 注意事项

- domain（域名）：必须与当前页面域名匹配或为其父域名
- path（路径）：Cookie仅在指定路径及其子路径下有效
- httpOnly：设置为true可防止JavaScript访问，提高安全性
- secure：设置为true时Cookie仅在HTTPS连接中传输
- sameSite：用于防止CSRF攻击，建议根据实际需求设置
