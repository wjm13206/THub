-- nofall ModuleScript (备选方案 - 直接修改 Humanoid 状态)
-- 放在 StarterCharacterScripts 中
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))

local player = Players.LocalPlayer

local heartbeatConnection = nil
local character = nil
local humanoid = nil
local rootPart = nil
local enabled = false
local wasFalling = false

local function onHeartbeat()
	if not humanoid or not humanoid.Parent then return end
	if not rootPart or not rootPart.Parent then return end

	-- 检测 Humanoid 的下落状态
	local state = humanoid:GetState()
	
	if state == Enum.HumanoidStateType.Freefall then
		wasFalling = true
		-- 在下落时把重力影响降到最低
		local velocity = rootPart.AssemblyLinearVelocity
		if velocity.Y < -50 then
			rootPart.AssemblyLinearVelocity = Vector3.new(velocity.X, -50, velocity.Z)
		end
	elseif wasFalling and state == Enum.HumanoidStateType.Landed then
		-- 刚落地，重置标记
		wasFalling = false
	end
end

local function startHeartbeat()
	if heartbeatConnection then return end
	heartbeatConnection = RunService.Heartbeat:Connect(onHeartbeat)
end

local function stopHeartbeat()
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
end

local function onCharacterAdded(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	wasFalling = false
	if enabled then
		startHeartbeat()
	end
end

if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)

local NoFall = {}

function NoFall.enable()
	if enabled then return end
	enabled = true
	if character then
		startHeartbeat()
	end
end

function NoFall.disable()
	enabled = false
	stopHeartbeat()
end

function NoFall.unload()
	NoFall.disable()
	character = nil
	humanoid = nil
	rootPart = nil
end

return NoFall