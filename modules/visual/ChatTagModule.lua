-- ChatTagModule - 聊天标签模块
-- 功能：为指定玩家添加自定义样式的聊天标签（纯本地，仅自己可见）

local cloneref = cloneref or clonereference or function(obj) return obj end
local TextChatService = cloneref(game:GetService("TextChatService"))
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))

local ChatTagModule = {}
ChatTagModule.__index = ChatTagModule

-- 内部存储
local activeTags = {}           -- [userId] = tagInstance
local isGlobalListenerActive = false
local rainbowConnections = {}   -- [userId] = connection

-- ========== 内部工具函数 ==========

-- 将 Color3 转换为十六进制
local function color3ToHex(color)
    return string.format("#%02X%02X%02X", 
        math.floor(color.R * 255), 
        math.floor(color.G * 255), 
        math.floor(color.B * 255)
    )
end

-- 生成彩虹色（基于时间偏移）
local function getRainbowColor(offset, speed)
    local hue = (os.clock() * speed + offset) % 1
    return Color3.fromHSV(hue, 1, 1)
end

-- 构建标签文本
local function buildTagText(config, rainbowColorHex)
    local parts = {}
    local tagContent = config.text or "[VIP]"
    
    -- 字体设置
    local fontTag = config.font and string.format(' font="%s"', config.font) or ""
    
    -- 颜色标签
    if config.rainbow and config.rainbow.enable then
        local colorHex = rainbowColorHex or "#FFFFFF"
        table.insert(parts, string.format('<font color="%s"%s>', colorHex, fontTag))
    elseif config.color then
        table.insert(parts, string.format('<font color="%s"%s>', config.color, fontTag))
    else
        table.insert(parts, string.format('<font%s>', fontTag))
    end
    
    -- 粗体
    if config.bold then
        table.insert(parts, "<b>")
    end
    
    -- 斜体
    if config.italic then
        table.insert(parts, "<i>")
    end
    
    -- 字号
    if config.size then
        table.insert(parts, string.format('<font size="%d">', config.size))
    end
    
    -- 描边
    if config.stroke and config.stroke.enable then
        local strokeColor = config.stroke.color or "#000000"
        local thickness = config.stroke.thickness or 1
        table.insert(parts, string.format('<stroke color="%s" thickness="%d">', strokeColor, thickness))
    end
    
    -- 实际文本
    table.insert(parts, tagContent)
    
    -- 闭合标签（倒序）
    if config.stroke and config.stroke.enable then
        table.insert(parts, "</stroke>")
    end
    
    if config.size then
        table.insert(parts, "</font>")
    end
    
    if config.italic then
        table.insert(parts, "</i>")
    end
    
    if config.bold then
        table.insert(parts, "</b>")
    end
    
    table.insert(parts, "</font>")
    table.insert(parts, " ")  -- 分隔空格
    
    return table.concat(parts)
end

-- 处理单条消息
local function processMessage(message, userId, config)
    local rainbowColorHex = nil
    
    -- 如果是彩虹模式，实时计算颜色
    if config.rainbow and config.rainbow.enable then
        local speed = config.rainbow.speed or 2
        local offset = config.rainbow.offset or 0
        local currentColor = getRainbowColor(offset, speed)
        rainbowColorHex = color3ToHex(currentColor)
    end
    
    return buildTagText(config, rainbowColorHex)
end

-- 全局消息处理器
local function onMessage(message)
    if not message.TextSource then return nil end
    
    local userId = message.TextSource.UserId
    local tagInstance = activeTags[userId]
    
    if tagInstance and tagInstance._enabled then
        local prefix = processMessage(message, userId, tagInstance._config)
        message.PrefixText = prefix .. (message.PrefixText or "")
    end
    
    return nil
end

-- ========== 标签实例类 ==========

function ChatTagModule.new(config)
    if type(config) ~= "table" then
        error("ChatTagModule.new() 必须传入一个配置表")
    end
    
    local player = config.player
    if not player then
        error("ChatTagModule.new() 必须提供 player 参数")
    end
    
    local userId = type(player) == "number" and player or player.UserId
    
    -- 默认配置
    local defaultConfig = {
        text = "[VIP]",
        color = "#FFD700",
        size = nil,
        bold = false,
        italic = false,
        font = nil,
        stroke = {
            enable = false,
            color = "#000000",
            thickness = 1
        },
        rainbow = {
            enable = false,
            speed = 2,
            offset = 0
        }
    }
    
    -- 合并配置
    local finalConfig = {}
    for k, v in pairs(defaultConfig) do
        if type(v) == "table" then
            finalConfig[k] = {}
            for sk, sv in pairs(v) do
                if config[k] and type(config[k]) == "table" then
                    finalConfig[k][sk] = config[k][sk] ~= nil and config[k][sk] or sv
                else
                    finalConfig[k][sk] = sv
                end
            end
        else
            finalConfig[k] = config[k] ~= nil and config[k] or v
        end
    end
    
    -- 处理简化的 rainbow 参数
    if type(finalConfig.rainbow) == "boolean" then
        finalConfig.rainbow = {
            enable = finalConfig.rainbow,
            speed = 2,
            offset = 0
        }
    end
    
    -- 处理简化的 stroke 参数
    if type(finalConfig.stroke) == "boolean" then
        finalConfig.stroke = {
            enable = finalConfig.stroke,
            color = "#000000",
            thickness = 1
        }
    end
    
    -- 创建标签实例
    local self = {
        _userId = userId,
        _config = finalConfig,
        _enabled = false
    }
    setmetatable(self, ChatTagModule)
    
    -- 存储到活跃列表
    activeTags[userId] = self
    
    -- 确保全局监听器已启动
    if not isGlobalListenerActive then
        TextChatService.OnIncomingMessage = onMessage
        isGlobalListenerActive = true
    end
    
    return self
end

-- 启用标签
function ChatTagModule:enable()
    self._enabled = true
    return self
end

-- 禁用标签
function ChatTagModule:disable()
    self._enabled = false
    return self
end

-- 更新配置
function ChatTagModule:update(newConfig)
    for k, v in pairs(newConfig) do
        if type(v) == "table" and type(self._config[k]) == "table" then
            for sk, sv in pairs(v) do
                self._config[k][sk] = sv
            end
        else
            self._config[k] = v
        end
    end
    return self
end

-- 获取当前配置
function ChatTagModule:getConfig()
    return self._config
end

-- 销毁此标签实例
function ChatTagModule:destroy()
    self:disable()
    activeTags[self._userId] = nil
end

-- ========== 模块级函数 ==========

-- 获取指定玩家的标签实例
function ChatTagModule.get(player)
    local userId = type(player) == "number" and player or player.UserId
    return activeTags[userId]
end

-- 移除指定玩家的标签
function ChatTagModule.remove(player)
    local userId = type(player) == "number" and player or player.UserId
    if activeTags[userId] then
        activeTags[userId]:destroy()
    end
end

-- 获取所有激活的标签
function ChatTagModule.getAll()
    local list = {}
    for _, tag in pairs(activeTags) do
        table.insert(list, tag)
    end
    return list
end

-- 卸载整个模块
function ChatTagModule.unload()
    for _, tag in pairs(activeTags) do
        tag:destroy()
    end
    
    if isGlobalListenerActive then
        TextChatService.OnIncomingMessage = nil
        isGlobalListenerActive = false
    end
    
    for _, conn in pairs(rainbowConnections) do
        conn:Disconnect()
    end
    rainbowConnections = {}
    activeTags = {}
end

return ChatTagModule