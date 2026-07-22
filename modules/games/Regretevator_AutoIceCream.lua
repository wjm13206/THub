local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local VirtualInputManager = cloneref(game:GetService("VirtualInputManager"))

local AutoIceCream = {}
local player = Players.LocalPlayer
local character = nil
local humanoid = nil

local enabled = false
local isUsing = false
local lastUseTime = 0
local useCooldown = 3
local healthThreshold = 1
local lastPressedSlot = 1
local healthConn = nil
local charConn = nil
local inputConn = nil

local numberToKeyCode = {
	[0] = Enum.KeyCode.Zero,
	[1] = Enum.KeyCode.One,
	[2] = Enum.KeyCode.Two,
	[3] = Enum.KeyCode.Three,
	[4] = Enum.KeyCode.Four,
	[5] = Enum.KeyCode.Five,
	[6] = Enum.KeyCode.Six,
	[7] = Enum.KeyCode.Seven,
	[8] = Enum.KeyCode.Eight,
	[9] = Enum.KeyCode.Nine,
}

local function pressKey(num)
	local keyCode = numberToKeyCode[num]
	if keyCode then
		VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
		VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
	end
end

local function clickMouse()
	VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
	task.wait(0.05)
	VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local function getIceCream()
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return nil end
	return backpack:FindFirstChild("IceCreamCone")
end

local function useIceCream()
	if isUsing then return end
	if not character or not humanoid then return end
	
	local iceCream = getIceCream()
	if not iceCream then return end
	
	local now = tick()
	if now - lastUseTime < useCooldown then return end
	
	local hp = humanoid.Health
	local maxHp = humanoid.MaxHealth
	if hp >= maxHp * healthThreshold then return end
	
	isUsing = true
	lastUseTime = now
	
	humanoid:EquipTool(iceCream)
	task.wait(0.1)
	clickMouse()
	task.wait(0.3)
	pressKey(lastPressedSlot)
	
	isUsing = false
end

local function onHealthChanged(newHealth)
	if not enabled then return end
	local maxHp = humanoid and humanoid.MaxHealth or 100
	if newHealth < maxHp * healthThreshold then
		useIceCream()
	end
end

local function unbindEvents()
	if healthConn then healthConn:Disconnect(); healthConn = nil end
	if charConn then charConn:Disconnect(); charConn = nil end
	if inputConn then inputConn:Disconnect(); inputConn = nil end
end

local function bindEvents()
	unbindEvents()
	
	inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		for i = 0, 9 do
			if input.KeyCode == numberToKeyCode[i] then
				lastPressedSlot = i
				return
			end
		end
	end)
	
	if humanoid then
		healthConn = humanoid.HealthChanged:Connect(onHealthChanged)
	end
	
	charConn = player.CharacterAdded:Connect(function(newChar)
		character = newChar
		humanoid = newChar:WaitForChild("Humanoid", 5)
		if humanoid and enabled then
			if healthConn then healthConn:Disconnect() end
			healthConn = humanoid.HealthChanged:Connect(onHealthChanged)
		end
	end)
end

function AutoIceCream:enable()
	if enabled then return end
	enabled = true
	character = player.Character
	if character then
		humanoid = character:FindFirstChildOfClass("Humanoid")
	end
	bindEvents()
end

function AutoIceCream:disable()
	if not enabled then return end
	enabled = false
	isUsing = false
	unbindEvents()
end

function AutoIceCream:unload()
	self:disable()
end

function AutoIceCream:setCooldown(seconds: number)
	useCooldown = seconds
end

function AutoIceCream:setHealthThreshold(ratio: number)
	healthThreshold = math.clamp(ratio, 0, 1)
end

return AutoIceCream