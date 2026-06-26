-- SnapReverse 模块（纯视角反转）
-- 放入 ReplicatedStorage，类型为 ModuleScript
-- 功能：按下热键，摄像机瞬间转向当前视角的反方向
--       第一人称和第三人称均适用
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))

local SnapReverse = {}
local enabled = false
local loaded = true

local player = nil
local camera = nil
local currentKeyBind = Enum.KeyCode.G  -- 默认按键 G

local inputBeganConn = nil

--==========================================
-- 核心：视角瞬间反转
--==========================================
local function snapCameraReverse()
	camera = cloneref(workspace).CurrentCamera
	if not camera then return end

	-- 当前摄像机朝向
	local lookVector = camera.CFrame.LookVector

	-- 180度反转：看向完全相反的方向
	-- 这样抬头看天，反转后就低头看地
	local reversedLook = -lookVector

	-- 保持摄像机位置不变，只改朝向
	camera.CFrame = CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + reversedLook)
end

--==========================================
-- 按键监听
--==========================================
local function onInputBegan(input, gameProcessed)
	if not enabled then return end
	if gameProcessed then return end

	if input.KeyCode == currentKeyBind then
		snapCameraReverse()
	end
end

--==========================================
-- 开启
--==========================================
function SnapReverse.Enable(plr)
	if not loaded then
		return
	end
	if enabled then return end

	player = plr or Players.LocalPlayer
	enabled = true

	inputBeganConn = UserInputService.InputBegan:Connect(onInputBegan)
end

--==========================================
-- 关闭
--==========================================
function SnapReverse.Disable()
	if not enabled then return end
	enabled = false

	if inputBeganConn then
		inputBeganConn:Disconnect()
		inputBeganConn = nil
	end
end

--==========================================
-- 彻底卸载
--==========================================
function SnapReverse.Unload()
	if not loaded then return end

	SnapReverse.Disable()

	player = nil
	camera = nil
	loaded = false

	for k, _ in pairs(SnapReverse) do
		SnapReverse[k] = nil
	end
end

--==========================================
-- 获取按键绑定
--==========================================
function SnapReverse.GetKeyBind()
	return currentKeyBind
end

--==========================================
-- 设置按键绑定
--==========================================
function SnapReverse.SetKeyBind(keyCode)
	if typeof(keyCode) == "EnumItem" and keyCode.EnumType == Enum.KeyCode then
		currentKeyBind = keyCode
		return true
	else
		return false
	end
end

return SnapReverse