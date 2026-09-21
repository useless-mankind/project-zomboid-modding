# Project Zomboid Mod 开发速查手册

> **适用版本**：Build 42.20.x（官方首页实时显示 Stable 42.20.4 / Unstable 42.20.4）
> **B42 转正时间**：2026-07-29 由 unstable 进入 Stable 分支
> **整理日期**：2026-09
> **证据等级约定**：本手册内容标注来源，`[官方文档]` = TIS 发布或官方 Javadoc，`[社区文档]` = 社区自动生成的 API 文档，`[论坛]` = 官方论坛玩家实测帖。凡我推断的会明确写「推断」。

---

## 0. 五分钟起步（先跑通再说）

1. 游戏装好后，找到用户目录：`C:\Users\<你的用户名>\Zomboid\`
2. 在里面建 `mods\MyFirstMod\`
3. 放进两个东西：`mod.info` + `media\scripts\`（物品/配方脚本）
4. 启动游戏 → 主菜单 **Mods** → 勾选你的 mod → 开新档
5. 想调试就在 Steam 启动项里填 `-debug`，并选 **Alternate launch**

**只做物品和配方的话，到这里你一行代码都不用写。**

---

## 1. 游戏架构：你到底能改什么

Project Zomboid = **Java 引擎 + Lua 游戏逻辑**。

| 层 | 内容 | 能否 mod |
|---|---|---|
| Java 引擎 | 编译成 `zombie/` 下的 `.class` | ❌ 不能直接改，但**部分 API 暴露给 Lua** |
| Lua 逻辑 | 玩法逻辑、UI、事件响应 | ✅ **源码完全公开**，改完重启即生效，无需编译 |
| 脚本 `.txt` | 物品、武器、配方、载具、特质定义 | ✅ 声明式，零编程 |
| 资源 | 贴图 / 模型 / 地图 / 音效 | ✅ 需要美术或官方地图工具 |

**关键机制**：PZ 用 `se.krka.kahlua` 库把 Lua 嵌进 Java。Java 的部分 API 被"声明"进 Lua 的全局命名空间——在 Lua 里调用同名全局函数，实际上就是调 Java 方法。

因此你会看到这种写法：

```lua
-- 这是 Java 的 ArrayList 对象，在 Lua 里用冒号调用其方法
local list = someJavaMethod()
list:get(0)          -- 不是 list.get(0)
list:size()
```

`[社区文档]` PZ-LuaFileStruct

**注意**：Java 的很多原生方法在 Lua 里也能全局调用，但这是开发者手工写进 Lua 命名空间的结果，不是 Lua 语言特性。绕过 Lua 直接调 Java 有性能开销，别放进 `OnTick` 这类每帧回调里。

---

## 2. 资料地图

| 资源 | 能查到什么 |
|:---|:---|
| [projectzomboid.com/modding/](https://projectzomboid.com/modding/) | **官方 Javadoc**，Java 侧 API 全量。`IsoPlayer`、`HandWeapon`、`InventoryItem` 等类的方法签名来这里 |
| [pz-wiki-modding.github.io/PZ-API-Docs](https://pz-wiki-modding.github.io/PZ-API-Docs/) | **脚本块文档，页头标注版本（当前 42.20.4）**。每个 `.txt` 脚本块的参数、类型、默认值，**B42 脚本的第一手资料** |
| [demiurgequantified.github.io/ProjectZomboidLuaDocs](https://demiurgequantified.github.io/ProjectZomboidLuaDocs/) | Lua 侧 API 文档（42.20.3），社区自动生成，还比较新 |
| [FWolfe/Zomboid-Modding-Guide](https://github.com/FWolfe/Zomboid-Modding-Guide) | 459★，最大社区指南。**B41 时代为主**，脚本语法大多仍有效 |
| [demiurgeQuantified/PZ-events-guide](https://github.com/demiurgeQuantified/PZ-events-guide) | `Events` / `Hook` 全清单。写机制类 mod 必备 |
| [demiurgeQuantified/PZEventStubs](https://github.com/demiurgeQuantified/PZEventStubs) | **每个事件的类型签名**（权威）。写 Lua 回调前先来这里查参数 |
| [asledgehammer/Umbrella](https://github.com/asledgehammer/Umbrella) | PZ modding 框架，带 EmmyLua 类型定义，编辑器可自动补全 |
| [theindiestone.com/forums](https://theindiestone.com/forums/) | 官方论坛。Modding 分区下 **Tutorials & Resources** 最有用；**实测帖价值常被低估** |
| [pzwiki.net](https://pzwiki.net/wiki/Modding) | 内容最全的"第一站" |
| [m.namu.moe](https://m.namu.moe/) | 韩语 namu 百科镜像，PZ 数值极详细（该页标注 42.20.2）。**仅作交叉验证，非官方** |
| GitHub 仓库搜索 + `git clone` | **找原版定义的最快路径**——搜"抄了原版定义的 mod 仓库"，见附录 B |

> 现实提醒：论坛里长期有人抱怨"教程散落各处，没人讲清文件放哪"`[论坛]`。**以 pz-wiki-modding 的脚本文档 + 官方 Javadoc 为准**，视频和二手教程经常还是 B41 时代的。
>
> 这份手册本身也是**边做边记**的产物。找资料的具体手法、查 API 是否存在的流程、以及踩过的坑，都整理在 **附录 B**——**下次开新 mod 前先看那一节**。

---

## 3. Mod 类型全景与选题建议

| 类型 | 难度 | 产出周期 | 门槛 | 说明 |
|---|---|---|---|---|
| 物品 / 武器 / 食物 | ★☆☆☆☆ | 1 小时 | 会写 txt | 纯声明式。真正的门槛是找图标素材 |
| 配方（craftRecipe） | ★★☆☆☆ | 2 小时 | 会写 txt | B42 新语法，见 §6 |
| **Lua 机制改写** | ★★★☆☆ | 半天～数天 | Lua | **自由度最高**。挂 Events/Hook 改规则 |
| **UI / HUD** | ★★★☆☆ | 半天 | Lua + 一点绘图 | 弹药显示、状态面板之类 |
| 角色特质 / 职业 | ★★★☆☆ | 半天 | txt + Lua | B42 需要配 registries，稍麻烦 |
| 载具 | ★★★★☆ | 数天 | 建模 + 脚本 | 需要 3D 模型 |
| 地图 | ★★★★☆ | 数周 | 官方编辑器 | 必须用 TIS 的 TileZed / WorldEd，不能换工具 |
| 大型整合（overhaul） | ★★★★★ | 数月 | 全能 | 不建议作为第一个项目 |

`[社区文档]` `[官方文档]`

### 针对你的三个推荐选题

你的背景是 Java 后端/Android 开发，**Lua 对你几乎零门槛**（语法比 Java 简单得多），所以完全可以直接从 ★★★ 起步，跳过纯脚本练手阶段。

**选题 A —「弹药/状态 HUD」**（难度 ★★★，最快出成果）
- 参考实现：[LabX1/ProjectZomboid-Build42-ModTemplate](https://github.com/LabX1/ProjectZomboid-Build42-ModTemplate) 就是一个"显示当前武器弹药 + 膛内 +1 + 颜色分级 + 可拖拽"的完整 UI mod
- 学到：`media/lua/client/`、`OnPostUIDraw`/`OnPlayerUpdate` 事件、UI 绘制、跨版本目录结构
- 好处：有现成参照物，出成果快，能立刻建立正反馈

**选题 B —「机制改写：自定义僵尸行为」**（难度 ★★★，最能体现 PZ mod 的核心玩法）
- 真实可用的 Hook：`Hook.WeaponHitCharacter`、`Hook.Attack`、`Hook.CalculateStats`
- 真实可用的事件：`OnZombieUpdate`、`OnZombieDead`、`EveryTenMinutes`、`EveryOneMinute`
- 参考框架：[Zomboid Forge B42](https://github.com/SimKDT/Zomboid-Forge-B42)（自述为"添加自定义僵尸类型且尽量兼容其他 mod"的框架，其 ZType 机制把 7 项僵尸属性做成 tag）
- 学到：Hook vs Event 的区别（见 §7.3）、运行时改 sandbox 参数

**选题 C —「科幻恐怖题材的生存机制」**（难度 ★★★★，贴合你的口味）
- PZ 本身是 90 年代肯塔基丧尸题材，科幻向 mod 有差异化空间
- 可落地方向：辐射区/污染地块（用区域判定 + `EveryTenMinutes` 扣血）、需要维护的动力装甲（耐久 + 资源消耗）、异常天气事件（`zombie.iso.weather` 包）
- 学到：世界区域查询、定时事件、资源系统——这三样是绝大多数大型 mod 的地基

`[社区文档]` `[论坛]`

---

## 4. B42 目录结构（**最容易翻车的地方**）

### 4.1 本地开发用（推荐日常用这个）

```
C:\Users\<你>\Zomboid\mods\MyMod\
├── mod.info                  ← 必须叫这个名字
├── poster.png                ← 可选，mod 封面
└── media\
    ├── lua\
    │   ├── shared\           ← 客户端+服务器共用，最先加载
    │   ├── client\           ← 仅客户端（UI、右键菜单、定时动作）
    │   └── server\           ← 仅服务器（刷物品、天气；单机开局后才加载）
    ├── scripts\              ← 物品/配方/载具/特质 .txt
    ├── textures\             ← 贴图（物品图标用 Item_ 前缀）
    ├── sound\                ← .wav / .ogg
    └── maps\                 ← 地图
```

`[社区文档]` FWolfe guide / PZ-LuaFileStruct `[论坛]`

### 4.2 创意工坊（上传用，B42 新结构）

```
MyMod\
├── Contents\mods\MyMod\
│   ├── common\               ← 各版本共用资源
│   │   └── media\...
│   ├── 42.0\                 ← B42 专用，**必须自带 mod.info**
│   │   ├── mod.info
│   │   └── poster.png
│   └── 41\                   ← B41 兼容（可省）
└── workshop.txt              ← 工坊配置
```

`[社区文档]` LabX1 B42 ModTemplate

**版本目录名到底叫什么？** 两个实测样本给出同一个规律——**目录名就是版本号，可以有三种形态**：

| 样本 | 版本目录 | 该目录 `mod.info` 里的版本声明 |
|:---|:---|:---|
| `micksatana/pz-mod-michonnes-katana` | `42/`、`42.15/` | **完全不写 `versionMin` / `versionMax`**（只靠目录名区分） |
| 另一 B42 大型机制 mod（见附录 B） | `42.14/`、`42.15/` | `42.14/` 写 `versionMin=42.14` + **`versionMax=42.14`（锁死）**；`42.15/` 只写 `versionMin=42.15`（不写上限＝向上开放到 42.20+） |

所以：

- **目录名可以精确到 minor**（`42.14` 是合法的版本目录名），不限于 `42` 或 `42.15`。泛目录用 `42` 覆盖一整段，要精确锁版本就写 `42.14`。
- **`versionMin` / `versionMax` 是可选的**，靠目录名分版本才是主机制；一旦要写，格式是 `major.minor`（`42.0`、`42.14` 都可以，**裸写 `42` 不生效**）。
- **两个样本都没有出现 `42/` 与 `42.14/` 并存**的情况——`[推断]` 同一 mod 内版本目录段不应重叠，否则哪个生效无保证。

做本地开发用扁平结构即可，只有上传工坊才需要版本目录。

**为什么工坊结构这么绕？** 论坛原帖的吐槽原文：作者想给 B41/B42 出两个版本供玩家各自下载，结果发现 B42 必须在 mod 内部再套一层版本目录，他说"为什么非得这样我想不通"。`[论坛]` 这是个历史包袱，不是你操作错了。

---

## 5. `mod.info` 完整字段（`[官方文档]`）

```
name=我的第一个 Mod
id=MyFirstMod
description=基础示例 mod
author=你的名字
modversion=1.0
poster=poster.png
icon=icon.png
url=https://example.com
category=features
versionMin=42.0
versionMax=42.20
```

| 字段 | 类型 | 说明 |
|---|---|---|
| `name` | translation | 显示名（可走翻译，见 §8） |
| `id` | string | **唯一标识**，mod 列表和服务器用它启用 mod。**不是工坊 ID** |
| `description` | translation | 描述，支持 `ISRichTextPanel` 标签 |
| `author` | string | 作者，多个用逗号 |
| `modversion` | string | mod 自己的版本号 |
| `poster` | string | 封面图，**可写多行**放多张图 |
| `icon` | string | 列表里名字旁的小图标 |
| `url` | string | mod 管理器里的 "Homepage" 链接 |
| `category` | string | **只认这几个**：`map` / `vehicle` / `features` / `modpack`。写别的不会生成新分类 |
| `versionMin` / `versionMax` | string | 可选，格式 `major.minor`（如 `42.0`、`42.14`）。**只写 `42` 不生效**。不写就靠版本目录名区分（见 §4.2） |
| `require` | string | 前置 mod，逗号分隔 |
| `loadModBefore` / `loadModAfter` | string | 加载顺序控制 |
| `incompatible` | string | 互斥 mod，启用后对方变灰不可选 |
| `pack` | string | 需要加载的 pack 文件（贴图包 / tile 包） |
| `tiledef` | string | 新增 tiledef 及其 ID，例：`tiledef=Excavation 2112`。**ID 会和其他 mod 冲突**，需查社区登记表。⚠️ **同一 mod 的不同版本目录要各写一个 ID**——可用 ID 段随 build 变化，实测同一 mod 的 `42.14/mod.info` 写 `13232`、`42.15/mod.info` 写 `5933` |

---

## 6. 脚本层：物品与配方（零编程）

所有定义放在 `media/scripts/*.txt`，用 `{ }` 分块。

### 6.1 module / imports 结构

```
module MyMod {
    imports { Base }

    item MyItem {
        ItemType    = base:normal,
        DisplayName = My First Item,
        Icon        = MyIcon,
        Weight      = 0.1,
    }
}
```

- `module` 名会成为物品全名的前缀：上面这个物品叫 `MyMod.MyItem`
- **vanilla 物品大多在 `Base` 模块**。用 `Base` 可以，但**定义同名物品会直接覆盖原版物品**——这既是改原版数值的手段，也是冲突来源
- `imports { Base }` 让你能直接写 `Nails` 而不用写 `Base.Nails`。不写 `imports` PZ 会打警告，可忽略

`[社区文档]` FWolfe guide

### 6.2 物品块

```
item MyKnife {
    DisplayName    = My Knife,
    DisplayCategory = Weapon,
    ItemType       = base:weapon,          // B42 语法（B41 是 Type = Weapon）
    Icon           = MyKnife,
    Weight         = 1.0,
    MaxDamage      = 1.5,
    SwingTime      = 3,
    TreeDamage     = 5,
    ConditionMax   = 10,
    Categories     = SmallBlade,
    Tags           = base:hasmetal;base:sharpknife,   // B42 标签带命名空间
}
```

**要点**：
- 物品块用 `属性 = 值,`（等号），配方块用 `属性:值,`（冒号）——**别搞混**
- **`ItemType = base:<类型>` 是 B42 写法**，B41 的 `Type = Weapon` 已过时。常见值：`base:weapon`、`base:normal`、`base:literature`、`base:food`
  - **精确分界**：官方参数文档里 `Type` 的废弃记录写着 `replacedBy: ItemType`、`version: 42.13.0`——即**从 B42.13 起 `Type` 被 `ItemType` 取代**
  - `ItemType` 是**封闭枚举**，共 15 个合法值（`base:alarmclock` / `base:clothing` / `base:container` / `base:drainable` / `base:food` / `base:key` / `base:literature` / `base:map` / `base:moveable` / `base:normal` / `base:radio` / `base:weapon` / `base:weaponpart` 等），**不能用自定义值**（官方原话：*You cannot use a custom class of item*）。**没有 `base:gun`**——枪械也是 `base:weapon`
- **`Tags` 在 B42 是命名空间化的**（`base:hasmetal`、`base:katana`、`base:sharpenable`），不是 B41 的裸字符串
  - **合法标签共 459 个**，完整列表见 [Item Tags](https://pz-wiki-modding.github.io/PZ-API-Docs/java/item_tags.html)（该页同时给出对应的 `ItemTag.XXX` Lua 常量名）
  - 写标签前**先查表**：B41 的不少标签在 B42 没有对应项（例如 `CraftedAxe`），照抄会静默失效
- `Icon` 指 `media/textures/` 下的 png，不带扩展名（文件名需 `Item_` 前缀，参数值不写）
- 完整参数表（376 个）见 [脚本文档 item 页](https://pz-wiki-modding.github.io/PZ-API-Docs/scripts/item.html)
- 做武器时**优先复用原版资源**：`Icon` / `WeaponSprite` / 音效 `event` 直接指向原版，外观手感立刻正确，还省掉美术工作
- 武器耐久是**三层系统**（本体 / 刃部 / 锋利度），见 附录 B.4

### 6.3 `craftRecipe`：B42 全新合成系统 ⚠️

**这是 B42 最大的破坏性变更**：B41 的 `recipe` 块被 `craftRecipe` 取代，配 `inputs`/`outputs` 子块。B41 教程里的配方写法**不能照抄**。

官方文档给出的完整示例：

```
module Base {
    craftRecipe SawLogs {
        timedAction = SawLogs,
        Time = 230,
        Tags = InHandCraft;CanBeDoneFromFloor,
        category = Carpentry,
        xpAward = Woodwork:5,
        inputs {
            item 1 [Base.Log] flags[Prop2],
            item 1 tags[Saw] mode:keep flags[MayDegradeLight;Prop1],
        }
        outputs {
            item 3 Base.Plank,
        }
    }
}
```

带学习条件的：

```
craftRecipe CarveWhistle {
    time = 200,
    tags = AnySurfaceCraft;Survivalist,
    category = Carving,
    xpAward = Carving:60,
    SkillRequired = Carving:6,
    needTobeLearn = true,
    AutoLearnAny = Carving:8,
    timedAction = SharpenStake,
    inputs {
        item 1 tags[DrillWood;DrillMetal;DrillWoodPoor] mode:keep flags[MayDegradeLight],
        item 1 tags[SharpKnife] mode:keep flags[MayDegradeLight],
        item 1 [Base.SmallAnimalBone] flags[Prop2;AllowDestroyedItem],
    }
    outputs {
        item 1 Base.Whistle_Bone,
    }
}
```

`[官方文档]` pz-wiki-modding craftRecipe 页（42.20.4）

**`craftRecipe` 主要参数**：

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `Tags` | array（`;` 分隔） | — | **必填**。必须含至少一个工作台 tag 才会被识别，如 `AnySurfaceCraft`、`InHandCraft` |
| `Time` / `time` | integer | 50 | 耗时（任意单位，参考原版数值） |
| `category` | translation | `Miscellaneous` | 合成菜单分类，需配 `IGUI_CraftingCategories_` 前缀的翻译键 |
| `xpAward` | `技能:数值;技能:数值` | — | 例 `Blacksmith:10;Tailoring:5` |
| `SkillRequired` | `技能:等级;...` | — | 例 `Blacksmith:3;Tailoring:2` |
| `AutoLearnAll` / `AutoLearnAny` | `技能:等级;...` | — | 达到等级自动学会（全部 / 任一） |
| `needTobeLearn` | boolean | — | 是否必须先学会 |
| `AllowBatchCraft` | boolean | `true` | 是否允许批量合成（显示数量滑块） |
| `CanWalk` | boolean | `false` | 合成时能否走动 |
| `timedAction` | block | — | 引用 `timedAction` 脚本块，管动画/音效/消耗 |
| `Icon` | string | — | `media/textures/` 下的图标；**默认用产出物图标**，原版几乎不用这个 |
| `OnCreate` / `OnTest` / `OnFailed` / `OnUpdate` | callback | — | Lua 回调，见下 |
| `MetaRecipe` | — | — | 单向关联：会 A 则自动会 B，反之不然 |
| `Tooltip` | translation | — | 合成菜单里的描述，需配 `Tooltip.json` |
| `ResearchSkillLevel` | integer | -1 | 研究该配方所需等级；`Inventive` 特质降 2 级 |

**`inputs` 语法要点**（B41 完全没有的概念）：
- `item <数量> <物品全名>` — `item 3 Base.Plank`
- `[A;B;C]` — 方括号内为**可接受的多个物品**（替代 B41 的 `/`）
- `tags[Saw]` — 按**标签**匹配而非具体物品，兼容性远好于枚举物品名
- `mode:keep` — 用完不消耗（工具）；`mode:destroy` — 消耗
- `flags[...]` — 附加条件，如 `MayDegradeLight`（可能掉耐久）、`NotFull`、`AllowFavorite`、`InheritFavorite`、`ItemCount`、`AllowDestroyedItem`、`Prop1`/`Prop2`
- `-fluid 1.0 [Petrol]` — 消耗流体
- `[*]` — 任意物品（占位）

**回调函数签名**（必须写成全局函数）：

```lua
---@param craftRecipeData CraftRecipeData
---@param character IsoGameCharacter
function MyOnCreateFunction(craftRecipeData, character)
    -- 你的逻辑
end

---@param item InventoryItem
---@param character IsoGameCharacter
---@return boolean
function MyOnTestFunction(item, character)
    return true   -- 返回 false 则该物品不可用于此配方
end
```

`[官方文档]`

### 6.4 B41 → B42 差异速查

| 项目 | B41 | B42 |
|---|---|---|
| 合成 | `recipe` 块 | **`craftRecipe` + inputs/outputs** |
| 工具不消耗 | `keep KitchenKnife` | `mode:keep` |
| 多选一 | `A/B/C` | `[A;B;C]` 或 `tags[...]` |
| 产出 | `Result:Nails=20` | `outputs { item 20 Base.Nails, }` |
| **物品类型** | `Type = Weapon` | **`ItemType = base:weapon`**（B42.13 起取代） |
| **物品标签** | `Tags = SharpKnife;HasMetal` | **`Tags = base:sharpknife;base:hasmetal`**（命名空间化，合法值 459 个） |
| **武器耐久** | 单层 `ConditionMax` | **三层：`Condition` / `HeadCondition` / `Sharpness`**（见附录 B.4） |
| 翻译文件 | `.txt`（`IG_UI_EN = { ... }`） | **`.json`**（**B42.15 起**切换，见 §8） |
| 工坊结构 | 扁平 | `Contents/mods/<名>/<build.major>/` |
| 特质 | 直接定义 | 需配 registries |

> 上表中前三行来自官方文档；**加粗的三行是本次实证得出的**（对照成熟 B42 mod 的脚本原文），普通中文教程基本都还是 B41 写法。

---

## 7. Lua 层

### 7.1 加载顺序

`shared` → `client` → `server`。`server` 目录下的脚本**只有在真正开局/开服后才加载**（不是主菜单）。

文件名不影响加载顺序，别指望靠命名控制时序——要控制顺序用 `mod.info` 的 `loadModBefore`/`loadModAfter`。

### 7.2 Events（事件）

事件由 Java 侧触发，把你的函数挂上去，只在条件满足时执行。

```lua
function playerCreated(playerNum, player)
    player:Say("I just spawned!")
end

Events.OnCreatePlayer.Add(playerCreated)
```

**常用事件（真实名称，`[社区文档]` PZ-events-guide）**：

| 事件 | 用途 |
|---|---|
| `OnGameStart` | 开局初始化，**注册框架/自定义内容的标准位置** |
| `OnGameBoot` / `OnPreGameStart` | 更早的启动钩子 |
| `OnCreatePlayer` | 玩家创建（参数：Player Index, IsoPlayer） |
| `OnPlayerUpdate` / `OnTick` | 每帧/每次更新，**注意性能** |
| `EveryOneMinute` / `EveryTenMinutes` | 定时逻辑的最佳落点 |
| `OnPlayerDeath` / `OnCharacterDeath` / `OnZombieDead` | 死亡处理 |
| `OnFillInventoryObjectContextMenu` | 给物品加右键菜单项 |
| `OnFillWorldObjectContextMenu` | 给世界物体加右键菜单项 |
| `OnWeaponHitCharacter` / `OnWeaponSwing` / `OnWeaponHitTree` | 战斗相关 |
| `OnKeyPressed` / `OnKeyStartPressed` | 快捷键 |
| `OnCreateUI` / `OnPostUIDraw` | UI 创建与绘制 |
| `OnSave` / `OnLoad` | 存档钩子 |
| `AddXP` / `LevelPerk` | 经验与技能升级 |
| `OnZombieUpdate` | 僵尸逐帧逻辑 |

完整 130+ 个事件清单见 [PZ-events-guide/Events.md](https://github.com/demiurgeQuantified/PZ-events-guide/blob/master/Events.md)。

### 7.3 Hook（钩子）

**Hook 和 Event 的区别**：Event 是"额外执行你的代码"，**Hook 是"取代原版 Java 代码"**。

```lua
-- 注意是 Hook，不是 Hooks；与 Events 不同
function cantHit(owner, weapon)
    owner:Say("I can't hit anything!")
end

Hook.WeaponSwing.Add(cantHit)
```

已知 Hook 清单（`[社区文档]`）：

| Hook | 参数 | 触发点 |
|---|---|---|
| `WeaponSwing` | owner, weapon | `SwipeStatePlayer:enter()` |
| `WeaponHitCharacter` | attacker, target, weapon, damageSplit | `IsoGameCharacter:Hit()` |
| `Attack` | attacker, ChargeDelta, weapon | `IsoLivingCharacter:attemptAttack()` |
| `CalculateStats` | character | `IsoGameCharacter:calculateStats()` |
| `AutoDrink` | character | `IsoGameCharacter:autoDrink()` |

已废弃：`UseItem`、`WeaponSwingHitPoint`。

**参数类型提示**：传进来的对象可能是子类实例（比如传 `IsoPlayer` 而文档写 `IsoGameCharacter`）。查方法签名去[官方 Javadoc](https://projectzomboid.com/modding/zombie/characters/IsoPlayer.html)。

### 7.4 一个完整的 client Lua 示例

```lua
-- media/lua/client/MyMod_Init.lua

local function onGameStart()
    print("[MyMod] game started")
end

local function onPlayerUpdate(player)
    -- 注意：这个回调频率极高，别做重活
    if player:isDead() then return end
end

Events.OnGameStart.Add(onGameStart)
Events.OnPlayerUpdate.Add(onPlayerUpdate)
```

`print()` 的输出会进 `console.txt` 和调试控制台窗口——**这是你最主要的调试手段**。

---

## 8. 翻译（做中文 mod 必读）

**B42 把翻译文件换成了 JSON**（B41 的 `.txt` 写法已不适用）。`[官方文档]`

> **精确分界**：实测一个同时带 `42.14/` 与 `42.15/` 两个版本目录的工坊 mod，前者翻译文件是 `ItemName_CN.txt`、后者是 `ItemName.json`——**`.txt` → `.json` 的切换发生在 B42.15**。写跨版本兼容的 mod 时要按这个分界分目录放。

存放位置：`media/lua/shared/Translate/<语言码>/`

常用文件与键前缀：

| 文件名 | 键前缀 | 用途 |
|---|---|---|
| `ItemName.json` | 无（键=物品全名） | **物品名** |
| `Recipes.json` | 无（键=`craftRecipe` 的 ID） | **配方名** |
| `IG_UI.json` | `IGUI_` | 界面文本、合成分类名 |
| `UI.json` | `UI_` | 界面元素（含特质名/描述） |
| `Tooltip.json` | `Tooltip_` | 提示框 |
| `Mod.json` | 无 | **mod.info 里的 name / description** |
| `ContextMenu.json` | `ContextMenu_` | 右键菜单 |
| `Sandbox.json` | `Sandbox_` | 沙盒选项 |

例（`ItemName.json`）：
```json
{
  "MyMod.MyKnife": "我的刀"
}
```

例（`Recipes.json`，**键不带 module 前缀**）：
```json
{
  "SawLogs": "锯木头"
}
```

例（`IG_UI.json`，自定义合成分类）：
```json
{
  "IGUI_CraftingCategories_MyCategory": "我的分类"
}
```

**新增一门语言**需要建一个以语言码命名的文件夹，里面放 `language.json`。

中文语言码请查 [Language Codes](https://pz-wiki-modding.github.io/PZ-API-Docs/translations/language_codes.html)（简体中文通常是 `CN`，B41 时代如此；**B42 请以该页为准**）。

`[官方文档]`

---

## 9. 调试与迭代

### 9.1 开调试模式（`[论坛]` 玩家实测，2026-03）

1. Steam → 库 → 右键 Project Zomboid → **属性** → **启动选项**，填入：
   ```
   -debug
   ```
2. 启动时**选 "Alternate launch"（备选启动）**，不要选默认启动
3. 效果：开启游戏内调试菜单 **+ 弹出命令行日志窗口**，Lua 报错直接显示位置

### 9.2 日志文件位置

```
C:\Users\<你>\Zomboid\console.txt          ← 主日志，Lua 错误在这
C:\Users\<你>\Zomboid\coop-console.txt     ← 本地主机服务器
C:\Users\<你>\Zomboid\server-console.txt   ← 专用服务器
```

`[社区文档]` PZ-LuaFileStruct

### 9.3 热重载现实

- **脚本 `.txt`（物品/配方）**：改完退出重进即生效，无需重开档
- **Lua 文件**：B42 调试模式下有 Lua 重载能力，但**改事件注册类代码仍建议重启游戏**，否则重复注册会导致回调叠加
- **贴图**：需要重启


---

## 10. 踩坑清单

按"新手最常卡住"排序：

1. **`mod.info` 文件名不对** —— Windows 默认隐藏扩展名，很容易做成 `mod.info.txt`，游戏直接无视。论坛里"本地 mod 不显示"的帖子十有八九是这个 `[论坛]`
2. **把 B41 的 `recipe` 语法抄进 B42** —— B42 要 `craftRecipe`，且 `Tags` 必填，否则配方根本不出现
3. **`inputs` 里忘了 `mode:keep`** —— 你的锤子会在合成后被吃掉
4. **工坊结构没套版本目录** —— 必须是 `Contents\mods\<名>\42.0\`，而不是 `Contents\mods\<名>\`
5. **本地开发目录放错** —— 日常开发放 `Zomboid\mods\`；`Zomboid\Workshop\` 是给工坊下载/上传用的，放错了可能不显示
6. **`item` 块和 `recipe` 块标点混用** —— item 用 `=`，recipe/craftRecipe 用 `:`
7. **模块命名冲突** —— 用 `Base` 模块定义同名物品会**覆盖原版**；自定义内容建议用独立模块名（通常与 mod id 同名）
8. **在 `OnTick`/`OnPlayerUpdate` 里做重活或频繁调 Java API** —— 帧率直接崩
9. **`tiledef` ID 撞车** —— 加 tile 包必须查社区 ID 登记表；而且**每个版本目录要各写一个 ID**（可用 ID 段随 build 变化，实测同一 mod 的 `42.14/` 用 `13232`、`42.15/` 用 `5933`），别把旧版本目录的 ID 直接抄进新版本目录
10. **`versionMin` 写成 `42`** —— 必须 `major.minor` 格式（`42.0`、`42.14`），否则不生效。反过来说，**版本目录名可以精确到 minor**（`42.14/` 是合法目录名），不是只能叫 `42` 或 `42.15`；`versionMin` / `versionMax` 本身则是可选的，靠目录名分版本才是主机制

---

## 11. 发布到创意工坊

1. 在 `Zomboid\Workshop\<你的 mod 名>\` 下按 §4.2 建好结构
2. 写 `workshop.txt`：
   ```
   version=1
   id=你的工坊ID
   title=Mod 标题
   description=描述
   visibility=public
   ```
3. 游戏内 **Workshop** 菜单 → 创建/更新条目
4. **首次发布后拿到工坊 ID，把它填回 `workshop.txt` 的 `id`**

`[社区文档]`

**注意**：`mod.info` 的 `id` 是 mod 的唯一标识（玩家启用 mod 用它），**与工坊 ID 是两个不同的东西**。

---

## 12. 枪械与弹药系统

本章回答两个问题：**B42 的枪械/弹药是怎么定义的**，以及**"无限弹药"这类需求能不能做、怎么做**。

**证据等级**：脚本参数来自官方参数文档（页头标注 42.20.4），Lua API 逐个在官方 Javadoc 中核实存在，事件签名来自社区类型存根。凡我没验证的一律标注，见 [12.7](#127-未验证事项)。

---

### 12.1 核心：两种装填模式

由 **`MagazineType`** 一个参数决定。这是所有枪械 mod 设计的岔路口：

| 写法 | 装填方式 | 弹药存放在 | 换弹消耗品 |
|:---|:---|:---|:---|
| **不写** `MagazineType` | 逐发装填 | **枪本身** | 背包里的散装子弹 |
| **写** `MagazineType = 某弹匣物品` | 换弹匣 | **弹匣物品** | 弹匣物品 |

`MaxAmmo` 是容量参数，作用于"枪或弹匣"中实际存弹药的那一方。`[官方文档]`

**因此写弹药相关逻辑时必须分支处理**：

```lua
if weapon:usesExternalMagazine() then
    -- 弹匣模式：弹药在弹匣物品上，不是枪上
else
    -- 逐发模式：弹药就在枪上
end
```

`usesExternalMagazine()` 在 `HandWeapon` 上，已核实存在。`[官方文档]`

---

### 12.2 枪械脚本参数

| 参数 | 类型 | 默认 | 说明 |
|:---|:---|:---|:---|
| `ItemType` | string | — | **必填**。枪械填 **`base:weapon`**——`ItemType` 是**封闭枚举**，`base:weapon` 是唯一的武器类型，**没有 `base:gun` 这种东西**，也**不允许自定义**（文档原话：*You cannot use a custom class of item*）。把物品标记为"枪"靠的是下面的 `IsAimedFirearm` |
| `IsAimedFirearm` | boolean | — | **开启整套瞄准射击子系统**：弹道控制器、准星、枪口火光、枪械专属耐久处理、弹道命中判定。**任何正规枪械都要设 `true`** |
| `Ranged` | boolean | — | 与 `IsAimedFirearm` **不同**：只把物品标记为"远程武器"以供动画条件使用 |
| `MagazineType` | block(item) | — | 见 12.1。不写则逐发装填 |
| `MaxAmmo` | integer | — | 容量（枪或弹匣） |
| `ClipSize` | integer | — | ⚠️ **B42 已废弃**，文档明写 `Is useless: True`，**不要再用** |
| `AmmoType` | string | — | **开火时消耗哪种弹药**，取值引用 registries 条目，如 `base:bullets_9mm`。同时决定弹道轨迹与命中音效的查找 |
| `AmmoBox` | block(item) | — | 关联的弹药盒物品，**主要用于刷枪时顺带刷出对应弹药盒** |
| `HaveChamber` | boolean | `True` | 除弹匣外是否有弹膛（可多压一发） |
| `JamGunChance` | float | `1.0` | 每次扣扳机的**卡壳基础概率**。最终判定还会叠加沙盒的卡壳倍率与枪的当前耐久。设 `0` 即永不卡壳 |
| `WeaponReloadType` | string | `handgun` | 换弹流程类型，影响"开火后是否拉栓"、插入方式与动画。取值对应 AnimNodes 里的 `WeaponReloadType` 条件 |
| `Projectilecount` | integer | `1` | **仅在武器为 `Ranged` 且 `RangeFalloff = true` 时生效**——该模式下弹道控制器会生成多枚散布弹丸 |
| `GunType` | string | — | 枪械分类 |
| `MinSightRange` / `MaxSightRange` | — | — | 瞄准距离区间。CQC 枪应低，狙击枪应高 |
| `RecoilDelay` / `RecoilDelayModifier` | — | — | 后坐力 |
| `RangeFalloff` | — | — | 距离伤害衰减，与 `Projectilecount` 联动 |
| `PiercingBullets` | — | — | 是否穿透 |
| `ProjectileSpread` / `ProjectileSpreadModifier` | — | — | 散布 |
| `MuzzleFlashModelKey` | — | — | 枪口火光模型 |
| 音效组 | — | — | `EjectAmmoSound`、`InsertAmmoSound`、`RackSound`、`ShellFallSound` 等，另有各自的 `Start`/`Stop` 变体 |

`[官方文档]` 完整参数表见 [脚本文档 item 页](https://pz-wiki-modding.github.io/PZ-API-Docs/scripts/item.html)（376 个参数）。

**无文档的枪械参数**（参数存在但官方没写说明，不要臆测语义）：
`InsertAllBulletsReload`、`ManuallyRemoveSpentRounds`、`RackAfterShoot`、`needtobeclosedoncereload`

---

### 12.3 弹药相关 Lua API

**以下每个方法都在官方 Javadoc 中逐个核实存在。**

| 方法 | 所在类 | 用途 |
|:---|:---|:---|
| `getCurrentAmmoCount()` | `InventoryItem` | 当前弹药数（`HandWeapon` 继承，可直接对枪调用） |
| `setCurrentAmmoCount(int)` | `InventoryItem` | **改当前弹药数** ← 无限弹药的关键 |
| `getMaxAmmo()` / `setMaxAmmo(int)` | `InventoryItem` | 容量 |
| `getAmmoType()` / `setAmmoType(AmmoType)` | `InventoryItem` | 弹药类型 |
| `haveChamber()` | `HandWeapon` | 是否有弹膛 |
| `isRoundChambered()` / `setRoundChambered(bool)` | `HandWeapon` | 膛内是否有实弹 |
| `isSpentRoundChambered()` / `setSpentRoundChambered(bool)` | `HandWeapon` | 膛内是否是空壳 |
| `getSpentRoundCount()` / `setSpentRoundCount(int)` | `HandWeapon` | 空壳计数 |
| `usesExternalMagazine()` | `HandWeapon` | **是否使用外置弹匣**（12.1 的分支依据） |
| `isContainsClip()` / `setContainsClip(bool)` | `HandWeapon` | 是否插着弹匣 |
| `isReloadable(IsoGameCharacter)` | `HandWeapon` | 当前是否可换弹 |
| `isJammed()` / `setJammed(bool)` | `HandWeapon` | 卡壳状态 |
| `isAimedFirearm()` | `HandWeapon` | 是否为瞄准式枪械 |
| `getAmmoPerShoot()` / `setAmmoPerShoot(int)` | `HandWeapon` | **每发消耗几颗弹药**（注意：**不是脚本参数**，只能运行时改） |
| `getFireMode()` / `setFireMode(String)` / `isSelectFire()` | `HandWeapon` | 射击模式 |
| `IsWeapon()` | `InventoryItem` | **安全判断是否为武器**（非武器也能调用，不会报错） |
| `getScriptItem()` | `InventoryItem` | 取脚本对象 |
| `isRanged()` | 脚本 `Item` | 是否为远程武器 |

---

### 12.4 相关事件与钩子

事件签名的**权威来源**是 [PZEventStubs](https://github.com/demiurgeQuantified/PZEventStubs)（社区维护的全部事件类型存根），比翻论坛可靠。

```lua
-- 按下换弹键（玩家手上有枪时）
Events.OnPressReloadButton.Add(function(player, weapon) end)
--   player : IsoPlayer    weapon : HandWeapon

-- 按下上膛（拉栓）键
Events.OnPressRackButton.Add(function(player, weapon) end)

-- 每 tick 更新玩家
Events.OnPlayerUpdate.Add(function(player) end)
--   player : IsoPlayer    ← 确认会传参

-- 开始挥击武器（远程武器开火也会触发）
Events.OnWeaponSwing.Add(function(attacker, weapon) end)
--   attacker : IsoPlayer    weapon : HandWeapon

-- 攻击动作结束
Events.OnPlayerAttackFinished.Add(function(player, weapon) end)

-- 命中僵尸
Events.OnHitZombie.Add(function(zombie, attacker, bodyPart, weapon) end)
```

钩子：

```lua
Hook.WeaponSwing.Add(function(character, weapon) end)   -- 挥击时寻找目标
Hook.Attack.Add(function(attacker, chargeDelta, weapon) end)
```

⚠️ **没有专门的"开火"或"换弹开始"钩子**——只能用上面这些近似事件。

---

### 12.5 如何安全判断"手持物是枪"

`isAimedFirearm()` 是 `HandWeapon` 的方法，对非武器物品调用会出错。安全写法：

```lua
local function isRangedWeapon(item)
    if not item then return false end
    if not item:IsWeapon() then return false end       -- InventoryItem 上，安全
    local script = item:getScriptItem()
    if not script then return false end
    return script:isRanged()
end
```

---

### 12.6 无限弹药：四条实现路径

| 方案 | 做法 | 优点 | 风险 |
|:---|:---|:---|:---|
| **1. 运行时补弹** | 节流调用 `setCurrentAmmoCount(getMaxAmmo())` | API 全部核实；**任意枪械通用**；不需要新物品、不需要子弹 | 弹匣枪需按 `usesExternalMagazine()` 分支；联机下弹药是服务端权威 |
| **2. 新枪 + 大弹容** | 新建枪械物品，`MaxAmmo` 设大 + `JamGunChance = 0`，再配 Lua 补弹 | 可自定义外观与数值 | **需要原版枪械定义**——和武士刀那次同样的困境 |
| **3. 拦截换弹** | 在 `OnPressReloadButton` 里直接补满，跳过原版消耗流程 | 符合直觉：按 R 就满弹 | 需确认事件触发时机是否早于换弹动作，以及能否取消原动作 |
| **4. `setAmmoPerShoot(0)`** | 每发消耗 0 颗弹药 | 最优雅——一次性设置，无需循环 | **未验证**：引擎是否接受 0；可能破坏换弹判定 |

#### 方案 1 的参考实现骨架

```lua
local TICK_INTERVAL = 30   -- 约每 0.5 秒

local function topUp(weapon)
    if not weapon or not weapon:IsWeapon() then return end
    local script = weapon:getScriptItem()
    if not script or not script:isRanged() then return end

    if weapon:usesExternalMagazine() then
        -- 弹匣模式：需要处理弹匣物品上的弹药（见 12.7 未验证事项 1）
        return
    end

    local maxAmmo = weapon:getMaxAmmo()
    if maxAmmo and maxAmmo > 0 and weapon:getCurrentAmmoCount() < maxAmmo then
        weapon:setCurrentAmmoCount(maxAmmo)
    end
    if weapon:haveChamber() and not weapon:isRoundChambered() then
        weapon:setRoundChambered(true)
    end
end

local tick = 0
Events.OnPlayerUpdate.Add(function(player)
    tick = tick + 1
    if tick % TICK_INTERVAL ~= 0 then return end
    topUp(player:getPrimaryHandItem())
    topUp(player:getSecondaryHandItem())
end)
```

> **未实测**：以上是按已核实 API 编写的骨架，**没有在游戏里跑过**（开发机无游戏）。见 12.7。

---

### 12.7 未验证事项

诚实标注，避免你按"已知事实"去用：

1. **弹匣枪的弹药究竟存在哪个对象上** —— `getCurrentAmmoCount()` 对"枪"和"弹匣物品"的语义是否不同，未验证。方案 1 对弹匣枪必须另行处理
2. **`setAmmoPerShoot(0)` 是否被引擎接受** —— 若接受，方案 4 是最干净的解法；若被拒绝或破坏换弹逻辑，则不可用
3. **`OnPressReloadButton` 的触发时机** —— 是否早于原版换弹动作开始（决定方案 3 能否拦截）
4. **`getMaxAmmo()` 对逐发装填的枪是否返回脚本里的 `MaxAmmo`** —— 属合理推断，未验证
5. **联机下弹药是否服务端权威** —— 单机不受影响
6. 本章所有内容**未经真机运行验证**

---

### 12.8 本章资料来源

- [PZ API Documentation — item 脚本块（42.20.4）](https://pz-wiki-modding.github.io/PZ-API-Docs/scripts/item.html) —— 脚本参数与官方说明
- [PZ 官方 Javadoc](https://projectzomboid.com/modding/) —— `HandWeapon`、`InventoryItem`、`IsoGameCharacter`、`Item` 的方法存在性核实
- [demiurgeQuantified/PZEventStubs](https://github.com/demiurgeQuantified/PZEventStubs) —— 全部事件/钩子的类型签名
- [asledgehammer/Umbrella](https://github.com/asledgehammer/Umbrella) —— PZ modding 框架，带 EmmyLua 类型定义

---

## 13. 大型 mod 工程结构

前面 12 章讲的是「怎么写一个 mod」，这一章讲「怎么把一个 mod 写成工程」。

> **素材来源**：对一个 B42 大型机制 mod（84 个 Lua 文件 / 2.6 万行，含自建 UI、自建网络协议、带版本迁移的存档）的完整通读。**下列模式都是它的真实做法**，但代码示例是为本章重写的最小骨架，不含其源码。该样本未入库（见 [CREDITS](../CREDITS.md) 的第三方说明）。

### 13.1 什么时候需要这一章

| 你的 mod | 需不需要 |
|:---|:---|
| 纯脚本物品 / 配方 | ❌ 一个 `.txt` 就够了 |
| 单文件 Lua 机制改写（挂几个 Events） | ❌ 几百行以内别上架构 |
| 带 UI + 持久化存档 | ✅ 从这时开始值得模块化 |
| 还要处理「客户端请求 → 服务端裁决」 | ✅ **必读**，这是最容易写崩的部分 |

### 13.2 模块化：命名空间 + 幂等注册

**一个全局命名空间 + 一个注册函数**，就足以撑起几十个文件：

```lua
-- shared/00_core/00_MyMod.lua   ← 唯一入口，最先加载
MyMod = { VERSION = "1.0", _modules = {} }

function MyMod.register(name)
    if MyMod[name] and MyMod[name]._loaded then return nil end   -- 已加载
    local m = { _loaded = true }
    MyMod[name] = m
    MyMod._modules[name] = true
    return m
end
```

每个业务文件**自己注册、自己防重载**：

```lua
-- shared/MyMod_Foo.lua
require "00_core/00_MyMod"

local Foo = MyMod.register("Foo")
if not Foo then return MyMod.Foo end   -- 已加载过 → 直接返回，避免重复注册事件

-- 你的逻辑，挂到 Foo 上
Foo.something = ...
return Foo
```

**要点**
- `_loaded` 幂等标志是防「事件重复注册导致回调叠加」的关键（§9.3 提过热重载的坑）
- 主入口**显式 `require` 依赖**，不要指望文件名或目录扫描顺序（§7.1：文件名不影响加载顺序）
- 需要全局别名就统一造：`K`（Kahlua 缺失函数补齐）、`L`（日志）、`D`（配置/难度）。**Kahlua 缺 `next()` / `os.*` / `rawget`**，写通用工具函数时要注意

### 13.3 三段目录的分工（含一个致命误解）

`shared` → `client` → `server`（§7.1）。

> ⚠️ **`media/lua/server/` 不是「多人模式专用目录」，单机也会加载它。**
> `[实测]` 那个大型 mod 里有一句守卫 `if isServer() or not isClient() then`——**这个判断只有在单机下才成立**，可见作者是假定 server 目录会被单机加载的；它还把「僵尸掉落材料」「水井补水」「作物加速」这些纯单机机制注册在 server 目录里。
> **推论：为了"只玩单机"而删掉 `server/` 会直接弄坏单机。**

`[实测]` **专用服务器上目录扫描时序不可靠** —— 服务端入口文件应当**显式 `require` 全部依赖**，别依赖自动加载。

### 13.4 环境判定集中到一个文件

`isServer()` / `isClient()` 散落全项目是维护灾难。做法：**只在一个文件里调它们**，其余地方调自己的语义化函数。

```lua
-- SP: (false,false)  server: (true,false)  client: (false,true)
function Env.isSingleplayer()       return not isServer() and not isClient() end
function Env.hasServerAuthority()   return Env.isSingleplayer() or Env.isServer() end
```

`[实测]` **Coop 主机也是两个独立进程**，`(true,true)` 这种组合实际不出现——所以判定用两个布尔就够，不需要第三个状态。

**`hasServerAuthority()` 是本手册最推荐的一个抽象**：单机恒为 `true`，用它写「这段逻辑需要本地权威」比到处写 `if isClient() then ... else ... end` 清楚得多，而且单机/服务端共用同一条代码路径。

### 13.5 存档：`GlobalModData` + 版本迁移链

**全局存档**（跨角色、跨死亡）用 `GlobalModData`，不是玩家身上的 ModData：

```lua
local md = ModData.getOrCreate("MyMod")   -- key 建议等于 mod id
md.Players = md.Players or {}
md.Players[player:getUsername()] = data
```

**三条硬规矩**

1. **显式序列化白名单**：写一个 `Serialize(data)` 只输出你希望进档的字段。别把运行期缓存（容器引用、roomId 列表、临时状态）混进存档——它们会让存档膨胀，还会在版本变化后变成脏数据。
2. **每个存档都带 `dataVersion`**，配一条 **Alembic 式迁移链**（按版本号逐级升）：

```lua
local CURRENT_DATA_VERSION = 3
local MIGRATIONS = {
    [1] = function(d) d.newFieldA = 0; return d end,
    [2] = function(d) d.newFieldB = {}; return d end,
}
-- 读档后：从 d.dataVersion 一路升到 CURRENT_DATA_VERSION，逐级执行
```

3. **每加一个字段 = 加一条迁移 + 抬版本号**。只改结构不加迁移，老档读出来就是 `nil`，表现为「玩家的避难所/存档突然空了」。

> 这是大型 mod 与玩具 mod 最大的工程差距：**存档格式是有版本契约的**。

### 13.6 客户端 ↔ 服务端通信协议

**不要**发明字符串拼接的野路子，做一个最小的协议层：

```lua
-- shared/Config.lua —— 命令常量集中定义，两端共用同一份
COMMAND_NAMESPACE = "MyMod"
COMMANDS = {
    REQUEST_ENTER  = "RequestEnter",     -- C→S
    TELEPORT_TO    = "TeleportTo",       -- S→C
}
```

两端各一张**分发表**：

```lua
-- server 侧
local Handlers = {}
Handlers[COMMANDS.REQUEST_ENTER] = function(player, args) ... end

local function OnClientCommand(module, command, player, args)
    if module ~= COMMAND_NAMESPACE then return end   -- 只认自己的命名空间
    local h = Handlers[command]; if h then h(player, args) end
end
Events.OnClientCommand.Add(OnClientCommand)
```

**必须做对的四件事**

| 事项 | 说明 |
|:---|:---|
| **服务端一律不信客户端** | 客户端发来的坐标、数量、等级全是「请求」，服务端重新校验一遍（`§10` 的思路：不信 + 复查） |
| **幂等 / 防重放** | 用 `transactionId` 或状态门（例如「只在 PENDING 态受理」），否则连点按钮能刷出多份奖励 |
| **限流与鉴权** | 交互类命令做速率限制；管理类命令查 `player:isAccessLevel("admin")` |
| **多步流程要握手** | 跨区块/跨实例的操作**不可能一帧完成**。标准形状：服务端下发目标坐标 → 客户端传送到位后等区块加载 → 回 `ChunksReady` → 服务端再发「生成完成」 |

**SP / MP 双路径**：单机下**别绕道命令协议**（自己发给自己没意义，还会引入时序 bug）。正确做法是 `if hasServerAuthority() then 本地直接跑同一套域逻辑 else 发命令 end`——`[实测]` 那个 mod 的每个交互点都是这个形状，单机路径是一套完整独立的实现。

### 13.7 自定义事件：让 UI 被动响应

`[实测]` PZ 允许往全局 `Events` 表里注册**自己的事件**，这是替代 `OnTick` 轮询的正道：

```lua
LuaEventManager.AddEvent("MyMod_OnInventoryChange")     -- 注册（必须早于监听）
-- 触发
triggerEvent("MyMod_OnInventoryChange", action, item, state)
-- 监听
Events.MyMod_OnInventoryChange.Add(function(action, item, state) ... end)
```

配合**防抖**（间隔内合并多次触发）用来刷新 UI，比每帧轮询干净且省性能。

再进一步：自己包一层生命周期事件，把 SP / Coop / 专用服务器的差异挡在外面：

```lua
MyMod.Events.OnServerReady.Add(fn)   -- 有本地权威时（单机 + 服务端）
MyMod.Events.OnClientReady.Add(fn)   -- 仅客户端
MyMod.Events.OnAnyReady.Add(fn)      -- 全环境
```

### 13.8 从 mod 目录读数据文件 ⚠️ 两个坑

想把配置外置成数据文件（YAML / CSV / 自定义文本）时用：

```lua
local reader = getModFileReader(modId, "media/lua/shared/data.txt", false)
local line = reader:readLine()      -- 循环读到 nil
reader:close()
```

> **坑 1：B42 的 mod id 可能要带反斜杠前缀。**
> `[实测]` 样本代码先试 `"mymod"`，失败再试 `"\mymod"`，并注释说明这是 B42+ 的行为。稳妥做法是**两个都试**。

> **坑 2：mod 不存在时 `getModFileReader` 会抛 Java NPE，`pcall` 抓不住。**
> `[实测]` 样本的做法是**先用 `getModInfoByID()` 校验 mod 存在**，再去开文件——直接 `pcall` 包 `getModFileReader` 挡不住这个异常。

另外：路径是**相对 mod 的（虚拟）根**；PZ **没有内置 YAML/JSON 解析器**——所以要么用 `media/scripts/*.txt` 的声明式块（推荐），要么自己写解析器（那个大型 mod 为了外置升级配置，自带了一个约 600 行的 YAML 解析器 + 物品组展开）。

### 13.9 事务化扣料：防复制，也防丢失

任何「消耗多种材料 → 产出结果」的操作都值得包一层事务：

```
Begin(player, 需求清单)
  ├─ 锁定所需物品（记录清单 journal，跨重连也认得出）
  ├─ 执行（校验 → 扣料 → 生效）
  ├─ 成功 → Finalize（清锁）
  └─ 失败/超时 → Rollback（按清单逆序回填：原容器 → 背包 → 地面）
```

**为什么要逆序回填**：先放回原容器，放不下再退到背包，最后才丢地上——保证**物品不消失**是底线。

**单机也要用**：它防的不只是作弊，更是自己逻辑里的 bug（中途 return、异常、条件分支写错）。

**必须配超时回收**：玩家断线会留下永远锁着的物品（`[实测]` 样本的解法是定时批检 + 自动回滚）。

### 13.10 工程习惯清单

| 习惯 | 解决什么 |
|:---|:---|
| 显式序列化白名单 | 存档可控、不膨胀 |
| 数据版本号 + 迁移链 | 改结构不炸旧档 |
| 分级日志（`logger(tag)`：debug/info/warn/error） | 出问题时能定位，正式时不刷屏 |
| 调试开关走 `getDebug()` | 调试代码不泄漏给玩家 |
| **故意失败的 debug 用例**（例如一个必然失败的升级项） | 能主动测回滚/错误路径，而不是等线上出事 |
| 环境判定集中在 `Env` | 单机/多人分支不散落 |
| 命令常量集中在 `Config` | 两端不会拼错字符串 |
| 客户端/服务端各一个分发器 | 新增交互只改两处 |
| 翻译从第一天就分语言目录 | 后期补翻译成本极低 |

### 13.11 反面清单（大型 mod 上最容易犯）

1. 在 `OnTick` / `OnPlayerUpdate` 里做重活或频繁调 Java API —— 帧率直接崩（§10 第 8 条）
2. 用文件名排序控制加载顺序 —— 不生效，用 `mod.info` 的 `loadModBefore/After` 或显式 `require`
3. 客户端相信自己的物品数量 —— 扣料必须服务端裁决
4. 把运行期缓存写进存档 —— 版本一变就是脏数据
5. 只在能跑通的那条路径上写 try（Lua 是 `pcall`）—— 回滚路径没测过等于没写
6. **为了「只玩单机」删掉 `media/lua/server/`** —— 见 [§13.3](#133-三段目录的分工含一个致命误解)，单机机制就注册在那里

### 13.12 参考实现

本地样本（**未入库**，仅自用）：`third-party/myspatialrefuge-workshop/`（原始工坊包）与其结构化分析 `analysis/myspatialrefuge/`——后者含架构索引、服务端/客户端/配置数据三份详解，以及一份「多人模式与单人的边界」说明。

---

## 附录 A：一键生成模板骨架

在**目标机器**（装了游戏的机器）上，把下面这段存成 `New-PZMod.ps1` 运行，会生成一个结构正确的最小 mod。

```powershell
# 用法: .\New-PZMod.ps1 -ModId "MyMod" -ModName "我的第一个Mod"
param(
    [Parameter(Mandatory=$true)][string]$ModId,
    [Parameter(Mandatory=$true)][string]$ModName
)

$root = Join-Path $env:USERPROFILE "Zomboid\mods\$ModId"
$dirs = @(
    $root,
    "$root\media\scripts",
    "$root\media\lua\client",
    "$root\media\lua\server",
    "$root\media\lua\shared",
    "$root\media\textures"
)
foreach ($d in $dirs) { New-Item -ItemType Directory -Force -Path $d | Out-Null }

# mod.info —— 注意必须叫 mod.info，且用 UTF8 无 BOM 编码
$modInfo = @"
name=$ModName
id=$ModId
description=由模板生成
author=
modversion=0.1
versionMin=42.0
category=features
"@
[System.IO.File]::WriteAllText("$root\mod.info", $modInfo, (New-Object System.Text.UTF8Encoding $false))

# 示例物品 + 配方
$script = @"
module $ModId {
    imports { Base }

    item ${ModId}Knife {
        DisplayName  = $ModName Knife,
        DisplayCategory = Weapon,
        /* B42 语法：ItemType = base:weapon（B41 的 Type = Weapon 已过时）*/
        ItemType     = base:weapon,
        /* Icon 指向 media/textures/<名字>.png（不带扩展名）。
           这里故意留空占位：没有对应贴图时物品会显示缺失图标，属正常现象，
           把自制 png 放进 media/textures/ 并把下面这行改成 Icon = 你的图标名, 即可 */
        Weight       = 1.0,
        MaxDamage    = 1.5,
        SwingTime    = 3,
        ConditionMax = 10,
    }

    craftRecipe Make${ModId}Knife {
        Time = 100,
        Tags = InHandCraft;AnySurfaceCraft,
        category = Miscellaneous,
        inputs {
            item 1 [Base.Twigs] mode:destroy,
            item 1 tags[SharpKnife] mode:keep flags[MayDegradeLight],
        }
        outputs { item 1 ${ModId}.${ModId}Knife, }
    }
}
"@
[System.IO.File]::WriteAllText("$root\media\scripts\${ModId}_items.txt", $script, (New-Object System.Text.UTF8Encoding $false))

# 示例 Lua
$lua = @"
-- media/lua/client/${ModId}_Init.lua
local function onGameStart()
    print("[$ModId] loaded")
end
Events.OnGameStart.Add(onGameStart)
"@
[System.IO.File]::WriteAllText("$root\media\lua\client\${ModId}_Init.lua", $lua, (New-Object System.Text.UTF8Encoding $false))

Write-Host "已生成: $root" -ForegroundColor Green
Get-ChildItem -Recurse $root | Select-Object FullName
```

> **编码提醒**：PZ 读取文件时对 BOM 敏感，脚本里刻意用了 `UTF8Encoding $false`（无 BOM）。如果你手工用记事本另存，请选 **UTF-8（无 BOM）**，否则可能出现文本乱码或 `mod.info` 解析失败。

---

## 附录 B：数据获取与研究设施（实战沉淀）

> 这一节是 2026-09 做 `PristineKatana` mod 时踩出来的完整路径。**下次开新 mod 前先读这里**，能省掉大量重复试错。

### B.1 资料源清单

| 资源 | 能查到什么 | 推荐用法 |
|:---|:---|:---|
| `projectzomboid.com/modding/` | 官方 Javadoc，**Java 侧 API 权威** | 抓 HTML 后正则提方法名（B.3） |
| `projectzomboid.com/blog/` | **实时版本号**（首页 header 有 Stable / Unstable） | 抓首页 |
| `pz-wiki-modding.github.io/PZ-API-Docs/` | **脚本块参数权威**（376 个 item 参数全在这） | 整页下载后本地 grep |
| `demiurgequantified.github.io/ProjectZomboidLuaDocs/` | Lua 侧 API（42.20.3） | 站点搜索 |
| `theindiestone.com/forums/` | 官方论坛。**玩家实测帖价值最高** | 抓 topic 页 |
| GitHub 仓库搜索 + `git clone` | **找原版定义、找成熟 mod 当模板** | `git clone`，见 B.2 手法 ① |
| `demiurgeQuantified/PZEventStubs` | **全部事件/钩子的类型签名**（权威） | `git clone`，见 B.2 手法 ③ |
| `asledgehammer/Umbrella` | PZ modding 框架，带 **EmmyLua 类型定义** | 编辑器里自动补全 / 查方法签名 |
| `m.namu.moe` | 韩语 namu 镜像，PZ 数值详细 | 仅作交叉验证，**非官方** |

### B.2 三条通用手法

**① 找原版定义的最快路径：搜「抄了原版定义的 mod」**

原版 `media/scripts/*.txt` **只存在于游戏安装目录里，网上没有公开副本**（官方 wiki 只收录部分数值，且常滞后于当前版本）。但大量 mod 会把原版条目复制过去改数值——**这些仓库就是原版定义的最佳来源**。

实战案例：要做武士刀 mod，用 GitHub 仓库搜索：

```
zomboid katana mod
```

命中 `micksatana/pz-mod-michonnes-katana`，clone 后直接拿到一份**经实战验证的完整 B42 武士刀定义**：原版网格/贴图/音效事件名、`base:katana` 标签、动画参数、以及 `Contents/mods/<名>/42.15/` 的标准 B42 目录结构。

**搜索词套路**：`<游戏名> <武器/物品名> mod`、`project zomboid weapon mod b42`、`zomboid <机制> mod`。

**② 数据源降级链**（拿不到一手时的优先级）

```
官方 Javadoc / PZ-API-Docs  →  成熟 mod 的脚本原文  →  namu 镜像（标注版本号）  →  论坛实测帖
```

论坛帖的价值常被低估：`-debug` + **Alternate launch** 这个调试开关、B42 工坊目录为什么要套版本目录，都是**只在论坛帖里有**，官方文档没写。

**③ 查事件签名：用 PZEventStubs，别靠猜**

"这个事件回调到底收几个参数、都是什么类型"是写 Lua 最容易出错的地方——写错了游戏里才报错，而且报错信息往往指不到真正的原因。

社区维护了一份**全部事件与钩子的类型签名存根**：

```powershell
git clone --depth 1 https://github.com/demiurgeQuantified/PZEventStubs.git
# 然后在 Events.lua 里搜事件名，能直接看到权威签名，例如：
#   ---@alias Callback_OnPressReloadButton fun(player:IsoPlayer,weapon:HandWeapon)
#   ---@alias Callback_OnWeaponSwing      fun(attacker:IsoPlayer,weapon:HandWeapon)
```

比翻论坛、读反编译都快。想要更完整的编辑器支持就用 `asledgehammer/Umbrella`，它提供 EmmyLua 类型定义，能自动补全并实时查方法签名。

**实战价值**：它能直接纠正猜测。做武士刀 mod 时我不确定 `OnPlayerUpdate` 到底传不传 player，只能写防御性代码；存根里明确写着 `fun(player:IsoPlayer)`，一轮试错就省掉了。

### B.3 查 API 存在性的标准流程 ⚠️ 有个正则坑

写 Lua 前**必须**先确认要调的方法真实存在，否则游戏里才报错。做法：下载 Javadoc 页面，正则提取方法锚点。

**坑**：方法名锚点形如 `id="getSharpness()"`——**带括号**。如果用

```powershell
id="([a-zA-Z0-9_]*[Ss]harp[a-zA-Z0-9_]*)"     # ✗ 错！匹配不到 ()，永远返回 0 个
```

会得出"这个方法不存在"的**错误结论**（我因为这个差点放弃锋利度方案）。必须把括号放进字符类：

```powershell
id="([a-zA-Z0-9_]*[Ss]harp[a-zA-Z0-9_]*\([^"]*\))"   # ✓ 对
```

**可复制脚本**：

```powershell
$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
$dir = Join-Path $env:TEMP "pz-docs"; New-Item -ItemType Directory -Force -Path $dir | Out-Null

function Get-PZClass($rel, $name) {
  $u = "https://projectzomboid.com/modding/$rel"
  $r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 40 -Headers @{"User-Agent"=$ua}
  [System.IO.File]::WriteAllText("$dir\$name.html", $r.Content, [System.Text.Encoding]::UTF8)
  "OK $name ($($r.RawContentLength) bytes)"
}

# 常用类
Get-PZClass "zombie/inventory/InventoryItem.html"        "InventoryItem"
Get-PZClass "zombie/inventory/ItemContainer.html"        "ItemContainer"
Get-PZClass "zombie/characters/IsoGameCharacter.html"    "IsoGameCharacter"
Get-PZClass "zombie/inventory/types/HandWeapon.html"     "HandWeapon"

# 查方法（关键字任意，比如 Sharp / Condition / Add / get）
$h = Get-Content "$dir\InventoryItem.html" -Raw -Encoding UTF8
[regex]::Matches($h, 'id="([a-zA-Z0-9_]*(?:[Ss]harp|[Cc]ondition)[a-zA-Z0-9_]*\([^"]*\))"') |
  ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
```

### B.4 B42 武器耐久是"三层"系统（本次新发现）

这是做"不灭武器"时才挖出来的，**普通教程里没有**：

| 层 | 脚本参数 | Lua 读写 API |
|---|---|---|
| 本体耐久 | `ConditionMax`、`ConditionLowerChanceOneIn` | `getCondition()` / `setConditionNoSound()` / `getConditionMax()` |
| **刃部/头部耐久** | `HeadCondition`、`HeadConditionMax`、`HeadConditionLowerChanceMultiplier` | `hasHeadCondition()` / `getHeadCondition()` / `setHeadCondition()` / `getHeadConditionMax()` |
| **锋利度** | ⚠️ **只有 `Sharpness` 一个参数（设初值/上限），没有任何参数能控制损耗** | `hasSharpness()` / `getSharpness()` / `getMaxSharpness()` / `applyMaxSharpness()` / `reduceSharpness()` / `sharpnessCheck(...)` |

**关键结论**：
- 掉耐久的概率 = `1 / ConditionLowerChanceOneIn`（**值越大越难掉**）
- `HeadConditionLowerChanceMultiplier = 0` 可让刃部永不掉耐久
- **锋利度无法用脚本控制损耗，只能靠 Lua 的 `applyMaxSharpness()` 兜底**。想做"永不钝"的武器，纯脚本方案走不通
- 锋利度取值范围约 `0 ~ 1`（满值 1）

### B.5 新物品 mod 的起手清单

基于做「不灭武士刀」时的那份可用实现（该 mod 现已合并进本地开发工程 `mods/myspatialrefuge/`，**不入库**，本仓库不再分发 mod 源码）：

```
<ModId>/
├── mod.info                     name / id / versionMin=42.0 / category
└── media
    ├── scripts\<ModId>.txt      item 块 + sound 块可以写在同一个文件里
    └── lua
        ├── client\<ModId>.lua   运行时逻辑
        └── shared\Translate\{CN,EN}\ItemName.json
```

**本地开发用扁平结构**（`mod.info` + `media/`），**上传工坊才需要** `Contents/mods/<名>/<build.major>/`。

做新武器时，**优先复用原版资源**，不要从零写：`Icon`、`WeaponSprite`、音效 `event` 都指向原版即可，外观手感立刻正确。

**发放物品给玩家**（"直接给我一个"这类需求）：

```lua
local ITEM_TYPE = "<ModId>.<ItemName>"

local function ensureHasItem(player)
    local inv = player:getInventory()
    if inv:contains(ITEM_TYPE) then return end   -- 已有就不重复发
    inv:AddItem(ITEM_TYPE)
end

Events.OnCreatePlayer.Add(function(_num, player) ensureHasItem(player) end)
Events.OnGameStart.Add(function()
    for i = 0, 3 do
        local p = getSpecificPlayer(i)
        if p then ensureHasItem(p) end
    end
end)
```

`ItemContainer` 常用方法（已核实存在）：`AddItem(String)`、`contains(String)`、`containsType(String)`、`getItems()`、`getAllType(String)`。

> **别手写递归翻背包**：引擎自带 `getFirstTypeRecurse(String)` / `getAllTypeRecurse(String)`，会**递归搜索背包内的子容器**（包括背包里的背包）。手写递归不仅多余，还容易漏掉手持物品的情况。判断"玩家身上有没有某物品"用
> ```lua
> local has = player:getInventory():getFirstTypeRecurse("ModId.ItemName") ~= nil
> ```
> 如果物品可能被拿在手上，还要另外检查 `getPrimaryHandItem()` / `getSecondaryHandItem()`。

### B.6 运行时改脚本参数：`DoParam()`

比"软覆盖"更可控的替代方案——**在 Lua 里直接改已加载的脚本参数**：

```lua
local item = ScriptManager.instance:getItem("Base.Katana")
item:DoParam("ConditionMax = 999999")
item:DoParam("ConditionLowerChanceOneIn = 1000000")
```

出处：`micksatana/pz-mod-michonnes-katana` 的 `media/lua/client/OnGameBoot_Michonne.lua`（用于和鞘类 mod 联动改 `AttachmentType`）。

**用途**：改原版物品数值而**不需要复制整段定义**，也不必赌软覆盖语义。缺点是全局生效、且是运行时才改，脚本工具看不到。

---

## 待确认 / 未验证事项

诚实标注我**没有**完全核实的地方，避免你踩坑时误判：

### 已解决（2026-09 通过实证）

| 原疑问 | 结论 | 证据 |
|---|---|---|
| 翻译文件是 `.json` 还是 `.txt`？ | **`.json`**，放 `media/lua/shared/Translate/<语言码>/` | 实战 mod `micksatana/pz-mod-michonnes-katana` 的 `42.15/media/lua/shared/Translate/CN/ItemName.json` |
| 简体中文语言码是 `CN` 吗？ | **是**，目录名 `Translate/CN/` | 同上 |
| 工坊结构是 `Contents/mods/<名>/<版本>/` 吗？ | **是**，且 `<版本>/mod.info` 必需 | 同上仓库的 `Contents/mods/MichonnesKatana/{42,42.15,common}/` |
| B42 物品脚本语法变了吗？ | **变了**：`ItemType = base:weapon`、`Tags = base:xxx;base:yyy`（命名空间化） | 同上仓库的 `items_Michonne.txt` |
| 能否只写部分字段覆盖原版物品？ | **不确定**，`Soft Override : True` 官方无解释；但有更可靠的替代——运行时 `DoParam()`，见附录 B.6 | — |
| **版本目录名可以是 `42.14` 这种 minor 精度吗？** | **可以**。目录名就是版本号，三种形态都实测过：`42/`（泛）、`42.15/`、`42.14/` | 两个工坊 mod 样本：`micksatana/pz-mod-michonnes-katana` 用 `42/`+`42.15/` 且 **mod.info 里完全不写 `versionMin`**；另一 B42 大型 mod 用 `42.14/`（`versionMin=42.14` + `versionMax=42.14`）+`42.15/`（只写 `versionMin`） |
| **`tiledef` 的 ID 在两个版本目录里要一样吗？** | **不一样，要各写一个** | 同一 mod 的 `42.14/mod.info` = `tiledef=myspatialrefuge 13232`，`42.15/mod.info` = `... 5933` |

### 仍未验证

1. **`versionMin` / `versionMax` 不写会怎样** —— 样本 `micksatana` 两个版本目录都没写，游戏显然正常加载；所以这组字段是"可选覆盖"而非"必需"，但**确切语义（是门控还是仅提示）未实测**
2. **软覆盖（Soft Override）的确切语义** —— 建议避开，改用 `DoParam()` 或复制整段定义
3. Lua 热重载的确切边界 —— 调试模式下的重载能力未实测
4. **本手册内容与开发工程里的脚本均未在真机验证过**（编写环境未安装游戏）。文件编码、括号配平、Lua 块结构（`end` = `function`+`if`+`for`）已静态校验，但**运行时行为只有游戏里能确认**
5. 原版 `Base.Katana` 的**完整脚本原文**始终没拿到（原版脚本不公开）。手册里的武士刀数值来自 42.20.2 的第三方数据源 + 成熟 mod 的结构参数，属**高可信但非原版逐字**

---

## 附录 C：参考资料

**官方**
- [PZ 官方 Javadoc（Java API）](https://projectzomboid.com/modding/)
- [PZ 官网 / 版本状态](https://projectzomboid.com/blog/)
- [B42.20 发布公告](https://projectzomboid.com/blog/news/2026/07/project-zomboid-build-42-20-released/)
- [Modding Policy（法务，商用前必读）](https://projectzomboid.com/blog/modding-policy/)
- [The Indie Stone 官方论坛](https://theindiestone.com/forums/)

**社区文档（42.20.x 对齐）**
- [PZ API Docs — 脚本块](https://pz-wiki-modding.github.io/PZ-API-Docs/)（craftRecipe / item / mod.info / 翻译 / 特质）
- [PZ Lua Docs](https://demiurgequantified.github.io/ProjectZomboidLuaDocs/)
- [PZ Java Docs（另一个镜像）](https://albion.codeberg.page/PZ-JavaDocs/)

**社区指南**
- [FWolfe/Zomboid-Modding-Guide](https://github.com/FWolfe/Zomboid-Modding-Guide)（459★，B41 为主）
- [demiurgeQuantified/PZ-events-guide](https://github.com/demiurgeQuantified/PZ-events-guide)（Events / Hook 清单）
- [LabX1/ProjectZomboid-Build42-ModTemplate](https://github.com/LabX1/ProjectZomboid-Build42-ModTemplate)（B42 结构 + UI mod 实例）
- [SimKDT/Zomboid-Forge-B42](https://github.com/SimKDT/Zomboid-Forge-B42)（自定义僵尸类型框架）
- [micksatana/pz-mod-michonnes-katana](https://github.com/micksatana/pz-mod-michonnes-katana)（**B42 武器定义的最佳参照物**，见附录 B.2）
- [PZ Wiki](https://pzwiki.net/wiki/Modding)（内容最全的第一站）
