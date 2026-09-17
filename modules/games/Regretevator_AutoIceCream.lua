--!native
--!optimize 2

local cloneref = cloneref or clonereference or function(obj) return obj end
local Services = setmetatable({}, {
    __index = function(self, name)
        local success, cache = pcall(function()
            return cloneref(game:GetService(name))
        end)
        if success then
            rawset(self, name, cache)
            return cache
        else
            error("无效服务: " .. tostring(name))
        end
    end
})

local Players = Services.Players
local RunService = Services.RunService

local AutoIceCream = {}
local player = Players.LocalPlayer

-- 配置项
local enabled = false
local isUsing = false
local lastUseTime = 0
local useCooldown = 3         -- 使用冷却时间(秒)
local healthThreshold = 0.95  -- 血量阈值(0-1)，低于此比例触发使用
local itemName = "IceCreamCone"

local humanoid = nil
local heartbeatConn = nil
local charConn = nil

-- 核心使用逻辑：叠加持有 -> Activate -> 放回背包
local function useItemOnTopOfCurrent()
    local character = player.Character
    if not character then return end

    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return end

    local targetItem = backpack:FindFirstChild(itemName)
    if not targetItem then return end

    -- 叠加持有
    targetItem.Parent = character

    task.wait(0.1)
    if targetItem:IsA("Tool") then
        targetItem:Activate()
    end

    -- 使用后放回背包
    task.wait(0.5)
    if targetItem and targetItem.Parent == character then
        targetItem.Parent = backpack
    end
end

-- 自动使用判断
local function tryUseIceCream()
    if isUsing then return end
    if not humanoid or not humanoid.Parent then return end

    local now = tick()
    if now - lastUseTime < useCooldown then return end

    local hp = humanoid.Health
    local maxHp = humanoid.MaxHealth
    if maxHp <= 0 then return end
    if hp >= maxHp * healthThreshold then return end

    -- 检查背包里是否有冰淇淋
    local backpack = player:FindFirstChild("Backpack")
    if not backpack or not backpack:FindFirstChild(itemName) then return end

    isUsing = true
    lastUseTime = now

    task.spawn(function()
        pcall(useItemOnTopOfCurrent)
        isUsing = false
    end)
end

-- Heartbeat 轮询检测血量
local function onHeartbeat()
    if not enabled then return end
    if not humanoid or not humanoid.Parent then return end

    local maxHp = humanoid.MaxHealth
    if maxHp <= 0 then return end

    if humanoid.Health < maxHp * healthThreshold then
        tryUseIceCream()
    end
end

local function unbindEvents()
    if heartbeatConn then
        heartbeatConn:Disconnect()
        heartbeatConn = nil
    end
    if charConn then
        charConn:Disconnect()
        charConn = nil
    end
end

local function bindEvents()
    unbindEvents()

    -- 使用 Heartbeat 代替 HealthChanged，每帧主动检测血量
    heartbeatConn = RunService.Heartbeat:Connect(onHeartbeat)

    charConn = player.CharacterAdded:Connect(function(newChar)
        humanoid = newChar:WaitForChild("Humanoid", 5)
        -- Heartbeat 已在运行，无需重新绑定，只需更新 humanoid 引用
    end)
end

function AutoIceCream:enable()
    if enabled then return end
    enabled = true
    local character = player.Character
    if character then
        humanoid = character:FindFirstChildOfClass("Humanoid")
    end
    bindEvents()
end

function AutoIceCream:disable()
    if not enabled then return end
    enabled = false
    isUsing = false
    unbindEvents()
    humanoid = nil
end

function AutoIceCream:unload()
    self:disable()
end

function AutoIceCream:setCooldown(seconds: number)
    useCooldown = seconds
end

function AutoIceCream:setHealthThreshold(ratio: number)
    healthThreshold = math.clamp(ratio, 0, 1)
end

return AutoIceCream