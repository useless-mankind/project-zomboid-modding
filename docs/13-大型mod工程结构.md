<!-- 《Project Zomboid Mod 开发速查手册》拆分章节，内容与单文件版一致 -->

> :book: [返回总目录](README.md)  ·  适用 **Build 42.20.x**  ·  整理于 2026-09-21

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
- `_loaded` 幂等标志是防「事件重复注册导致回调叠加」的关键（[§9.3](07-调试与发布.md) 提过热重载的坑）
- 主入口**显式 `require` 依赖**，不要指望文件名或目录扫描顺序（[§7.1](05-Lua层-事件与钩子.md)：文件名不影响加载顺序）
- 需要全局别名就统一造：`K`（Kahlua 缺失函数补齐）、`L`（日志）、`D`（配置/难度）。**Kahlua 缺 `next()` / `os.*` / `rawget`**，写通用工具函数时要注意

### 13.3 三段目录的分工（含一个致命误解）

`shared` → `client` → `server`（[§7.1](05-Lua层-事件与钩子.md)）。

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
| **服务端一律不信客户端** | 客户端发来的坐标、数量、等级全是「请求」，服务端重新校验一遍（`[§10](08-踩坑清单.md)` 的思路：不信 + 复查） |
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

1. 在 `OnTick` / `OnPlayerUpdate` 里做重活或频繁调 Java API —— 帧率直接崩（[§10](08-踩坑清单.md) 第 8 条）
2. 用文件名排序控制加载顺序 —— 不生效，用 `mod.info` 的 `loadModBefore/After` 或显式 `require`
3. 客户端相信自己的物品数量 —— 扣料必须服务端裁决
4. 把运行期缓存写进存档 —— 版本一变就是脏数据
5. 只在能跑通的那条路径上写 try（Lua 是 `pcall`）—— 回滚路径没测过等于没写
6. **为了「只玩单机」删掉 `media/lua/server/`** —— 见 [§13.3](#133-三段目录的分工含一个致命误解)，单机机制就注册在那里

### 13.12 参考实现

本地样本（**未入库**，仅自用）：`third-party/myspatialrefuge-workshop/`（原始工坊包）与其结构化分析 `analysis/myspatialrefuge/`——后者含架构索引、服务端/客户端/配置数据三份详解，以及一份「多人模式与单人的边界」说明。

---

> :book: [返回总目录](README.md)
