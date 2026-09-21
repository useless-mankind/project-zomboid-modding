# Project Zomboid Modding · 手册与示例 mod

Project Zomboid（僵尸毁灭工程）Build 42 的 mod 开发资料与一个可直接使用的示例 mod。

> 全部内容基于 **Build 42.20.x**（B42 于 2026-07-29 转入 Stable 分支）整理，2026-09。

---

## 仓库结构

```
pz-modding/
├── docs/          中文速查手册（拆分版，12 篇）—— 唯一事实源
├── handbook/      同一份手册的单文件完整版（由 tools/ 脚本生成）
├── mods/          自己的 mod 源码（示例 mod + 本地开发中的派生工程）
├── analysis/      对某个 mod 的整理与分析文档（入库）
├── reference/     自己的资料整理（入库）
├── tools/         维护脚本
├── dist/          打包产物（不入库）
├── .research/     资料缓存（不入库）
└── third-party/   第三方 mod 原始样本（不入库，见下）
```

> **为什么 `third-party/` 与 `mods/myspatialrefuge/` 不入库**：那里放的是**别人的 mod**（原始包与基于它的派生开发）。官方 [Modding Policy](https://projectzomboid.com/blog/modding-policy/) 第 4.1 条：自己研究修改可以，但**未经作者许可不得提交不属于自己的作品**。所以这两处只留在本地。
>
> 派生工程 `mods/myspatialrefuge/` 内部**自带一个独立的本地 git 仓库**（不推远端），用它做本地版本历史与回滚，弥补被 `.gitignore` 排除后没有版本控制的问题。

### 📘 `docs/` — 中文速查手册（拆分版）

面向中文 modder 的 B42 开发手册，12 篇。**以官方 Javadoc 与社区自动生成的 API 文档为准**，刻意避开了网上大量仍是 B41 时代的二手教程。

重点内容：

- **B42 的破坏性变更**：`recipe` → `craftRecipe`、单层耐久 → 三层耐久、`.txt` 翻译 → `.json`、工坊目录分层
- **`craftRecipe` 完整语法**：`inputs` / `outputs` / `mode:keep` / `tags[...]` / `flags[...]`
- **枪械与弹药系统**：两种装填模式、枪械参数、弹药 API，以及"无限弹药"的四条实现路径
- **调试流程**：`-debug` + Alternate launch、`console.txt` 定位报错
- **踩坑清单**：10 条新手最常卡住的地方
- **附录 B（数据获取方法论）**：原版脚本不公开，怎么把数据搞到手——资料源清单、找原版定义的手法、查 API 是否存在的流程

👉 **[进入手册目录](docs/README.md)**

### 📖 `handbook/` — 单文件完整版

同样的内容合成一个文件，方便离线阅读与全文搜索。

> **`docs/` 是唯一事实源。** 改完 `docs/` 后运行 `tools/sync-handbook.ps1` 重新生成单文件版，**不要直接编辑 `handbook/` 里的文件**——下次同步会被覆盖。

### 🔧 `tools/` — 维护脚本

| 脚本 | 用途 |
|:---|:---|
| `sync-handbook.ps1` | 从 `docs/` 重建 `handbook/` 单文件版 |
| `deploy-mod.ps1` | 把 `mods/<名>/` 部署到 `Zomboid\mods\`（拷贝或目录联结），供游戏内实测 |

> Windows PowerShell 5.1 读取**无 BOM** 的 `.ps1` 会按 ANSI 解码，脚本里的中文会变乱码。本目录的脚本均已保存为 **UTF-8 with BOM**，修改时请保持。

### 🔪 `mods/` — 可用的 mod

| mod | 说明 |
|:---|:---|
| [`PristineKatana`](mods/PristineKatana) | **不灭武士刀**：永不掉耐久、永不掉锋利度，进游戏自动发放 |
| [`InfiniteAxe`](mods/InfiniteAxe) | **无限斧头**：同一思路的斧头版，由 B41 旧版迁移到 B42 语法 |

两个 mod 都演示了同一套模式：**复用原版贴图与音效 + 脚本锁死耐久参数 + Lua 补锋利度**。

`InfiniteAxe` 的 [README](mods/InfiniteAxe/README.md) 里有一张 **B41 → B42 迁移对照表**（`Type` → `ItemType`、标签命名空间化、翻译 `.json` 化等），可以直接当迁移清单用。

### 🧪 `mods/myspatialrefuge/` — 本地开发工程（不入库）

以第三方 mod **My Spatial Refuge** 为基础继续开发的工程，**本地自用、不发布**。

- **扁平开发结构**：`mod.info` + `media/`（本地开发用这个，只有上传工坊才需要 `Contents/mods/<名>/<build.major>/` 那层壳）
- **单一目标版本**：B42.15 及以上，翻译用 `.json`（已丢弃 42.14 的 `.txt` 那套）
- **可直接部署**：`tools/deploy-mod.ps1` 一条命令拷进 `Zomboid\mods\`
- **原始工坊包快照**保留在 `third-party/myspatialrefuge-workshop/`（只读），用于 diff 与回滚
- 内部脚本改动记录、目标版本、多人模式说明见该目录下的 `FORK-NOTES.md`

> ⚠️ 这个目录在 `.gitignore` 里，**外层仓库不管它**；它自带一个独立的本地 git 仓库，`cd mods/myspatialrefuge && git log` 查看改动历史。

### 🔍 `analysis/` — mod 分析文档

对某个 mod 的完整整理（架构、数据模型、扩展点、已知问题），每个 mod 一个子目录。**不含任何第三方源码，只有我方的描述与行号引用**，因此入库；原样本本身仍留在 `third-party/`。

当前：[`analysis/myspatialrefuge/`](analysis/myspatialrefuge) —— My Spatial Refuge 的现状整理 + 服务端/客户端/配置数据三份子系统详解 + 多人模式边界说明。

### 📚 `reference/` — 自己的资料整理

物品 ID 参考表、轻量武器对比等，来源已在文内标注。

### 🔪 `mods/PristineKatana/` — 不灭武士刀

一个完整可用的 B42 mod，添加一把**永不掉耐久、永不掉锋利度**的武士刀，进游戏时若背包里没有会自动发放一把。

它同时是一份**可参照的实现范例**，演示了：

| 演示点 | 说明 |
|:---|:---|
| 复用原版资源 | `Icon` / `WeaponSprite` / 音效 `event` 全部指向原版武士刀，**不新增任何贴图模型** |
| B42 物品语法 | `ItemType = base:weapon`、命名空间化的 `Tags = base:katana;...` |
| 三层耐久控制 | `Condition*` / `HeadCondition*` / `Sharpness` |
| 脚本做不到的部分用 Lua 兜底 | **锋利度没有任何脚本参数能控制损耗**，只能用 `applyMaxSharpness()` |
| 发放物品给玩家 | `ItemContainer:AddItem()` + 递归查背包，幂等 |
| 中文翻译 | `media/lua/shared/Translate/CN/ItemName.json` |

---

## 安装 PristineKatana

1. 把 `mods/PristineKatana/` 整个文件夹复制到：

   ```
   C:\Users\<你的用户名>\Zomboid\mods\
   ```

   复制后路径应为 `...\Zomboid\mods\PristineKatana\mod.info`

2. 启动游戏 → 主菜单 **Mods** → 勾选 **Pristine Katana**

3. 读档进入游戏。若背包里没有这把刀，会**自动获得一把**。

**验证是否加载成功**：查看 `C:\Users\<你>\Zomboid\console.txt`，应出现

```
[PristineKatana] loaded - 不灭武士刀已加载
```

---

## 两项重要声明

### ⚠️ 未经真机验证

手册与 mod 均**尚未在真实游戏中运行验证**。已完成静态校验：

- 文件编码 UTF-8 无 BOM（PZ 对 BOM 敏感）
- 脚本花括号配平、Lua 块结构配平（`end` = `function` + `if` + `for`）
- 调用的每个 API 均在官方 Javadoc 中确认存在

但**运行时行为只有游戏里能确认**。如果出问题，`console.txt` 里的报错是最有价值的线索。

### 📄 不含游戏素材

本仓库**不包含 Project Zomboid 的任何美术、音频或数据文件**。`PristineKatana` 只是在脚本中*按名称引用*原版贴图与音效事件，游戏运行时会从玩家自己的安装中读取。

Project Zomboid 及其全部内容版权归 The Indie Stone 所有。本项目为非官方粉丝作品，与 The Indie Stone 无关联。

第三方来源与授权详见 **[CREDITS.md](CREDITS.md)**。

---

## 授权

[MIT](LICENSE)（`mods/PristineKatana` 派生自同为 MIT 协议的第三方 mod，其版权声明见 [CREDITS.md](CREDITS.md)）
