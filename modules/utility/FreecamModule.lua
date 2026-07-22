-- FreeCam 模块 v1.3.1
-- 优化函数定义顺序，解决调用问题

local FreeCam = {}

-- 服务引用
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))

-- 私有变量
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 状态变量
local freecamEnabled = false      -- 自由相机是否启用
local moduleEnabled = false        -- 模块总开关
local cameraRotation = Vector2.new()
local freecamConnection = nil
local charLock = nil
local moveVector = Vector3.new()

-- 快捷键配置
local currentKeybind = Enum.KeyCode.F

-- 事件连接存储
local eventConnections = {}

-- 配置
local DEFAULT_SPEED = 1.0
local cameraSpeed = DEFAULT_SPEED
local lookSensitivity = 50
local WHEEL_SENSITIVITY = 0.1

-- ========== 辅助函数 ==========

local function getRootPart()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart") or nil
end

-- ========== 角色锁定函数 ==========

local function lockCharacter()
    local root = getRootPart()
    if not root or charLock then return end
    
    charLock = Instance.new("BodyPosition")
    charLock.Name = "FreeCamLock"
    charLock.Position = root.Position
    charLock.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    charLock.D = 100
    charLock.P = 5000
    charLock.Parent = root
end

local function unlockCharacter()
    if charLock then
        charLock:Destroy()
        charLock = nil
    end
end

-- ========== 速度调整函数 ==========

local function adjustSpeedWithMouseWheel(delta)
    if not freecamEnabled then return end
    
    if delta > 0 then
        cameraSpeed = cameraSpeed * (1 + WHEEL_SENSITIVITY)
    else
        cameraSpeed = cameraSpeed * (1 - WHEEL_SENSITIVITY)
    end
    
    cameraSpeed = math.max(0, cameraSpeed)
end

-- ========== 自由相机更新函数 ==========

local function updateFreecam(dt)
    if not freecamEnabled then return end
    
    local moveSpeed = cameraSpeed * 50
    local currentMoveVector = moveVector
    
    if UserInputService:IsKeyDown(Enum.KeyCode.E) then
        currentMoveVector += Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
        currentMoveVector += Vector3.new(0, -1, 0)
    end
    
    local mouseDelta = UserInputService:GetMouseDelta()
    local sensitivity = lookSensitivity * 0.004
    
    cameraRotation += Vector2.new(
        -math.rad(mouseDelta.Y * sensitivity),
        -math.rad(mouseDelta.X * sensitivity)
    )
    
    cameraRotation = Vector2.new(
        math.clamp(cameraRotation.X, -math.pi/2, math.pi/2),
        cameraRotation.Y
    )
    
    local rotation = CFrame.fromEulerAnglesYXZ(cameraRotation.X, cameraRotation.Y, 0)
    local position = Camera.CFrame.Position
    
    if currentMoveVector.Magnitude > 0.01 and cameraSpeed > 0 then
        position += rotation:VectorToWorldSpace(currentMoveVector.Unit) * moveSpeed * dt
    end
    
    Camera.CFrame = CFrame.new(position) * rotation
end

-- ========== 内部启用/禁用函数 ==========

local function internalEnable()
    if freecamEnabled then return end
    
    freecamEnabled = true
    cameraSpeed = DEFAULT_SPEED
    
    lockCharacter()
    
    local _, yaw, pitch = Camera.CFrame:ToEulerAnglesYXZ()
    cameraRotation = Vector2.new(pitch, yaw)
    
    Camera.CameraType = Enum.CameraType.Scriptable
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    
    freecamConnection = RunService.RenderStepped:Connect(updateFreecam)
    
    return true
end

local function internalDisable()
    if not freecamEnabled then return end
    
    freecamEnabled = false
    
    if freecamConnection then
        freecamConnection:Disconnect()
        freecamConnection = nil
    end
    
    unlockCharacter()
    
    Camera.CameraType = Enum.CameraType.Custom
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    
    moveVector = Vector3.new()
    
    return true
end

-- ========== 模块启用状态函数 ==========

local function setModuleEnabled(value)
    if moduleEnabled == value then return end
    
    moduleEnabled = value
    
    if value then
    else
        -- 禁用模块时，如果自由相机正在运行，先关闭它
        if freecamEnabled then
            internalDisable()
        end
    end
end

-- ========== 事件处理函数 ==========

local function onKeyPress(input, gameProcessed)
    -- 模块未启用时忽略所有输入
    if not moduleEnabled then return end
    if gameProcessed or UserInputService:GetFocusedTextBox() then return end
    
    -- 使用当前设置的快捷键切换自由相机状态
    if input.KeyCode == currentKeybind then
        if freecamEnabled then
            internalDisable()
        else
            internalEnable()
        end
        return
    end
    
    -- 自由相机未启用时忽略移动按键
    if not freecamEnabled then return end
    
    local key = input.KeyCode
    if key == Enum.KeyCode.W then
        moveVector += Vector3.new(0, 0, -1)
    elseif key == Enum.KeyCode.S then
        moveVector += Vector3.new(0, 0, 1)
    elseif key == Enum.KeyCode.A then
        moveVector += Vector3.new(-1, 0, 0)
    elseif key == Enum.KeyCode.D then
        moveVector += Vector3.new(1, 0, 0)
    end
end

local function onKeyRelease(input, gameProcessed)
    -- 模块或自由相机未启用时忽略
    if not moduleEnabled or not freecamEnabled then return end
    if gameProcessed then return end
    
    local key = input.KeyCode
    if key == Enum.KeyCode.W then
        moveVector -= Vector3.new(0, 0, -1)
    elseif key == Enum.KeyCode.S then
        moveVector -= Vector3.new(0, 0, 1)
    elseif key == Enum.KeyCode.A then
        moveVector -= Vector3.new(-1, 0, 0)
    elseif key == Enum.KeyCode.D then
        moveVector -= Vector3.new(1, 0, 0)
    end
end

local function onMouseWheel(input, gameProcessed)
    -- 模块或自由相机未启用时忽略
    if not moduleEnabled or not freecamEnabled then return end
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        adjustSpeedWithMouseWheel(input.Position.Z)
    end
end

local function onCharacterAdded(character)
    task.wait(0.5)
    
    if freecamEnabled then
        internalDisable()  -- 角色重生时自动关闭自由相机
    else
        unlockCharacter()
    end
    
    local humanoid = character:WaitForChild("Humanoid", 2)
    if humanoid then
        Camera.CameraSubject = humanoid
        Camera.CameraType = Enum.CameraType.Custom
    end
end

local function onCharacterRemoving()
    if freecamEnabled then
        internalDisable()  -- 角色移除时自动关闭自由相机
    else
        unlockCharacter()
    end
end

-- ========== 公共方法和属性 ==========

-- 设置元表以实现属性控制
setmetatable(FreeCam, {
    __newindex = function(self, key, value)
        if key == "enable" then
            -- 模块未启用时，不允许操作自由相机
            if not moduleEnabled then
                -- warn("无法操作: FreeCam 模块当前未启用")
                return
            end
            if value then
                internalEnable()
            else
                internalDisable()
            end
        elseif key == "freecamenable" then
            setModuleEnabled(value)
        else
            rawset(self, key, value)
        end
    end,
    
    __index = function(self, key)
        if key == "enable" then
            return freecamEnabled
        elseif key == "freecamenable" then
            return moduleEnabled
        end
        return rawget(self, key)
    end
})

-- 获取当前快捷键
function FreeCam.getKeybind()
    return currentKeybind
end

-- 设置新快捷键
function FreeCam.setKeybind(newKeybind)
    -- 模块未启用时不允许设置快捷键
    if not moduleEnabled then
        -- warn("无法设置: FreeCam 模块当前未启用")
        return false
    end
    
    if not newKeybind or typeof(newKeybind) ~= "EnumItem" or newKeybind.EnumType ~= Enum.KeyCode then
        -- warn("无效的快捷键设置，请传入有效的 Enum.KeyCode 值")
        return false
    end
    
    local oldKeybind = currentKeybind
    currentKeybind = newKeybind
    
    return true
end

-- 获取当前速度
function FreeCam.getSpeed()
    return cameraSpeed
end

-- 完全卸载模块
function FreeCam.unload()
    -- 关闭自由相机
    internalDisable()
    
    -- 断开所有事件连接
    for _, connection in pairs(eventConnections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    table.clear(eventConnections)
    
    -- 清理角色锁定
    unlockCharacter()
    
    -- 重置所有状态变量
    freecamEnabled = false
    moduleEnabled = false  -- 模块也设为禁用状态
    cameraRotation = Vector2.new()
    moveVector = Vector3.new()
    cameraSpeed = DEFAULT_SPEED
    
    -- 恢复默认快捷键
    currentKeybind = Enum.KeyCode.F
    
    -- 确保相机控制权交还引擎
    if Camera then
        Camera.CameraType = Enum.CameraType.Custom
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                Camera.CameraSubject = humanoid
            end
        end
    end
    
    -- 恢复鼠标行为
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    
    return true
end

-- ========== 模块初始化 ==========

-- 设置事件监听
table.insert(eventConnections, UserInputService.InputBegan:Connect(onKeyPress))
table.insert(eventConnections, UserInputService.InputEnded:Connect(onKeyRelease))
table.insert(eventConnections, UserInputService.InputChanged:Connect(onMouseWheel))
table.insert(eventConnections, LocalPlayer.CharacterAdded:Connect(onCharacterAdded))
table.insert(eventConnections, LocalPlayer.CharacterRemoving:Connect(onCharacterRemoving))

-- 模块信息
FreeCam.version = "1.3.1"
FreeCam.author = "FreeCam Module"
FreeCam.description = "优化函数定义顺序，解决调用顺序问题"

return FreeCam