-- ChatSpy 模块 (适配新版 TextChatService)
local ChatSpy = {}

-- 私有状态
local enabled = false
local connections = {}      -- 存储所有事件连接
local spyOnSelf = false     -- 是否偷听自己的消息
local publicMode = false    -- 是否公开广播（转发到全局聊天）
local ignoreList = {        -- 忽略列表（保持不变）
    {Message = ":part/1/1/1", ExactMatch = true},
    {Message = ":part/10/10/10", ExactMatch = true},
    {Message = "A?????????", ExactMatch = false},
    {Message = ":colorshifttop 10000 0 0", ExactMatch = true},
    {Message = ":colorshiftbottom 10000 0 0", ExactMatch = true},
    {Message = ":colorshifttop 0 10000 0", ExactMatch = true},
    {Message = ":colorshiftbottom 0 10000 0", ExactMatch = true},
    {Message = ":colorshifttop 0 0 10000", ExactMatch = true},
    {Message = ":colorshiftbottom 0 0 10000", ExactMatch = true},
}

-- Services
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local TextChatService = cloneref(game:GetService("TextChatService"))
local LocalPlayer = Players.LocalPlayer

-- 判断是否为旧版聊天系统，用于兼容
local isLegacyChat = TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService

-- 加载系统通知模块（路径保持不变）
local SystemNotification = _G.SystemNotification or loadstring(game:HttpGet("https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/SystemNotification.lua"))()

-- 新版聊天系统的核心频道
local generalChannel = nil
local function getGeneralChannel()
    if not generalChannel then
        generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
    end
    return generalChannel
end

-- 辅助函数：检查消息是否应被忽略
local function isIgnored(message)
    for _, v in ipairs(ignoreList) do
        if v.ExactMatch and message == v.Message then
            return true
        elseif not v.ExactMatch and message:find(v.Message) then
            return true
        end
    end
    return false
end

-- 辅助函数：发送偷听消息到聊天框
local function sendSpyMessage(text)
    local messageText = "[SPY] - " .. text
    if publicMode then
        -- 公开模式：尝试通过新版API广播到全局聊天
        local channel = getGeneralChannel()
        if channel then
            -- 使用新版API发送消息
            channel:SendAsync(messageText)
        elseif isLegacyChat then
            -- 旧版兼容：通过远程事件发送
            local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
            local DefaultChatSystemChatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if DefaultChatSystemChatEvents then
                local SayMessageRequest = DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
                if SayMessageRequest then
                    SayMessageRequest:FireServer(messageText, "All")
                end
            end
        end
    else
        -- 私有模式：仅自己可见的系统消息
        if isLegacyChat then
            local StarterGui = cloneref(game:GetService("StarterGui"))
            StarterGui:SetCore("ChatMakeSystemMessage", {
                Text = messageText,
                Color = Color3.fromRGB(255, 0, 0)
            })
        else
            -- 新版聊天系统：使用自定义方法发送红色消息
            SystemNotification.Custom(messageText, Color3.fromRGB(255, 0, 0), "SourceSans", 14)
        end
    end
end

-- 辅助函数：发送状态消息
local function sendStatusMessage(text, isError)
    local color = isError and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
    if isLegacyChat then
        local StarterGui = cloneref(game:GetService("StarterGui"))
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "[SPY] - " .. text,
            Color = color
        })
    else
        if isError then
            SystemNotification.Error("[SPY] - " .. text)
        else
            SystemNotification.Success("[SPY] - " .. text)
        end
    end
end

-- 处理单条聊天消息 (新版核心逻辑)
local function onMessageReceived(message, channel)
    -- 检查模块是否开启
    if not enabled then return end

    -- 获取发送者玩家对象
    local sender = message.TextSource
    local player = sender and Players:GetPlayerByUserId(sender.UserId)
    if not player then return end

    -- 检查是否应该偷听自己
    if not spyOnSelf and player == LocalPlayer then return end

    -- 获取消息文本
    local cleanedMessage = message.Text:gsub("[\n\r]", ""):gsub("\t", " "):gsub("[ ]+", " ")
    if #cleanedMessage == 0 or isIgnored(cleanedMessage) then return end

    -- 检查频道类型 (用于队伍聊天判断)
    local isTeamChat = (channel.Name == "RBXTeam")
    
    -- 新版系统下，我们默认所有能捕获到的消息都是“可见”的。
    -- 隐藏消息判断 (基于旧版逻辑) 已移除，因为在新版中没有可靠的方法。
    -- 如果需要，可以在这里添加基于频道或消息特性的过滤。

    -- 输出偷听的消息
    if #cleanedMessage > 1200 then
        cleanedMessage = cleanedMessage:sub(1, 1200) .. "..."
    end
    
    local channelPrefix = isTeamChat and "[Team] " or ""
    local outputText = channelPrefix .. player.Name .. ": " .. cleanedMessage
    sendSpyMessage(outputText)
end

-- 设置新版聊天系统的监听
local function setupNewChatListener()
    local channel = getGeneralChannel()
    if not channel then
        -- 如果找不到通用频道，延迟重试或报错
        task.wait(1)
        return setupNewChatListener()
    end
    
    -- 监听通用频道 (RBXGeneral)
    local generalConn = channel.MessageReceived:Connect(function(msg)
        onMessageReceived(msg, channel)
    end)
    table.insert(connections, generalConn)
    
    -- 尝试监听队伍频道 (RBXTeam)，如果存在的话
    local teamChannel = TextChatService.TextChannels:FindFirstChild("RBXTeam")
    if teamChannel then
        local teamConn = teamChannel.MessageReceived:Connect(function(msg)
            onMessageReceived(msg, teamChannel)
        end)
        table.insert(connections, teamConn)
    end
end

-- 清理所有连接
local function clearAllConnections()
    for _, conn in ipairs(connections) do
        if conn then
            conn:Disconnect()
        end
    end
    connections = {}
end

-- 公开函数：开启 ChatSpy
function ChatSpy.enable()
    if enabled then return end
    enabled = true
    clearAllConnections() -- 确保开启时没有残留连接
    
    if isLegacyChat then
        -- 旧版系统逻辑 (保持原样或调用原函数，此处略作示意)
        sendStatusMessage("Legacy mode is not fully supported in this version.", true)
        return
    else
        -- 新版系统逻辑
        setupNewChatListener()
    end

    sendStatusMessage("Enabled", false)
end

-- 公开函数：关闭 ChatSpy
function ChatSpy.disable()
    if not enabled then return end
    enabled = false
    clearAllConnections()
    sendStatusMessage("Disabled", true)
end

-- 公开函数：完全卸载
function ChatSpy.unload()
    ChatSpy.disable()
    
    -- 清空模块方法
    ChatSpy.enable = nil
    ChatSpy.disable = nil
    ChatSpy.unload = nil
    ChatSpy.setSpyOnSelf = nil
    ChatSpy.setPublicMode = nil
end

-- 可选：配置方法
function ChatSpy.setSpyOnSelf(value)
    spyOnSelf = value
end

function ChatSpy.setPublicMode(value)
    publicMode = value
end

return ChatSpy