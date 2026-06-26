-- MovingPartCleaner 模块
-- 客户端使用，持续检测并删除正在移动的非玩家非固定部件
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local localPlayer = Players.LocalPlayer

local MovingPartCleaner = {}
local isEnabled = false
local heartbeatConnection = nil

-- 要保留的部件名称白名单（玩家角色核心部件）
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

-- 配置
local CONFIG = {
	MOVEMENT_THRESHOLD = 0.1,  -- 移动检测阈值
	SCAN_INTERVAL = 10,          -- 每多少帧扫描一次（越大越不卡）
	SCAN_RADIUS = 300,           -- 扫描半径，只处理玩家周围这个范围内的部件
	MAX_PARTS_PER_SCAN = 5,   -- 每次最多处理部件数
}

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

-- 检查部件是否属于某个玩家角色
local function isPartOfCharacter(part, character)
	if not character then return false end
	return part:IsDescendantOf(character)
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

-- 判断部件是否在移动（用pcall保护）
local function isPartMoving(part)
	local success, vel = pcall(function() return part.Velocity end)
	if success and vel and vel.Magnitude > CONFIG.MOVEMENT_THRESHOLD then
		return true
	end

	success, vel = pcall(function() return part.AssemblyLinearVelocity end)
	if success and vel and vel.Magnitude > CONFIG.MOVEMENT_THRESHOLD then
		return true
	end

	success, vel = pcall(function() return part.AssemblyAngularVelocity end)
	if success and vel and vel.Magnitude > CONFIG.MOVEMENT_THRESHOLD then
		return true
	end

	return false
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

-- 单次扫描逻辑（改用 GetPartBoundsInRadius，只扫描玩家周围）
local function scanAndClean()
	if not isEnabled then return end

	local character = localPlayer.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local centerPosition = rootPart.Position
	local allCharacters = getAllCharacters()

	local params = getOverlapParams()
	if not params then return end

	-- 只获取玩家周围范围内的部件（不遍历全图）
	local partsInRange
	local success, result = pcall(function()
		return cloneref(workspace):GetPartBoundsInRadius(centerPosition, CONFIG.SCAN_RADIUS, params)
	end)

	if not success then return end
	partsInRange = result

	local count = 0
	for _, part in ipairs(partsInRange) do
		-- 达到上限就停
		if count >= CONFIG.MAX_PARTS_PER_SCAN then break end
		-- 中途禁用就停
		if not isEnabled then return end

		if not part or not part.Parent then continue end
		if part.Anchored then continue end
		if PROTECTED_NAMES[part.Name] then continue end
		if isPartOfAnyPlayer(part, allCharacters) then continue end
		if not isPartMoving(part) then continue end

		-- 删除
		pcall(function()
			part:Destroy()
		end)
		count = count + 1
	end
end

-- 帧计数器
local frameCount = 0

-- 每帧执行
local function onHeartbeat()
	if not isEnabled then return end
	frameCount = frameCount + 1
	if frameCount >= CONFIG.SCAN_INTERVAL then
		frameCount = 0
		scanAndClean()
	end
end

-- ==================== 公开方法 ====================

-- 开启检测
function MovingPartCleaner.Enable()
	if isEnabled then return end

	isEnabled = true
	frameCount = 0

	heartbeatConnection = RunService.Heartbeat:Connect(onHeartbeat)
end

-- 关闭检测
function MovingPartCleaner.Disable()
	if not isEnabled then return end

	isEnabled = false

	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
end

-- 卸载模块
function MovingPartCleaner.Unload()
	MovingPartCleaner.Disable()

	for k, _ in pairs(MovingPartCleaner) do
		MovingPartCleaner[k] = nil
	end
end

return MovingPartCleaner