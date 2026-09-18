--[[--------------------------------------------------------------------------
    Pristine Katana - 不灭武士刀（客户端逻辑）

    做两件事：
      1. 开档/进游戏时，如果玩家身上没有这把刀，就发一把
      2. 使用过程中持续把耐久、刃部耐久、锋利度推回满值

    说明：脚本里已经把耐久参数设成实际不可能下降的数值，
    这里的 Lua 是第二道保险（同时也是唯一能锁住"锋利度"的手段，
    因为锋利度没有对应的脚本参数）。
--------------------------------------------------------------------------]]

local ITEM_TYPE     = "PristineKatana.PristineKatana"
local TICK_INTERVAL = 30   -- 约每 0.5 秒检查一次手持武器

-- 递归检查容器（含背包内的背包）里是否已有该物品
local function containerHasItem(container, fullType)
    if not container then return false end
    if container:contains(fullType) then return true end

    local items = container:getItems()
    if not items then return false end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            local sub = item:getContainer()
            if sub and containerHasItem(sub, fullType) then return true end
        end
    end
    return false
end

-- 把一件武器恢复成全新状态
local function makePristine(item)
    if not item or item:getFullType() ~= ITEM_TYPE then return end

    -- 刃部耐久
    if item:hasHeadCondition() then
        local headMax = item:getHeadConditionMax()
        if item:getHeadCondition() < headMax then
            item:setHeadCondition(headMax)
        end
    end

    -- 本体耐久
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
local function ensureHasKatana(player)
    if not player then return end
    local inv = player:getInventory()
    if not inv then return end

    if not containerHasItem(inv, ITEM_TYPE) then
        local item = inv:AddItem(ITEM_TYPE)
        if item then
            makePristine(item)
        end
    end
end

-- 进游戏时补发（读档同样会触发）
local function onGameStart()
    for i = 0, 3 do
        local player = getSpecificPlayer(i)
        if player then ensureHasKatana(player) end
    end
end

-- 新角色创建时补发
local function onCreatePlayer(_playerNum, player)
    ensureHasKatana(player)
end

-- 持续维持满状态，只检查双手（耐久与锋利度只在持用时才会下降）
local tickCounter = 0
local function onPlayerUpdate(player)
    tickCounter = tickCounter + 1
    if tickCounter % TICK_INTERVAL ~= 0 then return end

    -- 不同版本的 OnPlayerUpdate 回调参数不完全一致，这里做双保险
    if not player then player = getSpecificPlayer(0) end
    if not player then return end

    makePristine(player:getPrimaryHandItem())
    makePristine(player:getSecondaryHandItem())
end

Events.OnGameStart.Add(onGameStart)
Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnPlayerUpdate.Add(onPlayerUpdate)

print("[PristineKatana] loaded - 不灭武士刀已加载")
