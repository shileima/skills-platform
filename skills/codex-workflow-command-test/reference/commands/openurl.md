# 打开网页

- **指令标识**：`OpenUrl`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/openurl/
- **平台搜索名称**：`打开网页`
- **说明**：使用指定浏览器打开网页，以实现网页自动化
- **必填输入参数**：`网址`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 网址 | String | 是 | - | 要打开的网页地址，网址不能为空，必须包含协议（http:// 或 https://），例如： http://www.meituan.com |
| 超时时间 | Double | 否 | 10000 | 浏览器新开网页的超时时间，单位为毫秒，默认为 10000ms ， 0 表示不等待 |

## 配置要点

- **必填**：`网址`（标签旁有红色 `*`，未填时输入框红色边框）
- **填错位置高发**：URL 必须写入**弹框内**「* 网址」输入框，**禁止**写入 Chrome 顶部地址栏（见 [url-input.md](../url-input.md) §弹框网址 vs Chrome 地址栏）
- 填写完整 URL（含 `https://`），**禁止** `type_text`（会丢冒号变成 `https//`）
- **推荐**：Shell `echo -n "https://..." | pbcopy` → scoped 聚焦弹框「网址」→ `cmd+a` → `cmd+v` 粘贴
- **备选**：`set_value` 写入**弹框内** scoped idx（填后 AX 验证弹框 slice 含 `https://`）
- 完整 sky 示例与验证见 **[url-input.md](../url-input.md)**
- **保存前**确认弹框「网址」无红框、label 下方 slice 含 `://`（非仅地址栏），再点弹框右下角「保存」

## XML 示例

```xml
<OpenUrl  url='https://www.meituan.com'  />
```
