local module = {}

local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local LocalPlayer = Players.LocalPlayer
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))

-- 默认速度依照原脚本 (50)
local CFspeed = 50
local enable = false
local CFloop = nil
local bindKey = Enum.KeyCode.F
local connection = nil
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local function toggleCFrameFly()
    if enable then
        -- 关闭逻辑 (完全复刻 uncframefly 源码)
        enable = false
        if CFloop then
            CFloop:Disconnect()
            CFloop = nil
        end
        
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass('Humanoid')
            if humanoid then
                humanoid.PlatformStand = false
            end
            
            local Head = character:FindFirstChild("Head")
            if Head then
                Head.Anchored = false
            end
        end
    else 
        -- 开启逻辑 (完全复刻 cframefly 源码)
        enable = true
        local character = LocalPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChildOfClass('Humanoid')
        if not humanoid then return end
        
        humanoid.PlatformStand = true
        local Head = character:WaitForChild("Head")
        Head.Anchored = true
        
        if CFloop then CFloop:Disconnect() end
        
        -- 【核心】：绝对不改动原版的速度和CFrame计算方式！
        CFloop = RunService.Heartbeat:Connect(function(deltaTime)
            -- 原版源码逻辑：获取按键方向并乘以速度和帧率
            local moveDirection = humanoid.MoveDirection * (CFspeed * deltaTime)
            local headCFrame = Head.CFrame
            local camera = workspace.CurrentCamera
            local cameraCFrame = camera.CFrame
            local cameraOffset = headCFrame:ToObjectSpace(cameraCFrame).Position
            
            -- 计算相机偏移
            cameraCFrame = cameraCFrame * CFrame.new(-cameraOffset.X, -cameraOffset.Y, -cameraOffset.Z + 1)
            local cameraPosition = cameraCFrame.Position
            local headPosition = headCFrame.Position

            -- 【核心】：原版精髓！将移动方向转换为相机视角的相对空间方向
            local objectSpaceVelocity = CFrame.new(cameraPosition, Vector3.new(headPosition.X, cameraPosition.Y, headPosition.Z)):VectorToObjectSpace(moveDirection)
            
            -- 更新头部CFrame
            Head.CFrame = CFrame.new(headPosition) * (cameraCFrame - cameraPosition) * CFrame.new(objectSpaceVelocity)
        end)
    end
end

-- 按键监听逻辑
local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == bindKey and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        toggleCFrameFly()
        return Enum.ContextActionResult.Sink
    end
end

-- 开启模块
function module.enable()
    if isMobile then
        if not enable then toggleCFrameFly() end
    else
        if connection then connection:Disconnect() end
        connection = UserInputService.InputBegan:Connect(onInputBegan)
    end
end

-- 关闭模块
function module.disable()
    if isMobile then
        if enable then toggleCFrameFly() end
    else
        if enable then toggleCFrameFly() end
        if connection then connection:Disconnect() end
    end
end

-- 卸载模块
function module.unload()
    if enable then toggleCFrameFly() end
    if connection then connection:Disconnect() end
end

-- 设定速度
function module.setspeed(speed)
    if type(speed) == "number" and speed >= 0 then
        CFspeed = speed
    end
end

-- 获得速度
function module.getspeed()
    return CFspeed
end

-- 获得绑定的按键
function module.getbindkey()
    return bindKey
end

-- 设定绑定的按键
function module.setbindkey(key)
    if typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
        bindKey = key
    end
end

return module