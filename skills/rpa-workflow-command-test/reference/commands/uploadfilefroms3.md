# 上传文件

- **指令标识**：`UploadFileFromS3`
- **指令类型**：网页指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/uploadfilefroms3/
- **说明**：从S3拉取文件并将文件上传到类型为’file’的输入框中，支持多种上传策略
- **必填输入参数**：`元素选择器`, `文件S3路径`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| 元素选择器 | String | 是 | - | 用于选择文件上传控件的元素选择器，选择器不能为空，通常指向input[type=‘file’]元素，支持选择元素库元素/手动填写XPath等定位器值 |
| 文件S3路径 | String | 是 | - | 需要上传文件的S3存储路径，支持多个文件用逗号分隔，路径不能为空 |
| 上传超时 | Double | 否 | 30000 | 上传文件最大等待时间，默认 30000ms 。 |
| iframe页面定位器 | String | 否 | - | iframe的xpath，非必填，如果目标元素在iframe中则需要填存， eg：//html/iframe |
| 定位超时 | Double | 否 | 5000 | 元素定位的最大等待时间，单位 毫秒 ，默认值 5000ms 。设置为 0 表示不等待。 |

## XML 示例

```xml
<UploadFileFromS3    selector="//input[@type='file']"    s3Paths="https://s3plus.sankuai.com/aiagent-bucket/test-file.png"    inputFilesOptions="{'timeout':30000}"    findElementOptions="{'timeout':5000}"/>
```
