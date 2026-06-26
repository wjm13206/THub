-- NPC_Highlighter.lua
-- 完全内置的高性能 NPC 高亮模块（无外部依赖）

local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local Workspace = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))

local NPCHighlighter = {}
NPCHighlighter.__index = NPCHighlighter

-- 创建新的 NPC 高亮器实例
function NPCHighlighter.new(options)
    local self = setmetatable({}, NPCHighlighter)
    
    options = options or {}
    
    -- 高亮颜色设置
    self.enableHighlight = true
    self.outlineColor = options.outlineColor or Color3.fromRGB(255, 215, 0)
    self.fillColor = options.fillColor or Color3.fromRGB(255, 215, 0)
    self.highlightTransparency = options.highlightTransparency or 0.5
    
    -- 名称标签设置
    self.enableNameTag = true
    self.namePrefix = options.namePrefix or "[NPC] "
    self.nameSuffix = options.nameSuffix or ""
    self.fontSize = 16
    self.showDistance = options.showDistance or false
    self.tagColor = options.tagColor or Color3.new(1, 1, 1)
    
    -- 状态标志
    self.enabled = false
    self.isDestroyed = false
    
    -- 存储内部数据
    self.npcData = {}               -- [npcModel] = { highlights, billboard, label, baseName, connections }
    self.npcConnection = nil        -- DescendantAdded 连接
    self.removalConnection = nil    -- DescendantRemoving 连接
    self.cleanupConnection = nil    -- 清理无效数据连接
    self.heartbeatConnection = nil  -- 距离更新连接
    
    -- 分帧配置
    self.batchSize = options.batchSize or 500
    self.waitTimeout = options.waitTimeout or 5  -- 等待部件超时时间（秒）
    
    return self
end

-- 判断是否为 NPC
local function isNPC(model)
    if not model:IsA("Model") then
        return false
    end
    
    local humanoid = model:FindFirstChild("Humanoid")
    if not humanoid then
        return false
    end
    
    local player = Players:GetPlayerFromCharacter(model)
    return player == nil
end

-- 为部件添加高亮
local function addHighlightToPart(part, outlineColor, fillColor, transparency)
    if not part:IsA("BasePart") then
        return nil
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "NPC_Highlight"
    highlight.OutlineColor = outlineColor
    highlight.FillColor = fillColor
    highlight.FillTransparency = transparency
    highlight.Parent = part
    
    return highlight
end

-- 为模型添加高亮
local function addHighlightToModel(model, outlineColor, fillColor, transparency)
    local highlights = {}
    
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("BasePart") then
            local highlight = addHighlightToPart(child, outlineColor, fillColor, transparency)
            if highlight then
                table.insert(highlights, highlight)
            end
        end
    end
    
    return highlights
end

-- 创建名称标签
local function createNameTag(model, adornee, text, fontSize, textColor)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NPC_NameTag"
    billboard.Adornee = adornee
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = model
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = textColor
    label.TextStrokeTransparency = 0.5
    label.Font = Enum.Font.SourceSansBold
    label.Text = text
    label.Parent = billboard
    
    if fontSize then
        label.TextScaled = false
        label.TextSize = fontSize
    else
        label.TextScaled = true
    end
    
    return billboard, label
end

-- 获取模型的附着点（同步，不等待）
local function getAdorneeSync(model)
    -- 优先 Head
    local head = model:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        return head
    end
    
    -- 其次 HumanoidRootPart
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then
        return hrp
    end
    
    -- 再次 PrimaryPart
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
        return model.PrimaryPart
    end
    
    -- 最后找任意 BasePart
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("BasePart") then
            return child
        end
    end
    
    return nil
end

-- 等待模型的附着点就绪（异步，类似 WaitForChild）
local function waitForAdornee(model, timeout)
    -- 同步检查现有部件，优先 Head
    local part = model:FindFirstChild("Head")
    if part and part:IsA("BasePart") then return part end
    part = model:FindFirstChild("HumanoidRootPart")
    if part and part:IsA("BasePart") then return part end

    -- 使用 WaitForChild 异步等待（协程内挂起）
    local function tryWait(name)
        local success, result = pcall(model.WaitForChild, model, name, timeout)
        if success and result and result:IsA("BasePart") then
            return result
        end
        return nil
    end

    part = tryWait("Head") or tryWait("HumanoidRootPart")
    if part then return part end

    -- 仍可回退到 PrimaryPart 或任意 BasePart
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
        return model.PrimaryPart
    end
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("BasePart") then
            return child
        end
    end
    return nil
end

-- 处理单个 NPC（异步等待部件就绪）
function NPCHighlighter:processNPC(npcModel)
    if self.npcData[npcModel] then return end
    self.npcData[npcModel] = { processing = true }

    task.spawn(function()
        local adornee = nil
        -- 持续等待直到附着点出现或 NPC 失效
        while self.enabled and npcModel and npcModel.Parent do
            adornee = waitForAdornee(npcModel, 2)  -- 每次尝试等2秒
            if adornee then break end
            task.wait()  -- 让出执行权，避免死循环
        end

        -- 最终有效性检查
        if not self.enabled or not npcModel or not npcModel.Parent or not adornee then
            self.npcData[npcModel] = nil
            return
        end

        local existingData = self.npcData[npcModel]
        if existingData and existingData.billboard then return end
        
        local data = {}
        
        -- 创建高亮
        if self.enableHighlight then
            data.highlights = addHighlightToModel(npcModel, self.outlineColor, self.fillColor, self.highlightTransparency)
        end
        
        -- 创建标签
        if self.enableNameTag then
            local displayName = self.namePrefix .. npcModel.Name .. self.nameSuffix
            data.billboard, data.label = createNameTag(npcModel, adornee, displayName, self.fontSize, self.tagColor)
            data.baseName = displayName
        end
        
        -- 监听模型内部新增部件（为新部件添加高亮）
        if self.enableHighlight then
            local descendantAddedConn = npcModel.DescendantAdded:Connect(function(child)
                if child:IsA("BasePart") then
                    -- 检查这个部件是否已经有高亮了
                    local hasHighlight = false
                    if data.highlights then
                        for _, hl in ipairs(data.highlights) do
                            if hl and hl.Parent == child then
                                hasHighlight = true
                                break
                            end
                        end
                    end
                    
                    if not hasHighlight then
                        local highlight = addHighlightToPart(child, self.outlineColor, self.fillColor, self.highlightTransparency)
                        if highlight then
                            table.insert(data.highlights, highlight)
                        end
                    end
                end
            end)
            
            data.connections = { descendantAddedConn }
        end
        
        self.npcData[npcModel] = data
    end)
end

-- 移除 NPC 的高亮和标签
function NPCHighlighter:unprocessNPC(npcModel)
    local data = self.npcData[npcModel]
    if not data then
        return
    end
    
    -- 断开连接
    if data.connections then
        for _, conn in ipairs(data.connections) do
            conn:Disconnect()
        end
    end
    
    -- 移除高亮
    if data.highlights then
        for _, highlight in ipairs(data.highlights) do
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
        end
    end
    
    -- 移除标签
    if data.billboard and data.billboard.Parent then
        data.billboard:Destroy()
    end
    
    self.npcData[npcModel] = nil
end

-- 更新距离显示
function NPCHighlighter:updateDistances()
    local localPlayer = Players.LocalPlayer
    if not localPlayer then
        return
    end
    
    local character = localPlayer.Character
    if not character then
        return
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    if not rootPart then
        return
    end
    
    for npcModel, data in pairs(self.npcData) do
        if data and not data.processing then  -- 跳过正在处理的
            if npcModel and npcModel.Parent then
                if data.billboard and data.billboard.Adornee and data.label then
                    local adornee = data.billboard.Adornee
                    if adornee and adornee.Parent then
                        local distance = (adornee.Position - rootPart.Position).Magnitude
                        data.label.Text = string.format("%s (%.1f)", data.baseName, distance)
                    end
                end
            else
                self:unprocessNPC(npcModel)
            end
        end
    end
end

-- 扫描现有 NPC
function NPCHighlighter:scanExisting()
    local allObjects = Workspace:GetDescendants()
    
    -- 直接同步遍历，但处理是异步的
    for _, obj in ipairs(allObjects) do
        if isNPC(obj) then
            self:processNPC(obj)
        end
    end
end

-- 开始监听
function NPCHighlighter:startListeners()
    -- 新 NPC
    if self.npcConnection then
        self.npcConnection:Disconnect()
    end
    self.npcConnection = Workspace.DescendantAdded:Connect(function(descendant)
        if self.enabled and isNPC(descendant) then
            self:processNPC(descendant)
        end
    end)
    
    -- 移除 NPC
    if self.removalConnection then
        self.removalConnection:Disconnect()
    end
    self.removalConnection = Workspace.DescendantRemoving:Connect(function(descendant)
        if isNPC(descendant) then
            self:unprocessNPC(descendant)
        end
    end)
    
    -- 定期清理无效数据
    if self.cleanupConnection then
        self.cleanupConnection:Disconnect()
    end
    self.cleanupConnection = RunService.Heartbeat:Connect(function()
        if not self.enabled then
            return
        end
        
        local toRemove = {}
        for npcModel, data in pairs(self.npcData) do
            if data and not data.processing then
                if not npcModel or not npcModel.Parent then
                    table.insert(toRemove, npcModel)
                end
            end
        end
        
        for _, npcModel in ipairs(toRemove) do
            self:unprocessNPC(npcModel)
        end
    end)
    
    -- 距离更新
    if self.showDistance then
        if self.heartbeatConnection then
            self.heartbeatConnection:Disconnect()
        end
        self.heartbeatConnection = RunService.Heartbeat:Connect(function()
            self:updateDistances()
        end)
    end
end

-- 停止所有监听
function NPCHighlighter:stopListeners()
    if self.npcConnection then
        self.npcConnection:Disconnect()
        self.npcConnection = nil
    end
    
    if self.removalConnection then
        self.removalConnection:Disconnect()
        self.removalConnection = nil
    end
    
    if self.cleanupConnection then
        self.cleanupConnection:Disconnect()
        self.cleanupConnection = nil
    end
    
    if self.heartbeatConnection then
        self.heartbeatConnection:Disconnect()
        self.heartbeatConnection = nil
    end
end

-- 启用
function NPCHighlighter:enable()
    if self.enabled then
        return
    end
    
    self.enabled = true
    self:startListeners()
    self:scanExisting()
end

-- 禁用
function NPCHighlighter:disable()
    if not self.enabled then
        return
    end
    
    self.enabled = false
    self:stopListeners()
    
    for npcModel, _ in pairs(self.npcData) do
        self:unprocessNPC(npcModel)
    end
    
    self.npcData = {}
end

-- 卸载
function NPCHighlighter:unload()
    if self.isDestroyed then
        return
    end
    
    self:disable()
    self.isDestroyed = true
end

-- 获取 NPC 数量
function NPCHighlighter:getCount()
    local count = 0
    for npcModel, data in pairs(self.npcData) do
        if data and not data.processing and npcModel and npcModel.Parent then
            count = count + 1
        end
    end
    return count
end

-- 获取所有 NPC
function NPCHighlighter:getNPCs()
    local npcs = {}
    for npcModel, data in pairs(self.npcData) do
        if data and not data.processing and npcModel and npcModel.Parent then
            table.insert(npcs, npcModel)
        end
    end
    return npcs
end

-- 设置颜色
function NPCHighlighter:setColor(outlineColor, fillColor)
    self.outlineColor = outlineColor
    self.fillColor = fillColor or outlineColor
    
    for _, data in pairs(self.npcData) do
        if data and data.highlights then
            for _, highlight in ipairs(data.highlights) do
                if highlight and highlight.Parent then
                    highlight.OutlineColor = self.outlineColor
                    highlight.FillColor = self.fillColor
                end
            end
        end
    end
end

return NPCHighlighter