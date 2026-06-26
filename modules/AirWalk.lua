-- 空中行走模块
local airwalk = {}

-- 私有变量
local floorPart = nil
local floorY = nil
local isActive = false

-- 连接句柄，用于清理
local heartbeatConnection = nil
local characterAddedConnection = nil
local diedConnection = nil

-- 内部引用，避免重复获取
local cloneref = cloneref or clonereference or function(obj) return obj end
local LocalPlayer = cloneref(game:GetService("Players")).LocalPlayer
local RunService = cloneref(game:GetService("RunService"))

-- 创建地板
local function createFloor(character)
    if floorPart then return end
    
    local Humanoid = character:WaitForChild("Humanoid")
    local HumanoidRootPart = character:WaitForChild("HumanoidRootPart")

    -- 创建地板
    floorPart = Instance.new("Part")
    floorPart.Size = Vector3.new(10, 1, 10)
    floorPart.Transparency = 1 -- 完全透明
    floorPart.Anchored = true
    floorPart.CanCollide = true
    floorPart.Parent = workspace

    -- 添加发光特效
    local glow = Instance.new("SurfaceGui", floorPart)
    glow.Face = Enum.NormalId.Top
    local frame = Instance.new("Frame", glow)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.new(0, 1, 0) -- 绿色发光
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel = 0

    -- 计算地板Y轴高度：玩家脚底位置向下偏移地板厚度的一半再减1.8
    floorY = HumanoidRootPart.Position.Y - HumanoidRootPart.Size.Y / 2 - floorPart.Size.Y / 2 - 1.8
    floorPart.Position = Vector3.new(HumanoidRootPart.Position.X, floorY, HumanoidRootPart.Position.Z)
end

-- 删除地板
local function destroyFloor()
    if floorPart then
        floorPart:Destroy()
        floorPart = nil
    end
    floorY = nil
end

-- 更新地板位置
local function updateFloorPosition(character)
    if not floorPart or not floorY then return end
    local HumanoidRootPart = character:WaitForChild("HumanoidRootPart")
    floorPart.Position = Vector3.new(HumanoidRootPart.Position.X, floorY, HumanoidRootPart.Position.Z)
end

-- 获取当前角色（优先使用已存在的，否则等待）
local function getCurrentCharacter()
    local char = LocalPlayer.Character
    if char then return char end
    return LocalPlayer.CharacterAdded:Wait()
end

-- 死亡时自动关闭空中行走
local function onCharacterDied()
    if isActive then
        -- 直接调用disable，避免状态不一致
        airwalk.disable()
    end
end

-- 设置角色相关事件（每次角色重生时重新绑定）
local function setupCharacterEvents(character)
    local humanoid = character:WaitForChild("Humanoid")
    -- 先断开旧的死亡连接，避免重复绑定
    if diedConnection then
        diedConnection:Disconnect()
        diedConnection = nil
    end
    diedConnection = humanoid.Died:Connect(onCharacterDied)
end

-- 启用空中行走
function airwalk.enable()
    if isActive then return end
    
    local character = getCurrentCharacter()
    if not character then return end
    
    -- 创建地板
    createFloor(character)
    if not floorPart then return end -- 创建失败则退出
    
    isActive = true
    
    -- 绑定心跳更新地板位置
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
    end
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        if isActive and floorPart and LocalPlayer.Character then
            updateFloorPosition(LocalPlayer.Character)
        end
    end)
    
    -- 绑定角色重生事件，确保每次重生后仍能正常工作（重新创建地板）
    if characterAddedConnection then
        characterAddedConnection:Disconnect()
    end
    characterAddedConnection = LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        if isActive then
            -- 角色重生后重新创建地板
            destroyFloor()
            createFloor(newCharacter)
            setupCharacterEvents(newCharacter)
        end
    end)
    
    -- 为当前角色绑定死亡事件
    setupCharacterEvents(character)
end

-- 关闭空中行走（保留模块，仅停止功能）
function airwalk.disable()
    if not isActive then return end
    
    isActive = false
    destroyFloor()
    
    -- 断开心跳连接
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
    -- 断开死亡事件（避免disable后死亡仍触发清理）
    if diedConnection then
        diedConnection:Disconnect()
        diedConnection = nil
    end
    -- 注意：characterAddedConnection 保留，因为 disable 后重新 enable 仍需监听重生
    -- 但为了避免无用的监听，这里也断开，enable时会重新创建
    if characterAddedConnection then
        characterAddedConnection:Disconnect()
        characterAddedConnection = nil
    end
end

-- 完全卸载模块，清理所有残留，并将airwalk表重置
function airwalk.unload()
    -- 先禁用功能
    airwalk.disable()
    
    -- 清理所有可能的残留连接（确保彻底）
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
    if characterAddedConnection then
        characterAddedConnection:Disconnect()
        characterAddedConnection = nil
    end
    if diedConnection then
        diedConnection:Disconnect()
        diedConnection = nil
    end
    
    -- 清除模块内所有数据
    floorPart = nil
    floorY = nil
    isActive = false
    
    -- 可选：清空airwalk表，使其无法再次调用（如果需要彻底卸载）
    -- 但为了保留模块结构，仅清除内部状态，外部仍可调用，但无效果
    -- 如果想彻底销毁，可以执行: for k in pairs(airwalk) do airwalk[k] = nil end
    -- 这里选择保留方法但功能已失效（因为内部状态已清）
end

-- 返回模块
return airwalk