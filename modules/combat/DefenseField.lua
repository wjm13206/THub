-- DefenseField 防御力场模块（删除版）
-- 客户端使用，进入力场范围的可移动非玩家部件直接删除
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local localPlayer = Players.LocalPlayer

local DefenseField = {}
local isEnabled = false
local heartbeatConnection = nil
local characterAddedConnection = nil

-- 配置
local CONFIG = {
	RADIUS = 15,                -- 力场半径（Studs）
	SHOW_VISUAL = true,         -- 是否显示力场视觉效果
	VISUAL_TRANSPARENCY = 0.85, -- 视觉效果透明度
	SCAN_INTERVAL = 5,          -- 每隔多少帧扫描一次
	MOVEMENT_THRESHOLD = 0.1,   -- 移动检测阈值
	MAX_DELETE_PER_SCAN = 10,   -- 每次最多删除数量
}

-- 要保护的部件名称
local PROTECTED_NAMES = {
	["HumanoidRootPart"] = true,
	["Head"] = true,
	["Torso"] = true,
	["UpperTorso"] = true,
	["LowerTorso"] = true,
	["Left Arm"] = true,
	["Right Arm"] = true,
	["Left Leg"] = true,
	["Right Leg"] = true,
	["Humanoid"] = true,
}

-- 视觉效果
local visualField = nil

-- OverlapParams 复用
local overlapParams
local function getOverlapParams()
	if overlapParams then return overlapParams end
	local success, result = pcall(function()
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.RespectCanCollide = false
		return params
	end)
	if success then
		overlapParams = result
	end
	return overlapParams
end

-- 获取所有玩家角色列表
local function getAllCharacters()
	local characters = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			characters[player.Character] = true
		end
	end
	return characters
end

-- 检查部件是否属于某个玩家角色
local function isPartOfCharacter(part, character)
	if not character then return false end
	return part:IsDescendantOf(character)
end

-- 检查部件是否属于任何玩家
local function isPartOfAnyPlayer(part, allCharacters)
	for char, _ in pairs(allCharacters) do
		if isPartOfCharacter(part, char) then
			return true
		end
	end
	return false
end

-- 判断部件是否在移动
local function isPartMoving(part)
	local success, vel = pcall(function() return part.AssemblyLinearVelocity end)
	if success and vel and vel.Magnitude > CONFIG.MOVEMENT_THRESHOLD then
		return true
	end

	success, vel = pcall(function() return part.Velocity end)
	if success and vel and vel.Magnitude > CONFIG.MOVEMENT_THRESHOLD then
		return true
	end

	return false
end

-- 安全创建 Part
local function safeCreatePart()
	local success, part = pcall(function()
		return Instance.new("Part")
	end)
	if success and part then
		return part
	end
	return nil
end

-- 移除视觉效果
local function removeVisual()
	if visualField then
		pcall(function()
			visualField:Destroy()
		end)
		visualField = nil
	end
end

-- 创建视觉效果
local function createVisual(character)
	removeVisual()

	if not CONFIG.SHOW_VISUAL then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local part = safeCreatePart()
	if not part then return end

	part.Name = "DefenseFieldVisual"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(CONFIG.RADIUS * 2, CONFIG.RADIUS * 2, CONFIG.RADIUS * 2)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.Transparency = CONFIG.VISUAL_TRANSPARENCY
	part.Color = Color3.fromRGB(255, 50, 50)
	part.Material = Enum.Material.ForceField
	part.CastShadow = false
	part.Parent = cloneref(workspace)
	part.Position = rootPart.Position

	visualField = part
end

-- 角色重生时重新创建视觉效果
local function onCharacterAdded(character)
	if not isEnabled then return end

	removeVisual()

	local rootPart = character:WaitForChild("HumanoidRootPart", 5)
	if rootPart and CONFIG.SHOW_VISUAL then
		createVisual(character)
	end
end

-- 扫描并删除周围移动部件
local function scanAndDelete(centerPosition)
	local params = getOverlapParams()
	if not params then return end

	local allCharacters = getAllCharacters()

	local partsInRange
	local success, result = pcall(function()
		return cloneref(workspace):GetPartBoundsInRadius(centerPosition, CONFIG.RADIUS, params)
	end)

	if not success then return end
	partsInRange = result

	local deleteCount = 0
	for _, part in ipairs(partsInRange) do
		if deleteCount >= CONFIG.MAX_DELETE_PER_SCAN then break end
		if not isEnabled then return end

		if not part or not part.Parent then continue end
		if part.Anchored then continue end
		if PROTECTED_NAMES[part.Name] then continue end
		if isPartOfAnyPlayer(part, allCharacters) then continue end
		if not isPartMoving(part) then continue end

		pcall(function()
			part:Destroy()
		end)
		deleteCount = deleteCount + 1
	end
end

-- 帧计数器
local frameCount = 0

-- 每帧执行
local function onHeartbeat()
	if not isEnabled then return end

	local character = localPlayer.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- 每帧更新球体位置
	if CONFIG.SHOW_VISUAL and visualField and visualField.Parent then
		visualField.Position = rootPart.Position
	end

	-- 每 N 帧扫描一次
	frameCount = frameCount + 1
	if frameCount >= CONFIG.SCAN_INTERVAL then
		frameCount = 0
		scanAndDelete(rootPart.Position)
	end
end

-- ==================== 公开方法 ====================

function DefenseField.SetConfig(newConfig)
	for k, v in pairs(newConfig) do
		if CONFIG[k] ~= nil then
			CONFIG[k] = v
		end
	end
	if newConfig.RADIUS and isEnabled and CONFIG.SHOW_VISUAL and localPlayer.Character then
		createVisual(localPlayer.Character)
	end
end

function DefenseField.GetConfig()
	return CONFIG
end

-- 开启防御力场
function DefenseField.enable()
	if isEnabled then return end

	isEnabled = true
	frameCount = 0

	heartbeatConnection = RunService.Heartbeat:Connect(onHeartbeat)
	characterAddedConnection = localPlayer.CharacterAdded:Connect(onCharacterAdded)

	if localPlayer.Character and CONFIG.SHOW_VISUAL then
		createVisual(localPlayer.Character)
	end
end

-- 关闭防御力场
function DefenseField.disable()
	if not isEnabled then return end

	isEnabled = false

	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end

	if characterAddedConnection then
		characterAddedConnection:Disconnect()
		characterAddedConnection = nil
	end

	removeVisual()
end

-- 卸载模块
function DefenseField.unload()
	DefenseField.disable()

	for k, _ in pairs(DefenseField) do
		DefenseField[k] = nil
	end
end

return DefenseField