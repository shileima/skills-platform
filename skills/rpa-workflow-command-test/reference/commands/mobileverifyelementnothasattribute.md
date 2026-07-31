# 验证元素没有属性

- **指令标识**：`MobileVerifyElementNotHasAttribute`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/mobileverifyelementnothasattribute/
- **说明**：验证手机当前屏幕中的特定UI元素没有选定的属性,输出验证结果（True或False）
- **必填输入参数**：`元素选择器`, `元素属性名称`
- **必填输出参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 元素选择器 | String | 是 | - | 元素定位方式， eg：id、xpath、text、accessibilityId 等，不能为空 |
| 元素属性名称 | String | 是 | - | 要获取的元素属性名， eg：text、checked、content-desc |
| 超时时间 | Double | 否 | 10000 | 指令最大等待时间（毫秒）， >0 时 Controller 会根据该值计算重试次数 |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | - | 输出指令的结果， True 表示元素不具有属性， False 表示元素具有属性 |

## XML 示例

```xml
<MobileVerifyElementNotHasAttribute    selector="//*[@text='我的']"    attributeName="clickable"    timeout="10000"    outKey="output"/>
```
