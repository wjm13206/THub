-- ScrollSwitch 模块
-- V + 滚轮 循环切换快捷栏道具

local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local ContextActionService = cloneref(game:GetService("ContextActionService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local VirtualInputManager = cloneref(game:GetService("VirtualInputManager"))

local ScrollSwitch = {}
local player = Players.LocalPlayer
local character = nil

-- 内部状态
local enabled = false
local modifierKey = Enum.KeyCode.V  -- 默认V键
local validSlots = {}
local currentSlotIndex = 1
local lastScrollTime = 0
local modifierHeld = false

-- 事件连接引用，用于断开
local connections = {}

-- 数字到KeyCode的映射
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

-- 模拟按数字键
local function pressNumberKey(num: number)
	local keyCode = numberToKeyCode[num]
	if keyCode then
		VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
		VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
	end
end

-- 检测手上是否有道具
local function hasToolEquipped()
	if not character then return false end
	return character:FindFirstChildOfClass("Tool") ~= nil
end

-- 扫描全部10个格子
local function scanAllSlots()
	validSlots = {}
	
	if not character then return end
	
	for i = 1, 9 do
		pressNumberKey(i)
		task.wait(0.05)
		
		if hasToolEquipped() then
			table.insert(validSlots, i)
			-- 取消装备
			pressNumberKey(i)
			task.wait(0.05)
		end
	end
	
	pressNumberKey(0)
	task.wait(0.05)
	if hasToolEquipped() then
		table.insert(validSlots, 0)
		pressNumberKey(0)
		task.wait(0.05)
	end
	
	if #validSlots > 0 then
		currentSlotIndex = 1
		pressNumberKey(validSlots[1])
	end
end

-- 切换到上一个
local function switchToPrev()
	if #validSlots == 0 then return end
	currentSlotIndex = currentSlotIndex - 1
	if currentSlotIndex < 1 then
		currentSlotIndex = #validSlots
	end
	pressNumberKey(validSlots[currentSlotIndex])
end

-- 切换到下一个
local function switchToNext()
	if #validSlots == 0 then return end
	currentSlotIndex = currentSlotIndex + 1
	if currentSlotIndex > #validSlots then
		currentSlotIndex = 1
	end
	pressNumberKey(validSlots[currentSlotIndex])
end

-- 绑定所有事件
local function bindEvents()
	-- 先解绑旧的（如果有的话），确保干净
	ContextActionService:UnbindAction("ScrollSwitch")
	
	-- 滚轮绑定
	ContextActionService:BindAction(
		"ScrollSwitch",
		function(actionName, inputState, inputObject)
			if inputState == Enum.UserInputState.Change then
				if modifierHeld then
					local now = tick()
					if now - lastScrollTime < 0.1 then
						return Enum.ContextActionResult.Sink
					end
					lastScrollTime = now

					local delta = inputObject.Position.Z
					if delta > 0 then
						switchToPrev()
					elseif delta < 0 then
						switchToNext()
					end
					return Enum.ContextActionResult.Sink
				else
					return Enum.ContextActionResult.Pass
				end
			end
			return Enum.ContextActionResult.Pass
		end,
		false,
		Enum.UserInputType.MouseWheel
	)

	-- 按键按下
	local inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode == modifierKey then
			modifierHeld = true
		else
			-- 检测是否按下了数字键1~9或0
			local pressedSlot = nil
			for i = 1, 9 do
				if input.KeyCode == numberToKeyCode[i] then
					pressedSlot = i
					break
				end
			end
			if not pressedSlot and input.KeyCode == Enum.KeyCode.Zero then
				pressedSlot = 0
			end
		
			-- 如果按的是数字键，且在有效格子里，同步循环位置
			if pressedSlot then
				for idx, slot in ipairs(validSlots) do
					if slot == pressedSlot then
						currentSlotIndex = idx
						break
					end
				end
			end
		end
	end)
	table.insert(connections, inputBeganConn)

	-- 修饰键松开
	local inputEndedConn = UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.KeyCode == modifierKey then
			modifierHeld = false
		end
	end)
	table.insert(connections, inputEndedConn)

	-- 角色重生
	local charAddedConn = player.CharacterAdded:Connect(function(newChar)
		character = newChar
		task.wait(0.2)
		if enabled then
			scanAllSlots()
		end
	end)
	table.insert(connections, charAddedConn)
end

-- 解绑所有事件
local function unbindEvents()
	ContextActionService:UnbindAction("ScrollSwitch")

	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end
	connections = {}

	modifierHeld = false
end

-- ============ 公开方法 ============

-- 开启功能
function ScrollSwitch:enable()
	if enabled then return end
	enabled = true

	-- 获取当前角色
	character = player.Character
	if character then
		task.wait(0.2)
		scanAllSlots()
	end

	-- 绑定事件
	bindEvents()
end

-- 关闭功能
function ScrollSwitch:disable()
	if not enabled then return end
	enabled = false
	unbindEvents()
end

-- 卸载功能（与disable一样，完全清理）
function ScrollSwitch:unload()
	self:disable()
end

-- 获取绑定按键
function ScrollSwitch:getbind()
	return modifierKey
end

-- 设置绑定按键
function ScrollSwitch:setbind(newKey: Enum.KeyCode)
	if typeof(newKey) ~= "EnumItem" then
		warn("setbind 需要传入 Enum.KeyCode 类型的值")
		return
	end
	modifierKey = newKey
	print("修饰键已设置为:", modifierKey.Name)

	-- 如果当前是启用状态，只重建按键监听，不动滚轮
	if enabled then
		-- 断开旧的按键监听
		for i = #connections, 1, -1 do
			local conn = connections[i]
			conn:Disconnect()
			table.remove(connections, i)
		end

		-- 重建按键监听
		local inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if input.KeyCode == modifierKey then
				modifierHeld = true
			end
		end)
		table.insert(connections, inputBeganConn)

		local inputEndedConn = UserInputService.InputEnded:Connect(function(input, gameProcessed)
			if input.KeyCode == modifierKey then
				modifierHeld = false
			end
		end)
		table.insert(connections, inputEndedConn)
		
		modifierHeld = false
	end
end

return ScrollSwitch