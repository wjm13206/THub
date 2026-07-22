-- 死亡球脚本模块（自执行，暴露全局）
local DeathBallScript = {}
DeathBallScript.__index = DeathBallScript

-- 私有变量
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local Workspace = cloneref(game:GetService("Workspace"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local VirtualInputManager = cloneref(game:GetService("VirtualInputManager"))
local ContextActionService = cloneref(game:GetService("ContextActionService"))
local RunService = cloneref(game:GetService("RunService"))

local LocalPlayer = Players.LocalPlayer

-- 模块内部变量
local connections = {}
local mainGui = nil
local statusText = nil
local distanceText = nil
local targetBall = nil
local isEnabled = false
local character = nil
local rootPart = nil

-- 查找球的函数
local function findBall()
    for _, child in pairs(Workspace:GetChildren()) do
        if child.Name == "Part" and child:IsA("BasePart") then
            return child
        end
    end
    return nil
end

-- 更新目标球引用
local function updateBallReference()
    targetBall = findBall()
end

-- 创建UI
local function createUI()
    if mainGui then return end
    
    mainGui = Instance.new("ScreenGui")
    if syn and syn.protect_gui then
        syn.protect_gui(mainGui)
        mainGui.Parent = cloneref(game.CoreGui)
    else
        mainGui.Parent = gethui and gethui() or cloneref(game.CoreGui)
    end
    
    statusText = Instance.new("TextLabel")
    statusText.Parent = mainGui
    statusText.Size = UDim2.new(0, 200, 0, 30)
    statusText.Position = UDim2.new(0.5, -100, 0.1, 0)
    statusText.BackgroundTransparency = 1
    statusText.Text = "游戏未开始"
    statusText.TextColor3 = Color3.fromRGB(230, 230, 250)
    statusText.TextSize = 25
    statusText.Font = Enum.Font.GothamBold
    
    distanceText = Instance.new("TextLabel")
    distanceText.Parent = mainGui
    distanceText.Size = UDim2.new(0, 200, 0, 20)
    distanceText.Position = UDim2.new(0.5, -100, 0.14, 0)
    distanceText.BackgroundTransparency = 1
    distanceText.Text = ""
    distanceText.TextColor3 = Color3.fromRGB(166, 166, 166)
    distanceText.TextSize = 15
end

-- 隐藏UI
local function hideUI()
    if mainGui then
        mainGui.Enabled = false
    end
end

-- 显示UI
local function showUI()
    if mainGui then
        mainGui.Enabled = true
    end
end

-- 销毁UI
local function destroyUI()
    if mainGui then
        mainGui:Destroy()
        mainGui = nil
        statusText = nil
        distanceText = nil
    end
end

-- R键传送功能（改进版：先按F，再瞬移，再返回）
local function teleportToBallAndBack()
    -- 检查目标球
    if not targetBall or not targetBall:IsDescendantOf(Workspace) then
        return
    end
    
    -- 检查角色部件
    if not rootPart or not rootPart.Parent then
        return
    end
    
    local currentCFrame = rootPart.CFrame
    local ballCFrame = targetBall.CFrame
    
    -- 计算球的半径（假设球为立方体，可根据实际情况微调）
    local ballSize = targetBall.Size
    local radius = (ballSize.X + ballSize.Y + ballSize.Z) / 6  -- 近似半径
    local offset = radius + 2  -- 玩家与球表面的距离（2是玩家碰撞箱半径的估算）
    
    -- 1. 先按下F键，进入格挡状态
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
    -- 等待一小段时间，让格挡动作完全启动（可调整等待帧数或时间）
    for _ = 1, 3 do  -- 等待3帧，约0.05秒（60帧下）
        RunService.Heartbeat:Wait()
    end
    
    -- 2. 计算传送位置：从球心沿玩家当前方向偏移，确保玩家面向球
    local direction = (currentCFrame.Position - ballCFrame.Position).Unit
    local newPos = ballCFrame.Position + direction * offset
    local newCFrame = CFrame.new(newPos, ballCFrame.Position)  -- 面向球心
    
    -- 3. 瞬移到该位置
    rootPart.CFrame = newCFrame
    
    -- 4. 再等待一段时间，让碰撞检测生效，确保球被反弹
    for _ = 1, 3 do
        RunService.Heartbeat:Wait()
    end
    
    -- 5. 松开F键（可选，如果游戏不需要保持按下，可以不松；但这里模拟完整按键）
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    
    -- 6. 立即传送回原位置
    rootPart.CFrame = currentCFrame
end

-- UI更新函数
local function updateUI()
    local ball = targetBall
    local playerChar = LocalPlayer.Character
    local playerPos = playerChar and playerChar:FindFirstChild("HumanoidRootPart")
    
    if not ball or not playerPos then
        if statusText then
            statusText.Text = "游戏未开始"
            statusText.TextColor3 = Color3.fromRGB(230, 230, 250)
        end
        if distanceText then
            distanceText.Text = ""
        end
        return
    end
    
    local isSpectating = playerPos.Position.Z < -767.55 and playerPos.Position.Y > 279.17
    
    if isSpectating then
        if statusText then
            statusText.Text = "观战中"
            statusText.TextColor3 = Color3.fromRGB(230, 230, 250)
        end
        if distanceText then
            distanceText.Text = ""
        end
    else
        local isLocked = ball.Highlight and ball.Highlight.FillColor ~= Color3.new(1, 1, 1)
        if statusText then
            statusText.Text = isLocked and "已被球锁定" or "未被球锁定"
            statusText.TextColor3 = isLocked and Color3.fromRGB(238, 17, 17) or Color3.fromRGB(17, 238, 17)
        end
        
        local distance = (ball.Position - playerPos.Position).Magnitude
        if distanceText then
            distanceText.Text = string.format("%.0f", distance)
        end
    end
end

-- 启用模块
function DeathBallScript:Enable()
    if isEnabled then
        return
    end
    
    -- 获取角色引用
    character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    rootPart = character:WaitForChild("HumanoidRootPart")
    
    -- 创建并显示UI
    createUI()
    showUI()
    
    -- 初始化球引用
    updateBallReference()
    
    -- 设置监听器
    table.insert(connections, Workspace.ChildAdded:Connect(function(child)
        if child.Name == "Part" and child:IsA("BasePart") then
            targetBall = child
        end
    end))
    
    table.insert(connections, Workspace.ChildRemoved:Connect(function(child)
        if child == targetBall then
            targetBall = nil
        end
    end))
    
    local bindConnection = ContextActionService:BindAction("TeleportToBall", function(actionName, inputState)
        if inputState == Enum.UserInputState.Begin then
            teleportToBallAndBack()
        end
        return Enum.ContextActionResult.Pass
    end, false, Enum.KeyCode.R)
    table.insert(connections, bindConnection)
    
    table.insert(connections, RunService.Heartbeat:Connect(function()
        if isEnabled then
            updateUI()
        end
    end))
    
    table.insert(connections, LocalPlayer.CharacterAdded:Connect(function(newChar)
        if isEnabled then
            character = newChar
            rootPart = character:WaitForChild("HumanoidRootPart")
        end
    end))
    
    isEnabled = true
end

-- 禁用模块
function DeathBallScript:Disable()
    if not isEnabled then
        return
    end
    
    -- 断开所有连接
    for _, connection in ipairs(connections) do
        if connection then
            if connection.Disconnect then
                connection:Disconnect()
            elseif connection.Unbind then
                connection:Unbind()
            end
        end
    end
    connections = {}
    
    -- 隐藏UI
    hideUI()
    
    isEnabled = false
    character = nil
    rootPart = nil
    targetBall = nil
end

-- 卸载模块
function DeathBallScript:Unload()
    self:Disable()
    destroyUI()
    
    -- 清理ContextActionService绑定（以防万一）
    ContextActionService:UnbindAction("TeleportToBall")
    
    -- 重置全局标记
    _G.DeathBallScriptLoaded = false
end

-- 将模块暴露到全局变量
_G.DeathBallScript = DeathBallScript

-- 如果作为 require 的模块，返回自身
return DeathBallScript