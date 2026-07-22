-- AntiFling.lua
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))

local AntiFling = {}
local connections = {}
local isEnabled = false
local speaker
local heartbeatConn -- 定期巡检连接

-- 处理单个角色
local function setupCharacter(character)
	if not character then return end

	for _, v in pairs(character:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
		end
	end

	local conn = character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
		end
	end)
	table.insert(connections, conn)
end

-- 定期巡检：只修复 CanCollide = true 的部件（兜底保障）
local function patrolCheck()
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= speaker and player.Character then
			for _, v in pairs(player.Character:GetDescendants()) do
				if v:IsA("BasePart") and v.CanCollide == true then
					v.CanCollide = false
				end
			end
		end
	end
end

-- 处理新玩家加入
local function onPlayerAdded(player)
	if not isEnabled or player == speaker then return end

	local charConn = player.CharacterAdded:Connect(function(character)
		setupCharacter(character)
	end)
	table.insert(connections, charConn)

	if player.Character then
		setupCharacter(player.Character)
	end
end

-- 恢复所有碰撞
local function restoreAllCollisions()
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= speaker and player.Character then
			for _, v in pairs(player.Character:GetDescendants()) do
				if v:IsA("BasePart") then
					v.CanCollide = true
				end
			end
		end
	end
end

function AntiFling.enable(speakerRef)
	if isEnabled then return end
	isEnabled = true
	speaker = speakerRef

	-- 事件驱动（主力）
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= speaker then
			onPlayerAdded(player)
		end
	end

	local playerAddedConn = Players.PlayerAdded:Connect(onPlayerAdded)
	table.insert(connections, playerAddedConn)

	-- 定期巡检（兜底，每1秒检查一次）
	heartbeatConn = RunService.Heartbeat:Connect(function()
		-- 用简单的时间计数，避免依赖 os.clock
		if not isEnabled then return end
		patrolCheck()
	end)
end

function AntiFling.disable()
	if not isEnabled then return end
	isEnabled = false

	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end
	table.clear(connections)

	if heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end

	restoreAllCollisions()
	speaker = nil
end

function AntiFling.unload()
	AntiFling.disable()
end

return AntiFling