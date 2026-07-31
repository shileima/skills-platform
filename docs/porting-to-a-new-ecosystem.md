# 新增一个生态适配

`skilldev` 的多生态支持是**适配器（adapter）**模式。新增一个生态通常只需两步。

## 1. 注册路径

编辑 `src/lib/ecosystems.mjs`，在 `ECOSYSTEMS` 中加一项：

```js
myeco: {
  id: "myeco",
  // 技能安装根目录；envVar 允许运行时覆盖
  defaultSkillsDir: join(home, ".myeco", "skills"),
  envVar: "SKILLDEV_MYECO_SKILLS_DIR",
}
```

`skillsDir(id)` 会优先读环境变量，否则用默认值。

## 2. 写适配器

新建 `src/adapters/myeco.mjs`，导出统一接口：

```js
export default {
  id: "myeco",
  skillsDir() { return skillsDir("myeco"); },

  // 把 canonical 技能内容落到 outDir（供 build/install 使用）
  async stage(skill, srcDir, outDir) {
    await copyIncluded(skill, srcDir, outDir); // 按 pack.include 拷贝
    // 如该生态需要专属清单/元数据，在这里生成
  },

  // 安装到生态目录后的收尾（可选）
  async postInstall(skill, destDir) { /* 例如装依赖 */ },
};
```

在 `src/adapters/index.mjs` 里把它加入 `adapters` 映射。

## 参考现有适配器

- `claude.mjs` / `codex.mjs` / `cursor.mjs`：最简，纯按白名单拷贝 `SKILL.md` + 支撑目录。
- `automan.mjs`：最全，额外由 `skill.json` 生成 `.meta.json`，并支持 `pack`（zip）与依赖安装。

## 约定

- **不要**在 adapter 里写死绝对路径 —— 一律走 `ecosystems.mjs`。
- 生态若有“整仓插件清单”（如 marketplace），放到 `src/commands/manifest.mjs`，而不是 adapter。
