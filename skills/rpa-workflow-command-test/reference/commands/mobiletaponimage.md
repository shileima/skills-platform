# 点击图像

- **指令标识**：`MobileTapOnImage`
- **指令类型**：移动端指令
- **官方文档**：https://document.waimai.st.sankuai.com/commands/ui-commands/mobiletaponimage/
- **说明**：在移动设备上通过图像匹配并点击指定位置
- **必填输入参数**：`imageFilePath`

## 输入参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| imageFilePath | String | 是 | - | 要点击图片的S3地址，断言基准图片 S3 URL，用于图像比对 |

## XML 示例

```xml
<MobileTapOnImage    imageFilePath="https://s3plus.sankuai.com/aiagent-bucket/00%E6%96%87%E6%A1%A3%E7%AB%99%E7%82%B9%E5%9B%BE%E7%89%87/%E7%A7%BB%E5%8A%A8%E6%8C%87%E4%BB%A4/%E7%BE%8E%E5%9B%A2-%E5%A4%96%E5%8D%96.png"/>
```
