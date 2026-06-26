-- Loop Oof (loopoof) 模块
-- 循环播放所有玩家的死亡音效（Oof声音）
-- 
-- 使用方法：
--   local loopoof = loadstring(game:HttpGet("raw_url_here"))()
--   
--   -- 启用循环Oof（所有玩家都会发出Oof声）
--   loopoof.enable()
--   
--   -- 禁用循环Oof
--   loopoof.disable()
--   
--   -- 检查是否正在运行
--   print(loopoof.isEnabled())
--   
--   -- 卸载整个模块
--   loopoof.unload()

local LoopOofModule = {}

-- Services
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local LocalPlayer = Players.LocalPlayer

-- 内部状态
local isActive = false
local currentLoop = nil
local currentPlayers = {}

-- 存储所有连接，用于unload
local connections = {}

-- 获取玩家的声音对象
local function getOofSound(character)
    if not character then return nil end
    
    local head = character:FindFirstChild("Head")
    if not head then return nil end
    
    -- 查找Head下的所有声音
    for _, sound in pairs(head:GetChildren()) do
        if sound:IsA("Sound") then
            return sound
        end
    end
    
    return nil
end

-- 播放单个玩家的Oof声音
local function playOofSound(player)
    if not player or not player.Character then return false end
    
    local character = player.Character
    local oofSound = getOofSound(character)
    
    if oofSound then
        pcall(function()
            oofSound.Playing = true
        end)
        return true
    end
    return false
end

-- 播放所有玩家的Oof声音
local function playAllOofSounds()
    for _, player in pairs(currentPlayers) do
        if player and player.Character then
            playOofSound(player)
        end
    end
end

-- 更新玩家列表
local function updatePlayerList()
    currentPlayers = {}
    for _, player in pairs(Players:GetPlayers()) do
        table.insert(currentPlayers, player)
    end
end

-- 主循环
local function startLoop()
    if currentLoop then
        currentLoop:Disconnect()
        currentLoop = nil
    end
    
    isActive = true
    updatePlayerList()
    
    -- 每0.1秒循环播放一次
    currentLoop = RunService.Heartbeat:Connect(function()
        if not isActive then
            if currentLoop then
                currentLoop:Disconnect()
                currentLoop = nil
            end
            return
        end
        
        playAllOofSounds()
        task.wait(0.1)
    end)
    
    -- 监听玩家加入/离开事件
    local playerAddedConn = Players.PlayerAdded:Connect(function(player)
        table.insert(currentPlayers, player)
    end)
    table.insert(connections, playerAddedConn)
    
    local playerRemovingConn = Players.PlayerRemoving:Connect(function(player)
        for i, p in ipairs(currentPlayers) do
            if p == player then
                table.remove(currentPlayers, i)
                break
            end
        end
    end)
    table.insert(connections, playerRemovingConn)
    
    -- 存储循环连接
    table.insert(connections, currentLoop)
end

-- 停止循环
local function stopLoop()
    isActive = false
    if currentLoop then
        currentLoop:Disconnect()
        currentLoop = nil
    end
end

-- 清理所有连接
local function cleanupAll()
    stopLoop()
    
    for _, conn in ipairs(connections) do
        if conn and conn.Disconnect then
            pcall(function() conn:Disconnect() end)
        end
    end
    connections = {}
    currentPlayers = {}
end

-- 启用循环Oof
function LoopOofModule.enable()
    if isActive then
        return false
    end
    startLoop()
    return true
end

-- 禁用循环Oof
function LoopOofModule.disable()
    if not isActive then
        return false
    end
    stopLoop()
    return true
end

-- 检查是否启用
function LoopOofModule.isEnabled()
    return isActive
end

-- 卸载整个模块
function LoopOofModule.unload()
    cleanupAll()
    
    -- 清空模块中的所有函数
    LoopOofModule.enable = nil
    LoopOofModule.disable = nil
    LoopOofModule.isEnabled = nil
    LoopOofModule.unload = nil
    
    -- 清空内部状态
    isActive = false
    currentLoop = nil
    currentPlayers = {}
    connections = {}
end

return LoopOofModule