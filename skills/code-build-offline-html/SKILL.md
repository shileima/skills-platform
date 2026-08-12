---
name: code-build-offline-html
description: 为 automan 客户端「个性化工作台」（~/.automan/personal-workspace/）构建 Vite / React 三件套产物，工作台在 Shadow DOM 里加载并复用客户端登录态。用户提及「个性化工作台」「automan workbench」「workbench.html」「personal-workspace」「离线工作台构建」时使用。
---

# 构建 automan 个性化工作台产物

本技能为 automan 客户端左侧「工作台」菜单生成静态资源。入口产物必须是
`workbench.html` / `workbench.css` / `workbench.js` 三件套；其它确需的图片、字体等资源
可由宿主通过 `automan://workspace/` 协议访问，但 Vite 入口 JS/CSS 不得残留在 `assets/`。

**关键约束**——三件套 `workbench.html` / `workbench.css` / `workbench.js` 都**必需**且**必须独立**：

- `workbench.html`：宿主只把 `<body>` 的 innerHTML 注入 shadow root，**里面的 inline `<script>` 不会被执行**（Shadow DOM 里的 innerHTML script 受安全限制）。
- `workbench.css`：宿主主动读入并塞进 shadow root 的 `<style>` 标签，作者在 HTML 里写 `<link rel="stylesheet">` 是无效的（head 里的 link 不会被插入）。
- `workbench.js`：宿主用 `new Function('root', 'workspace', 'document', 'window', script)` 执行；这是业务 JS **唯一**能跑进 Shadow DOM 的途径。

> ❌ 不要把 JS / CSS inline 进 `workbench.html`——那种单文件形态**在 Shadow DOM 里完全是空白**，
> inline script 不会执行，CSS 也不会注入。把 JS / CSS 拆成独立文件即可一次性解决问题，
> 构建脚本还必须确保最终 `workbench.js` 是无 import/export 的单一自包含脚本，才能兼容宿主和 `file://`。

## 宿主契约

宿主目录：`~/.automan/personal-workspace/`（可用环境变量 `OPENCLAW_DATA_DIR` / `VITE_OPENCLAW_DATA_DIR`
覆盖 `.automan` 根）。

### 目录结构

```
~/.automan/personal-workspace/
├── workbench.html      # 入口，body innerHTML 注入 shadow root
├── workbench.css       # 宿主主动读入并注入 shadow root <style>
├── workbench.js        # 宿主用 new Function 执行，接收 root/workspace/document/window
├── assets/             # 任意子目录、任意文件，通过 automan://workspace/... 加载
│   ├── logo-abc123.png
│   ├── vendor-xyz.js
│   └── ...
└── .backup-<ts>/       # 「应用到工作台」按钮自动创建的备份，宿主会屏蔽此目录
```

### 相对路径改写

宿主渲染层会在把 HTML/CSS 注入 shadow root **之前**做一次 URL 改写：

- HTML 里 `<img src="./assets/logo.png">`、`<link href="/styles.css">`、`<video poster="cover.jpg">`、
  `<img srcset="a.png 1x, b.png 2x">` 都会被改写为 `automan://workspace/...` 绝对协议 URL；
- CSS 里 `url(./assets/xxx.svg)`、`url("fonts/x.woff2")` 也会被改写；
- 已带绝对协议（`http:` / `https:` / `data:` / `blob:` / `automan:` 等）或以 `#` 开头的锚点会保持原样；
- `<a href>` 不改写（防止改到内部导航路由）；`<script src>` 不改写（保留作者意图）。

Vite 常规产出直接可用：`vite build --base ./ --outDir dist/workbench-final`，
把 `index.html` 重命名为 `workbench.html`，把 `assets/index-XXX.css` 重命名为
`workbench.css`、`assets/index-XXX.js` 重命名为 `workbench.js`，并改 HTML 里的
`<link>` / `<script>` 引用即可。详见下文「构建步骤」。

### workbench.js 契约

workbench.js 是宿主脚本入口（**不是** ES Module；顶层不能有 `import` / `export`）。
宿主用 `new Function('root', 'workspace', 'document', 'window', script)` 调用，传入四个入参：

| 名称 | 类型 | 可用能力 |
| --- | --- | --- |
| `root` | `ShadowRoot` | 真实 shadowRoot；用于挂载应用和限定元素查询范围 |
| `workspace` | 对象 | `{ root, onData(handler), navigate(path, query) }` |
| `document` | 代理 | 保留标准节点创建 API；`head/body/documentElement`、元素查询和事件监听均映射到 shadow root 内 |
| `window` | 代理 | 提供消息、导航及 React 运行时所需的 `getComputedStyle`、`matchMedia`、`HTMLIFrameElement` |

数据事件：

```json
{
  "type": "automan-workspace:data",
  "payload": {
    "modules": [
      {
        "key": "test-hub",
        "label": "测试计划",
        "description": "…",
        "path": "/test-hub",
        "items": [{ "title": "…", "subtitle": "…", "path": "/test-hub", "query": { "planId": 1 } }]
      }
    ]
  }
}
```

导航（等价，任选其一）：

```js
workspace.navigate('/test-hub', { planId: 1 });
window.parent.postMessage(
  { type: 'automan-workspace:navigate', payload: { path: '/test-hub', query: { planId: 1 } } },
  '*'
);
```

**注意**：`workbench.js` 是纯脚本片段。顶层不能有 `import` / `export`。
`document` / `window` 是受限代理：节点创建和工作台内查询应使用 `document.createElement`、
`document.querySelector` 等代理 API；定时器、网络请求等未暴露能力使用 `globalThis`。**不要通过
`root.ownerDocument.head/body/documentElement` 插入节点或修改属性**，因为 `ownerDocument` 是客户端
宿主的真实 Document，会绕过 Shadow DOM 隔离并污染左侧导航等全局界面。

第三方库运行时执行 `document.head.appendChild(style)`（例如 Toast、CSS-in-JS 动态样式）是支持的：
代理会把它写入 shadow root 内的样式宿主，不会进入客户端全局 `<head>`。同理，
`document.body` 和 `document.documentElement` 都指向右侧工作台内容宿主。

React 应用的最小接入示范（脚本从 workbench.js 顶层跑起来）：

```js
(function () {
  // 1) 找挂载点：workbench.html 里 <div id="root"></div> 已被宿主注入到 shadowRoot，
  //    documentProxy.getElementById('root') 直接命中 shadowRoot 里的元素
  var rootEl = document.getElementById('root') || document.createElement('div');
  if (!rootEl.id) { rootEl.id = 'root'; root.appendChild(rootEl); }
// 2) React 与 ReactDOM 必须一起打包进自包含的 workbench.js，由宿主 new Function 执行
// 3) 拿到数据后渲染
  var reactRoot = ReactDOM.createRoot(rootEl);
  workspace.onData(function (event) {
    reactRoot.render(App(event.data.payload.modules));
  });
  // 没有数据契约的话，直接 reactRoot.render(App()) 也行
})();
```

## 客户端登录态与接口鉴权（硬性要求）

个性化工作台运行在已登录的 automan 客户端中，**必须复用客户端登录状态，不得再实现一套 SSO**：

- 删除工作台工程里的 `AuthGate`、登录页、SSO callback、`redirectToSsoLogin`、刷新 token、登出等独立鉴权机制；禁止修改 `window.location.href` 跳登录中心，否则会导航整个客户端宿主页面。
- 工作台路由使用 `MemoryRouter`，不要使用依赖宿主 `window.history` 的 `BrowserRouter`。
- 客户端登录凭证只读取 `~/Library/Preferences/automan/config.json` 的 `xcAuth` 字段，不得读取项目 `.env`、localStorage 或另建登录态。
- 工作台调用需要鉴权的接口时，统一写入请求头 `xc-auth: <xcAuth>`。字段名固定为 **`xc-auth`**，不要写成 `Authorization`、`xc-token` 或 `access-token`。
- 必须把鉴权头收敛到统一的 `authenticatedFetch` / API client 中，禁止各页面散写 header。
- `xcAuth` 只用于本机工作台运行；禁止打印日志、提交 Git、上传、分享或发布包含真实 token 的产物。

当前宿主尚未给 `workspace` 对象提供通用 HTTP 代理，因此只能暂时由构建脚本在 Node 侧读取配置并通过 Vite `define` 注入。此方案会让 token 存在于本机 `workbench.js`，所以必须关闭 source map，且产物只能留在本机，不得进入发布、分享或版本管理流程。最小模式：

```ts
// vite.config.ts（Node 构建阶段）
import { existsSync, readFileSync } from 'node:fs'
import { homedir } from 'node:os'
import { resolve } from 'node:path'

function readClientXcAuth(): string {
  const file = resolve(homedir(), 'Library/Preferences/automan/config.json')
  if (!existsSync(file)) {
    throw new Error(`客户端配置不存在：${file}`)
  }
  try {
    const value = JSON.parse(readFileSync(file, 'utf8'))?.xcAuth
    if (typeof value === 'string' && value.trim()) return value.trim()
  } catch {
    throw new Error(`客户端配置无法解析：${file}`)
  }
  throw new Error('客户端尚未登录或 config.json 缺少 xcAuth，无法构建工作台')
}

export default defineConfig(({ mode }) => {
  const isWorkbench = mode === 'workbench'
  return {
    define: {
      __WORKBENCH_XC_AUTH__: JSON.stringify(isWorkbench ? readClientXcAuth() : ''),
    },
    build: {
      sourcemap: false,
    },
  }
})
```

```ts
// src/api.ts：所有业务请求只能经此入口
declare const __WORKBENCH_XC_AUTH__: string

export async function authenticatedFetch(input: RequestInfo | URL, init: RequestInit = {}) {
  if (!__WORKBENCH_XC_AUTH__) throw new Error('客户端登录状态不可用，请重新登录后构建工作台')
  const headers = new Headers(init.headers)
  headers.set('xc-auth', __WORKBENCH_XC_AUTH__)
  return fetch(input, { ...init, headers })
}
```

`build:workbench` 必须使用 `vite build --mode workbench ...`，并在构建前确认客户端已登录。未来若宿主提供安全 HTTP 代理，应迁移为“主进程读取 `xcAuth` 并注入 header”，避免 token 进入静态 JS；迁移前不得编造不存在的 `workspace.fetch` API。

## 硬性红线

- **工作台不得包含独立 SSO 鉴权机制**；必须复用客户端 `config.json.xcAuth`，接口统一携带 `xc-auth` header。
- **`workbench.html` / `workbench.css` / `workbench.js` 三件套都必需且独立**。把 JS inline 进
  HTML 不会执行；CSS 走 `<link rel="stylesheet">` 也不会注入（head 不会被原样插入 shadow root）。
- **`.backup-*` 前缀在宿主端被屏蔽**：`automan://workspace/.backup-xxx/foo.png` 会返回 403，
  自动化文件系统监听也会忽略该目录。作者不要使用以 `.backup-` 开头的目录名。
- **`workbench.js` 必须是单一自包含脚本，不能包含顶层 `import` / `export`、`import.meta` 或动态 `import()`**。不要强制 `format: 'iife'`，以免 Tailwind v4 把 CSS 注入 JS；构建后检查最终文件即可。
- **`document` / `window` 是受限代理**。标准节点创建、工作台内查询、动态样式注入使用代理；
  非 DOM 能力使用 `globalThis`。禁止通过 `root.ownerDocument` 修改真实 `head/body/documentElement`，
  否则会绕过 Shadow DOM 并污染客户端全局样式或结构。
- **顶层路径以 `/` 开头的会被视为绝对路径**（如 `/api/xxx`），改写为
  `automan://workspace/api/xxx` 后不会命中真实 API。因此不要在工作台产物里直接调用远程接口；
  确需时用完整的 `https://...`。
- **产物大小**：`~/.automan/personal-workspace/` 会被完整拷贝到用户机器，谨慎放巨大文件；
  推荐图标/字体保持在合理体量（<1 MB / 文件）。
- **禁止在源码中硬编码 token、mis、appkey、内部服务域名**。`xcAuth` 仅允许在本机 `build:workbench` 时从客户端配置注入，产物不得提交、上传、分享或发布。

## 完成定义与应用门禁（硬性要求）

**“构建命令退出码为 0”不代表任务完成。** 工作台只有依次通过“构建 → 静态验证 → 客户端同构运行时验证 → 应用”后才算完成；禁止构建后直接复制产物，也禁止把“请用户再点一次应用按钮”作为交付结果。

必须执行以下闭环：

1. 运行 `pnpm run build:workbench` 生成候选产物，尚未验证时不得覆盖 `~/.automan/personal-workspace/`；
2. 执行静态验证：三件套完整且唯一、HTML 引用正确、JS 自包含、无 module/assets 入口、无 `.backup-*`、source map 和真实 token 不得进入可提交/分享产物；
3. 执行客户端同构运行时验证：必须使用与正式工作台相同的 Shadow DOM 加载器、`document`/`window` 代理和 URL 改写，不能只用浏览器打开 `file://` 代替；
4. 捕获同步异常、`error`、`unhandledrejection`、`console.error`，等待首屏稳定，并确认 `#root` 已产生有效内容；像 `window.matchMedia is not a function`、`window.getComputedStyle is not a function` 这类宿主兼容错误必须在此阶段拦截；
5. 任一阶段失败：根据构建日志或运行时堆栈修复源码/构建配置，然后**重新从步骤 1 开始**，旧的验证结果不得复用；
6. 自动修复最多 3 轮；三轮仍失败则停止并保留原工作台，禁止用失败候选产物覆盖；
7. 全部验证通过后立即自动备份并应用到工作台，通过文件监听触发热更新，无需用户再次点击按钮。

**唯一允许应用的条件**：本轮候选产物的静态验证与客户端同构运行时验证都通过，并且应用前文件指纹未变化。只验证 `file://`、只检查三件套、只看构建退出码，均不满足应用条件。

## 构建步骤

推荐把工作台前端做成独立 Vite 项目。**宿主要求的硬性产物**是
`dist/workbench-final/{workbench.html,workbench.css,workbench.js}` 三件套。

### 步骤 1：`package.json`

```json
{
  "scripts": {
    "build:workbench": "node scripts/build-workbench.mjs"
  }
}
```

### 步骤 2：`scripts/build-workbench.mjs`

跑 `vite build` → 改名 `assets/index-XXX.css` → `workbench.css`、`assets/index-XXX.js` →
`workbench.js`、`index.html` → `workbench.html` → 改写 `workbench.html` 里的 `<link>` / `<script>`
路径 → 内联 favicon → 删 `assets/` 与 `favicon.svg` → 校验三件套 & `.backup-*` 前缀。

```js
/**
 * 「应用到工作台」产物构建脚本（三件套形态）。
 *
 * Vite 默认应用产物以 module script 引用入口；workbench mode 必须保持 CSS 独立输出，
 * 再把无 import/export 的自包含入口改写为普通 defer 脚本，形成 workbench.html/css/js 三件套。
 *
 * 之所以不用 inline 形态（把 JS/CSS 内联进 workbench.html）：
 *   - Workspace 组件把 workbench.html 的 body innerHTML 注入 shadow root，
 *     inline <script> 在 Shadow DOM 的 innerHTML 里**不会执行**（浏览器安全限制）；
 *   - CSS 走 head 里的 <link rel="stylesheet"> 也**不会被插入**到 shadow root。
 *   三件套才是 Workspace 组件能正确加载的形态；最终 JS 通过自包含校验后也兼容 file://。
 */
import { execFileSync } from 'node:child_process';
import {
  existsSync, readdirSync, readFileSync, renameSync, rmSync, writeFileSync,
} from 'node:fs';
import { resolve, join } from 'node:path';

const projectDir = resolve(import.meta.dirname, '..');
const outDir = resolve(projectDir, 'dist', 'workbench-final');

// 1. 使用 workbench mode 构建；vite.config 在此模式读取客户端 config.json.xcAuth
execFileSync('pnpm', ['exec', 'vite', 'build', '--mode', 'workbench', '--base', './', '--outDir', outDir], {
  cwd: projectDir,
  stdio: 'inherit',
});

const indexPath = resolve(outDir, 'index.html');
const assetDir = resolve(outDir, 'assets');
if (!existsSync(indexPath)) throw new Error(`vite 产物缺少 index.html：${indexPath}`);
if (!existsSync(assetDir)) throw new Error(`vite 产物缺少 assets/：${assetDir}`);

const assetFiles = readdirSync(assetDir);
const cssFiles = assetFiles.filter((f) => f.endsWith('.css'));
const jsFiles = assetFiles.filter((f) => f.endsWith('.js'));
if (cssFiles.length !== 1 || jsFiles.length !== 1) {
  throw new Error(`workbench mode 必须恰好生成一个 CSS 和一个 JS，实际：${assetFiles.join(', ')}`);
}
const [cssFile] = cssFiles;
const [jsFile] = jsFiles;

const cssPath = join(assetDir, cssFile);
const jsPath = join(assetDir, jsFile);
const cssOut = resolve(outDir, 'workbench.css');
const jsOut = resolve(outDir, 'workbench.js');

// 2. 改名三件套
renameSync(cssPath, cssOut);
renameSync(jsPath, jsOut);
renameSync(indexPath, resolve(outDir, 'workbench.html'));

// 3. 改写 workbench.html：<link href="./assets/xxx.css"> → ./workbench.css
//    <script type="module" src="./assets/xxx.js"> → ./workbench.js（构建后会校验入口无模块语法；
//    file:// 下 Chromium 会拒绝 module script，因此改为普通 defer 脚本）
//    同时清掉 modulepreload <link>（vite 偶尔会产，file:// 解析报错）
const faviconPath = resolve(outDir, 'favicon.svg');
const faviconBase64 = existsSync(faviconPath)
  ? readFileSync(faviconPath).toString('base64')
  : '';

let html = readFileSync(resolve(outDir, 'workbench.html'), 'utf8');
html = html.replace(
  /<link rel="stylesheet"([^>]*?)href="\.\/assets\/[^"]+"([^>]*?)\/?>/,
  () => `<link rel="stylesheet" href="./workbench.css">`,
);
html = html.replace(
  /<script\s+type="module"([^>]*?)src="\.\/assets\/[^"]+"([^>]*?)>\s*<\/script>/,
  () => `<script defer src="./workbench.js"></script>`,
);
html = html.replace(/<link[^>]*rel="modulepreload"[^>]*>\s*/g, '');

if (faviconBase64) {
  html = html.replace(
    /<link rel="icon"[^>]*>/,
    () => `<link rel="icon" href="data:image/svg+xml;base64,${faviconBase64}">`,
  );
}

const cssLinkCount = (html.match(/<link[^>]*href="\.\/workbench\.css"/g) ?? []).length;
const jsScriptCount = (html.match(/<script[^>]*src="\.\/workbench\.js"/g) ?? []).length;
const deferredScriptCount = (html.match(/<script[^>]*\bdefer\b[^>]*src="\.\/workbench\.js"/g) ?? []).length;
if (cssLinkCount !== 1 || jsScriptCount !== 1 || deferredScriptCount !== 1) {
  throw new Error(
    `workbench.html 改写异常：css link ${cssLinkCount} 个，js script ${jsScriptCount} 个，defer script ${deferredScriptCount} 个（预期各 1 个）`,
  );
}
if (/type=["']module["']/i.test(html) || /(?:src|href)=["'][^"']*\/assets\//i.test(html)) {
  throw new Error('workbench.html 仍包含 module 或 assets/ 入口引用');
}
writeFileSync(resolve(outDir, 'workbench.html'), html, 'utf8');

// 5. 清理中间产物
if (existsSync(assetDir)) rmSync(assetDir, { recursive: true, force: true });
if (existsSync(faviconPath)) rmSync(faviconPath, { force: true });

// 6. 校验：恰好 workbench.html/css/js 三件套，且未触发 .backup-* 前缀
function assertNoBackupPrefix(dir) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.name.startsWith('.backup-')) {
      throw new Error(`产物目录包含被宿主屏蔽的文件: ${entry.name}`);
    }
    if (entry.isDirectory()) assertNoBackupPrefix(join(dir, entry.name));
  }
}
assertNoBackupPrefix(outDir);

const finalEntries = readdirSync(outDir).sort();
const expected = ['workbench.css', 'workbench.html', 'workbench.js'];
if (finalEntries.join(',') !== expected.join(',')) {
  throw new Error(`产物目录不符合三件套约定：${finalEntries.join(', ')}`);
}
const finalScript = readFileSync(jsOut, 'utf8');
if (
  /(?:^|[;{}])\s*(?:import|export)\s/m.test(finalScript) ||
  /\bimport\s*(?:\(|\.)/.test(finalScript)
) {
  throw new Error('workbench.js 不是自包含脚本，仍包含 import/export/import.meta');
}

console.log('[build:workbench] done →', outDir, '(三件套 workbench.html/css/js)');
```

### 步骤 3：Shadow DOM 主题兼容（必需）

宿主只注入 `<body>` 内容，CSS 变量与页面基础样式必须同时作用于 `:host`：

```css
:root,
:host {
  --background: #fff;
  --foreground: #111;
}

body,
:host {
  background: var(--background);
  color: var(--foreground);
}
```

### 步骤 4：`vite.config`（必需）

工作台模式关闭 source map，但不要强制 `format: 'iife'`：Tailwind CSS v4 在该配置下可能把 CSS 注入 JS，导致缺少独立 `workbench.css`。保持 Vite 默认输出，并由步骤 2 严格校验只有一个 JS、一个 CSS，且最终 JS 不含模块语法：

```js
export default defineConfig(({ mode }) => ({
  base: './',
  build: {
    outDir: 'dist/workbench-final',
    emptyOutDir: true,
    assetsDir: 'assets',
    sourcemap: mode === 'workbench' ? false : undefined,
  },
}));
```

### 步骤 5：构建与静态验证候选产物

```bash
pnpm run build:workbench
# 构建前必须确认客户端已登录，config.json 中存在非空 xcAuth；不得输出 token 内容
ls dist/workbench-final/   # → workbench.html + workbench.css + workbench.js
# file:// 预览只能作为附加冒烟检查，不能替代客户端同构运行时验证
```

构建脚本中的断言必须全部通过；另外确认 `workbench.js` 不含 `import` / `export` / `import.meta` / 动态 `import()`，`workbench.html` 不含 `type="module"` 或 `assets/` 入口引用。此时产物仍是**候选产物**，不得复制到正式工作台。

### 步骤 6：客户端同构运行时验证（应用前必需）

通过 automan 客户端提供的工作台候选验证流程加载 `dist/workbench-final/`。验证器必须复用正式工作台的 Shadow DOM、URL 改写、`documentProxy` 和 `windowProxy`，并检查：

- 脚本执行期间无同步异常、`error`、`unhandledrejection`、`console.error`；
- 首屏稳定后 `#root` 存在且具有有效渲染内容；
- React、路由、Radix/Sonner 等运行时没有调用宿主代理缺失的浏览器 API；
- 主题类和 `:host` 样式在 Shadow DOM 中生效；
- 对含 Toast、CSS-in-JS 等动态样式注入的产物，确认新增 `<style>` 位于 shadow root，且客户端真实
  `document.head` 未新增工作台样式；左侧导航的字号、间距、颜色和布局不受工作台 CSS 影响；
- 必需接口请求携带 `xc-auth`，没有触发独立 SSO 或宿主页面跳转。

普通浏览器直接打开 `file://.../workbench.html` 只能证明静态文件在完整 Window 环境可执行，**不能发现受限代理缺少 `matchMedia` / `getComputedStyle` 等客户端专属问题，因此不能据此判定可应用。**

### 步骤 7：失败修复与自动重试

验证失败时，把失败阶段、结构化原因、构建日志尾部、运行时错误及堆栈交给智能体修复。修复完成后自动重新构建并从步骤 5 开始完整验证，最多 3 轮。不得跳过失败项、吞掉异常、放宽断言或直接复制产物来伪造成功。

### 步骤 8：验证通过后自动应用

用户点击一次「应用到我的工作台」，或智能体完成本轮工作台代码修改后，客户端应自动完成后续闭环。静态与运行时验证全部通过后，宿主自动：

- 确认候选产物指纹与验证时一致；
- 把 `~/.automan/personal-workspace/` 里原有内容（除 `.backup-*` 外）整体备份到 `.backup-<ts>/`；
- 递归复制已验证候选产物；
- 通过文件监听自动热更新工作台。

**禁止要求用户在智能体修复后再次点击按钮。禁止绕过客户端验证手工 `rsync` 到 `personal-workspace`。** 三轮仍失败时保留旧工作台并报告最终诊断。

## 常见坑

- **把“构建成功”当成“可以应用”**：构建退出码、三件套静态检查和 `file://` 冒烟都无法覆盖客户端 Shadow DOM 代理兼容性。必须完成客户端同构运行时验证，通过后才能自动应用。
- **通过 `root.ownerDocument.head` 注入运行时样式**：这是真实宿主 Document，会让 Tailwind reset、
  Toast 或 CSS-in-JS 样式影响客户端左侧区域。始终使用代理 `document.head`，并在同构验证中检查
  客户端全局 `<head>` 没有新增工作台样式。
- **修复后停下来让用户再点按钮**：自动修复完成后必须恢复原闭环，重新构建、静态验证、运行时验证并自动应用；最多 3 轮，不能把流程恢复责任交给用户。
- **验证失败仍覆盖正式工作台**：候选目录与 `personal-workspace` 必须隔离。失败时保留旧工作台，只有本轮全部门禁通过且指纹未变化才允许覆盖。
- **单文件形态（把 JS inline 进 HTML）在 Shadow DOM 里完全空白**：inline script 不执行、
  CSS 不注入。一定要走三件套。
- **`<script type="module">` 在 file:// 双击预览时被 Chromium 拒绝**。build 脚本必须把
  workbench mode 产物改成 `<script defer src="./workbench.js">`（构建后必须确认 JS 自包含；
  `defer` 确保 `#root` 已解析），并在应用前校验不存在 module 和 assets/ 入口引用。
- **图片路径少写了 `./`**：`<img src="assets/x.png">` 和 `<img src="./assets/x.png">` 都能被改写，
  但 `<img src="/assets/x.png">`（含前导 `/`）也会被改写成 `automan://workspace/assets/x.png`。
  如果确实想引用另一个协议（例如 `https://xxx`），用完整绝对 URL。
- **Vite CSS 里的 `@import`**：`@import url('./other.css')` 目前不在改写范围内，Vite 会在构建时
  把 CSS `@import` 内联进产物，通常不会出现；如出现请手动改成 `@import 'automan://workspace/other.css'`
  或干脆合并成一个 CSS 文件。
- **JS 里的动态 URL**：`fetch('./data.json')`、`new URL('./x.png', import.meta.url)` 这类不会被
  静态改写，运行时会尝试相对于宿主 renderer 的 origin 请求，会失败。要么改成绝对 URL
  （`automan://workspace/data.json`），要么把资源在构建时内联进 JS bundle。
- **工作台打开后跳到登录中心或宿主路由异常**：工程仍残留 `AuthGate` / SSO redirect / `BrowserRouter`。删除独立 SSO，改用 `MemoryRouter`，请求统一携带客户端 `xcAuth`。
- **接口返回 401**：确认 `~/Library/Preferences/automan/config.json` 中 `xcAuth` 非空，再确认 header 名严格为 `xc-auth`；禁止回退到另一套网页登录。
- **热更新看不到变化**：确认没有把新版本落到 `.backup-*` 目录里；宿主 `fs.watch` 会忽略该前缀。