-- highlight_module_optimized.lua
-- 高性能高亮模块（异步分帧，防止重复，可调批大小）
-- 支持匹配模式: "only", "fuzzy", "path", "pathFuzzy"

local highlighter = {}
local cloneref = cloneref or clonereference or function(obj) return obj end
local RunService = cloneref(game:GetService("RunService"))
local Workspace = cloneref(game:GetService("Workspace"))

-- 预定义颜色方案
local colorPresets = {
    item = {
        outlineColor = Color3.fromRGB(0, 170, 255),
        fillColor = Color3.fromRGB(0, 170, 255)
    },
    npc = {
        outlineColor = Color3.fromRGB(255, 215, 0),
        fillColor = Color3.fromRGB(255, 215, 0)
    },
    hostileNpc = {
        outlineColor = Color3.fromRGB(255, 30, 30),
        fillColor = Color3.fromRGB(255, 30, 30)
    },
    neutralNpc = {
        outlineColor = Color3.fromRGB(255, 200, 0),
        fillColor = Color3.fromRGB(255, 200, 0)
    },
    normal =  {
        outlineColor = Color3.fromRGB(255, 255, 255),
        fillColor = Color3.fromRGB(255, 255, 255)
    },
}

-- 存储所有活动的高亮器实例（用于全局卸载）
local activeHighlighters = {}

-- 任务ID生成器
local taskCounter = 0
local function getNewTaskId()
    taskCounter = taskCounter + 1
    return taskCounter
end

-- 内部：构建对象的完整路径
-- @param obj 目标对象
-- @return 完整路径字符串，如 "Workspace.bugbo.Build.Rocks.Rock"
local function getFullPath(obj)
    local parts = {}
    local current = obj
    while current do
        table.insert(parts, 1, current.Name)
        current = current.Parent
    end
    return table.concat(parts, ".")
end

-- 内部：路径绝对匹配 - 找到指定路径的对象，返回该对象（如果存在）
-- @param pathStr 完整路径字符串，如 "Workspace.bugbo.Build.Rocks.Rock"
-- @return 匹配到的对象，或 nil
local function findObjectByAbsolutePath(pathStr)
    local parts = {}
    for part in string.gmatch(pathStr, "[^%.]+") do
        table.insert(parts, part)
    end
    
    if #parts == 0 then return nil end
    
    -- 第一段必须是 Workspace
    local current = game
    for i = 1, #parts do
        current = current:FindFirstChild(parts[i])
        if not current then
            return nil
        end
    end
    return current
end

-- 内部：路径模糊匹配 - 在路径中查找匹配的层级
-- @param pathStr 对象的完整路径
-- @param patterns 要匹配的字符串或字符串表
-- @return 最深的匹配层级索引（从1开始），如果没找到返回0；如果传入表则返回最深的匹配层级
local function findDeepestMatchLevel(pathStr, patterns)
    local pathParts = {}
    for part in string.gmatch(pathStr, "[^%.]+") do
        table.insert(pathParts, part)
    end
    
    -- 统一转为表处理
    local searchTerms
    if type(patterns) == "table" then
        searchTerms = patterns
    else
        searchTerms = {patterns}
    end
    
    -- 对于单个字符串：找最深的匹配层级
    if #searchTerms == 1 then
        local term = searchTerms[1]
        local deepestLevel = 0
        for i, part in ipairs(pathParts) do
            if string.find(part, term) then
                deepestLevel = i
            end
        end
        return deepestLevel
    end
    
    -- 对于多个字符串的表：每个路径段检查是否包含任意一个搜索词
    -- 取最深的匹配层级（同时满足：该层级及以上已覆盖所有搜索词）
    local matchedLevels = {}
    for _, term in ipairs(searchTerms) do
        local deepestForTerm = 0
        for i, part in ipairs(pathParts) do
            if string.find(part, term) then
                deepestForTerm = i
            end
        end
        if deepestForTerm == 0 then
            return 0  -- 有搜索词完全没匹配到
        end
        table.insert(matchedLevels, deepestForTerm)
    end
    
    -- 返回最深的匹配层级
    local maxLevel = 0
    for _, level in ipairs(matchedLevels) do
        if level > maxLevel then
            maxLevel = level
        end
    end
    return maxLevel
end

-- 内部：判断对象是否在指定路径层级之下（从该层级往下）
-- @param obj 要检查的对象
-- @param targetPathLevel 目标层级索引（从1开始，1=Workspace）
-- @return boolean, 目标层级对象本身
local function isDescendantOfPathLevel(obj, targetPathLevel)
    if targetPathLevel <= 0 then return false, nil end
    
    local pathParts = {}
    local current = obj
    while current do
        table.insert(pathParts, 1, current)
        current = current.Parent
    end
    
    -- pathParts[1] = game, pathParts[2] = Workspace, ...
    -- targetPathLevel=1 对应 game, targetPathLevel=2 对应 Workspace
    -- 所以实际索引需要 +1（因为加入了 game）
    local actualIndex = targetPathLevel + 1
    
    if actualIndex <= #pathParts then
        return true, pathParts[actualIndex]
    end
    return false, nil
end

-- 创建高亮器实例
-- @param modelName     要匹配的名称/路径
-- @param matchMode     "only" 完全匹配, "fuzzy" 模糊匹配, "path" 路径绝对匹配, "pathFuzzy" 路径模糊匹配
-- @param colorPresetKey 颜色预设键名（如 "item"）
-- @param batchSize     每帧处理的对象数量（默认100，可根据性能调整）
local function createHighlighterInstance(modelName, matchMode, colorPresetKey, batchSize)
    local self = {}
    
    self.modelName = modelName
    self.matchMode = matchMode or "fuzzy"
    self.batchSize = batchSize or 100
    self.colorPreset = colorPresets[colorPresetKey] or {
        outlineColor = Color3.new(1, 1, 1),
        fillColor = Color3.new(1, 1, 1)
    }
    self.loop = true
    self.activeHandles = {}
    self.partToHighlight = {}
    self.scanConnection = nil
    self.descendantConnection = nil
    self.modelConns = {}
    
    -- 内部：为单个部件添加高亮（防重复）
    local function addHighlight(part)
        if not part:IsA("BasePart") then return end
        if self.partToHighlight[part] then
            return
        end
        local highlight = Instance.new("Highlight")
        highlight.FillColor = self.colorPreset.fillColor
        highlight.OutlineColor = self.colorPreset.outlineColor
        highlight.Parent = part
        table.insert(self.activeHandles, highlight)
        self.partToHighlight[part] = highlight
    end
    
    -- 内部：移除指定高亮
    local function removeHighlight(highlight)
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    
    -- 内部：为模型及其所有子部件添加高亮
    local function highlightModelAndDescendants(model)
        for _, part in model:GetDescendants() do
            addHighlight(part)
        end
    end
    
    -- 内部：检查对象是否应该被高亮（根据不同匹配模式）
    -- @param obj 要检查的对象
    -- @return boolean
    local function shouldHighlight(obj)
        if self.matchMode == "only" then
            return obj.Name == self.modelName
        elseif self.matchMode == "fuzzy" or not self.matchMode then
            -- 默认模糊匹配（保持向后兼容）
            return string.find(obj.Name, self.modelName) ~= nil
        elseif self.matchMode == "path" then
            -- 路径绝对匹配：对象路径必须完全等于指定路径
            local objPath = getFullPath(obj)
            return objPath == self.modelName
        elseif self.matchMode == "pathFuzzy" then
            -- 路径模糊匹配：对象的路径中任意层级包含匹配项
            local objPath = getFullPath(obj)
            local matchLevel = findDeepestMatchLevel(objPath, self.modelName)
            return matchLevel > 0
        end
        return false
    end
    
    -- 内部：处理路径匹配模式的高亮逻辑（path 和 pathFuzzy 共用）
    -- @param obj 目标对象
    local function handlePathModeHighlight(obj)
        if self.matchMode == "path" then
            -- 路径绝对匹配：找到指定路径的对象，高亮它及其所有子对象
            local targetObj = findObjectByAbsolutePath(self.modelName)
            if targetObj then
                if targetObj:IsA("Model") then
                    highlightModelAndDescendants(targetObj)
                elseif targetObj:IsA("BasePart") then
                    addHighlight(targetObj)
                end
                -- 如果目标对象本身是 Model，还要高亮它自己内部的部件
                -- 这里已经通过 highlightModelAndDescendants 处理了
            end
        elseif self.matchMode == "pathFuzzy" then
            -- 路径模糊匹配：在对象路径中查找匹配层级
            local objPath = getFullPath(obj)
            local matchLevel = findDeepestMatchLevel(objPath, self.modelName)
            if matchLevel > 0 then
                -- 找到最深的匹配层级，获取该层级的对象
                local pathParts = {}
                local current = obj
                while current do
                    table.insert(pathParts, 1, current)
                    current = current.Parent
                end
                -- pathParts: [game, Workspace, ...]
                -- matchLevel: 路径中的层级（1=Workspace 在路径中，但实际是 game 的子级）
                -- 所以 pathParts 中索引 = matchLevel + 1
                local targetIndex = matchLevel + 1
                if targetIndex <= #pathParts then
                    local targetObj = pathParts[targetIndex]
                    if targetObj:IsA("Model") then
                        highlightModelAndDescendants(targetObj)
                    elseif targetObj:IsA("BasePart") then
                        addHighlight(targetObj)
                    end
                end
            end
        end
    end
    
    -- 内部：异步扫描核心（分帧处理）
    local function asyncApplyCore(taskId)
        if self.scanConnection then
            self.scanConnection:Disconnect()
            self.scanConnection = nil
        end
        
        -- 路径匹配模式特殊处理：不需要遍历所有对象，直接定位目标
        if self.matchMode == "path" then
            -- 路径绝对匹配：直接找到目标对象，扫描其子对象（分帧）
            local targetObj = findObjectByAbsolutePath(self.modelName)
            if not targetObj then
                self.isApplyingAsync = false
                return
            end
            
            local allObjects = targetObj:GetDescendants()
            -- 如果目标对象本身是 BasePart，也需要高亮
            if targetObj:IsA("BasePart") then
                table.insert(allObjects, 1, targetObj)
            elseif targetObj:IsA("Model") then
                -- Model 本身不高亮，但它的子部件已经包含在 GetDescendants 中
                -- 不需要额外处理
            end
            
            local total = #allObjects
            local processed = 0
            local batch = self.batchSize
            
            self.scanConnection = RunService.RenderStepped:Connect(function()
                if taskId ~= self.currentApplyTaskId then
                    if self.scanConnection then
                        self.scanConnection:Disconnect()
                        self.scanConnection = nil
                    end
                    return
                end
                
                local endIdx = math.min(processed + batch, total)
                for i = processed + 1, endIdx do
                    local obj = allObjects[i]
                    addHighlight(obj)
                end
                processed = endIdx
                
                if processed >= total then
                    if self.scanConnection then
                        self.scanConnection:Disconnect()
                        self.scanConnection = nil
                    end
                    self.isApplyingAsync = false
                end
            end)
            return
        end
        
        -- 路径模糊匹配：需要遍历所有对象，但只为匹配的添加高亮
        local allObjects = Workspace:GetDescendants()
        local total = #allObjects
        local processed = 0
        local batch = self.batchSize
        
        self.scanConnection = RunService.RenderStepped:Connect(function()
            if taskId ~= self.currentApplyTaskId then
                if self.scanConnection then
                    self.scanConnection:Disconnect()
                    self.scanConnection = nil
                end
                return
            end
            
            local endIdx = math.min(processed + batch, total)
            for i = processed + 1, endIdx do
                local obj = allObjects[i]
                
                if self.matchMode == "pathFuzzy" then
                    -- 路径模糊匹配：检查对象路径并处理
                    local objPath = getFullPath(obj)
                    local matchLevel = findDeepestMatchLevel(objPath, self.modelName)
                    if matchLevel > 0 then
                        -- 找到匹配层级，高亮对象（如果是 BasePart）
                        -- 注意：如果 obj 是该层级对象的后代，也会被匹配到
                        if obj:IsA("BasePart") then
                            addHighlight(obj)
                        end
                    end
                else
                    -- 原有的 only/fuzzy 匹配逻辑
                    if obj.Name == self.modelName or (self.matchMode ~= "only" and string.find(obj.Name, self.modelName)) then
                        if obj:IsA("Model") then
                            for _, part in obj:GetDescendants() do
                                addHighlight(part)
                            end
                        elseif obj:IsA("BasePart") then
                            addHighlight(obj)
                        end
                    end
                end
            end
            processed = endIdx
            
            if processed >= total then
                if self.scanConnection then
                    self.scanConnection:Disconnect()
                    self.scanConnection = nil
                end
                self.isApplyingAsync = false
            end
        end)
    end
    
    -- 公共方法：应用高亮（异步）
    self.apply = function()
        if self.isApplyingAsync then
            self.currentApplyTaskId = getNewTaskId()
            if self.scanConnection then
                self.scanConnection:Disconnect()
                self.scanConnection = nil
            end
        else
            self.currentApplyTaskId = getNewTaskId()
        end
        
        -- 清理之前的动态监听
        if self.descendantConnection then
            self.descendantConnection:Disconnect()
            self.descendantConnection = nil
        end
        for _, conn in pairs(self.modelConns) do
            conn:Disconnect()
        end
        self.modelConns = {}
        
        self.isApplyingAsync = true
        asyncApplyCore(self.currentApplyTaskId)
        
        -- 如果启用循环，监听新加入的对象
        if self.loop then
            self.descendantConnection = Workspace.DescendantAdded:Connect(function(descendant)
                if self.matchMode == "path" then
                    -- 路径绝对匹配的循环监听
                    local targetObj = findObjectByAbsolutePath(self.modelName)
                    if targetObj then
                        -- 检查新对象是否是目标对象的后代
                        local current = descendant
                        while current do
                            if current == targetObj then
                                if descendant:IsA("BasePart") then
                                    addHighlight(descendant)
                                elseif descendant:IsA("Model") then
                                    for _, part in descendant:GetDescendants() do
                                        addHighlight(part)
                                    end
                                    local childConn = descendant.DescendantAdded:Connect(function(newPart)
                                        addHighlight(newPart)
                                    end)
                                    table.insert(self.modelConns, childConn)
                                end
                                break
                            end
                            current = current.Parent
                        end
                    end
                elseif self.matchMode == "pathFuzzy" then
                    -- 路径模糊匹配的循环监听
                    local objPath = getFullPath(descendant)
                    local matchLevel = findDeepestMatchLevel(objPath, self.modelName)
                    if matchLevel > 0 and descendant:IsA("BasePart") then
                        addHighlight(descendant)
                    end
                    -- 如果是 Model，监听其内部新增部件
                    if matchLevel > 0 and descendant:IsA("Model") then
                        for _, part in descendant:GetDescendants() do
                            addHighlight(part)
                        end
                        local childConn = descendant.DescendantAdded:Connect(function(newPart)
                            addHighlight(newPart)
                        end)
                        table.insert(self.modelConns, childConn)
                    end
                else
                    -- 原有的 only/fuzzy 循环逻辑
                    local current = descendant
                    while current do
                        if current.Name == self.modelName or (self.matchMode ~= "only" and string.find(current.Name, self.modelName)) then
                            if current:IsA("Model") then
                                for _, part in current:GetDescendants() do
                                    addHighlight(part)
                                end
                                local childConn = current.DescendantAdded:Connect(function(newPart)
                                    addHighlight(newPart)
                                end)
                                table.insert(self.modelConns, childConn)
                            elseif current:IsA("BasePart") then
                                addHighlight(current)
                            end
                            break
                        end
                        current = current.Parent
                    end
                end
            end)
        end
    end
    
    -- 公共方法：销毁此高亮器创建的所有高亮
    self.destroy = function()
        if self.scanConnection then
            self.scanConnection:Disconnect()
            self.scanConnection = nil
        end
        if self.descendantConnection then
            self.descendantConnection:Disconnect()
            self.descendantConnection = nil
        end
        for _, conn in pairs(self.modelConns) do
            conn:Disconnect()
        end
        self.modelConns = {}
        
        for _, highlight in pairs(self.activeHandles) do
            removeHighlight(highlight)
        end
        self.activeHandles = {}
        self.partToHighlight = {}
        
        if self.isApplyingAsync then
            self.currentApplyTaskId = getNewTaskId()
            self.isApplyingAsync = false
        end
    end
    
    -- 公共方法：卸载此实例
    self.unload = function()
        self.destroy()
        for i, v in ipairs(activeHighlighters) do
            if v == self then
                table.remove(activeHighlighters, i)
                break
            end
        end
    end
    
    table.insert(activeHighlighters, self)
    return self
end

-- 对外接口
highlighter.new = createHighlighterInstance

-- 全局卸载所有高亮器
highlighter.unload = function()
    for i = #activeHighlighters, 1, -1 do
        activeHighlighters[i]:unload()
    end
end

return highlighter