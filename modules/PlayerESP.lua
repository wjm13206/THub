-- EspSimple 模块
local EspSimple = {}

-- 私有状态
local enabled = false
local highlights = {}      -- 玩家 -> Highlight
local labels = {}          -- 玩家 -> BillboardGui
local connections = {}     -- 玩家 -> {CharacterAdded连接, CharacterRemoving连接}
local playerAddedConn = nil
local playerRemovingConn = nil

-- 颜色定义
local FRIEND_COLOR = Color3.new(0, 1, 0)  -- 绿色
local NON_FRIEND_COLOR = Color3.new(1, 0, 0) -- 红色
local MARKED_COLOR = Color3.new(1, 1, 1) -- 白色（被标记的玩家）

-- 本地玩家与输入服务
local cloneref = cloneref or clonereference or function(obj) return obj end
local localPlayer = cloneref(game:GetService("Players")).LocalPlayer
local UserInputService = cloneref(game:GetService("UserInputService"))

-- 存储被标记的玩家（键为玩家对象，值为 true）
local markedPlayers = {}

-- 默认配置（不可修改）
local DEFAULT_CONFIG = {
    fillColor = Color3.new(1, 0, 0),
    fillTransparency = 0.8,
    outlineColor = Color3.new(1, 0, 0),
    outlineTransparency = 0,
    onlyOutline = false,
    labelOffset = Vector3.new(0, 3, 0),
    labelSize = UDim2.new(0, 200, 0, 50),
    textSize = 18,
    textColor = Color3.new(1, 1, 1),
}

-- 获取玩家应该显示的颜色（优先级：标记 > 好友 > 普通）
local function getPlayerColor(player)
    if markedPlayers[player] then
        return MARKED_COLOR
    elseif player:IsFriendsWith(localPlayer.UserId) then
        return FRIEND_COLOR
    else
        return NON_FRIEND_COLOR
    end
end

-- 更新单个玩家的高亮颜色（根据当前状态重新设置）
local function updatePlayerColor(player)
    local highlight = highlights[player]
    if not highlight then return end
    
    local color = getPlayerColor(player)
    highlight.FillColor = color
    highlight.OutlineColor = color
end

-- 添加高亮
local function addHighlight(player, character)
    if player == localPlayer or not character then return end

    local color = getPlayerColor(player)
    
    local highlight = Instance.new("Highlight")
    highlight.Adornee = character
    highlight.FillColor = color
    highlight.FillTransparency = DEFAULT_CONFIG.fillTransparency
    highlight.OutlineColor = color
    highlight.OutlineTransparency = DEFAULT_CONFIG.outlineTransparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    if DEFAULT_CONFIG.onlyOutline then
        highlight.FillTransparency = 1
    end
    highlights[player] = highlight
end

-- 添加名字标签（被标记的玩家名字前加 [★] 标识）
local function addLabel(player, character)
    if player == localPlayer or not character then return end
    local head = character:WaitForChild("Head", 5)
    if not head then return end

    local isMarked = markedPlayers[player]
    local isFriend = player:IsFriendsWith(localPlayer.UserId)
    local prefix = ""
    
    if isMarked then
        prefix = "📍 "  -- 被标记的玩家显示特殊标记
    elseif isFriend then
        prefix = "⭐ "  -- 好友显示星标
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = head
    billboard.Size = DEFAULT_CONFIG.labelSize
    billboard.StudsOffset = DEFAULT_CONFIG.labelOffset
    billboard.AlwaysOnTop = true
    billboard.Parent = head

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    if player.DisplayName == player.Name then
        label.Text = prefix .. player.DisplayName
    else
        label.Text = prefix .. player.DisplayName .. " (@" .. player.Name .. ")"
    end
    label.TextColor3 = DEFAULT_CONFIG.textColor
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = DEFAULT_CONFIG.textSize
    label.Parent = billboard

    labels[player] = billboard
end

-- 移除单个玩家的所有效果
local function removePlayerEffects(player)
    local h = highlights[player]
    if h then
        h:Destroy()
        highlights[player] = nil
    end
    local l = labels[player]
    if l then
        l:Destroy()
        labels[player] = nil
    end
end

-- 为单个玩家设置监听（角色变化）
local function setupPlayer(player)
    if not enabled then return end
    if player == localPlayer then return end

    -- 如果已有连接，先清理
    if connections[player] then
        for _, conn in ipairs(connections[player]) do
            conn:Disconnect()
        end
        connections[player] = nil
        removePlayerEffects(player)
    end

    -- 如果当前有角色，立即添加效果
    local character = player.Character
    if character then
        addHighlight(player, character)
        addLabel(player, character)
    end

    -- 角色添加时（重生后重新应用效果，且保留标记状态）
    local charAdded = player.CharacterAdded:Connect(function(newChar)
        removePlayerEffects(player)   -- 移除旧效果
        addHighlight(player, newChar) -- 重新添加高亮（会自动应用标记色）
        addLabel(player, newChar)     -- 重新添加标签
    end)

    -- 角色移除时清理
    local charRemoving = player.CharacterRemoving:Connect(function()
        removePlayerEffects(player)
    end)

    connections[player] = {charAdded, charRemoving}
end

-- 清理所有玩家效果并断开所有连接
local function clearAll()
    for player, conns in pairs(connections) do
        for _, conn in ipairs(conns) do
            conn:Disconnect()
        end
        removePlayerEffects(player)
    end
    connections = {}
    highlights = {}
    labels = {}
end

-- 全局监听玩家加入/离开
local function startGlobalListeners()
    if playerAddedConn then return end
    playerAddedConn = game.Players.PlayerAdded:Connect(setupPlayer)
    playerRemovingConn = game.Players.PlayerRemoving:Connect(removePlayerEffects)
end

local function stopGlobalListeners()
    if playerAddedConn then
        playerAddedConn:Disconnect()
        playerAddedConn = nil
    end
    if playerRemovingConn then
        playerRemovingConn:Disconnect()
        playerRemovingConn = nil
    end
end

-- 处理鼠标中键点击（标记/取消标记玩家）
local mouseClickConn = nil
local function setupMouseClickHandler()
    if mouseClickConn then return end
    mouseClickConn = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end  -- 忽略聊天输入等场景
        if not enabled then return end         -- 仅在 ESP 开启时生效
        
        -- 检查是否为鼠标中键
        if input.UserInputType == Enum.UserInputType.MouseButton3 then
            -- 获取鼠标指向的玩家
            local mouse = localPlayer:GetMouse()
            local target = mouse.Target
            if not target then return end
            
            -- 向上查找玩家角色
            local character = target:FindFirstAncestorOfClass("Model")
            if not character then return end
            
            local player = game.Players:GetPlayerFromCharacter(character)
            if not player or player == localPlayer then return end
            
            -- 切换标记状态
            if markedPlayers[player] then
                -- 已标记 → 取消标记
                markedPlayers[player] = nil
            else
                -- 未标记 → 添加标记
                markedPlayers[player] = true
            end
            
            -- 更新该玩家的高亮颜色（如果存在）
            updatePlayerColor(player)
            -- 同时更新标签（让前缀也变化）
            local label = labels[player]
            if label then
                -- 简单粗暴：重新生成标签（或者只改文本，为了代码简洁，直接重建）
                local characterNow = player.Character
                if characterNow then
                    removePlayerEffects(player)
                    addHighlight(player, characterNow)
                    addLabel(player, characterNow)
                end
            end
        end
    end)
end

-- 公开函数：开启ESP
function EspSimple.enable()
    if enabled then return end
    enabled = true
    startGlobalListeners()
    -- 为所有现有玩家（除了自己）添加效果
    for _, player in ipairs(game.Players:GetPlayers()) do
        setupPlayer(player)
    end
    -- 设置鼠标中键监听（整个生命周期只设置一次，但内部会检查 enabled）
    if not mouseClickHandlerSet then
        setupMouseClickHandler()
        mouseClickHandlerSet = true
    end
end

-- 公开函数：关闭ESP（清除所有效果，但不清除标记记录）
function EspSimple.disable()
    if not enabled then return end
    enabled = false
    clearAll()
    -- 注意：标记记录 markedPlayers 不清空，但此时 ESP 已关闭，用户看不到效果
    -- 如果再次 enable，会重新读取 markedPlayers 并应用白色高亮
end

-- 公开函数：完全卸载（彻底销毁，不能再被启用）
function EspSimple.unload()
    enabled = false
    clearAll()
    stopGlobalListeners()
    if mouseClickConn then
        mouseClickConn:Disconnect()
        mouseClickConn = nil
    end
    -- 清空标记记录
    markedPlayers = {}
    -- 清空所有表，防止再次调用
    highlights = nil
    labels = nil
    connections = nil
    -- 将公开函数置空，防止误调用
    EspSimple.enable = nil
    EspSimple.disable = nil
    EspSimple.unload = nil
end

-- 初始化鼠标中键处理器的标记（避免重复设置）
local mouseClickHandlerSet = false

return EspSimple