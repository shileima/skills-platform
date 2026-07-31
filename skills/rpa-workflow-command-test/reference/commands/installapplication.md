# 安装应用

- **指令标识**：`InstallApplication`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/installapplication/
- **说明**：在移动设备上安装指定应用程序
- **必填输入参数**：`appPath`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| appPath | String | 是 | - | 要安装的应用包路径，包路径不能为空，支持 http/https 协议 |

## XML 示例

```xml
<InstallApplication    appPath="https://hyperloop-s3.sankuai.com/hpx-artifacts/2816749-16430-1725444664849277/MeiTuanWaiMai-8.35.0-waimai-develop_61019-default.apk"/>
```
