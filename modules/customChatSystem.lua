local cloneref = cloneref or clonereference or function(obj) return obj end
local translateModuel = loadstring(game:HttpGet("https://raw.gitcode.com/Furrycalin/RobloxScripts/raw/main/translateModuel.lua"))()
local chatControl = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/ChatControl.lua"))()
local TopbarLuau = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/TopbarLuau/raw/main/init.lua"))()
local Players = cloneref(game:GetService("Players"))
local player = Players.LocalPlayer
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))

local colorCache = {}

-- 颜色表
local colortable = {
    Color3.fromRGB(152, 109, 216), -- 原颜色：紫色（中等饱和度）
    Color3.fromRGB(237, 39, 64),   -- 原颜色：红色（高饱和度）
    Color3.fromRGB(3, 173, 82),    -- 原颜色：绿色（中等饱和度）
    Color3.fromRGB(239, 200, 47),  -- 原颜色：黄色（中等饱和度）
    Color3.fromRGB(227, 182, 196), -- 原颜色：粉红色（低饱和度）
    Color3.fromRGB(3, 143, 225),   -- 原颜色：蓝色（中等饱和度）
    Color3.fromRGB(211, 193, 151), -- 原颜色：米黄色（低饱和度）
    Color3.fromRGB(207, 126, 62),  -- 原颜色：橙色（中等饱和度）

    -- 新增的 10 个亮色
    Color3.fromRGB(255, 105, 180), -- 亮粉色（高饱和度）
    Color3.fromRGB(255, 165, 0),   -- 亮橙色（高饱和度）
    Color3.fromRGB(255, 215, 0),   -- 亮金色（高饱和度）
    Color3.fromRGB(173, 216, 230), -- 亮天蓝色（低饱和度）
    Color3.fromRGB(144, 238, 144), -- 亮绿色（低饱和度）
    Color3.fromRGB(255, 182, 193), -- 亮粉红色（低饱和度）
    Color3.fromRGB(240, 230, 140), -- 亮卡其色（低饱和度）
    Color3.fromRGB(221, 160, 221), -- 亮紫色（低饱和度）
    Color3.fromRGB(152, 251, 152), -- 亮薄荷绿（低饱和度）
    Color3.fromRGB(255, 239, 213), -- 亮米白色（低饱和度）

    -- 新增的 10 个新颖亮色
    Color3.fromRGB(255, 127, 80),  -- 珊瑚色（高饱和度）
    Color3.fromRGB(255, 99, 71),   -- 番茄色（高饱和度）
    Color3.fromRGB(255, 218, 185), -- 桃色（低饱和度）
    Color3.fromRGB(240, 128, 128), -- 亮珊瑚色（中等饱和度）
    Color3.fromRGB(255, 160, 122), -- 浅橙红色（中等饱和度）
    Color3.fromRGB(255, 228, 181), -- 杏仁色（低饱和度）
    Color3.fromRGB(255, 222, 173), -- 玉米色（低饱和度）
    Color3.fromRGB(255, 239, 213), -- 蛋壳色（低饱和度）
    Color3.fromRGB(240, 248, 255), -- 天青蓝（低饱和度）
    Color3.fromRGB(245, 245, 220),  -- 米黄色（低饱和度）

    -- 季节
    Color3.fromRGB(173, 255, 47), -- 春绿色（明亮、清新）
    Color3.fromRGB(255, 182, 193), -- 樱花粉（柔和、浪漫）
    Color3.fromRGB(255, 223, 186), -- 春日阳光（温暖、明亮）
    Color3.fromRGB(255, 215, 0), -- 夏日金黄（热烈、活力）
    Color3.fromRGB(0, 255, 255), -- 海洋蓝（清凉、透明）
    Color3.fromRGB(255, 99, 71), -- 夏日番茄红（热情、活力）
    Color3.fromRGB(255, 165, 0), -- 秋叶橙（温暖、丰收）
    Color3.fromRGB(210, 105, 30), -- 棕色（沉稳、自然）
    Color3.fromRGB(255, 69, 0), -- 枫叶红（鲜艳、醒目）
    Color3.fromRGB(173, 216, 230), -- 冰雪蓝（冷静、纯净）
    Color3.fromRGB(240, 248, 255), -- 雪白色（明亮、干净）
    Color3.fromRGB(135, 206, 250), -- 冬日天空蓝（清新、宁静）

    -- 心情
    Color3.fromRGB(255, 223, 0), -- 阳光黄（明亮、愉悦）
    Color3.fromRGB(255, 105, 180), -- 快乐粉（活泼、可爱）
    Color3.fromRGB(173, 216, 230), -- 天空蓝（宁静、放松）
    Color3.fromRGB(152, 251, 152), -- 薄荷绿（清新、平和）
    Color3.fromRGB(255, 69, 0), -- 火焰红（激情、活力）
    Color3.fromRGB(255, 140, 0), -- 橙色（热烈、兴奋）
    Color3.fromRGB(135, 206, 250), -- 浅蓝（柔和、安静）
    Color3.fromRGB(221, 160, 221), -- 淡紫（温柔、内敛）

    -- 水果
    Color3.fromRGB(255, 59, 48), -- 苹果红（鲜艳、醒目）
    Color3.fromRGB(155, 255, 155), -- 青苹果绿（清新、自然）
    Color3.fromRGB(255, 255, 102), -- 柠檬黄（明亮、活力）
    Color3.fromRGB(255, 105, 180), -- 草莓粉（甜美、可爱）
    Color3.fromRGB(255, 165, 0), -- 橙子橙（温暖、活力）
    Color3.fromRGB(79, 134, 247), -- 蓝莓蓝（深邃、自然）

    -- 植物
    Color3.fromRGB(34, 139, 34), -- 森林绿（自然、沉稳）
    Color3.fromRGB(152, 251, 152), -- 嫩叶绿（清新、生机）
    Color3.fromRGB(255, 105, 180), -- 樱花粉（浪漫、柔和）
    Color3.fromRGB(255, 20, 147), -- 玫瑰红（热情、艳丽）
    Color3.fromRGB(124, 252, 0), -- 草地绿（明亮、自然）
    Color3.fromRGB(0, 128, 0) -- 深绿（沉稳、自然）
}

-- 函数：从颜色表中随机选择一个颜色
local function getRandomColor(colortable)
    return colortable[math.random(1, #colortable)]
end

-- 封装函数：根据文本生成固定颜色
local function getColorForText(text)
    if not text or type(text) ~= "string" then
        warn("输入文本无效，必须是一个字符串。")
        return Color3.new(1, 1, 1) -- 返回默认颜色（白色）
    end

    if colorCache[text] then
        return colorCache[text]
    end

    local color = getRandomColor(colortable)
    colorCache[text] = color
    return color
end

-- 函数：将字改变颜色
local function setTextColor(text, startIndex, endIndex, color)
    local coloredText = text:sub(startIndex, endIndex)
    local coloredTextWithTag = string.format('<font color="#%s">%s</font>', color:ToHex(), coloredText)
    return text:sub(1, startIndex - 1) .. coloredTextWithTag .. text:sub(endIndex + 1)
end

-- 定义替换表
local replaceTable = {
    a='ᴀ', b='ʙ', c='ᴄ', d='ᴅ', e='ᴇ', f='ғ', g='ɢ', h='ʜ', i='ɪ', j='ᴊ',
    k='ᴋ', l='ʟ', m='ᴍ', n='ɴ', o='ᴏ', p='ᴘ', q='ǫ', r='ʀ', s='ꜱ', t='ᴛ',
    u='ᴜ', v='ᴠ', w='ᴡ', x='x', y='ʏ', z='ᴢ',
    A='ᴀ', B='ʙ', C='ᴄ', D='ᴅ', E='ᴇ', F='ғ', G='ɢ', H='ʜ', I='ɪ', J='ᴊ',
    K='ᴋ', L='ʟ', M='ᴍ', N='ɴ', O='ᴏ', P='ᴘ', Q='ǫ', R='ʀ', S='ꜱ', T='ᴛ',
    U='ᴜ', V='ᴠ', W='ᴡ', X='x', Y='ʏ', Z='ᴢ'
}

local function replaceText(text)
    local result = ""
    for i = 1, #text do
        local char = text:sub(i, i)
        result = result .. (replaceTable[char] or char)
    end
    return result
end

local lastMouseHoverTime = os.time()
local isHiding = false
local activeTween = nil

local hoverTimeout = 10          -- 隐藏超时时间(秒)

-- 创建自定义聊天栏
local function createCustomChat()
    local translateAPI = "YouDao"
    local autotranslate = false
    local chatlog = {}
    local replacefont = "default"
    local repf = false

    -- 创建 ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CustomChat"
    screenGui.Parent = game.CoreGui
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    pcall(function() syn.protect_gui(screenGui) end)

    cloneref(game:GetService("StarterGui")):SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)

    -- 创建聊天栏背景
    local chatFrame = Instance.new("Frame")
    chatFrame.Name = "ChatFrame"
    chatFrame.Size = UDim2.new(0.278, 0, 0.31, 4)
    chatFrame.Position = UDim2.new(0, 10, 0, 6)
    chatFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    chatFrame.BackgroundTransparency = 0.4
    chatFrame.Parent = screenGui

    local corner999 = Instance.new("UICorner", chatFrame)
    corner999.CornerRadius = UDim.new(0, 7)

    -- 创建消息滚动区域
    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Name = "MessageScroll"
    scrollingFrame.Size = UDim2.new(1, 0, 0.84, 0)
    scrollingFrame.Position = UDim2.new(0, 0, 0, 0)
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.ScrollBarThickness = 5
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollingFrame.Parent = chatFrame

    local corner2 = Instance.new("UICorner", scrollingFrame)
    corner2.CornerRadius = UDim.new(0, 5)

    -- 创建消息布局
    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Padding = UDim.new(0, 5)
    uiListLayout.Parent = scrollingFrame

    -- 创建输入栏容器
    local inputContainer = Instance.new("Frame")
    inputContainer.Name = "InputContainer"
    inputContainer.Size = UDim2.new(0.98, 0, 0.13, 0)
    inputContainer.Position = UDim2.new(0, 5, 0.85, -2)
    inputContainer.BackgroundColor3 = Color3.new(0, 0, 0)
    inputContainer.BackgroundTransparency = 0.5
    inputContainer.Parent = chatFrame

    local corner3 = Instance.new("UICorner", inputContainer)
    corner3.CornerRadius = UDim.new(0, 5)

    local inputStroke = Instance.new("UIStroke", inputContainer)
    inputStroke.Color = Color3.new(0.3, 0.3, 0.3)
    inputStroke.Thickness = 1

    -- 创建输入栏
    local inputBox = Instance.new("TextBox")
    inputBox.Name = "InputBox"
    inputBox.Size = UDim2.new(0.9, 0, 1, 0)
    inputBox.Position = UDim2.new(0.043, 0, 0, 0)
    inputBox.BackgroundColor3 = Color3.new(0, 0, 0)
    inputBox.TextColor3 = Color3.new(1, 1, 1)
    inputBox.PlaceholderText = "若要聊天，请点按此处或按下\"/\"键"
    inputBox.TextXAlignment = Enum.TextXAlignment.Left
    inputBox.BackgroundTransparency = 1
    inputBox.ClearTextOnFocus = false
    inputBox.Text = ""
    inputBox.TextSize = 8
    inputBox.Parent = inputContainer

    local corner4 = Instance.new("UICorner", inputBox)
    corner4.CornerRadius = UDim.new(0, 5)

    -- 创建发送按钮
    local sendButton = Instance.new("TextButton")
    sendButton.Name = "SendButton"
    sendButton.Size = UDim2.new(0.08, 0, 1, 0)
    sendButton.Position = UDim2.new(0.92, 0, 0, 0)
    sendButton.BackgroundTransparency = 1
    sendButton.TextColor3 = Color3.new(1, 1, 1)
    sendButton.Text = "▶"
    sendButton.TextSize = 12
    sendButton.Parent = inputContainer

    local corner5 = Instance.new("UICorner", sendButton)
    corner5.CornerRadius = UDim.new(0, 5)

    -- 发送消息的逻辑
    local function sendMessage()
        local message = inputBox.Text
        if message ~= "" then
            if repf then message = replaceText(message) end
            chatControl:chat(message)
            inputBox.Text = ""
        end
    end

    sendButton.MouseButton1Click:Connect(sendMessage)
    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            sendMessage()
        end
    end)

    local sidebarismin = false

    -- 创建侧边栏
    local sideBar = Instance.new("Frame")
    sideBar.Name = "SideBar"
    sideBar.Size = UDim2.new(0.15, 0, 1, 0)
    sideBar.Position = UDim2.new(1, 0, 0, 0)
    sideBar.BackgroundColor3 = Color3.new(0, 0, 0)
    sideBar.BackgroundTransparency = 0.5
    sideBar.Parent = chatFrame

    local corner6 = Instance.new("UICorner", sideBar)
    corner6.CornerRadius = UDim.new(0, 5)

    -- 创建侧边栏滚动区域
    local sideBarScroll = Instance.new("ScrollingFrame")
    sideBarScroll.Name = "SideBarScroll"
    sideBarScroll.Size = UDim2.new(1, 0, 1, -30)  -- 留出标题空间
    sideBarScroll.Position = UDim2.new(0, 0, 0, 30)
    sideBarScroll.BackgroundTransparency = 1
    sideBarScroll.ScrollBarThickness = 5
    sideBarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    sideBarScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sideBarScroll.Parent = sideBar

    local corner7 = Instance.new("UICorner", sideBarScroll)
    corner7.CornerRadius = UDim.new(0, 5)

    -- 创建侧边栏标题
    local sideBarTitle = Instance.new("TextButton")
    sideBarTitle.Name = "SideBarTitle"
    sideBarTitle.Size = UDim2.new(1, 0, 0, 30)
    sideBarTitle.Position = UDim2.new(0, 0, 0, 0)
    sideBarTitle.BackgroundTransparency = 1
    sideBarTitle.TextColor3 = Color3.new(1, 1, 1)
    sideBarTitle.Text = "功能栏▼"
    sideBarTitle.TextSize = 8
    sideBarTitle.TextXAlignment = Enum.TextXAlignment.Center
    sideBarTitle.Parent = sideBar

    local corner8 = Instance.new("UICorner", sideBarTitle)
    corner8.CornerRadius = UDim.new(0, 5)

    -- 创建按钮容器（现在放在滚动区域内）
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, 0, 0, 0)  -- 高度由内容决定
    buttonContainer.Position = UDim2.new(0, 0, 0, 0)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = sideBarScroll

    -- 创建按钮布局
    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.Padding = UDim.new(0, 5)
    buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    buttonLayout.Parent = buttonContainer

    -- 更新按钮容器大小
    buttonLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sideBarScroll.CanvasSize = UDim2.new(0, 0, 0, buttonLayout.AbsoluteContentSize.Y)
    end)

    -- 修改折叠功能
    sideBarTitle.MouseButton1Click:Connect(function()
        sidebarismin = not sidebarismin
        if sidebarismin then
            sideBarTitle.Text = "功能栏▲"
            sideBarScroll.Visible = false
            sideBar.Size = UDim2.new(0.15, 0, 0, 30)
        else
            sideBarTitle.Text = "功能栏▼"
            sideBarScroll.Visible = true
            sideBar.Size = UDim2.new(0.15, 0, 1, 0)
        end
    end)

    -- 添加按钮的函数（完整版）
    local buttonIndex = 0
    local function addButtonToSideBar(buttonName, onClick)
        buttonIndex = buttonIndex + 1

        local button = Instance.new("TextButton")
        button.Name = buttonName
        button.Size = UDim2.new(1, -10, 0, 25)  -- 宽度减去10像素边距，固定高度25像素
        button.Position = UDim2.new(0, 5, 0, 0)  -- 添加5像素左边距
        button.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
        button.TextColor3 = Color3.new(1, 1, 1)
        button.BackgroundTransparency = 0.5
        button.Text = buttonName
        button.TextSize = 8
        button.LayoutOrder = buttonIndex
        button.Parent = buttonContainer

        -- 添加圆角
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = button

        button.MouseButton1Click:Connect(function()
            onClick(button)
        end)

        return button
    end

    local function highlightButton(button)
        for _, child in ipairs(buttonContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
            end
        end
        button.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    end

    -- 添加按钮
    addButtonToSideBar(autotranslate and "自动(开)" or "自动(关)", function(button)
        autotranslate = not autotranslate
        button.Text = autotranslate and "自动(开)" or "自动(关)"
    end)

    addButtonToSideBar("复制日志", function()
        setclipboard(table.concat(chatlog, "\n"))
    end)

    addButtonToSideBar(repf and "反敏感词(开)" or "反敏感词(关)", function(button)
        repf = not repf
        if repf then replacefont = "全角字母" else replacefont = "default" end
        button.Text = repf and "反敏感词(开)" or "反敏感词(关)"
    end)

    addButtonToSideBar("原文", function(button)
        highlightButton(button)
        translateAPI = "Source"
    end)

    addButtonToSideBar("RB翻译", function(button)
        highlightButton(button)
        translateAPI = "Roblox"
    end)

    addButtonToSideBar("有道翻译", function(button)
        highlightButton(button)
        translateAPI = "YouDao"
    end)

    addButtonToSideBar("AI翻译", function(button)
        highlightButton(button)
        translateAPI = "AI"
    end)

    addButtonToSideBar("必应翻译", function(button)
        highlightButton(button)
        translateAPI = "Bing"
    end)

    addButtonToSideBar("搜狗翻译", function(button)
        highlightButton(button)
        translateAPI = "SoGou"
    end)

    addButtonToSideBar("QQ翻译", function(button)
        highlightButton(button)
        translateAPI = "QQ"
    end)
    local uninstallScript
    addButtonToSideBar("卸载", function()
        uninstallScript()
    end)

    -- 处理消息文本
    local function HandleText(Data)
        local sourcemsghand = Data.nickname .. ":"
        local msghand = setTextColor(sourcemsghand, 1, #sourcemsghand, getColorForText(Data.sender))
        local msgtail = Data.text
        local iscmd = Data.text:sub(1, 1) == "/" or Data.text:sub(1, 1) == ";"
        if not iscmd and autotranslate then
            msgtail = translateModuel:translateText(Data.text, translateAPI)
        end
        if player.name == Data.sender then
            msgtail = setTextColor(msgtail, 1, #msgtail, Color3.fromRGB(204, 255, 204))
        end
        return msghand .. " " .. msgtail
    end

    -- 获取当前日期时间
    local function getCurrentDateTime()
        return os.date("%Y-%m-%d %H:%M:%S")
    end

    -- 函数：根据玩家 ID 或玩家名生成私聊格式
    local function getPrivateMessageTag(playerIdentifier)
        -- 如果传入的是玩家 ID
        if type(playerIdentifier) == "number" then
            local player = Players:GetPlayerByUserId(playerIdentifier)
            if player then
                return "[@" .. player.Name .. "]: "
            else
                warn("未找到玩家 ID: " .. playerIdentifier)
                return nil
            end
        -- 如果传入的是玩家名
        elseif type(playerIdentifier) == "string" then
            local player = Players:FindFirstChild(playerIdentifier)
            if player then
                return "[@" .. player.Name .. "]: "
            else
                warn("未找到玩家名: " .. playerIdentifier)
                return nil
            end
        else
            warn("无效的玩家标识符类型")
            return nil
        end
    end

    -- 创建消息框
    local function createMessageBox(title, content)
        local screenGui2 = Instance.new("ScreenGui")
        screenGui2.Parent = game.CoreGui
        screenGui2.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui2.ResetOnSpawn = false
        screenGui2.Name = "MessageBoxGui"

        local background = Instance.new("Frame")
        background.Name = "Background"
        background.Size = UDim2.new(1, 0, 1, 0)
        background.Position = UDim2.new(0, 0, 0, 0)
        background.BackgroundColor3 = Color3.new(0, 0, 0)
        background.BackgroundTransparency = 0.5
        background.Parent = screenGui2

        local messageBox = Instance.new("Frame")
        messageBox.Name = "MessageBox"
        messageBox.Size = UDim2.new(0, 300, 0, 200)
        messageBox.Position = UDim2.new(0.5, -150, 0.5, -100)
        messageBox.AnchorPoint = Vector2.new(0.5, 0.5)
        messageBox.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
        messageBox.BackgroundTransparency = 0.2
        messageBox.BorderSizePixel = 0
        messageBox.Parent = screenGui2

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = messageBox

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Title"
        titleLabel.Size = UDim2.new(1, -20, 0, 30)
        titleLabel.Position = UDim2.new(0, 10, 0, 10)
        titleLabel.Text = title
        titleLabel.TextColor3 = Color3.new(1, 1, 1)
        titleLabel.TextSize = 18
        titleLabel.Font = Enum.Font.SourceSansBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.BackgroundTransparency = 1
        titleLabel.Parent = messageBox

        local contentLabel = Instance.new("TextLabel")
        contentLabel.Name = "Content"
        contentLabel.Size = UDim2.new(1, -20, 1, -100)
        contentLabel.Position = UDim2.new(0, 10, 0, 50)
        contentLabel.Text = content
        contentLabel.TextColor3 = Color3.new(1, 1, 1)
        contentLabel.TextSize = 14
        contentLabel.Font = Enum.Font.SourceSans
        contentLabel.TextWrapped = true
        contentLabel.TextXAlignment = Enum.TextXAlignment.Left
        contentLabel.TextYAlignment = Enum.TextYAlignment.Top
        contentLabel.BackgroundTransparency = 1
        contentLabel.Parent = messageBox

        local confirmButton = Instance.new("TextButton")
        confirmButton.Name = "ConfirmButton"
        confirmButton.Size = UDim2.new(0, 120, 0, 40)
        confirmButton.Position = UDim2.new(0.5, -130, 1, -50)
        confirmButton.Text = "确认"
        confirmButton.TextColor3 = Color3.new(1, 1, 1)
        confirmButton.TextSize = 14
        confirmButton.Font = Enum.Font.SourceSans
        confirmButton.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
        confirmButton.AutoButtonColor = true
        confirmButton.Parent = messageBox

        local confirmCorner = Instance.new("UICorner")
        confirmCorner.CornerRadius = UDim.new(0, 8)
        confirmCorner.Parent = confirmButton

        local cancelButton = Instance.new("TextButton")
        cancelButton.Name = "CancelButton"
        cancelButton.Size = UDim2.new(0, 120, 0, 40)
        cancelButton.Position = UDim2.new(0.5, 10, 1, -50)
        cancelButton.Text = "取消"
        cancelButton.TextColor3 = Color3.new(1, 1, 1)
        cancelButton.TextSize = 14
        cancelButton.Font = Enum.Font.SourceSans
        cancelButton.BackgroundColor3 = Color3.new(0.6, 0.2, 0.2)
        cancelButton.AutoButtonColor = true
        cancelButton.Parent = messageBox

        local cancelCorner = Instance.new("UICorner")
        cancelCorner.CornerRadius = UDim.new(0, 8)
        cancelCorner.Parent = cancelButton

        local messageBoxInstance = {
            ScreenGui = screenGui2,
            OnConfirm = function(callback)
                confirmButton.MouseButton1Click:Connect(callback)
            end,
            OnCancel = function(callback)
                cancelButton.MouseButton1Click:Connect(callback)
            end,
            Destroy = function()
                screenGui2:Destroy()
            end
        }

        return messageBoxInstance
    end

    -- 查找链接
    local function findLink(text)
        local pattern = "https?://[%w-_%.%?%.:/%+=&]+"
        local link = string.match(text, pattern)
        return link and { islink = true, link = link } or { islink = false, link = nil }
    end

    local maxbottom = 0
    local autoscroll = false

    rs = RunService.Heartbeat:Connect(function()
        if maxbottom <= scrollingFrame.CanvasPosition.Y then
            maxbottom = scrollingFrame.CanvasPosition.Y
            autoscroll = true
        elseif maxbottom > scrollingFrame.CanvasPosition.Y then
            autoscroll = false
        end
    end)

    -- 存储消息的表
    local messageTable = {}

    -- 创建搜索框容器
    local searchContainer = Instance.new("Frame")
    searchContainer.Name = "SearchContainer"
    searchContainer.Size = UDim2.new(0.4, 0, 0.1, 0)
    searchContainer.BackgroundColor3 = Color3.new(0, 0, 0)
    searchContainer.Position = UDim2.new(0.6, 0, -0.12, 0)
    searchContainer.BackgroundTransparency = 0.7
    searchContainer.Parent = chatFrame

    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 8)
    searchCorner.Parent = searchContainer

    -- 创建搜索框
    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(0.7, 0, 1, 0)
    searchBox.Position = UDim2.new(0.013, 0, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.TextColor3 = Color3.new(1, 1, 1)
    searchBox.PlaceholderText = "搜索昵称..."
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.Text = ""
    searchBox.TextSize = 8
    searchBox.Parent = searchContainer

    -- 创建搜索按钮
    local searchButton = Instance.new("TextButton")
    searchButton.Name = "SearchButton"
    searchButton.Size = UDim2.new(0.25, 0, 1, 0)
    searchButton.Position = UDim2.new(0.75, 0, 0, 0)
    searchButton.BackgroundColor3 = Color3.new(0, 0, 0)
    searchButton.BackgroundTransparency = 0.5
    searchButton.TextColor3 = Color3.new(1, 1, 1)
    searchButton.Text = "🔍"
    searchButton.TextSize = 8
    searchButton.Parent = searchContainer

    local searchButtonCorner = Instance.new("UICorner")
    searchButtonCorner.CornerRadius = UDim.new(0, 8)
    searchButtonCorner.Parent = searchButton

    -- 创建消息 UI
    local function createMessageUI(msgData)
        local findl = findLink(msgData.text)

        local messageContainer = Instance.new("Frame")
        messageContainer.Name = "MessageContainer"
        messageContainer.Size = UDim2.new(1, 0, 0, 20)
        messageContainer.BackgroundTransparency = 1
        messageContainer.AutomaticSize = Enum.AutomaticSize.Y
        messageContainer.Parent = scrollingFrame

        local imageLabel = Instance.new("ImageLabel")
        imageLabel.Name = "MessageImage"
        imageLabel.Size = UDim2.new(0, 20, 0, 20)
        imageLabel.Position = UDim2.new(0, 0, 0, 0)
        imageLabel.BackgroundTransparency = 1
        imageLabel.Image = msgData.head
        imageLabel.Parent = messageContainer

        local messageLabel = Instance.new("TextLabel")
        messageLabel.Name = "MessageLabel"
        messageLabel.Size = UDim2.new(findl.islink and 0.735 or 0.785, 0, 1, 0)
        messageLabel.Position = UDim2.new(0, 25, 0, 0)
        messageLabel.BackgroundTransparency = 1
        messageLabel.TextColor3 = Color3.new(1, 1, 1)
        messageLabel.Text = HandleText(msgData)
        messageLabel.TextXAlignment = Enum.TextXAlignment.Left
        messageLabel.TextSize = 12
        messageLabel.RichText = true
        messageLabel.TextWrapped = true
        messageLabel.AutomaticSize = Enum.AutomaticSize.Y
        messageLabel.Parent = messageContainer

        local privateMsgButton = Instance.new("TextButton")
        privateMsgButton.Name = "privateMsgButton"
        privateMsgButton.Size = messageLabel.Size
        privateMsgButton.Position = messageLabel.Position
        privateMsgButton.BackgroundTransparency = 1
        privateMsgButton.Text = ""
        privateMsgButton.Parent = messageContainer

        privateMsgButton.MouseButton1Click:Connect(function()
            inputBox.Text = getPrivateMessageTag(msgData.sender)
            inputBox:CaptureFocus()
        end)

        if findl.islink then
            local superlinkButton = Instance.new("TextButton")
            superlinkButton.Name = "超链接"
            superlinkButton.Size = UDim2.new(0.05, 0, 1, 0)
            superlinkButton.Position = UDim2.new(0.835, 0, 0, 0)
            superlinkButton.BackgroundColor3 = Color3.new(0, 0, 0)
            superlinkButton.BackgroundTransparency = 1
            superlinkButton.TextColor3 = Color3.new(1, 1, 1)
            superlinkButton.Text = "🔗"
            superlinkButton.TextSize = 8
            superlinkButton.Parent = messageContainer

            superlinkButton.MouseButton1Click:Connect(function()
                local messageBox = createMessageBox("这是一段链接，是否将其复制吗？", findl.link)

                messageBox.OnConfirm(function()
                    setclipboard(findl.link)
                    messageBox.Destroy()
                end)

                messageBox.OnCancel(function()
                    messageBox.Destroy()
                end)
            end)
        end

        local transleButton = Instance.new("TextButton")
        transleButton.Name = "翻译"
        transleButton.Size = UDim2.new(0.05, 0, 1, 0)
        transleButton.Position = UDim2.new(0.885, 0, 0, 0)
        transleButton.BackgroundColor3 = Color3.new(0, 0, 0)
        transleButton.BackgroundTransparency = 1
        transleButton.TextColor3 = Color3.new(1, 1, 1)
        transleButton.Text = "🌐"
        transleButton.TextSize = 8
        transleButton.Parent = messageContainer

        transleButton.MouseButton1Click:Connect(function()
            local linshiData = msgData
            linshiData.text = translateModuel:translateText(msgData.text, translateAPI)
            messageLabel.Text = HandleText(linshiData)
        end)

        local copyButton = Instance.new("TextButton")
        copyButton.Name = "复制"
        copyButton.Size = UDim2.new(0.05, 0, 1, 0)
        copyButton.Position = UDim2.new(0.935, 0, 0, 0)
        copyButton.BackgroundColor3 = Color3.new(0, 0, 0)
        copyButton.TextColor3 = Color3.new(1, 1, 1)
        copyButton.BackgroundTransparency = 1
        copyButton.Text = "📋"
        copyButton.TextSize = 8
        copyButton.Parent = messageContainer

        copyButton.MouseButton1Click:Connect(function()
            setclipboard(msgData.text)
        end)
    end

    -- 搜索功能
    local function searchMessages(keyword)
        for _, child in ipairs(scrollingFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end

        if keyword == "" then
            for _, msgData in ipairs(messageTable) do
                createMessageUI(msgData)
            end
            return
        end

        for _, msgData in ipairs(messageTable) do
            if string.find(msgData.nickname:lower(), keyword:lower()) then
                createMessageUI(msgData)
            end
        end
    end

    -- 绑定搜索按钮点击事件
    searchButton.MouseButton1Click:Connect(function()
        local keyword = searchBox.Text
        searchMessages(keyword)
        scrollingFrame.CanvasPosition = Vector2.new(0, 99999999)
        maxbottom = scrollingFrame.CanvasPosition.Y
        autoscroll = true
    end)

    -- 绑定搜索框回车事件
    searchBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local keyword = searchBox.Text
            searchMessages(keyword)
        end
    end)

    chatControl:MessageReceiver(function(msgData)
        table.insert(messageTable, msgData)
        table.insert(chatlog, "[" .. getCurrentDateTime() .. "] " .. msgData.nickname .. "(@" .. msgData.sender .. ") : " .. msgData.text)
        if searchBox.Text ~= "" and not string.find(msgData.nickname:lower(), searchBox.Text:lower()) then return end

        createMessageUI(msgData)

        if autoscroll then
            scrollingFrame.CanvasPosition = Vector2.new(0, 99999999)
            maxbottom = scrollingFrame.CanvasPosition.Y
        end
    end)

    -- 创建切换按钮
    local toggleBtn = TopbarLuau.new()
    toggleBtn:setImage("rbxassetid://120139782405970")
    toggleBtn:setToggle(true)
    toggleBtn:onToggle(function(enabled) chatFrame.Visible = enabled end)
    toggleBtn:setToggleState(true, false)

    -- 鼠标进入事件
    chatFrame.MouseEnter:Connect(function()
        lastMouseHoverTime = os.time()
    end)

    -- 鼠标离开事件
    chatFrame.MouseLeave:Connect(function()
        lastMouseHoverTime = os.time()
    end)

    -- 创建定时检查循环
    local hideCheckLoop
    hideCheckLoop = RunService.Heartbeat:Connect(function()
        local timeSinceLastHover = os.time() - lastMouseHoverTime
    
        if timeSinceLastHover >= hoverTimeout and not isHiding then
            isHiding = true
            chatFrame.BackgroundTransparency = 1
            searchContainer.Visible = false
            inputContainer.Visible = false
            sideBar.Visible = false
        elseif timeSinceLastHover < hoverTimeout and isHiding then
            isHiding = false
            chatFrame.BackgroundTransparency = 0.5
            searchContainer.Visible = true
            inputContainer.Visible = true
            sideBar.Visible = true
            -- 更高效的实现方式
            for _, messageContainer in ipairs(scrollingFrame:GetChildren()) do
                if messageContainer.Name == "MessageContainer" then
                    -- 使用FindFirstChildOfClass递归查找所有TextButton
                    local textButtons = messageContainer:GetDescendants()
                    for _, child in ipairs(textButtons) do
                        if child:IsA("TextButton") then
                            child.Visible = true
                        end
                    end
                end
            end
        end

        if isHiding then
            -- 更高效的实现方式
            for _, messageContainer in ipairs(scrollingFrame:GetChildren()) do
                if messageContainer.Name == "MessageContainer" then
                    -- 使用FindFirstChildOfClass递归查找所有TextButton
                    local textButtons = messageContainer:GetDescendants()
                    for _, child in ipairs(textButtons) do
                        if child:IsA("TextButton") then
                            child.Visible = false
                        end
                    end
                end
            end
        end
    end)

    local presstocrose = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Slash then
            chatFrame.Visible = true
            inputBox:CaptureFocus()
        end
    end)

    -- 卸载功能
    uninstallScript = function()
        cloneref(game:GetService("StarterGui")):SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
        if screenGui and screenGui.Parent then
            screenGui:Destroy()
        end

        if presstocrose then
            presstocrose:Disconnect()
        end
        if hideCheckLoop then
            hideCheckLoop:Disconnect()
        end
        if activeTween then
            activeTween:Cancel()
        end

        colorCache = {}
        chatlog = {}
        translateModuel = nil
        chatControl = nil

        TopbarLuau.clearAll()

        rs:Disconnect()
        script:Destroy()
    end
end

-- 初始化自定义聊天栏
createCustomChat()