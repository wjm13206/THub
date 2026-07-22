-- ClickDeleteModule - 按住 Ctrl + 点击删除部件
-- 方法：Enable() 开启功能 | Disable() 关闭功能 | Unload() 彻底卸载

local ClickDeleteModule = {}
local connections = {}
local isEnabled = false
local isUnloaded = false

-- 内部引用
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local player
local mouse
local button1DownConnection

-- ========== 核心功能 ==========

local function onButton1Down()
	if not isEnabled then return end
	if isUnloaded then return end
	
	-- 检测 Ctrl 键
	local ctrlHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) 
		or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
	
	if not ctrlHeld then return end
	
	-- 获取点击目标
	local target = mouse.Target
	if not target then return end
	
	-- 只删除 BasePart，排除地形
	if target:IsA("BasePart") then
		-- 可选：排除玩家自己的角色
		local character = player.Character
		if character and target:IsDescendantOf(character) then
			return
		end
		
		-- 删除部件
		target:Destroy()
	end
end

-- ========== 公开方法 ==========

-- 开启功能
function ClickDeleteModule.enable()
	if isUnloaded then
		return
	end
	
	if isEnabled then
		return
	end
	
	-- 初始化玩家和鼠标
	player = Players.LocalPlayer
	mouse = player:GetMouse()
	
	-- 绑定点击事件
	button1DownConnection = mouse.Button1Down:Connect(onButton1Down)
	table.insert(connections, button1DownConnection)
	
	isEnabled = true
end

-- 关闭功能（可重新开启）
function ClickDeleteModule.disable()
	if not isEnabled then
		return
	end
	
	-- 断开点击事件
	if button1DownConnection then
		button1DownConnection:Disconnect()
		button1DownConnection = nil
	end
	
	isEnabled = false
end

-- 彻底卸载（无法再使用）
function ClickDeleteModule.unload()
	-- 先关闭功能
	if isEnabled then
		ClickDeleteModule.disable()
	end
	
	-- 清空所有连接
	for _, conn in ipairs(connections) do
		if conn then
			conn:Disconnect()
		end
	end
	connections = {}
	
	-- 清空引用
	player = nil
	mouse = nil
	
	isUnloaded = true
end

-- ========== 返回模块 ==========

return ClickDeleteModule