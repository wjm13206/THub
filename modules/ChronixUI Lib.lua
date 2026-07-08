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
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local UIParticleSystem
task.spawn(function()
    local ok, result = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/UIParticleSystem.lua")
    if ok and result then
        local success, mod = pcall(loadstring, result)
        if success and mod then
            UIParticleSystem = mod()
        end
    end
end)

-- ========== 多图标库集成模块 ==========
local IconModule = {
    -- 默认图标类型
    DefaultType = "lucide",
    
    -- 所有可用的图标库
    AvailableTypes = {
        "lucide",
        "solar", 
        "craft",
        "geist",
        "sfsymbols",
        "gravity",
        "other",
    },
    
    -- 存储所有图标数据
    Icons = {},
    
    -- 加载状态
    Loaded = {},
    IsLoading = {},
}

-- 异步加载指定类型的图标库
function IconModule:LoadIconSet(iconType)
    if self.Loaded[iconType] or self.IsLoading[iconType] then
        return
    end
    
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

-- 加载所有图标库
function IconModule:LoadAll()
    for _, iconType in ipairs(self.AvailableTypes) do
        self:LoadIconSet(iconType)
    end
end

-- 设置默认图标类型
function IconModule:SetDefaultType(iconType)
    if table.find(self.AvailableTypes, iconType) then
        self.DefaultType = iconType
    end
end

-- 获取图标（支持指定类型）
function IconModule:GetIcon(iconName, iconType)
    iconType = iconType or self.DefaultType
    
    -- 如果还没加载，尝试同步加载（可能会阻塞，所以只做 fallback）
    if not self.Loaded[iconType] then
        self:LoadIconSet(iconType)
        return nil
    end
    
    local iconSet = self.Icons[iconType]
    if not iconSet then
        return nil
    end
    
    -- 直接返回资产 ID
    if iconSet[iconName] and type(iconSet[iconName]) == "string" and iconSet[iconName]:find("rbxassetid://") then
        return iconSet[iconName]
    end
    
    -- 如果是复杂格式，提取 Image 字段
    if iconSet.Icons and iconSet.Icons[iconName] then
        return iconSet.Icons[iconName].Image
    end
    
    return nil
end

-- 检查图标是否已加载
function IconModule:IsIconLoaded(iconName, iconType)
    iconType = iconType or self.DefaultType
    return self.Loaded[iconType] and self:GetIcon(iconName, iconType) ~= nil
end

-- 创建图标 ImageLabel
function IconModule:CreateIcon(iconName, size, color, iconType)
    local iconId = self:GetIcon(iconName, iconType)
    if not iconId then
        return nil
    end
    
    local iconLabel = Instance.new("ImageLabel")
    iconLabel.Size = size or UDim2.new(0, 24, 0, 24)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Image = iconId
    iconLabel.ScaleType = Enum.ScaleType.Fit
    
    if color then
        iconLabel.ImageColor3 = color
    end
    
    return iconLabel
end

-- 等待图标加载完成（异步）
function IconModule:WaitForIcon(iconName, iconType, callback)
    iconType = iconType or self.DefaultType
    
    task.spawn(function()
        local waited = 0
        while not self:IsIconLoaded(iconName, iconType) and waited < 5 do
            task.wait(0.5)
            waited = waited + 0.5
        end
        
        if self:IsIconLoaded(iconName, iconType) then
            callback(self:GetIcon(iconName, iconType))
        else
            callback(nil)
        end
    end)
end

-- 仅加载默认图标库（lucide），其他按需加载
IconModule:LoadIconSet(IconModule.DefaultType)
-- ========== 多图标库集成结束 ==========

-- 辅助：判断是否为点击/触摸输入
local function isClickInput(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

-- 设备类型判断
local function GetDeviceType()
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        return "Mobile"
    elseif UserInputService.MouseEnabled and not UserInputService.TouchEnabled then
        return "Desktop"
    elseif UserInputService.GamepadEnabled then
        return "Console"
    else
        return "Unknown"
    end
end

-- 主题颜色配置
ChronixUI.Themes = {
    Default = {
        Background = Color3.fromRGB(30, 30, 46),
        Sidebar = Color3.fromRGB(24, 24, 37),
        Accent = Color3.fromRGB(119, 221, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(170, 170, 170),
        Border = Color3.fromRGB(44, 44, 62),
        Card = Color3.fromRGB(37, 37, 53),
        Input = Color3.fromRGB(37, 37, 53),
        Hover = Color3.fromRGB(45, 45, 65),
        Success = Color3.fromRGB(46, 213, 115),
        Error = Color3.fromRGB(255, 71, 87),
        Warning = Color3.fromRGB(255, 165, 2),
        Info = Color3.fromRGB(102, 210, 246),
        NotificationBg = Color3.fromRGB(45, 45, 55),
        NotificationBorder = Color3.fromRGB(60, 60, 70),
        IconColor = Color3.fromRGB(255, 255, 255)
    },
    Light = {
        Background = Color3.fromRGB(245, 245, 250),
        Sidebar = Color3.fromRGB(235, 235, 240),
        Accent = Color3.fromRGB(0, 110, 200),
        Text = Color3.fromRGB(30, 30, 30),
        TextDark = Color3.fromRGB(90, 90, 90),
        Border = Color3.fromRGB(180, 180, 180),      
        Card = Color3.fromRGB(255, 255, 255),
        Input = Color3.fromRGB(255, 255, 255),
        Hover = Color3.fromRGB(230, 230, 235),
        Success = Color3.fromRGB(46, 125, 50),
        Error = Color3.fromRGB(211, 47, 47),
        Warning = Color3.fromRGB(237, 108, 0),
        Info = Color3.fromRGB(2, 136, 209),
        NotificationBg = Color3.fromRGB(250, 250, 255),
        NotificationBorder = Color3.fromRGB(200, 200, 210),
        IconColor = Color3.fromRGB(0, 0, 0)
    }
}
ChronixUI.CurrentTheme = "Default"

-- 音效
local function PlaySound(soundId, volume)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.3
    sound.Parent = SoundService
    sound:Play()
    game.Debris:AddItem(sound, 2)
end

local function PlayClickSound()
    PlaySound("rbxassetid://535716488", 0.3)
end

-- 获取玩家头像
local function GetPlayerAvatar(userId)
    return "https://www.roblox.com/avatar-thumbnail/image?userId=" .. userId .. "&width=420&height=420&format=png"
end

-- 辅助函数
local function CreateFrame(parent, size, position, color, transparency)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = size
    frame.Position = position or UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = color or Color3.fromRGB(255, 255, 255)
    frame.BackgroundTransparency = transparency or 0
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    return frame
end

local function CreateLabel(parent, text, size, position, color, textSize, font, alignment)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.Text = text or ""
    label.Size = size or UDim2.new(1, 0, 1, 0)
    label.Position = position or UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    label.TextSize = textSize or 14
    label.Font = font or Enum.Font.Gotham
    label.TextXAlignment = alignment or Enum.TextXAlignment.Left
    return label
end

local function AddStroke(obj, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(44, 44, 62)
    stroke.Thickness = thickness or 1
    stroke.Parent = obj
    return stroke
end

local function AddListLayout(parent, padding, order)
    local layout = Instance.new("UIListLayout")
    layout.Parent = parent
    layout.Padding = UDim.new(0, padding or 12)
    layout.SortOrder = order or Enum.SortOrder.LayoutOrder
    return layout
end

-- 包装 Instance，使其支持 :Destroy() 方法，同时方法调用正确转发
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
                return function(...)
                    return value(instance, ...)
                end
            end
            return value
        end,
        __newindex = function(t, k, v)
            instance[k] = v
        end
    })
end

-- ========== 通知系统（原封不动整合版 + 手机适配） ==========
local notifications = {}
local notificationScreenGui = nil
local notificationContainer = nil

-- 通知系统配置
local notificationConfig = {
    notificationWidth = 400,
    notificationHeight = 150,
    padding = 20,
    defaultDuration = 4,
}

-- 获取缩放比例
local function getScale()
    local isMobile = (UserInputService.TouchEnabled and not UserInputService.MouseEnabled)
    return isMobile and 0.5 or 1
end

-- 初始化通知 GUI
local function initNotificationScreenGui()
    if notificationScreenGui then return true end

    local scale = getScale()

    notificationScreenGui = Instance.new("ScreenGui")
    notificationScreenGui.Name = "ChronixNotifications"
    notificationScreenGui.IgnoreGuiInset = true
    notificationScreenGui.DisplayOrder = 10000
    notificationScreenGui.ResetOnSpawn = false
    if syn and syn.protect_gui then
        syn.protect_gui(notificationScreenGui)
        notificationScreenGui.Parent = cloneref(game.CoreGui)
    else
        notificationScreenGui.Parent = gethui and gethui() or cloneref(game.CoreGui)
    end

    -- 右侧中间位置的容器
    notificationContainer = Instance.new("Frame")
    notificationContainer.Name = "Container"
    notificationContainer.BackgroundTransparency = 1
    notificationContainer.Size = UDim2.new(0, notificationConfig.notificationWidth * scale, 1, 0)
    notificationContainer.Position = UDim2.new(1, 0, 0.52, 0)
    notificationContainer.AnchorPoint = Vector2.new(1, 0.5)
    notificationContainer.Parent = notificationScreenGui

    return true
end

local notifColorMap = {info="Info", success="Success", warning="Warning", error="Error"}

local function getColorByType(notifType)
    local t = ChronixUI.Themes[ChronixUI.CurrentTheme]
    local key = notifColorMap[notifType] or "Info"
    return t[key] or Color3.fromRGB(30, 144, 255)
end

-- 创建单个通知
local function createNotificationFrame(title, text, color)
    local scale = getScale()
    
    -- 外层容器（用于裁剪动画）
    local clipFrame = Instance.new("Frame")
    clipFrame.Name = "ClipFrame"
    clipFrame.Size = UDim2.new(1, 0, 0, notificationConfig.notificationHeight * scale)
    clipFrame.BackgroundTransparency = 1
    clipFrame.BorderSizePixel = 0
    clipFrame.ClipsDescendants = true
    
    -- 内层通知（实际内容）
    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrame"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(1, 0, 0, 0) -- 初始在右侧外
    frame.BackgroundColor3 = Color3.fromRGB(26, 26, 29)
    frame.BorderSizePixel = 0
    frame.Parent = clipFrame
    
    -- 渐变效果（从右到左）
    local uiGradient = Instance.new("UIGradient")
    uiGradient.Rotation = 180
    uiGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.04),
        NumberSequenceKeypoint.new(0.5, 0.25),
        NumberSequenceKeypoint.new(0.9, 0.45),
        NumberSequenceKeypoint.new(1, 1)
    })
    uiGradient.Parent = frame
    
    -- 标题
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = title
    titleLabel.TextColor3 = color
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 22 * scale
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Size = UDim2.new(1, -48 * scale, 0, 24 * scale)
    titleLabel.Position = UDim2.new(0, 34 * scale, 0, 20 * scale)
    titleLabel.Parent = frame
    
    -- 横线
    local line = Instance.new("Frame")
    line.BackgroundColor3 = color
    line.BorderSizePixel = 0
    line.Size = UDim2.new(1, 0, 0, 1 * scale)
    line.Position = UDim2.new(0, 34 * scale, 0, 50 * scale)
    line.Parent = frame
    
    -- 内容
    local contentLabel = Instance.new("TextLabel")
    contentLabel.Text = text
    contentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    contentLabel.BackgroundTransparency = 1
    contentLabel.Font = Enum.Font.Gotham
    contentLabel.TextSize = 18 * scale
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.Size = UDim2.new(1, -48 * scale, 0, 120 * scale)
    contentLabel.Position = UDim2.new(0, 34 * scale, 0, (55 + 8) * scale)
    contentLabel.TextYAlignment = Enum.TextYAlignment.Top
    contentLabel.TextWrapped = true
    contentLabel.Parent = frame
    
    return clipFrame, frame
end

-- 计算所有通知的总高度和起始位置
local function calculateLayout()
    if #notifications == 0 then return 0 end
    
    local scale = getScale()
    local scaledHeight = notificationConfig.notificationHeight * scale
    local scaledPadding = notificationConfig.padding * scale
    
    local totalHeight = (#notifications * scaledHeight) + ((#notifications - 1) * scaledPadding)
    local startY = -totalHeight / 2
    return startY
end

-- 更新所有通知位置
local function updateAllPositions()
    local startY = calculateLayout()
    local scale = getScale()
    local scaledHeight = notificationConfig.notificationHeight * scale
    local scaledPadding = notificationConfig.padding * scale
    
    for i, notification in ipairs(notifications) do
        if notification.clipFrame and notification.clipFrame.Parent then
            local targetY = startY + ((i - 1) * (scaledHeight + scaledPadding))
            notification.clipFrame.Position = UDim2.new(0, 0, 0.5, targetY)
        end
    end
end

local notifSoundMap = {
    info = "rbxassetid://129485210015224",
    success = "rbxassetid://129485210015224",
    warning = "rbxassetid://124951621656853",
    error = "rbxassetid://17525305988",
}

local function playNotificationSound(notifType)
    PlaySound(notifSoundMap[notifType] or "rbxassetid://4590662766", 0.5)
end

-- 动画辅助函数：滑入/滑出
local function animateSlide(frame, fromX, toX, direction)
    if not frame then return end
    frame.Position = UDim2.new(fromX, 0, 0, 0)
    local tween = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, direction), {
        Position = UDim2.new(toX, 0, 0, 0)
    })
    tween:Play()
end

-- 辅助函数：从列表中移除通知
local function removeNotification(notification)
    local index = table.find(notifications, notification)
    if index then
        table.remove(notifications, index)
        return true
    end
    return false
end

-- 核心通知函数
function ChronixUI:Notify(config)
    local title = config.Title or "通知"
    local content = config.Content or ""
    local duration = config.Duration or notificationConfig.defaultDuration
    local notifType = config.Type or "info"
    
    -- 确保容器存在
    if not notificationContainer then
        initNotificationScreenGui()
    end
    
    -- 获取颜色
    local color = getColorByType(notifType)
    
    -- 创建通知
    local clipFrame, innerFrame = createNotificationFrame(title, content, color)
    clipFrame.Parent = notificationContainer
    
    -- 创建通知对象
    local notification = {
        clipFrame = clipFrame,
        innerFrame = innerFrame,
        duration = duration
    }
    
    -- 添加到通知列表
    table.insert(notifications, notification)
    
    -- 播放音效
    playNotificationSound(notifType)
    
    -- 更新所有位置
    updateAllPositions()
    
    -- 等待一帧确保渲染完成
    RunService.Heartbeat:Wait()
    
    -- 入场动画
    task.spawn(animateSlide, innerFrame, 1, 0, Enum.EasingDirection.Out)
    
    -- 处理通知生命周期
    task.spawn(function()
        task.wait(duration)
        
        if not clipFrame or not clipFrame.Parent then
            removeNotification(notification)
            updateAllPositions()
            return
        end
        
        animateSlide(innerFrame, 0, 1, Enum.EasingDirection.In)
        
        removeNotification(notification)
        if clipFrame and clipFrame.Parent then
            clipFrame:Destroy()
        end
        updateAllPositions()
    end)
    
    return notification
end
-- ========== 通知系统结束 ==========

-- 窗口拖动功能（修复断开问题，使用全局 InputEnded 监听）
local function MakeDraggable(frame, dragHandle)
    local dragging = false
    local dragStart, startPos

    local function beginDrag(input)
        if isClickInput(input) then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end

    local function endDrag(input)
        if isClickInput(input) then
            dragging = false
            dragStart = nil
            startPos = nil
        end
    end

    dragHandle.InputBegan:Connect(beginDrag)
    -- 使用全局 InputEnded 确保无论鼠标/手指在何处松开都能正确结束拖动
    UserInputService.InputEnded:Connect(endDrag)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                       startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- 创建主窗口
function ChronixUI:CreateWindow(config)
    config = config or {}
    
    local isMobile = (GetDeviceType() == "Mobile")
    local scale = isMobile and 0.7 or 1          -- 手机端缩放 70%

    local defaultWidth = 680
    local defaultHeight = 420
    local windowSize = config.Size or (isMobile and UDim2.new(0, px(defaultWidth), 0, px(defaultHeight)) or UDim2.new(0, defaultWidth, 0, defaultHeight))
    local windowName = config.Name or "Chronix UI"

    local gui = Instance.new("ScreenGui")
    gui.Name = "ChronixUI_" .. tostring(#self.Windows + 1)
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    if syn and syn.protect_gui then
        syn.protect_gui(gui)
        gui.Parent = cloneref(game.CoreGui)
    else
        gui.Parent = gethui and gethui() or cloneref(game.CoreGui)
    end

    -- 创建模糊效果（放在 Lighting 中才能模糊 3D 场景）
    local blurEffect = nil
    local function createBlurEffect()
        if blurEffect then return blurEffect end
        blurEffect = Instance.new("BlurEffect")
        blurEffect.Name = "ChronixUI_Blur"
        blurEffect.Size = 0  -- 初始为0
        blurEffect.Parent = Lighting
        return blurEffect
    end

    -- 平滑模糊控制
    local blurTween = nil
    local function setBlur(enabled, instant)
        local blur = createBlurEffect()
        
        -- 计算目标模糊程度
        local targetSize = 0
        if enabled and ChronixUI.Settings.BackgroundBlur then
            targetSize = ChronixUI.Settings.BlurSize
        else
            targetSize = 0  -- 关闭或禁用时都设为 0
        end
        
        if instant then
            blur.Size = targetSize
            return
        end
        
        if blurTween then
            blurTween:Cancel()
        end
        
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        blurTween = TweenService:Create(blur, tweenInfo, {Size = targetSize})
        blurTween:Play()
    end

    local theme = self.Themes[self.CurrentTheme]
    local px = function(n) return math.floor(n * scale) end

    local mainFrame = CreateFrame(gui, windowSize, UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2),
                                   theme.Background)
    AddStroke(mainFrame, theme.Border)

    local windowVisible = true
    local originalSize = windowSize
    local savedPosition = mainFrame.Position

    -- 使用 ContextActionService 绑定快捷键
    local toggleActionName = "ChronixUIToggle_" .. tostring(#self.Windows + 1)
    ContextActionService:BindAction(toggleActionName, function(actionName, inputState, inputObject)
        if inputState == Enum.UserInputState.Begin then
            if inputObject.KeyCode == self.Settings.ToggleKey then
                windowVisible = not windowVisible
                if windowVisible then
                    setBlur(true, false)  -- 显示菜单时开启模糊
                else
                    setBlur(false, false) -- 隐藏菜单时关闭模糊
                end
                mainFrame.Visible = windowVisible
                if not windowVisible and self.Settings.FirstHide then
                    self.Settings.FirstHide = false
                    self:Notify({
                        Title = "菜单已隐藏",
                        Content = string.format("按 %s 重新打开菜单", self.Settings.ToggleKeyName),
                        Type = "info",
                        Duration = 10
                    })
                end
                return Enum.ContextActionResult.Sink
            end
        end
        return Enum.ContextActionResult.Pass
    end, false, self.Settings.ToggleKey)

    -- 标题栏
    local titleBarHeight = px(45)
    local titleBar = CreateFrame(mainFrame, UDim2.new(1, 0, 0, titleBarHeight), UDim2.new(0, 0, 0, 0),
                                  theme.Background, 1)
    MakeDraggable(mainFrame, titleBar)

    -- 监听拖动，保存位置
    local function savePosition()
        if not windowData or not windowData.Minimized then
            savedPosition = mainFrame.Position
        end
    end
    mainFrame:GetPropertyChangedSignal("Position"):Connect(savePosition)

    -- 标题文字
    local titleFontSize = px(18)
    local titleLabel = CreateLabel(titleBar, windowName, UDim2.new(1, -140*scale, 1, 0), UDim2.new(0, 20*scale, 0, 0),
                                    theme.Accent, titleFontSize, Enum.Font.GothamBold)

    -- 按钮容器
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(0, 120*scale, 1, 0)
    buttonContainer.Position = UDim2.new(1, -130*scale, 0, 0)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = titleBar

    local btnSize = px(32)
    local btnOffset = px(38)

    -- 辅助函数：创建元素右侧图标
    local function createElementIcon(cfg)
        local parent = cfg.Parent
        if not parent then return end
        local hasIcon = cfg.HasIcon
        local iconName = cfg.IconName
        local iconType = cfg.IconType
        local iconColor = cfg.IconColor
        local name = cfg.Name or "ElementIcon"
        local position = cfg.Position or UDim2.new(1, -28 * scale, 0.5, -10 * scale)
        local size = cfg.Size or UDim2.new(0, 20 * scale, 0, 20 * scale)
        if hasIcon and iconName ~= "" then
            local iconLabel = IconModule:CreateIcon(iconName, size, iconColor, iconType)
            if iconLabel then
                iconLabel.Name = name
                iconLabel.Position = position
                iconLabel.Parent = parent
            else
                IconModule:WaitForIcon(iconName, iconType, function(iconId)
                    if iconId and parent and parent.Parent then
                        local newIcon = Instance.new("ImageLabel")
                        newIcon.Name = name
                        newIcon.Size = size
                        newIcon.Position = position
                        newIcon.BackgroundTransparency = 1
                        newIcon.Image = iconId
                        newIcon.ScaleType = Enum.ScaleType.Fit
                        if iconColor then newIcon.ImageColor3 = iconColor end
                        newIcon.Parent = parent
                    end
                end)
            end
        end
    end

    -- 辅助函数：创建标题栏按钮
    local function createTitleButton(position, text, textSize)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, btnSize, 0, btnSize)
        btn.Position = position
        btn.Text = text
        btn.TextColor3 = theme.Text
        btn.TextSize = textSize
        btn.BackgroundColor3 = theme.Card
        btn.BorderSizePixel = 0
        btn.Parent = buttonContainer
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, px(6))
        corner.Parent = btn
        AddStroke(btn, theme.Border)
        return btn
    end

    -- 设置按钮
    local settingsBtn = createTitleButton(UDim2.new(0, 0, 0.5, -btnSize/2), "≡", px(20))
    -- 最小化按钮
    local minBtn = createTitleButton(UDim2.new(0, btnOffset, 0.5, -btnSize/2), "−", px(24))
    -- 关闭按钮
    local closeBtn = createTitleButton(UDim2.new(0, btnOffset*2, 0.5, -btnSize/2), "×", px(20))

    -- 缓存 UIStroke 引用，供 UpdateTheme 使用
    local mainStroke = mainFrame:FindFirstChildOfClass("UIStroke")
    local settingsBtnStroke = settingsBtn:FindFirstChildOfClass("UIStroke")
    local minBtnStroke = minBtn:FindFirstChildOfClass("UIStroke")
    local closeBtnStroke = closeBtn:FindFirstChildOfClass("UIStroke")

    -- 底部玩家信息栏
    local playerBarHeight = px(50)
    local playerBar = CreateFrame(mainFrame, UDim2.new(1, 0, 0, playerBarHeight), UDim2.new(0, 0, 1, -playerBarHeight),
                                   theme.Card)
    AddStroke(playerBar, theme.Border)
    local playerBarStroke = playerBar:FindFirstChildOfClass("UIStroke")

    -- 头像容器
    local avatarSize = px(36)
    local avatarContainer = Instance.new("Frame")
    avatarContainer.Size = UDim2.new(0, avatarSize, 0, avatarSize)
    avatarContainer.Position = UDim2.new(0, 12*scale, 0.5, -avatarSize/2)
    avatarContainer.BackgroundColor3 = theme.Border
    avatarContainer.BorderSizePixel = 0
    avatarContainer.Parent = playerBar
    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(0, px(8))
    avatarCorner.Parent = avatarContainer

    local avatarImage = Instance.new("ImageLabel")
    avatarImage.Size = UDim2.new(1, -2, 1, -2)
    avatarImage.Position = UDim2.new(0, 1, 0, 1)
    avatarImage.BackgroundTransparency = 1
    avatarImage.Image = GetPlayerAvatar(LocalPlayer.UserId)
    avatarImage.Parent = avatarContainer
    local imageCorner = Instance.new("UICorner")
    imageCorner.CornerRadius = UDim.new(0, px(6))
    imageCorner.Parent = avatarImage

    local premiumBadge = Instance.new("ImageLabel")
    premiumBadge.Name = "PremiumBadge"
    premiumBadge.Size = UDim2.new(0, px(12), 0, px(12))
    premiumBadge.Position = UDim2.new(1, px(-4), 1, px(-4))
    premiumBadge.AnchorPoint = Vector2.new(1, 1)      -- 锚点在右下角
    premiumBadge.BackgroundTransparency = 1
    premiumBadge.Image = "rbxassetid://126540142153628"
    premiumBadge.ImageTransparency = 0.15
    premiumBadge.ScaleType = Enum.ScaleType.Fit
    premiumBadge.Visible = (LocalPlayer.MembershipType == Enum.MembershipType.Premium)
    premiumBadge.Parent = avatarContainer

    -- 玩家名称和游戏信息（稍后填充）
    local playerNameLabel = CreateLabel(playerBar, "", UDim2.new(0, 200*scale, 0, px(24)), UDim2.new(0, 60*scale, 0, 8*scale),
                                         theme.Text, px(16), Enum.Font.GothamBold)
    local playerInfoLabel = CreateLabel(playerBar, "", UDim2.new(0, 200*scale, 0, px(20)), UDim2.new(0, 60*scale, 0, 30*scale),
                                         theme.TextDark, px(12), 12)
    playerInfoLabel.Name = "PlayerInfoLabel"

    -- 获取游戏名的函数（需在 safePlayerInfo 前定义）
    local gameInfoCache = nil
    local function getGameName(universeId)
        if gameInfoCache then return gameInfoCache end
        local url = "https://games.roblox.com/v1/games?universeIds=" .. universeId
        local success, response = pcall(function()
            return game:HttpGet(url)
        end)
        if success then
            local data = HttpService:JSONDecode(response)
            if data.data and #data.data > 0 then
                gameInfoCache = data.data[1]
                return gameInfoCache
            end
        end
        return nil
    end
    
    -- 安全获取玩家信息
    local function updatePlayerInfoDisplay()
        local player = Players.LocalPlayer
        if not player then return end

        local platformInfo = UserInputService:GetPlatform().Name

        if ChronixUI.Settings.PrivacyMode then
            -- 隐私模式：显示遮盖字符
            playerNameLabel.Text = "####################"
            playerInfoLabel.Text = "####################"
            premiumBadge.Image = ""
            avatarImage.Image = ""
        else
            -- 正常模式：显示真实信息
            premiumBadge.Image = "rbxassetid://126540142153628"
            avatarImage.Image = GetPlayerAvatar(LocalPlayer.UserId)

            local executorname, executorversion = identifyexecutor()
            
            local nameStr = string.format(
                "欢迎~ %s#%d %s %s%s",
                player.DisplayName,
                player.UserId,
                platformInfo,
                executorname,
                executorversion
            )
            playerNameLabel.Text = nameStr
    
            local gameInfo = getGameName(game.GameId)
            if gameInfo then
                playerInfoLabel.Text = "在玩: " .. gameInfo.name .. " | ID: " .. game.GameId
            else
                playerInfoLabel.Text = "未找到游戏信息, 未找到游戏ID | Debug: InConsole"
            end
        end
    end

    -- 初始化时调用
    updatePlayerInfoDisplay()

    -- 侧边栏
    local sidebarWidth = px(160)
    local sidebar = CreateFrame(mainFrame, UDim2.new(0, sidebarWidth, 1, -playerBarHeight - titleBarHeight), UDim2.new(0, 0, 0, titleBarHeight),
                                 theme.Sidebar)

    local sidebarTitle = CreateLabel(sidebar, "功能菜单", UDim2.new(1, 0, 0, 40*scale), UDim2.new(0, 0, 0, 10*scale),
                                      theme.Accent, px(16), Enum.Font.GothamBold)
    sidebarTitle.TextXAlignment = Enum.TextXAlignment.Center

    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Parent = sidebar
    tabContainer.Size = UDim2.new(1, 0, 1, -60*scale)
    tabContainer.Position = UDim2.new(0, 0, 0, 50*scale)
    tabContainer.BackgroundTransparency = 1
    tabContainer.BorderSizePixel = 0
    tabContainer.ScrollBarThickness = px(6)
    tabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)

    local tabList = AddListLayout(tabContainer, px(8))

    -- 更新侧边栏滚动区域
    local function updateSidebarCanvas()
        tabContainer.CanvasSize = UDim2.new(0, 0, 0, tabList.AbsoluteContentSize.Y + 20*scale)
    end
    tabList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSidebarCanvas)

    -- 内容区域
    local contentArea = CreateFrame(mainFrame, UDim2.new(1, -sidebarWidth, 1, -playerBarHeight - titleBarHeight), UDim2.new(0, sidebarWidth, 0, titleBarHeight),
                                     theme.Background, 1)

    local contentScroll = Instance.new("ScrollingFrame")
    contentScroll.Parent = contentArea
    contentScroll.Size = UDim2.new(1, 0, 1, 0)
    contentScroll.BackgroundTransparency = 1
    contentScroll.BorderSizePixel = 0
    contentScroll.ScrollBarThickness = px(6)
    contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

    local contentLayout = AddListLayout(contentScroll, px(16))
    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingLeft = UDim.new(0, px(20))
    contentPadding.PaddingRight = UDim.new(0, px(20))
    contentPadding.PaddingTop = UDim.new(0, px(20))
    contentPadding.PaddingBottom = UDim.new(0, px(20))
    contentPadding.Parent = contentScroll

    -- 更新内容区域滚动
    local function updateContentCanvas()
        contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 40*scale)
    end
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateContentCanvas)

    -- 关闭按钮事件
    closeBtn.MouseButton1Click:Connect(function()
        PlayClickSound()
        -- 关闭模糊效果
        if blurEffect then
            blurEffect:Destroy()
            blurEffect = nil
        end
        ContextActionService:UnbindAction(toggleActionName)
        if gui then
            gui:Destroy()
        end
        if notificationScreenGui then
            notificationScreenGui:Destroy()
            notificationScreenGui = nil
            notificationContainer = nil
        end
        for i, window in pairs(self.Windows) do
            if window.Gui == gui then
                table.remove(self.Windows, i)
                break
            end
        end
        if config.CloseCallback then
            config.CloseCallback()
        end
    end)

    -- 窗口数据对象
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
        UpdateTheme = nil
    }

        -- 主题更新函数
    function windowData:UpdateTheme(themeName)
        local theme = ChronixUI.Themes[themeName]
        if not theme then return false end
        
        -- 1. 更新主框架背景和边框描边
        mainFrame.BackgroundColor3 = theme.Background
        if mainStroke then mainStroke.Color = theme.Border end
        
        -- 2. 更新侧边栏
        sidebar.BackgroundColor3 = theme.Sidebar
        sidebarTitle.TextColor3 = theme.Accent
        
        -- 3. 更新标题栏文字颜色
        titleLabel.TextColor3 = theme.Accent
        
        -- 4. 更新右上角按钮样式
        settingsBtn.BackgroundColor3 = theme.Card
        settingsBtn.TextColor3 = theme.Text
        if settingsBtnStroke then settingsBtnStroke.Color = theme.Border end
        minBtn.BackgroundColor3 = theme.Card
        minBtn.TextColor3 = theme.Text
        if minBtnStroke then minBtnStroke.Color = theme.Border end
        closeBtn.BackgroundColor3 = theme.Card
        closeBtn.TextColor3 = theme.Text
        if closeBtnStroke then closeBtnStroke.Color = theme.Border end
        
        -- 5. 更新底部玩家信息栏
        playerBar.BackgroundColor3 = theme.Card
        if playerBarStroke then playerBarStroke.Color = theme.Border end
        if avatarContainer then
            avatarContainer.BackgroundColor3 = theme.Border
        end
        playerNameLabel.TextColor3 = theme.Text
        playerInfoLabel.TextColor3 = theme.TextDark
        
        -- 6. 更新粒子系统颜色
        if self.ParticleSystem then
            self.ParticleSystem:setColor(theme.Accent)
        end
        
        -- 递归更新元素颜色（供Tab内容和设置页共用）
        local function updateElementColors(obj)
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                if obj:IsA("TextButton") then
                    local isSpecial = false
                    for _, tab in pairs(self.Tabs) do
                        if obj == tab.Button then
                            isSpecial = true
                            break
                        end
                    end
                    if not isSpecial then
                        obj.BackgroundColor3 = theme.Card
                    end
                elseif obj:IsA("TextBox") then
                    obj.BackgroundColor3 = theme.Input
                end
                
                if obj:FindFirstChild("IsTitle") then
                    obj.TextColor3 = theme.Accent
                elseif obj:FindFirstChild("IsDark") then
                    obj.TextColor3 = theme.TextDark
                else
                    obj.TextColor3 = theme.Text
                end
            end
            
            local stroke = obj:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = theme.Border
            end
            
            for _, child in ipairs(obj:GetChildren()) do
                updateElementColors(child)
            end
        end
        
        -- 7. 更新所有Tab按钮样式
        for _, tabData in pairs(self.Tabs) do
            if tabData.Button then
                tabData.Button.BackgroundColor3 = theme.Card
                tabData.Button.TextColor3 = theme.TextDark
            end
            
            -- 当前选中的Tab保持高亮
            if self.CurrentTab and self.CurrentTab.Name == tabData.Name then
                tabData.Button.BackgroundColor3 = theme.Accent
                tabData.Button.TextColor3 = Color3.fromRGB(0, 0, 0)
            end
            
            updateElementColors(tabData.Content)
        end
        
        -- 8. 单独处理设置页
        if self.SettingsTabContent then
            updateElementColors(self.SettingsTabContent)
        end
        
        return true
    end

    -- ========== 在这里添加粒子系统 ==========
    -- 在 windowData 定义之后添加
    if UIParticleSystem then
        local particleBgFrame = Instance.new("Frame")
        particleBgFrame.Name = "ParticleBackground"
        particleBgFrame.Size = UDim2.new(1, 0, 1, -titleBarHeight - playerBarHeight)
        particleBgFrame.Position = UDim2.new(0, 0, 0, titleBarHeight)
        particleBgFrame.BackgroundTransparency = 1
        particleBgFrame.BorderSizePixel = 0
        particleBgFrame.ClipsDescendants = true
        particleBgFrame.ZIndex = 5
        particleBgFrame.Parent = mainFrame
    
        windowData.ParticleSystem = UIParticleSystem.new(particleBgFrame)
        if windowData.ParticleSystem then
            windowData.ParticleSystem:setColor(theme.Accent)
        end
    end
    -- ========== 粒子系统添加结束 ==========

    -- Tab 切换方法（供局部 SelectTab 和设置按钮共用）
    function windowData:SelectTab(name)
        local t = ChronixUI.Themes[ChronixUI.CurrentTheme]
        for _, tab in pairs(self.Tabs) do
            if tab.Name == name then
                tab.Button.BackgroundColor3 = t.Accent
                tab.Button.TextColor3 = Color3.fromRGB(0, 0, 0)
                tab.Content.Visible = true
            else
                tab.Button.BackgroundColor3 = t.Background
                tab.Button.TextColor3 = t.TextDark
                tab.Content.Visible = false
            end
        end
        self.CurrentTab = { Name = name }
        updateContentCanvas()
    end

    -- 最小化功能
    minBtn.MouseButton1Click:Connect(function()
        PlayClickSound()
        windowData.Minimized = not windowData.Minimized
        -- 最小化时关闭模糊，还原时开启模糊
    if windowData.Minimized then
        setBlur(false, false)
    else
        setBlur(true, false)
    end
        if windowData.Minimized then
            savedPosition = mainFrame.Position
            TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, px(280), 0, titleBarHeight),
                Position = savedPosition
            }):Play()
            sidebar.Visible = false
            contentArea.Visible = false
            playerBar.Visible = false
            settingsBtn.Visible = false
            minBtn.Text = "+"
        else
            TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = originalSize,
                Position = savedPosition
            }):Play()
            sidebar.Visible = true
            contentArea.Visible = true
            playerBar.Visible = true
            settingsBtn.Visible = true
            minBtn.Text = "−"
        end
    end)

    -- 创建 Tab 函数
    function windowData:CreateTab(tabConfig)
        local tabName = tabConfig.Name or "Tab"
        local isSettings = tabConfig.IsSettings or false

        -- 图标配置
        local hasIcon = tabConfig.HasIcon or false
        local iconName = tabConfig.IconName or ""
        local iconType = tabConfig.IconType or "lucide"  -- lucide, solar, craft, geist, sfsymbols, gravity, other
        local iconColor = tabConfig.IconColor or theme.IconColor
        
        -- 计算文字偏移量
        local textPadding = 8 * scale
        local iconOffset = 0

        local tabBtn = Instance.new("TextButton")
        tabBtn.Parent = tabContainer
        tabBtn.Size = UDim2.new(1, -12*scale, 0, px(36))
        tabBtn.Position = UDim2.new(0, 6*scale, 0, 0)
        tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
        tabBtn.Text = ""
        tabBtn.TextColor3 = theme.TextDark
        tabBtn.TextSize = px(14)
        tabBtn.TextXAlignment = Enum.TextXAlignment.Left
        tabBtn.Font = Enum.Font.GothamSemibold
        tabBtn.BorderSizePixel = 0

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, px(4))
        btnCorner.Parent = tabBtn

        -- 图标 ImageLabel（如果需要）
        local iconLabel = nil
        if hasIcon and iconName ~= "" then
            local iconSize = UDim2.new(0, 18 * scale, 0, 18 * scale)
            local createdIcon = IconModule:CreateIcon(iconName, iconSize, iconColor, iconType)
            
            if createdIcon then
                iconLabel = createdIcon
                iconLabel.Name = "TabIcon"
                iconLabel.Position = UDim2.new(0, 8 * scale, 0.5, -9 * scale)
                iconLabel.Parent = tabBtn
                iconOffset = 26 * scale
            else
                -- 图标还没加载完，先预留位置，等加载完再补上
                iconOffset = 26 * scale
            end
        end
        
        -- 文字 Label
        local tabTextLabel = Instance.new("TextLabel")
        tabTextLabel.Name = "TabText"
        tabTextLabel.Size = UDim2.new(1, -textPadding - iconOffset - 8*scale, 1, 0)
        tabTextLabel.Position = UDim2.new(0, textPadding + iconOffset, 0, 0)
        tabTextLabel.BackgroundTransparency = 1
        tabTextLabel.Text = tabName
        tabTextLabel.TextColor3 = theme.TextDark
        tabTextLabel.TextSize = px(14)
        tabTextLabel.TextXAlignment = Enum.TextXAlignment.Left
        tabTextLabel.Font = Enum.Font.GothamSemibold
        tabTextLabel.Parent = tabBtn

        -- 延迟补加载图标
        if hasIcon and iconName ~= "" and not iconLabel then
            IconModule:WaitForIcon(iconName, iconType, function(iconId)
                if iconId and tabBtn and tabBtn.Parent then
                    local newIcon = Instance.new("ImageLabel")
                    newIcon.Name = "TabIcon"
                    newIcon.Size = UDim2.new(0, 18 * scale, 0, 18 * scale)
                    newIcon.Position = UDim2.new(0, 8 * scale, 0.5, -9 * scale)
                    newIcon.BackgroundTransparency = 1
                    newIcon.Image = iconId
                    newIcon.ScaleType = Enum.ScaleType.Fit
                    if iconColor then
                        newIcon.ImageColor3 = iconColor
                    end
                    newIcon.Parent = tabBtn
                end
            end)
        end

        tabBtn.MouseButton1Click:Connect(function()
            PlayClickSound()
        end)

        local tabContent = Instance.new("Frame")
        tabContent.Parent = contentScroll
        tabContent.Size = UDim2.new(1, 0, 0, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = false
        tabContent.AutomaticSize = Enum.AutomaticSize.Y

        local tabLayout = AddListLayout(tabContent, px(12))

        local function SelectTab()
            windowData:SelectTab(tabName)
        end

        tabBtn.MouseButton1Click:Connect(SelectTab)

        if isSettings then
            windowData.SettingsTabContent = tabContent
            tabBtn.Visible = false
        end

        if #windowData.Tabs == 0 and not isSettings then
            SelectTab()
        end

        local tabData = {
            Button = tabBtn,
            Content = tabContent,
            Layout = tabLayout,
            Name = tabName
        }

        table.insert(windowData.Tabs, tabData)

        -- UI 元素创建函数 - 所有控件返回包装对象，尺寸已缩放
        local elements = {}

        local function wrap(obj)
            return wrapInstance(obj)
        end

        function elements:AddButton(config)
            local btnConfig = config or {}
            local btnText = btnConfig.Text or "按钮"
            local callback = btnConfig.Callback or function() end

            -- === 新增：图标配置 ===
            local hasIcon = btnConfig.HasIcon or true
            local iconName = btnConfig.IconName or "mouse-pointer-click"
            local iconType = btnConfig.IconType or "lucide"
            local iconColor = btnConfig.IconColor or theme.IconColor
            -- =====================

            local btn = Instance.new("TextButton")
            btn.Parent = tabContent
            btn.Size = UDim2.new(1, 0, 0, px(38))
            btn.BackgroundColor3 = theme.Card
            btn.Text = btnText
            btn.TextColor3 = theme.Text
            btn.TextSize = px(14)
            btn.Font = Enum.Font.GothamSemibold
            btn.BorderSizePixel = 0
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, px(4))
            btnCorner.Parent = btn
            AddStroke(btn, theme.Border)

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

            local hoverTween
            btn.MouseEnter:Connect(function()
                if hoverTween then hoverTween:Cancel() end
                hoverTween = TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = theme.Hover})
                hoverTween:Play()
            end)

            btn.MouseLeave:Connect(function()
                if hoverTween then hoverTween:Cancel() end
                hoverTween = TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = theme.Card})
                hoverTween:Play()
            end)

            return wrap(btn)
        end

        function elements:AddDropdown(config)
            local dropdownConfig = config or {}
            local label = dropdownConfig.Label or "选项"
            local options = dropdownConfig.Options or {"选项1", "选项2", "选项3"}
            local default = dropdownConfig.Default or options[1]
            local callback = dropdownConfig.Callback or function() end

            -- === 新增：图标配置 ===
            local hasIcon = dropdownConfig.HasIcon or true
            local iconName = dropdownConfig.IconName or "chevron-down"
            local iconType = dropdownConfig.IconType or "lucide"
            local iconColor = dropdownConfig.IconColor or theme.IconColor
            -- =====================

            local container = Instance.new("Frame")
            container.Parent = tabContent
            container.Size = UDim2.new(1, 0, 0, px(70))
            container.BackgroundTransparency = 1
            container.AutomaticSize = Enum.AutomaticSize.Y

            local labelText = CreateLabel(container, label, UDim2.new(1, 0, 0, px(20)), UDim2.new(0, 0, 0, 0),
                                           theme.Text, px(14), Enum.Font.GothamSemibold)

            local dropdownBtn = Instance.new("TextButton")
            dropdownBtn.Parent = container
            dropdownBtn.Size = UDim2.new(1, 0, 0, px(36))
            dropdownBtn.Position = UDim2.new(0, 0, 0, px(28))
            dropdownBtn.BackgroundColor3 = theme.Input
            dropdownBtn.Text = "  " .. default
            dropdownBtn.TextColor3 = theme.Text
            dropdownBtn.TextSize = px(14)
            dropdownBtn.TextXAlignment = Enum.TextXAlignment.Left
            dropdownBtn.Font = Enum.Font.Gotham
            dropdownBtn.BorderSizePixel = 0
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, px(4))
            btnCorner.Parent = dropdownBtn
            AddStroke(dropdownBtn, theme.Border)

            createElementIcon({
                HasIcon = hasIcon,
                IconName = iconName,
                IconType = iconType,
                IconColor = iconColor,
                Parent = dropdownBtn,
                Name = "ButtonIcon",
            })

            local dropdownList = Instance.new("Frame")
            dropdownList.Parent = container
            dropdownList.Size = UDim2.new(1, 0, 0, 0)
            dropdownList.Position = UDim2.new(0, 0, 0, px(64))
            dropdownList.BackgroundColor3 = theme.Input
            dropdownList.ClipsDescendants = true
            dropdownList.Visible = false
            local listCorner = Instance.new("UICorner")
            listCorner.CornerRadius = UDim.new(0, px(4))
            listCorner.Parent = dropdownList
            AddStroke(dropdownList, theme.Border)

            local listLayout = AddListLayout(dropdownList, 0)

            local expanded = false
            local function collapseDropdown()
                TweenService:Create(dropdownList, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                task.wait(0.2)
                dropdownList.Visible = false
            end
            for _, option in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Parent = dropdownList
                optBtn.Size = UDim2.new(1, 0, 0, px(32))
                optBtn.BackgroundColor3 = theme.Input
                optBtn.Text = "  " .. option
                optBtn.TextColor3 = theme.Text
                optBtn.TextSize = px(14)
                optBtn.TextXAlignment = Enum.TextXAlignment.Left
                optBtn.Font = Enum.Font.Gotham
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
                    local totalHeight = #options * px(32)
                    TweenService:Create(dropdownList, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, totalHeight)}):Play()
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

            local container = Instance.new("Frame")
            container.Parent = tabContent
            container.Size = UDim2.new(1, 0, 0, px(70))
            container.BackgroundTransparency = 1

            local labelText = CreateLabel(container, label, UDim2.new(1, 0, 0, px(20)), UDim2.new(0, 0, 0, 0),
                                           theme.Text, px(14), Enum.Font.GothamSemibold)

            local valueLabel = CreateLabel(container, tostring(default), UDim2.new(0, px(50), 0, px(20)), UDim2.new(1, -60*scale, 0, 0),
                                            theme.Accent, px(14), Enum.Font.GothamBold)
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right

            local slider = Instance.new("Frame")
            slider.Parent = container
            slider.Size = UDim2.new(1, 0, 0, px(4))
            slider.Position = UDim2.new(0, 0, 0, px(40))
            slider.BackgroundColor3 = theme.Border
            slider.BorderSizePixel = 0
            local sliderCorner = Instance.new("UICorner")
            sliderCorner.CornerRadius = UDim.new(0, px(2))
            sliderCorner.Parent = slider

            local fill = Instance.new("Frame")
            fill.Parent = slider
            fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = theme.Accent
            fill.BorderSizePixel = 0
            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(0, px(2))
            fillCorner.Parent = fill

            local handle = Instance.new("Frame")
            handle.Parent = slider
            handle.Size = UDim2.new(0, px(12), 0, px(12))
            handle.Position = UDim2.new((default - min) / (max - min), -px(6), 0, -px(4))
            handle.BackgroundColor3 = theme.Accent
            handle.BorderSizePixel = 0
            local handleCorner = Instance.new("UICorner")
            handleCorner.CornerRadius = UDim.new(0, px(6))
            handleCorner.Parent = handle

            local dragging = false
            local function UpdateSlider(input)
                local pos = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + (max - min) * pos)
                fill.Size = UDim2.new(pos, 0, 1, 0)
                handle.Position = UDim2.new(pos, -px(6), 0, -px(4))
                valueLabel.Text = tostring(value)
                callback(value)
            end

            local sliderHitbox = Instance.new("TextButton")
            sliderHitbox.Parent = container
            sliderHitbox.Size = UDim2.new(1, 0, 0, px(30))
            sliderHitbox.Position = UDim2.new(0, 0, 0, px(35))
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
                if dragConnection then
                    dragConnection:Disconnect()
                    dragConnection = nil
                end
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

            local container = Instance.new("Frame")
            container.Parent = tabContent
            container.Size = UDim2.new(1, 0, 0, px(50))
            container.BackgroundTransparency = 1

            local labelText = CreateLabel(container, label, UDim2.new(1, -60*scale, 0, px(30)), UDim2.new(0, 0, 0, px(10)),
                                           theme.Text, px(14), Enum.Font.GothamSemibold)

            local toggleBtn = Instance.new("Frame")
            toggleBtn.Parent = container
            toggleBtn.Size = UDim2.new(0, px(50), 0, px(26))
            toggleBtn.Position = UDim2.new(1, -60*scale, 0, px(12))
            toggleBtn.BackgroundColor3 = default and theme.Accent or Color3.fromRGB(80, 80, 80)
            toggleBtn.BorderSizePixel = 0
            local toggleCorner = Instance.new("UICorner")
            toggleCorner.CornerRadius = UDim.new(0, px(13))
            toggleCorner.Parent = toggleBtn

            local toggleHandle = Instance.new("Frame")
            toggleHandle.Parent = toggleBtn
            toggleHandle.Size = UDim2.new(0, px(22), 0, px(22))
            toggleHandle.Position = default and UDim2.new(1, -26*scale, 0.5, -px(11)) or UDim2.new(0, px(4), 0.5, -px(11))
            toggleHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            toggleHandle.BorderSizePixel = 0
            local handleCorner = Instance.new("UICorner")
            handleCorner.CornerRadius = UDim.new(0, px(11))
            handleCorner.Parent = toggleHandle

            local toggled = default
            local toggleBtnTween, toggleHandleTween
            toggleBtn.InputBegan:Connect(function(input)
                if not isClickInput(input) then return end
                PlayClickSound()
                toggled = not toggled
                if toggleBtnTween then toggleBtnTween:Cancel() end
                if toggleHandleTween then toggleHandleTween:Cancel() end
                local targetColor = toggled and theme.Accent or Color3.fromRGB(80, 80, 80)
                local targetPos = toggled and UDim2.new(1, -26*scale, 0.5, -px(11)) or UDim2.new(0, px(4), 0.5, -px(11))
                toggleBtnTween = TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = targetColor})
                toggleBtnTween:Play()
                toggleHandleTween = TweenService:Create(toggleHandle, TweenInfo.new(0.2), {Position = targetPos})
                toggleHandleTween:Play()
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

            -- === 新增：图标配置 ===
            local hasIcon = inputConfig.HasIcon or true
            local iconName = inputConfig.IconName or "text-cursor-input"
            local iconType = inputConfig.IconType or "lucide"
            local iconColor = inputConfig.IconColor or theme.IconColor
            -- =====================

            local container = Instance.new("Frame")
            container.Parent = tabContent
            local containerHeight = customHeight and (customHeight + 34) or 70
            container.Size = UDim2.new(1, 0, 0, px(containerHeight))
            container.BackgroundTransparency = 1

            local labelText = CreateLabel(container, label, UDim2.new(1, 0, 0, px(20)), UDim2.new(0, 0, 0, 0),
                                           theme.Text, px(14), Enum.Font.GothamSemibold)

            local inputBox = Instance.new("TextBox")
            inputBox.Parent = container
            local inputHeight = customHeight and customHeight or 36
            inputBox.Size = UDim2.new(1, 0, 0, px(inputHeight))
            inputBox.Position = UDim2.new(0, 0, 0, px(28))
            inputBox.BackgroundColor3 = theme.Input
            inputBox.PlaceholderText = placeholder
            inputBox.PlaceholderColor3 = theme.TextDark
            inputBox.Text = default or ""
            inputBox.TextColor3 = theme.Text
            inputBox.TextSize = px(14)
            inputBox.Font = Enum.Font.Gotham
            inputBox.BorderSizePixel = 0
            inputBox.ClearTextOnFocus = clearTextOnFocus
                               
            if isMultiLine then
                inputBox.TextYAlignment = Enum.TextYAlignment.Top
                inputBox.TextXAlignment = Enum.TextXAlignment.Left
                inputBox.TextWrapped = true  -- 启用文本自动换行
                inputBox.MultiLine = true  -- 启用多行输入
            end

            local inputCorner = Instance.new("UICorner")
            inputCorner.CornerRadius = UDim.new(0, px(4))
            inputCorner.Parent = inputBox
            AddStroke(inputBox, theme.Border)

            local iconPosition = isMultiLine and UDim2.new(1, -28 * scale, 0, 8 * scale) or UDim2.new(1, -28 * scale, 0.5, -10 * scale)
            createElementIcon({
                HasIcon = hasIcon,
                IconName = iconName,
                IconType = iconType,
                IconColor = iconColor,
                Parent = inputBox,
                Name = "InputIcon",
                Position = iconPosition,
            })

            inputBox.FocusLost:Connect(function()
                callback(inputBox.Text)
            end)

            local wrapped = {}
            local inputBoxRef = inputBox
            
            setmetatable(wrapped, {
                __index = function(t, k)
                    if k == "Text" then
                        return inputBoxRef.Text
                    end
                    if k == "Destroy" then
                        return function()
                            container:Destroy()
                        end
                    end
                    local containerVal = container[k]
                    if containerVal ~= nil then
                        if type(containerVal) == "function" then
                            return function(...)
                                return containerVal(container, ...)
                            end
                        end
                        return containerVal
                    end
                    return nil
                end,
                __newindex = function(t, k, v)
                    if k == "Text" then
                        inputBoxRef.Text = tostring(v)
                    else
                        rawset(t, k, v)
                    end
                end
            })
            
            return wrapped
        end

        function elements:AddKeybind(config)
            local keybindConfig = config or {}
            local label = keybindConfig.Label or "按键绑定"
            local defaultKey = keybindConfig.Default or "未设置"
            local callback = keybindConfig.Callback or function() end

            -- === 新增：图标配置 ===
            local hasIcon = keybindConfig.HasIcon or true
            local iconName = keybindConfig.IconName or "mouse-pointer-click"
            local iconType = keybindConfig.IconType or "lucide"
            local iconColor = keybindConfig.IconColor or theme.IconColor
            -- =====================

            local container = Instance.new("Frame")
            container.Parent = tabContent
            container.Size = UDim2.new(1, 0, 0, px(70))
            container.BackgroundTransparency = 1

            local labelText = CreateLabel(container, label, UDim2.new(1, 0, 0, px(20)), UDim2.new(0, 0, 0, 0),
                                           theme.Text, px(14), Enum.Font.GothamSemibold)

            local keyBtn = Instance.new("TextButton")
            keyBtn.Parent = container
            keyBtn.Size = UDim2.new(1, 0, 0, px(36))
            keyBtn.Position = UDim2.new(0, 0, 0, px(28))
            keyBtn.BackgroundColor3 = theme.Input
            keyBtn.Text = defaultKey
            keyBtn.TextColor3 = theme.Accent
            keyBtn.TextSize = px(14)
            keyBtn.Font = Enum.Font.GothamBold
            keyBtn.BorderSizePixel = 0
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, px(4))
            btnCorner.Parent = keyBtn
            AddStroke(keyBtn, theme.Border)

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
                keyBtn.TextColor3 = theme.Text

                local connection
                connection = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        local key = input.KeyCode.Name
                        if key ~= "Unknown" then
                            keyBtn.Text = key
                            keyBtn.TextColor3 = theme.Accent
                            if callback then
                                callback(key)
                            end
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
            local default = colorConfig.Default or Color3.fromRGB(119, 221, 255)
            local callback = colorConfig.Callback or function() end
        
            local container = Instance.new("Frame")
            container.Parent = tabContent
            container.Size = UDim2.new(1, 0, 0, 38 * scale)
            container.BackgroundTransparency = 1
            container.AutomaticSize = Enum.AutomaticSize.Y
        
            local h, s, v = Color3.toHSV(default)
            local expanded = false
            
            -- 颜色预览条
            local header = Instance.new("Frame")
            header.Size = UDim2.new(1, 0, 0, 38 * scale)
            header.BackgroundTransparency = 1
            header.Parent = container
            
            local labelText = CreateLabel(header, label, UDim2.new(1, -50*scale, 1, 0), UDim2.new(0, 12*scale, 0, 0),
                theme.Text, 14 * scale, Enum.Font.GothamSemibold)
            
            local colorPreview = Instance.new("Frame")
            colorPreview.Size = UDim2.new(0, 30 * scale, 0, 30 * scale)
            colorPreview.Position = UDim2.new(1, -40*scale, 0.5, -15 * scale)
            colorPreview.BackgroundColor3 = default
            colorPreview.BorderSizePixel = 0
            colorPreview.Parent = header
            
            local previewCorner = Instance.new("UICorner")
            previewCorner.CornerRadius = UDim.new(0, 6 * scale)
            previewCorner.Parent = colorPreview
            AddStroke(colorPreview, theme.Border)
            
            local expandBtn = Instance.new("TextButton")
            expandBtn.Size = UDim2.new(1, 0, 1, 0)
            expandBtn.BackgroundTransparency = 1
            expandBtn.Text = ""
            expandBtn.Parent = header
            
            -- 颜色选择器面板
            local pickerPanel = Instance.new("Frame")
            pickerPanel.Size = UDim2.new(1, 0, 0, 150 * scale)
            pickerPanel.Position = UDim2.new(0, 0, 0, 38 * scale)
            pickerPanel.BackgroundTransparency = 1
            pickerPanel.Visible = false
            pickerPanel.Parent = container
            
            -- 色盘容器
            local squareContainer = Instance.new("Frame")
            squareContainer.Size = UDim2.new(1, -45 * scale, 1, -10 * scale)
            squareContainer.Position = UDim2.new(0, 5 * scale, 0, 5 * scale)
            squareContainer.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            squareContainer.BorderSizePixel = 0
            squareContainer.Parent = pickerPanel
            
            local squareCorner = Instance.new("UICorner")
            squareCorner.CornerRadius = UDim.new(0, 6 * scale)
            squareCorner.Parent = squareContainer
            
            local satBrightGradient = Instance.new("ImageLabel")
            satBrightGradient.Size = UDim2.new(1, 0, 1, 0)
            satBrightGradient.BackgroundTransparency = 1
            satBrightGradient.Image = "rbxassetid://4155801252"
            satBrightGradient.ScaleType = Enum.ScaleType.Stretch
            satBrightGradient.Parent = squareContainer
            
            -- 色相条容器
            local hueContainer = Instance.new("Frame")
            hueContainer.Size = UDim2.new(0, 20 * scale, 1, -10 * scale)
            hueContainer.Position = UDim2.new(1, -25 * scale, 0, 5 * scale)
            hueContainer.BackgroundTransparency = 1
            hueContainer.BorderSizePixel = 0
            hueContainer.Parent = pickerPanel
            
            local hueCorner = Instance.new("UICorner")
            hueCorner.CornerRadius = UDim.new(0, 6 * scale)
            hueCorner.Parent = hueContainer
            
            local hueGradientBar = Instance.new("Frame")
            hueGradientBar.Size = UDim2.new(1, 0, 1, 0)
            hueGradientBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            hueGradientBar.BackgroundTransparency = 0
            hueGradientBar.BorderSizePixel = 0
            hueGradientBar.Parent = hueContainer
            
            local hueBarCorner = Instance.new("UICorner")
            hueBarCorner.CornerRadius = UDim.new(0, 6 * scale)
            hueBarCorner.Parent = hueGradientBar
            
            local hueGradient = Instance.new("UIGradient")
            hueGradient.Rotation = 270
            hueGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
            })
            hueGradient.Parent = hueGradientBar
            
            -- 选择器圆点 - 关键修复：设置正确的锚点
            local squareSelector = Instance.new("ImageLabel")
            squareSelector.Size = UDim2.new(0, 14 * scale, 0, 14 * scale)
            squareSelector.AnchorPoint = Vector2.new(0.5, 0.5)  -- 中心锚点
            squareSelector.BackgroundTransparency = 1
            squareSelector.Image = "rbxassetid://4805639000"
            squareSelector.ZIndex = 10
            squareSelector.Parent = squareContainer
            
            local hueSelector = Instance.new("ImageLabel")
            hueSelector.Size = UDim2.new(0, 14 * scale, 0, 14 * scale)
            hueSelector.AnchorPoint = Vector2.new(0.5, 0.5)  -- 中心锚点
            hueSelector.BackgroundTransparency = 1
            hueSelector.Image = "rbxassetid://4805639000"
            hueSelector.ZIndex = 10
            hueSelector.Parent = hueContainer
            
            -- 更新颜色显示
            local function updateColor()
                local color = Color3.fromHSV(h, s, v)
                colorPreview.BackgroundColor3 = color
                squareContainer.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                callback(color)
            end
            
            -- 更新选择器位置 - 关键修复：简化计算，直接映射鼠标位置
            local function updateSquareSelectorPosition(xPos, yPos)
                -- 因为锚点是0.5,0.5，位置就是鼠标坐标在容器中的比例位置
                -- 不需要额外偏移计算
                local clampedX = math.clamp(xPos, 0, 1)
                local clampedY = math.clamp(yPos, 0, 1)
                squareSelector.Position = UDim2.new(clampedX, 0, clampedY, 0)
            end
            
            local function updateHueSelectorPosition(yPos)
                local clampedY = math.clamp(yPos, 0, 1)
                hueSelector.Position = UDim2.new(0.5, 0, clampedY, 0)
            end
            
            -- 从鼠标位置更新所有值
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
            
            -- 拖动辅助函数
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
                    if connection then
                        connection:Disconnect()
                        connection = nil
                    end
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
            
            -- 初始化位置
            local function initializePositions()
                -- 设置色盘选择器位置
                local initialX = s
                local initialY = 1 - v
                squareSelector.Position = UDim2.new(initialX, 0, initialY, 0)
                
                -- 设置色相选择器位置
                local initialHueY = 1 - h
                hueSelector.Position = UDim2.new(0.5, 0, initialHueY, 0)
            end
            
            -- 展开/收起
            expandBtn.MouseButton1Click:Connect(function()
                PlayClickSound()
                expanded = not expanded
                if expanded then
                    TweenService:Create(container, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 188 * scale)}):Play()
                    pickerPanel.Visible = true
                    task.wait()
                    initializePositions()
                else
                    TweenService:Create(container, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 38 * scale)}):Play()
                    task.wait(0.15)
                    pickerPanel.Visible = false
                end
            end)
            
            -- 初始化
            task.wait()
            initializePositions()
            updateColor()
            
            return wrap(container)
        end

        function elements:AddParagraph(config)
            local paraConfig = config or {}
            local title = paraConfig.Title or "标题"
            local content = paraConfig.Content or "内容"

            local container = Instance.new("Frame")
            container.Parent = tabContent
            container.Size = UDim2.new(1, 0, 0, 0)
            container.BackgroundTransparency = 1
            container.AutomaticSize = Enum.AutomaticSize.Y

            local titleLabel = CreateLabel(container, title, UDim2.new(1, 0, 0, px(24)), UDim2.new(0, 0, 0, 0),
                                            theme.Text, px(16), Enum.Font.GothamBold)

            local contentLabel = CreateLabel(container, content, UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, px(28)),
                                              theme.TextDark, px(13), Enum.Font.Gotham)
            contentLabel.TextWrapped = true
            contentLabel.AutomaticSize = Enum.AutomaticSize.Y

            return wrap(container)
        end

        function elements:AddDivider()
            local divider = Instance.new("Frame")
            divider.Parent = tabContent
            divider.Size = UDim2.new(1, 0, 0, px(1))
            divider.BackgroundColor3 = theme.Border
            divider.BorderSizePixel = 0

            return wrap(divider)
        end

        function elements:AddTitle(text)
            local title = CreateLabel(tabContent, text, UDim2.new(1, 0, 0, px(40)), UDim2.new(0, 0, 0, 0),
                                       theme.Accent, px(20), Enum.Font.GothamBold)

            return wrap(title)
        end

        function elements:AddLabel(text)
            local label = CreateLabel(tabContent, text, UDim2.new(1, 0, 0, px(30)), UDim2.new(0, 0, 0, 0),
                                       theme.Text, px(14), Enum.Font.Gotham)

            return wrap(label)
        end

        return elements
    end

    -- 创建内置设置 Tab（不在侧边栏显示）
    local settingsElements = windowData:CreateTab({ Name = "设置", IsSettings = true })
    settingsElements:AddTitle("UI 设置")
    settingsElements:AddDivider()
    settingsElements:AddKeybind({
        Label = "菜单开关按键",
        Default = self.Settings.ToggleKeyName,
        Callback = function(key)
            local newKey = Enum.KeyCode[key]
            if newKey then
                self.Settings.ToggleKey = newKey
                self.Settings.ToggleKeyName = key
                ContextActionService:UnbindAction(toggleActionName)
                ContextActionService:BindAction(toggleActionName, function(actionName, inputState, inputObject)
                    if inputState == Enum.UserInputState.Begin then
                        if inputObject.KeyCode == self.Settings.ToggleKey then
                            windowVisible = not windowVisible
                            mainFrame.Visible = windowVisible
                            if not windowVisible and self.Settings.FirstHide then
                                self.Settings.FirstHide = false
                                self:Notify({
                                    Title = "菜单已隐藏",
                                    Content = string.format("按 %s 重新打开菜单", self.Settings.ToggleKeyName),
                                    Type = "info",
                                    Duration = 10
                                })
                            end
                            return Enum.ContextActionResult.Sink
                        end
                    end
                    return Enum.ContextActionResult.Pass
                end, false, self.Settings.ToggleKey)
                self:Notify({
                    Title = "设置",
                    Content = string.format("菜单开关已设置为: %s", key),
                    Type = "success",
                    Duration = 3
                })
            end
        end
    })
    -- 背景模糊开关
    settingsElements:AddToggle({
        Label = "背景模糊效果",
        Default = ChronixUI.Settings.BackgroundBlur,
        Callback = function(value)
            ChronixUI.Settings.BackgroundBlur = value
            
            -- 根据当前菜单状态决定是否应用模糊
            if windowVisible and not windowData.Minimized then
                -- 菜单显示中：根据新设置更新模糊
                setBlur(true, false)
            else
                -- 菜单隐藏中：强制关闭模糊
                setBlur(false, false)
            end
            
            ChronixUI:Notify({
                Title = "设置",
                Content = "背景模糊已" .. (value and "开启" or "关闭"),
                Type = "success",
                Duration = 2
            })
        end
    })
    -- 隐私模式开关
    settingsElements:AddToggle({
        Label = "隐私模式",
        Default = ChronixUI.Settings.PrivacyMode,
        Callback = function(value)
            ChronixUI.Settings.PrivacyMode = value
            -- 更新底部信息栏显示
            updatePlayerInfoDisplay()
        
            ChronixUI:Notify({
                Title = "隐私模式",
                Content = "隐私模式已" .. (value and "开启" or "关闭"),
                Type = "success",
                Duration = 2
            })
        end
    })
    -- 添加主题切换下拉菜单
    local themeNames = {}
    for themeName, _ in pairs(ChronixUI.Themes) do
        table.insert(themeNames, themeName)
    end
    table.sort(themeNames) -- 按字母排序，看起来整齐
    
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
                    Duration = 2
                })
            end
        end
    })
    settingsElements:AddDivider()
    settingsElements:AddLabel("其他设置")
    windowData.SettingsElements = settingsElements

    -- 添加刷新内容的方法
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

-- 销毁所有窗口
function ChronixUI:Destroy()
    for _, window in pairs(self.Windows) do
        if window.Gui then
            window.Gui:Destroy()
        end
    end
    self.Windows = {}
    if notificationScreenGui then
        notificationScreenGui:Destroy()
        notificationScreenGui = nil
        notificationContainer = nil
    end
end

-- 设置主题
function ChronixUI:SetTheme(themeName)
    if not self.Themes[themeName] then
        warn("ChronixUI: 主题 '" .. tostring(themeName) .. "' 不存在")
        return false
    end
    
    self.CurrentTheme = themeName
    
    -- 遍历所有窗口，调用它们的 UpdateTheme 方法
    for _, window in ipairs(self.Windows) do
        if window.UpdateTheme then
            window:UpdateTheme(themeName)
        end
    end
    
    return true
end

return ChronixUI