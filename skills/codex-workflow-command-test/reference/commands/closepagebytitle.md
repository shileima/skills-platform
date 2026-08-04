# 关闭指定标题网页

- **指令标识**：`ClosePageByTitle`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/closepagebytitle/
- **说明**：根据窗口标题关闭匹配的浏览器窗口，标题需要完全匹配
- **必填输入参数**：`标题`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 标题 | String | 是 | - | 需要关闭的页面标题，不能为空 |
| 超时时间 | Double | 否 | 2000 | 等待页面关闭的最大时长，超出抛出异常，单位毫秒。默认 2000ms ，设置为 0 表示不等待 |

## XML 示例

```xml
<ClosePageByTitle    title="美团 - 帮大家吃得更好，生活更好"    timeout="2000"/>
```
