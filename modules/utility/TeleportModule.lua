-- 模块脚本，建议放在 ReplicatedStorage 或 StarterPlayerScripts 中
local teleportModule = {}

-- 内部变量
local cloneref = cloneref or clonereference or function(obj) return obj end
local userInputService = cloneref(game:GetService("UserInputService"))
local players = cloneref(game:GetService("Players"))
local localPlayer = players.LocalPlayer
local mouse = localPlayer:GetMouse()

local ctrlHeld = false
local inputBeganConn = nil
local inputEndedConn = nil
local mouseButton1Conn = nil

-- 清理所有连接
local function cleanConnections()
	if inputBeganConn then
		inputBeganConn:Disconnect()
		inputBeganConn = nil
	end
	if inputEndedConn then
		inputEndedConn:Disconnect()
		inputEndedConn = nil
	end
	if mouseButton1Conn then
		mouseButton1Conn:Disconnect()
		mouseButton1Conn = nil
	end
end

-- 开启功能
function teleportModule.enable()
	-- 如果已开启则先关闭
	if mouseButton1Conn then
		teleportModule.disable()
	end

	-- 检测 Ctrl 按下
	inputBeganConn = userInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
			ctrlHeld = true
		end
	end)

	-- 检测 Ctrl 松开
	inputEndedConn = userInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
			ctrlHeld = false
		end
	end)

	-- 检测鼠标点击
	mouseButton1Conn = mouse.Button1Down:Connect(function()
		if not ctrlHeld then return end
		
		local character = localPlayer.Character
		if not character then return end
		
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then return end

		local hitPos = mouse.Hit
		if hitPos then
			local targetPos = hitPos.Position + Vector3.new(0, 2.5, 0)
			humanoidRootPart.CFrame = CFrame.new(targetPos)
		end
	end)
end

-- 关闭功能
function teleportModule.disable()
	ctrlHeld = false
	cleanConnections()
end

-- 卸载模块
function teleportModule.unload()
	teleportModule.disable()
	-- 清空模块方法
	for k in pairs(teleportModule) do
		teleportModule[k] = nil
	end
end

return teleportModule