<!-- 《Project Zomboid Mod 开发速查手册》拆分章节，内容与单文件版一致 -->

> :book: [返回总目录](README.md)  ·  适用 **Build 42.20.x**  ·  整理于 2026-09

## 3. Mod 类型全景与选题建议

| 类型 | 难度 | 产出周期 | 门槛 | 说明 |
|---|---|---|---|---|
| 物品 / 武器 / 食物 | ★☆☆☆☆ | 1 小时 | 会写 txt | 纯声明式。真正的门槛是找图标素材 |
| 配方（craftRecipe） | ★★☆☆☆ | 2 小时 | 会写 txt | B42 新语法，见 [§6](04-脚本层-物品与配方.md) |
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
- 学到：Hook vs Event 的区别（见 [§7.3](05-Lua层-事件与钩子.md)）、运行时改 sandbox 参数

**选题 C —「科幻恐怖题材的生存机制」**（难度 ★★★★，贴合你的口味）
- PZ 本身是 90 年代肯塔基丧尸题材，科幻向 mod 有差异化空间
- 可落地方向：辐射区/污染地块（用区域判定 + `EveryTenMinutes` 扣血）、需要维护的动力装甲（耐久 + 资源消耗）、异常天气事件（`zombie.iso.weather` 包）
- 学到：世界区域查询、定时事件、资源系统——这三样是绝大多数大型 mod 的地基

`[社区文档]` `[论坛]`


---

> :book: [返回总目录](README.md)