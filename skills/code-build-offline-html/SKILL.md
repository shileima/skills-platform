---
name: code-build-offline-html
description: 将 Vite/React 站点构建为可离线打开的单一 index.html，并可在 Electron React 宿主中通过 Shadow DOM 隔离渲染。用户提及“单文件 HTML”“离线页面”“内联 JS/CSS/图片”“Vite 打包单页”或“Shadow DOM 集成”时使用。
---

# 构建离线单文件 HTML

将目标站点产出为一个不依赖网络资源的 `index.html`；如需嵌入 Electron React 宿主，使用 Shadow DOM 隔离页面的样式、脚本与内部路由。

## 适用边界

- 适用于静态 Vite/React 站点，或可移除登录、后端 API、远程图片等运行时依赖的站点。
- 不将含有真实用户密钥、需要服务端鉴权或必须在线请求的数据伪装成离线页面。先移除相应功能，或明确告知用户无法离线。
- 不要把生成的构建产物拆成 HTML、CSS、JS 多个文件交付。

## 单文件构建

1. 审查入口、路由、图片、认证和 API 调用；删除未使用的登录、鉴权配置、代理和网络请求源码，避免把 client secret、token 或服务地址写入产物。
2. 为项目增加独立命令，例如：

```json
{
  "scripts": {
    "build:single": "tsc -b && node scripts/build-single-html.mjs"
  }
}
```

3. 脚本先使用相对资源路径构建，再内联资源：

```js
execFileSync('pnpm', ['exec', 'vite', 'build', '--base', './', '--outDir', outputDir], {
  cwd: projectDir,
  stdio: 'inherit',
});
```

4. 内联 HTML 中的 CSS、JS、favicon 和图片。对每个本地 `href` / `src` 读取文件：
   - CSS → `<style>…</style>`
   - JS → 内联 `<script>…</script>`
   - 图片 / favicon → `data:<mime>;base64,…`
   - 删除原始 `assets/` 与独立图片文件。
5. 替换必须使用回调，而非替换字符串。压缩后的 JS 可能含 `$&`、`$'` 等，直接传给 `String.replace` 会被解释为占位符，重新注入 `<script src>` 并破坏页面。

```js
const inlineScript = script.replace(/<\/script/gi, '<\\/script');
const html = sourceHtml.replace(
  /<script type="module"[^>]*src="[^"]+"[^>]*><\/script>/,
  () => `<script>${inlineScript}</script>`,
);
```

6. 构建后断言：
   - 输出目录只有 `index.html`；
   - HTML 不含本地 `assets/`、远程业务 API、登录中心、token；
   - 内联脚本只保留一个真实的 `</script>` 闭合标签。否则 HTML 解析器可能提前截断脚本。

```bash
pnpm run build:single
```

若 Vite 产生多个 JS chunk，不能只内联第一个文件：应先关闭动态分包，或递归收集并按依赖顺序内联全部 chunk，再通过离线打开验证。

## Shadow DOM 集成

1. 不用 iframe。通过已有的安全本地文件 IPC 读取 `index.html`；避免让渲染进程依赖尚未注册为 `supportFetchAPI` 的自定义协议。
2. `DOMParser` 解析 HTML，提取 `#root`、所有 `<style>` 与内联脚本，写入宿主元素的 `shadowRoot`。
3. Shadow Root 没有 `html` / `body`，构建 CSS 注入前转换作用域：

```ts
const shadowCss = css.replaceAll(':root', ':host').replaceAll('body{', ':host{');
```

4. 动态执行 bundle 时必须：
   - 用 IIFE 包裹，避免 Vite 压缩变量与宿主脚本重复声明；
   - 在执行前将 Shadow Root 临时传给 `window.__LEARNING_PLAYGROUND_SHADOW_ROOT__`；
   - bundle 从该字段获取 `#root`，并在 `finally` 中删除字段；
   - 不依赖 `document.currentScript`，动态插入 Shadow Root 时它不可靠。
5. 嵌入式 React 应用使用 `MemoryRouter`，禁止 `BrowserRouter` 改写 Electron 宿主地址栏。

## 验证清单

- [ ] `build:single` 通过，且输出仅有 `index.html`。
- [ ] 断网或阻断外网后页面仍可打开。
- [ ] Shadow DOM 中主题变量、背景、字体和图片均正确。
- [ ] 点击站内导航不改变宿主 URL。
- [ ] 检查宿主与站点改动文件的 lint；若有类型检查，记录与本次无关的既存错误。
