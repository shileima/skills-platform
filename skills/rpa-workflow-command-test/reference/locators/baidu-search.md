# baidu 搜索结果页 — 元素定位器缓存

> **自动生成**，请勿手改。更新：`bash scripts/update-locators.sh baidu-search`

## 缓存信息

| 项 | 值 |
|----|-----|
| 站点 | baidu |
| 页面 | search |
| URL | https://www.baidu.com/s?ie=utf-8&f=8&rsv_bp=1&rsv_idx=1&ch=&tn=baidu&bar=&wd=%E4%BD%A0%E5%A5%BD&rn=&fenlei=256&oq=&rsv_pq=b9ff093e0000e419&rsv_t=3635FYbdbC8tlWmudZmYaUnaucNe%2BRzTzNEGqg%2FJuniQU10WL5mtMQehIrU&rqlang=cn&rsv_enter=1&rsv_dl=ib |
| 标题 | 你好_百度搜索 |
| 采集时间 | 2026-07-29T13:21:58.623Z |
| 元素数量 | 98 |
| 采集器版本 | 1.0.0 |
| 完整数据 | [baidu-search.elements.json](./baidu-search.elements.json) |

## 快捷 XPath

- **搜索框**：`//*[@id="chat-textarea"]`
  - 标签限定 XPath：`//textarea[@id="chat-textarea"]`
- **搜索按钮**：`//*[@id="chat-submit-button"]`
  - 标签限定 XPath：`//button[@id="chat-submit-button"]`

> **适用 URL**：`https://www.baidu.com/s?...`（搜索结果页）
> 顶栏搜索框为 `textarea#chat-textarea`，旧版 `input#kw` 此时隐藏。
> 首页搜索请用 [baidu.md](./baidu.md)。
- **首条结果区域**：`/body[1]/div[2]/div[4]/div[1]/div[3]/div[1]/div[1]/h3[1]`

## 全部可见元素（按标签分组）

### A (62)

| 标签/文本 | id | name | XPath |
|----------|-----|------|-------|
| #result_logo | result_logo | - | `//a[@id="result_logo"]` |
| 登录 | - | tj_login | `/body[1]/div[2]/div[1]/div[1]/div[2]/a[3]` |
| 百度首页 | - | - | `/body[1]/div[2]/div[1]/div[1]/div[2]/a[1]` |
| 设置 | - | tj_settingicon | `/body[1]/div[2]/div[1]/div[1]/div[2]/a[2]` |
| a | - | - | `/body[1]/div[2]/div[3]/div[1]/div[1]/a[1]` |
| 图片 | - | - | `/body[1]/div[2]/div[3]/div[1]/div[1]/a[2]` |
| 资讯 | - | - | `/body[1]/div[2]/div[3]/div[1]/div[1]/a[3]` |
| 视频 | - | - | `/body[1]/div[2]/div[3]/div[1]/div[1]/a[4]` |
| 笔记 | - | - | `/body[1]/div[2]/div[3]/div[1]/div[1]/a[5]` |
| 地图 | - | - | `/body[1]/div[2]/div[3]/div[1]/div[1]/a[6]` |
| 贴吧 | - | - | `/body[1]/div[2]/div[3]/div[1]/div[1]/a[7]` |
| 文库 | - | - | `/body[1]/div[2]/div[3]/div[1]/div[1]/a[8]` |
| 更多 | - | - | `/body[1]/div[2]/div[3]/div[1]/div[1]/a[9]` |
| 你好 - 百度百科 | - | - | `/body[1]/div[2]/div[4]/div[1]/div[3]/div[1]/div[1]/h3[1]/a[1]` |
| 你好之后怎么聊天 | - | - | `/div[1]/div[1]/div[1]/div[1]/div[1]/div[2]/div[1]/div[1]/a[1]` |
| 您好 你好 | - | - | `/div[1]/div[1]/div[1]/div[1]/div[1]/div[2]/div[2]/div[1]/a[1]` |
| 你好邻居正式版下载 | - | - | `/div[1]/div[1]/div[1]/div[1]/div[1]/div[2]/div[3]/div[1]/a[1]` |
| 详情 | - | - | `/div[1]/div[2]/div[1]/div[1]/div[1]/p[1]/span[3]/span[1]/a[1]` |
|  | - | - | `/div[1]/div[2]/div[1]/div[1]/div[1]/p[1]/span[3]/span[1]/a[2]` |
| 檀健次的个人资料简介介绍 | - | - | `/div[1]/div[1]/div[1]/div[1]/div[1]/div[2]/div[4]/div[1]/a[1]` |
| 影响 | - | - | `/div[1]/div[2]/div[1]/div[2]/div[2]/div[1]/div[1]/div[1]/a[1]` |
| 你好释义 | - | - | `/div[1]/div[2]/div[1]/div[2]/div[2]/div[1]/div[1]/div[2]/a[1]` |
| 类似问候语 | - | - | `/div[1]/div[2]/div[1]/div[2]/div[2]/div[1]/div[1]/div[3]/a[1]` |
| 例句与英文 | - | - | `/div[1]/div[2]/div[1]/div[2]/div[2]/div[1]/div[1]/div[4]/a[1]` |
| 来了来了要来了 | - | - | `/div[1]/div[1]/div[1]/div[1]/div[1]/div[2]/div[5]/div[1]/a[1]` |
| 哈喽 | - | - | `/div[1]/div[1]/div[1]/div[1]/div[1]/div[2]/div[6]/div[1]/a[1]` |
| 百度百科 | - | - | `/div[4]/div[1]/div[3]/div[1]/div[1]/div[2]/div[1]/div[1]/a[1]` |
| 换一换 | - | - | `/td[1]/div[1]/div[2]/div[1]/div[1]/div[1]/div[1]/div[1]/a[1]` |
|  | - | - | `/tr[1]/td[1]/div[1]/div[2]/div[1]/div[1]/div[1]/div[1]/a[1]` |
| 你好,星期六 2025-综艺高清视频在线观看 | - | - | `/body[1]/div[2]/div[4]/div[1]/div[3]/div[2]/div[1]/h3[1]/a[1]` |
| 真人秀 | - | - | `/div[4]/div[1]/div[3]/div[2]/div[1]/div[1]/div[2]/div[1]/a[1]` |
| a | - | - | `/div[2]/div[4]/div[1]/div[3]/div[2]/div[1]/div[1]/div[1]/a[1]` |
| 促进团结奋斗 汇聚磅礴力量 | - | - | `/div[2]/div[1]/div[1]/div[1]/div[3]/div[1]/div[1]/div[1]/a[1]` |
| 内地 | - | - | `/div[4]/div[1]/div[3]/div[2]/div[1]/div[1]/div[2]/div[2]/a[1]` |
| 大陆 | - | - | `/div[4]/div[1]/div[3]/div[2]/div[1]/div[1]/div[2]/div[2]/a[2]` |
| 银行大面积调整营业时间 | - | - | `/div[2]/div[1]/div[1]/div[1]/div[3]/div[1]/div[2]/div[1]/a[1]` |
| 斯洛伐克总统怀疑中国机器人藏真人 | - | - | `/div[2]/div[1]/div[1]/div[1]/div[3]/div[1]/div[3]/div[1]/a[1]` |
| 从四款出口“爆品”看“中国智造” | - | - | `/div[2]/div[1]/div[1]/div[1]/div[3]/div[1]/div[4]/div[1]/a[1]` |
| 电影《八仙！》热映带火取景地悬空寺 | - | - | `/div[2]/div[1]/div[1]/div[1]/div[3]/div[1]/div[5]/div[1]/a[1]` |
| 小区电梯突然失控从31楼下坠到负2楼 | - | - | `/div[2]/div[1]/div[1]/div[1]/div[3]/div[1]/div[6]/div[1]/a[1]` |
| 演员修杰楷当庭认罪 | - | - | `/div[2]/div[1]/div[1]/div[1]/div[3]/div[1]/div[7]/div[1]/a[1]` |
| 赵心童vs丁俊晖 | - | - | `/div[2]/div[1]/div[1]/div[1]/div[3]/div[1]/div[8]/div[1]/a[1]` |
| 最新 2025-12-28 | - | - | `/div[1]/div[3]/div[2]/div[1]/div[3]/div[1]/div[1]/div[1]/a[1]` |
| 2025-12-27 | - | - | `/div[1]/div[3]/div[2]/div[1]/div[3]/div[1]/div[2]/div[1]/a[1]` |
| 2025-12-26 | - | - | `/div[1]/div[3]/div[2]/div[1]/div[3]/div[1]/div[3]/div[1]/a[1]` |
| 想去东北避暑 结果东北人也去避暑了 | - | - | `/div[2]/div[1]/div[1]/div[1]/div[3]/div[1]/div[9]/div[1]/a[1]` |
| 粉笔投资亏损超5600万元 | - | - | `/div[2]/div[1]/div[1]/div[1]/div[3]/div[1]/div[10]/div[1]/a[1]` |
| 《庆余年》演员入职景区当NPC | - | - | `/div[2]/div[1]/div[1]/div[1]/div[3]/div[1]/div[11]/div[1]/a[1]` |
| 宋威龙赵今麦答题名场面默契来袭 杨迪爆梗帅气秘诀竟是挡脸大法 | - | - | `/div[2]/div[1]/div[3]/div[1]/div[1]/div[1]/div[1]/div[1]/a[1]` |
| 宋威龙赵今麦复刻高甜拥抱 丁程鑫杨迪刻进DNA的默契答题 | - | - | `/div[2]/div[1]/div[3]/div[1]/div[2]/div[1]/div[1]/div[1]/a[1]` |
| 你好,星期六2025 超前探班第34期:宋威龙赵今麦好六街合照甜度爆表 丁程鑫巧 | - | - | `/div[2]/div[1]/div[3]/div[1]/div[3]/div[1]/div[1]/div[1]/a[1]` |
| “喀什经开区零地价供地”系谣言 | - | - | `/div[2]/div[1]/div[1]/div[1]/div[3]/div[1]/div[12]/div[1]/a[1]` |
| 查看更多 | - | - | `/div[2]/div[4]/div[1]/div[3]/div[2]/div[1]/div[3]/div[2]/a[1]` |
| 这8个饮食习惯悄悄“吃掉”免疫力 | - | - | `/div[2]/div[1]/div[1]/div[1]/div[3]/div[1]/div[13]/div[1]/a[1]` |
| a | - | - | `/body[1]/div[2]/div[4]/div[1]/div[3]/div[2]/div[1]/div[4]/a[1]` |
| 下班了 年轻人赶着去做副业 | - | - | `/div[2]/div[1]/div[1]/div[1]/div[3]/div[1]/div[14]/div[1]/a[1]` |
| 保姆因无法生育 拐走雇主家男婴35年 | - | - | `/div[2]/div[1]/div[1]/div[1]/div[3]/div[1]/div[15]/div[1]/a[1]` |
| a | - | - | `/div[3]/div[1]/div[1]/div[1]/div[1]/div[1]/div[1]/div[1]/a[1]` |
| a | - | - | `/div[3]/div[1]/div[1]/div[1]/div[1]/div[1]/div[1]/div[2]/a[1]` |
| a | - | - | `/div[3]/div[1]/div[1]/div[1]/div[1]/div[1]/div[1]/div[3]/a[1]` |
| a | - | - | `/div[3]/div[1]/div[1]/div[1]/div[1]/div[1]/div[1]/div[4]/a[1]` |
| “ABB”店名怎么越来越多了 | - | - | `/div[2]/div[1]/div[1]/div[1]/div[3]/div[1]/div[16]/div[1]/a[1]` |

### BUTTON (1)

| 标签/文本 | id | name | XPath |
|----------|-----|------|-------|
| 百度一下 | chat-submit-button | - | `//button[@id="chat-submit-button"]` |

### DIV (19)

| 标签/文本 | id | name | XPath |
|----------|-----|------|-------|
| 百度一下 百度首页设置登录 网页 图片 资讯 视频 笔记 地图 贴吧 文库 更多 | wrapper | - | `//div[@id="wrapper"]` |
| 百度一下 百度首页设置登录 | head | - | `//div[@id="head"]` |
| 网页 图片 资讯 视频 笔记 地图 贴吧 文库 更多 搜索工具 | s_tab | - | `//div[@id="s_tab"]` |
| 百度首页设置登录 | u | - | `//div[@id="u"]` |
| 百度一下 | chat-input-main | - | `//div[@id="chat-input-main"]` |
| 你好 | chat-input-area | - | `//div[@id="chat-input-area"]` |
| #right-tool | right-tool | - | `//div[@id="right-tool"]` |
| #voice-input-wrapper | voice-input-wrapper | - | `//div[@id="voice-input-wrapper"]` |
| 网页 图片 资讯 视频 笔记 地图 贴吧 文库 更多 搜索工具 | s_tab_inner | - | `//div[@id="s_tab_inner"]` |
| 相关搜索 你好之后怎么聊天 您好 你好 你好邻居正式版下载 檀健次的个人资料简介 | wrapper_wrapper | - | `//div[@id="wrapper_wrapper"]` |
| 相关搜索 你好之后怎么聊天 您好 你好 你好邻居正式版下载 檀健次的个人资料简介 | container | - | `//div[@id="container"]` |
| 你好 - 百度百科 你好是汉语常用问候语，拼音为nǐ hǎo，注音为ㄋㄧˇ ㄏㄠ | content_left | - | `//div[@id="content_left"]` |
| 相关搜索 你好之后怎么聊天 您好 你好 你好邻居正式版下载 檀健次的个人资料简介 | content_right | - | `//div[@id="content_right"]` |
| 相关搜索 你好之后怎么聊天 您好 你好 你好邻居正式版下载 檀健次的个人资料简介 | con-ar | - | `//div[@id="con-ar"]` |
| 相关搜索 你好之后怎么聊天 您好 你好 你好邻居正式版下载 檀健次的个人资料简介 | 1 | - | `//div[@id="1"]` |
| #feedback_13698195641876618136_1 | feedback_13698195641876618136_1 | - | `//div[@id="feedback_13698195641876618136_1"]` |
|  换一换 热搜榜北京榜民生榜财经榜  促进团结奋斗 汇聚磅礴力量 1 银 | con-ceiling-wrapper | - | `//div[@id="con-ceiling-wrapper"]` |
|  换一换 热搜榜北京榜民生榜财经榜  促进团结奋斗 汇聚磅礴力量 1 银 | 2 | - | `//div[@id="2"]` |
| 系列作品 你好,星期六 2026 第五季 你好,星期六 2023 第二季 你好， | 3 | - | `//div[@id="3"]` |

### H3 (3)

| 标签/文本 | id | name | XPath |
|----------|-----|------|-------|
| 你好 - 百度百科 | - | - | `/body[1]/div[2]/div[4]/div[1]/div[3]/div[1]/div[1]/h3[1]` |
| 你好,星期六 2025-综艺高清视频在线观看 | - | - | `/body[1]/div[2]/div[4]/div[1]/div[3]/div[2]/div[1]/h3[1]` |
| 系列作品 | - | - | `/div[2]/div[4]/div[1]/div[3]/div[3]/div[1]/div[1]/div[1]/h3[1]` |

### IMG (12)

| 标签/文本 | id | name | XPath |
|----------|-----|------|-------|
| 到百度首页 | - | - | `/body[1]/div[2]/div[1]/div[1]/div[1]/div[1]/a[1]/img[1]` |
| img | - | - | `/body[1]/div[2]/div[3]/div[1]/div[1]/a[1]/img[1]` |
| img | - | - | `/div[1]/div[1]/div[1]/div[2]/div[1]/div[1]/div[1]/div[1]/img[1]` |
| img | - | - | `/div[3]/div[2]/div[1]/div[1]/div[1]/a[1]/div[1]/div[1]/img[1]` |
| img | - | - | `/div[1]/div[3]/div[2]/div[1]/div[1]/div[1]/a[1]/div[2]/img[1]` |
| img | - | - | `/div[1]/div[3]/div[1]/div[1]/div[1]/a[1]/div[1]/div[3]/img[1]` |
| img | - | - | `/div[1]/div[3]/div[1]/div[2]/div[1]/a[1]/div[1]/div[2]/img[1]` |
| img | - | - | `/div[1]/div[3]/div[1]/div[3]/div[1]/a[1]/div[1]/div[2]/img[1]` |
| img | - | - | `/div[1]/div[3]/div[2]/div[1]/div[3]/div[1]/div[1]/div[2]/img[1]` |
| img | - | - | `/div[1]/div[3]/div[2]/div[1]/div[3]/div[1]/div[2]/div[2]/img[1]` |
| img | - | - | `/div[1]/div[3]/div[2]/div[1]/div[3]/div[1]/div[3]/div[2]/img[1]` |
| img | - | - | `/div[4]/div[1]/div[3]/div[2]/div[1]/div[3]/div[2]/a[1]/img[1]` |

### TEXTAREA (1)

| 标签/文本 | id | name | XPath |
|----------|-----|------|-------|
| 你好 | chat-textarea | - | `//textarea[@id="chat-textarea"]` |
