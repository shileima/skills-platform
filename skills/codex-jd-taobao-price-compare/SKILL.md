---
name: codex-jd-taobao-price-compare
description: >
  京东与淘宝/天猫同款商品比价与采购建议技能。当用户说「对比京东和淘宝 X 的价格」
  「京东淘宝哪个便宜」「帮我比价 X」「同款商品京东和淘宝对比」「淘宝京东哪个买划算」
  「比一下 jd.com 和 taobao.com 的 X」等意图时激活。通过 Chrome 桌面浏览器分别打开
  京东与淘宝搜索、进入官方旗舰店/自营商品详情页，提取价格、国补/优惠、销量、售后、
  分期、发货时效等字段，输出对比表格并给出推荐购买链接。登录敏感场景每 10s 轮询检测，
  或用户主动告知「已登录」后继续。
---

# codex-jd-taobao-price-compare — 京东 × 淘宝同款比价与采购建议

面向消费者的桌面浏览器比价技能：给定一个商品关键词（如「华为WATCH GT 7 黑色」），
分别在 [jd.com](https://www.jd.com/) 与 [taobao.com](https://www.taobao.com/)
上搜索并进入官方旗舰店/自营详情页，抓取关键采购字段，输出结构化对比表 +
购买链接 + 推荐结论。

## 依赖

参照 `cua-router-basic` 的 `references/install.md` 与 `references/runtime-exec.md`。
执行 sky 操作前必须验证服务在线：

```bash
SKILL_ROOT="${CUA_ROUTER_INSTALL_DIR:-${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic}"
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  SKILL_ROOT="${HOME}/.cursor/skills/cua-router-basic"
fi
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  SKILL_ROOT="${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic"
fi
if [ ! -f "$SKILL_ROOT/SKILL.md" ]; then
  SKILL_ROOT="${HOME}/.automan/claude-code-agents/cua-agent/skills/cua-router-basic"
fi
bash "$SKILL_ROOT/scripts/daemon.sh" start
bash "$SKILL_ROOT/scripts/exec.sh" 'nodeRepl.write("ok")'
```

输出 `ok` 后才能继续。Chrome 操作遵循 `cua-router-basic` 核心规范：
地址栏 `set_value` + `Return`、每次操作后 `get_app_state({ disableDiff: true })`、
在完整 `s.text` 上搜索元素、AX 参数名统一 snake_case（`element_index`）。

## 触发判定

- 「对比京东和淘宝的 X」「京东淘宝比价 X」
- 「X 京东和淘宝哪个便宜/划算」
- 「帮我在京东和淘宝搜同款 X 并对比」
- 「同款商品 jd.com vs taobao.com」
- 明确给出 `https://www.jd.com/` 和 `https://www.taobao.com/` 两个链接 + 商品关键词

单一平台比价不激活本技能（如只在京东内比不同 SKU）。

## 稳定流程

1. **准备**：启动并验证 `cua-router-basic`；从用户诉求提取 `商品关键词`（`query`），并**先解析 SKU 维度**（见下一节「SKU 维度核对」），得到 `targetSku` 对象后再开浏览器。
2. **京东侧**：
   1. 地址栏导航到 `https://www.jd.com/`，等 Ready。
   2. 直接跳搜索页 URL：`https://search.jd.com/Search?keyword=<encoded>&enc=utf-8`（比走搜索框更稳定）。
   3. 在 AX Tree 里定位第一个 **京东自营/华为官方旗舰店** 类目下与 `query` 强匹配的商品卡（`container` 节点标题）。
   4. `sky.click({ element_index })` 打开详情页，等待 5～6s。
   5. **SKU 选规格**（**强制，不可跳过**）：在详情页按 `targetSku` 逐维点击规格按钮（颜色 → 容量 → 版本），每次点击后等 2～3s 并重取 AX Tree；调用 `verifySelectedSku({ platform: "jd", targetSku })`，未通过则继续点选，最多重试 3 次。
   6. 抓取字段（**仅在 SKU 核对通过后**）：
      - 商品标题（Window title）
      - **已选规格**（`已选：` 行或规格区高亮项，必须与 `targetSku` 一致）
      - 详情页 URL（地址栏 Value，含正确 `item.jd.com/{sku}.html`）
      - 标价 / 国补领后价 / 到手价
      - 分期（如 `¥xxx × 3期 0服务费`）
      - 售后条目（`90天只换不修`、`一年质保`、`7天价保`、`免费上门退换`、`59元免基础运费`、`正品行货带票`）
      - 销量 / 评价数 / 加购数
      - 店铺（`华为京东自营旗舰店` 等）
      - 延保加购（`3年全保 +¥xxx` / `5年全保 +¥xxx`）
3. **淘宝/天猫侧**：
   1. 地址栏导航到 `https://www.taobao.com/` 以复用 Cookie，再跳 `https://s.taobao.com/search?q=<encoded>`。
   2. 从搜索结果里找 `Description` 含 **"华为官方旗舰店"** 或 **"天猫旗舰店"** 且标题含 `query` 关键短语的 `link` 元素。
   3. `sky.click({ element_index })` 打开详情页（`detail.tmall.com/item.htm?id=…` 或 `item.taobao.com`），等待 5～6s。
   4. **SKU 选规格**（**强制，不可跳过**）：天猫详情页**默认 SKU 往往不等于用户目标**（如默认 128GB 而非 256GB）。必须在 AX Tree 里找到规格区（`颜色分类` / `机身颜色` / `存储容量` / `版本` / `套餐类型`），按 `targetSku` 逐维 `sky.click` 对应选项；每次点击后等 2～3s 并重取 AX Tree，确认价格区已刷新。调用 `verifySelectedSku({ platform: "tb", targetSku })`，未通过则继续点选，最多重试 3 次。
   5. 抓取字段（**仅在 SKU 核对通过后**）：
      - 商品标题
      - **已选规格**（`已选：` / `selected` 高亮项 / 规格按钮 `pressed` 状态）
      - 详情页 URL（必须含与当前选中规格对应的 `skuId`；剥离 `spm/xxc/ali_refid/utparam` 等追踪参数）
      - 价格 / 优惠后价 / 补贴后价
      - 分期 / 花呗
      - 发货时效（`预售，X 月 X 日前发货` / `48 小时内发`）
      - 服务（`7天价保`、`7天无理由退换`、`退货宝`、`假一赔四`、`极速退款`、`88VIP 退货包运费`）
      - 销量（`已售 xxx+` / `xxx 人付款` / `xxx 加购`）
      - 店铺信誉（`华为官方旗舰店 5.0 88VIP 好评率 xx%`）
4. **跨平台 SKU 对齐门禁**（**输出前强制**）：两侧 `已选规格` 必须在存储容量、颜色、型号版本上语义等价（见「SKU 维度核对 → 跨平台对齐规则」）。任一侧未对齐则**禁止输出价格对比**，回到对应平台重选规格并重抓。
5. **登录检测**（见下一节）：若命中未登录关键词，提示用户手动登录并每 10s 轮询。
6. **输出**：Markdown 对比表（含 **已选 SKU** 行）+ 推荐购买链接 + 采购建议 + 时效声明（下方"输出格式"）。

## 登录检测与轮询

每一步 `get_app_state` 后按下表判定：

| 平台 | 未登录信号（正则） |
|------|------------------|
| 京东 | `请登录` / `Hi，请登录` / `passport\.jd\.com` / `扫码登录` |
| 淘宝天猫 | `亲，请登录` / `login\.taobao\.com` / `login\.tmall\.com` / `扫码登录` |

命中即：

1. 向用户输出提示：`⚠️ 检测到 <平台> 未登录，请在浏览器中完成登录（扫码或账号密码），登录完成后告诉我，或我将每 10s 自动复检…`
2. 循环 `await new Promise(r => setTimeout(r, 10000))` 并复取 AX Tree；未命中登录关键词时视为登录完成。
3. 用户主动说「已登录 / 登好了 / 完成了」也立即退出轮询继续下一步。
4. 单次会话最长等待 10 分钟（`maxWaitMs = 10 * 60 * 1000`）；超时告知用户并中止流程。

推荐轮询模板（在 `nodeRepl.write` 的 IIFE 里）：

```js
async function waitLogin({ app = "com.google.Chrome", platform = "jd", maxWaitMs = 10 * 60 * 1000 } = {}) {
  const PATTERNS = {
    jd: /请登录|passport\.jd\.com|扫码登录/,
    tb: /亲，请登录|login\.(taobao|tmall)\.com|扫码登录/,
  };
  const pat = PATTERNS[platform] ?? PATTERNS.jd;
  const start = Date.now();
  while (Date.now() - start < maxWaitMs) {
    const s = await sky.get_app_state({ app, disableDiff: true });
    if (!s.text.split("\n").some(l => pat.test(l))) return { ok: true, waitedMs: Date.now() - start };
    await new Promise(r => setTimeout(r, 10000));
  }
  return { ok: false, timeout: true };
}
```

Agent 在每次浏览器动作后可调用 `waitLogin({ platform })` 保证后续采集有效。
若用户在对话中主动打断（"我登录好了 / 已登录"），立即跳出轮询继续。

## SKU 维度核对（**强制**）

比价的核心是**同款同规格**，不是同 SPU 不同 SKU。Agent 必须在抓价前完成「解析 → 点选 → 验证 → 对齐」四步，**禁止**用详情页默认 SKU 或搜索卡片的标题价直接对比。

### 1. 从 query 解析 targetSku

从用户关键词中提取下列维度（缺失的维度标注为 `null`，但存储/颜色/型号至少命中两项）：

| 维度 | 解析规则 | 同义词映射 |
|------|----------|------------|
| `storage` | `\d+\s*GB` / `\d+\s*TB` | `256G→256GB`、`1T→1TB` |
| `color` | 颜色实词 | 见下方颜色别名表 |
| `model` | 型号关键词 | `GT7→GT 7`、`16Pro→16 Pro` |
| `variant` | Pro / Max / Plus / Ultra / SE | 精确匹配，不自动升级 |
| `network` | `5G` / `WiFi` / `蜂窝` | `蜂窝版→蜂窝` |
| `edition` | 国行 / 港版 / 美版 / 全新未激活 | 默认按国行理解 |

**颜色别名表**（两侧规格按钮文案可能不同，比对时用别名归一）：

```
黑色 ↔ 疾影黑 / 碳晶黑 / 黑色钛金属 / 深空黑 / 曜石黑
白色 ↔ 陶瓷白 / 白色钛金属 / 星光色 / 雪域白
蓝色 ↔ 远峰蓝 / 海蓝色 / 冰晶蓝
紫色 ↔ 暗紫色 / 丁香紫
金色 ↔ 沙漠色钛金属 / 原色钛金属
```

解析示例：`iPhone 16 Pro 256GB 黑色钛金属` →

```json
{
  "storage": "256GB",
  "color": "黑色",
  "colorAliases": ["黑色", "黑色钛金属", "深空黑"],
  "model": "16 Pro",
  "variant": "Pro",
  "network": null,
  "edition": null
}
```

`compare.sh` 会输出 `targetSku` 供 Agent 直接使用；若与用户口述不一致，以用户最新补充为准。

### 2. 详情页 SKU 点选流程

**京东**规格区常见标签：`颜色`、`版本`、`购买方式`、`存储`、`尺码`。

**天猫**规格区常见标签：`颜色分类`、`机身颜色`、`存储容量`、`版本`、`套餐类型`、`网络类型`。

通用步骤：

1. `get_app_state({ disableDiff: true })` 取完整 AX Tree。
2. 在 `s.text` 中定位规格维度标题行（如 `存储容量`），向下找同级/子级 `button` / `link` / `radio` 节点。
3. 对每个 `targetSku` 维度，在 AX 里找**文案命中别名**且**未 disabled** 的选项，`sky.click({ element_index })`。
4. 每次点击后 `await sleep(2500)`，重取 AX Tree，确认：
   - 价格区数字已变化（或「券后价」「补贴价」行更新）；
   - 存在 `已选` / `selected` / `pressed: true` 且文案含目标规格；
   - 地址栏 URL 的 `skuId`（天猫）或路径 SKU（京东）已更新。
5. 若目标规格显示 `无货` / `缺货` / `到货通知`，记录并在输出中标注，**不得**偷换其它容量/颜色继续比价。

### 3. verifySelectedSku 验证函数

在 `nodeRepl.write` 的 IIFE 里使用（Agent 每次点选规格后必须调用）：

```js
function normalizeStorage(s) {
  if (!s) return null;
  const m = String(s).match(/(\d+)\s*(GB|TB|G|T)/i);
  if (!m) return null;
  const n = m[1], u = m[2].toUpperCase().startsWith("T") ? "TB" : "GB";
  return `${n}${u}`;
}

function lineMatchesAny(line, aliases) {
  return aliases.some(a => line.includes(a));
}

async function verifySelectedSku({ app = "com.google.Chrome", platform, targetSku, maxRetries = 3 } = {}) {
  const storageAliases = targetSku.storage ? [targetSku.storage, targetSku.storage.replace("GB", "G"), targetSku.storage.replace("TB", "T")] : [];
  const colorAliases = targetSku.colorAliases ?? (targetSku.color ? [targetSku.color] : []);
  const modelAliases = targetSku.model ? [targetSku.model, targetSku.model.replace(/\s+/g, "")] : [];
  const variantAliases = targetSku.variant ? [targetSku.variant] : [];

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    const s = await sky.get_app_state({ app, disableDiff: true });
    const lines = s.text.split("\n");
    const selectedLine = lines.find(l => /已选|selected/i.test(l)) ?? "";
    const pressedLines = lines.filter(l => /pressed:\s*true|selected:\s*true|checked:\s*true/i.test(l));

    const blob = [selectedLine, ...pressedLines, ...lines.filter(l => /GB|TB|钛金属|颜色|存储|版本/.test(l))].join("\n");

    const checks = {
      storage: !targetSku.storage || storageAliases.some(a => blob.includes(a)),
      color: !targetSku.color || colorAliases.some(a => lineMatchesAny(blob, [a])),
      model: !targetSku.model || modelAliases.some(a => blob.includes(a)),
      variant: !targetSku.variant || variantAliases.some(a => blob.includes(a)),
    };

    const addrLine = lines.find(l => /地址和搜索栏|Address and search bar/i.test(l)) ?? "";
    const url = addrLine.match(/Value:\s*(https?:\/\/[^,\s]+)/)?.[1] ?? "";
    let skuId = null;
    if (platform === "tb") {
      skuId = url.match(/[?&]skuId=(\d+)/)?.[1] ?? null;
      if (targetSku.storage && !skuId && attempt === maxRetries - 1) {
        checks.storage = false; // 天猫必须有 skuId 才算选中成功
      }
    }
    if (platform === "jd") {
      skuId = url.match(/item\.jd\.com\/(\d+)\.html/)?.[1] ?? null;
    }

    const ok = Object.values(checks).every(Boolean);
    if (ok) return { ok: true, checks, skuId, url, selectedLine: selectedLine.trim() };

    await new Promise(r => setTimeout(r, 2000));
  }
  return { ok: false, error: "SKU 验证未通过", targetSku };
}
```

**验证失败时的 Agent 行为**：

1. 向用户说明：「当前页面选中规格与目标不一致（已选 vs 目标），正在重新点选…」
2. 回到规格区重新点击，**不得**直接用当前价输出对比表。
3. 连续 3 次失败 → 标注该平台「目标 SKU 无货或规格不可选」，询问用户是否换规格或换店铺。

### 4. 跨平台对齐规则

输出对比表前，确认两侧采集到的 `selectedSku` 在下列维度**语义等价**：

| 维度 | 对齐要求 |
|------|----------|
| 存储 | 归一后完全相同（`256GB` = `256G`，禁止 128GB vs 256GB） |
| 颜色 | 命中同一别名组（`黑色钛金属` ≈ `黑色`） |
| 型号/版本 | 完全相同（`16 Pro` ≠ `16 Pro Max`） |
| 网络 | 若用户指定则必须一致（WiFi 版 vs 蜂窝版不可混比） |

对齐检查伪代码：

```js
function skuAligned(jdSelected, tbSelected, targetSku) {
  return normalizeStorage(jdSelected.storage) === normalizeStorage(tbSelected.storage)
    && normalizeStorage(jdSelected.storage) === normalizeStorage(targetSku.storage)
    && colorSameGroup(jdSelected.color, tbSelected.color, targetSku.colorAliases);
}
```

**未对齐时禁止输出到手价对比**，只能输出「SKU 不一致警告」并给出两侧各自已选规格与链接，请用户确认。

### 5. Agent 执行检查清单（输出前必过）

- [ ] 已从 query 解析 `targetSku`，并与用户确认（如有歧义）
- [ ] 京东详情页已点选目标规格，`verifySelectedSku({ platform: "jd" })` 返回 `ok: true`
- [ ] 天猫详情页已点选目标规格，`verifySelectedSku({ platform: "tb" })` 返回 `ok: true` 且 URL 含 `skuId`
- [ ] 两侧 `selectedLine` 存储/颜色/型号语义对齐
- [ ] 购买链接中的 SKU / skuId 与已选规格一致
- [ ] 对比表包含 **已选 SKU** 行，便于用户复核

## 商品匹配启发式

搜索结果通常混入配件（表带 / 保护壳 / 贴膜）、以及大量**二手 / 准新机 / 翻新机 / 拍拍二手**。按下列顺序过滤：

1. **剔除配件**：标题含 `表带 | 保护壳 | 保护套 | 钢化膜 | 贴膜 | 支架 | 充电线 | 数据线 | 手机壳 | MagSafe 保护套`。
2. **仅对比全新，剔除二手/准新/翻新（默认强制启用）**：标题或店铺名含以下任一关键词的卡片一律剔除：
   - **二手/翻新类**：`二手 | 拍拍 | 拍拍二手 | 官方回收 | 认证翻新 | 官翻 | 严选 | 优品 | 靓机 | 甄选 | 二手买手店`
   - **准新/成色标记**：`准新机 | 95新 | 99新 | 9新 | A+ | 严选好机 | 良品 | 展示机 | 后封 | 二手机`
   - **保留关键词**（属于"全新"信号，可放行）：`全新未激活 | 全新原封 | 全新原装 | 未激活国行 | 官方授权 | 官方标配 | 京东自营 | 官方旗舰店`
   - Agent 输出对比表前，必须在两侧各自命中"至少一个全新信号"，否则整条剔除。
   - **例外**：用户在对话中明确说 `包含二手 / 认证翻新也算 / 二手也对比` 时，才可放行二手结果，并在对比表单独一列注明 `商品状态`。
3. 优先命中 **官方旗舰店** / **京东自营** 关键词的卡片。
4. 标题包含用户 query 里所有实词（如 `华为 WATCH GT 7 黑色` → 必须同时含 `华为`、`GT 7 / GT7`、`黑色 / 疾影黑 / 碳晶黑`）。
5. 排除 Pro/Ultra 等升级款，除非用户明确要 Pro。
6. 若多款均满足，取「京东自营 / 品牌官方旗舰店 + 到手价最低」的一款。

## Apple 官方渠道停售兜底（旧款手机常见）

新旗舰发布后 3~6 个月，`Apple 产品京东自营旗舰店` / `Apple Store 天猫官方旗舰店` 往往会**下架上一代 Pro 型号**（如 iPhone 17 系发布后 16 Pro 消失）。此时按顺序处理：

1. **确认下架**：在 `apple.tmall.com` 进入 iPhone 分类页，若列表里没有目标型号主机（只剩配件如 `iPhone 16 Pro 专用 MagSafe 保护壳`），即视为 Apple 官方**已停售**。京东同理，在自营旗舰店 SKU 列表里翻找不到目标存储/颜色即视为下架。
2. **切换到第三方全新经销商**：搜索关键词补充 `全新未激活 国行`，例如 `iPhone 16 Pro 256GB 黑色钛金属 全新未激活 国行`。
   - 京东侧：从搜索结果里挑第三方经销商店（如 `xx数码全新产品经营部`、`xx优选买手店`），仍必须命中"全新未激活"或"全新原封"标签。
   - 天猫侧：`https://s.taobao.com/search?q=<query>&tab=mall` 仅在 tmall 商城模式下搜；挑 13 年老店、好评率 >85%、高销量的数码专营店。
3. **同时告知用户价格已高于原价**：Apple 停售后经销商价通常**高于官网首发价**（如 iPhone 16 Pro 256GB 原价 ¥8,999，停售后第三方 ¥9,000+），需在采购建议里明确提示，并给出 Apple 官方在售替代款（如 `iPhone 17 Pro 256GB`）与 Apple 官方保留的同系列旧款 SKU（如 `iPhone 16 Pro 128GB 白色钛金属`）作为对照。
4. 对比表加一列 `商品状态`（`全新未激活国行` / `Apple 官方自营`），让用户一眼看出这不是苹果直营。

## 售后字段解析

按 AX 文本行匹配：

| 字段 | 关键词 |
|------|--------|
| 送货上门 | `送货上门` / `京东物流` |
| 运费门槛 | `59 ?元免基础运费` |
| 正品发票 | `正品行货带票` / `可开发票` |
| 换新政策 | `90 ?天只换不修` |
| 质保 | `一年质保` / `厂家质保` |
| 价保 | `7 ?天价保` |
| 无理由 | `7 ?天无理由` |
| 免费上门 | `免费上门退换` |
| 假一赔四 | `假一赔四` |
| 极速退款 | `极速退款` |
| 88VIP | `88 ?VIP` |
| 分期 | `X 期 ?0 ?服务费` / `花呗` / `白条` |

## 购买链接采集规范（**强制**）

对比表的"购买链接"列**必须**是**具体商品详情页 URL**（`item.jd.com/{sku}.html` 或 `detail.tmall.com/item.htm?id={id}&skuId={skuId}`），**禁止**输出以下几类：

- ❌ 搜索页 URL（如 `search.jd.com/Search?keyword=...`、`s.taobao.com/search?q=...`）
- ❌ 店铺首页 URL（如 `apple.tmall.com/`、`mall.jd.com/index-xxx.html`）
- ❌ 追踪跳转短链或截断的 `detail.tmall.com/item.htm`（缺 `id` 参数）
- ❌ 纯文本描述（如 `搜索页 → 钧沨数码卡片`）

采集流程：

1. 在搜索页 AX Tree 里 `sky.click({ element_index })` 目标商品卡片进入详情页。
2. 等待 ≥6s，`get_app_state` 拿地址栏 `Value` 完整 URL：
   ```js
   const s = await sky.get_app_state({ app: "com.google.Chrome", disableDiff: true });
   const addrLine = s.text.split("\n").find(l => /地址和搜索栏|Address and search bar/i.test(l));
   const url = addrLine.match(/Value:\s*(https?:\/\/[^,]+)/)?.[1];
   ```
3. **剥离追踪参数**，只保留业务必需字段：
   - 京东：`https://item.jd.com/{sku}.html`（去掉 `?pcdk=…&spmTag=…`）
   - 天猫：`https://detail.tmall.com/item.htm?id={id}&skuId={skuId}`（保留 `id` 与 `skuId`，去掉 `abbucket / mi_id / priceTId / spm / xxc / utparam / ns / ali_refid` 等）
   - 京东 SKU 号在 URL 里就是 `item.jd.com/(\d+)\.html`；如果详情页 URL 长得像 `item.jd.com/product/…`，需从 AX 树里再找一次 `data-sku` 或规范化 URL。
4. **仅当详情页 URL 拿到、SKU 已点选且 `verifySelectedSku` 通过**，才写入对比表。选错 SKU（如天猫默认 128GB 而非目标 256GB）会导致到手价与链接不对应，**必须重选后重取 URL 与价格**。
5. 若因反爬拿不到 URL，禁止用搜索页兜底；改为向用户报错并请求手动打开一次详情页后重试。
6. **天猫特别注意**：进入详情页后 URL 里的 `skuId` 可能只是默认 SKU；点选目标规格后 URL 通常会变，必须以**点选后**的 `skuId` 为准。

## 输出格式

统一 Markdown 对比表，**至少包含**下列列（商品状态、价格、发货、售后、销量、购买链接）：

```markdown
## <商品关键词> · 京东 vs 淘宝天猫 对比

| 维度 | 京东（<店铺名>）| 淘宝天猫（<店铺名>）|
|---|---|---|
| **商品** | <标题> | <标题> |
| **已选 SKU** | <颜色 + 容量 + 版本，如「黑色钛金属 256GB」> | <颜色 + 容量 + 版本，如「黑色钛金属 256GB」> |
| **SKU ID** | item.jd.com/<sku> | skuId=<skuId> |
| **商品状态** | 全新未激活国行 / 京东自营（新机） | 全新未激活国行 / 官方旗舰店（新机） |
| **购买链接** | [item.jd.com/xxx.html](https://item.jd.com/xxx.html) | [detail.tmall.com/item.htm?id=xxx&skuId=yyy](https://detail.tmall.com/item.htm?id=xxx&skuId=yyy) |
| **标价** | ¥xxxx | ¥xxxx |
| **国补/优惠** | ... | ... |
| **到手价** | ¥xxxx | ¥xxxx |
| **分期** | ... | ... |
| **发货** | ... | ... |
| **运费** | ... | ... |
| **销量/热度** | ... | ... |
| **店铺信誉** | ... | ... |
| **售后** | ... | ... |
| **延保加购** | ... | ... |
| **开发票** | ✅/❌ | ✅/❌ |

### 采购建议 ✅
- **推荐链接**：<商品详情页绝对 URL>（**不是**搜索页/店铺首页）
- **理由**：到手价 / 发货时效 / 售后 三点内说明
- **备选**：给出另一端的商品详情页绝对 URL 与适用场景
- **若两侧均非品牌官方直营**：必须附一条说明，例如"Apple 官方京东自营 & 天猫官方旗舰店已停售此型号；下列均为第三方全新未激活国行经销商，价格通常高于官网原价，可考虑改买 <官方在售替代款>"

> ⚠️ 价格与国补/发货时间为 <YYYY-MM-DD> 实时抓取，下单前请再次确认到手价与国补资格。
```

## 一键执行

```bash
# 唤起 Chrome，检查 cua-router，然后 Agent 分两步走：京东采集 → 淘宝采集
bash "./scripts/compare.sh" "<商品关键词>"
```

`scripts/compare.sh` 只负责启动 daemon 并把 `query` 传给 Agent；具体的抓取
和登录轮询由 Agent 使用 `bash "$SKILL_ROOT/scripts/exec.sh"` 执行内联 JS
完成，避免把复杂 AX 解析写死到 shell。

## 避坑清单

| 陷阱 | 解决 |
|------|------|
| `type_text` 输 URL 触发中文 IME | 一律 `set_value(addrIdx, url)` + `press_key("Return")` |
| AX 参数写 `elementIndex` / `idx` 报错 | 用 `element_index`（snake_case） |
| Playwright 占用 Chrome 无窗口 | `CUA_ROUTER_CHROME_PREFLIGHT=auto` 或 `preflight-chrome.sh fix` |
| 京东搜索结果里全是配件 | 用启发式过滤：剔除 `表带 / 保护壳 / 贴膜`；优先 `京东自营 / 官方旗舰店` |
| 淘宝详情页跳登录 | 触发 `waitLogin({ platform: "tb" })`，每 10s 复检 |
| 详情页 URL 带一大堆追踪参数 | 输出时保留 `id` / `skuId` / 短路径，剥离 `spm/xxc/ali_refid/utparam` 等 |
| 复用旧 AX idx | 每次 click 后立即 `get_app_state({ disableDiff: true })` 重新取树 |
| 到手价 ≠ 标价 | 优先输出到手价（考虑国补、券后、88VIP），标价单列 |
| 预售发货 | 明确写「预售，X 月 X 日前发货」，不要与"次日达"混淆 |
| 购买链接写成搜索页 URL | **禁止**。必须点进详情页取地址栏 `Value`，输出 `item.jd.com/{sku}.html` / `detail.tmall.com/item.htm?id=xx&skuId=yy` |
| **天猫默认 SKU ≠ 目标规格** | 进入详情页后**必须**在规格区点选目标容量/颜色，调用 `verifySelectedSku` 验证；禁止直接用默认 skuId 的价格 |
| **两侧 SKU 未对齐就输出比价** | 存储/颜色/型号必须语义等价；未对齐只能输出警告，不得给出「哪个更便宜」结论 |
| 对比结果混入二手/准新 | 默认仅对比全新未激活（含 `准新 / 二手 / 拍拍 / 95新 / 99新 / 严选 / 官方回收` 关键词的一律剔除）；用户显式要求"包含二手"才放行 |
| Apple 官方渠道搜不到目标 SKU | 视为已停售，改用第三方 `全新未激活 国行` 关键词兜底，并在采购建议里加官方停售说明 + 官方在售替代款 |
| Chrome AX Tree 只有窗口标题（<100 字符） | 参照 `cua-router-basic` "Chrome Full AX 强制启用"章节，用 `--force-renderer-accessibility` 重启 Chrome |

## 边界

- 只对比两个平台（京东 + 淘宝/天猫），不扩展到拼多多 / 抖音商城，除非用户明确要求。
- **默认只对比全新未激活国行**；命中二手/准新/翻新/拍拍/95新/99新/严选/官方回收等关键词的卡片一律剔除，除非用户明确要求"包含二手"。
- 不下单、不加购、不修改用户购物车。
- 不长期缓存价格；每次比价均实时抓取。
- 不针对 Pro/Ultra 等衍生型号做偏移推荐，除非用户指定。
- 输出建议仅供参考，最终以用户下单时页面显示为准。
