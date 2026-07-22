local cloneref = cloneref or clonereference or function(obj) return obj end
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local module = {}

-- 内部状态
local isEnabled = false
local isUnlocked = false
local originalMouseBehavior = nil
local heartbeatConnection = nil
local keyStates = { K = false, L = false }
local toggleTriggered = false

-- 保存所有连接
local connections = {}

-- 强制保持解锁状态的循环
local function enforceUnlock()
	if not isUnlocked then return end
	if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

-- 快捷键处理
local function onInputBegan(input, gameProcessed)
	if not isEnabled or gameProcessed then return end
	if UserInputService:GetFocusedTextBox() then return end

	local key = input.KeyCode
	if key == Enum.KeyCode.K then
		keyStates.K = true
	elseif key == Enum.KeyCode.L then
		keyStates.L = true
	end

	if keyStates.K and keyStates.L and not toggleTriggered then
		toggleTriggered = true
		if isUnlocked then
			module.Restore()
		else
			module.Unlock()
		end
	end
end

local function onInputEnded(input)
	if not isEnabled then return end
	local key = input.KeyCode
	if key == Enum.KeyCode.K then
		keyStates.K = false
		toggleTriggered = false
	elseif key == Enum.KeyCode.L then
		keyStates.L = false
		toggleTriggered = false
	end
end

local beganConn, endedConn

function module.enable()
	if isEnabled then return end
	isEnabled = true
	keyStates.K = false
	keyStates.L = false
	toggleTriggered = false
	beganConn = UserInputService.InputBegan:Connect(onInputBegan)
	endedConn = UserInputService.InputEnded:Connect(onInputEnded)
	-- 保存连接
	table.insert(connections, beganConn)
	table.insert(connections, endedConn)
end

function module.disable()
	if not isEnabled then return end
	isEnabled = false
	if beganConn then beganConn:Disconnect() beganConn = nil end
	if endedConn then endedConn:Disconnect() endedConn = nil end
	-- 从连接表中移除
	for i, conn in ipairs(connections) do
		if conn == beganConn or conn == endedConn then
			table.remove(connections, i)
		end
	end
	if isUnlocked then
		module.Restore()
	end
	keyStates.K = false
	keyStates.L = false
	toggleTriggered = false
end

function module.Unlock()
	if isUnlocked then return end
	if originalMouseBehavior == nil then
		originalMouseBehavior = UserInputService.MouseBehavior
	end
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	isUnlocked = true
	if not heartbeatConnection then
		heartbeatConnection = RunService.Heartbeat:Connect(enforceUnlock)
		-- 保存连接
		table.insert(connections, heartbeatConnection)
	end
end

function module.Restore()
	if not isUnlocked then return end
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		-- 从连接表中移除
		for i, conn in ipairs(connections) do
			if conn == heartbeatConnection then
				table.remove(connections, i)
				break
			end
		end
		heartbeatConnection = nil
	end
	if originalMouseBehavior then
		UserInputService.MouseBehavior = originalMouseBehavior
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
	isUnlocked = false
end

function module.IsUnlocked()
	return isUnlocked
end

function module.IsEnabled()
	return isEnabled
end

-- 卸载函数
function module.unload()
	-- 先恢复到原始状态
	if isUnlocked then
		module.Restore()
	end
	
	-- 禁用快捷键监听
	if isEnabled then
		if beganConn then 
			beganConn:Disconnect() 
			beganConn = nil 
		end
		if endedConn then 
			endedConn:Disconnect() 
			endedConn = nil 
		end
		isEnabled = false
	end
	
	-- 确保心跳连接已断开
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
	
	-- 断开所有剩余连接
	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end
	connections = {}
	
	-- 重置所有内部状态
	keyStates = { K = false, L = false }
	toggleTriggered = false
	originalMouseBehavior = nil
	
	-- 清空模块表
	for k in pairs(module) do
		module[k] = nil
	end
end

return module