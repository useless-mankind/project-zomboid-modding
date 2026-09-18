# InfiniteAxe MOD 技术文档

## 1. 概述

**MOD名称**: InfiniteAxe  
**功能**: 提供一把无限耐久、永不变钝的魔法斧头  
**版本**: V1.0  
**适用游戏**: Project Zomboid Build 42+  

## 2. 文件结构

```
InfiniteAxeMod/
  mod.info                              -- MOD 元信息
  media/
    scripts/
      items_InfiniteAxe.txt             -- 物品脚本定义
    lua/
      client/
        InfiniteAxe_Client.lua          -- 客户端脚本（自动发放+耐久维护）
      shared/
        Translate/
          CN/UI_CN.txt                  -- 简体中文翻译
          EN/UI_EN.txt                  -- 英文翻译
```

## 3. 物品定义 (items_InfiniteAxe.txt)

| 属性 | 值 | 说明 |
|:---|:---:|:---|
| Type | Weapon | 武器类型 |
| SubCategory | Axe | 斧头子类 |
| Weight | 2.0 | 重量 |
| MinDamage | 1.5 | 最小伤害（原版手斧 0.7） |
| MaxDamage | 3.0 | 最大伤害（原版手斧 1.5） |
| BaseSpeed | 1.0 | 攻击速度 |
| CriticalChance | 25 | 暴击率 25%（原版 15%） |
| CritDmgMultiplier | 5 | 暴击倍率 5x |
| ConditionMax | 999999 | 最大耐久（几乎无限） |
| ConditionLowerChanceOneIn | 999999 | 降级概率 1/999999（几乎不降） |
| TreeDamage | 35 | 砍树伤害（原版 15） |
| DoorDamage | 40 | 破门伤害 |
| TwoHandWeapon | FALSE | 单手持握 |

### 与原版手斧对比

| 属性 | 原版手斧 | InfiniteAxe |
|:---|:---:|:---:|
| 最小伤害 | 0.7 | 1.5 |
| 最大伤害 | 1.5 | 3.0 |
| 暴击率 | 15% | 25% |
| 最大耐久 | 15 | 999999 |
| 降级概率 | 1/10 | 1/999999 |
| 砍树伤害 | 15 | 35 |

## 4. 客户端脚本 (InfiniteAxe_Client.lua)

### 核心逻辑

1. **findInfiniteAxe(player)**: 搜索玩家身上的无限斧头
   - 搜索顺序：背包（含子容器）→ 主手 → 副手
   - 确保不会因为手持时检测不到而重复添加

2. **ensureInfiniteAxe(player)**: 确保玩家拥有一把
   - 没有 → 自动添加到背包，耐久设为最大
   - 已有 → 补满耐久（如果有损耗）

### 事件注册

| 事件 | 频率 | 作用 |
|:---|:---|:---|
| OnGameStart | 游戏开始时 | 首次添加斧头 |
| EveryTenMinutes | 每10游戏分钟 | 检查+补满耐久 |

## 5. 安装方法

1. 将 `InfiniteAxeMod` 文件夹复制到 `C:\Users\<用户名>\Zomboid\mods\`
2. 启动 PZ → 主菜单 → MODS → 勾选 InfiniteAxe
3. 开始新游戏，斧头自动出现在背包中

## 6. 使用的 PZ API

| API | 类 | 用途 |
|:---|:---|:---|
| `getPlayer()` | 全局 | 获取当前玩家 |
| `player:getInventory()` | IsoPlayer | 获取玩家背包 |
| `inv:getFirstTypeRecurse(type)` | ItemContainer | 递归搜索物品 |
| `inv:AddItem(type)` | ItemContainer | 添加物品 |
| `item:getCondition()` | InventoryItem | 获取当前耐久 |
| `item:getConditionMax()` | InventoryItem | 获取最大耐久 |
| `item:setCondition(val)` | InventoryItem | 设置耐久 |
| `item:getFullType()` | InventoryItem | 获取完整物品类型 |
| `player:getPrimaryHandItem()` | IsoPlayer | 获取主手物品 |
| `player:getSecondaryHandItem()` | IsoPlayer | 获取副手物品 |
| `Events.OnGameStart` | 事件 | 游戏开始事件 |
| `Events.EveryTenMinutes` | 事件 | 每10分钟事件 |
