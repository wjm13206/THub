-- ClickInspectModule - 按住 Ctrl + 点击打印部件信息
-- 方法：Enable() 开启功能 | Disable() 关闭功能 | Unload() 彻底卸载

local ClickInspectModule = {}
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

-- ========== 辅助函数 ==========

-- 获取部件的完整路径
local function getFullPath(instance)
	local path = {}
	local current = instance
	
	while current do
		table.insert(path, 1, current.Name)
		current = current.Parent
	end
	
	return table.concat(path, " → ")
end

-- 获取部件的主要属性信息
local function getPartInfo(target)
	local info = {}
	
	-- 基本信息
	info["名称"] = target.Name
	info["完整路径"] = getFullPath(target)
	info["类型"] = target.ClassName
	info["父级"] = target.Parent and target.Parent:GetFullName() or "nil"
	
	-- BasePart 专有属性
	if target:IsA("BasePart") then
		info["位置 (Position)"] = target.Position
		info["大小 (Size)"] = target.Size
		info["旋转 (Orientation)"] = target.Orientation
		info["材质 (Material)"] = tostring(target.Material)
		info["颜色 (Color)"] = target.Color
		info["锚定 (Anchored)"] = target.Anchored
		info["碰撞 (CanCollide)"] = target.CanCollide
		info["透明度 (Transparency)"] = target.Transparency
		
		-- 如果是 MeshPart
		if target:IsA("MeshPart") and target.MeshId ~= "" then
			info["网格ID (MeshId)"] = target.MeshId
		end
	end
	
	-- 实例的 GUID（如果存在）
	-- info["GUID"] = tostring(target:GetAttribute("GUID")) -- 自定义属性示例
	
	return info
end

-- 美化打印部件信息
local function printPartInfo(target)
	local info = getPartInfo(target)
	local separator = string.rep("═", 60)
	
	print("\n" .. separator)
	print("🔍 部件信息 (Ctrl+点击)")
	print(separator)
	
	for key, value in pairs(info) do
		print(string.format("  %-25s : %s", key, tostring(value)))
	end
	
	print(separator .. "\n")
end

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
	if not target then
		return
	end
	
	-- 打印部件信息
	printPartInfo(target)
end

-- ========== 公开方法 ==========

-- 开启功能
function ClickInspectModule.enable()
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
function ClickInspectModule.disable()
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
function ClickInspectModule.unload()
	-- 先关闭功能
	if isEnabled then
		ClickInspectModule.disable()
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

return ClickInspectModule