--!native
--!optimize 2
-- ChronixUI fork v4.3

local ChronixUI = {}
ChronixUI.Version = "4.3.0"
ChronixUI.Windows = {}
ChronixUI.Notifications = {}
ChronixUI.Settings = {
    ToggleKey = Enum.KeyCode.RightShift,
    ToggleKeyName = "RightShift",
    FirstHide = true,
    BackgroundBlur = true,
    BlurSize = 10,
    PrivacyMode = false,
}

-- 服务引用
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local RunService = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))
local SoundService = cloneref(game:GetService("SoundService"))
local ContextActionService = cloneref(game:GetService("ContextActionService"))
local Lighting = cloneref(game:GetService("Lighting"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- 缓存常用构造器
local _New = Instance.new
local _C3 = Color3.fromRGB
local _U2 = UDim2.new
local _U = UDim.new
local _V2 = Vector2.new
local _Tween = TweenService.Create
local _TInfo = TweenInfo.new
local _FontGotham = Enum.Font.Gotham
local _FontGothamBold = Enum.Font.GothamBold
local _FontGothamSemibold = Enum.Font.GothamSemibold
local _CornerRadius6 = UDim.new(0, 6)
local _CornerRadius4 = UDim.new(0, 4)
local _CornerRadius2 = UDim.new(0, 2)

local UIParticleSystem = loadstring(game:HttpGet("https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/UIParticleSystem.lua"))()

-- 多图标库集成模块
local IconModule = {
    DefaultType = "lucide",
    AvailableTypes = {
        "lucide", "solar", "craft", "geist", "sfsymbols", "gravity", "other",
    },
    Icons = {},
    Loaded = {},
    IsLoading = {},
}

function IconModule:LoadIconSet(iconType)
    if self.Loaded[iconType] or self.IsLoading[iconType] then return end
    self.IsLoading[iconType] = true
    task.spawn(function()
        local url = "https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/icons/" .. iconType .. "/Icons.lua"
        local data = game:HttpGet(url)
        if data then
            local success, icons = pcall(loadstring(data))
            if success and type(icons) == "table" then
                self.Icons[iconType] = icons
                self.Loaded[iconType] = true
            end
        end
        self.IsLoading[iconType] = false
    end)
end

function IconModule:LoadAll()
    for _, iconType in ipairs(self.AvailableTypes) do
        self:LoadIconSet(iconType)
    end
end

function IconModule:SetDefaultType(iconType)
    if table.find(self.AvailableTypes, iconType) then
        self.DefaultType = iconType
    end
end

function IconModule:GetIcon(iconName, iconType)
    iconType = iconType or self.DefaultType
    if not self.Loaded[iconType] then
        self:LoadIconSet(iconType)
        return nil
    end
    local iconSet = self.Icons[iconType]
    if not iconSet then return nil end
    if iconSet[iconName] and type(iconSet[iconName]) == "string" and iconSet[iconName]:find("rbxassetid://") then
        return iconSet[iconName]
    end
    if iconSet.Icons and iconSet.Icons[iconName] then
        return iconSet.Icons[iconName].Image
    end
    return nil
end

function IconModule:IsIconLoaded(iconName, iconType)
    iconType = iconType or self.DefaultType
    return self.Loaded[iconType] and self:GetIcon(iconName, iconType) ~= nil
end

function IconModule:CreateIcon(iconName, size, color, iconType)
    local iconId = self:GetIcon(iconName, iconType)
    if not iconId then return nil end
    local iconLabel = _New("ImageLabel")
    iconLabel.Size = size or _U2(0, 24, 0, 24)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Image = iconId
    iconLabel.ScaleType = Enum.ScaleType.Fit
    if color then iconLabel.ImageColor3 = color end
    return iconLabel
end

function IconModule:WaitForIcon(iconName, iconType, callback)
    iconType = iconType or self.DefaultType
    task.spawn(function()
        local waited = 0
        while not self:IsIconLoaded(iconName, iconType) and waited < 5 do
            task.wait(0.5)
            waited += 0.5
        end
        callback(self:IsIconLoaded(iconName, iconType) and self:GetIcon(iconName, iconType) or nil)
    end)
end

IconModule:LoadAll()

local function isClickInput(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function GetDeviceType()
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        return "Mobile"
    elseif UserInputService.MouseEnabled and not UserInputService.TouchEnabled then
        return "Desktop"
    elseif UserInputService.GamepadEnabled then
        return "Console"
    end
    return "Unknown"
end

ChronixUI.Themes = {
    Default = {
        Background = _C3(30, 30, 46),
        Sidebar = _C3(24, 24, 37),
        Accent = _C3(119, 221, 255),
        Text = _C3(255, 255, 255),
        TextDark = _C3(170, 170, 170),
        Border = _C3(44, 44, 62),
        Card = _C3(37, 37, 53),
        Input = _C3(37, 37, 53),
        Hover = _C3(45, 45, 65),
        Success = _C3(46, 213, 115),
        Error = _C3(255, 71, 87),
        Warning = _C3(255, 165, 2),
        Info = _C3(102, 210, 246),
        NotificationBg = _C3(45, 45, 55),
        NotificationBorder = _C3(60, 60, 70),
        IconColor = _C3(255, 255, 255)
    },
    Light = {
        Background = _C3(245, 245, 250),
        Sidebar = _C3(235, 235, 240),
        Accent = _C3(0, 110, 200),
        Text = _C3(30, 30, 30),
        TextDark = _C3(90, 90, 90),
        Border = _C3(180, 180, 180),
        Card = _C3(255, 255, 255),
        Input = _C3(255, 255, 255),
        Hover = _C3(230, 230, 235),
        Success = _C3(46, 125, 50),
        Error = _C3(211, 47, 47),
        Warning = _C3(237, 108, 0),
        Info = _C3(2, 136, 209),
        NotificationBg = _C3(250, 250, 255),
        NotificationBorder = _C3(200, 200, 210),
        IconColor = _C3(0, 0, 0)
    }
}
ChronixUI.CurrentTheme = "Default"

local function PlaySound(soundId, volume)
    local sound = _New("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.3
    sound.Parent = SoundService
    sound:Play()
    Debris:AddItem(sound, 2)
end

local function PlayClickSound()
    PlaySound("rbxassetid://535716488", 0.3)
end

local function GetPlayerAvatar(userId)
    return "https://www.roblox.com/avatar-thumbnail/image?userId=" .. userId .. "&width=420&height=420&format=png"
end

local function CreateFrame(parent, size, position, color, transparency)
    local frame = _New("Frame")
    frame.Parent = parent
    frame.Size = size
    frame.Position = position or _U2(0, 0, 0, 0)
    frame.BackgroundColor3 = color or _C3(255, 255, 255)
    frame.BackgroundTransparency = transparency or 0
    frame.BorderSizePixel = 0
    local corner = _New("UICorner")
    corner.CornerRadius = _CornerRadius6
    corner.Parent = frame
    return frame
end

local function CreateLabel(parent, text, size, position, color, textSize, font, alignment)
    local label = _New("TextLabel")
    label.Parent = parent
    label.Text = text or ""
    label.Size = size or _U2(1, 0, 1, 0)
    label.Position = position or _U2(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color or _C3(255, 255, 255)
    label.TextSize = textSize or 14
    label.Font = font or _FontGotham
    label.TextXAlignment = alignment or Enum.TextXAlignment.Left
    return label
end

local function AddStroke(obj, color, thickness)
    local stroke = _New("UIStroke")
    stroke.Color = color or _C3(44, 44, 62)
    stroke.Thickness = thickness or 1
    stroke.Parent = obj
    return stroke
end

local function AddListLayout(parent, padding, order)
    local layout = _New("UIListLayout")
    layout.Parent = parent
    layout.Padding = _U(0, padding or 12)
    layout.SortOrder = order or Enum.SortOrder.LayoutOrder
    return layout
end

local function wrapInstance(instance)
    local proxy = {
        _instance = instance,
        Destroy = function()
            if instance and instance.Parent then
                instance:Destroy()
            end
        end
    }
    return setmetatable(proxy, {
        __index = function(t, k)
            if k == "Destroy" then return t.Destroy end
            local value = instance[k]
            if type(value) == "function" then
                return function(...) return value(instance, ...) end
            end
            return value
        end,
        __newindex = function(t, k, v)
            instance[k] = v
        end
    })
end

-- 通知系统
local notifications = {}
local notificationScreenGui = nil
local notificationContainer = nil

local notificationConfig = {
    notificationWidth = 400,
    notificationHeight = 150,
    padding = 20,
    defaultDuration = 4,
}

local function getScale()
    local isMobile = (UserInputService.TouchEnabled and not UserInputService.MouseEnabled)
    return isMobile and 0.5 or 1
end

local function initNotificationScreenGui()
    if notificationScreenGui then return true end
    local scale = getScale()
    notificationScreenGui = _New("ScreenGui")
    notificationScreenGui.Name = "ChronixNotifications"
    notificationScreenGui.IgnoreGuiInset = true
    notificationScreenGui.DisplayOrder = 10000
    notificationScreenGui.ResetOnSpawn = false
    if syn and syn.protect_gui then
        syn.protect_gui(notificationScreenGui)
        notificationScreenGui.Parent = CoreGui
    else
        notificationScreenGui.Parent = gethui and gethui() or CoreGui
    end
    notificationContainer = _New("Frame")
    notificationContainer.Name = "Container"
    notificationContainer.BackgroundTransparency = 1
    notificationContainer.Size = _U2(0, notificationConfig.notificationWidth * scale, 1, 0)
    notificationContainer.Position = _U2(1, 0, 0.52, 0)
    notificationContainer.AnchorPoint = _V2(1, 0.5)
    notificationContainer.Parent = notificationScreenGui
    return true
end

local function getColorByType(notifType)
    local theme = ChronixUI.Themes[ChronixUI.CurrentTheme]
    if notifType == "info" then
        return theme.Info or _C3(30, 144, 255)
    elseif notifType == "success" then
        return theme.Success or _C3(46, 213, 115)
    elseif notifType == "warning" then
        return theme.Warning or _C3(255, 165, 2)
    elseif notifType == "error" then
        return theme.Error or _C3(255, 71, 87)
    end
    return theme.Info or _C3(30, 144, 255)
end

local function createNotificationFrame(title, text, color)
    local scale = getScale()
    local clipFrame = _New("Frame")
    clipFrame.Name = "ClipFrame"
    clipFrame.Size = _U2(1, 0, 0, notificationConfig.notificationHeight * scale)
    clipFrame.BackgroundTransparency = 1
    clipFrame.BorderSizePixel = 0
    clipFrame.ClipsDescendants = true

    local frame = _New("Frame")
    frame.Name = "NotificationFrame"
    frame.Size = _U2(1, 0, 1, 0)
    frame.Position = _U2(1, 0, 0, 0)
    frame.BackgroundColor3 = _C3(26, 26, 29)
    frame.BorderSizePixel = 0
    frame.Parent = clipFrame

    local uiGradient = _New("UIGradient")
    uiGradient.Rotation = 180
    uiGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.04),
        NumberSequenceKeypoint.new(0.5, 0.25),
        NumberSequenceKeypoint.new(0.9, 0.45),
        NumberSequenceKeypoint.new(1, 1),
    })
    uiGradient.Parent = frame

    local titleLabel = _New("TextLabel")
    titleLabel.Text = title
    titleLabel.TextColor3 = color
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = _FontGothamBold
    titleLabel.TextSize = 22 * scale
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Size = _U2(1, -48 * scale, 0, 24 * scale)
    titleLabel.Position = _U2(0, 34 * scale, 0, 20 * scale)
    titleLabel.Parent = frame

    local line = _New("Frame")
    line.BackgroundColor3 = color
    line.BorderSizePixel = 0
    line.Size = _U2(1, 0, 0, scale)
    line.Position = _U2(0, 34 * scale, 0, 50 * scale)
    line.Parent = frame

    local contentLabel = _New("TextLabel")
    contentLabel.Text = text
    contentLabel.TextColor3 = _C3(255, 255, 255)
    contentLabel.BackgroundTransparency = 1
    contentLabel.Font = _FontGotham
    contentLabel.TextSize = 18 * scale
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.Size = _U2(1, -48 * scale, 0, 120 * scale)
    contentLabel.Position = _U2(0, 34 * scale, 0, (55 + 8) * scale)
    contentLabel.TextYAlignment = Enum.TextYAlignment.Top
    contentLabel.TextWrapped = true
    contentLabel.Parent = frame

    return clipFrame, frame
end

local function calculateLayout()
    if #notifications == 0 then return 0 end
    local scale = getScale()
    local scaledHeight = notificationConfig.notificationHeight * scale
    local scaledPadding = notificationConfig.padding * scale
    local n = #notifications
    local totalHeight = (n * scaledHeight) + ((n - 1) * scaledPadding)
    return -totalHeight / 2
end

local function updateAllPositions()
    local startY = calculateLayout()
    local scale = getScale()
    local scaledHeight = notificationConfig.notificationHeight * scale
    local scaledPadding = notificationConfig.padding * scale
    for i, notification in ipairs(notifications) do
        if notification.clipFrame and notification.clipFrame.Parent then
            notification.clipFrame.Position = _U2(0, 0, 0.5, startY + ((i - 1) * (scaledHeight + scaledPadding)))
        end
    end
end

local function playNotificationSound(notifType)
    local soundsid = "rbxassetid://4590662766"
    if notifType == "info" then
        soundsid = "rbxassetid://129485210015224"
    elseif notifType == "warning" then
        soundsid = "rbxassetid://124951621656853"
    elseif notifType == "error" then
        soundsid = "rbxassetid://17525305988"
    elseif notifType == "success" then
        soundsid = "rbxassetid://129485210015224"
    end
    PlaySound(soundsid, 0.5)
end

local function slideTween(frame, toX, easingDir, callback)
    if type(easingDir) == "function" then
        callback = easingDir
        easingDir = Enum.EasingDirection.Out
    end
    local tween = _Tween(frame, _TInfo(0.5, Enum.EasingStyle.Quad, easingDir or Enum.EasingDirection.Out), {
        Position = _U2(toX, 0, 0, 0)
    })
    tween.Completed:Connect(function()
        if callback then callback() end
    end)
    tween:Play()
end

local function removeNotification(notification)
    local index = table.find(notifications, notification)
    if index then
        table.remove(notifications, index)
        return true
    end
    return false
end

function ChronixUI:Notify(config)
    local title = config.Title or "通知"
    local content = config.Content or ""
    local duration = config.Duration or notificationConfig.defaultDuration
    local notifType = config.Type or "info"
    if not notificationContainer then initNotificationScreenGui() end

    local color = getColorByType(notifType)
    local clipFrame, innerFrame = createNotificationFrame(title, content, color)
    clipFrame.Parent = notificationContainer

    local notification = {
        clipFrame = clipFrame,
        innerFrame = innerFrame,
        duration = duration,
    }
    table.insert(notifications, notification)
    playNotificationSound(notifType)
    updateAllPositions()
    RunService.Heartbeat:Wait()

    -- 入场动画
    slideTween(innerFrame, 0)

    -- 生命周期
    task.spawn(function()
        task.wait(duration)
        if not clipFrame or not clipFrame.Parent then
            removeNotification(notification)
            updateAllPositions()
            return
        end
        -- 出场动画
        slideTween(innerFrame, 1, Enum.EasingDirection.In, function()
            removeNotification(notification)
            if clipFrame and clipFrame.Parent then clipFrame:Destroy() end
            updateAllPositions()
        end)
    end)

    return notification
end

-- 窗口拖动
local function MakeDraggable(frame, dragHandle)
    local dragging = false
    local dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if isClickInput(input) then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if isClickInput(input) then
            dragging = false
            dragStart = nil
            startPos = nil
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = _U2(startPos.X.Scale, startPos.X.Offset + delta.X,
                                 startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- 创建主窗口
function ChronixUI:CreateWindow(config)
    config = config or {}
    local theme = self.Themes[self.CurrentTheme]

    local isMobile = (GetDeviceType() == "Mobile")
    local scale = isMobile and 0.7 or 1

    local defaultWidth = 680
    local defaultHeight = 420
    local windowSize = config.Size or (isMobile and _U2(0, defaultWidth * scale // 1, 0, defaultHeight * scale // 1) or _U2(0, defaultWidth, 0, defaultHeight))
    local windowName = config.Name or "Chronix UI"

    local gui = _New("ScreenGui")
    gui.Name = "ChronixUI_" .. tostring(#self.Windows + 1)
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    if syn and syn.protect_gui then
        syn.protect_gui(gui)
        gui.Parent = CoreGui
    else
        gui.Parent = gethui and gethui() or CoreGui
    end

    local blurEffect = nil
    local function createBlurEffect()
        if blurEffect then return blurEffect end
        blurEffect = _New("BlurEffect")
        blurEffect.Name = "ChronixUI_Blur"
        blurEffect.Size = 0
        blurEffect.Parent = Lighting
        return blurEffect
    end

    local blurTween = nil
    local function setBlur(enabled, instant)
        local blur = createBlurEffect()
        local targetSize = 0
        if enabled and ChronixUI.Settings.BackgroundBlur then
            targetSize = ChronixUI.Settings.BlurSize
        end
        if instant then blur.Size = targetSize; return end
        if blurTween then blurTween:Cancel() end
        blurTween = _Tween(blur, _TInfo(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize})
        blurTween:Play()
    end

    local mainFrame = CreateFrame(gui, windowSize, _U2(0.5, -windowSize.X.Offset / 2, 0.5, -windowSize.Y.Offset / 2), theme.Background)
    AddStroke(mainFrame, theme.Border)

    local windowVisible = true
    local minimized = false
    local originalSize = windowSize
    local savedPosition = mainFrame.Position

    local toggleActionName = "ChronixUIToggle_" .. tostring(#self.Windows + 1)
    local function bindToggleAction(keyCode)
        ContextActionService:BindAction(toggleActionName, function(actionName, inputState, inputObject)
            if inputState == Enum.UserInputState.Begin and inputObject.KeyCode == keyCode then
                windowVisible = not windowVisible
                mainFrame.Visible = windowVisible
                setBlur(windowVisible, false)
                if not windowVisible and self.Settings.FirstHide then
                    self.Settings.FirstHide = false
                    self:Notify({
                        Title = "菜单已隐藏",
                        Content = string.format("按 %s 重新打开菜单", self.Settings.ToggleKeyName),
                        Type = "info",
                        Duration = 10,
                    })
                end
                return Enum.ContextActionResult.Sink
            end
            return Enum.ContextActionResult.Pass
        end, false, keyCode)
    end
    bindToggleAction(self.Settings.ToggleKey)

    local titleBarHeight = 45 * scale // 1
    local titleBar = CreateFrame(mainFrame, _U2(1, 0, 0, titleBarHeight), _U2(0, 0, 0, 0), theme.Background, 1)
    MakeDraggable(mainFrame, titleBar)

    local function savePosition()
        if not minimized then savedPosition = mainFrame.Position end
    end
    mainFrame:GetPropertyChangedSignal("Position"):Connect(savePosition)

    local titleFontSize = 18 * scale // 1
    local titleLabel = CreateLabel(titleBar, windowName, _U2(1, -140 * scale, 1, 0), _U2(0, 20 * scale, 0, 0), theme.Accent, titleFontSize, _FontGothamBold)

    local buttonContainer = _New("Frame")
    buttonContainer.Size = _U2(0, 120 * scale, 1, 0)
    buttonContainer.Position = _U2(1, -130 * scale, 0, 0)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = titleBar

    local btnSize = 32 * scale // 1
    local btnOffset = 38 * scale // 1

    local function createElementIcon(cfg)
        local parent = cfg.Parent
        if not parent then return end
        if cfg.HasIcon and cfg.IconName ~= "" then
            local iconLabel = IconModule:CreateIcon(cfg.IconName, cfg.Size or _U2(0, 20 * scale, 0, 20 * scale), cfg.IconColor, cfg.IconType)
            if iconLabel then
                iconLabel.Name = cfg.Name or "ElementIcon"
                iconLabel.Position = cfg.Position or _U2(1, -28 * scale, 0.5, -10 * scale)
                iconLabel.Parent = parent
            else
                IconModule:WaitForIcon(cfg.IconName, cfg.IconType, function(iconId)
                    if iconId and parent and parent.Parent then
                        local newIcon = _New("ImageLabel")
                        newIcon.Name = cfg.Name or "ElementIcon"
                        newIcon.Size = cfg.Size or _U2(0, 20 * scale, 0, 20 * scale)
                        newIcon.Position = cfg.Position or _U2(1, -28 * scale, 0.5, -10 * scale)
                        newIcon.BackgroundTransparency = 1
                        newIcon.Image = iconId
                        newIcon.ScaleType = Enum.ScaleType.Fit
                        if cfg.IconColor then newIcon.ImageColor3 = cfg.IconColor end
                        newIcon.Parent = parent
                    end
                end)
            end
        end
    end

    local function createTitleButton(position, text, textSize)
        local btn = _New("TextButton")
        btn.Size = _U2(0, btnSize, 0, btnSize)
        btn.Position = position
        btn.Text = text
        btn.TextColor3 = theme.Text
        btn.TextSize = textSize
        btn.BackgroundColor3 = theme.Card
        btn.BorderSizePixel = 0
        btn.Parent = buttonContainer
        local corner = _New("UICorner")
        corner.CornerRadius = _U(0, 6 * scale // 1)
        corner.Parent = btn
        AddStroke(btn, theme.Border)
        return btn
    end

    local settingsBtn = createTitleButton(_U2(0, 0, 0.5, -btnSize / 2), "≡", 20 * scale // 1)
    local minBtn = createTitleButton(_U2(0, btnOffset, 0.5, -btnSize / 2), "−", 24 * scale // 1)
    local closeBtn = createTitleButton(_U2(0, btnOffset * 2, 0.5, -btnSize / 2), "×", 20 * scale // 1)

    local playerBarHeight = 50 * scale // 1
    local playerBar = CreateFrame(mainFrame, _U2(1, 0, 0, playerBarHeight), _U2(0, 0, 1, -playerBarHeight), theme.Card)
    AddStroke(playerBar, theme.Border)

    local avatarSize = 36 * scale // 1
    local avatarContainer = _New("Frame")
    avatarContainer.Size = _U2(0, avatarSize, 0, avatarSize)
    avatarContainer.Position = _U2(0, 12 * scale, 0.5, -avatarSize / 2)
    avatarContainer.BackgroundColor3 = theme.Border
    avatarContainer.BorderSizePixel = 0
    avatarContainer.Parent = playerBar
    local avatarCorner = _New("UICorner")
    avatarCorner.CornerRadius = _U(0, 8 * scale // 1)
    avatarCorner.Parent = avatarContainer

    local avatarImage = _New("ImageLabel")
    avatarImage.Size = _U2(1, -2, 1, -2)
    avatarImage.Position = _U2(0, 1, 0, 1)
    avatarImage.BackgroundTransparency = 1
    avatarImage.Image = GetPlayerAvatar(LocalPlayer.UserId)
    avatarImage.Parent = avatarContainer
    local imageCorner = _New("UICorner")
    imageCorner.CornerRadius = _U(0, 6 * scale // 1)
    imageCorner.Parent = avatarImage

    local premiumBadge = _New("ImageLabel")
    premiumBadge.Name = "PremiumBadge"
    premiumBadge.Size = _U2(0, 12 * scale // 1, 0, 12 * scale // 1)
    premiumBadge.Position = _U2(1, -4 * scale // 1, 1, -4 * scale // 1)
    premiumBadge.AnchorPoint = _V2(1, 1)
    premiumBadge.BackgroundTransparency = 1
    premiumBadge.Image = "rbxassetid://126540142153628"
    premiumBadge.ImageTransparency = 0.15
    premiumBadge.ScaleType = Enum.ScaleType.Fit
    premiumBadge.Visible = (LocalPlayer.MembershipType == Enum.MembershipType.Premium)
    premiumBadge.Parent = avatarContainer

    local playerNameLabel = CreateLabel(playerBar, "", _U2(0, 200 * scale, 0, 24 * scale // 1), _U2(0, 60 * scale, 0, 8 * scale), theme.Text, 16 * scale // 1, _FontGothamBold)
    local playerInfoLabel = CreateLabel(playerBar, "", _U2(0, 200 * scale, 0, 20 * scale // 1), _U2(0, 60 * scale, 0, 30 * scale), theme.TextDark, 12 * scale // 1, 12)
    playerInfoLabel.Name = "PlayerInfoLabel"

    local gameInfoCache = nil
    local function getGameName(universeId)
        if gameInfoCache then return gameInfoCache end
        local url = "https://games.roblox.com/v1/games?universeIds=" .. universeId
        local success, response = pcall(function() return game:HttpGet(url) end)
        if success then
            local data = HttpService:JSONDecode(response)
            if data.data and #data.data > 0 then
                gameInfoCache = data.data[1]
                return gameInfoCache
            end
        end
        return nil
    end

    local function updatePlayerInfoDisplay()
        local player = Players.LocalPlayer
        if not player then return end
        local platformInfo = UserInputService:GetPlatform().Name

        if ChronixUI.Settings.PrivacyMode then
            playerNameLabel.Text = "####################"
            playerInfoLabel.Text = "####################"
            premiumBadge.Image = ""
            avatarImage.Image = ""
        else
            premiumBadge.Image = "rbxassetid://126540142153628"
            avatarImage.Image = GetPlayerAvatar(LocalPlayer.UserId)
            local executorname, executorversion = identifyexecutor()
            playerNameLabel.Text = string.format("欢迎~ %s#%d %s %s%s", player.DisplayName, player.UserId, platformInfo, executorname, executorversion)
            local gameInfo = getGameName(game.GameId)
            if gameInfo then
                playerInfoLabel.Text = "在玩: " .. gameInfo.name .. " | ID: " .. game.GameId
            else
                playerInfoLabel.Text = "未找到游戏信息, 未找到游戏ID | Debug: InConsole"
            end
        end
    end
    updatePlayerInfoDisplay()

    local sidebarWidth = 160 * scale // 1
    local sidebar = CreateFrame(mainFrame, _U2(0, sidebarWidth, 1, -playerBarHeight - titleBarHeight), _U2(0, 0, 0, titleBarHeight), theme.Sidebar)

    local sidebarTitle = CreateLabel(sidebar, "功能菜单", _U2(1, 0, 0, 40 * scale), _U2(0, 0, 0, 10 * scale), theme.Accent, 16 * scale // 1, _FontGothamBold)
    sidebarTitle.TextXAlignment = Enum.TextXAlignment.Center

    local tabContainer = _New("ScrollingFrame")
    tabContainer.Parent = sidebar
    tabContainer.Size = _U2(1, 0, 1, -60 * scale)
    tabContainer.Position = _U2(0, 0, 0, 50 * scale)
    tabContainer.BackgroundTransparency = 1
    tabContainer.BorderSizePixel = 0
    tabContainer.ScrollBarThickness = 6 * scale // 1
    tabContainer.CanvasSize = _U2(0, 0, 0, 0)

    local tabList = AddListLayout(tabContainer, 8 * scale // 1)

    local function updateSidebarCanvas()
        tabContainer.CanvasSize = _U2(0, 0, 0, tabList.AbsoluteContentSize.Y + 20 * scale)
    end
    tabList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSidebarCanvas)

    local contentArea = CreateFrame(mainFrame, _U2(1, -sidebarWidth, 1, -playerBarHeight - titleBarHeight), _U2(0, sidebarWidth, 0, titleBarHeight), theme.Background, 1)

    local contentScroll = _New("ScrollingFrame")
    contentScroll.Parent = contentArea
    contentScroll.Size = _U2(1, 0, 1, 0)
    contentScroll.BackgroundTransparency = 1
    contentScroll.BorderSizePixel = 0
    contentScroll.ScrollBarThickness = 6 * scale // 1
    contentScroll.CanvasSize = _U2(0, 0, 0, 0)

    local contentLayout = AddListLayout(contentScroll, 16 * scale // 1)
    local contentPadding = _New("UIPadding")
    contentPadding.PaddingLeft = _U(0, 20 * scale // 1)
    contentPadding.PaddingRight = _U(0, 20 * scale // 1)
    contentPadding.PaddingTop = _U(0, 20 * scale // 1)
    contentPadding.PaddingBottom = _U(0, 20 * scale // 1)
    contentPadding.Parent = contentScroll

    local function updateContentCanvas()
        contentScroll.CanvasSize = _U2(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 40 * scale)
    end
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateContentCanvas)

    closeBtn.MouseButton1Click:Connect(function()
        PlayClickSound()
        if blurEffect then blurEffect:Destroy(); blurEffect = nil end
        ContextActionService:UnbindAction(toggleActionName)
        if gui then gui:Destroy() end
        if notificationScreenGui then
            notificationScreenGui:Destroy()
            notificationScreenGui = nil
            notificationContainer = nil
        end
        for i, window in pairs(self.Windows) do
            if window.Gui == gui then table.remove(self.Windows, i); break end
        end
        if config.CloseCallback then config.CloseCallback() end
    end)

    local windowData = {
        Gui = gui,
        MainFrame = mainFrame,
        ContentArea = contentScroll,
        ContentLayout = contentLayout,
        Tabs = {},
        CurrentTab = nil,
        SettingsTabContent = nil,
        ParticleSystem = nil,
        Minimized = false,
        UpdateTheme = nil,
    }

    function windowData:UpdateTheme(themeName)
        local t = ChronixUI.Themes[themeName]
        if not t then return false end

        mainFrame.BackgroundColor3 = t.Background
        local mainStroke = mainFrame:FindFirstChildOfClass("UIStroke")
        if mainStroke then mainStroke.Color = t.Border end

        sidebar.BackgroundColor3 = t.Sidebar
        sidebarTitle.TextColor3 = t.Accent
        titleLabel.TextColor3 = t.Accent

        local function updateButtonStyle(btn)
            btn.BackgroundColor3 = t.Card
            btn.TextColor3 = t.Text
            local s = btn:FindFirstChildOfClass("UIStroke")
            if s then s.Color = t.Border end
        end
        updateButtonStyle(settingsBtn)
        updateButtonStyle(minBtn)
        updateButtonStyle(closeBtn)

        playerBar.BackgroundColor3 = t.Card
        local barStroke = playerBar:FindFirstChildOfClass("UIStroke")
        if barStroke then barStroke.Color = t.Border end
        if avatarContainer then avatarContainer.BackgroundColor3 = t.Border end
        playerNameLabel.TextColor3 = t.Text
        playerInfoLabel.TextColor3 = t.TextDark

        if self.ParticleSystem then self.ParticleSystem:setColor(t.Accent) end

        local function updateElementColors(obj)
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                if obj:IsA("TextButton") then
                    local isSpecial = false
                    for _, tab in pairs(self.Tabs) do
                        if obj == tab.Button then isSpecial = true; break end
                    end
                    if not isSpecial then obj.BackgroundColor3 = t.Card end
                elseif obj:IsA("TextBox") then
                    obj.BackgroundColor3 = t.Input
                end
                if obj:FindFirstChild("IsTitle") then
                    obj.TextColor3 = t.Accent
                elseif obj:FindFirstChild("IsDark") then
                    obj.TextColor3 = t.TextDark
                else
                    obj.TextColor3 = t.Text
                end
            end
            local stroke = obj:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = t.Border end
            for _, child in ipairs(obj:GetChildren()) do
                updateElementColors(child)
            end
        end

        for _, tabData in pairs(self.Tabs) do
            if tabData.Button then
                tabData.Button.BackgroundColor3 = t.Card
                tabData.Button.TextColor3 = t.TextDark
            end
            if self.CurrentTab and self.CurrentTab.Name == tabData.Name then
                tabData.Button.BackgroundColor3 = t.Accent
                tabData.Button.TextColor3 = _C3(0, 0, 0)
            end
            updateElementColors(tabData.Content)
        end
        if self.SettingsTabContent then updateElementColors(self.SettingsTabContent) end
        return true
    end

    -- 粒子系统
    if UIParticleSystem then
        local particleBgFrame = _New("Frame")
        particleBgFrame.Name = "ParticleBackground"
        particleBgFrame.Size = _U2(1, 0, 1, -titleBarHeight - playerBarHeight)
        particleBgFrame.Position = _U2(0, 0, 0, titleBarHeight)
        particleBgFrame.BackgroundTransparency = 1
        particleBgFrame.BorderSizePixel = 0
        particleBgFrame.ClipsDescendants = true
        particleBgFrame.ZIndex = 5
        particleBgFrame.Parent = mainFrame
        windowData.ParticleSystem = UIParticleSystem.new(particleBgFrame)
        if windowData.ParticleSystem then windowData.ParticleSystem:setColor(theme.Accent) end
    end

    function windowData:SelectTab(name)
        for _, tab in pairs(self.Tabs) do
            if tab.Name == name then
                tab.Button.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Accent
                tab.Button.TextColor3 = _C3(0, 0, 0)
                tab.Content.Visible = true
            else
                tab.Button.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Background
                tab.Button.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].TextDark
                tab.Content.Visible = false
            end
        end
        self.CurrentTab = { Name = name }
        updateContentCanvas()
    end

    minBtn.MouseButton1Click:Connect(function()
        PlayClickSound()
        windowData.Minimized = not windowData.Minimized
        if windowData.Minimized then
            setBlur(false, false)
        else
            setBlur(true, false)
        end
        if windowData.Minimized then
            savedPosition = mainFrame.Position
            _Tween(mainFrame, _TInfo(0.3, Enum.EasingStyle.Quad), {
                Size = _U2(0, 280 * scale // 1, 0, titleBarHeight),
                Position = savedPosition,
            }):Play()
            sidebar.Visible = false
            contentArea.Visible = false
            playerBar.Visible = false
            settingsBtn.Visible = false
            minBtn.Text = "+"
        else
            _Tween(mainFrame, _TInfo(0.3, Enum.EasingStyle.Quad), {
                Size = originalSize,
                Position = savedPosition,
            }):Play()
            sidebar.Visible = true
            contentArea.Visible = true
            playerBar.Visible = true
            settingsBtn.Visible = true
            minBtn.Text = "−"
        end
    end)

    function windowData:CreateTab(tabConfig)
        local tabName = tabConfig.Name or "Tab"
        local isSettings = tabConfig.IsSettings or false
        local hasIcon = tabConfig.HasIcon or false
        local iconName = tabConfig.IconName or ""
        local iconType = tabConfig.IconType or "lucide"
        local iconColor = tabConfig.IconColor or ChronixUI.Themes[ChronixUI.CurrentTheme].IconColor

        local textPadding = 8 * scale
        local iconOffset = 0

        local tabBtn = _New("TextButton")
        tabBtn.Parent = tabContainer
        tabBtn.Size = _U2(1, -12 * scale, 0, 36 * scale // 1)
        tabBtn.Position = _U2(0, 6 * scale, 0, 0)
        tabBtn.BackgroundColor3 = _C3(30, 30, 46)
        tabBtn.Text = ""
        tabBtn.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].TextDark
        tabBtn.TextSize = 14 * scale // 1
        tabBtn.TextXAlignment = Enum.TextXAlignment.Left
        tabBtn.Font = _FontGothamSemibold
        tabBtn.BorderSizePixel = 0

        local btnCorner = _New("UICorner")
        btnCorner.CornerRadius = _U(0, 4 * scale // 1)
        btnCorner.Parent = tabBtn

        local iconLabel = nil
        if hasIcon and iconName ~= "" then
            local iconSize = _U2(0, 18 * scale, 0, 18 * scale)
            local createdIcon = IconModule:CreateIcon(iconName, iconSize, iconColor, iconType)
            if createdIcon then
                iconLabel = createdIcon
                iconLabel.Name = "TabIcon"
                iconLabel.Position = _U2(0, 8 * scale, 0.5, -9 * scale)
                iconLabel.Parent = tabBtn
                iconOffset = 26 * scale
            else
                iconOffset = 26 * scale
            end
        end

        local tabTextLabel = _New("TextLabel")
        tabTextLabel.Name = "TabText"
        tabTextLabel.Size = _U2(1, -textPadding - iconOffset - 8 * scale, 1, 0)
        tabTextLabel.Position = _U2(0, textPadding + iconOffset, 0, 0)
        tabTextLabel.BackgroundTransparency = 1
        tabTextLabel.Text = tabName
        tabTextLabel.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].TextDark
        tabTextLabel.TextSize = 14 * scale // 1
        tabTextLabel.TextXAlignment = Enum.TextXAlignment.Left
        tabTextLabel.Font = _FontGothamSemibold
        tabTextLabel.Parent = tabBtn

        if hasIcon and iconName ~= "" and not iconLabel then
            IconModule:WaitForIcon(iconName, iconType, function(iconId)
                if iconId and tabBtn and tabBtn.Parent then
                    local newIcon = _New("ImageLabel")
                    newIcon.Name = "TabIcon"
                    newIcon.Size = _U2(0, 18 * scale, 0, 18 * scale)
                    newIcon.Position = _U2(0, 8 * scale, 0.5, -9 * scale)
                    newIcon.BackgroundTransparency = 1
                    newIcon.Image = iconId
                    newIcon.ScaleType = Enum.ScaleType.Fit
                    if iconColor then newIcon.ImageColor3 = iconColor end
                    newIcon.Parent = tabBtn
                end
            end)
        end

        tabBtn.MouseButton1Click:Connect(PlayClickSound)

        local tabContent = _New("Frame")
        tabContent.Parent = contentScroll
        tabContent.Size = _U2(1, 0, 0, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = false
        tabContent.AutomaticSize = Enum.AutomaticSize.Y

        local tabLayout = AddListLayout(tabContent, 12 * scale // 1)

        local function SelectTab()
            windowData:SelectTab(tabName)
        end

        tabBtn.MouseButton1Click:Connect(SelectTab)

        if isSettings then
            windowData.SettingsTabContent = tabContent
            tabBtn.Visible = false
        end

        if #windowData.Tabs == 0 and not isSettings then SelectTab() end

        local tabData = {
            Button = tabBtn,
            Content = tabContent,
            Layout = tabLayout,
            Name = tabName,
        }

        table.insert(windowData.Tabs, tabData)

        local elements = {}

        local function wrap(obj) return wrapInstance(obj) end

        function elements:AddButton(config)
            local btnConfig = config or {}
            local btnText = btnConfig.Text or "按钮"
            local callback = btnConfig.Callback or function() end
            local hasIcon = btnConfig.HasIcon or true
            local iconName = btnConfig.IconName or "mouse-pointer-click"
            local iconType = btnConfig.IconType or "lucide"
            local iconColor = btnConfig.IconColor or ChronixUI.Themes[ChronixUI.CurrentTheme].IconColor

            local btn = _New("TextButton")
            btn.Parent = tabContent
            btn.Size = _U2(1, 0, 0, 38 * scale // 1)
            btn.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Card
            btn.Text = btnText
            btn.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Text
            btn.TextSize = 14 * scale // 1
            btn.Font = _FontGothamSemibold
            btn.BorderSizePixel = 0
            local btnCorner = _New("UICorner")
            btnCorner.CornerRadius = _CornerRadius4
            btnCorner.Parent = btn
            AddStroke(btn, ChronixUI.Themes[ChronixUI.CurrentTheme].Border)

            createElementIcon({
                HasIcon = hasIcon,
                IconName = iconName,
                IconType = iconType,
                IconColor = iconColor,
                Parent = btn,
                Name = "ButtonIcon",
            })

            btn.MouseButton1Click:Connect(function()
                PlayClickSound()
                callback()
            end)

            btn.MouseEnter:Connect(function()
                _Tween(btn, _TInfo(0.2), {BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Hover}):Play()
            end)

            btn.MouseLeave:Connect(function()
                _Tween(btn, _TInfo(0.2), {BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Card}):Play()
            end)

            return wrap(btn)
        end

        function elements:AddDropdown(config)
            local dropdownConfig = config or {}
            local label = dropdownConfig.Label or "选项"
            local options = dropdownConfig.Options or {"选项1", "选项2", "选项3"}
            local default = dropdownConfig.Default or options[1]
            local callback = dropdownConfig.Callback or function() end
            local hasIcon = dropdownConfig.HasIcon or true
            local iconName = dropdownConfig.IconName or "chevron-down"
            local iconType = dropdownConfig.IconType or "lucide"
            local iconColor = dropdownConfig.IconColor or ChronixUI.Themes[ChronixUI.CurrentTheme].IconColor

            local container = _New("Frame")
            container.Parent = tabContent
            container.Size = _U2(1, 0, 0, 70 * scale // 1)
            container.BackgroundTransparency = 1
            container.AutomaticSize = Enum.AutomaticSize.Y

            local labelText = CreateLabel(container, label, _U2(1, 0, 0, 20 * scale // 1), _U2(0, 0, 0, 0), ChronixUI.Themes[ChronixUI.CurrentTheme].Text, 14 * scale // 1, _FontGothamSemibold)

            local dropdownBtn = _New("TextButton")
            dropdownBtn.Parent = container
            dropdownBtn.Size = _U2(1, 0, 0, 36 * scale // 1)
            dropdownBtn.Position = _U2(0, 0, 0, 28 * scale // 1)
            dropdownBtn.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Input
            dropdownBtn.Text = "  " .. default
            dropdownBtn.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Text
            dropdownBtn.TextSize = 14 * scale // 1
            dropdownBtn.TextXAlignment = Enum.TextXAlignment.Left
            dropdownBtn.Font = _FontGotham
            dropdownBtn.BorderSizePixel = 0
            local btnCorner = _New("UICorner")
            btnCorner.CornerRadius = _CornerRadius4
            btnCorner.Parent = dropdownBtn
            AddStroke(dropdownBtn, ChronixUI.Themes[ChronixUI.CurrentTheme].Border)

            createElementIcon({
                HasIcon = hasIcon,
                IconName = iconName,
                IconType = iconType,
                IconColor = iconColor,
                Parent = dropdownBtn,
                Name = "ButtonIcon",
            })

            local dropdownList = _New("Frame")
            dropdownList.Parent = container
            dropdownList.Size = _U2(1, 0, 0, 0)
            dropdownList.Position = _U2(0, 0, 0, 64 * scale // 1)
            dropdownList.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Input
            dropdownList.ClipsDescendants = true
            dropdownList.Visible = false
            local listCorner = _New("UICorner")
            listCorner.CornerRadius = _CornerRadius4
            listCorner.Parent = dropdownList
            AddStroke(dropdownList, ChronixUI.Themes[ChronixUI.CurrentTheme].Border)

            local listLayout = AddListLayout(dropdownList, 0)

            local expanded = false
            local function collapseDropdown()
                local tween = _Tween(dropdownList, _TInfo(0.2), {Size = _U2(1, 0, 0, 0)})
                tween.Completed:Connect(function()
                    dropdownList.Visible = false
                end)
                tween:Play()
            end

            for _, option in ipairs(options) do
                local optBtn = _New("TextButton")
                optBtn.Parent = dropdownList
                optBtn.Size = _U2(1, 0, 0, 32 * scale // 1)
                optBtn.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Input
                optBtn.Text = "  " .. option
                optBtn.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Text
                optBtn.TextSize = 14 * scale // 1
                optBtn.TextXAlignment = Enum.TextXAlignment.Left
                optBtn.Font = _FontGotham
                optBtn.BorderSizePixel = 0

                optBtn.MouseButton1Click:Connect(function()
                    PlayClickSound()
                    dropdownBtn.Text = "  " .. option
                    callback(option)
                    expanded = false
                    collapseDropdown()
                end)
            end

            dropdownBtn.MouseButton1Click:Connect(function()
                PlayClickSound()
                expanded = not expanded
                dropdownList.Visible = true
                if expanded then
                    local totalHeight = #options * (32 * scale // 1)
                    _Tween(dropdownList, _TInfo(0.2), {Size = _U2(1, 0, 0, totalHeight)}):Play()
                else
                    collapseDropdown()
                end
            end)

            return wrap(container)
        end

        function elements:AddSlider(config)
            local sliderConfig = config or {}
            local label = sliderConfig.Label or "滑块"
            local min = sliderConfig.Min or 0
            local max = sliderConfig.Max or 100
            local default = sliderConfig.Default or 50
            local callback = sliderConfig.Callback or function() end

            local container = _New("Frame")
            container.Parent = tabContent
            container.Size = _U2(1, 0, 0, 70 * scale // 1)
            container.BackgroundTransparency = 1

            local labelText = CreateLabel(container, label, _U2(1, 0, 0, 20 * scale // 1), _U2(0, 0, 0, 0), ChronixUI.Themes[ChronixUI.CurrentTheme].Text, 14 * scale // 1, _FontGothamSemibold)

            local valueLabel = CreateLabel(container, tostring(default), _U2(0, 50 * scale // 1, 0, 20 * scale // 1), _U2(1, -60 * scale, 0, 0), ChronixUI.Themes[ChronixUI.CurrentTheme].Accent, 14 * scale // 1, _FontGothamBold)
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right

            local slider = _New("Frame")
            slider.Parent = container
            slider.Size = _U2(1, 0, 0, 4 * scale // 1)
            slider.Position = _U2(0, 0, 0, 40 * scale // 1)
            slider.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Border
            slider.BorderSizePixel = 0
            local sliderCorner = _New("UICorner")
            sliderCorner.CornerRadius = _CornerRadius2
            sliderCorner.Parent = slider

            local fill = _New("Frame")
            fill.Parent = slider
            fill.Size = _U2((default - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Accent
            fill.BorderSizePixel = 0
            local fillCorner = _New("UICorner")
            fillCorner.CornerRadius = _CornerRadius2
            fillCorner.Parent = fill

            local handle = _New("Frame")
            handle.Parent = slider
            handle.Size = _U2(0, 12 * scale // 1, 0, 12 * scale // 1)
            handle.Position = _U2((default - min) / (max - min), -(6 * scale // 1), 0, -(4 * scale // 1))
            handle.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Accent
            handle.BorderSizePixel = 0
            local handleCorner = _New("UICorner")
            handleCorner.CornerRadius = _U(0, 6 * scale // 1)
            handleCorner.Parent = handle

            local dragging = false
            local function UpdateSlider(input)
                local pos = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
                local value = (min + (max - min) * pos) // 1
                fill.Size = _U2(pos, 0, 1, 0)
                handle.Position = _U2(pos, -(6 * scale // 1), 0, -(4 * scale // 1))
                valueLabel.Text = tostring(value)
                callback(value)
            end

            local sliderHitbox = _New("TextButton")
            sliderHitbox.Parent = container
            sliderHitbox.Size = _U2(1, 0, 0, 30 * scale // 1)
            sliderHitbox.Position = _U2(0, 0, 0, 35 * scale // 1)
            sliderHitbox.BackgroundTransparency = 1
            sliderHitbox.Text = ""
            sliderHitbox.AutoButtonColor = false

            local dragConnection = nil

            local function startDrag(input)
                dragging = true
                UpdateSlider(input)
                dragConnection = UserInputService.InputChanged:Connect(function(inp)
                    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                        UpdateSlider(inp)
                    end
                end)
            end

            sliderHitbox.InputBegan:Connect(function(input)
                if isClickInput(input) then startDrag(input) end
            end)

            local function stopDrag()
                dragging = false
                if dragConnection then dragConnection:Disconnect(); dragConnection = nil end
            end

            sliderHitbox.InputEnded:Connect(stopDrag)
            UserInputService.InputEnded:Connect(function(input)
                if isClickInput(input) then stopDrag() end
            end)

            return wrap(container)
        end

        function elements:AddToggle(config)
            local toggleConfig = config or {}
            local label = toggleConfig.Label or "开关"
            local default = toggleConfig.Default or false
            local callback = toggleConfig.Callback or function() end

            local container = _New("Frame")
            container.Parent = tabContent
            container.Size = _U2(1, 0, 0, 50 * scale // 1)
            container.BackgroundTransparency = 1

            local labelText = CreateLabel(container, label, _U2(1, -60 * scale, 0, 30 * scale // 1), _U2(0, 0, 0, 10 * scale // 1), ChronixUI.Themes[ChronixUI.CurrentTheme].Text, 14 * scale // 1, _FontGothamSemibold)

            local toggleBtn = _New("Frame")
            toggleBtn.Parent = container
            toggleBtn.Size = _U2(0, 50 * scale // 1, 0, 26 * scale // 1)
            toggleBtn.Position = _U2(1, -60 * scale, 0, 12 * scale // 1)
            toggleBtn.BackgroundColor3 = default and ChronixUI.Themes[ChronixUI.CurrentTheme].Accent or _C3(80, 80, 80)
            toggleBtn.BorderSizePixel = 0
            local toggleCorner = _New("UICorner")
            toggleCorner.CornerRadius = _U(0, 13 * scale // 1)
            toggleCorner.Parent = toggleBtn

            local toggleHandle = _New("Frame")
            toggleHandle.Parent = toggleBtn
            toggleHandle.Size = _U2(0, 22 * scale // 1, 0, 22 * scale // 1)
            toggleHandle.Position = default and _U2(1, -(26 * scale // 1), 0.5, -(11 * scale // 1)) or _U2(0, 4 * scale // 1, 0.5, -(11 * scale // 1))
            toggleHandle.BackgroundColor3 = _C3(255, 255, 255)
            toggleHandle.BorderSizePixel = 0
            local handleCorner = _New("UICorner")
            handleCorner.CornerRadius = _U(0, 11 * scale // 1)
            handleCorner.Parent = toggleHandle

            local toggled = default
            toggleBtn.InputBegan:Connect(function(input)
                if not isClickInput(input) then return end
                PlayClickSound()
                toggled = not toggled
                local targetColor = toggled and ChronixUI.Themes[ChronixUI.CurrentTheme].Accent or _C3(80, 80, 80)
                local targetPos = toggled and _U2(1, -(26 * scale // 1), 0.5, -(11 * scale // 1)) or _U2(0, 4 * scale // 1, 0.5, -(11 * scale // 1))
                _Tween(toggleBtn, _TInfo(0.2), {BackgroundColor3 = targetColor}):Play()
                _Tween(toggleHandle, _TInfo(0.2), {Position = targetPos}):Play()
                callback(toggled)
            end)

            return wrap(container)
        end

        function elements:AddInput(config)
            local inputConfig = config or {}
            local label = inputConfig.Label or "输入框"
            local placeholder = inputConfig.Placeholder or "请输入..."
            local default = inputConfig.Default or ""
            local clearTextOnFocus = inputConfig.ClearTextOnFocus or false
            local customHeight = inputConfig.Height or nil
            local callback = inputConfig.Callback or function() end
            local isMultiLine = customHeight ~= nil
            local hasIcon = inputConfig.HasIcon or true
            local iconName = inputConfig.IconName or "text-cursor-input"
            local iconType = inputConfig.IconType or "lucide"
            local iconColor = inputConfig.IconColor or ChronixUI.Themes[ChronixUI.CurrentTheme].IconColor

            local container = _New("Frame")
            container.Parent = tabContent
            local containerHeight = customHeight and (customHeight + 34) or 70
            container.Size = _U2(1, 0, 0, containerHeight * scale // 1)
            container.BackgroundTransparency = 1

            local labelText = CreateLabel(container, label, _U2(1, 0, 0, 20 * scale // 1), _U2(0, 0, 0, 0), ChronixUI.Themes[ChronixUI.CurrentTheme].Text, 14 * scale // 1, _FontGothamSemibold)

            local inputBox = _New("TextBox")
            inputBox.Parent = container
            local inputHeight = customHeight or 36
            inputBox.Size = _U2(1, 0, 0, inputHeight * scale // 1)
            inputBox.Position = _U2(0, 0, 0, 28 * scale // 1)
            inputBox.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Input
            inputBox.PlaceholderText = placeholder
            inputBox.PlaceholderColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].TextDark
            inputBox.Text = default or ""
            inputBox.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Text
            inputBox.TextSize = 14 * scale // 1
            inputBox.Font = _FontGotham
            inputBox.BorderSizePixel = 0
            inputBox.ClearTextOnFocus = clearTextOnFocus

            if isMultiLine then
                inputBox.TextYAlignment = Enum.TextYAlignment.Top
                inputBox.TextXAlignment = Enum.TextXAlignment.Left
                inputBox.TextWrapped = true
                inputBox.MultiLine = true
            end

            local inputCorner = _New("UICorner")
            inputCorner.CornerRadius = _CornerRadius4
            inputCorner.Parent = inputBox
            AddStroke(inputBox, ChronixUI.Themes[ChronixUI.CurrentTheme].Border)

            local iconPosition = isMultiLine and _U2(1, -28 * scale, 0, 8 * scale) or _U2(1, -28 * scale, 0.5, -10 * scale)
            createElementIcon({
                HasIcon = hasIcon,
                IconName = iconName,
                IconType = iconType,
                IconColor = iconColor,
                Parent = inputBox,
                Name = "InputIcon",
                Position = iconPosition,
            })

            inputBox.FocusLost:Connect(function() callback(inputBox.Text) end)

            local wrapped = {}
            local inputBoxRef = inputBox

            setmetatable(wrapped, {
                __index = function(t, k)
                    if k == "Text" then return inputBoxRef.Text end
                    if k == "Destroy" then return function() container:Destroy() end end
                    local containerVal = container[k]
                    if containerVal ~= nil then
                        if type(containerVal) == "function" then
                            return function(...) return containerVal(container, ...) end
                        end
                        return containerVal
                    end
                    return nil
                end,
                __newindex = function(t, k, v)
                    if k == "Text" then inputBoxRef.Text = tostring(v) else rawset(t, k, v) end
                end,
            })

            return wrapped
        end

        function elements:AddKeybind(config)
            local keybindConfig = config or {}
            local label = keybindConfig.Label or "按键绑定"
            local defaultKey = keybindConfig.Default or "未设置"
            local callback = keybindConfig.Callback or function() end
            local hasIcon = keybindConfig.HasIcon or true
            local iconName = keybindConfig.IconName or "mouse-pointer-click"
            local iconType = keybindConfig.IconType or "lucide"
            local iconColor = keybindConfig.IconColor or ChronixUI.Themes[ChronixUI.CurrentTheme].IconColor

            local container = _New("Frame")
            container.Parent = tabContent
            container.Size = _U2(1, 0, 0, 70 * scale // 1)
            container.BackgroundTransparency = 1

            local labelText = CreateLabel(container, label, _U2(1, 0, 0, 20 * scale // 1), _U2(0, 0, 0, 0), ChronixUI.Themes[ChronixUI.CurrentTheme].Text, 14 * scale // 1, _FontGothamSemibold)

            local keyBtn = _New("TextButton")
            keyBtn.Parent = container
            keyBtn.Size = _U2(1, 0, 0, 36 * scale // 1)
            keyBtn.Position = _U2(0, 0, 0, 28 * scale // 1)
            keyBtn.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Input
            keyBtn.Text = defaultKey
            keyBtn.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Accent
            keyBtn.TextSize = 14 * scale // 1
            keyBtn.Font = _FontGothamBold
            keyBtn.BorderSizePixel = 0
            local btnCorner = _New("UICorner")
            btnCorner.CornerRadius = _CornerRadius4
            btnCorner.Parent = keyBtn
            AddStroke(keyBtn, ChronixUI.Themes[ChronixUI.CurrentTheme].Border)

            createElementIcon({
                HasIcon = hasIcon,
                IconName = iconName,
                IconType = iconType,
                IconColor = iconColor,
                Parent = keyBtn,
                Name = "ButtonIcon",
            })

            local listening = false
            keyBtn.MouseButton1Click:Connect(function()
                PlayClickSound()
                if listening then return end
                listening = true
                keyBtn.Text = "按下按键..."
                keyBtn.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Text

                local connection
                connection = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        local key = input.KeyCode.Name
                        if key ~= "Unknown" then
                            keyBtn.Text = key
                            keyBtn.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Accent
                            if callback then callback(key) end
                            listening = false
                            connection:Disconnect()
                        end
                    end
                end)
            end)

            return wrap(container)
        end

        function elements:AddColorPicker(config)
            local colorConfig = config or {}
            local label = colorConfig.Label or "颜色选择"
            local default = colorConfig.Default or _C3(119, 221, 255)
            local callback = colorConfig.Callback or function() end

            local container = _New("Frame")
            container.Parent = tabContent
            container.Size = _U2(1, 0, 0, 38 * scale)
            container.BackgroundTransparency = 1
            container.AutomaticSize = Enum.AutomaticSize.Y

            local h, s, v = Color3.toHSV(default)
            local expanded = false

            local header = _New("Frame")
            header.Size = _U2(1, 0, 0, 38 * scale)
            header.BackgroundTransparency = 1
            header.Parent = container

            local labelText = CreateLabel(header, label, _U2(1, -50 * scale, 1, 0), _U2(0, 12 * scale, 0, 0), ChronixUI.Themes[ChronixUI.CurrentTheme].Text, 14 * scale, _FontGothamSemibold)

            local colorPreview = _New("Frame")
            colorPreview.Size = _U2(0, 30 * scale, 0, 30 * scale)
            colorPreview.Position = _U2(1, -40 * scale, 0.5, -15 * scale)
            colorPreview.BackgroundColor3 = default
            colorPreview.BorderSizePixel = 0
            colorPreview.Parent = header
            local previewCorner = _New("UICorner")
            previewCorner.CornerRadius = _U(0, 6 * scale)
            previewCorner.Parent = colorPreview
            AddStroke(colorPreview, ChronixUI.Themes[ChronixUI.CurrentTheme].Border)

            local expandBtn = _New("TextButton")
            expandBtn.Size = _U2(1, 0, 1, 0)
            expandBtn.BackgroundTransparency = 1
            expandBtn.Text = ""
            expandBtn.Parent = header

            local pickerPanel = _New("Frame")
            pickerPanel.Size = _U2(1, 0, 0, 150 * scale)
            pickerPanel.Position = _U2(0, 0, 0, 38 * scale)
            pickerPanel.BackgroundTransparency = 1
            pickerPanel.Visible = false
            pickerPanel.Parent = container

            local squareContainer = _New("Frame")
            squareContainer.Size = _U2(1, -45 * scale, 1, -10 * scale)
            squareContainer.Position = _U2(0, 5 * scale, 0, 5 * scale)
            squareContainer.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            squareContainer.BorderSizePixel = 0
            squareContainer.Parent = pickerPanel
            local squareCorner = _New("UICorner")
            squareCorner.CornerRadius = _U(0, 6 * scale)
            squareCorner.Parent = squareContainer

            local satBrightGradient = _New("ImageLabel")
            satBrightGradient.Size = _U2(1, 0, 1, 0)
            satBrightGradient.BackgroundTransparency = 1
            satBrightGradient.Image = "rbxassetid://4155801252"
            satBrightGradient.ScaleType = Enum.ScaleType.Stretch
            satBrightGradient.Parent = squareContainer

            local hueContainer = _New("Frame")
            hueContainer.Size = _U2(0, 20 * scale, 1, -10 * scale)
            hueContainer.Position = _U2(1, -25 * scale, 0, 5 * scale)
            hueContainer.BackgroundTransparency = 1
            hueContainer.BorderSizePixel = 0
            hueContainer.Parent = pickerPanel

            local hueGradientBar = _New("Frame")
            hueGradientBar.Size = _U2(1, 0, 1, 0)
            hueGradientBar.BackgroundColor3 = _C3(255, 255, 255)
            hueGradientBar.BackgroundTransparency = 0
            hueGradientBar.BorderSizePixel = 0
            hueGradientBar.Parent = hueContainer
            local hueBarCorner = _New("UICorner")
            hueBarCorner.CornerRadius = _U(0, 6 * scale)
            hueBarCorner.Parent = hueGradientBar

            local hueGradient = _New("UIGradient")
            hueGradient.Rotation = 270
            hueGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, _C3(255, 0, 0)),
                ColorSequenceKeypoint.new(0.16, _C3(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, _C3(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, _C3(0, 255, 255)),
                ColorSequenceKeypoint.new(0.66, _C3(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, _C3(255, 0, 255)),
                ColorSequenceKeypoint.new(1, _C3(255, 0, 0)),
            })
            hueGradient.Parent = hueGradientBar

            local squareSelector = _New("ImageLabel")
            squareSelector.Size = _U2(0, 14 * scale, 0, 14 * scale)
            squareSelector.AnchorPoint = _V2(0.5, 0.5)
            squareSelector.BackgroundTransparency = 1
            squareSelector.Image = "rbxassetid://4805639000"
            squareSelector.ZIndex = 10
            squareSelector.Parent = squareContainer

            local hueSelector = _New("ImageLabel")
            hueSelector.Size = _U2(0, 14 * scale, 0, 14 * scale)
            hueSelector.AnchorPoint = _V2(0.5, 0.5)
            hueSelector.BackgroundTransparency = 1
            hueSelector.Image = "rbxassetid://4805639000"
            hueSelector.ZIndex = 10
            hueSelector.Parent = hueContainer

            local function updateColor()
                local color = Color3.fromHSV(h, s, v)
                colorPreview.BackgroundColor3 = color
                squareContainer.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                callback(color)
            end

            local function updateSquareSelectorPosition(xPos, yPos)
                squareSelector.Position = _U2(math.clamp(xPos, 0, 1), 0, math.clamp(yPos, 0, 1), 0)
            end

            local function updateHueSelectorPosition(yPos)
                hueSelector.Position = _U2(0.5, 0, math.clamp(yPos, 0, 1), 0)
            end

            local function updateFromSquareMouse(mouseX, mouseY)
                local xPos = math.clamp((mouseX - satBrightGradient.AbsolutePosition.X) / satBrightGradient.AbsoluteSize.X, 0, 1)
                local yPos = math.clamp((mouseY - satBrightGradient.AbsolutePosition.Y) / satBrightGradient.AbsoluteSize.Y, 0, 1)
                s = xPos
                v = 1 - yPos
                updateSquareSelectorPosition(xPos, yPos)
                updateColor()
            end

            local function updateFromHueMouse(mouseY)
                local yPos = math.clamp((mouseY - hueGradientBar.AbsolutePosition.Y) / hueGradientBar.AbsoluteSize.Y, 0, 1)
                h = 1 - yPos
                updateHueSelectorPosition(yPos)
                updateColor()
            end

            local function createDragHandler(target, onStart, onDrag)
                local dragging = false
                local connection = nil
                target.InputBegan:Connect(function(input)
                    if not isClickInput(input) then return end
                    dragging = true
                    onStart(input)
                    if connection then connection:Disconnect() end
                    connection = RunService.RenderStepped:Connect(function()
                        if dragging then onDrag() end
                    end)
                end)
                target.InputEnded:Connect(function(input)
                    if not isClickInput(input) then return end
                    dragging = false
                    if connection then connection:Disconnect(); connection = nil end
                end)
            end

            createDragHandler(hueGradientBar,
                function(input) updateFromHueMouse(input.Position.Y) end,
                function() updateFromHueMouse(Mouse.Y) end
            )

            createDragHandler(satBrightGradient,
                function(input) updateFromSquareMouse(input.Position.X, input.Position.Y) end,
                function() updateFromSquareMouse(Mouse.X, Mouse.Y) end
            )

            local function initializePositions()
                squareSelector.Position = _U2(s, 0, 1 - v, 0)
                hueSelector.Position = _U2(0.5, 0, 1 - h, 0)
            end

            expandBtn.MouseButton1Click:Connect(function()
                PlayClickSound()
                expanded = not expanded
                if expanded then
                    _Tween(container, _TInfo(0.2), {Size = _U2(1, 0, 0, 188 * scale)}):Play()
                    pickerPanel.Visible = true
                    task.wait()
                    initializePositions()
                else
                    _Tween(container, _TInfo(0.2), {Size = _U2(1, 0, 0, 38 * scale)}):Play()
                    task.wait(0.15)
                    pickerPanel.Visible = false
                end
            end)

            task.wait()
            initializePositions()
            updateColor()

            return wrap(container)
        end

        function elements:AddParagraph(config)
            local paraConfig = config or {}
            local title = paraConfig.Title or "标题"
            local content = paraConfig.Content or "内容"

            local container = _New("Frame")
            container.Parent = tabContent
            container.Size = _U2(1, 0, 0, 0)
            container.BackgroundTransparency = 1
            container.AutomaticSize = Enum.AutomaticSize.Y

            local titleLabel = CreateLabel(container, title, _U2(1, 0, 0, 24 * scale // 1), _U2(0, 0, 0, 0), ChronixUI.Themes[ChronixUI.CurrentTheme].Text, 16 * scale // 1, _FontGothamBold)
            local contentLabel = CreateLabel(container, content, _U2(1, 0, 0, 0), _U2(0, 0, 0, 28 * scale // 1), ChronixUI.Themes[ChronixUI.CurrentTheme].TextDark, 13 * scale // 1, _FontGotham)
            contentLabel.TextWrapped = true
            contentLabel.AutomaticSize = Enum.AutomaticSize.Y

            return wrap(container)
        end

        function elements:AddDivider()
            local divider = _New("Frame")
            divider.Parent = tabContent
            divider.Size = _U2(1, 0, 0, scale // 1)
            divider.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Border
            divider.BorderSizePixel = 0
            return wrap(divider)
        end

        function elements:AddTitle(text)
            return wrap(CreateLabel(tabContent, text, _U2(1, 0, 0, 40 * scale // 1), _U2(0, 0, 0, 0), ChronixUI.Themes[ChronixUI.CurrentTheme].Accent, 20 * scale // 1, _FontGothamBold))
        end

        function elements:AddLabel(text)
            return wrap(CreateLabel(tabContent, text, _U2(1, 0, 0, 30 * scale // 1), _U2(0, 0, 0, 0), ChronixUI.Themes[ChronixUI.CurrentTheme].Text, 14 * scale // 1, _FontGotham))
        end

        return elements
    end

    -- 设置 Tab
    local settingsElements = windowData:CreateTab({ Name = "设置", IsSettings = true })
    settingsElements:AddTitle("UI 设置")
    settingsElements:AddDivider()
    settingsElements:AddKeybind({
        Label = "菜单开关按键",
        Default = self.Settings.ToggleKeyName,
        Callback = function(key)
            local newKey = Enum.KeyCode[key]
            if not newKey then return end
            self.Settings.ToggleKey = newKey
            self.Settings.ToggleKeyName = key
            ContextActionService:UnbindAction(toggleActionName)
            bindToggleAction(newKey)
            self:Notify({
                Title = "设置",
                Content = string.format("菜单开关已设置为: %s", key),
                Type = "success",
                Duration = 3,
            })
        end
    })
    settingsElements:AddToggle({
        Label = "背景模糊效果",
        Default = ChronixUI.Settings.BackgroundBlur,
        Callback = function(value)
            ChronixUI.Settings.BackgroundBlur = value
            if windowVisible and not windowData.Minimized then
                setBlur(true, false)
            else
                setBlur(false, false)
            end
            ChronixUI:Notify({
                Title = "设置",
                Content = "背景模糊已" .. (value and "开启" or "关闭"),
                Type = "success",
                Duration = 2,
            })
        end
    })
    settingsElements:AddToggle({
        Label = "隐私模式",
        Default = ChronixUI.Settings.PrivacyMode,
        Callback = function(value)
            ChronixUI.Settings.PrivacyMode = value
            updatePlayerInfoDisplay()
            ChronixUI:Notify({
                Title = "隐私模式",
                Content = "隐私模式已" .. (value and "开启" or "关闭"),
                Type = "success",
                Duration = 2,
            })
        end
    })

    local themeNames = {}
    for themeName, _ in pairs(ChronixUI.Themes) do
        table.insert(themeNames, themeName)
    end
    table.sort(themeNames)

    settingsElements:AddDropdown({
        Label = "界面主题",
        Options = themeNames,
        Default = ChronixUI.CurrentTheme,
        Callback = function(selectedTheme)
            if ChronixUI.Themes[selectedTheme] then
                ChronixUI.CurrentTheme = selectedTheme
                windowData:UpdateTheme(selectedTheme)
                ChronixUI:Notify({
                    Title = "主题已切换",
                    Content = "当前主题: " .. selectedTheme,
                    Type = "success",
                    Duration = 2,
                })
            end
        end
    })
    settingsElements:AddDivider()
    settingsElements:AddLabel("其他设置")
    windowData.SettingsElements = settingsElements

    function windowData:RefreshContent()
        updateContentCanvas()
    end

    settingsBtn.MouseButton1Click:Connect(function()
        PlayClickSound()
        windowData:SelectTab("设置")
    end)

    table.insert(self.Windows, windowData)

    if ChronixUI.Settings.BackgroundBlur then
        setBlur(true, false)
    end

    return windowData
end

function ChronixUI:Destroy()
    for _, window in pairs(self.Windows) do
        if window.Gui then window.Gui:Destroy() end
    end
    self.Windows = {}
    if notificationScreenGui then
        notificationScreenGui:Destroy()
        notificationScreenGui = nil
        notificationContainer = nil
    end
end

function ChronixUI:SetTheme(themeName)
    if not self.Themes[themeName] then
        warn("ChronixUI: 主题 '" .. tostring(themeName) .. "' 不存在")
        return false
    end
    self.CurrentTheme = themeName
    for _, window in ipairs(self.Windows) do
        if window.UpdateTheme then window:UpdateTheme(themeName) end
    end
    return true
end

return ChronixUI
