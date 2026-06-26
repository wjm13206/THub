local tpWalk = {}

local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Workspace = cloneref(game:GetService("Workspace"))

local player = Players.LocalPlayer

local teleportDistance = 0.1
local isTeleporting = false

-- 保存连接
local connections = {}

-- 安全获取当前有效角色及其核心部件的函数
local function getCharacterParts()
    local char = player.Character
    if not char then
        return nil, nil, nil
    end

    if not char.Parent then
        return nil, nil, nil
    end

    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if not hum or not hrp then
        return nil, nil, nil
    end

    return char, hum, hrp
end

-- 禁用所有与移动相关的状态
local function DisableDefaultMovement(humanoid)
    if not humanoid then return end
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
end

-- 启用所有与移动相关的状态
local function EnableDefaultMovement(humanoid)
    if not humanoid then return end
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, true)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
end

-- 自定义传送函数
local function Teleport()
    if not isTeleporting then
        return
    end

    local character, humanoid, rootPart = getCharacterParts()
    
    if not character or not humanoid or not rootPart then
        return
    end

    local moveDirection = humanoid.MoveDirection
    if moveDirection.Magnitude == 0 then
        return
    end

    local teleportVector = moveDirection * teleportDistance

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local raycastResult = Workspace:Raycast(rootPart.Position, teleportVector, raycastParams)

    if raycastResult then
        teleportVector = (raycastResult.Position - rootPart.Position).Unit * teleportDistance
    end

    rootPart.CFrame = rootPart.CFrame + teleportVector
end

-- 控制开关函数
function tpWalk:Enabled(enabled)
    isTeleporting = enabled
    
    local _, humanoid = getCharacterParts()
    
    if enabled then
        DisableDefaultMovement(humanoid)
    else
        EnableDefaultMovement(humanoid)
    end
end

function tpWalk:GetEnabled()
    return isTeleporting
end

function tpWalk:SetSpeed(speed)
    teleportDistance = speed or 0.1
end

function tpWalk:GetSpeed()
    return teleportDistance
end

-- 每帧更新传送（保存连接）
local heartbeatConn = RunService.Heartbeat:Connect(function()
    if isTeleporting then
        Teleport()
    end
end)
table.insert(connections, heartbeatConn)

-- 卸载函数
function tpWalk:unload()
    -- 先关闭传送
    if isTeleporting then
        local _, humanoid = getCharacterParts()
        EnableDefaultMovement(humanoid)
        isTeleporting = false
    end

    -- 断开所有连接
    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
    connections = {}

    -- 清空模块表（可选）
    for k in pairs(tpWalk) do
        tpWalk[k] = nil
    end
end

return tpWalk