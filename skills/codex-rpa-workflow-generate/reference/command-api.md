# 指令 API 与鉴权

## 鉴权

读取 Automan 本地配置：

```
~/Library/Preferences/automan/config.json → xcAuth
```

请求头：

```
xc-auth: <xcAuth>
tenant-id: <tenantId>   # 若有
```

实现：`scripts/lib/auth.mjs`

## 接口

| 用途 | 方法 | URL |
|------|------|-----|
| 指令树 | GET | `/platform/api/v1/command/listAll?source=1` |
| 指令详情 | GET | `/platform/api/commandManage/getCommandDetail?commandId={id}&userInfoFlag=0` |

Base URL：`https://digitalgateway.sankuai.com`

## 缓存

- 指令列表缓存：`data/commands-list.json`（30 分钟 TTL）
- 指令详情：进程内内存缓存

## 常用 commandId（unionId 映射以 listAll 为准）

| unionId | 典型 id | 平台名 |
|---------|---------|--------|
| OpenUrl | 1 | 打开网页(web) |
| FillText | 55 | 输入文本(web) |
| ReloadPage | 131 | 刷新网页 |
| ClickElementMixed | 841 | 点击(web) |
| NavigateToUrl | — | 导航到URL |

指令文档：https://document.waimai.st.sankuai.com/commands/ui-commands/
