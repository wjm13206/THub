-- GuiDeleter.lua
-- 一款无需实例化的模块，用于按绑定键删除鼠标指向的GUI
-- 放置于 ReplicatedStorage 或 ServerScriptService 等合适位置

local cloneref = cloneref or clonereference or function(obj) return obj end
local UserInputService = cloneref(game:GetService("UserInputService"))
local Players = cloneref(game:GetService("Players"))

local GuiDeleter = {}
local isEnabled = false
local bindKey = Enum.KeyCode.Backspace -- 默认按键
local inputBeganConnection = nil
local localPlayer = Players.LocalPlayer

-- 内部核心删除函数
local function deleteGuisAtPosition()
	pcall(function()
		local playerGui = localPlayer:GetGuiObjectsAtPosition(
			UserInputService:GetMouseLocation().X,
			UserInputService:GetMouseLocation().Y
		)
		for _, gui in ipairs(playerGui) do
			if gui.Visible then
				gui:Destroy()
			end
		end
	end)
end

-- 处理按键输入
local function onInputBegan(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == bindKey then
		deleteGuisAtPosition()
	end
end

-- 启动功能
local function start()
	if isEnabled and not inputBeganConnection then
		inputBeganConnection = UserInputService.InputBegan:Connect(onInputBegan)
	end
end

-- 停止功能
local function stop()
	if inputBeganConnection then
		inputBeganConnection:Disconnect()
		inputBeganConnection = nil
	end
end

--[[
	启用模块功能
]]
function GuiDeleter.enable()
	if isEnabled then return end
	isEnabled = true
	start()
end

--[[
	禁用模块功能
]]
function GuiDeleter.disable()
	if not isEnabled then return end
	isEnabled = false
	stop()
end

--[[
	获取当前绑定的按键
	@return Enum.KeyCode 当前绑定的按键
]]
function GuiDeleter.getBindKey()
	return bindKey
end

--[[
	设置新的绑定按键
	@param newKey Enum.KeyCode 新的按键代码
]]
function GuiDeleter.setBindKey(newKey)
	if typeof(newKey) ~= "EnumItem" or newKey.EnumType ~= Enum.KeyCode then
		warn("GuiDeleter.setBindKey 需要传入一个 Enum.KeyCode 类型的参数")
		return
	end

	local wasEnabled = isEnabled
	if wasEnabled then
		stop()
	end

	bindKey = newKey

	if wasEnabled then
		start()
	end
end

--[[
	卸载整个模块，断开所有连接并重置状态
]]
function GuiDeleter.unload()
	stop()
	isEnabled = false
	bindKey = Enum.KeyCode.Backspace
end

return GuiDeleter