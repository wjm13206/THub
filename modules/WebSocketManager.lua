-- WebSocketManager.lua
-- 用于 Potassium 注入器环境，WebSocket 全局可用

local WebSocketManager = {}
WebSocketManager.__index = WebSocketManager
local cloneref = cloneref or clonereference or function(obj) return obj end
local HttpService = cloneref(game:GetService("HttpService"))
local Players = cloneref(game:GetService("Players"))
local SERVER_URL = "wss://alphabetical-virtually-criterion-punk.trycloudflare.com"

function WebSocketManager.new()
    local self = setmetatable({}, WebSocketManager)
    self.userId = Players.LocalPlayer.UserId
    self.username = Players.LocalPlayer.DisplayName
    self.ws = nil
    self.isConnected = false
    self._connectThread = nil
    self._reconnectAttempts = 0
    self._maxReconnectAttempts = 5
    self._reconnectDelay = 3
    self._shouldReconnect = false

    self.OnMessageReceived = Instance.new("BindableEvent")
    self.OnSystemMessage = Instance.new("BindableEvent")
    self.OnUserListUpdate = Instance.new("BindableEvent")
    self.OnConnectionChanged = Instance.new("BindableEvent")
    self.OnUserOnline = Instance.new("BindableEvent")   -- 新增
    self.OnUserOffline = Instance.new("BindableEvent")  -- 新增

    return self
end

function WebSocketManager:Connect()
    -- 取消之前的重连
    self._shouldReconnect = false
    if self._connectThread then
        task.cancel(self._connectThread)
        self._connectThread = nil
    end

    if self.ws then
        pcall(function() self.ws:Close() end)
        self.ws = nil
    end

    -- ✅ 异步连接，不阻塞主线程
    self._shouldReconnect = true
    self._reconnectAttempts = 0
    self:_tryConnect()
end

function WebSocketManager:_tryConnect()
    if not self._shouldReconnect then return end
    if self._reconnectAttempts >= self._maxReconnectAttempts then
        warn("[WebSocketManager] 达到最大重连次数，停止重连")
        self.OnConnectionChanged:Fire(false)
        return
    end

    self._reconnectAttempts = self._reconnectAttempts + 1
    
    -- ✅ 使用 task.spawn 异步执行连接
    self._connectThread = task.spawn(function()
        local encodedUsername = HttpService:UrlEncode(self.username)
        local url = SERVER_URL .. "?userId=" .. tostring(self.userId) .. "&username=" .. encodedUsername

        print("[WebSocketManager] 正在连接 (尝试 " .. self._reconnectAttempts .. "/" .. self._maxReconnectAttempts .. ")")

        -- 连接（这里可能会阻塞，但在 task.spawn 中不影响主线程）
        local ws = WebSocket.connect(url)

        if not ws then
            warn("[WebSocketManager] 连接失败，返回 nil")
            if self._shouldReconnect then
                print("[WebSocketManager] " .. self._reconnectDelay .. "秒后重试...")
                task.wait(self._reconnectDelay)
                self:_tryConnect()
            end
            return
        end

        -- 连接成功
        self.ws = ws
        self._reconnectAttempts = 0
        print("[WebSocketManager] ✅ 对象创建成功，绑定事件")

        -- 绑定事件
        self:_bindEvents()

        self.isConnected = true
        self.OnConnectionChanged:Fire(true)
        print("[WebSocketManager] ✅ 连接完成")
    end)
end

function WebSocketManager:_bindEvents()
    if not self.ws then return end

    if self.ws.OnMessage then
        self.ws.OnMessage:Connect(function(message)
            -- ✅ 在任务调度器中处理消息，避免阻塞
            task.spawn(function()
                self:_handleMessage(message)
            end)
        end)
    end

    if self.ws.OnError then
        self.ws.OnError:Connect(function(err)
            warn("[WebSocketManager] 错误:", err)
        end)
    end
end

function WebSocketManager:SendChatMessage(content)
    if not self.ws or not self.isConnected then
        warn("[WebSocketManager] 未连接，无法发送")
        return
    end

    -- ✅ 异步发送，避免阻塞
    task.spawn(function()
        local msg = {
            type = "chat",
            content = tostring(content)
        }
        
        local jsonStr = HttpService:JSONEncode(msg)
        
        local ok, err = pcall(function()
            self.ws:Send(jsonStr)
        end)
        
        if not ok then
            warn("[WebSocketManager] 发送失败:", err)
        end
    end)
end

function WebSocketManager:Disconnect()
    self._shouldReconnect = false
    
    if self._connectThread then
        task.cancel(self._connectThread)
        self._connectThread = nil
    end

    if self.ws then
        pcall(function() self.ws:Close() end)
        self.ws = nil
    end
    
    self.isConnected = false
    self.OnConnectionChanged:Fire(false)
    print("[WebSocketManager] 已主动断开")
end

function WebSocketManager:SetMaxReconnectAttempts(n)
    self._maxReconnectAttempts = n or 5
end

function WebSocketManager:SetReconnectDelay(seconds)
    self._reconnectDelay = seconds or 3
end

function WebSocketManager:_handleMessage(data)
    local msg
    if type(data) == "string" then
        local ok, decoded = pcall(HttpService.JSONDecode, HttpService, data)
        if not ok then return end
        msg = decoded
    else
        msg = data
    end

    if not msg or type(msg) ~= "table" then return end

    if msg.type == "chat" then
        self.OnMessageReceived:Fire({
            userId = msg.userId,
            username = msg.username,
            content = msg.content,
            timestamp = msg.timestamp
        })
    elseif msg.type == "system" then
        self.OnSystemMessage:Fire(msg.content)
    elseif msg.type == "userList" then
        self.OnUserListUpdate:Fire(msg.users)
    elseif msg.type == "userOnline" then  -- ✅ 检测到别人上线
        self.OnUserOnline:Fire({
            userId = msg.userId,
            username = msg.username
        })
    elseif msg.type == "userOffline" then  -- ✅ 检测到别人下线
        self.OnUserOffline:Fire({
            userId = msg.userId,
            username = msg.username
        })
    end
end

return WebSocketManager