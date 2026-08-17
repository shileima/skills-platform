# diagram-design

Automan 流程图设计技能（MVP）。基于 [diagram-design](https://github.com/cathrynlavery/diagram-design) 设计系统，产出自包含 HTML + SVG 图表。

## 安装

内网安装脚本（与 cua-router-basic 同模式）：

```bash
curl -fsSL https://s3plus.sankuai.com/aiagent-bucket/diagram-design-resources/install-intranet.sh | bash
```

## 打包

```bash
node src/cli.mjs pack diagram-design
```
