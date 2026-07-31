# 获取下拉框选项数量

- **指令标识**：`GetNumberOfTotalOption`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/getnumberoftotaloption/
- **说明**：获取指定下拉框（select元素）中所有option选项的总数量，包括选中和未选中的选项
- **必填输入参数**：`元素选择器`
- **必填输出参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 元素选择器 | String | 是 | - | 用于定位下拉框元素的选择器，必须指向 select 元素，选择器不能为空，支持从元素库选择元素或手动填写XPath等定位器值 |
| iframe页面定位器 | String | 否 | - | iframe的XPath，非必填，如果目标元素在iframe中则需要填写，例如：//html/iframe |
| 定位超时 | Double | 否 | 5000 | 元素定位的最大等待时间，单位 毫秒 ，默认值 5000ms 。设置为 0 表示不等待 |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | - | 填写变量名称（例如：totalCount），保存获取到的选项总数，返回整数类型 |

## XML 示例

```xml
<GetNumberOfTotalOption    selector="//*[@id='country-select']"    findElementOptions="{'timeout':5000}"    outKey="output"/>
```
