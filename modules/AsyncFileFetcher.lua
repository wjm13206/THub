-- AsyncFileFetcher 模块 (Pure ASCII Console Version with Throttle)
local AsyncFileFetcher = {}

-- Configuration
local CONFIG = {
    TIMEOUT = 20,
    POLL_INTERVAL = 0.01,
    MAX_RETRIES = 3,
    PROGRESS_BAR_WIDTH = 40,
    POTASSIUM_HOLD_SECONDS = 3,
    REDRAW_INTERVAL = 0.1,           -- 最小重绘间隔（秒）
}

-- Check if Potassium console is available
local function hasPotassiumConsole()
    return type(rconsolecreate) == "function" 
        and type(rconsoleprint) == "function" 
        and type(rconsoledestroy) == "function"
        and type(rconsoleclear) == "function"
end

-- HTTP request (unchanged)
local function performRequest(url)
    if syn and syn.request then
        local response = syn.request({
            Url = url,
            Method = "GET",
            Headers = { ["User-Agent"] = "Roblox" }
        })
        if response.Success then
            return response.Body
        else
            error("HTTP Error: " .. tostring(response.StatusCode))
        end
    elseif game and game.HttpGet then
        return game:HttpGet(url)
    else
        error("No HTTP request method available")
    end
end

local function requestWithRetry(url, retries)
    retries = retries or CONFIG.MAX_RETRIES
    for i = 1, retries do
        local success, result = pcall(performRequest, url)
        if success then
            return result
        elseif i == retries then
            error(result)
        else
            task.wait(1)
        end
    end
end

-- Original progress bar (with Unicode block characters for Roblox output)
local function getProgressBar(current, total, width)
    width = width or 20
    local ratio = current / total
    local filled = math.floor(ratio * width)
    local empty = width - filled
    local bar = "[" .. string.rep("█", filled) .. string.rep("░", empty) .. "]"
    return string.format("%s %d/%d", bar, current, total)
end

-- ==================== Potassium Fancy UI (Pure ASCII) ====================
local potassium = {
    enabled = false,
    total = 0,
    loaded = 0,
    failed = {},
    failedCount = 0,
    currentFileName = "Starting...",
    isComplete = false,
    lastRedrawTime = 0,              -- 上次重绘时间戳
}

-- Pure ASCII title
local function getBigTitle()
    return [[
    +-----------------------------------------------------------------------+
    |                                                                       |
    |                         AsyncFileFetcher v1.0                         |
    |                       Parallel Download Manager                       |
    |                                                                       |
    +-----------------------------------------------------------------------+
    ]]
end

-- Long progress bar (pure ASCII)
local function getLongProgressBar(current, total, width)
    local ratio = current / total
    local filled = math.floor(ratio * width)
    local empty = width - filled
    return "[" .. string.rep("#", filled) .. string.rep("-", empty) .. "]"
end

-- Draw the entire Potassium UI (with throttle)
local function drawPotassiumUI(force)
    if not potassium.enabled then return end
    
    local now = os.clock()
    if not force and (now - potassium.lastRedrawTime) < CONFIG.REDRAW_INTERVAL then
        return  -- 未达到重绘间隔，跳过
    end
    potassium.lastRedrawTime = now
    
    local total = potassium.total
    local loaded = potassium.loaded
    local failedList = potassium.failedList or {}
    local failedCount = #failedList
    local fileName = potassium.currentFileName
    local isComplete = potassium.isComplete
    
    rconsoleclear()
    rconsoleprint("\n" .. getBigTitle() .. "\n\n")
    
    -- Status header
    if isComplete then
        rconsoleprint("    +-----------------------------------------------------------------------+\n")
        rconsoleprint("    |                                                                       |\n")
        rconsoleprint("    |                             S U C C E S S                             |\n")
        rconsoleprint("    |                                                                       |\n")
        rconsoleprint("    +-----------------------------------------------------------------------+\n\n")
    else
        rconsoleprint("    +-----------------------------------------------------------------------+\n")
        rconsoleprint("    |                                                                       |\n")
        rconsoleprint("    |                        L O A D I N G   F I L E S                      |\n")
        rconsoleprint("    |                                                                       |\n")
        rconsoleprint("    +-----------------------------------------------------------------------+\n\n")
    end
    
    -- Current file
    rconsoleprint("    >> File: " .. fileName .. "\n")
    rconsoleprint("    >> Progress: " .. loaded .. " / " .. total .. " files loaded")
    if failedCount > 0 then
        rconsoleprint("   (Failed: " .. table.concat(failedList, ", ") .. ")")
    end
    rconsoleprint("\n\n")
    
    -- Progress bar
    local barWidth = CONFIG.PROGRESS_BAR_WIDTH
    local bar = getLongProgressBar(loaded, total, barWidth)
    local percent = (loaded / total) * 100
    rconsoleprint("    " .. bar .. "  " .. string.format("%.1f", percent) .. "%\n\n")
    
    -- Footer
    if isComplete then
        rconsoleprint("    =========================================================================\n")
        rconsoleprint("    [OK] All files loaded successfully! Window will close in " .. CONFIG.POTASSIUM_HOLD_SECONDS .. " seconds.\n")
    else
        rconsoleprint("    -------------------------------------------------------------------------\n")
        rconsoleprint("     AsyncFileFetcher | Parallel downloading | Please wait...\n")
    end
end

-- Update potassium data and redraw (throttled)
local function updatePotassium(loaded, total, fileName, failedList)
    if not potassium.enabled then return end
    potassium.loaded = loaded
    potassium.total = total
    potassium.failedList = failedList or {}  -- 保存失败列表
    potassium.failedCount = #failedList      -- 单独保存数量
    if fileName then
        local shortName = fileName:match("([^/]+)$") or fileName
        if #shortName > 60 then shortName = shortName:sub(1,57).."..." end
        potassium.currentFileName = shortName
    end
    drawPotassiumUI(false)
end

-- Finish and close
local function finishPotassium(successCount, failedList)
    if not potassium.enabled then return end
    potassium.isComplete = true
    potassium.loaded = successCount + #failedList
    potassium.failedList = failedList
    potassium.failedCount = #failedList
    drawPotassiumUI(true)
    
    task.spawn(function()
        task.wait(CONFIG.POTASSIUM_HOLD_SECONDS)
        if rconsoledestroy then
            rconsoledestroy()
        end
        potassium.enabled = false
    end)
end

local function initPotassium(totalFiles)
    if not hasPotassiumConsole() then
        return false
    end
    rconsolecreate()
    if rconsolesettitle then
        rconsolesettitle("AsyncFileFetcher - Fancy Downloader")
    end
    potassium.enabled = true
    potassium.total = totalFiles
    potassium.loaded = 0
    potassium.failedList = {}  -- 改为空表
    potassium.failedCount = 0
    potassium.isComplete = false
    potassium.currentFileName = "Initializing..."
    potassium.lastRedrawTime = os.clock()
    drawPotassiumUI(true)
    return true
end

-- ==================== Original Functions ====================
function AsyncFileFetcher.fetchMultiple(fileTable)
    local loadedFiles = {}
    local totalFiles = 0
    local loadedCount = 0
    local failedCount = 0
    local allLoaded = false
    local failedList = {}
    
    for _ in pairs(fileTable) do totalFiles = totalFiles + 1 end
    if totalFiles == 0 then return loadedFiles end
    
    local potassiumEnabled = initPotassium(totalFiles)
    
    local startTime = os.clock()
    print("[AsyncFileFetcher] Starting to load " .. totalFiles .. " files...")
    
    local lastCompletedKey = nil
    local function updateLastCompleted(key)
        lastCompletedKey = key
        if potassiumEnabled then
            updatePotassium(loadedCount, totalFiles, key, failedList)
        end
    end
    
    for key, url in pairs(fileTable) do
        task.spawn(function()
            local success, result = pcall(requestWithRetry, url)
            if success then
                loadedFiles[key] = result
            else
                failedCount = failedCount + 1
                table.insert(failedList, tostring(key))
            end
            loadedCount = loadedCount + 1
            updateLastCompleted(key)
            if loadedCount >= totalFiles then
                allLoaded = true
            end
        end)
    end
    
    local lastProgress = ""
    while not allLoaded do
        if os.clock() - startTime > CONFIG.TIMEOUT then
            print("[AsyncFileFetcher] ⚠ Timeout! Loaded: " .. loadedCount .. "/" .. totalFiles)
            break
        end
        local currentProgress = getProgressBar(loadedCount, totalFiles)
        if currentProgress ~= lastProgress then
            lastProgress = currentProgress
        end
        task.wait(CONFIG.POLL_INTERVAL)
    end
    
    local elapsed = string.format("%.2f", os.clock() - startTime)
    local successCount = loadedCount - #failedList
    local summary = getProgressBar(loadedCount, totalFiles) .. " | Success: " .. successCount .. " | Failed: " .. #failedList
    print("[AsyncFileFetcher] ✓ Completed in " .. elapsed .. "s")
    print(summary)
    if not allLoaded then
        warn("⚠ Failed files: " .. table.concat(failedList, ", "))
    end
    
    if potassiumEnabled then
        finishPotassium(successCount, failedList)
    end
    
    return loadedFiles
end

function AsyncFileFetcher.fetchSingle(url)
    local success, result = pcall(requestWithRetry, url)
    if success then
        return result, true
    else
        return nil, false, result
    end
end

return AsyncFileFetcher