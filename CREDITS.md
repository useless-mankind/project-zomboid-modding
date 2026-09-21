# 第三方来源与授权 / Credits & Third-Party Notices

> **公开仓库现状（2026-09-21 起）**：本仓库**不再包含任何 mod 源码**，只含手册、文档与我方撰写的分析。原先随仓库分发的示例 mod `PristineKatana` 与 `InfiniteAxe` 已删除。
> 下面 §1 的声明**继续保留**，因为派生代码仍存在于**本地未入库**的开发工程 `mods/myspatialrefuge/`（不随本仓库发布），依 MIT 协议该声明必须随之保留。

---

## 1. 代码派生来源（MIT，必须保留声明）

`mods/myspatialrefuge/media/scripts/PristineKatana.txt`（本地开发工程，**不入库**；原为 `mods/PristineKatana/`，2026-09-21 合并后删除）中的物品定义，其**参数结构与资源引用方式**派生自以下项目：

- **项目**：[micksatana/pz-mod-michonnes-katana](https://github.com/micksatana/pz-mod-michonnes-katana)（Michonne's Katana）
- **作者**：Satana Charuwichitratana
- **授权**：MIT License

依据 MIT 协议，其许可原文如下：

```
MIT License

Copyright (c) 2022 Satana Charuwichitratana

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

**说明**：本项目对该定义做了实质修改——重命名模块与物品、改用原版武士刀的图标/贴图/音效引用、按 42.20.x 数值设定攻击参数、并把耐久与锋利度改为不会衰减。原项目的作者与授权信息在此明确致谢并保留。

---

## 2. 资料与数据来源

`docs/` 下的手册内容综合自以下来源，均为**引用与转述**而非复制：

### 官方（The Indie Stone）

- [PZ 官方 Javadoc（Java API）](https://projectzomboid.com/modding/)
- [PZ 官网 / 版本状态](https://projectzomboid.com/blog/)
- [Modding Policy（mod 政策）](https://projectzomboid.com/blog/modding-policy/)
- [The Indie Stone 官方论坛](https://theindiestone.com/forums/)

### 社区文档

- [PZ API Documentation（脚本块参数，42.20.4）](https://pz-wiki-modding.github.io/PZ-API-Docs/) — PZ-Wiki-Modding 组织，由 `pz-scripts-data` 等数据集自动生成
- [Project Zomboid Lua Docs](https://demiurgequantified.github.io/ProjectZomboidLuaDocs/) — demiurgeQuantified
- [PZ Java Docs 镜像](https://albion.codeberg.page/PZ-JavaDocs/) — albion

### 社区指南

- [FWolfe/Zomboid-Modding-Guide](https://github.com/FWolfe/Zomboid-Modding-Guide) — 脚本块语法
- [demiurgeQuantified/PZ-events-guide](https://github.com/demiurgeQuantified/PZ-events-guide) — Events / Hook 清单
- [LabX1/ProjectZomboid-Build42-ModTemplate](https://github.com/LabX1/ProjectZomboid-Build42-ModTemplate) — B42 目录结构
- [SimKDT/Zomboid-Forge-B42](https://github.com/SimKDT/Zomboid-Forge-B42) — 僵尸类型数据（ZType 七项属性表）
- [m.namu.moe](https://m.namu.moe/) — 长刀武器数值交叉验证（该页标注 42.20.2）

### 数据可信度提示

手册中**武器数值**（攻击力、暴击、耐久等）来自上列社区来源，**不是**从游戏原版脚本逐字提取的——原版 `media/scripts/*.txt` 无法公开获取。这些数值属"高可信但非原版逐字"，详见手册中的「待确认 / 未验证事项」。

---

## 3. Project Zomboid 版权声明

**Project Zomboid** 及其全部内容（含代码、美术、音频、文本、商标）版权归 **The Indie Stone** 所有。

本仓库：

- **不包含** Project Zomboid 的任何游戏素材文件
- 仅在脚本中**按名称引用**原版贴图与音效事件，运行时由玩家自己的游戏安装提供
- 是非官方粉丝作品，与 The Indie Stone 无任何关联，未获其背书

使用本项目的 mod 需要玩家自行合法拥有 Project Zomboid。
