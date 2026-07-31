# 关闭应用

- **指令标识**：`MobileCloseApplication`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/mobilecloseapplication/
- **说明**：在移动设备上强制关闭指定应用程序
- **必填输入参数**：`appPackage`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| appPackage | Enum | 是 | - | Android 包名或iOS/Harmony BundleId，用于定位需要终止的应用， eg：com.sankuai.meituan |

## XML 示例

```xml
<MobileCloseApplication    appPackage="com.sankuai.meituan.takeoutnew"/>
```
