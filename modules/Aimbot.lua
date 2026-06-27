--!native
--!optimize 2

local fov = 75
local attraction = 0.3
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Cam = game.Workspace.CurrentCamera

local FOVring = Drawing.new("Circle")
FOVring.Visible = true
FOVring.Thickness = 2
FOVring.Color = Color3.fromRGB(0, 0, 0)
FOVring.Filled = false
FOVring.Radius = fov
FOVring.Position = Cam.ViewportSize / 2

local currentTarget = nil

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Delete then
		RunService:UnbindFromRenderStep("AimbotUpdate")
		FOVring:Remove()
		currentTarget = nil
	end
end)

local function isAlive(player)
	if not player or not player.Character then return false end
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid.Health > 0
end

local function attractToTarget(targetPos)
	local ePos, isVisible = Cam:WorldToViewportPoint(targetPos)
	if isVisible then
		local center = Cam.ViewportSize / 2
		local delta = Vector2.new(ePos.X, ePos.Y) - center
		mousemoverel(delta.X * attraction, delta.Y * attraction)
	end
end

local function getClosestPlayerInFOV(trg_part)
	local nearest = nil
	local last = math.huge
	local center = Cam.ViewportSize / 2

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= Players.LocalPlayer and isAlive(player) then
			local part = player.Character:FindFirstChild(trg_part)
			if part then
				local ePos, isVisible = Cam:WorldToViewportPoint(part.Position)
				local distance = (Vector2.new(ePos.X, ePos.Y) - center).Magnitude
				if distance < last and isVisible and distance < fov then
					last = distance
					nearest = player
				end
			end
		end
	end
	return nearest
end

RunService:BindToRenderStep("AimbotUpdate", Enum.RenderPriority.Camera.Value, function()
	FOVring.Position = Cam.ViewportSize / 2

	if currentTarget and not isAlive(currentTarget) then
		currentTarget = nil
	end

	local closest = currentTarget or getClosestPlayerInFOV("Head")
	if closest and closest.Character and closest.Character:FindFirstChild("Head") then
		currentTarget = closest
		attractToTarget(closest.Character.Head.Position)
	end
end)
