# 截图

- **指令标识**：`TakeScreenshot`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/takescreenshot/
- **说明**：对当前页面进行截图并保存到S3服务器，支持多种截图配置选项
- **必填输出参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 起点横坐标 | Double | 否 | 0 | 截图区域的起点横坐标，用于局部截图 |
| 起点纵坐标 | Double | 否 | 0 | 截图区域的起点纵坐标，用于局部截图 |
| 截图宽度(px) | Double | 否 | - | 截图区域的宽度，单位为像素。全屏截图 关闭 时，该参数 必填 |
| 截图高度(px) | Double | 否 | - | 截图区域的高度，单位为像素。全屏截图 关闭 时，该参数 必填 |
| 全屏截图 | Boolean | 否 | true | 用于截取整个可滚动页面的完整截图。默认打开。。 |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | String | 是 | - | 填写变量名称（ eg：screenshotPath ），保存截图文件的访问URL，返回字符串类型 |

## XML 示例

```xml
<TakeScreenshot    screenshotOption="{'clip':{'x':0,'y':0,'width':100,'height':100},'fullPage':false}"    outKey="output"/>
```
