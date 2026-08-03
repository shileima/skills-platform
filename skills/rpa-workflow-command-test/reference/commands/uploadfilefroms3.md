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

## 适用性预判清单（实战踩坑，配置前必核对）

底层实现是 **Playwright `setInputFiles()`**，需目标 XPath 指向**原生 `<input type='file'>`**。逐条对照后再配表：

| 检查项 | 通过标准 | 失败现象 |
|---|---|---|
| 元素选择器 | 指向真实的 `<input type="file">` DOM 元素 | `所有文件上传策略都失败了`（SPA label / 触发 dialog 的 button 不满足） |
| S3 路径协议 | `https://` 前缀（含 `s3plus.sankuai.com/...`、`www.baidu.com/img/...` 等 http 图片） | `未知协议:s3`（不支持 `s3://xxx`） |
| S3 URL 内网可达 | 云浏览器能 GET 该 URL | HTTP 403 / 404 / 超时（避开外网站点） |
| 目标页 URL | 云浏览器可访问（内网 or `www.baidu.com` / `rpa.sankuai.com` / `s3plus.sankuai.com`） | 「打开网页超时异常」（外网站点如 `ant-design.antgroup.com`、`the-internet.herokuapp.com`、`file.io` **不通**）；`data:text/html,...` URL 被 rpa 前置校验拒（「无法导航到无效的URL」） |

## 推荐通路

见 [scenarios/upload-file.md](../scenarios/upload-file.md)：

- **通路 A**：把带 `<input type=file>` 的静态 HTML 上传到 `s3plus.sankuai.com/v1/<mss_bucket>/upload-test.html`，工作流只需 2 节点（打开网页 + 上传文件）—— **首选**
- **通路 B**：走 rpa 平台自身「新建工作流 → 头像 → 自定义上传 tab」5 节点链路（含 AntD Upload 原生 file input），头像和 tab 的 XPath **必须走方式 B 平台捕获**

## 已知失败案例（避坑参考）

| URL | XPath | 结果 |
|---|---|---|
| `https://ant-design.antgroup.com/components/upload-cn` | `//input[@type="file"]` | 打开网页 45s 超时（外网封锁） |
| `data:text/html;...` 内嵌 file input | — | 无法导航到无效的URL |
| `https://image.baidu.com/` | `//input[@type="file"]` | 找得到元素但 setInputFiles 超时（SPA 动态注入 + 触发 dialog） |
| `https://rpa.sankuai.com/rpa/chat` | `//input[@type="file"]` | 同上 |
| S3 路径 = `s3://test/dummy.txt` | — | `未知协议:s3` |
