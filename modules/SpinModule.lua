-- Spin 模块
-- 让角色高速旋转
-- 
-- 使用方法：
--   local spin = loadstring(game:HttpGet("raw_url_here"))()
--   
--   -- 启用旋转（默认速度20）
--   spin.enable()
--   
--   -- 启用旋转并设置速度（速度越大转得越快）
--   spin.enable(50)
--   
--   -- 启用旋转并设置速度（速度越大转得越快）
--   spin.enable(100)
--   
--   -- 禁用旋转
--   spin.disable()
--   
--   -- 检查是否正在旋转
--   print(spin.isEnabled())
--   
--   -- 获取当前旋转速度
--   print(spin.getSpeed())
--   
--   -- 设置旋转速度（运行时调整）
--   spin.setSpeed(200)
--   
--   -- 卸载整个模块
--   spin.unload()

local SpinModule = {}

-- Services
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local LocalPlayer = Players.LocalPlayer

-- 内部状态
local isActive = false
local currentSpinBody = nil
local currentSpeed = 20
local currentCharacter = nil
local characterAddedConn = nil

-- 存储所有连接，用于unload
local connections = {}

-- 获取角色的根部件（HumanoidRootPart）
local function getRoot(char)
    if char and char:FindFirstChildOfClass("Humanoid") then
        return char:FindFirstChildOfClass("Humanoid").RootPart
    end
    return nil
end

-- 清理旋转体
local function cleanupSpinBody()
    if currentSpinBody and currentSpinBody.Parent then
        pcall(function()
            currentSpinBody:Destroy()
        end)
    end
    currentSpinBody = nil
end

-- 停止旋转
local function stopSpin()
    isActive = false
    cleanupSpinBody()
    
    -- 断开角色重生监听
    if characterAddedConn then
        characterAddedConn:Disconnect()
        characterAddedConn = nil
    end
    
    currentCharacter = nil
end

-- 开始旋转
local function startSpin(speed)
    -- 停止当前旋转
    stopSpin()
    
    -- 设置速度
    if speed and type(speed) == "number" and speed > 0 then
        currentSpeed = speed
    end
    
    local char = LocalPlayer.Character
    if not char then
        -- 如果角色不存在，等待角色出现
        characterAddedConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
            characterAddedConn:Disconnect()
            characterAddedConn = nil
            startSpin(currentSpeed)
        end)
        return false
    end
    
    local root = getRoot(char)
    if not root then
        return false
    end
    
    currentCharacter = char
    isActive = true
    
    -- 创建旋转体（BodyAngularVelocity）
    -- BodyAngularVelocity 可以让部件绕指定轴持续旋转
    currentSpinBody = Instance.new("BodyAngularVelocity")
    currentSpinBody.Name = "__SpinVelocity"
    currentSpinBody.Parent = root
    currentSpinBody.MaxTorque = Vector3.new(0, math.huge, 0)  -- 只允许Y轴旋转
    currentSpinBody.AngularVelocity = Vector3.new(0, currentSpeed, 0)  -- Y轴旋转速度
    
    -- 监听角色重生
    characterAddedConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
        currentCharacter = newChar
        local newRoot = getRoot(newChar)
        if newRoot and isActive then
            -- 重新创建旋转体
            local newSpinBody = Instance.new("BodyAngularVelocity")
            newSpinBody.Name = "__SpinVelocity"
            newSpinBody.Parent = newRoot
            newSpinBody.MaxTorque = Vector3.new(0, math.huge, 0)
            newSpinBody.AngularVelocity = Vector3.new(0, currentSpeed, 0)
            
            -- 替换旧的
            cleanupSpinBody()
            currentSpinBody = newSpinBody
        end
    end)
    
    table.insert(connections, characterAddedConn)
    
    return true
end

-- 更新旋转速度
local function updateSpinSpeed(speed)
    if currentSpinBody and currentSpinBody.Parent then
        currentSpinBody.AngularVelocity = Vector3.new(0, speed, 0)
    end
end

-- 清理所有连接
local function cleanupAll()
    stopSpin()
    
    for _, conn in ipairs(connections) do
        if conn and conn.Disconnect then
            pcall(function() conn:Disconnect() end)
        end
    end
    connections = {}
end

-- 启用旋转
function SpinModule.enable(speed)
    if isActive then
        -- 如果已经在旋转，可以更新速度
        if speed and type(speed) == "number" and speed > 0 then
            currentSpeed = speed
            updateSpinSpeed(currentSpeed)
        end
        return true
    end
    return startSpin(speed)
end

-- 禁用旋转
function SpinModule.disable()
    if not isActive then
        return false
    end
    stopSpin()
    return true
end

-- 检查是否正在旋转
function SpinModule.isEnabled()
    return isActive
end

-- 获取当前旋转速度
function SpinModule.getSpeed()
    return currentSpeed
end

-- 设置旋转速度（运行时调整）
function SpinModule.setSpeed(speed)
    if type(speed) ~= "number" or speed <= 0 then
        return false
    end
    
    currentSpeed = speed
    
    if isActive then
        updateSpinSpeed(currentSpeed)
    end
    
    return true
end

-- 卸载整个模块
function SpinModule.unload()
    cleanupAll()
    
    -- 清空模块中的所有函数
    SpinModule.enable = nil
    SpinModule.disable = nil
    SpinModule.isEnabled = nil
    SpinModule.getSpeed = nil
    SpinModule.setSpeed = nil
    SpinModule.unload = nil
    
    -- 清空内部状态
    isActive = false
    currentSpinBody = nil
    currentSpeed = 20
    currentCharacter = nil
    characterAddedConn = nil
    connections = {}
end

return SpinModule