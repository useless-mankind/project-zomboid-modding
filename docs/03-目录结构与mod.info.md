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

**版本目录名到底叫 `42` 还是 `42.0`？** 已实证：成熟 mod `micksatana/pz-mod-michonnes-katana` 同时存在 `42/` 和 `42.15/` 两个版本目录，说明**目录名跟随 `build.major`**（`42` 对 `42.0`~`42.14`，`42.15` 对 42.15+）。做本地开发用扁平结构即可，只有上传工坊才需要版本目录。

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
| `versionMin` / `versionMax` | string | 必须是 `build.major` 格式（如 `42.0`）。**只写 `42` 不生效** |
| `require` | string | 前置 mod，逗号分隔 |
| `loadModBefore` / `loadModAfter` | string | 加载顺序控制 |
| `incompatible` | string | 互斥 mod，启用后对方变灰不可选 |
| `pack` | string | 需要加载的 pack 文件（贴图包 / tile 包） |
| `tiledef` | string | 新增 tiledef 及其 ID，例：`tiledef=Excavation 2112`。**ID 会和其他 mod 冲突**，需查社区登记表 |


---

> :book: [返回总目录](README.md)