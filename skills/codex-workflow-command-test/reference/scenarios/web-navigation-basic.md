# 场景：网页操作基础（WF3 · 多标签导航）

> **禁止**使用 `example.com` / `example.org` 等 IANA 保留域。本场景使用国内可访问、标题稳定的真实站点。

## 站点与用途

| 角色 | URL | 页面标题（切换/关闭标题用） |
|------|-----|---------------------------|
| 首屏 | `https://www.baidu.com` | `百度一下，你就知道` |
| 导航目标 | `https://www.sogou.com` | `搜狗搜索` |
| 第二标签 | `https://www.sina.com.cn` | `新浪网` 或 `新浪网_新浪网` |

## 工作流指令顺序（15 条）

| # | 指令 | 关键参数 |
|---|------|----------|
| 1 | 打开网页 | 网址 = `https://www.baidu.com` |
| 2 | 导航到URL | 导航到的网址 = `https://www.sogou.com` |
| 3 | 等待页面加载 | 加载状态 = `LOAD` |
| 4 | 截图 | — |
| 5 | 刷新网页 | — |
| 6 | 网页后退 | 回到百度 |
| 7 | 网页前进 | 回到搜狗 |
| 8 | 打开网页 | 网址 = `https://www.sina.com.cn`（开第二标签） |
| 9 | 切换到指定索引网页 | 索引 = `0` |
| 10 | 切换到指定URL网页 | URL = `https://www.sogou.com` |
| 11 | 切换到指定标题网页 | 标题含 `搜狗` 或 `新浪`（按当前剩余标签） |
| 12 | 关闭指定索引网页 | 索引 = `1` |
| 13 | 关闭指定URL网页 | URL = `https://www.sina.com.cn` |
| 14 | 删除所有Cookie | — |
| 15 | 关闭浏览器 | **必须最后** |

## URL 填写

一律 **pbcopy + 弹框内 Cmd+V**，见 [`url-input.md`](../url-input.md)。禁止 `type_text` 写 URL。

## 插入指令

见 [`insert-command.md`](../insert-command.md) §平台 UI 实测踩坑 · 推荐最小路径。
