# 导航到URL

- **指令标识**：`NavigateToUrl`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/navigatetourl/
- **说明**：在当前浏览器实例中导航到指定的网址，如果当前没有页面则会新建一个页面
- **必填输入参数**：`导航到的网址`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 导航到的网址 | String | 是 | - | 需要导航到的目标网页地址，导航到的网址不能为空，支持http、https等协议，例如： https://www.meituan.com |
| 超时时间 | Double | 否 | 30000 | 导航超时时间，单位为毫秒，默认 30000ms ，为 0 表示不等待 |
| 成功状态 | Enum | 否 | LOAD | 页面等待的成功状态类型，支持的枚举值包括： - 加载完成 - 构建DOM树之后、样式加载完成之前 - 网络空闲 - 浏览器收到请求并开始渲染 |

## 配置要点

- **必填**：`导航到的网址`
- 填写 URL 时**禁止** `type_text`，用 `pbcopy+paste` 或 `set_value`，见 [url-input.md](../url-input.md)

## XML 示例

```xml
<NavigateToUrl    rawUrl="https://www.meituan.com"    navigateOptions='{"timeout":30000,"waitUntil":"LOAD"}'/>
```
