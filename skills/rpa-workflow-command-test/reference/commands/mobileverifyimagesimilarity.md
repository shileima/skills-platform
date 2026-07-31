# 验证图片相似度>90%

- **指令标识**：`MobileVerifyImageSimilarity`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/mobileverifyimagesimilarity/
- **说明**：验证特定图片在手机当前屏幕的相似度是否超过指定阈值，输出验证结果（True或False）
- **必填输入参数**：`测试文件的S3地址`, `目标文件的S3地址`
- **必填输出参数**：`将结果保存至`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 测试文件的S3地址 | String | 是 | - | 待测图片s3地址 |
| 目标文件的S3地址 | String | 是 | - | 目标图片s3地址 |

## 输出参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 将结果保存至 | Boolean | 是 | - | 输出指令的结果 |

## XML 示例

```xml
<MobileVerifyImageSimilarity    assertFile="待测图片的S3地址"    targetFile="目标图片的S3地址"    outKey="output"/>
```
