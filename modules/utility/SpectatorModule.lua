-- 模块化封装旁观功能
local SpectatorModule = {}

-- 服务引用
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService")) -- 用于按钮动画

-- 核心变量（模块内私有）
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local spectatorPlayers = {}
local currentSpectateIndex = 0
local isSpectating = false

-- GUI相关变量（用于后续清理）
local screenGui = nil
local buttonFrame = nil
local prevButton = nil
local nextButton = nil

-- 事件连接引用（用于unload时断开）
local renderSteppedConn = nil
local playerAddedConn = nil
local playerRemovingConn = nil
local prevClickConn = nil
local nextClickConn = nil
local keybindConn = nil

-- 按钮样式配置（方便统一修改）
local BUTTON_STYLE = {
    NormalColor = Color3.new(0.2, 0.4, 0.8),   -- 正常状态颜色
    HoverColor = Color3.new(0.3, 0.5, 0.9),    -- 悬停状态颜色
    PressColor = Color3.new(0.1, 0.3, 0.7),    -- 点击状态颜色
    DisabledColor = Color3.new(0.3, 0.3, 0.3), -- 禁用状态颜色
    TextColor = Color3.new(1, 1, 1),           -- 文字颜色
    CornerRadius = UDim.new(0, 8),              -- 圆角大小
    Font = Enum.Font.SourceSansBold,
    TextSize = 18
}

-- 创建GUI（私有方法）
local function createGUI()
    -- 主容器
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SpectatorGUI"
    if syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = cloneref(game.CoreGui)
    else
        screenGui.Parent = gethui and gethui() or cloneref(game.CoreGui)
    end
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- 按钮容器（上移避开物品栏，原-60改为-110）
    buttonFrame = Instance.new("Frame")
    buttonFrame.Name = "ButtonFrame"
    buttonFrame.Size = UDim2.new(0, 300, 0, 50)
    buttonFrame.Position = UDim2.new(0.5, -150, 1, -110) -- 上移50像素，避开物品栏
    buttonFrame.BackgroundTransparency = 1 -- 完全透明背景
    buttonFrame.BorderSizePixel = 0
    buttonFrame.Visible = false -- 初始隐藏
    buttonFrame.Parent = screenGui

    -- 创建通用按钮的方法（复用逻辑）
    local function createButton(name, text, position)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Size = UDim2.new(0, 140, 0, 40)
        button.Position = position
        button.BackgroundColor3 = BUTTON_STYLE.DisabledColor
        button.Text = text
        button.TextColor3 = BUTTON_STYLE.TextColor
        button.Font = BUTTON_STYLE.Font
        button.TextSize = BUTTON_STYLE.TextSize
        button.AutoButtonColor = false -- 禁用默认样式，自定义反馈
        button.Active = false -- 初始禁用
        button.Parent = buttonFrame

        -- 添加圆角
        local corner = Instance.new("UICorner")
        corner.CornerRadius = BUTTON_STYLE.CornerRadius
        corner.Parent = button

        -- 悬停/点击反馈
        button.MouseEnter:Connect(function()
            if button.Active then
                button.BackgroundColor3 = BUTTON_STYLE.HoverColor
            end
        end)
        button.MouseLeave:Connect(function()
            if button.Active then
                button.BackgroundColor3 = BUTTON_STYLE.NormalColor
            else
                button.BackgroundColor3 = BUTTON_STYLE.DisabledColor
            end
        end)
        button.MouseButton1Down:Connect(function()
            if button.Active then
                button.BackgroundColor3 = BUTTON_STYLE.PressColor
            end
        end)
        button.MouseButton1Up:Connect(function()
            if button.Active then
                button.BackgroundColor3 = BUTTON_STYLE.HoverColor
            end
        end)

        return button
    end

    -- 创建上一个/下一个按钮
    prevButton = createButton("PreviousButton", "上一个人", UDim2.new(0, 5, 0, 5))
    nextButton = createButton("NextButton", "下一个人", UDim2.new(0, 155, 0, 5))
end

-- 刷新可旁观玩家列表（私有方法）
local function refreshSpectatorPlayers()
    spectatorPlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
            table.insert(spectatorPlayers, player)
        end
    end

    if currentSpectateIndex > #spectatorPlayers then
        currentSpectateIndex = 0
    end

    -- 更新按钮状态
    local hasPlayers = #spectatorPlayers > 0
    prevButton.Active = isSpectating and hasPlayers
    nextButton.Active = isSpectating and hasPlayers
    
    -- 更新按钮颜色（禁用/启用）
    prevButton.BackgroundColor3 = prevButton.Active and BUTTON_STYLE.NormalColor or BUTTON_STYLE.DisabledColor
    nextButton.BackgroundColor3 = nextButton.Active and BUTTON_STYLE.NormalColor or BUTTON_STYLE.DisabledColor
end

-- 切换视角（私有方法）
local function switchToPlayer(index)
    if not isSpectating then return end
    if #spectatorPlayers == 0 then
        currentSpectateIndex = 0
        camera.CameraSubject = localPlayer.Character and localPlayer.Character.Humanoid or camera
        return
    end

    -- 循环切换逻辑
    currentSpectateIndex = index
    if currentSpectateIndex < 1 then
        currentSpectateIndex = #spectatorPlayers
    elseif currentSpectateIndex > #spectatorPlayers then
        currentSpectateIndex = 1
    end

    local targetPlayer = spectatorPlayers[currentSpectateIndex]
    if targetPlayer and targetPlayer.Character then
        local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            camera.CameraSubject = humanoid
            camera.CameraType = Enum.CameraType.Custom
        end
    end
end

-- 公开方法：开启旁观
function SpectatorModule.enable()
    SpectatorModule.start()
end

function SpectatorModule.disable()
    SpectatorModule.close()
end

function SpectatorModule.start()
    if isSpectating then return end
    isSpectating = true

    -- 初始化GUI（如果未创建）
    if not screenGui then
        createGUI()
    end

    -- 绑定事件（防止重复绑定）
    if not playerAddedConn then
        playerAddedConn = Players.PlayerAdded:Connect(refreshSpectatorPlayers)
    end
    if not playerRemovingConn then
        playerRemovingConn = Players.PlayerRemoving:Connect(refreshSpectatorPlayers)
    end
    if not prevClickConn then
        prevClickConn = prevButton.MouseButton1Click:Connect(function()
            switchToPlayer(currentSpectateIndex - 1)
        end)
    end
    if not nextClickConn then
        nextClickConn = nextButton.MouseButton1Click:Connect(function()
            switchToPlayer(currentSpectateIndex + 1)
        end)
    end
    if not renderSteppedConn then
        renderSteppedConn = RunService.RenderStepped:Connect(function()
            if not isSpectating then return end
            refreshSpectatorPlayers()

            -- 检测当前旁观玩家角色是否有效
            local currentPlayer = spectatorPlayers[currentSpectateIndex]
            if currentPlayer and (not currentPlayer.Character or not currentPlayer.Character:FindFirstChild("Humanoid")) then
                switchToPlayer(currentSpectateIndex + 1)
            end
        end)
    end

    -- 刷新玩家列表并显示按钮
    refreshSpectatorPlayers()
    buttonFrame.Visible = true

    -- 切换到第一个玩家
    if #spectatorPlayers > 0 then
        switchToPlayer(1)
    end
end

-- 公开方法：关闭旁观
function SpectatorModule.close()
    if not isSpectating then return end
    isSpectating = false
    currentSpectateIndex = 0

    -- 恢复自身视角
    if localPlayer.Character then
        local humanoid = localPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            camera.CameraSubject = humanoid
        end
    end
    camera.CameraType = Enum.CameraType.Custom

    -- 隐藏按钮
    if buttonFrame then
        buttonFrame.Visible = false
    end

    -- 禁用按钮
    if prevButton then prevButton.Active = false end
    if nextButton then nextButton.Active = false end
end

-- 公开方法：卸载整个模块（彻底清理）
function SpectatorModule.unload()
    -- 先关闭旁观
    SpectatorModule.close()

    -- 断开所有事件连接
    if renderSteppedConn then
        renderSteppedConn:Disconnect()
        renderSteppedConn = nil
    end
    if playerAddedConn then
        playerAddedConn:Disconnect()
        playerAddedConn = nil
    end
    if playerRemovingConn then
        playerRemovingConn:Disconnect()
        playerRemovingConn = nil
    end
    if prevClickConn then
        prevClickConn:Disconnect()
        prevClickConn = nil
    end
    if nextClickConn then
        nextClickConn:Disconnect()
        nextClickConn = nil
    end
    if keybindConn then
        keybindConn:Disconnect()
        keybindConn = nil
    end

    -- 删除所有GUI
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
        buttonFrame = nil
        prevButton = nil
        nextButton = nil
    end
end

-- 返回模块，供外部调用
return SpectatorModule