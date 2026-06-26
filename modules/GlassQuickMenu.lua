--[[
	GlassQuickMenu Module - 玻璃快捷菜单
	独立模块，通过 return 暴露接口
]]

local GlassQuickMenu = {}
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local HttpService = cloneref(game:GetService("HttpService"))

local player = Players.LocalPlayer
local DEPTH = 5
local FADE_TIME = 0.15
local RIGHT_OFFSET = 250

-- 存储注册的控件
local registeredControls = {}  -- {name = "xxx", text = "xxx", type = "button"|"toggle", callback = fn, toggleState = bool, toggleRef = object}
local quickBindings = {}  -- {[1] = {name = "xxx"}, [2] = {name = nil}, ...} 索引1-10

local allButtonData = {}  -- 10个按钮的组件引用
local isShowing = false
local bindKey = Enum.KeyCode.R

-- 获取存储文件夹
local function getParentFolder()
	local folder = workspace:FindFirstChild("GlassQuickMenuObjects")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "GlassQuickMenuObjects"
		folder.Parent = workspace
	end
	return folder
end

-- 获取绑定目标
local function getBinding(index)
	return quickBindings[index]
end

-- 设置绑定
local function setBinding(index, name, controlType)
	if index < 1 or index > 10 then return end
	
	if name then
		quickBindings[index] = {name = name, type = controlType}
	else
		quickBindings[index] = nil
	end
	
	-- 更新按钮文本
	if allButtonData[index] then
		allButtonData[index].updateText()
	end
end

-- 清除所有绑定
local function clearAllBindings()
	for i = 1, 10 do
		quickBindings[i] = nil
	end
	for _, data in ipairs(allButtonData) do
		data.updateText()
	end
end

-- 获取当前绑定列表
local function getBindings()
	return quickBindings
end

-- 获取注册的控件列表
local function getRegisteredControls()
	return registeredControls
end

-- 创建单个玻璃按钮
local function createGlassButton(index)
	local buttonConfigs = {
		"按钮 1", "按钮 2", "按钮 3", "按钮 4", "按钮 5",
		"按钮 6", "按钮 7", "按钮 8", "按钮 9", "按钮 10"
	}
	local colors = {
		Color3.fromRGB(200, 220, 255), Color3.fromRGB(200, 255, 220),
		Color3.fromRGB(255, 220, 200), Color3.fromRGB(220, 200, 255),
		Color3.fromRGB(255, 255, 200), Color3.fromRGB(200, 255, 255),
		Color3.fromRGB(255, 200, 255), Color3.fromRGB(220, 255, 200),
		Color3.fromRGB(255, 220, 220), Color3.fromRGB(220, 220, 255),
	}
	
	local BUTTON_WIDTH = 200
	local BUTTON_HEIGHT = 45
	local BUTTON_SPACING = 8
	local totalHeight = 10 * BUTTON_HEIGHT + 9 * BUTTON_SPACING
	local firstButtonY = -(totalHeight / 2) + (BUTTON_HEIGHT / 2)
	local yOffset = firstButtonY + (index - 1) * (BUTTON_HEIGHT + BUTTON_SPACING)
	
	local screenGui = player:WaitForChild("PlayerGui"):FindFirstChild("GlassQuickMenuGUI")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "GlassQuickMenuGUI"
		screenGui.IgnoreGuiInset = true
		screenGui.Parent = player:WaitForChild("PlayerGui")
	end
	
	-- UI按钮
	local button = Instance.new("TextButton")
	button.Name = "QuickButton_" .. index
	button.Size = UDim2.new(0, BUTTON_WIDTH, 0, BUTTON_HEIGHT)
	button.Position = UDim2.new(0.5, RIGHT_OFFSET, 0.5, yOffset)
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.Text = "空"
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextTransparency = 1
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.AutoButtonColor = false
	button.Active = false
	button.Parent = screenGui
	
	local textStroke = Instance.new("UIStroke")
	textStroke.Color = Color3.fromRGB(0, 0, 0)
	textStroke.Transparency = 1
	textStroke.Thickness = 1.5
	textStroke.Parent = button
	
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 10)
	uiCorner.Parent = button
	
	-- 3D玻璃面板
	local model = Instance.new("Model")
	model.Name = "GlassModel_" .. index
	model.Parent = nil
	
	local part = Instance.new("Part")
	part.Name = "GlassPanel"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Glass
	part.Transparency = 1
	part.Color = colors[index]
	part.Size = Vector3.new(0.05, 1, 1)
	part.Parent = model
	
	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.OutlineTransparency = 1
	highlight.Adornee = part
	highlight.Parent = part
	
	local showTransparency = 0.55
	local showOutlineTransparency = 0.4
	local isAnimating = false
	
	-- 更新按钮文本
	local function updateText()
		local binding = getBinding(index)
		if binding and binding.name then
			local displayText = binding.name
			if binding.type == "toggle" then
				-- 查找toggle状态
				for _, ctrl in ipairs(registeredControls) do
					if ctrl.name == binding.name and ctrl.type == "toggle" then
						local stateText = ctrl.toggleState and "开" or "关"
						displayText = binding.name .. "(" .. stateText .. ")"
						break
					end
				end
			end
			button.Text = displayText
		else
			button.Text = "空"
		end
	end
	
	-- 位置更新
	local function updatePosition()
		if not model.Parent then return end
		
		local camera = workspace.CurrentCamera
		if not camera then return end
		
		local absPos = button.AbsolutePosition
		local absSize = button.AbsoluteSize
		
		if absSize.X <= 0 or absSize.Y <= 0 then return end
		
		local centerX = absPos.X + absSize.X / 2
		local centerY = absPos.Y + absSize.Y / 2
		
		local centerRay = camera:ScreenPointToRay(centerX, centerY, DEPTH)
		local worldPos = centerRay.Origin + centerRay.Direction * DEPTH
		
		local cameraForward = camera.CFrame.LookVector
		local planeNormal = cameraForward
		local planePoint = worldPos
		
		local function screenToPlane(screenPos)
			local ray = camera:ScreenPointToRay(screenPos.X, screenPos.Y)
			local rayOrigin = ray.Origin
			local rayDir = ray.Direction
			
			local denom = rayDir:Dot(planeNormal)
			if math.abs(denom) < 0.0001 then
				return rayOrigin + rayDir * DEPTH
			end
			
			local t = (planePoint - rayOrigin):Dot(planeNormal) / denom
			if t < 0 then t = DEPTH end
			return rayOrigin + rayDir * t
		end
		
		local topLeft = Vector2.new(absPos.X, absPos.Y)
		local topRight = Vector2.new(absPos.X + absSize.X, absPos.Y)
		local bottomLeft = Vector2.new(absPos.X, absPos.Y + absSize.Y)
		local bottomRight = Vector2.new(absPos.X + absSize.X, absPos.Y + absSize.Y)
		
		local worldTopLeft = screenToPlane(topLeft)
		local worldTopRight = screenToPlane(topRight)
		local worldBottomLeft = screenToPlane(bottomLeft)
		local worldBottomRight = screenToPlane(bottomRight)
		
		local worldWidth = (worldTopRight - worldTopLeft).Magnitude
		local worldHeight = (worldBottomLeft - worldTopLeft).Magnitude
		
		part.Size = Vector3.new(0.05, worldHeight, worldWidth)
		local cameraCF = camera.CFrame
		local rotation = CFrame.Angles(0, math.rad(90), 0)
		part.CFrame = CFrame.new(worldPos) * cameraCF.Rotation * rotation
	end
	
	local renderName = "GlassQMBtn_" .. HttpService:GenerateGUID(false)
	RunService:BindToRenderStep(renderName, Enum.RenderPriority.Camera.Value + 1, updatePosition)
	
	-- 显示
	local function show()
		isAnimating = true
		button.Active = true
		model.Parent = getParentFolder()
		part.Transparency = 1
		highlight.OutlineTransparency = 1
		
		local tweenInfo = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(button, tweenInfo, {TextTransparency = 0}):Play()
		TweenService:Create(textStroke, tweenInfo, {Transparency = 0.5}):Play()
		TweenService:Create(part, tweenInfo, {Transparency = showTransparency}):Play()
		local ht = TweenService:Create(highlight, tweenInfo, {OutlineTransparency = showOutlineTransparency})
		ht:Play()
		ht.Completed:Connect(function() isAnimating = false end)
	end
	
	-- 隐藏
	local function hide()
		isAnimating = true
		button.Active = false
		
		local tweenInfo = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(button, tweenInfo, {TextTransparency = 1}):Play()
		TweenService:Create(textStroke, tweenInfo, {Transparency = 1}):Play()
		TweenService:Create(part, tweenInfo, {Transparency = 1}):Play()
		local ht = TweenService:Create(highlight, tweenInfo, {OutlineTransparency = 1})
		ht:Play()
		ht.Completed:Connect(function()
			model.Parent = nil
			isAnimating = false
		end)
	end
	
	-- 点击执行
	button.MouseButton1Click:Connect(function()
		if not button.Active then return end
		local binding = getBinding(index)
		if binding then
			for _, ctrl in ipairs(registeredControls) do
				if ctrl.name == binding.name then
					if ctrl.type == "button" and ctrl.callback then
						pcall(ctrl.callback)
					elseif ctrl.type == "toggle" and ctrl.toggleRef then
						-- 切换toggle状态
						ctrl.toggleRef:SetValue(not ctrl.toggleState)
					end
					break
				end
			end
		end
	end)
	
	-- 悬停效果
	button.MouseEnter:Connect(function()
		if button.Active and model.Parent and not isAnimating then
			local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(part, tweenInfo, {Transparency = showTransparency - 0.2}):Play()
			TweenService:Create(highlight, tweenInfo, {OutlineTransparency = showOutlineTransparency - 0.3}):Play()
		end
	end)
	
	button.MouseLeave:Connect(function()
		if button.Active and model.Parent and not isAnimating then
			local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(part, tweenInfo, {Transparency = showTransparency}):Play()
			TweenService:Create(highlight, tweenInfo, {OutlineTransparency = showOutlineTransparency}):Play()
		end
	end)
	
	-- 清理
	button.AncestryChanged:Connect(function(_, newParent)
		if not newParent then
			RunService:UnbindFromRenderStep(renderName)
			model:Destroy()
		end
	end)
	
	return {
		button = button,
		model = model,
		show = show,
		hide = hide,
		updateText = updateText,
	}
end

-- 按键监听设置
local inputBeganConn = nil
local inputEndedConn = nil

local function setupKeyListener()
	if inputBeganConn then inputBeganConn:Disconnect() end
	if inputEndedConn then inputEndedConn:Disconnect() end
	
	inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == bindKey then
			if not isShowing then
				isShowing = true
				for _, data in ipairs(allButtonData) do
					data.show()
				end
			end
		end
	end)
	
	inputEndedConn = UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.KeyCode == bindKey then
			if isShowing then
				isShowing = false
				for _, data in ipairs(allButtonData) do
					data.hide()
				end
			end
		end
	end)
end

-- ============ 公共接口 ============

-- 注册按钮
function GlassQuickMenu:RegisterButton(name, text, callback)
	table.insert(registeredControls, {
		name = name,
		text = text,
		type = "button",
		callback = callback,
	})
end

-- 注册开关
function GlassQuickMenu:RegisterToggle(name, text, callback, defaultState, toggleRef)
	-- toggleRef 需要有 :SetValue(bool) 和 :GetValue() 方法
	local state = defaultState or false
	local ctrl = {
		name = name,
		text = text,
		type = "toggle",
		callback = callback,
		toggleState = state,
		toggleRef = toggleRef,
	}
	table.insert(registeredControls, ctrl)
	
	-- 监听toggle变化
	if toggleRef and toggleRef.ValueChanged then
		toggleRef.ValueChanged:Connect(function(newValue)
			ctrl.toggleState = newValue
			-- 更新所有绑定了这个toggle的快捷按钮文本
			for i = 1, 10 do
				local binding = quickBindings[i]
				if binding and binding.name == name then
					if allButtonData[i] then
						allButtonData[i].updateText()
					end
				end
			end
		end)
	end
	
	return ctrl
end

-- 设置按键
function GlassQuickMenu:SetKey(keyEnum)
	bindKey = keyEnum
	setupKeyListener()
end

-- 获取当前按键
function GlassQuickMenu:GetKey()
	return bindKey
end

-- 获取所有注册控件
function GlassQuickMenu:GetRegisteredControls()
	return registeredControls
end

-- 设置快捷按钮绑定
function GlassQuickMenu:SetBinding(buttonIndex, controlName)
	if not controlName or controlName == "" then
		setBinding(buttonIndex, nil)
		return
	end
	
	for _, ctrl in ipairs(registeredControls) do
		if ctrl.name == controlName then
			setBinding(buttonIndex, ctrl.name, ctrl.type)
			return
		end
	end
end

-- 清除绑定
function GlassQuickMenu:ClearBinding(buttonIndex)
	setBinding(buttonIndex, nil)
end

-- 获取绑定
function GlassQuickMenu:GetBinding(buttonIndex)
	return quickBindings[buttonIndex]
end

-- 全局刷新所有按钮文本（当toggle状态变化时调用）
function GlassQuickMenu:RefreshAllTexts()
	for i = 1, 10 do
		if allButtonData[i] then
			allButtonData[i].updateText()
		end
	end
end

-- 初始化
function GlassQuickMenu:Init()
	-- 创建10个按钮
	for i = 1, 10 do
		allButtonData[i] = createGlassButton(i)
	end
	
	-- 初始隐藏
	for _, data in ipairs(allButtonData) do
		data.updateText()
	end
	
	-- 设置按键监听
	setupKeyListener()
	
	print("GlassQuickMenu: 初始化完成，按键: " .. tostring(bindKey))
end

-- 销毁
function GlassQuickMenu:Destroy()
	if inputBeganConn then inputBeganConn:Disconnect() end
	if inputEndedConn then inputEndedConn:Disconnect() end
	
	for _, data in ipairs(allButtonData) do
		if data.model then data.model:Destroy() end
		if data.button then data.button:Destroy() end
	end
	
	allButtonData = {}
	registeredControls = {}
	quickBindings = {}
	
	local gui = player:WaitForChild("PlayerGui"):FindFirstChild("GlassQuickMenuGUI")
	if gui then gui:Destroy() end
	
	local folder = workspace:FindFirstChild("GlassQuickMenuObjects")
	if folder then folder:Destroy() end
	
	print("GlassQuickMenu: 已销毁")
end

return GlassQuickMenu