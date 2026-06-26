local ConfigModule = {}
local cloneref = cloneref or clonereference or function(obj) return obj end
ConfigModule.mainFolderName = nil
ConfigModule.config = {}

-- 字符串分割辅助函数
local function stringSplit(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from, true)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from, true)
    end
    table.insert(result, string.sub(str, from))
    return result
end

-- 检查文件扩展名是否为音频文件
local function isAudioFile(filename)
    local audioExtensions = {
        [".mp3"] = true,
        [".wav"] = true,
        [".ogg"] = true,
        [".flac"] = true,
        [".m4a"] = true,
        [".wma"] = true,
        [".aac"] = true
    }
    
    local lowerFilename = string.lower(filename)
    for ext, _ in pairs(audioExtensions) do
        if string.sub(lowerFilename, -string.len(ext)) == ext then
            return true
        end
    end
    return false
end

-- 递归创建目录
local function createDirectory(path)
    local parts = stringSplit(path, "/")
    local currentPath = ""
    for _, part in ipairs(parts) do
        if part ~= "" then  -- 跳过空部分
            if currentPath == "" then
                currentPath = part
            else
                currentPath = currentPath .. "/" .. part
            end
            
            local success = pcall(function()
                readfile(currentPath .. "/.keep")
            end)
            
            if not success then
                local writeSuccess, writeErr = pcall(function()
                    writefile(currentPath .. "/.keep", "")
                end)
                if not writeSuccess then
                    warn("无法创建目录: " .. currentPath .. " - " .. tostring(writeErr))
                end
            end
        end
    end
end

local function isSupportedPath(str)
    -- 检查是否包含非 ASCII 字符（中文、日文、特殊 Unicode 等）
    for _, char in utf8.codes(str) do
        if char > 127 then
            -- 非 ASCII 字符
            return false
        end
    end
    
    -- 可选：进一步检查是否包含某些特殊符号
    -- Potassium 通常不支持这些字符
    local unsafeChars = {
        ["\\"] = true,  -- 反斜杠
        [":"] = true,   -- 冒号
        ["*"] = true,   -- 星号
        ["?"] = true,   -- 问号
        ['"'] = true,   -- 双引号
        ["<"] = true,   -- 小于号
        [">"] = true,   -- 大于号
        ["|"] = true,   -- 竖线
        ["%%"] = true,  -- 百分号（在某些系统中有特殊含义）
    }
    
    for char in string.gmatch(str, ".") do
        if unsafeChars[char] then
            return false
        end
    end
    
    return true
end

-- 设置主配置文件夹
function ConfigModule.setmain(folderName)
    if not folderName or folderName == "" then
        error("必须提供有效的主配置文件夹名称")
    end
    
    ConfigModule.mainFolderName = folderName
    createDirectory(folderName)
end

-- 创建配置
function ConfigModule.createconfig(path)
    if not ConfigModule.mainFolderName then
        error("请先使用 setmain() 设置主配置文件夹")
    end
    
    if not path or path == "" then
        error("必须提供有效的配置文件路径")
    end
    
    local pathParts = stringSplit(path, "/")
    local fileName = pathParts[#pathParts]
    table.remove(pathParts, #pathParts)
    
    local fullPath = ConfigModule.mainFolderName
    for _, part in ipairs(pathParts) do
        fullPath = fullPath .. "/" .. part
    end
    
    -- 创建目录结构
    createDirectory(fullPath)
    
    local configFilePath = fullPath .. "/" .. fileName .. ".json"
    
    -- 加载或创建配置
    local configData = {}
    local success, content = pcall(function()
        return readfile(configFilePath)
    end)
    
    if success and content and content ~= "" then
        local decodeSuccess, decodedData = pcall(function()
            return cloneref(game:GetService("HttpService")):JSONDecode(content)
        end)
        if decodeSuccess then
            configData = decodedData
        end
    end
    
    local configObject = {}
    
    -- 使用闭包存储数据
    local data = configData
    local filePath = configFilePath
    
    local mt = {
        __index = function(_, key)
            return data[key]
        end,
        __newindex = function(_, key, value)
            data[key] = value
            local encodedData = cloneref(game:GetService("HttpService")):JSONEncode(data)
            writefile(filePath, encodedData)
        end
    }
    
    setmetatable(configObject, mt)
    ConfigModule.config[path] = configObject
    
    return configObject
end

-- 创建音乐配置（扫描音乐文件夹并返回音乐表）
function ConfigModule.createmusicconfig(path)
    if not ConfigModule.mainFolderName then
        error("请先使用 setmain() 设置主配置文件夹")
    end
    
    if not path or path == "" then
        error("必须提供有效的音乐配置路径")
    end
    
    -- 构建音乐文件夹路径
    local musicFolderPath = ConfigModule.mainFolderName .. "/" .. path
    
    -- 确保目录存在
    if not isfolder(musicFolderPath) then
        makefolder(musicFolderPath)
        return { ["无"] = "" }
    end
    
    -- 使用Potassium的listfiles API获取文件列表
    local musicTable = {}
    local success, files = pcall(function()
        return listfiles(musicFolderPath)
    end)
    
    if success and files then
        for _, filepath in ipairs(files) do
            -- 提取文件名部分
            local parts = stringSplit(filepath, "\\")
            local filename = parts[#parts]

            if not isSupportedPath(filename) then
                warn("不支持的文件名: " .. filename)
                -- 跳转到下一个文件
            elseif isAudioFile(filename) then
                -- 获取不带扩展名的文件名作为键
                local nameWithoutExt = string.gsub(filename, "%.[^.]*$", "")
                
                -- 获取资产ID
                local assetId = getcustomasset(filepath)
                
                if assetId and assetId ~= "" then
                    musicTable[nameWithoutExt] = assetId
                end
            end
        end
    else
        warn("无法读取音乐文件夹: " .. musicFolderPath)
    end
    
    return musicTable
end

return ConfigModule