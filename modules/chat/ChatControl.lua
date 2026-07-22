local cloneref = cloneref or clonereference or function(obj) return obj end
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local TextChatService = cloneref(game:GetService("TextChatService"))
local Players = cloneref(game:GetService("Players"))

-- 判断是否为旧聊天系统
local isLegacyChat = TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService

local chatControl = {}

-- 保存连接
local connections = {}

-- 发送消息的函数
function chatControl:chat(str)
    str = tostring(str)
    local ok, err = pcall(function()
        if not isLegacyChat then
            TextChatService.TextChannels.RBXGeneral:SendAsync(str)
        else
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(str, "All")
        end
    end)
    return ok, err
end

-- 获取玩家头像
local thumbnailType = Enum.ThumbnailType.HeadShot
local thumbnailSize = Enum.ThumbnailSize.Size100x100

-- 接收消息的函数
function chatControl:MessageReceiver(callback)
    local conn = TextChatService.MessageReceived:Connect(function(message)
        -- 防止 TextSource 为 nil
        if not message.TextSource then
            return
        end
        
        local player = Players:GetPlayerByUserId(message.TextSource.UserId)
        if not player then return end
        
        local success, thumbnailUrl = pcall(function()
            return Players:GetUserThumbnailAsync(message.TextSource.UserId, thumbnailType, thumbnailSize)
        end)
        
        local msgData = {}
        msgData["sender"] = player.Name
        msgData["nickname"] = player.DisplayName
        msgData["head"] = thumbnailUrl
        msgData["text"] = message.Text
        callback(msgData)
    end)
    
    -- 保存连接以便后续断开
    table.insert(connections, conn)
end

-- 卸载函数
function chatControl:unload()
    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
    connections = {}
end

return chatControl