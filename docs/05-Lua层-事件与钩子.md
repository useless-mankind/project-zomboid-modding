<!-- 《Project Zomboid Mod 开发速查手册》拆分章节，内容与单文件版一致 -->

> :book: [返回总目录](README.md)  ·  适用 **Build 42.20.x**  ·  整理于 2026-09

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

> :book: [返回总目录](README.md)