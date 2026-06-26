-- ================================================
-- 文件名：MovableHighlighter.lua
-- 放置位置：ReplicatedStorage（客户端 require 使用）
-- ================================================

local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local Workspace = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))

local MovableHighlighter = {}

-- 默认配置（可修改）
local DEFAULT_CONFIG = {
    fillColor = Color3.fromRGB(255, 215, 0),      -- 填充色（金色）
    outlineColor = Color3.fromRGB(255, 215, 0),     -- 轮廓色（红色）
    fillTransparency = 0.7,
    outlineTransparency = 0.0,
    maxHeight = 100,                               -- 最大允许高度（Y轴）
    excludedNames = {"Camera", "Terrain"},         -- 排除的物体名称
    batchSize = 80,                                -- 每帧处理的对象数量（降低初始卡顿）
}

-- 实例表（用于全局卸载）
local instances = {}

-- -------------------------------------------------
-- 实例元表
-- -------------------------------------------------
local Highlighter = {}
Highlighter.__index = Highlighter

-- 创建新实例
function MovableHighlighter.new(config)
    local self = setmetatable({}, Highlighter)
    self.config = {}
    for k, v in pairs(DEFAULT_CONFIG) do
        self.config[k] = config and config[k] ~= nil and config[k] or v
    end
    self.enabled = false
    self.activeHighlights = {}          -- { [BasePart] = Highlight }
    self.scanConnection = nil           -- 分帧扫描连接
    self.descendantConnection = nil     -- DescendantAdded 连接
    self.pendingTask = nil              -- 当前扫描任务ID
    table.insert(instances, self)
    return self
end

-- -------------------------------------------------
-- 内部函数：判断部件是否合法
-- -------------------------------------------------
local function isValidPart(self, part)
    -- 1. 必须是 BasePart
    if not part:IsA("BasePart") then
        return false
    end
    -- 2. 未锚定
    if part.Anchored then
        return false
    end
    -- 3. 排除玩家角色及其所有子部件（向上找到根模型）
    local model = part
    while model and not model:IsA("Model") do
        model = model.Parent
    end
    if model and Players:GetPlayerFromCharacter(model) then
        return false
    end
    -- 4. 排除名称黑名单
    if table.find(self.config.excludedNames, part.Name) then
        return false
    end
    -- 5. 低于最大高度
    if part.Position.Y >= self.config.maxHeight then
        return false
    end
    return true
end

-- -------------------------------------------------
-- 内部函数：为部件添加高亮（防重复）
-- -------------------------------------------------
local function addHighlightToPart(self, part)
    if self.activeHighlights[part] then
        return
    end
    local highlight = Instance.new("Highlight")
    highlight.Name = "MovableObjectHighlight"
    highlight.FillColor = self.config.fillColor
    highlight.OutlineColor = self.config.outlineColor
    highlight.FillTransparency = self.config.fillTransparency
    highlight.OutlineTransparency = self.config.outlineTransparency
    highlight.Adornee = part
    highlight.Parent = part
    self.activeHighlights[part] = highlight
end

-- -------------------------------------------------
-- 内部函数：移除所有高亮
-- -------------------------------------------------
local function removeAllHighlights(self)
    for part, highlight in pairs(self.activeHighlights) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    self.activeHighlights = {}
end

-- -------------------------------------------------
-- 内部函数：分帧扫描现有物体（异步，只收集 BasePart 和 Model）
-- -------------------------------------------------
local function scanExistingAsync(self)
    if self.scanConnection then
        self.scanConnection:Disconnect()
        self.scanConnection = nil
    end
    -- 只收集需要检查的对象（BasePart 和 Model），减少后续遍历
    local allObjects = Workspace:GetDescendants()
    local relevant = {}
    for _, obj in ipairs(allObjects) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            table.insert(relevant, obj)
        end
    end
    local total = #relevant
    local processed = 0
    local batchSize = self.config.batchSize
    local taskId = {}
    self.pendingTask = taskId

    self.scanConnection = RunService.RenderStepped:Connect(function()
        if not self.enabled or taskId ~= self.pendingTask then
            if self.scanConnection then
                self.scanConnection:Disconnect()
                self.scanConnection = nil
            end
            return
        end
        local endIdx = math.min(processed + batchSize, total)
        for i = processed + 1, endIdx do
            local obj = relevant[i]
            if obj:IsA("BasePart") and isValidPart(self, obj) then
                addHighlightToPart(self, obj)
            elseif obj:IsA("Model") then
                -- 模型需要检查其内部所有 BasePart
                for _, part in ipairs(obj:GetDescendants()) do
                    if part:IsA("BasePart") and isValidPart(self, part) then
                        addHighlightToPart(self, part)
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
            self.pendingTask = nil
        end
    end)
end

-- -------------------------------------------------
-- 内部函数：监听新物体
-- -------------------------------------------------
local function startListeners(self)
    if self.descendantConnection then
        self.descendantConnection:Disconnect()
        self.descendantConnection = nil
    end
    self.descendantConnection = Workspace.DescendantAdded:Connect(function(desc)
        if not self.enabled then return end
        if desc:IsA("BasePart") and isValidPart(self, desc) then
            addHighlightToPart(self, desc)
        elseif desc:IsA("Model") then
            -- 模型整体加入，递归处理其子部件
            for _, part in ipairs(desc:GetDescendants()) do
                if part:IsA("BasePart") and isValidPart(self, part) then
                    addHighlightToPart(self, part)
                end
            end
        end
    end)
end

-- -------------------------------------------------
-- 内部函数：停止所有监听和扫描
-- -------------------------------------------------
local function stopAll(self)
    if self.scanConnection then
        self.scanConnection:Disconnect()
        self.scanConnection = nil
    end
    if self.descendantConnection then
        self.descendantConnection:Disconnect()
        self.descendantConnection = nil
    end
    self.pendingTask = nil
end

-- -------------------------------------------------
-- 公共方法：启用高亮
-- -------------------------------------------------
function Highlighter:enable()
    if self.enabled then return end
    self.enabled = true
    -- 延迟一帧开始扫描，避免阻塞当前线程（可选）
    task.defer(function()
        if not self.enabled then return end
        scanExistingAsync(self)
        startListeners(self)
    end)
end

-- -------------------------------------------------
-- 公共方法：禁用高亮（清除所有高亮，停止监听）
-- -------------------------------------------------
function Highlighter:disable()
    if not self.enabled then return end
    self.enabled = false
    stopAll(self)
    removeAllHighlights(self)
end

-- -------------------------------------------------
-- 公共方法：卸载实例（彻底清理）
-- -------------------------------------------------
function Highlighter:unload()
    self:disable()
    -- 从全局实例列表中移除
    for i, inst in ipairs(instances) do
        if inst == self then
            table.remove(instances, i)
            break
        end
    end
    setmetatable(self, nil)
end

-- -------------------------------------------------
-- 模块级卸载：销毁所有实例
-- -------------------------------------------------
function MovableHighlighter.unloadAll()
    for i = #instances, 1, -1 do
        instances[i]:unload()
    end
end

return MovableHighlighter