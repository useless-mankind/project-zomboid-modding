--[[--------------------------------------------------------------------------
    Infinite Axe - 无限耐久斧头（客户端逻辑）

    做两件事：
      1. 进游戏时如果玩家身上没有这把斧头，就发一把
      2. 持续把本体耐久、刃部耐久、锋利度推回满值

    脚本里已经把耐久参数设成实际不可能下降的数值，这里的 Lua 是第二道保险，
    同时也是**唯一**能锁住"锋利度"的手段（锋利度没有对应的脚本参数）。
--------------------------------------------------------------------------]]

local ITEM_TYPE     = "InfiniteAxe.InfiniteAxe"
local TICK_INTERVAL = 30   -- 约每 0.5 秒检查一次手持武器

-- 把一件斧头恢复成全新状态
local function makePristine(item)
    if not item or item:getFullType() ~= ITEM_TYPE then return end

    -- 刃部耐久
    if item:hasHeadCondition() then
        local headMax = item:getHeadConditionMax()
        if item:getHeadCondition() < headMax then
            item:setHeadCondition(headMax)
        end
    end

    -- 本体耐久（用 NoSound 变体，避免每次补满都播放修理音效）
    local condMax = item:getConditionMax()
    if item:getCondition() < condMax then
        item:setConditionNoSound(condMax)
    end

    -- 锋利度
    if item:hasSharpness() then
        if item:getSharpness() < item:getMaxSharpness() then
            item:applyMaxSharpness()
        end
    end
end

-- 保证玩家拥有一把，且是全新状态
local function ensureHasAxe(player)
    if not player then return end
    local inv = player:getInventory()
    if not inv then return end

    -- getFirstTypeRecurse 会递归搜索背包内的子容器（引擎自带，无需手写递归）
    local axe = inv:getFirstTypeRecurse(ITEM_TYPE)
    if not axe then
        axe = inv:AddItem(ITEM_TYPE)
        if axe then
            print("[InfiniteAxe] 已发放一把无限斧头")
        end
    end
    makePristine(axe)
end

-- 进游戏时补发（读档同样会触发）
local function onGameStart()
    for i = 0, 3 do
        local player = getSpecificPlayer(i)
        if player then ensureHasAxe(player) end
    end
end

-- 新角色创建时补发
local function onCreatePlayer(_playerNum, player)
    ensureHasAxe(player)
end

-- 持续维持满状态，只检查双手（耐久与锋利度只在持用时才会下降）
local tickCounter = 0
local function onPlayerUpdate(player)
    tickCounter = tickCounter + 1
    if tickCounter % TICK_INTERVAL ~= 0 then return end

    if not player then player = getSpecificPlayer(0) end
    if not player then return end

    makePristine(player:getPrimaryHandItem())
    makePristine(player:getSecondaryHandItem())
end

Events.OnGameStart.Add(onGameStart)
Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnPlayerUpdate.Add(onPlayerUpdate)

print("[InfiniteAxe] loaded - 无限斧头已加载")
