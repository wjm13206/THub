-- Handle Kill (hkill) 模块（完整版）
-- 使用手中的武器击杀范围内的玩家
-- 
-- 使用方法：
--   local hkill = loadstring(game:HttpGet("raw_url_here"))()
--   
--   -- 击杀所有玩家（无限距离）
--   hkill.kill("All")
--   
--   -- 击杀100格内的所有玩家
--   hkill.kill("All", 100)
--   
--   -- 击杀单个玩家（无限距离）
--   hkill.kill("Playername")
--   
--   -- 击杀100格内的单个玩家
--   hkill.kill("Playername", 100)
--   
--   -- 击杀指定的多个玩家
--   hkill.kill({"Player1", "Player2", "Player3"}, 50)
--   
--   -- 或者使用玩家对象
--   hkill.kill(game.Players:FindFirstChild("Playername"), 100)
--   
--   -- 停止当前正在执行的hkill
--   hkill.stop()
--   
--   -- 检查是否正在运行
--   print(hkill.isRunning())
--   
--   -- 卸载整个模块
--   hkill.unload()

local HandleKillModule = {}

-- Services
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local LocalPlayer = Players.LocalPlayer

-- 内部状态
local isActive = false
local currentLoop = nil
local currentTargets = {}
local currentRange = math.huge

-- 存储所有连接，用于unload
local connections = {}

-- 获取玩家的根部件
local function getRoot(char)
    if char and char:FindFirstChildOfClass("Humanoid") then
        return char:FindFirstChildOfClass("Humanoid").RootPart
    end
    return nil
end

-- 解析距离参数
local function parseRange(range)
    if range == nil then
        return math.huge
    end
    
    if type(range) == "string" and range:lower() == "infinity" then
        return math.huge
    end
    
    if type(range) == "number" and range > 0 then
        return range
    end
    
    return math.huge
end

-- 解析玩家参数，返回玩家对象列表
local function parsePlayers(input)
    local result = {}
    
    -- 如果是 "All" 字符串，返回所有玩家
    if type(input) == "string" and input:lower() == "all" then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(result, player)
            end
        end
        return result
    end
    
    -- 如果是单个字符串（玩家名）
    if type(input) == "string" then
        for _, player in pairs(Players:GetPlayers()) do
            if player.Name:lower() == input:lower() or 
               (player.DisplayName and player.DisplayName:lower() == input:lower()) then
                if player ~= LocalPlayer then
                    table.insert(result, player)
                end
                break
            end
        end
        return result
    end
    
    -- 如果是单个 Player 对象
    if type(input) == "userdata" and input:IsA("Player") then
        if input ~= LocalPlayer then
            table.insert(result, input)
        end
        return result
    end
    
    -- 如果是表，遍历处理
    if type(input) == "table" then
        for _, item in ipairs(input) do
            if type(item) == "string" then
                -- 字符串：按名称查找玩家
                for _, player in pairs(Players:GetPlayers()) do
                    if player.Name:lower() == item:lower() or 
                       (player.DisplayName and player.DisplayName:lower() == item:lower()) then
                        if player ~= LocalPlayer and not table.find(result, player) then
                            table.insert(result, player)
                        end
                    end
                end
            elseif type(item) == "userdata" and item:IsA("Player") then
                -- 直接是 Player 对象
                if item ~= LocalPlayer and not table.find(result, item) then
                    table.insert(result, item)
                end
            end
        end
        return result
    end
    
    return result
end

-- 检查是否在范围内
local function isInRange(player, range)
    if range == math.huge then return true end
    local char = LocalPlayer.Character
    local targetChar = player.Character
    if not char or not targetChar then return false end
    
    local root = getRoot(char)
    local targetRoot = getRoot(targetChar)
    if not root or not targetRoot then return false end
    
    return (root.Position - targetRoot.Position).magnitude <= range
end

-- 获取 firetouchinterest 函数
local function getFireTouchInterest()
    -- 尝试多种方式获取 firetouchinterest
    local fireFunc = syn and syn.fire_touch_interest
    
    if not fireFunc then
        fireFunc = firetouchinterest
    end
    
    if not fireFunc then
        local env = getrenv and getrenv()
        if env then
            fireFunc = env.firetouchinterest
        end
    end
    
    if not fireFunc then
        local gc = getgc and getgc()
        if gc then
            for _, v in pairs(gc) do
                if type(v) == "function" and tostring(v):find("firetouchinterest") then
                    fireFunc = v
                    break
                end
            end
        end
    end
    
    return fireFunc
end

-- 主要的击杀循环
local function startKillLoop(targetPlayers, range)
    -- 停止当前运行的循环
    if currentLoop then
        currentLoop:Disconnect()
        currentLoop = nil
    end
    
    if not targetPlayers or #targetPlayers == 0 then
        isActive = false
        return false
    end
    
    currentTargets = targetPlayers
    currentRange = range
    isActive = true
    
    -- 验证工具可用性
    local function validateTool()
        local char = LocalPlayer.Character
        if not char then return false, nil, nil end
        
        -- 查找手中持有的工具
        local tool = nil
        for _, child in pairs(char:GetChildren()) do
            if child:IsA("Tool") then
                tool = child
                break
            end
        end
        
        if not tool then return false, nil, nil end
        
        local handle = tool:FindFirstChild("Handle")
        if not handle then return false, nil, nil end
        
        return true, tool, handle
    end
    
    -- 获取 firetouchinterest
    local firetouchinterestFunc = getFireTouchInterest()
    
    if not firetouchinterestFunc then
        isActive = false
        return false
    end
    
    -- 开始循环
    currentLoop = RunService.Heartbeat:Connect(function()
        if not isActive then
            if currentLoop then currentLoop:Disconnect() end
            currentLoop = nil
            return
        end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local success, tool, handle = validateTool()
        if not success or not tool or not handle then
            -- 没有工具时停止
            if currentLoop then currentLoop:Disconnect() end
            currentLoop = nil
            isActive = false
            return
        end
        
        -- 检查工具是否还在手中
        if tool.Parent ~= char then
            return
        end
        
        -- 遍历目标玩家
        for i = #currentTargets, 1, -1 do
            local player = currentTargets[i]
            
            -- 检查玩家是否仍然有效
            if not player or not player:IsDescendantOf(Players) then
                table.remove(currentTargets, i)
                break
            end
            
            -- 检查目标是否活着
            local targetChar = player.Character
            if not targetChar then
                break
            end
            
            local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                break
            end
            
            -- 检查距离范围
            if not isInRange(player, currentRange) then
                break
            end
            
            -- 检查是否处于死亡状态
            local state = humanoid:GetState()
            if state == Enum.HumanoidStateType.Dead then
                break
            end
            
            -- 执行击杀
            local targetRoot = getRoot(targetChar)
            if targetRoot then
                pcall(function()
                    -- 触发触碰事件两次（进入和离开）来造成伤害
                    firetouchinterestFunc(handle, targetRoot, 0)
                    firetouchinterestFunc(handle, targetRoot, 1)
                end)
            end
        end
        
        -- 如果没有更多有效目标，停止
        if #currentTargets == 0 then
            if currentLoop then currentLoop:Disconnect() end
            currentLoop = nil
            isActive = false
        end
    end)
    
    -- 存储连接以便unload
    table.insert(connections, currentLoop)
    
    return true
end

-- 停止击杀
local function stopKill()
    isActive = false
    if currentLoop then
        currentLoop:Disconnect()
        currentLoop = nil
    end
    currentTargets = {}
    currentRange = math.huge
end

-- 清理所有连接
local function cleanupAll()
    stopKill()
    
    for _, conn in ipairs(connections) do
        if conn and conn.Disconnect then
            pcall(function() conn:Disconnect() end)
        end
    end
    connections = {}
end

-- 主要的 kill 函数（支持多种调用方式）
function HandleKillModule.kill(targets, range)
    -- 停止之前的运行
    stopKill()
    
    -- 解析距离
    local parsedRange = parseRange(range)
    
    -- 解析目标（支持字符串、玩家对象、表、以及 "All"）
    local playerList = parsePlayers(targets)
    
    if #playerList == 0 then
        return false
    end
    
    -- 验证是否有工具
    local char = LocalPlayer.Character
    if not char then return false end
    
    local hasTool = false
    for _, child in pairs(char:GetChildren()) do
        if child:IsA("Tool") then
            local handle = child:FindFirstChild("Handle")
            if handle then
                hasTool = true
                break
            end
        end
    end
    
    if not hasTool then
        return false
    end
    
    -- 检查 firetouchinterest 可用性
    if not getFireTouchInterest() then
        return false
    end
    
    -- 开始击杀循环
    return startKillLoop(playerList, parsedRange)
end

-- 停止当前击杀
function HandleKillModule.stop()
    stopKill()
end

-- 检查是否正在运行
function HandleKillModule.isRunning()
    return isActive
end

-- 获取当前目标数量
function HandleKillModule.getTargetCount()
    return #currentTargets
end

-- 卸载整个模块
function HandleKillModule.unload()
    cleanupAll()
    
    -- 清空模块中的所有函数
    HandleKillModule.kill = nil
    HandleKillModule.stop = nil
    HandleKillModule.isRunning = nil
    HandleKillModule.getTargetCount = nil
    HandleKillModule.unload = nil
    
    -- 清空内部状态
    isActive = false
    currentLoop = nil
    currentTargets = {}
    currentRange = math.huge
    connections = {}
end

return HandleKillModule