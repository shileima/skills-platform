# code-build-offline-html

为 automan 客户端「个性化工作台」构建 Vite / React 产物，落到 `~/.automan/personal-workspace/`。
工作台菜单会在 Shadow DOM 中加载并热更新。

产物是一份**目录**（不是单文件）：

- `workbench.html` — 必需，入口页面
- `workbench.css` / `workbench.js` — 可选，宿主主动读入并注入 shadow root
- `assets/` 及任意其它静态资源 — 由 `automan://workspace/` 协议按需服务
- HTML/CSS 里的相对/根路径由宿主自动改写为 `automan://workspace/...` 绝对 URL

详见 [`SKILL.md`](./SKILL.md) 的宿主契约、构建脚本模板与常见坑。

## 分发/安装

```bash
skilldev install code-build-offline-html --target claude
skilldev pack code-build-offline-html            # automan zip
```
