# 场景 D：上传文件指令（`UploadFileFromS3`）

**目标**：单独跑通 `UploadFileFromS3` 指令，验证元素选择器 + S3 路径两个必填字段的落库与执行。

**工作流命名建议**：`上传文件测试-YYYYMMDD`（或用户指定名称）

**触发关键词**：上传文件、UploadFileFromS3、`input[type=file]` 测试、图片上传组件、附件上传指令测试

---

## 指令背景（必读）

参考 [commands/uploadfilefroms3.md](../commands/uploadfilefroms3.md)：

- 底层实现是 **Playwright `setInputFiles()`**，需要目标 XPath 指向**原生 `<input type='file'>` 元素**
- 非原生（`<div>` / `<button>` 触发系统 file dialog）的上传按钮**必定失败**（`所有文件上传策略都失败了`）
- `文件S3路径` 支持 **HTTP(S)** 前缀（走 HTTP 下载再喂给 file input）；**不支持** `s3://` 协议（`未知协议:s3`）
- `文件S3路径` 也支持 rpa 官方 S3 域名 `s3plus.sankuai.com`

---

## 云浏览器网络与前端限制清单（本场景踩坑总结）

| 类型 | 现象 | 判定 |
|---|---|---|
| 外网站点（GitHub、Heroku、AntD 官网 `ant-design.antgroup.com`、file.io） | `net::ERR_TUNNEL_CONNECTION_FAILED` 或「打开网页超时异常」 | **不通** — 云浏览器封外网 |
| `data:text/html;...` URL | 「无法导航到无效的URL」 | **不通** — rpa 平台前置 URL 校验拒 `data:` 协议 |
| 内网 SPA 页面（`image.baidu.com`、`rpa.sankuai.com/rpa/chat`） | 「所有文件上传策略都失败了」 | **不通** — file input 是 SPA 动态注入 + label 触发原生 dialog，`setInputFiles` 无法直接赋值 |
| `s3://xxx` 前缀 S3 路径 | 「文件下载异常，未知协议:s3」 | **不通** — 平台不识别 `s3://` |
| **`https://` 前缀 S3 或 CDN 图片** | ✅ 走 HTTP 下载 | **可用** — 首选 `https://www.baidu.com/img/flexible/logo/pc/result.png` 或 s3plus 域名 |

## 通路选择（按可靠性）

| 通路 | URL | 需中间点击 | 推荐度 |
|---|---|---|---|
| **通路 A · s3plus 静态 HTML**（首选） | `https://s3plus.sankuai.com/v1/<你的-mss-bucket>/upload-test.html` | 无 | ⭐⭐⭐ 一次配好长期复用 |
| **通路 B · rpa 自身新建工作流→自定义上传** | `https://rpa.sankuai.com/space/<SPACE>/rpa/workflow` | **需 3 次点击**：新建按钮 → 头像 → 「自定义上传」tab | ⭐⭐ 内网稳定但 XPath 需捕获 |
| ❌ 通路 C · 外网 AntD 官方 Upload demo | `https://ant-design.antgroup.com/components/upload-cn` | 无 | 不通（外网封锁） |
| ❌ 通路 D · data URL 内嵌 file input | `data:text/html,...` | 无 | 不通（rpa 拒 data 协议） |

---

## 通路 A：s3plus 静态 HTML（推荐）

### A.1 准备测试页

将下面 HTML 上传到你名下任一 `mss_xxx` bucket，得到公开可访问 URL：

```html
<!doctype html><html><head><meta charset="utf-8"><title>Upload Test</title></head>
<body>
  <h1>UploadFileFromS3 Test</h1>
  <input id="file-upload" type="file" name="file"/>
  <p id="result">Ready</p>
</body></html>
```

放在如 `https://s3plus.sankuai.com/v1/mss_<hash>/upload-test.html`。

### A.2 工作流节点（2 条）

| # | 指令 | 关键配置 |
|---|---|---|
| 1 | 打开网页 | 网址：**s3plus 静态 HTML URL**（`pbcopy` 粘贴，见 [url-input.md](../url-input.md)） |
| 2 | 上传文件 | 元素选择器：`//*[@id="file-upload"]` 或 `//input[@type="file"]`；文件S3路径：`https://www.baidu.com/img/flexible/logo/pc/result.png`（任意 https 图片，云浏览器内网可访问） |

调试预期：两个节点全部 `check-circle`。

---

## 通路 B：rpa 自身「新建工作流 → 自定义上传」

### B.1 UI 路径

`rpa.sankuai.com/space/<SPACE>/rpa/workflow`
→ 点顶部「**+ 新建工作流**」按钮
→ 弹框内点**头像图片**（触发头像选择面板，含 3 个 tab：系统 / 图标 / **自定义上传**）
→ 点「**自定义上传**」tab（AntD Upload 组件渲染 `<input type=file>` 到 DOM）
→ `UploadFileFromS3` 指向该 file input

### B.2 工作流节点（5 条）

| # | 指令 | 元素选择器 XPath | 说明 |
|---|---|---|---|
| 1 | 打开网页 | — | 网址：`https://rpa.sankuai.com/space/<SPACE>/rpa/workflow` |
| 2 | 点击（web） | `//button[contains(@class,"ant-btn-primary")]` | 「+ 新建工作流」按钮，纯 ASCII XPath 已实测落库成功 |
| 3 | 点击（web） | ⚠️ 需**平台捕获**采集 | 头像图片（弹框顶部头像 SVG，class 是 CSS Modules 哈希，普通 XPath 全部超时） |
| 4 | 点击（web） | ⚠️ 需**平台捕获**采集 | 「自定义上传」tab（不是标准 `ant-tabs-tab` 类，`role="tab"` 也命中错元素） |
| 5 | 上传文件 | `//input[@type="file"]` | 文件S3路径：`https://www.baidu.com/img/flexible/logo/pc/result.png` |

### B.3 已验证的失败 XPath（作为反例）

以下 XPath 对**节点 3、4** 都超时（`ClickElementMixed,点击失败，超时5000ms`）：

- `(//div[@role="tab"])[3]` — 命中的是 rpa 左侧 Chat/指令/元素/子流程 tab
- `//div[contains(@class,"ant-modal")]//div[@role="tab"][last()]` — rpa 弹框类非标准 `ant-modal`
- `(//div[contains(@class,"ant-tabs-tab")])[last()]` — 弹框 tab 类是运行时哈希
- `//button[contains(., "新建工作流")]` — 含中文字符串字面量，**保存后 canvas 显示 `selectorId` 落库失败**（点击类指令对复杂 XPath 表达式校验严格）

结论：**含中文字面量的 XPath** 与 **依赖 antd 标准类名的 XPath** 在 rpa 平台点击指令上落库不稳；应走**方式 B 平台捕获**。

---

## 元素选择器写入策略（本场景强绑定）

按 [element-selector.md](../element-selector.md) 优先级：

| 优先级 | 方式 | 何时用 |
|---|---|---|
| **1** | **方式 C：`pbcopy` + `Cmd+V` + `Enter`**（默认）| `UploadFileFromS3` 的 `//input[@type="file"]`（纯 ASCII）稳定成功 |
| **2** | **方式 B：平台「捕获」**（退而求其次）| 通路 B 的节点 3、4（头像 / 自定义上传 tab）中文字面量 XPath 落库失败时 |

⚠️ 关键强制铁律（本场景实战验证）：

1. **XPath 落库不稳时**（含中文字符串、依赖运行时 hash 类名）→ **必须**转平台捕获，不要死磕手写
2. **通路 A 优先**：一次上传测试页 HTML，工作流永远只需 2 节点，避免走 5 节点强依赖捕获
3. **S3 路径协议**：只用 `https://`，禁用 `s3://`；HTTP 图片 URL 云浏览器需内网可达（`baidu.com` / `s3plus.sankuai.com` 已实测通）
4. **XPath 必须指向原生 `<input type=file>`**：SPA 的 label / 自定义 button 触发 dialog **不满足**，会报「所有文件上传策略都失败」

---

## 执行步骤（通路 A 简版）

按 [test-workflow.md](../test-workflow.md) 标准流程：

1. rpa.sankuai.com **首页** → 点「工作流」→ 新建**空**编排工作流
2. **第 1 条 · 打开网页**：点 canvas「拖拽添加指令」提示行 → 右侧搜索框搜「打开网页」→ 双击 (web) 结果 → 网址栏 `pbcopy` 粘贴 s3plus HTML URL → 保存
3. **第 2 条 · 上传文件**：选中「打开网页」→ Enter 创建空行 → 搜「上传文件」→ 双击结果 → 元素选择器组合框 `pbcopy` + `Cmd+V` `//input[@type="file"]` + `Enter` → 文件 S3 路径粘贴 `https://www.baidu.com/img/flexible/logo/pc/result.png` → 保存
4. 点「**检查**」确认无「配置异常节点」
5. **调试 → 运行**
6. 聊天区应显示：`打开网页(web) ✅` + `上传文件 ✅`（通常 < 1s）
7. 如报错，按 [debug.md](../debug.md) 修复

---

## 通路 B 执行步骤（依赖平台捕获）

按 [test-workflow.md](../test-workflow.md)，但节点 3、4 的 XPath 采集**必须走方式 B**：

1. 完成节点 1（打开网页）+ 节点 2（点击 - 新建工作流按钮，`//button[contains(@class,"ant-btn-primary")]` 可手写）
2. 添加节点 3（点击 - 头像图片）：**不要手写 XPath**，直接进入弹框
3. 点顶部「调试」→ 让工作流跑到节点 2 打开新建对话框后停下
4. 双击节点 3 弹框 → 点「**捕获**」按钮 → 云浏览器 VNC 里点选头像图片 → 平台自动生成 selectorId → 保存
5. 同理为节点 4（自定义上传 tab）走捕获
6. 添加节点 5（上传文件），元素选择器 `//input[@type="file"]`（此时 file input 已渲染到 DOM）
7. 全链路调试运行

捕获详见 [capture-element.md](../capture-element.md)。

---

## 常见踩坑与修复

| 现象 | 原因 | 修复 |
|---|---|---|
| `打开网页超时异常`（外网站点） | 云浏览器封外网 | 换通路 A（内网 s3plus HTML） |
| `未知协议:s3` | S3 路径用了 `s3://` 前缀 | 改用 `https://` 前缀 |
| `所有文件上传策略都失败了` | 元素选择器指向非原生 file input（SPA label / 触发 dialog 的 button） | 换页面到通路 A 或通路 B 的自定义上传 tab；确保 XPath 指向真实 `<input type=file>` |
| `ClickElementMixed,点击失败，超时5000ms`（点击类指令） | XPath 含中文字面量 或 依赖 antd 标准类名但实际是 CSS Modules hash | 转平台捕获（方式 B） |
| canvas 节点显示 `selectorId 元素...`（保存后 XPath 未落库） | AntD Select 未 confirm-input 为 tag | 双击重开弹框 → click 组合框 → `Cmd+A` → `Delete` → `Cmd+V` → **Enter**（三步紧凑，见 `element-selector.md` §方式 C 决策表） |
| `无法导航到无效的URL` | `data:text/html,...` | rpa 拒 data 协议，改真实 URL |

其他修复见 [debug.md](../debug.md)。

---

## 参考

- [commands/uploadfilefroms3.md](../commands/uploadfilefroms3.md) — 指令参数
- [element-selector.md](../element-selector.md) — 方式 C / B 完整流程
- [capture-element.md](../capture-element.md) — 平台捕获 6 步
- [url-input.md](../url-input.md) — 网址字段填写规范
- [debug.md](../debug.md) — 报错对照表
