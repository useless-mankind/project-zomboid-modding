# Project Zomboid Modding · 手册与示例 mod

Project Zomboid（僵尸毁灭工程）Build 42 的 mod 开发资料与一个可直接使用的示例 mod。

> 全部内容基于 **Build 42.20.x**（B42 于 2026-07-29 转入 Stable 分支）整理，2026-09。

---

## 仓库内容

### 📘 `docs/` — 中文速查手册

面向中文 modder 的 B42 开发手册，11 篇。**以官方 Javadoc 与社区自动生成的 API 文档为准**，刻意避开了网上大量仍是 B41 时代的二手教程。

重点内容：

- **B42 的破坏性变更**：`recipe` → `craftRecipe`、单层耐久 → 三层耐久、`.txt` 翻译 → `.json`、工坊目录分层
- **`craftRecipe` 完整语法**：`inputs` / `outputs` / `mode:keep` / `tags[...]` / `flags[...]`
- **调试流程**：`-debug` + Alternate launch、`console.txt` 定位报错
- **踩坑清单**：10 条新手最常卡住的地方
- **附录 B（数据获取方法论）**：本机网络环境下哪些资料源可用、怎么绕行、怎么查 API 是否存在

👉 **[进入手册目录](docs/README.md)**

### 🔪 `mods/PristineKatana/` — 示例 mod：不灭武士刀

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

手册与 mod 均**没有在本机实机运行过**（开发机未安装游戏）。已完成静态校验：

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
