# Infinite Axe · 无限斧头（Build 42 版）

一把**无限耐久、永不变钝**的斧头。进游戏时若背包里没有会自动发放一把。

原版为 Build 41 时代编写，本目录是**迁移到 B42 语法后的版本**（v2.0）。旧版文档存档在 [`reference/InfiniteAxe-旧版B41文档.md`](../../reference/InfiniteAxe-旧版B41文档.md)。

---

## 安装

1. 把 `InfiniteAxe` 整个文件夹复制到：

   ```
   C:\Users\<你的用户名>\Zomboid\mods\
   ```

   复制后路径应为 `...\Zomboid\mods\InfiniteAxe\mod.info`

2. 启动游戏 → 主菜单 **Mods** → 勾选 **Infinite Axe**

3. 读档进入游戏。若背包里没有这把斧头，会**自动获得一把**。

**验证加载**：`C:\Users\<你>\Zomboid\console.txt` 中应出现

```
[InfiniteAxe] loaded - 无限斧头已加载
```

---

## 属性

| 项 | 值 | 原版手斧对比 |
|:---|:---|:---|
| 伤害 | 1.5 – 3.0 | 0.7 – 1.5 |
| 暴击率 / 暴击倍率 | 25% / ×5 | 15% / — |
| 砍树 / 破门 | 35 / 40 | 15 / — |
| 握持 | 单手（`TwoHandWeapon = FALSE`） | 单手 |
| 本体耐久 | `ConditionMax = 999999` | 15 |
| 掉耐久概率 | `1 / 1000000` | `1 / 10` |
| 刃部耐久 | `999999`，损耗倍率 `0` | — |
| 锋利度 | `1`（满值） | — |

外观（`Icon` / `WeaponSprite`）与音效全部**复用原版斧头资源**，不新增任何贴图或模型。

---

## 从 B41 迁移到 B42 改了什么

| 项 | 旧版（B41） | 本版（B42） | 依据 |
|:---|:---|:---|:---|
| 物品类型 | `Type = Weapon` | **`ItemType = base:weapon`** | 官方文档：`Type` 已废弃，`replacedBy: ItemType`，**废弃版本 42.13.0** |
| 标签 | `Tags = ChopTree;CutPlant;...` | **`Tags = base:choptree;base:cutplant;...`** | B42 标签命名空间化，共 459 个合法值 |
| `CraftedAxe` 标签 | 有 | **已移除** | B42 标签表中无对应项 |
| 翻译文件 | `UI_CN.txt` | **`ItemName.json` / `Tooltip.json`** | 翻译文件从 `.txt` 改为 `.json` 发生在 **B42.15** |
| 物品 ID | `Base.InfiniteAxe` | **`InfiniteAxe.InfiniteAxe`** | 改用独立模块，不再污染 `Base` |
| 刃部耐久 / 锋利度 | 未处理 | **已锁死** | B42 耐久是三层系统 |
| 已删参数 | `ShareDamage` / `ShareEndurance` | **已移除** | 这两个参数在 B42 的 376 个 item 参数中已不存在 |
| 背包搜索 | 自写递归 | **`getFirstTypeRecurse()`** | 引擎自带，比手写递归干净 |
| 补耐久频率 | 每 10 游戏分钟 | 约每 0.5 秒（仅双手） | 保证锋利度不会肉眼可见地下降 |

---

## ⚠️ 未验证事项

**本 mod 尚未在真实游戏中运行验证。**

- 文件编码、脚本括号配平、Lua 块结构已静态校验；脚本与 Lua 用到的每个 API 均在官方 Javadoc 中确认存在
- 物品脚本参数已逐个比对 B42 的 376 个 item 参数表，确认无失效参数

**仍未确认**：

1. **音效名 `AxeHit` / `AxeSwing` / `AxeBreak`** 是原版音效名，沿用旧版未改。B42 若已改名，斧头会静音（PZ 会打一条 `no GameSound called ...` 警告并自动补一个默认条目，不会报错）
2. `versionMin=42.13` 是按 `ItemType` 取代 `Type` 的版本推断的，未逐年验证
3. 斧头在 B42 是否真的存在"刃部耐久 / 锋利度"这两层——若不适用，相关赋值会被忽略（无害）

---

## 文件结构

```
InfiniteAxe/
├── mod.info
└── media
    ├── scripts/InfiniteAxe.txt                    物品定义
    └── lua
        ├── client/InfiniteAxe_Client.lua          发放 + 维持满状态
        └── shared/Translate
            ├── CN/{ItemName.json,Tooltip.json}    简体中文
            └── EN/{ItemName.json,Tooltip.json}    英文
```
