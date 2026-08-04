# 执行安卓adb shell命令

- **指令标识**：`ExecuteMobileCommand`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/executemobilecommand/
- **说明**：执行安卓adb shell命令，输出执行结果（True或False）
- **必填输入参数**：`命令`
- **必填输出参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 命令 | String | 是 | - | 需要执行的 Shell / ADB / iDevice 命令字符串 |
| 超时时间 | Double | 否 | 30000 | 指令执行的超时时间，单位为毫秒， >0 时 Controller 会根据该值计算重试次数 |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | - | 输出指令的执行结果 |

## XML 示例

```xml
<ExecuteMobileCommand    command="ls /sdcard/"    outKey="result"/>
```
