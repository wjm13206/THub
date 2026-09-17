--!native
--!optimize 2
-- TornadoModule.lua
-- 一个纯粹的龙卷风/黑洞效果模块，无GUI，通过API控制

local TornadoModule = {}
TornadoModule.__index = TornadoModule

-- 服务引用
local cloneref = cloneref or clonereference or function(obj) return obj end
local Services = setmetatable({}, { __index = function(self, name) local success, cache = pcall(function() return cloneref(game:GetService(name)) end); if success then rawset(self, name, cache); return cache else error("无效服务: "..tostring(name)) end end})

local Players = Services.Players
local RunService = Services.RunService
local Workspace = Services.Workspace

-- 内部状态
local moduleState = {
    enabled = false,
    config = {
        radius = 50,
        height = 100,
        rotationSpeed = 10,
        attractionStrength = 1000,
    },
    parts = {},
    connections = {},
    localPlayer = nil,
    character = nil,
    humanoidRootPart = nil,
}

-- 获取/设置配置
function TornadoModule.setRadius(self, value)
    moduleState.config.radius = math.clamp(value, 0, 10000)
end

function TornadoModule.getRadius(self)
    return moduleState.config.radius
end

function TornadoModule.setHeight(self, value)
    moduleState.config.height = math.clamp(value, 0, 10000)
end

function TornadoModule.getHeight(self)
    return moduleState.config.height
end

function TornadoModule.setRotationSpeed(self, value)
    moduleState.config.rotationSpeed = math.clamp(value, 0, 10000)
end

function TornadoModule.getRotationSpeed(self)
    return moduleState.config.rotationSpeed
end

function TornadoModule.setAttractionStrength(self, value)
    moduleState.config.attractionStrength = math.clamp(value, 0, 10000)
end

function TornadoModule.getAttractionStrength(self)
    return moduleState.config.attractionStrength
end

-- 批量设置配置
function TornadoModule.setConfig(self, configTable)
    if configTable.radius then
        self:setRadius(configTable.radius)
    end
    if configTable.height then
        self:setHeight(configTable.height)
    end
    if configTable.rotationSpeed then
        self:setRotationSpeed(configTable.rotationSpeed)
    end
    if configTable.attractionStrength then
        self:setAttractionStrength(configTable.attractionStrength)
    end
end

-- 检查部件是否应该被控制
local function shouldControlPart(part)
    if not part:IsA("BasePart") then
        return false
    end
    
    if part.Anchored then
        return false
    end
    
    if not part:IsDescendantOf(Workspace) then
        return false
    end
    
    -- 排除玩家角色相关的部件
    local character = moduleState.localPlayer.Character
    if character and (part:IsDescendantOf(character) or part.Parent == character) then
        return false
    end
    
    -- 排除其他玩家角色的部件
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= moduleState.localPlayer then
            local otherCharacter = player.Character
            if otherCharacter and (part:IsDescendantOf(otherCharacter) or part.Parent == otherCharacter) then
                return false
            end
        end
    end
    
    return true
end

-- 保留部件（修改物理属性）
local function retainPart(part)
    if shouldControlPart(part) then
        part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        part.CanCollide = false
        return true
    end
    return false
end

-- 添加部件到控制列表
local function addPart(part)
    if not table.find(moduleState.parts, part) and retainPart(part) then
        table.insert(moduleState.parts, part)
    end
end

-- 从控制列表移除部件
local function removePart(part)
    local index = table.find(moduleState.parts, part)
    if index then
        table.remove(moduleState.parts, index)
    end
end

-- 设置网络控制（扩大模拟范围）
local function setupNetworkControl()
    -- 修改模拟半径为无限大
    local heartbeatConnection
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        sethiddenproperty(moduleState.localPlayer, "SimulationRadius", math.huge)
        moduleState.localPlayer.ReplicationFocus = Workspace
    end)
    
    table.insert(moduleState.connections, heartbeatConnection)
end

-- 主要的龙卷风逻辑
local function setupTornadoLogic()
    local tornadoConnection
    tornadoConnection = RunService.Heartbeat:Connect(function()
        if not moduleState.enabled then return end
        
        -- 获取角色根部件
        local character = moduleState.localPlayer.Character
        if not character then return end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        local center = rootPart.Position
        local config = moduleState.config
        
        -- 处理所有控制的部件
        for _, part in pairs(moduleState.parts) do
            if part.Parent and not part.Anchored and part:IsDescendantOf(Workspace) then
                local pos = part.Position
                
                -- 计算水平距离
                local distance = (Vector3.new(pos.X, center.Y, pos.Z) - center).Magnitude
                
                -- 计算当前角度
                local angle = math.atan2(pos.Z - center.Z, pos.X - center.X)
                
                -- 计算新角度
                local newAngle = angle + math.rad(config.rotationSpeed)
                
                -- 计算目标位置（螺旋效果）
                local targetPos = Vector3.new(
                    center.X + math.cos(newAngle) * math.min(config.radius, distance),
                    center.Y + (config.height * math.abs(math.sin((pos.Y - center.Y) / math.max(config.height, 0.01)))),
                    center.Z + math.sin(newAngle) * math.min(config.radius, distance)
                )
                
                -- 施加速度
                local directionToTarget = (targetPos - part.Position).Unit
                part.Velocity = directionToTarget * config.attractionStrength
            end
        end
    end)
    
    table.insert(moduleState.connections, tornadoConnection)
    
    -- 监听新部件
    local descendantAddedConnection
    descendantAddedConnection = Workspace.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") then
            addPart(descendant)
        end
    end)
    table.insert(moduleState.connections, descendantAddedConnection)
    
    -- 监听部件移除
    local descendantRemovingConnection
    descendantRemovingConnection = Workspace.DescendantRemoving:Connect(function(descendant)
        if descendant:IsA("BasePart") then
            removePart(descendant)
        end
    end)
    table.insert(moduleState.connections, descendantRemovingConnection)
    
    -- 监听角色变化
    local characterAddedConnection
    characterAddedConnection = moduleState.localPlayer.CharacterAdded:Connect(function(character)
        moduleState.character = character
        local rootPart = character:WaitForChild("HumanoidRootPart")
        if rootPart then
            moduleState.humanoidRootPart = rootPart
        end
    end)
    table.insert(moduleState.connections, characterAddedConnection)
end

-- 清理所有连接
local function cleanupConnections()
    for _, connection in pairs(moduleState.connections) do
        if connection then
            connection:Disconnect()
        end
    end
    moduleState.connections = {}
end

-- 清理所有部件
local function cleanupParts()
    for _, part in pairs(moduleState.parts) do
        if part and part.Parent then
            -- 恢复原始物理属性（可选，这里只是移除特殊属性）
            pcall(function()
                part.CustomPhysicalProperties = PhysicalProperties.new(
                    part.Material,
                    0.3, 0.5, 0.5, -- 默认摩擦力等
                    1, 1
                )
                part.CanCollide = true
            end)
        end
    end
    moduleState.parts = {}
end

-- 初始化
function TornadoModule.enable(self)
    if moduleState.enabled then return end
    
    moduleState.localPlayer = Players.LocalPlayer
    if not moduleState.localPlayer then
        warn("TornadoModule: LocalPlayer not found")
        return
    end
    
    -- 初始化角色引用
    local character = moduleState.localPlayer.Character
    if character then
        moduleState.character = character
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            moduleState.humanoidRootPart = rootPart
        end
    end
    
    -- 收集所有现有部件
    for _, descendant in pairs(Workspace:GetDescendants()) do
        if descendant:IsA("BasePart") then
            addPart(descendant)
        end
    end
    
    -- 设置网络控制
    setupNetworkControl()
    
    -- 设置龙卷风逻辑
    setupTornadoLogic()
    
    moduleState.enabled = true
end

-- 禁用
function TornadoModule.disable(self)
    if not moduleState.enabled then return end
    
    cleanupConnections()
    cleanupParts()
    
    moduleState.enabled = false
end

-- 卸载（完全清理）
function TornadoModule.unload(self)
    self:disable()
    
    -- 清理所有状态
    moduleState.config = {
        radius = 50,
        height = 100,
        rotationSpeed = 10,
        attractionStrength = 1000,
    }
    moduleState.parts = {}
    moduleState.connections = {}
    moduleState.localPlayer = nil
    moduleState.character = nil
    moduleState.humanoidRootPart = nil
    
    -- 清理自身
    TornadoModule = nil
end

-- 检查状态
function TornadoModule.isEnabled(self)
    return moduleState.enabled
end

return TornadoModule