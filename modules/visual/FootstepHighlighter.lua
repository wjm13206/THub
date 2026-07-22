-- 落脚点指示器模块 (支持移动部件版)
-- 功能：在玩家下方所有可站立表面显示标记点（包括移动部件）
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))

-- 配置
local DETECT_RADIUS = 5             -- 检测范围半径（加大一点，移动部件可能较远）
local MAX_DETECT_DEPTH = 10000        -- 最大检测深度
local MARKER_COLOR = Color3.fromRGB(255, 80, 80)
local MARKER_TRANSPARENCY = 0.4
local BILLBOARD_SIZE = Vector2.new(1.5, 1.5)

-- 私有状态
local _enabled = false
local _connection = nil
local _markers = {}          -- {part: markerModel}
local _player = Players.LocalPlayer
local _loaded = true

-- 创建标记模型
local function createMarker(position)
    local model = Instance.new("Model")
    model.Name = "LandingMarker"

    -- 底面光圈
    local ring = Instance.new("Part")
    ring.Name = "Ring"
    ring.Size = Vector3.new(0.6, 0.05, 0.6)
    ring.CFrame = CFrame.new(position)
    ring.Anchored = true
    ring.CanCollide = false
    ring.CastShadow = false
    ring.Transparency = MARKER_TRANSPARENCY
    ring.Material = Enum.Material.Neon
    ring.BrickColor = BrickColor.new(MARKER_COLOR)
    ring.Parent = model

    -- 小光柱向上延伸
    local pillar = Instance.new("Part")
    pillar.Name = "Pillar"
    pillar.Size = Vector3.new(0.15, 0.3, 0.15)
    pillar.CFrame = CFrame.new(position) * CFrame.new(0, 0.175, 0)
    pillar.Anchored = true
    pillar.CanCollide = false
    pillar.CastShadow = false
    pillar.Transparency = 0.3
    pillar.Material = Enum.Material.Neon
    pillar.BrickColor = BrickColor.new(MARKER_COLOR)
    pillar.Parent = model

    -- Billboard标志
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "MarkerGUI"
    billboard.Adornee = ring
    billboard.Size = UDim2.new(0, BILLBOARD_SIZE.X, 0, BILLBOARD_SIZE.Y)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 0.3, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    billboard.Parent = ring

    -- 使用简单图形
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Position = UDim2.new(0.5, -15, 0.5, -15)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    icon.ImageColor3 = MARKER_COLOR
    icon.ImageTransparency = 0.2
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = icon

    return model
end

-- 获取部件顶部可站立位置
local function getStandableSurface(part, footPos)
    if not part or not part:IsA("BasePart") then return nil end
    if not part.CanCollide then return nil end
    -- 移除了 Anchored 的限制！现在移动部件也能被检测到
    
    local cframe = part.CFrame
    local size = part.Size
    
    -- 计算部件顶部世界坐标
    local topSurfaceY = cframe.Position.Y + size.Y / 2
    
    -- 检查footPos是否在部件水平范围内
    local relativePos = cframe:PointToObjectSpace(Vector3.new(footPos.X, topSurfaceY, footPos.Z))
    
    local halfX = size.X / 2
    local halfZ = size.Z / 2
    
    -- 扩大一点容差，让移动部件更容易被检测到
    local margin = 1.0
    if math.abs(relativePos.X) > halfX + margin or math.abs(relativePos.Z) > halfZ + margin then
        return nil
    end
    
    -- 计算可站立的表面点（部件的顶部中心投影）
    local clampedX = math.clamp(relativePos.X, -halfX, halfX)
    local clampedZ = math.clamp(relativePos.Z, -halfZ, halfZ)
    
    local worldPos = cframe:PointToWorldSpace(Vector3.new(clampedX, size.Y / 2, clampedZ))
    
    -- 只要在玩家下方就显示（包括空中预判）
    if worldPos.Y < footPos.Y - 0.05 then
        return worldPos
    end
    
    return nil
end

-- 更新标记位置（用于移动部件）
local function updateMarkerPosition(marker, newPosition)
    if not marker or not marker.Parent then return end
    
    local ring = marker:FindFirstChild("Ring")
    if ring then
        ring.CFrame = CFrame.new(newPosition)
    end
    
    local pillar = marker:FindFirstChild("Pillar")
    if pillar then
        pillar.CFrame = CFrame.new(newPosition) * CFrame.new(0, 0.175, 0)
    end
end

-- 清理所有标记
local function clearMarkers()
    for part, marker in pairs(_markers) do
        if marker and marker.Parent then
            marker:Destroy()
        end
    end
    _markers = {}
end

-- 主更新函数
local function updateMarkers()
    if not _loaded or not _enabled then return end
    
    local character = _player.Character
    if not character then
        clearMarkers()
        return
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then
        clearMarkers()
        return
    end
    
    -- 玩家脚底位置
    local footPos = rootPart.Position - Vector3.new(0, humanoid.HipHeight, 0)
    
    -- 获取玩家下方所有部件
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Blacklist
    overlapParams.FilterDescendantsInstances = {character}
    overlapParams.MaxParts = 100
    
    -- 检测范围：以玩家脚底为中心，向下延伸
    local boxCenter = footPos - Vector3.new(0, MAX_DETECT_DEPTH / 2, 0)
    local boxSize = Vector3.new(DETECT_RADIUS * 2, MAX_DETECT_DEPTH, DETECT_RADIUS * 2)
    
    local overlapParts = workspace:GetPartBoundsInBox(CFrame.new(boxCenter), boxSize, overlapParams)
    
    -- 记录当前帧检测到的部件
    local currentParts = {}
    local newMarkers = {}
    
    for _, part in ipairs(overlapParts) do
        -- 移除了 Anchored 判断！现在所有 CanCollide 的部件都会被检测
        if part:IsA("BasePart") and part.CanCollide then
            -- 避免重复处理
            if not currentParts[part] then
                currentParts[part] = true
                
                local landingPoint = getStandableSurface(part, footPos)
                if landingPoint then
                    -- 检查是否已有标记
                    local existingMarker = _markers[part]
                    if existingMarker and existingMarker.Parent then
                        -- 更新位置（移动部件需要每帧更新）
                        updateMarkerPosition(existingMarker, landingPoint)
                        newMarkers[part] = existingMarker
                    else
                        -- 创建新标记
                        local marker = createMarker(landingPoint)
                        marker.Parent = workspace
                        newMarkers[part] = marker
                    end
                end
            end
        end
    end
    
    -- 删除不再需要的标记
    for part, marker in pairs(_markers) do
        if not newMarkers[part] then
            if marker and marker.Parent then
                marker:Destroy()
            end
        end
    end
    
    _markers = newMarkers
end

-- 公共API
local API = {}

function API.enable()
    if not _loaded then
        return false
    end
    if _enabled then return true end
    
    _enabled = true
    _connection = RunService.RenderStepped:Connect(updateMarkers)
    return true
end

function API.disable()
    if not _enabled then return end
    _enabled = false
    if _connection then
        _connection:Disconnect()
        _connection = nil
    end
    clearMarkers()
end

function API.unload()
    if not _loaded then return end
    API.disable()
    _loaded = false
    _player = nil
    _markers = nil
end

return API