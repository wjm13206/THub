--!native
--!optimize 2
-- ChatSpammer 自动喊话器模块
-- 定时向游戏聊天发送自定义消息

local ChatSpammer = {}

-- Services
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local TextChatService = cloneref(game:GetService("TextChatService"))
local LocalPlayer = Players.LocalPlayer

-- 内部状态
local isActive = false
local messages = {}
local interval = 5
local isRandom = false
local currentLoop = nil
local currentIndex = 1

-- 存储所有连接，用于unload
local connections = {}

-- 判断聊天系统版本
local isLegacyChat = TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService

-- 发送消息
local function sendMessage(msg)
    pcall(function()
        if isLegacyChat then
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(tostring(msg), "All")
        else
            TextChatService.TextChannels.RBXGeneral:SendAsync(tostring(msg))
        end
    end)
end

-- 主循环
local function startLoop()
    if currentLoop then
        currentLoop:Disconnect()
        currentLoop = nil
    end

    currentLoop = RunService.Heartbeat:Connect(function()
        if not isActive or #messages == 0 then
            return
        end

        local msg
        if isRandom then
            msg = messages[math.random(1, #messages)]
        else
            msg = messages[currentIndex]
            currentIndex = currentIndex % #messages + 1
        end
        sendMessage(msg)

        currentLoop:Disconnect()
        currentLoop = nil
        task.wait(interval)
        if isActive then
            startLoop()
        end
    end)
    table.insert(connections, currentLoop)
end

-- 停止循环
local function stopLoop()
    isActive = false
    if currentLoop then
        currentLoop:Disconnect()
        currentLoop = nil
    end
end

-- 清理所有连接
local function cleanupAll()
    stopLoop()

    for _, conn in ipairs(connections) do
        if conn and conn.Disconnect then
            pcall(function() conn:Disconnect() end)
        end
    end
    connections = {}
end

-- 更新消息列表
function ChatSpammer.setMessages(msgList)
    if type(msgList) ~= "table" then return false end
    messages = msgList
    return true
end

-- 从多行文本更新消息列表
function ChatSpammer.setMessagesFromText(text)
    local lines = {}
    for line in tostring(text):gmatch("[^\r\n]+") do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed and trimmed ~= "" then
            table.insert(lines, trimmed)
        end
    end
    messages = lines
    return true
end

-- 获取当前消息列表（拼接为多行文本）
function ChatSpammer.getMessagesAsText()
    return table.concat(messages, "\n")
end

-- 设置间隔
function ChatSpammer.setInterval(sec)
    if type(sec) ~= "number" or sec < 0.5 then return false end
    interval = sec
    return true
end

-- 获取当前间隔
function ChatSpammer.getInterval()
    return interval
end

-- 设置模式
function ChatSpammer.setRandom(mode)
    isRandom = mode or false
end

-- 获取当前模式
function ChatSpammer.isRandomMode()
    return isRandom
end

-- 启用
function ChatSpammer.enable()
    if isActive then return false end
    if #messages == 0 then return false end
    isActive = true
    currentIndex = 1
    startLoop()
    return true
end

-- 禁用
function ChatSpammer.disable()
    if not isActive then return false end
    stopLoop()
    return true
end

-- 检查是否启用
function ChatSpammer.isEnabled()
    return isActive
end

-- 卸载整个模块
function ChatSpammer.unload()
    cleanupAll()

    ChatSpammer.enable = nil
    ChatSpammer.disable = nil
    ChatSpammer.isEnabled = nil
    ChatSpammer.setMessages = nil
    ChatSpammer.setMessagesFromText = nil
    ChatSpammer.getMessagesAsText = nil
    ChatSpammer.setInterval = nil
    ChatSpammer.getInterval = nil
    ChatSpammer.setRandom = nil
    ChatSpammer.isRandomMode = nil
    ChatSpammer.unload = nil

    isActive = false
    messages = {}
    interval = 5
    isRandom = false
    currentLoop = nil
    currentIndex = 1
    connections = {}
end

return ChatSpammer
