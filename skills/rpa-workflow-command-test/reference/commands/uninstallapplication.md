# 卸载应用

- **指令标识**：`UnInstallApplication`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/uninstallapplication/
- **说明**：在移动设备上卸载指定应用程序
- **必填输入参数**：`应用包名`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 应用包名 | String | 是 | - | Android 包名或 iOS/Harmony BundleId， eg： com.sankuai.meituan |

## XML 示例

```xml
<UnInstallApplication    appPackage="com.sankuai.meituan"/>
```
