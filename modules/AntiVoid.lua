-- AntiVoid 模块
local AntiVoid = {}

-- 私有状态
local enabled = false
local connections = {}  -- 存储所有连接的字典
local currentCharacter = nil

-- Services
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local LocalPlayer = Players.LocalPlayer

-- 检测是否有其他人持有相同的 Handle
local function toolMatch(Handle)
    local allPlayers = Players:GetPlayers()
    for i = 1, #allPlayers do
        local Player = allPlayers[i]
        if Player == LocalPlayer then
            continue
        end
        
        -- 确保角色存在
        local Character = Player.Character
        if not Character then
            continue
        end
        
        local RightArm = Character:FindFirstChild("Right Arm")
        if not RightArm then
            continue
        end
        
        local RightGrip = RightArm:FindFirstChild("RightGrip")
        if RightGrip and RightGrip.Part1 == Handle then
            return Player
        end
    end
    return nil
end

-- 为单个角色设置监听
local function setupCharacter(character)
    if not enabled then return end
    
    local RightArm = character:WaitForChild("Right Arm")
    
    local conn = RightArm.ChildAdded:Connect(function(child)
        if child:IsA("Weld") and child.Name == "RightGrip" and enabled then
            local ConnectedHandle = child.Part1
            local matched = toolMatch(ConnectedHandle)
            
            if matched then
                ConnectedHandle.Parent:Destroy()
                print(matched.Name, "想要甩飞你但被阻止了!")
            end
        end
    end)
    
    -- 存储连接，方便后续清理
    if not connections[character] then
        connections[character] = {}
    end
    table.insert(connections[character], conn)
end

-- 角色变化时的处理
local function onCharacterAdded(character)
    if not enabled then return end
    
    -- 清理旧角色的连接
    if currentCharacter and connections[currentCharacter] then
        for _, conn in ipairs(connections[currentCharacter]) do
            conn:Disconnect()
        end
        connections[currentCharacter] = nil
    end
    
    currentCharacter = character
    setupCharacter(character)
end

-- 清理所有连接
local function clearAllConnections()
    for character, connList in pairs(connections) do
        for _, conn in ipairs(connList) do
            conn:Disconnect()
        end
    end
    connections = {}
    currentCharacter = nil
end

-- 启用 AntiVoid
function AntiVoid.enable()
    if enabled then return end
    enabled = true
    
    -- 如果当前有角色，立即设置监听
    local character = LocalPlayer.Character
    if character then
        onCharacterAdded(character)
    end
    
    -- 监听角色重生
    local charAddedConn = LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
    connections["_charAdded"] = {charAddedConn}
end

-- 禁用 AntiVoid（保留监听，但不再执行防御逻辑）
function AntiVoid.disable()
    if not enabled then return end
    enabled = false
    
    -- 不清除连接，只是停止响应，这样下次 enable 时无需重新设置
    -- 注意：实际防御逻辑在 setupCharacter 的回调中已经检查 enabled 标志
end

-- 完全卸载 AntiVoid
function AntiVoid.unload()
    enabled = false
    clearAllConnections()
    
    -- 清空模块方法，防止误调用
    AntiVoid.enable = nil
    AntiVoid.disable = nil
    AntiVoid.unload = nil
end

return AntiVoid