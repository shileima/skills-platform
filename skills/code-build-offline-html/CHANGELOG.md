# Changelog — code-build-offline-html

## [0.2.0] - unreleased

### Changed
- 产物形态从「三文件独占目录」改为「目录 mirror」：只要求 `workbench.html` 存在，其它任意静态资源
  （`workbench.css` / `workbench.js` 可选、`assets/` 等子目录、图片、JS chunk）都可以携带。
- 宿主渲染层新增 URL 改写：HTML/CSS 里的相对 / 根路径自动改写为 `automan://workspace/...`，
  由主进程按需 stream personal-workspace/ 下的文件。
- `.backup-*` 前缀作为约定的备份目录名：宿主协议屏蔽访问，watcher 忽略变更事件。
- 简化构建脚本：不再需要合并 CSS/JS 与内联图片，Vite 常规 `vite build --base ./` 产物直接可用；
  额外的 `finalize-workbench.mjs` 只做「index.html → workbench.html」重命名与产物校验。

## [0.1.0]

### Changed
- 定位调整为 automan 客户端「个性化工作台」构建工具。
- 产物形态改为宿主约定的三文件：`workbench.html / workbench.css / workbench.js`。
- SKILL.md 补充宿主契约：Function 入参 `root / workspace / document / window`、数据事件
  `automan-workspace:data`、导航 `automan-workspace:navigate`、受限 API 清单。

## [0.0.1]

### Added
- Initial skill.
