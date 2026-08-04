# 验证图片存在

- **指令标识**：`MobileVerifyImagePresent`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/mobileverifyimagepresent/
- **说明**：验证特定图片在手机当前屏幕是否存在，输出验证结果（True或False）
- **必填输入参数**：`图片S3地址`
- **必填输出参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 对比图片相似度 | Double | 否 | - | 设置要验证图片相似度 |
| 图片S3地址 | String | 是 | - | 图片的S3 url地址 |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | Boolean | 是 | - | 输出指令的结果，输出 True 或 False |

## XML 示例

```xml
<MobileVerifyImagePresent    imageFilePath="your_image_s3_url"    similarityValue="0.9"    outKey="output"/>
```
