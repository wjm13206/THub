-- SnapTurn 模块
-- 放入 ReplicatedStorage，类型为 ModuleScript
-- 使用方式: local SnapTurn = require(path.to.SnapTurn)
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))

local SnapTurn = {}
local connections = {}  -- 存储连接，用于卸载
local enabled = false

-- 内部变量
local player = nil
local character = nil
local humanoid = nil
local rootPart = nil
local renderSteppedConn = nil
local charAddedConn = nil

--==========================================
-- 每帧执行的转向逻辑
--==========================================
local function onRenderStepped()
	if not humanoid or not humanoid.Parent or not rootPart or not rootPart.Parent then
		return
	end

	local moveDir = humanoid.MoveDirection
	if moveDir.Magnitude > 0 then
		rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + moveDir)
	end
end

--==========================================
-- 绑定角色
--==========================================
local function setupCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	rootPart = char:WaitForChild("HumanoidRootPart")

	humanoid.AutoRotate = false

	-- 连接到渲染循环
	if renderSteppedConn then
		renderSteppedConn:Disconnect()
	end
	renderSteppedConn = RunService.RenderStepped:Connect(onRenderStepped)
end

--==========================================
-- 公开方法
--==========================================

-- 开启 SnapTurn
function SnapTurn.Enable(plr)
	player = plr or Players.LocalPlayer

	if enabled then return end
	enabled = true

	-- 监听角色添加
	charAddedConn = player.CharacterAdded:Connect(function(char)
		if enabled then
			setupCharacter(char)
		end
	end)

	-- 绑定当前角色
	if player.Character then
		setupCharacter(player.Character)
	end
end

-- 关闭 SnapTurn（恢复默认转向，保留监听）
function SnapTurn.Disable()
	if not enabled then return end
	enabled = false

	-- 恢复 AutoRotate
	if humanoid then
		humanoid.AutoRotate = true
	end

	-- 断开渲染连接
	if renderSteppedConn then
		renderSteppedConn:Disconnect()
		renderSteppedConn = nil
	end
end

-- 彻底卸载（清理所有连接，无法再次使用，需要重新 require）
function SnapTurn.Unload()
	SnapTurn.Disable()

	-- 断开角色添加监听
	if charAddedConn then
		charAddedConn:Disconnect()
		charAddedConn = nil
	end

	-- 清空引用
	player = nil
	character = nil
	humanoid = nil
	rootPart = nil

	-- 清空模块函数，防止再次调用
	for k, _ in pairs(SnapTurn) do
		SnapTurn[k] = nil
	end
end

return SnapTurn