<!-- 《Project Zomboid Mod 开发速查手册》拆分章节，内容与单文件版一致 -->

> :book: [返回总目录](README.md)  ·  适用 **Build 42.20.x**  ·  整理于 2026-09

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
| 另一 B42 大型机制 mod（见[附录 B](10-数据获取与研究设施.md)） | `42.14/`、`42.15/` | `42.14/` 写 `versionMin=42.14` + **`versionMax=42.14`（锁死）**；`42.15/` 只写 `versionMin=42.15`（不写上限＝向上开放到 42.20+） |

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
| `name` | translation | 显示名（可走翻译，见 [§8](06-翻译.md)） |
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

> :book: [返回总目录](README.md)