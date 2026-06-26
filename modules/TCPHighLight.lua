-- HighlightModule.lua
local HighlightModule = {}
local cloneref = cloneref or clonereference or function(obj) return obj end
local RunService = cloneref(game:GetService("RunService"))
local Players = cloneref(game:GetService("Players"))

-- 创建子表
HighlightModule.touchinterest = {}
HighlightModule.clickdetectors = {}
HighlightModule.proximityprompts = {}

-- 内部状态
local connections = {}
local adornments = {}
local billboardGuis = {}
local isActive = {
    touchInterest = false,
    clickDetectors = false,
    proximityPrompts = false
}

-- 颜色配置
local COLORS = {
    touchInterest = {
        outline = Color3.fromRGB(255, 100, 100),
        textColor = Color3.fromRGB(180, 30, 30),
        strokeColor = Color3.fromRGB(255, 200, 200),
    },
    clickDetectors = {
        outline = Color3.fromRGB(100, 150, 255),
        textColor = Color3.fromRGB(30, 60, 180),
        strokeColor = Color3.fromRGB(200, 220, 255),
    },
    proximityPrompts = {
        outline = Color3.fromRGB(100, 255, 100),
        textColor = Color3.fromRGB(30, 150, 30),
        strokeColor = Color3.fromRGB(200, 255, 200),
    }
}

-- 全局距离更新连接
local distanceUpdater = nil

-- 更新所有Billboard距离
local function updateDistances()
    local player = Players.LocalPlayer
    if not player then return end
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- 使用pairs避免删除时的错误
    for part, data in pairs(billboardGuis) do
        if data and data.Parent and part and part.Parent then
            local dist = (part.Position - hrp.Position).Magnitude
            data.Text = string.format("%s\n%.1fm", part.Parent.Name, dist)
        end
    end
end

-- 开始/停止距离更新
local function startDistanceUpdater()
    if not distanceUpdater then
        distanceUpdater = RunService.Heartbeat:Connect(updateDistances)
    end
end

local function stopDistanceUpdater()
    if distanceUpdater and next(billboardGuis) == nil then
        distanceUpdater:Disconnect()
        distanceUpdater = nil
    end
end

-- 创建BoxHandleAdornment
local function createAdornment(part, color)
    if not part or not part.Parent then return end
    if adornments[part] then return end
    
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "ESP_BoxHandle"
    box.Adornee = part
    box.AlwaysOnTop = true
    box.ZIndex = 1
    box.Size = part.Size + Vector3.new(0.2, 0.2, 0.2)
    box.Color3 = color.outline
    box.Transparency = 0.6
    box.Parent = part
    
    adornments[part] = box
end

-- 创建Billboard
local function createBillboard(part, name, color)
    if not part or not part.Parent then return end
    if billboardGuis[part] then return end
    
    local bg = Instance.new("BillboardGui")
    bg.Adornee = part
    bg.Size = UDim2.new(0, 250, 0, 70)
    bg.StudsOffset = Vector3.new(0, 2, 0)
    bg.AlwaysOnTop = true
    
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, -10, 1, -10)
    tl.Position = UDim2.new(0, 5, 0, 5)
    tl.BackgroundTransparency = 1
    tl.TextColor3 = color.textColor
    tl.TextStrokeColor3 = color.strokeColor
    tl.TextStrokeTransparency = 0
    tl.Font = Enum.Font.SourceSansBold
    tl.TextSize = 18
    tl.Text = name
    tl.Parent = bg
    
    -- 存储TextLabel引用用于更新距离
    billboardGuis[part] = tl
    bg.Parent = part
    
    return bg
end

-- 获取所有部件
local function getAllParts(instance)
    if not instance then return {} end
    local parts = {}
    local function scan(obj)
        if not obj then return end
        if obj:IsA("BasePart") then
            table.insert(parts, obj)
        end
        for _, child in ipairs(obj:GetChildren()) do
            scan(child)
        end
    end
    scan(instance)
    return parts
end

-- 获取目标对象
local function getTargetObject(instance)
    if not instance or not instance.Parent then return nil end
    local target = instance.Parent
    if target:IsA("Attachment") then
        target = target.Parent
    end
    return target
end

-- 为对象添加ESP
local function addESPToObject(target, color)
    if not target then return end
    local parts = getAllParts(target)
    for _, part in ipairs(parts) do
        createAdornment(part, color)
        createBillboard(part, target.Name, color)
    end
    if #parts > 0 then
        startDistanceUpdater()
    end
end

-- 清理单个部件的ESP
local function removeESPFromPart(part)
    -- 清理Adornment
    local adorn = adornments[part]
    if adorn then
        adornments[part] = nil
        if adorn.Parent then
            adorn:Destroy()
        end
    end
    
    -- 清理Billboard
    local label = billboardGuis[part]
    if label then
        billboardGuis[part] = nil
        if label.Parent then
            label.Parent:Destroy()  -- 销毁整个BillboardGui
        end
    end
end

-- 清理实例相关的所有ESP
local function removeESPFromInstance(instance)
    local target = getTargetObject(instance)
    if target then
        local parts = getAllParts(target)
        for _, part in ipairs(parts) do
            removeESPFromPart(part)
        end
    end
    stopDistanceUpdater()
end

-- 清理所有ESP
local function clearAllESP()
    -- 先清理所有Adornment
    for part, adorn in pairs(adornments) do
        if adorn.Parent then
            adorn:Destroy()
        end
    end
    adornments = {}
    
    -- 再清理所有Billboard
    for part, label in pairs(billboardGuis) do
        if label.Parent then
            label.Parent:Destroy()  -- 销毁BillboardGui
        end
    end
    billboardGuis = {}
    
    stopDistanceUpdater()
end

-- 通用透视设置函数
local function setupESP(triggerType, instanceType, color)
    local activeKey = triggerType
    if isActive[activeKey] then return end
    isActive[activeKey] = true
    
    -- 处理现有实例
    for _, instance in ipairs(cloneref(game):GetDescendants()) do
        if instance:IsA(instanceType) then
            addESPToObject(getTargetObject(instance), color)
        end
    end
    
    -- 监听新实例
    local conn1 = cloneref(game).DescendantAdded:Connect(function(desc)
        if desc:IsA(instanceType) and isActive[activeKey] then
            -- 延迟一帧确保对象加载完成
            task.wait()
            addESPToObject(getTargetObject(desc), color)
        end
    end)
    table.insert(connections, {type = triggerType, conn = conn1})
    
    -- 监听删除
    local conn2 = cloneref(game).DescendantRemoving:Connect(function(desc)
        if desc:IsA(instanceType) then
            -- 直接从存储中清理对应的部件
            local target = getTargetObject(desc)
            if target then
                local parts = getAllParts(target)
                for _, part in ipairs(parts) do
                    removeESPFromPart(part)
                end
            end
            stopDistanceUpdater()
        end
    end)
    table.insert(connections, {type = triggerType, conn = conn2})
end

-- 通用透视关闭函数
local function disableESP(triggerType, instanceType)
    local activeKey = triggerType
    if not isActive[activeKey] then return end
    isActive[activeKey] = false
    
    -- 断开该类型的连接
    local remainingConns = {}
    for _, connData in ipairs(connections) do
        if connData.type == triggerType then
            if connData.conn.Connected then
                connData.conn:Disconnect()
            end
        else
            table.insert(remainingConns, connData)
        end
    end
    connections = remainingConns
    
    -- 清除该类型实例的所有ESP
    for _, instance in ipairs(cloneref(game):GetDescendants()) do
        if instance:IsA(instanceType) then
            removeESPFromInstance(instance)
        end
    end
end

-- 定义方法
HighlightModule.touchinterest.enable = function()
    setupESP("touchInterest", "TouchTransmitter", COLORS.touchInterest)
end

HighlightModule.touchinterest.disable = function()
    disableESP("touchInterest", "TouchTransmitter")
end

HighlightModule.clickdetectors.enable = function()
    setupESP("clickDetectors", "ClickDetector", COLORS.clickDetectors)
end

HighlightModule.clickdetectors.disable = function()
    disableESP("clickDetectors", "ClickDetector")
end

HighlightModule.proximityprompts.enable = function()
    setupESP("proximityPrompts", "ProximityPrompt", COLORS.proximityPrompts)
end

HighlightModule.proximityprompts.disable = function()
    disableESP("proximityPrompts", "ProximityPrompt")
end

-- 卸载
function HighlightModule.unload()
    HighlightModule.touchinterest.disable()
    HighlightModule.clickdetectors.disable()
    HighlightModule.proximityprompts.disable()
    
    -- 断开所有连接
    for _, connData in ipairs(connections) do
        if connData.conn.Connected then
            connData.conn:Disconnect()
        end
    end
    connections = {}
    
    -- 强制清理所有残留
    clearAllESP()
end

return HighlightModule