-- TranslationModule.lua
local cloneref = cloneref or clonereference or function(obj) return obj end
local HttpService = cloneref(game:GetService("HttpService"))
local RunService = cloneref(game:GetService("RunService"))

-- 加载异步请求模块
local AsyncFileFetcher = loadstring(game:HttpGet("https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/AsyncFileFetcher.lua"))()

local TranslationModule = {}

-- ==================== 内部状态变量 ====================
TranslationModule._enabled = false
TranslationModule._connection = nil
TranslationModule._taskQueue = {}
TranslationModule._originalTexts = {}
TranslationModule._lastTaskTime = 0
TranslationModule._scanCount = 0
TranslationModule._translatedCount = 0

local TEXT_PROPERTIES = {
    ["BillboardGui"] = "Text",
    ["GuiMain"] = "Text",
    ["ImageLabel"] = "ToolTip",
    ["ImageButton"] = "ToolTip",
    ["TextLabel"] = "Text",
    ["TextBox"] = "Text",
    ["TextButton"] = "Text",
    ["ViewportFrame"] = "Text",
}

-- ==================== 核心工具函数 ====================

-- 安全的UTF-8字符遍历，跳过无效字符
local function safeUtf8Codes(str)
    local function iterator(s, index)
        if index > #s then return nil end
        
        local b1 = string.byte(s, index)
        if not b1 then return nil end
        
        local bytes = 1
        if b1 >= 0xC0 and b1 <= 0xDF then
            bytes = 2
        elseif b1 >= 0xE0 and b1 <= 0xEF then
            bytes = 3
        elseif b1 >= 0xF0 and b1 <= 0xF7 then
            bytes = 4
        elseif b1 >= 0x80 and b1 <= 0xBF then
            -- 无效的续字节，跳过
            return index + 1, 0xFFFD
        end
        
        if index + bytes - 1 > #s then
            return index + 1, 0xFFFD
        end
        
        local codepoint = 0
        if bytes == 1 then
            codepoint = b1
        elseif bytes == 2 then
            local b2 = string.byte(s, index + 1)
            if b2 and b2 >= 0x80 and b2 <= 0xBF then
                codepoint = ((b1 - 0xC0) * 0x40) + (b2 - 0x80)
            else
                return index + 1, 0xFFFD
            end
        elseif bytes == 3 then
            local b2 = string.byte(s, index + 1)
            local b3 = string.byte(s, index + 2)
            if b2 and b2 >= 0x80 and b2 <= 0xBF and b3 and b3 >= 0x80 and b3 <= 0xBF then
                codepoint = ((b1 - 0xE0) * 0x1000) + ((b2 - 0x80) * 0x40) + (b3 - 0x80)
            else
                return index + 1, 0xFFFD
            end
        elseif bytes == 4 then
            local b2 = string.byte(s, index + 1)
            local b3 = string.byte(s, index + 2)
            local b4 = string.byte(s, index + 3)
            if b2 and b2 >= 0x80 and b2 <= 0xBF and b3 and b3 >= 0x80 and b3 <= 0xBF and b4 and b4 >= 0x80 and b4 <= 0xBF then
                codepoint = ((b1 - 0xF0) * 0x40000) + ((b2 - 0x80) * 0x1000) + ((b3 - 0x80) * 0x40) + (b4 - 0x80)
            else
                return index + 1, 0xFFFD
            end
        end
        
        return index + bytes, codepoint
    end
    
    return iterator, str, 1
end

-- 判断一个码点是否为中文字符（涵盖所有Unicode汉字区块）
local function isChineseChar(codepoint)
    return (codepoint >= 0x4E00 and codepoint <= 0x9FFF)   -- CJK统一汉字
        or (codepoint >= 0x3400 and codepoint <= 0x4DBF)   -- CJK扩展A
        or (codepoint >= 0xF900 and codepoint <= 0xFAFF)   -- CJK兼容汉字
        or (codepoint >= 0x20000 and codepoint <= 0x2A6DF) -- CJK扩展B
        or (codepoint >= 0x2A700 and codepoint <= 0x2B73F) -- CJK扩展C
        or (codepoint >= 0x2B740 and codepoint <= 0x2B81F) -- CJK扩展D
        or (codepoint >= 0x2B820 and codepoint <= 0x2CEAF) -- CJK扩展E
        or (codepoint >= 0x2CEB0 and codepoint <= 0x2EBEF) -- CJK扩展F
        or (codepoint >= 0x2F800 and codepoint <= 0x2FA1F) -- CJK兼容补充
end

-- 使用字节模式判断是否包含中文字符（UTF-8字节特征，覆盖所有区块）
local function containsChinese(text)
    local pattern3 = "[\226-\239][\128-\191][\128-\191]"
    local pattern4 = "[\240][\160-\191][\128-\191][\128-\191]"
    
    if string.find(text, pattern3) then
        return true
    end
    if string.find(text, pattern4) then
        return true
    end
    return false
end

-- 判断文本是否需要翻译（包含中文就不翻译）
local function shouldTranslate(text)
    if not text or type(text) ~= "string" or text == "" then
        return false
    end
    
    if containsChinese(text) then
        return false
    end
    
    local needsLang = false
    local success, _ = pcall(function()
        for codepoint in safeUtf8Codes(text) do
            if (codepoint >= 0x0020 and codepoint <= 0x007E) or
               (codepoint >= 0x0400 and codepoint <= 0x04FF) or
               (codepoint >= 0x3040 and codepoint <= 0x309F) or
               (codepoint >= 0x30A0 and codepoint <= 0x30FF) or
               (codepoint >= 0xAC00 and codepoint <= 0xD7AF) or
               (codepoint >= 0xFF00 and codepoint <= 0xFFEF) then
                needsLang = true
                break
            end
        end
    end)
    
    if not success then
        return false
    end
    
    return needsLang
end

-- 获取表的大小
local function getTableSize(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

local function scanInstances(parent, depth)
    depth = depth or 0
    if depth > 50 then
        return 
    end
    
    for _, child in ipairs(parent:GetChildren()) do
        local prop = TEXT_PROPERTIES[child.ClassName]
        
        if prop then
            local success, text = pcall(function()
                return child[prop]
            end)
            
            if success and type(text) == "string" and text ~= "" then
                if shouldTranslate(text) and not TranslationModule._originalTexts[child] then
                    TranslationModule._scanCount = TranslationModule._scanCount + 1
                    table.insert(TranslationModule._taskQueue, {
                        instance = child,
                        property = prop,
                        originalValue = text
                    })
                    TranslationModule._originalTexts[child] = text
                end
            end
        end
        scanInstances(child, depth + 1)
    end
end

-- ==================== 主循环与API调用 ====================

local function processTask(task)
    pcall(function()
        local url = "https://api.52vmy.cn/api/query/fanyi/youdao?msg=" .. HttpService:UrlEncode(task.originalValue)
        
        local jsonStr = AsyncFileFetcher.fetchSingle(url)
        
        if not jsonStr or jsonStr == "" then
            return
        end
        
        local res = HttpService:JSONDecode(jsonStr)
        
        if not res then
            return
        end
        
        if res and res.code == 200 and res.data and res.data.target then
            if task.instance and task.instance.Parent and task.instance[task.property] == task.originalValue then
                task.instance[task.property] = res.data.target
                TranslationModule._translatedCount = TranslationModule._translatedCount + 1
            end
        end
    end)
end

local function onHeartbeat()
    if not TranslationModule._enabled then return end
    if #TranslationModule._taskQueue == 0 then return end
    
    local now = tick()
    
    if (now - TranslationModule._lastTaskTime >= 0.6) then
        local task = table.remove(TranslationModule._taskQueue, 1)
        TranslationModule._lastTaskTime = now
        
        spawn(function()
            processTask(task)
        end)
    end
end

-- ==================== 对外暴露的接口 ====================

function TranslationModule.enable()
    if TranslationModule._enabled then 
        return 
    end
    
    TranslationModule._enabled = true
    TranslationModule._lastTaskTime = tick()
    TranslationModule._scanCount = 0
    TranslationModule._translatedCount = 0
    
    TranslationModule._connection = RunService.Heartbeat:Connect(onHeartbeat)
    
    pcall(function()
        scanInstances(game)
    end)
end

function TranslationModule.disable()
    if not TranslationModule._enabled then 
        return 
    end
    
    TranslationModule._enabled = false
    
    if TranslationModule._connection then
        TranslationModule._connection:Disconnect()
        TranslationModule._connection = nil
    end
    
    for inst, originalText in pairs(TranslationModule._originalTexts) do
        pcall(function()
            if inst and inst.Parent then
                local prop = TEXT_PROPERTIES[inst.ClassName]
                if prop then 
                    inst[prop] = originalText
                end
            end
        end)
    end
    
    TranslationModule._taskQueue = {}
    TranslationModule._originalTexts = {}
    TranslationModule._scanCount = 0
    TranslationModule._translatedCount = 0
end

function TranslationModule.unload()
    TranslationModule.disable()
    for k, _ in pairs(TranslationModule) do
        TranslationModule[k] = nil
    end
end

function TranslationModule.getStats()
    return {
        enabled = TranslationModule._enabled,
        queueSize = TranslationModule._enabled and #TranslationModule._taskQueue or 0,
        scannedTotal = TranslationModule._scanCount,
        translated = TranslationModule._translatedCount,
        trackedInstances = getTableSize(TranslationModule._originalTexts),
        lastTaskTime = TranslationModule._lastTaskTime,
        secondsSinceLastTask = TranslationModule._enabled and (tick() - TranslationModule._lastTaskTime) or 0
    }
end

function TranslationModule.printStats()
    local stats = TranslationModule.getStats()
end

return TranslationModule