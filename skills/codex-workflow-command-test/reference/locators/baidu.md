# baidu 首页 — 元素定位器缓存

> **自动生成**，请勿手改。更新：`bash scripts/update-locators.sh baidu`

## 缓存信息

| 项 | 值 |
|----|-----|
| 站点 | baidu |
| 页面 | home |
| URL | https://www.baidu.com/ |
| 标题 | 百度一下，你就知道 |
| 采集时间 | 2026-07-29T13:29:46.149Z |
| 元素数量 | 39 |
| 采集器版本 | 1.1.0 |
| 完整数据 | [baidu.elements.json](./baidu.elements.json) |

## 快捷 XPath

- **搜索框**：`//*[@id="kw"]`
  - 标签限定 XPath：`//input[@id="kw"]`
- **搜索按钮**：`//*[@id="su"]`
  - 标签限定 XPath：`//input[@id="su"]`

> **本环境采集探测**：variant=`kw`，input=`kw`，wrapper=`wrapper_new`

> **适用 URL**：`https://www.baidu.com/`（标题「百度一下，你就知道」）
> ⚠️ **同一 URL 存在两种 UI**：
> - 经典版：`input#kw` + `input#su`
> - 智能输入版：`textarea#chat-textarea` + `button#chat-submit-button`
> **云浏览器（bots 调试）与本地 Playwright 可能不同**。配置 FillText 前必须在**云浏览器 DevTools** 探测可见输入框，**禁止仅凭 URL 或缓存文件名断定**。
> 探测命令见 `reference/element-selector.md` §百度搜索框探测。

## 全部可见元素（按标签分组）

### A (26)

| 标签/文本 | id | name | XPath |
|----------|-----|------|-------|
| 登录 | - | tj_login | `//a[name="tj_login"]` |
| 新闻 | - | - | `/body[1]/div[1]/div[1]/div[1]/a[1]` |
| hao123 | - | - | `/body[1]/div[1]/div[1]/div[1]/a[2]` |
| 地图 | - | - | `/body[1]/div[1]/div[1]/div[1]/a[3]` |
| 直播 | - | - | `/body[1]/div[1]/div[1]/div[1]/a[4]` |
| 视频 | - | - | `/body[1]/div[1]/div[1]/div[1]/a[5]` |
| 贴吧 | - | - | `/body[1]/div[1]/div[1]/div[1]/a[6]` |
| 学术 | - | - | `/body[1]/div[1]/div[1]/div[1]/a[7]` |
| 更多 | - | tj_briicon | `//a[name="tj_briicon"]` |
| 总书记的一周 | - | - | `/body[1]/div[1]/div[1]/div[3]/div[1]/div[2]/ul[1]/li[1]/a[1]` |
| 5微信新功能上线 可一键删除单向好友 | - | - | `/body[1]/div[1]/div[1]/div[3]/div[1]/div[2]/ul[1]/li[2]/a[1]` |
| 1习近平出席民营企业座谈会并讲话 | - | - | `/body[1]/div[1]/div[1]/div[3]/div[1]/div[2]/ul[1]/li[3]/a[1]` |
| 6这下遇到真石矶娘娘了 | - | - | `/body[1]/div[1]/div[1]/div[3]/div[1]/div[2]/ul[1]/li[4]/a[1]` |
| 2《哪吒2》超《狮子王》进全球票房前10 | - | - | `/body[1]/div[1]/div[1]/div[3]/div[1]/div[2]/ul[1]/li[5]/a[1]` |
| 7于正发长文致歉 | - | - | `/body[1]/div[1]/div[1]/div[3]/div[1]/div[2]/ul[1]/li[6]/a[1]` |
| 3“村超”持续助推乡村振兴 | - | - | `/body[1]/div[1]/div[1]/div[3]/div[1]/div[2]/ul[1]/li[7]/a[1]` |
| 8尼格买提：别找了结界兽在禾木 | - | - | `/body[1]/div[1]/div[1]/div[3]/div[1]/div[2]/ul[1]/li[8]/a[1]` |
| 4《哪吒2》总票房突破120亿 | - | - | `/body[1]/div[1]/div[1]/div[3]/div[1]/div[2]/ul[1]/li[9]/a[1]` |
| 9大学生60米栏跑出7.53酷似刘翔 | - | - | `/body[1]/div[1]/div[1]/div[3]/div[1]/div[2]/ul[1]/li[10]/a[1]` |
| 关于百度 | - | - | `/body[1]/div[1]/div[1]/div[4]/div[1]/p[1]/a[1]` |
| About Baidu | - | - | `/body[1]/div[1]/div[1]/div[4]/div[1]/p[2]/a[1]` |
| 使用百度前必读 | - | - | `/body[1]/div[1]/div[1]/div[4]/div[1]/p[3]/a[1]` |
| 帮助中心 | - | - | `/body[1]/div[1]/div[1]/div[4]/div[1]/p[4]/a[1]` |
| 京公网安备11000002000001号 | - | - | `/body[1]/div[1]/div[1]/div[4]/div[1]/p[5]/a[1]` |
| 京ICP证030173号 | - | - | `/body[1]/div[1]/div[1]/div[4]/div[1]/p[6]/a[1]` |
| 信息网络传播视听节目许可证 0110516 | - | - | `/body[1]/div[1]/div[1]/div[4]/div[1]/p[9]/a[1]` |

### DIV (8)

| 标签/文本 | id | name | XPath |
|----------|-----|------|-------|
| 新闻 hao123 地图 直播 视频 贴吧 学术 更多 登录   总书记的 | wrapper | - | `//div[@id="wrapper"]` |
| 新闻 hao123 地图 直播 视频 贴吧 学术 更多 登录   总书记的 | head | - | `//div[@id="head"]` |
| 新闻 hao123 地图 直播 视频 贴吧 学术 更多 | s-top-left | - | `//div[@id="s-top-left"]` |
|   总书记的一周 5微信新功能上线 可一键删除单向好友 热 1习近平出席民 | head_wrapper | - | `//div[@id="head_wrapper"]` |
| 登录 | u1 | - | `//div[@id="u1"]` |
| #lg | lg | - | `//div[@id="lg"]` |
|   总书记的一周 5微信新功能上线 可一键删除单向好友 热 1习近平出席民 | s-hotsearch-wrapper | - | `//div[@id="s-hotsearch-wrapper"]` |
| 关于百度 About Baidu 使用百度前必读 帮助中心 京公网安备11000 | bottom_layer | - | `//div[@id="bottom_layer"]` |

### FORM (1)

| 标签/文本 | id | name | XPath |
|----------|-----|------|-------|
| #form | form | f | `//form[@id="form"]` |

### IMG (1)

| 标签/文本 | id | name | XPath |
|----------|-----|------|-------|
| #s_lg_img | s_lg_img | - | `//img[@id="s_lg_img"]` |

### INPUT (2)

| 标签/文本 | id | name | XPath |
|----------|-----|------|-------|
| #kw | kw | wd | `//input[@id="kw"]` |
| #su | su | - | `//input[@id="su"]` |

### SPAN (1)

| 标签/文本 | id | name | XPath |
|----------|-----|------|-------|
| ©2026 Baidu | year | - | `//span[@id="year"]` |
