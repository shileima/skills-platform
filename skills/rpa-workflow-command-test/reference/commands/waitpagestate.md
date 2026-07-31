# 等待页面加载

- **指令标识**：`WaitPageState`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/waitpagestate/
- **说明**：等待页面加载完成
- **必填输入参数**：`加载状态`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 加载状态 | Enum | 是 | LOAD | 页面等待的加载状态类型，不能为空。支持值： - 等待页面完全加载 - 等待DOM内容加载完成 - 等待网络空闲 |
| 超时时间 | Double | 否 | 30000 | 设置为 0 可禁用超时，默认值 30000ms |

## XML 示例

```xml
<WaitPageState    loadState="LOAD"    waitForLoadStateOptions='{"timeout":30000}'/>
```
