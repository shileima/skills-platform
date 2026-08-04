# 验证元素存在

- **指令标识**：`MobileVerifyElementExist`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/mobileverifyelementexist/
- **说明**：验证特定UI元素在手机当前屏幕是否存在，输出验证结果（True或False）
- **必填输入参数**：`元素选择器`
- **必填输出参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 元素选择器 | String | 是 | - | 元素定位方式， eg：id、xpath、text、accessibilityId 等，不能为空 |
| 超时时间 | Double | 否 | 10000 | 查找元素超时退出时间（ ms，毫秒 ） |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | Boolean | 是 | - | 输出指令的结果， True 表示元素存在， False 表示元素不存在 |

## XML 示例

```xml
<MobileVerifyElementExist    selector="//*[@content-desc='我的']"    timeout="10000"    outKey="output"/>
```
