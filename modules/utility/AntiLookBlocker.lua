-- 模块名：AntiLookBlocker (ModuleScript)
-- 放置位置：ReplicatedStorage 等可被客户端访问的容器
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))

local Module = {}
local enabled = false
local loaded = true

local player = nil
local camera = nil
local blockerPart = nil
local renderConnection = nil

-- 创建/销毁阻挡物
local function createBlocker()
	if blockerPart then return end
	blockerPart = Instance.new("Part")
	blockerPart.Name = "AntiLookBlocker"
	blockerPart.Size = Vector3.new(4, 4, 0.2)
	blockerPart.Transparency = 1
	blockerPart.CanCollide = false
	blockerPart.Anchored = true
	blockerPart.Material = Enum.Material.SmoothPlastic
	blockerPart.CastShadow = false
	blockerPart.Parent = cloneref(workspace)
end

local function destroyBlocker()
	if blockerPart then
		blockerPart:Destroy()
		blockerPart = nil
	end
end

-- 每帧更新阻挡物位置（紧贴摄像机前方）
local function onRenderStep()
	if not enabled then return end
	if not camera then
		camera = cloneref(workspace).CurrentCamera
		if not camera then return end
	end
	if not blockerPart or not blockerPart.Parent then
		createBlocker()
	end
	-- 放在摄像机前方 2 studs，并朝向摄像机（阻挡射线）
	local offset = camera.CFrame * CFrame.new(0, 0, -2)
	blockerPart.CFrame = offset * CFrame.Angles(0, math.rad(180), 0)
end

-- 开启功能
function Module.enable(plr)
	if not loaded then return end
	if enabled then return end

	player = plr or Players.LocalPlayer
	enabled = true

	createBlocker()
	if not renderConnection then
		renderConnection = RunService.RenderStepped:Connect(onRenderStep)
	end
end

-- 关闭功能
function Module.disable()
	if not enabled then return end
	enabled = false

	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
	destroyBlocker()
end

-- 彻底卸载模块（不可再次使用）
function Module.unload()
	Module.disable()
	loaded = false
	player = nil
	camera = nil
	-- 移除模块自身所有字段，帮助GC
	for k in pairs(Module) do
		if type(Module[k]) ~= "function" then
			Module[k] = nil
		end
	end
end

return Module