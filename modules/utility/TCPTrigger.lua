--!native
--!optimize 2
local cloneref = cloneref or clonereference or function(obj) return obj end
local Services = setmetatable({}, { __index = function(self, name) local success, cache = pcall(function() return cloneref(game:GetService(name)) end); if success then rawset(self, name, cache); return cache else error("无效服务: "..tostring(name)) end end})

local Players = Services.Players
local Workspace = Services.Workspace
local RunService = Services.RunService

local LocalPlayer = Players.LocalPlayer

-- ============================================================
--  状态管理（支持多类型同时运行）
-- ============================================================

local ActiveTypes = {} -- [interactType] = { Connection, Triggered }
local Distance = 20
local RingScale = 0.8
local RangeRing = nil
local LoopEnabled = false -- 循环触发开关，默认关闭

-- 全局实例缓存：{ [interactType] = { inst1, inst2, ... } }
local TypeCache = {}
local CacheConnections = {}

-- 循环触发状态管理
local LoopStates = {} -- [interactType] = { loopConnection, lastTriggerTime }
local LOOP_INTERVAL = 1/100 -- 每秒100次的间隔时间

-- ============================================================
--  工具 & 触发函数
-- ============================================================

local function GetRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart") or nil
end

local function GetInstancePosition(inst)
    local cur = inst
    while cur do
        if cur:IsA("BasePart") then return cur.Position end
        cur = cur.Parent
    end
    return nil
end

local function FireTouch(inst, rootPart)
    if not firetouchinterest then return end
    local part = inst:FindFirstAncestorWhichIsA("Part")
    if part then
        task.spawn(function()
            firetouchinterest(part, rootPart, 1)
            task.wait()
            firetouchinterest(part, rootPart, 0)
        end)
    else
        pcall(function() inst.CFrame = rootPart.CFrame end)
    end
end

local function FireClick(inst)
    if not fireclickdetector then return end
    pcall(fireclickdetector, inst)
end

local function FirePrompt(inst)
    if not fireproximityprompt then return end
    pcall(fireproximityprompt, inst)
end

local FireMap = {
    TouchTransmitter = FireTouch,
    ClickDetector = FireClick,
    ProximityPrompt = FirePrompt,
}

-- ============================================================
--  增量缓存系统（解决卡顿核心）
-- ============================================================

local function BuildCache(interactType)
    TypeCache[interactType] = {}
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA(interactType) then
            table.insert(TypeCache[interactType], desc)
        end
    end
end

local function StartCacheTracking(interactType)
    BuildCache(interactType)

    local addedConn = Workspace.DescendantAdded:Connect(function(desc)
        if desc:IsA(interactType) then
            table.insert(TypeCache[interactType], desc)
        end
    end)

    local removingConn = Workspace.DescendantRemoving:Connect(function(desc)
        if desc:IsA(interactType) then
            local cache = TypeCache[interactType]
            if cache then
                for i = #cache, 1, -1 do
                    if cache[i] == desc then
                        table.remove(cache, i)
                        break
                    end
                end
            end
        end
    end)

    CacheConnections[interactType] = { addedConn, removingConn }
end

local function StopCacheTracking(interactType)
    local conns = CacheConnections[interactType]
    if conns then
        for _, conn in ipairs(conns) do conn:Disconnect() end
        CacheConnections[interactType] = nil
    end
    TypeCache[interactType] = nil
end

-- ============================================================
--  可视化范围圈 - 用多个小Part拼成圆形环
-- ============================================================

local RingParts = {}

-- ★ 根据半径动态计算分段数，保证圆环始终连贯
local function GetSegmentCount(radius)
    -- 每段弧长控制在 0.5 studs 左右，保证圆环看起来是实线
    local circumference = math.pi * 2 * radius
    local count = math.floor(circumference / 0.5)
    return math.max(32, math.min(256, count))  -- 最少32段，最多256段
end

local function BuildRing(rootPart)
    local ringRadius = Distance * RingScale
    local segmentCount = GetSegmentCount(ringRadius)
    local ringThickness = 0.3
    local ringHeight = 0.2
    local arcLength = (math.pi * 2 * ringRadius) / segmentCount + 0.05
    
    local footY = rootPart.Position.Y - (rootPart.Size.Y / 2) + 0.1
    local centerPos = Vector3.new(rootPart.Position.X, footY, rootPart.Position.Z)
    
    -- 如果分段数变了，先销毁旧的重新创建
    if #RingParts > 0 and #RingParts ~= segmentCount then
        DestroyRing()
    end
    
    if #RingParts == 0 then
        -- 创建新圆环
        for i = 1, segmentCount do
            local angle = (i - 1) * (math.pi * 2 / segmentCount)
            local x = math.cos(angle) * ringRadius
            local z = math.sin(angle) * ringRadius
            
            local part = Instance.new("Part")
            part.Name = "__RingSegment"
            part.Size = Vector3.new(ringThickness, ringHeight, arcLength)
            part.Position = centerPos + Vector3.new(x, 0, z)
            part.Anchored = true
            part.CanCollide = false
            part.Material = Enum.Material.Neon
            part.Color = Color3.fromRGB(0, 200, 255)
            part.Transparency = 0.5
            
            part.CFrame = CFrame.new(part.Position, centerPos) * CFrame.Angles(0, math.rad(90), 0)
            
            part.Parent = workspace
            table.insert(RingParts, part)
        end
    else
        -- 更新位置
        for i, part in ipairs(RingParts) do
            if part and part.Parent then
                local angle = (i - 1) * (math.pi * 2 / #RingParts)
                local x = math.cos(angle) * ringRadius
                local z = math.sin(angle) * ringRadius
                part.Size = Vector3.new(ringThickness, ringHeight, arcLength)
                part.Position = centerPos + Vector3.new(x, 0, z)
                part.CFrame = CFrame.new(part.Position, centerPos) * CFrame.Angles(0, math.rad(90), 0)
            end
        end
    end
end

local function DestroyRing()
    for _, part in ipairs(RingParts) do
        if part and part.Parent then
            part:Destroy()
        end
    end
    RingParts = {}
end

-- ============================================================
--  循环触发逻辑
-- ============================================================

local function StartLoopTrigger(interactType)
    local state = ActiveTypes[interactType]
    if not state then return end
    
    local fireFunc = FireMap[interactType]
    local loopState = {
        loopConnection = nil,
        lastTriggerTime = 0
    }
    
    loopState.loopConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not state.Running or not LoopEnabled then return end
        
        local rootPart = GetRoot()
        if not rootPart then return end
        
        local distSq = Distance * Distance
        local rootPos = rootPart.Position
        local cache = TypeCache[interactType]
        
        if not cache then return end
        
        local currentTime = tick()
        if currentTime - loopState.lastTriggerTime < LOOP_INTERVAL then
            return -- 还没到触发时间
        end
        
        local triggered = false
        
        for i = 1, #cache do
            if not state.Running or not LoopEnabled then break end
            
            local inst = cache[i]
            if inst and inst.Parent then
                local pos = GetInstancePosition(inst)
                if pos then
                    local dx, dy, dz = pos.X - rootPos.X, pos.Y - rootPos.Y, pos.Z - rootPos.Z
                    if dx*dx + dy*dy + dz*dz <= distSq then
                        fireFunc(inst, rootPart)
                        triggered = true
                    end
                end
            end
        end
        
        if triggered then
            loopState.lastTriggerTime = currentTime
        end
    end)
    
    LoopStates[interactType] = loopState
end

local function StopLoopTrigger(interactType)
    local loopState = LoopStates[interactType]
    if loopState and loopState.loopConnection then
        loopState.loopConnection:Disconnect()
    end
    LoopStates[interactType] = nil
end

-- ============================================================
--  核心循环工厂
-- ============================================================

local function CreateLoop(interactType)
    local state = ActiveTypes[interactType]
    if not state then return end

    local fireFunc = FireMap[interactType]
    
    local ringCreated = false

    state.Connection = RunService.Heartbeat:Connect(function()
        if not state.Running then return end

        local rootPart = GetRoot()
        if not rootPart then 
            if ringCreated then
                DestroyRing()
                ringCreated = false
            end
            return 
        end

        -- 每帧重建/更新圆环（让 setDistance/setRingScale 实时生效）
        BuildRing(rootPart)
        ringCreated = true

        -- 如果循环模式开启，跳过默认触发逻辑
        if LoopEnabled then return end

        local distSq = Distance * Distance  -- ★ 每帧重新算，setDistance 实时生效
        local rootPos = rootPart.Position
        local currentlyInRange = {}
        local cache = TypeCache[interactType]

        if cache then
            for i = 1, #cache do
                if not state.Running then break end

                local inst = cache[i]
                if inst and inst.Parent then
                    local pos = GetInstancePosition(inst)
                    if pos then
                        local dx, dy, dz = pos.X - rootPos.X, pos.Y - rootPos.Y, pos.Z - rootPos.Z
                        if dx*dx + dy*dy + dz*dz <= distSq then
                            currentlyInRange[inst] = true
                            if not state.Triggered[inst] then
                                state.Triggered[inst] = true
                                fireFunc(inst, rootPart)
                            end
                        end
                    end
                end
            end
        end

        for inst in pairs(state.Triggered) do
            if not currentlyInRange[inst] then
                state.Triggered[inst] = nil
            end
        end
    end)
end

-- ============================================================
--  模块 API
-- ============================================================

local Module = {}
local VALID_TYPES = { TouchTransmitter = true, ClickDetector = true, ProximityPrompt = true }

function Module.enable(interactType)
    if not VALID_TYPES[interactType] then return end

    if ActiveTypes[interactType] then
        Module.disable(interactType)
    end

    local state = {
        Running = true,
        Triggered = setmetatable({}, { __mode = "k" }),
        Connection = nil,
    }
    ActiveTypes[interactType] = state

    StartCacheTracking(interactType)
    CreateLoop(interactType)
    
    -- 如果循环模式开启，启动循环触发
    if LoopEnabled then
        StartLoopTrigger(interactType)
    end
end

function Module.disable(interactType)
    if not VALID_TYPES[interactType] then return end

    local state = ActiveTypes[interactType]
    if not state then return end

    state.Running = false

    if state.Connection then
        state.Connection:Disconnect()
        state.Connection = nil
    end

    StopLoopTrigger(interactType) -- 停止循环触发
    StopCacheTracking(interactType)
    ActiveTypes[interactType] = nil

    if not next(ActiveTypes) then
        DestroyRing()
    end
end

function Module.unload()
    for interactType in pairs(ActiveTypes) do
        Module.disable(interactType)
    end

    for interactType in pairs(CacheConnections) do
        StopCacheTracking(interactType)
    end

    DestroyRing()
    table.clear(Module)

    setmetatable(Module, {
        __index = function() return nil end,
        __newindex = function() end,
    })
end

function Module.setDistance(d)
    if type(d) == "number" and d > 0 then
        Distance = d
        DestroyRing()  -- ★ 强制销毁，下一帧会重建
    end
end

function Module.getDistance()
    return Distance
end

function Module.setRingScale(s)
    if type(s) == "number" and s > 0 then
        RingScale = s
        DestroyRing()  -- ★ 立即重建，分段数可能变化
    end
end

function Module.getRingScale()
    return RingScale
end

-- 循环触发开关控制
function Module.enableLoop()
    if LoopEnabled then return end
    
    LoopEnabled = true
    
    -- 为所有当前激活的类型启动循环触发
    for interactType, state in pairs(ActiveTypes) do
        if state.Running and not LoopStates[interactType] then
            StartLoopTrigger(interactType)
        end
    end
end

function Module.disableLoop()
    if not LoopEnabled then return end
    
    LoopEnabled = false
    
    -- 停止所有循环触发
    for interactType in pairs(LoopStates) do
        StopLoopTrigger(interactType)
    end
end

function Module.isLoopEnabled()
    return LoopEnabled
end

return Module