local module = {}

local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local LocalPlayer = Players.LocalPlayer
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local ContextActionService = cloneref(game:GetService("ContextActionService"))

local speeds = 1
local enable = false

local function togglefly()
	if enable == true then
		enable = false
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,true)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,true)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,true)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,true)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,true)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed,true)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics,true)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,true)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,true)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,true)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,true)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,true)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,true)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,true)
		LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
	else
		enable = true
		for i = 1, speeds do
			spawn(function()
				local hb = game:GetService("RunService").Heartbeat
				tpwalking = true
				local chr = Players.LocalPlayer.Character
				local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
				while tpwalking and hb:Wait() and chr and hum and hum.Parent do
					if hum.MoveDirection.Magnitude > 0 then
						chr:TranslateBy(hum.MoveDirection)
					end
				end
			end)
		end
		LocalPlayer.Character.Animate.Disabled = true
		local Char = Players.LocalPlayer.Character
		local hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
		for i,v in next, hum:GetPlayingAnimationTracks() do
			v:AdjustSpeed(0)
		end
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,false)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,false)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,false)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,false)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed,false)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics,false)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,false)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,false)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,false)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,false)
		LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,false)
		LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
	end
	if LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R6 then
		local torso = LocalPlayer.Character.Torso
		local ctrl = {f = 0, b = 0, l = 0, r = 0}
		local lastctrl = {f = 0, b = 0, l = 0, r = 0}
		local maxspeed = 50
		local speed = 0
		local bg = Instance.new("BodyGyro", torso)
		bg.P = 9e4
		bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
		bg.cframe = torso.CFrame
		local bv = Instance.new("BodyVelocity", torso)
		bv.velocity = Vector3.new(0,0.1,0)
		bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
		if enable == true then
			LocalPlayer.Character.Humanoid.PlatformStand = true
		end
		while enable == true or LocalPlayer.Character.Humanoid.Health == 0 do
			cloneref(game:GetService("RunService")).RenderStepped:Wait()
			if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
				speed = speed+.5+(speed/maxspeed)
				if speed > maxspeed then
					speed = maxspeed
				end
			elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
				speed = speed-1
				if speed < 0 then
					speed = 0
				end
			end
			if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
				bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f+ctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l+ctrl.r,(ctrl.f+ctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
				lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
			elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
				bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f+lastctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l+lastctrl.r,(lastctrl.f+lastctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
			else
				bv.velocity = Vector3.new(0,0,0)
			end
			bg.cframe = game.Workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*speed/maxspeed),0,0)
		end
		ctrl = {f = 0, b = 0, l = 0, r = 0}
		lastctrl = {f = 0, b = 0, l = 0, r = 0}
		speed = 0
		bg:Destroy()
		bv:Destroy()
		LocalPlayer.Character.Humanoid.PlatformStand = false
		LocalPlayer.Character.Animate.Disabled = false
		tpwalking = false
	else
		local UpperTorso = LocalPlayer.Character.UpperTorso
		local ctrl = {f = 0, b = 0, l = 0, r = 0}
		local lastctrl = {f = 0, b = 0, l = 0, r = 0}
		local maxspeed = 50
		local speed = 0
		local bg = Instance.new("BodyGyro", UpperTorso)
		bg.P = 9e4
		bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
		bg.cframe = UpperTorso.CFrame
		local bv = Instance.new("BodyVelocity", UpperTorso)
		bv.velocity = Vector3.new(0,0.1,0)
		bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
		if enable == true then
			LocalPlayer.Character.Humanoid.PlatformStand = true
		end
		while enable == true or LocalPlayer.Character.Humanoid.Health == 0 do
			wait()
			if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
				speed = speed+.5+(speed/maxspeed)
				if speed > maxspeed then
					speed = maxspeed
				end
			elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
				speed = speed-1
				if speed < 0 then
					speed = 0
				end
			end
			if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
				bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f+ctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l+ctrl.r,(ctrl.f+ctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
				lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
			elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
				bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f+lastctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l+lastctrl.r,(lastctrl.f+lastctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
			else
				bv.velocity = Vector3.new(0,0,0)
			end
			bg.cframe = game.Workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*speed/maxspeed),0,0)
		end
		ctrl = {f = 0, b = 0, l = 0, r = 0}
		lastctrl = {f = 0, b = 0, l = 0, r = 0}
		speed = 0
		bg:Destroy()
		bv:Destroy()
		LocalPlayer.Character.Humanoid.PlatformStand = false
		LocalPlayer.Character.Animate.Disabled = false
		tpwalking = false
	end
end

local Gui = Instance.new("ScreenGui")
Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
Gui.ResetOnSpawn = false

local window = Instance.new("Frame")
window.Size = UDim2.new(0, 190, 0, 57)
window.Position = UDim2.new(0.100320168, 0, 0.379746825, 0)
window.BackgroundColor3 = Color3.new(1, 1, 1)
window.BackgroundTransparency = 0.8
window.BorderSizePixel = 0
window.ZIndex = 10
window.Parent = Gui
window.Draggable = true

local uiCorner = Instance.new("UICorner", window)
uiCorner.CornerRadius = UDim.new(0, 3)

local titleBar = Instance.new("Frame", window)
titleBar.Size = UDim2.new(1, 0, 0, 20)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.new(0.9, 0.9, 0.9)
titleBar.BackgroundTransparency = 1
titleBar.BorderSizePixel = 0
titleBar.ZIndex = window.ZIndex + 1

local titleBarCorner = Instance.new("UICorner", titleBar)
titleBarCorner.CornerRadius = UDim.new(0, 3)

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size = UDim2.new(1, 0, 1, 0)
titleText.Text = "飞行V4"
titleText.TextColor3 = Color3.new(0, 0, 0)
titleText.TextSize = 14
titleText.BackgroundTransparency = 1
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Position = UDim2.new(0.05, 0, 0, 0)

local flytogglebutton = Instance.new("TextButton", window)
flytogglebutton.Size = UDim2.new(0, 59, 0, 25)
flytogglebutton.Text = "飞行(关)"
flytogglebutton.TextColor3 = Color3.new(0, 0, 0)
flytogglebutton.TextSize = 14
flytogglebutton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
flytogglebutton.BorderSizePixel = 0
flytogglebutton.Position = UDim2.new(0.05, 0, 0.45, 0)

local speedText = Instance.new("TextLabel", window)
speedText.Size = UDim2.new(0, 39, 0, 25)
speedText.Text = speeds
speedText.TextColor3 = Color3.new(0, 0, 0)
speedText.TextSize = 14
speedText.Font = Enum.Font.GothamBold
speedText.BorderSizePixel = 0
speedText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
speedText.Position = UDim2.new(0.395, 0, 0.45, 0)

local speedup = Instance.new("TextButton", window)
speedup.Size = UDim2.new(0, 29, 0, 25)
speedup.Text = "+"
speedup.TextColor3 = Color3.new(0, 0, 0)
speedup.TextSize = 14
speedup.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
speedup.BorderSizePixel = 0
speedup.Position = UDim2.new(0.63, 0, 0.45, 0)

local speeddown = Instance.new("TextButton", window)
speeddown.Size = UDim2.new(0, 29, 0, 25)
speeddown.Text = "-"
speeddown.TextColor3 = Color3.new(0, 0, 0)
speeddown.TextSize = 14
speeddown.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
speeddown.BorderSizePixel = 0
speeddown.Position = UDim2.new(0.8, 0, 0.45, 0)

local isDragging = false
local dragStartPos
local windowStartPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
        windowStartPos = window.Position
    end
end)

titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartPos
        window.Position = UDim2.new(
            windowStartPos.X.Scale,
            windowStartPos.X.Offset + delta.X,
            windowStartPos.Y.Scale,
            windowStartPos.Y.Offset + delta.Y
        )
    end
end)

local connection

local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        flytogglebutton.Text = enable and "飞行(关)" or "飞行(开)"
	    togglefly()
	    return Enum.ContextActionResult.Sink
    end
end

connection = UserInputService.InputBegan:Connect(onInputBegan)

flytogglebutton.MouseButton1Click:Connect(function()
    flytogglebutton.Text = enable and "飞行(关)" or "飞行(开)"
    togglefly()
end)

speedup.MouseButton1Click:Connect(function()
	speeds = speeds + 1
	speedText.Text = speeds
	if enable == true then
		tpwalking = false
		for i = 1, speeds do
			spawn(function()
				local hb = cloneref(game:GetService("RunService")).Heartbeat
				tpwalking = true
				local chr = Players.LocalPlayer.Character
				local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
				while tpwalking and hb:Wait() and chr and hum and hum.Parent do
					if hum.MoveDirection.Magnitude > 0 then
						chr:TranslateBy(hum.MoveDirection)
					end
				end
			end)
		end
	end
end)

speeddown.MouseButton1Click:Connect(function()
	if speeds == 1 then
		speedText.Text = '不能小于1'
		wait(1)
		speedText.Text = speeds
	else
		speeds = speeds - 1
		speedText.Text = speeds
		if enable == true then
			tpwalking = false
			for i = 1, speeds do
				spawn(function()
					local hb = cloneref(game:GetService("RunService")).Heartbeat
					tpwalking = true
					local chr = Players.LocalPlayer.Character
					local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
					while tpwalking and hb:Wait() and chr and hum and hum.Parent do
						if hum.MoveDirection.Magnitude > 0 then
							chr:TranslateBy(hum.MoveDirection)
						end
					end
				end)
			end
		end
	end
end)

function module.enable()
end

function module.disable()
end

function module.unload()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	Gui:Destroy()
end

return module