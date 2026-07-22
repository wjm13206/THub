--!native
--!optimize 2

-- AimBotModule.lua
-- 纯净瞄准模块，无UI，无ESP，无配置系统，单例模式

local AimBotModule = {}

-- 内部状态
local _enabled = false
local _teamCheck = false
local _wallCheck = false
local _showFov = true -- 默认开启
local _fov = 360 -- 固定大小
local _aimPart = "Head"
local _smoothing = 30 -- 默认30 (实际0.3)
local _prediction = false
local _predictionAmount = 100 -- 默认100 (实际1.0)
local _stickyAim = false
local _useMouse = true
local _mouseBind = "MouseButton2"
local _keybind = Enum.KeyCode.E

-- 运行时状态
local _isAimKeyDown = false
local _target = nil
local _cameraTween = nil
local _fovCircle = nil
local _connections = {}

-- 服务引用
local cloneref = cloneref or clonereference or function(obj) return obj end
local _players = cloneref(game:GetService("Players"))
local _localPlayer = _players.LocalPlayer
local _currentCamera = cloneref(game.Workspace.CurrentCamera)
local _tweenService = cloneref(game:GetService("TweenService"))
local _userInputService = cloneref(game:GetService("UserInputService"))
local _runService = cloneref(game:GetService("RunService"))

-- 创建FOV圆圈
local function _createFovCircle()
	local coreGui = cloneref(game:FindFirstChild("CoreGui")) or _localPlayer:WaitForChild("PlayerGui")
	
	local fovGui = Instance.new("ScreenGui")
	fovGui.Name = "AimBotFOV"
	fovGui.Parent = coreGui
	fovGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	fovGui.ResetOnSpawn = false
	fovGui.Enabled = false
	pcall(function() syn.protect_gui(fovGui) end)
	
	local fovFrame = Instance.new("Frame")
	fovFrame.Name = "FOVFrame"
	fovFrame.Parent = fovGui
	fovFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	fovFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	fovFrame.BorderSizePixel = 0
	fovFrame.BackgroundTransparency = 1
	fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	fovFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	fovFrame.Size = UDim2.new(0, _fov, 0, _fov)
	
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(1, 0)
	uiCorner.Parent = fovFrame
	
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(100, 0, 100)
	uiStroke.Parent = fovFrame
	uiStroke.Thickness = 1
	uiStroke.ApplyStrokeMode = "Border"
	
	_fovCircle = {
		Gui = fovGui,
		Frame = fovFrame,
		Stroke = uiStroke
	}
end

-- 检查玩家是否存活
local function _isAlive(player)
	if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
		return true
	end
	return false
end

-- 获取队伍
local function _getTeam(player)
	if not _localPlayer.Neutral then
		return game.Teams[player.Team.Name]
	end
	return true
end

-- 可见性检查
local function _isVisible(position, character)
	if not _wallCheck then
		return true
	end
	
	local parts = {_currentCamera, _localPlayer.Character}
	if character then
		table.insert(parts, character)
	end
	
	return #_currentCamera:GetPartsObscuringTarget({position}, parts) == 0
end

-- 获取离鼠标最近的目标
local function _getClosestToMouse()
	local aimFov = _fov
	local targetPos = nil
	local mouseLocation = _userInputService:GetMouseLocation()
	
	for _, player in pairs(_players:GetPlayers()) do
		if player ~= _localPlayer then
			if not _teamCheck or _getTeam(player) ~= _getTeam(_localPlayer) then
				if _isAlive(player) then
					local targetPart = player.Character:FindFirstChild(_aimPart)
					if targetPart then
						local screenPos, onScreen = _currentCamera:WorldToViewportPoint(targetPart.Position)
						local screenPos2D = Vector2.new(screenPos.X, screenPos.Y)
						local magnitude = (screenPos2D - mouseLocation).Magnitude
						
						if onScreen and magnitude < aimFov and _isVisible(targetPart.Position, player.Character) then
							aimFov = magnitude
							targetPos = player
						end
					end
				end
			end
		end
	end
	
	return targetPos
end

-- 设置输入监听
local function _setupInputListeners()
	-- 键盘输入
	local keyBeganConn = _userInputService.InputBegan:Connect(function(input)
		if input.KeyCode == _keybind and not _useMouse then
			_target = _getClosestToMouse()
			_isAimKeyDown = true
		end
	end)
	
	local keyEndedConn = _userInputService.InputEnded:Connect(function(input)
		if input.KeyCode == _keybind and not _useMouse then
			_target = nil
			_isAimKeyDown = false
			if _cameraTween then
				_cameraTween:Cancel()
				_cameraTween = nil
			end
		end
	end)
	
	-- 鼠标输入
	local mouse = _localPlayer:GetMouse()
	
	local mouse1DownConn = mouse.Button1Down:Connect(function()
		if _mouseBind == "MouseButton1" and _useMouse then
			if _isAimKeyDown then
				_target = nil
				_isAimKeyDown = false
				if _cameraTween then
					_cameraTween:Cancel()
					_cameraTween = nil
				end
			else
				_target = _getClosestToMouse()
				_isAimKeyDown = true
			end
		end
	end)
	
	local mouse1UpConn = mouse.Button1Up:Connect(function()
		if _mouseBind == "MouseButton1" and _useMouse then
			_target = nil
			_isAimKeyDown = false
			if _cameraTween then
				_cameraTween:Cancel()
				_cameraTween = nil
			end
		end
	end)
	
	local mouse2DownConn = mouse.Button2Down:Connect(function()
		if _mouseBind == "MouseButton2" and _useMouse then
			_target = _getClosestToMouse()
			_isAimKeyDown = true
		end
	end)
	
	local mouse2UpConn = mouse.Button2Up:Connect(function()
		if _mouseBind == "MouseButton2" and _useMouse then
			_target = nil
			_isAimKeyDown = false
			if _cameraTween then
				_cameraTween:Cancel()
				_cameraTween = nil
			end
		end
	end)
	
	table.insert(_connections, keyBeganConn)
	table.insert(_connections, keyEndedConn)
	table.insert(_connections, mouse1DownConn)
	table.insert(_connections, mouse1UpConn)
	table.insert(_connections, mouse2DownConn)
	table.insert(_connections, mouse2UpConn)
end

-- 设置主循环
local function _setupMainLoop()
	local heartbeatConn = _runService.Heartbeat:Connect(function()
		-- 更新FOV圆圈
		if _enabled and _showFov then
			_fovCircle.Gui.Enabled = true
			_fovCircle.Stroke.Enabled = true
			local mousePos = _userInputService:GetMouseLocation()
			_fovCircle.Frame.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y - 36)
			_fovCircle.Frame.Size = UDim2.fromOffset(_fov * 1.5, _fov * 1.5)
		else
			_fovCircle.Gui.Enabled = false
			_fovCircle.Stroke.Enabled = false
		end
		
		-- 瞄准逻辑
		if _enabled and _isAimKeyDown then
			if _stickyAim then
				if _target then
					if not _isAlive(_target) then
						_target = _getClosestToMouse()
					end
					
					if _target and _isAlive(_target) then
						local targetPart = _target.Character:FindFirstChild(_aimPart)
						if targetPart then
							local targetPos = targetPart.Position
							
							if _prediction then
								local ping = _localPlayer:GetNetworkPing()
								targetPos = targetPos + targetPart.Velocity * (ping * (_predictionAmount / 100))
							end
							
							_cameraTween = _tweenService:Create(
								_currentCamera,
								TweenInfo.new(_smoothing / 100, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
								{CFrame = CFrame.new(_currentCamera.CFrame.Position, targetPos)}
							)
							_cameraTween:Play()
						end
					end
				end
			else
				local target = _getClosestToMouse()
				if target and _isAlive(target) then
					local targetPart = target.Character:FindFirstChild(_aimPart)
					if targetPart then
						local targetPos = targetPart.Position
						
						if _prediction then
							local ping = _localPlayer:GetNetworkPing()
							targetPos = targetPos + targetPart.Velocity * (ping * (_predictionAmount / 100))
						end
						
						_cameraTween = _tweenService:Create(
							_currentCamera,
							TweenInfo.new(_smoothing / 100, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
							{CFrame = CFrame.new(_currentCamera.CFrame.Position, targetPos)}
						)
						_cameraTween:Play()
					end
				elseif _cameraTween then
					_cameraTween:Cancel()
					_cameraTween = nil
				end
			end
		end
	end)
	
	table.insert(_connections, heartbeatConn)
end

-- ==================== 公开API ====================

function AimBotModule.enable()
	_enabled = true
end

function AimBotModule.disable()
	_enabled = false
	_isAimKeyDown = false
	_target = nil
	if _cameraTween then
		_cameraTween:Cancel()
		_cameraTween = nil
	end
end

function AimBotModule.SetTeamCheck(enabled)
	_teamCheck = enabled
end

function AimBotModule.GetTeamCheck()
	return _teamCheck
end

function AimBotModule.SetWallCheck(enabled)
	_wallCheck = enabled
end

function AimBotModule.GetWallCheck()
	return _wallCheck
end

function AimBotModule.SetHitScan(partName)
	_aimPart = partName
end

function AimBotModule.GetHitScan()
	return _aimPart
end

function AimBotModule.SetKey(keyCode)
	if typeof(keyCode) == "EnumItem" then
		_keybind = keyCode
	end
end

function AimBotModule.GetKey()
	return _keybind
end

function AimBotModule.SetMouseBind(mouseButton)
	if mouseButton == "MouseButton1" or mouseButton == "MouseButton2" then
		_mouseBind = mouseButton
	end
end

function AimBotModule.GetMouseBind()
	return _mouseBind
end

function AimBotModule.SetUseMouse(enabled)
	_useMouse = enabled
end

function AimBotModule.GetUseMouse()
	return _useMouse
end

function AimBotModule.SetStickyAim(enabled)
	_stickyAim = enabled
end

function AimBotModule.SetSmoothing(value)
	_smoothing = math.clamp(value, 0, 50)
end

function AimBotModule.GetSmoothing()
	return _smoothing
end

function AimBotModule.SetPrediction(enabled)
	_prediction = enabled
end

function AimBotModule.SetPredictionAmount(value)
	_predictionAmount = math.max(0, value)
end

function AimBotModule.GetPredictionAmount()
	return _predictionAmount
end

function AimBotModule.unload()
	_enabled = false
	_isAimKeyDown = false
	_target = nil
	
	if _cameraTween then
		_cameraTween:Cancel()
		_cameraTween = nil
	end
	
	for _, conn in pairs(_connections) do
		conn:Disconnect()
	end
	_connections = {}
	
	if _fovCircle then
		if _fovCircle.Gui then
			_fovCircle.Gui:Destroy()
		end
		_fovCircle = nil
	end
	
	_players = nil
	_localPlayer = nil
	_currentCamera = nil
	_tweenService = nil
	_userInputService = nil
	_runService = nil
end

-- 初始化
_createFovCircle()
_setupInputListeners()
_setupMainLoop()

return AimBotModule
