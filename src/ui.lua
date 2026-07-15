--!native
--!optimize 2

--=============================================================================================

local mainWindow = ChronixUI:CreateWindow({
    Name = "THubv3",
    Size = data["basicdata"]["window"]["windowSize"],

    CloseCallback = function()
        unloadTHub()
    end
})

-- Helper functions to reduce duplicate code
local function sliderLock(tab, sliderLabel, min, max, default, sliderCb, lockLabel, lockCb)
    tab:AddSlider({ Label = sliderLabel, Min = min, Max = max, Default = default, Callback = sliderCb })
    tab:AddToggle({ Label = lockLabel, Default = false, Callback = lockCb })
end

local function enableToggle(tab, label, onFn, offFn)
    tab:AddToggle({ Label = label, Default = false, Callback = function(v) if v then onFn() else offFn() end end })
end

local function safeGetKeyCode(key)
    if typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
        return key
    end
    if type(key) ~= "string" or key == "" then
        return nil
    end
    local ok, keyCode = pcall(function()
        return Enum.KeyCode[key]
    end)
    if ok then
        return keyCode
    end
    return nil
end

local function settingsKeybindInput(tab, bindLabel, defaultKey, setKey, inputLabel, defaultVal, setVal)
    tab:AddKeybind({ Label = bindLabel, Default = defaultKey, Callback = function(key)
        if key then
            local nk = safeGetKeyCode(key)
            if nk then
                setKey(nk)
            end
        end
    end })
    tab:AddInput({ Label = inputLabel, Placeholder = "", Default = defaultVal, Callback = function(text)
        local n = tonumber(text); if n then setVal(n) end
    end })
end

-- ===== 基础设置 Tab =====
local basicTab = mainWindow:CreateTab({ Name = "基础设置", HasIcon = true, IconName = "pencil-ruler" })
basicTab:AddTitle("基础数据修改")
sliderLock(basicTab, "玩家移速", 0, 1000, data["basicdata"]["player"]["speed"],
    function(v) LocalPlayer.Character.Humanoid.WalkSpeed = v; data["basicdata"]["player"]["speed"] = v end,
    "锁定玩家移速", function(v) data["basicdata"]["player"]["islockspeed"] = v; requestSpoofHooks() end)
sliderLock(basicTab, "跳跃力量", 0, 1000, data["basicdata"]["player"]["jump"],
    function(v) LocalPlayer.Character.Humanoid.JumpPower = v; data["basicdata"]["player"]["jump"] = v end,
    "锁定跳跃力量", function(v) data["basicdata"]["player"]["islockjump"] = v; requestSpoofHooks() end)
sliderLock(basicTab, "最大血量", 0, 1000, data["basicdata"]["player"]["maxhealth"],
    function(v) LocalPlayer.Character.Humanoid.MaxHealth = v; data["basicdata"]["player"]["maxhealth"] = v end,
    "锁定最大血量", function(v) if v then enableLockMaxHealth() else disableLockMaxHealth() end end)
sliderLock(basicTab, "当前血量", 0, 1000, data["basicdata"]["player"]["health"],
    function(v) LocalPlayer.Character.Humanoid.Health = v; data["basicdata"]["player"]["health"] = v end,
    "锁定当前血量", function(v) if v then enableLockHealth() else disableLockHealth() end end)
sliderLock(basicTab, "世界重力", 0, 1000, data["basicdata"]["player"]["gravity"],
    function(v) Workspace.Gravity = v; data["basicdata"]["player"]["gravity"] = v end,
    "锁定世界重力", function(v) if v then enableLockGravity() else disableLockGravity() end end)

-- ===== 工具 Tab =====
local ToolsTab = mainWindow:CreateTab({ Name = "工具", HasIcon = true, IconName = "wrench" })
ToolsTab:AddTitle("各种实用工具")
ToolsTab:AddToggle({
    Label = "防挂机",
    Default = true,
    Callback = function(v) if v then enableAntiAFK() else disableAntiAFK() end end
})
ToolsTab:AddToggle({
    Label = "保留THub - 传送后自动执行",
    Default = false,
    Callback = function(v) if v then enableKeepTHub() else disableKeepTHub() end end
})
enableToggle(ToolsTab, "飞行", function()
    FlyModule.enable()
    ChronixUI:Notify({ Title = "提示", Content = "按住Ctrl+" .. FlyModule.getbindkey().Name .. "开关飞行状态", Type = "info", Duration = 5 })
end, function() FlyModule.disable() end)
enableToggle(ToolsTab, "帧飞行", function()
    CframeFly.enable()
    ChronixUI:Notify({ Title = "提示", Content = "按住Ctrl+" .. CframeFly.getbindkey().Name .. "开关飞行状态", Type = "info", Duration = 5 })
end, function() CframeFly.disable() end)
enableToggle(ToolsTab, "载具飞行", function()
    VehicleFly.enable()
    ChronixUI:Notify({ Title = "提示", Content = "按住Ctrl+" .. VehicleFly.getbindkey().Name .. "开关飞行状态", Type = "info", Duration = 5 })
end, function() VehicleFly.disable() end)
enableToggle(ToolsTab, "点击传送", function()
    TeleportModule.enable()
    ChronixUI:Notify({ Title = "提示", Content = "按住Ctrl并点击来传送", Type = "info", Duration = 5 })
end, function() TeleportModule.disable() end)
enableToggle(ToolsTab, "玩家透视", function() PlayerESP.enable() end, function() PlayerESP.disable() end)
enableToggle(ToolsTab, "NPC透视", function() data["basicdata"]["releasetools"]["npc"]:enable() end, function() data["basicdata"]["releasetools"]["npc"]:disable() end)
enableToggle(ToolsTab, "TPWalk", function() tpWalk:Enabled(true) end, function() tpWalk:Enabled(false) end)
enableToggle(ToolsTab, "鼠标解锁", function()
    MouseUnlockModule.Enable()
    ChronixUI:Notify({ Title = "提示", Content = "按下K+L组合键开关解锁鼠标", Type = "info", Duration = 5 })
end, function() MouseUnlockModule.Disable() end)
enableToggle(ToolsTab, "锁定视角", function()
    LockCameraModule.enable()
    ChronixUI:Notify({ Title = "提示", Content = "按住" .. LockCameraModule.getBindKey().Name .. "键来锁定视角", Type = "info", Duration = 5 })
end, function() LockCameraModule.disable() end)
enableToggle(ToolsTab, "瞬间转向", function() SnapTurn.Enable() end, function() SnapTurn.Disable() end)
enableToggle(ToolsTab, "瞬间回头", function()
    SnapReverse.Enable()
    ChronixUI:Notify({ Title = "提示", Content = "按下" .. SnapReverse.GetKeyBind().Name .. "键来瞬间回头", Type = "info", Duration = 5 })
end, function() SnapReverse.Disable() end)
enableToggle(ToolsTab, "自动瞄准", function() AimBotModule.Enable() end, function() AimBotModule.Disable() end)
enableToggle(ToolsTab, "物品滚轮切换", function()
    ChronixUI:Notify({ Title = "提示", Content = "按住" .. ScrollSwitch:getbind().Name .. "键并滚动鼠标滚轮来切换物品", Type = "info", Duration = 5 })
    ScrollSwitch:enable()
end, function() ScrollSwitch:disable() end)
enableToggle(ToolsTab, "望远镜", function()
    data["basicdata"]["releasetools"]["zoom"]:Enable()
    ChronixUI:Notify({ Title = "提示", Content = "按住" .. tostring(data["basicdata"]["releasetools"]["zoom"]:GetBindKey()):gsub("^Enum%.%w+%.", "") .. "键放大", Type = "info", Duration = 5 })
end, function() data["basicdata"]["releasetools"]["zoom"]:Disable() end)
enableToggle(ToolsTab, "隐身", function() PlayerVisibleModule.enable() end, function() PlayerVisibleModule.disable() end)
enableToggle(ToolsTab, "查看落脚点", function() FootstepHighlighter.enable() end, function() FootstepHighlighter.disable() end)
enableToggle(ToolsTab, "落地特效", function() LandingEffect.enable() end, function() LandingEffect.disable() end)
ToolsTab:AddToggle({
    Label = "夜视",
    Default = false,
    Callback = function(v) if v then enableNightVision() else disableNightVision() end end
})
ToolsTab:AddToggle({
    Label = "超级夜视",
    Default = false,
    Callback = function(v) if v then enableSuperNightVision() else disableSuperNightVision() end end
})
enableToggle(ToolsTab, "阻挡射线检测", function() AntiLookBlocker.enable() end, function() AntiLookBlocker.disable() end)
ToolsTab:AddToggle({
    Label = "随身灯笼",
    Default = false,
    Callback = function(v) data["basicdata"]["releasetools"]["Lantern"]["enable"] = v end
})
ToolsTab:AddToggle({
    Label = "超级光明",
    Default = false,
    Callback = function(v) data["basicdata"]["releasetools"]["SuperLighter"]["enable"] = v end
})
local xrayLastUpdate = 0
local xrayLoop = nil
local function toggleXrayLoop(enable)
    if enable then
        if xrayLoop then return end
        xrayLoop = RunService.Heartbeat:Connect(function()
            local now = tick()
            if now - xrayLastUpdate >= 1 then
                xrayLastUpdate = now
                xray(true)
            end
        end)
    else
        if xrayLoop then xrayLoop:Disconnect(); xrayLoop = nil end
    end
end
ToolsTab:AddToggle({
    Label = "X光",
    Default = false,
    Callback = function(v)
        data["basicdata"]["releasetools"]["xray"] = v
        toggleXrayLoop(v)
        if v then xray(true) else xray(false) end
    end
})
ToolsTab:AddToggle({
    Label = "显示隐藏部件",
    Default = false,
    Callback = function(v) showpartsfunction(v) end
})
ToolsTab:AddToggle({
    Label = "灵魂出窍",
    Default = false,
    Callback = function(v) FreecamModule.freecamenable = v end
})
enableToggle(ToolsTab, "平移", function()
    movementModule.Enable()
    ChronixUI:Notify({ Title = "提示", Content = "按下↑↓←→键进行平移", Type = "info", Duration = 5 })
end, function() movementModule.Disable() end)
enableToggle(ToolsTab, "空中移动", function() AirWalk.enable() end, function() AirWalk.disable() end)
enableToggle(ToolsTab, "无摔落伤害", function() NoFall.enable() end, function() NoFall.disable() end)
enableToggle(ToolsTab, "瞬间交互", function() InstantInteraction.enable() end, function() InstantInteraction.disable() end)
ToolsTab:AddToggle({
    Label = "穿墙",
    Default = false,
    Callback = function(v)
        data["basicdata"]["releasetools"]["noclip"] = v
        if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
        if noclipRespawn then noclipRespawn:Disconnect(); noclipRespawn = nil end
        if not v then
            for _, part in ipairs(data["basicdata"]["releasetools"]["noclipParts"]) do
                if part and part.Parent then part.CanCollide = true end
            end
            data["basicdata"]["releasetools"]["noclipParts"] = {}
            return
        end
        local function scanAndDisable()
            local char = LocalPlayer.Character
            if not char then return end
            pcall(function() char:WaitForChild("HumanoidRootPart") end)
            data["basicdata"]["releasetools"]["noclipParts"] = {}
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                    table.insert(data["basicdata"]["releasetools"]["noclipParts"], part)
                end
            end
        end
        scanAndDisable()
        noclipRespawn = LocalPlayer.CharacterAdded:Connect(scanAndDisable)
    end
})
ToolsTab:AddToggle({
    Label = "连跳",
    Default = false,
    Callback = function(v)
        data["basicdata"]["releasetools"]["infjump"] = v
        if JR then JR:Disconnect(); JR = nil end
        JR = UserInputService.JumpRequest:Connect(function()
            if not data["basicdata"]["releasetools"]["infjump"] then
                JR:Disconnect(); JR = nil
            else
                local c = LocalPlayer.Character
                if c and c.Parent then
                    local hum = c:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum:ChangeState("Jumping")
                    end
                end
            end
        end)
    end
})
local _autoJumpLast = 0
ToolsTab:AddToggle({
    Label = "自动跳跃",
    Default = false,
    Callback = function(v)
        data["basicdata"]["releasetools"]["autojump"] = v
        if v then
            autoJumpConnection = RunService.Heartbeat:Connect(function()
                if not data["basicdata"]["releasetools"]["autojump"] then
                    autoJumpConnection:Disconnect()
                    return
                end
                if tick() - _autoJumpLast < 0.2 then return end
                _autoJumpLast = tick()
                local c = LocalPlayer.Character
                if c and c.Parent then
                    local hum = c:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum:ChangeState("Jumping")
                    end
                end
            end)
        else
            if autoJumpConnection then
                autoJumpConnection:Disconnect()
                autoJumpConnection = nil
            end
        end
    end
})
enableToggle(ToolsTab, "固定到世界", function()
    LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RootPart.Anchored = true
end, function()
    LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RootPart.Anchored = false
end)
enableToggle(ToolsTab, "旁观模式", function() SpectatorModule.start() end, function() SpectatorModule.close() end)
enableToggle(ToolsTab, "摄像头穿墙", function() NoclipCam.enable(LocalPlayer) end, function() NoclipCam.disable() end)
ToolsTab:AddToggle({ Label = "防击倒", Default = false, Callback = function(v) if v then enableAntiFall() else disableAntiFall() end end })
enableToggle(ToolsTab, "晕厥康复", function() StandRecovery:enableDetection() end, function() StandRecovery:disableDetection() end)
enableToggle(ToolsTab, "防甩飞", function() FlingDetector.enable(LocalPlayer) end, function() FlingDetector.disable() end)
enableToggle(ToolsTab, "反物理劫持", function() AntiVoidModule.enable() end, function() AntiVoidModule.disable() end)
enableToggle(ToolsTab, "移除移动部件", function() MovingPartCleaner.Enable() end, function() MovingPartCleaner.Disable() end)
enableToggle(ToolsTab, "防御立场", function() DefenseField.Enable() end, function() DefenseField.Disable() end)
ToolsTab:AddToggle({
    Label = "管理员检测",
    Default = false,
    Callback = function(v) if v then enableStaffCheck() else disableStaffCheck() end end
})
enableToggle(ToolsTab, "死亡播报", function() enableDeathAnnounce() end, function() disableDeathAnnounce() end)
ToolsTab:AddToggle({
    Label = "防死亡",
    Default = false,
    Callback = function(v) if v then enableAntiDead() else disableAntiDead() end end
})
ToolsTab:AddToggle({
    Label = "聊天重发",
    Default = false,
    Callback = function(v) if v then enableChatResend() else disableChatResend() end end
})
enableToggle(ToolsTab, "聊天偷听", function() ChatSpy.enable() end, function() ChatSpy.disable() end)
enableToggle(ToolsTab, "自动喊话器", function() ChatSpammer.enable() end, function() ChatSpammer.disable() end)
ToolsTab:AddInput({
    Label = "喊话内容（每行一条）",
    Height = 80,
    Default = ChatSpammer.getMessagesAsText(),
    Callback = function(text) ChatSpammer.setMessagesFromText(text) end
})
ToolsTab:AddSlider({ Label = "喊话间隔（秒）", Min = 0.5, Max = 60, Default = ChatSpammer.getInterval(), Callback = function(v) ChatSpammer.setInterval(v) end })
ToolsTab:AddToggle({ Label = "随机模式", Default = ChatSpammer.isRandomMode(), Callback = function(v) ChatSpammer.setRandom(v) end })
enableToggle(ToolsTab, "坐下", function() LocalPlayer.Character:FindFirstChild("Humanoid").Sit = true end, function() LocalPlayer.Character:FindFirstChild("Humanoid").Sit = false end)
ToolsTab:AddToggle({
    Label = "防踢出",
    Default = false,
    Callback = function(v)
        if v then
            local success, message = AntiKickModule.enable()
            if message == "Incompatible Exploit: missing hookmetamethod or LocalPlayer not accessible" then
                ChronixUI:Notify({ Title = "不支持的漏洞", Content = (identifyexecutor and identifyexecutor() or "UnKnown") .. "暂不支持此功能", Type = "error", Duration = 5 })
            end
        else
            AntiKickModule.disable()
        end
    end
})
enableToggle(ToolsTab, "模型删除工具", function()
    DeleteTool.Enable()
    ChronixUI:Notify({ Title = "提示", Content = "按住Ctrl键点击来删除指向的模型", Type = "info", Duration = 5 })
end, function() DeleteTool.Disable() end)
enableToggle(ToolsTab, "GUI删除工具", function()
    GuiDeleter.enable()
    ChronixUI:Notify({ Title = "提示", Content = "按下" .. GuiDeleter.getBindKey().Name .. "键来删除鼠标指向的UI", Type = "info", Duration = 5 })
end, function() GuiDeleter.disable() end)
enableToggle(ToolsTab, "模型信息查询工具", function()
    ClickInspectModule.Enable()
    ChronixUI:Notify({ Title = "提示", Content = "按下Ctrl键点击来查看模型信息", Type = "info", Duration = 5 })
end, function() ClickInspectModule.Disable() end)
ToolsTab:AddToggle({
    Label = "禁用购买提示框",
    Default = false,
    Callback = function(v)
        if v then
            CoreGui.PurchasePromptApp.Enabled = false
        else
            CoreGui.PurchasePromptApp.Enabled = true
        end
    end
})
ToolsTab:AddToggle({
    Label = "禁用游戏暂停",
    Default = false,
    Callback = function(v) if v then enableNetworkPauseDisable() else disableNetworkPauseDisable() end end
})
enableToggle(ToolsTab, "游戏翻译", function()
    TranslationModule.enable()
    ChronixUI:Notify({ Title = "提示", Content = "正在翻译中，可能会比较慢\n速度限制2次/s", Type = "info", Duration = 10 })
end, function() TranslationModule.disable() end)
enableToggle(ToolsTab, "透视触点实例", function() TCPHighLight.touchinterest.enable() end, function() TCPHighLight.touchinterest.disable() end)
ToolsTab:AddToggle({ Label = "禁用触点实例", Default = false, Callback = function(v) toggleInteraction("TouchTransmitter", v); ChronixUI:Notify({ Title = "提示", Content = v and "已禁用所有触点" or "已恢复所有触点", Type = "info" }) end })
enableToggle(ToolsTab, "透视点击触发实例", function() TCPHighLight.clickdetectors.enable() end, function() TCPHighLight.clickdetectors.disable() end)
ToolsTab:AddToggle({ Label = "禁用点击触发实例", Default = false, Callback = function(v) toggleInteraction("ClickDetector", v) end })
enableToggle(ToolsTab, "透视可交互实例", function() TCPHighLight.proximityprompts.enable() end, function() TCPHighLight.proximityprompts.disable() end)
ToolsTab:AddToggle({ Label = "禁用可交互实例", Default = false, Callback = function(v) toggleInteraction("ProximityPrompt", v) end })
ToolsTab:AddButton({ Text = "触发所有触点实例", Callback = function()
	local Root = LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RootPart or LocalPlayer.Character:FindFirstChildWhichIsA("BasePart")
	if not firetouchinterest then
		ChronixUI:Notify({ Title = "错误", Content = "你的执行器不支持此功能。", Type = "error", Duration = 5 })
		return
	end
	local function Touch(x)
		x = x.FindFirstAncestorWhichIsA(x, "Part")
		if x then
			return task.spawn(function()
				firetouchinterest(x, Root, 1, wait() and firetouchinterest(x, Root, 0))
			end)
		end
		x.CFrame = Root.CFrame
	end
	for _, v in ipairs(Workspace:GetDescendants()) do
		if v.IsA(v, "TouchTransmitter") then
			Touch(v)
		end
	end
end })
ToolsTab:AddButton({ Text = "触发所有点击触发实例", Callback = function()
    if fireclickdetector then
		for _, descendant in ipairs(Workspace:GetDescendants()) do
			if descendant:IsA("ClickDetector") then
				fireclickdetector(descendant)
			end
		end
	else
		ChronixUI:Notify({ Title = "错误", Content = "你的执行器不支持此功能。", Type = "error", Duration = 5 })
	end
end })
ToolsTab:AddButton({ Text = "触发所有可交互实例", Callback = function()
    if fireproximityprompt then
		for _, descendant in ipairs(Workspace:GetDescendants()) do
			if descendant:IsA("ProximityPrompt") then
				fireproximityprompt(descendant)
			end
		end
	else
		ChronixUI:Notify({ Title = "错误", Content = "你的执行器不支持此功能。", Type = "error", Duration = 5 })
	end
end })
ToolsTab:AddButton({ Text = "回满血", Callback = function() LocalPlayer.Character.Humanoid.Health = LocalPlayer.Character.Humanoid.MaxHealth end })
ToolsTab:AddButton({ Text = "自杀", Callback = function() LocalPlayer.Character.Humanoid.Health = 0 end })
ToolsTab:AddButton({ Text = "强制自杀", Callback = function() respawn() end })
ToolsTab:AddButton({ Text = "原地重生", Callback = function() refresh() end })
ToolsTab:AddButton({ Text = "设置当前位置为重生点", Callback = function() data["basicdata"]["releasetools"]["spawnpos"] = LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RootPart.CFrame end })
ToolsTab:AddButton({ Text = "恢复默认重生点", Callback = function() data["basicdata"]["releasetools"]["spawnpos"] = nil end })
ToolsTab:AddButton({ Text = "回到最后的死亡点", Callback = function() if data["basicdata"]["releasetools"]["lastDeath"] ~= nil then LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RootPart.CFrame = data["basicdata"]["releasetools"]["lastDeath"] else ChronixUI:Notify({ Title = "错误", Content = "没有记录的死亡点。", Type = "error", Duration = 5 }) end end })
ToolsTab:AddButton({ Text = "获取游戏内全部工具", Callback = function() gettools() end })
ToolsTab:AddButton({ Text = "移除全部工具", Callback = function() removetools() end })
ToolsTab:AddButton({ Text = "丢弃手中工具", Callback = function() drophandtool(); ChronixUI:Notify({ Title = "掉落工具", Content = "已丢弃手中工具", Type = "success", Duration = 3 }) end })
ToolsTab:AddButton({ Text = "丢弃全部工具", Callback = function() droptool(); ChronixUI:Notify({ Title = "掉落工具", Content = "已丢弃全部工具", Type = "success", Duration = 3 }) end })
ToolsTab:AddButton({ Text = "获得点击传送工具", Callback = function()
    local backpack = LocalPlayer:FindFirstChildWhichIsA("Backpack")
    if backpack and backpack:FindFirstChild("手持点击传送") then
        ChronixUI:Notify({ Title = "提示", Content = "点击传送工具已存在", Type = "info", Duration = 2 })
        return
    end
    local mouse = LocalPlayer:GetMouse()
    local newTool = Instance.new("Tool")
    newTool.RequiresHandle = false
    newTool.Name = "手持点击传送"
    newTool.Parent = backpack
    newTool.Activated:Connect(function()
        local pos = mouse.Hit + Vector3.new(0, 2.5, 0)
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos.X, pos.Y, pos.Z)
    end)
end })
ToolsTab:AddButton({ Text = "重新加入当前房间(服务器)", Callback = function() rejoinCurrentGame() end })
ToolsTab:AddButton({ Text = "切换角色为R6", Callback = function() promptNewRig("R6") end })
ToolsTab:AddButton({ Text = "切换角色为R15", Callback = function() promptNewRig("R15") end })
ToolsTab:AddButton({ Text = "切换时间为白天", Callback = function() setDay() end })
ToolsTab:AddButton({ Text = "切换时间为黑夜", Callback = function() setNight() end })
ToolsTab:AddToggle({
    Label = "禁用雾效",
    Default = false,
    Callback = function(v) RemoveFog(v) end
})
ToolsTab:AddButton({ Text = "优化世界光效", Callback = function() loadstring(cloneref(game):HttpGet("https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/WorldShader.lua"))() end })
ToolsTab:AddButton({ Text = "打印当前坐标", Callback = function()
    local position1 = LocalPlayer.Character.HumanoidRootPart.Position
    print(string.format("[THub] 玩家坐标: (%.2f, %.2f, %.2f)", position1.X, position1.Y, position1.Z))
end })
ToolsTab:AddButton({ Text = "开启控制台界面", Callback = function() StarterGui:SetCore("DevConsoleVisible", true) end })
ToolsTab:AddButton({ Text = "启用所有ROBLOXUI", Callback = function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end })
ToolsTab:AddButton({ Text = "获取建筑工具", Callback = function()
    local backpack = LocalPlayer:FindFirstChildWhichIsA("Backpack")
    if not backpack then return end
    local existing = 0
    for _, v in pairs(backpack:GetChildren()) do
        if v:IsA("HopperBin") then existing += 1 end
    end
    if existing >= 4 then
        ChronixUI:Notify({ Title = "提示", Content = "背包中已有建筑工具", Type = "info", Duration = 2 })
        return
    end
    for i = 1, 4 do
		local Tool = Instance.new("HopperBin")
		Tool.BinType = i
		Tool.Name = randomString()
		Tool.Parent = backpack
	end
end })

ToolsTab:AddButton({ Text = "终止当前游戏进程", Callback = function()
    if messagebox then
        local result = messagebox("Do you want to end the current game?\n\nIt may be used in situations where exit is not possible.", "Roblox", 4 + 32)
        if result == 6 then game:Shutdown() end
    else
        data["basicdata"]["releasetools"]["exitgame"] = data["basicdata"]["releasetools"]["exitgame"] + 1
        if data["basicdata"]["releasetools"]["exitgame"] == 1 then ChronixUI:Notify({ Title = "警告", Content = "你确定要终止游戏进程吗？", Type = "warning", Duration = 10 }) end
        if data["basicdata"]["releasetools"]["exitgame"] == 2 then ChronixUI:Notify({ Title = "警告", Content = "再次确定？", Type = "warning", Duration = 10 }) end
        if data["basicdata"]["releasetools"]["exitgame"] == 3 then ChronixUI:Notify({ Title = "警告", Content = "最终确定？", Type = "warning", Duration = 10 }) end
        if data["basicdata"]["releasetools"]["exitgame"] == 4 then game:Shutdown() end
    end
end })

-- ===== 脚本中心 Tab =====
local scripthubTab = mainWindow:CreateTab({ Name = "脚本中心", HasIcon = true, IconName = "computer" })
scripthubTab:AddTitle("由作者推荐的脚本 - 注意大部分脚本未经过验证，请谨慎使用。")
local function addscripts(name, link)
    scripthubTab:AddButton({ Text = name, Callback = function()
        ChronixUI:Notify({ Title = "提示", Content = name .. "正在启动，请耐心等待。", Type = "info", Duration = 5 })

        local content, success = AsyncFileFetcher.fetchSingle(link)
        if success then loadstring(content)() else ChronixUI:Notify({ Title = "提示", Content = name .. "启动失败。", Type = "warning", Duration = 5 }) end
        ChronixUI:Notify({ Title = "提示", Content = name .. "启动成功。", Type = "success", Duration = 5 })
    end })
end
for index, scriptInfo in ipairs(data["scriptlist"]) do
    addscripts(scriptInfo.name, scriptInfo.link)
end

-- ===== 玩家传送 Tab =====
local function createPlayerButton(player)
    return playerteleporterTab:AddButton({
        Text = player.DisplayName .. " (" .. player.Name .. ")",
        Callback = function()
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local targetCharacter = player.Character
                if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
                    character:SetPrimaryPartCFrame(CFrame.new(targetCharacter.HumanoidRootPart.Position))
                    ChronixUI:Notify({ Title = "传送成功", Content = "已传送到 " .. player.DisplayName, Type = "success", Duration = 2 })
                else
                    ChronixUI:Notify({ Title = "传送失败", Content = "目标玩家角色不存在", Type = "error", Duration = 2 })
                end
            else
                ChronixUI:Notify({ Title = "传送失败", Content = "无法获取你的角色", Type = "error", Duration = 2 })
            end
        end
    })
end

playerteleporterTab = mainWindow:CreateTab({ Name = "玩家传送", HasIcon = true, IconName = "contact-round" })
playerteleporterTab:AddTitle("玩家列表")
playerteleporterTab:AddDivider()
playerButtons = {}
function updatePlayerList()
    local currentPlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then currentPlayers[player.Name] = player end
    end
    for playerName, button in pairs(playerButtons) do
        if not currentPlayers[playerName] then
            if button and button.Destroy then button:Destroy() end
            playerButtons[playerName] = nil
        end
    end
    for playerName, player in pairs(currentPlayers) do
        if not playerButtons[playerName] then
            playerButtons[playerName] = createPlayerButton(player)
        end
    end
end
updatePlayerList()
playerListAddedConn = Players.PlayerAdded:Connect(updatePlayerList)
playerListRemovingConn = Players.PlayerRemoving:Connect(updatePlayerList)

-- ===== 路径点传送 Tab =====
waypointTab = mainWindow:CreateTab({ Name = "路径点传送", HasIcon = true, IconName = "map-pinned" })
waypointConfig = ConfigModule.createconfig("waypoint/data/" .. game.GameId)
waypointsData = waypointConfig.waypointsData and waypointConfig.waypointsData or {}
waypointUIElements = {}
waypointDisplayEnabled = false
local waypointHeartbeatConnection = nil
function startWaypointHeartbeat()
    if waypointHeartbeatConnection then return end
    waypointHeartbeatConnection = RunService.Heartbeat:Connect(function()
        if not waypointDisplayEnabled then return end
        for _, beamData in pairs(waypointBeams) do
            if beamData.indicatorPart and beamData.indicatorPart.Parent then
                local camera = Workspace.CurrentCamera
                if camera then
                    local direction = (camera.CFrame.Position - beamData.posVector) * Vector3.new(1, 0, 1)
                    if direction.Magnitude > 0.01 then
                        local lookAt = CFrame.new(beamData.posVector + Vector3.new(0, 25, 0), beamData.posVector + Vector3.new(0, 25, 0) + direction.Unit)
                        beamData.indicatorPart.CFrame = lookAt
                    end
                end
            end
            if beamData.textLabel and beamData.textLabel.Parent then
                local playerPosition = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.new(0, 0, 0)
                local distance = (beamData.posVector - playerPosition).Magnitude
                beamData.textLabel.Text = string.format("📍 #%d (%.1fm)\n%s", beamData.id, distance, beamData.note or "")
            end
        end
    end)
end
function stopWaypointHeartbeat()
    if waypointHeartbeatConnection then
        waypointHeartbeatConnection:Disconnect()
        waypointHeartbeatConnection = nil
    end
end

waypointBeams = {}
function updateWaypointDisplay()
    for _, beamData in pairs(waypointBeams) do
        if beamData.anchorPart and beamData.anchorPart.Parent then beamData.anchorPart:Destroy() end
        if beamData.indicatorPart and beamData.indicatorPart.Parent then beamData.indicatorPart:Destroy() end
    end
    waypointBeams = {}
    if not waypointDisplayEnabled then stopWaypointHeartbeat(); return else startWaypointHeartbeat() end
    for _, waypoint in ipairs(waypointsData) do
        local pos = waypoint.position
        local posVector = Vector3.new(pos.X, pos.Y, pos.Z)
        local anchorPart = Instance.new("Part")
        anchorPart.Name = "WaypointAnchor_" .. waypoint.id
        anchorPart.Size = Vector3.new(0.2, 0.2, 0.2)
        anchorPart.Transparency = 1
        anchorPart.CanCollide = false
        anchorPart.Anchored = true
        anchorPart.CFrame = CFrame.new(posVector)
        anchorPart.Parent = Workspace
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "WaypointBillboard_" .. waypoint.id
        billboard.Size = UDim2.new(0, 200, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = 0
        billboard.Adornee = anchorPart
        billboard.Parent = anchorPart
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        textLabel.TextStrokeTransparency = 0
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextScaled = true
        textLabel.Parent = billboard
        local indicatorPart = Instance.new("Part")
        indicatorPart.Name = "WaypointIndicator_" .. waypoint.id
        indicatorPart.Size = Vector3.new(0.1, 2000, 0.1)
        indicatorPart.CanCollide = false
        indicatorPart.Anchored = true
        indicatorPart.Material = Enum.Material.Neon
        indicatorPart.Color = Color3.fromRGB(0, 255, 100)
        indicatorPart.Transparency = 0.6
        indicatorPart.CFrame = CFrame.new(posVector)
        indicatorPart.Parent = Workspace
        local noteStr = type(waypoint.note) == "string" and waypoint.note or tostring(waypoint.note or "")
        textLabel.Text = string.format("📍 #%d\n%s", waypoint.id, noteStr ~= "" and noteStr or "")
        local beamData = {
            id = waypoint.id,
            posVector = posVector,
            anchorPart = anchorPart,
            indicatorPart = indicatorPart,
            textLabel = textLabel,
            note = noteStr,
        }
        table.insert(waypointBeams, beamData)
    end
end
function clearWaypointList()
    for _, elements in ipairs(waypointUIElements) do
        for _, element in ipairs(elements) do
            if element and element.Destroy then
                element:Destroy()
            end
        end
    end
waypointUIElements = {}
waypointTitleMap = {}
    waypointTitleMap = {}
end
local function updateWaypointTitle(id)
    local entry = waypointTitleMap[id]
    if not entry then return end
    local wp = waypointsData[id]
    if not wp then return end
    local noteStr = type(wp.note) == "string" and wp.note ~= "" and (" - " .. wp.note) or ""
    if type(entry.title.setText) == "function" then
        entry.title:setText(string.format("📍 路径点 #%d%s", id, noteStr))
    end
end
local function buildWaypointElements(waypoint)
    local elements = {}
    if waypoint.id > 1 then
        local divider = waypointTab:AddDivider()
        table.insert(elements, divider)
    end
    local idNum = tonumber(waypoint.id) or 0
    local noteStr = type(waypoint.note) == "string" and waypoint.note or tostring(waypoint.note)
    local titleText = string.format("📍 路径点 #%d", idNum)
    if noteStr ~= "" then
        titleText = titleText .. " - " .. noteStr
    end
    local title = waypointTab:AddTitle(titleText)
    table.insert(elements, title)
    waypointTitleMap[waypoint.id] = { title = title }
    local pos = waypoint.position
    local x = pos and pos.X or 0
    local y = pos and pos.Y or 0
    local z = pos and pos.Z or 0
    local coordText = string.format("坐标: X: %.1f, Y: %.1f, Z: %.1f", x, y, z)
    local coordLabel = waypointTab:AddLabel(coordText)
    table.insert(elements, coordLabel)
    local noteInput = waypointTab:AddInput({
        Label = "备注",
        Placeholder = "输入备注信息...",
        Default = noteStr,
        Callback = function(text)
            waypoint.note = text or ""
            waypointConfig.waypointsData = waypointsData
            updateWaypointTitle(waypoint.id)
        end
    })
    table.insert(elements, noteInput)
    local teleportBtn = waypointTab:AddButton({
        Text = "🚀 传送到此路径点",
        Callback = function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local targetPos = Vector3.new(pos.X, pos.Y, pos.Z)
                char:SetPrimaryPartCFrame(CFrame.new(targetPos))
                ChronixUI:Notify({ Title = "传送成功", Content = string.format("已传送到 %s", noteStr ~= "" and noteStr or "路径点"), Type = "success", Duration = 2 })
            else
                ChronixUI:Notify({ Title = "传送失败", Content = "无法获取你的角色", Type = "error", Duration = 2 })
            end
        end
    })
    table.insert(elements, teleportBtn)
    local tweenBtn = waypointTab:AddButton({
        Text = "🎯 缓动到此路径点",
        Callback = function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
                local targetPos = Vector3.new(pos.X, pos.Y, pos.Z)
                local root = char.HumanoidRootPart
                TweenService:Create(root, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)}):Play()
                ChronixUI:Notify({ Title = "缓动中", Content = string.format("正在缓动到 %s", noteStr ~= "" and noteStr or "路径点"), Type = "info", Duration = 2 })
            else
                ChronixUI:Notify({ Title = "缓动失败", Content = "无法获取你的角色", Type = "error", Duration = 2 })
            end
        end
    })
    table.insert(elements, tweenBtn)
    local walkBtn = waypointTab:AddButton({
        Text = "🚶 步行到此路径点",
        Callback = function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                local targetPos = Vector3.new(pos.X, pos.Y, pos.Z)
                if humanoid.SeatPart then
                    humanoid.Sit = false
                    task.wait(0.1)
                end
                humanoid.WalkToPoint = targetPos
                ChronixUI:Notify({ Title = "步行中", Content = string.format("正在走向 %s", noteStr ~= "" and noteStr or "路径点"), Type = "info", Duration = 2 })
            else
                ChronixUI:Notify({ Title = "步行失败", Content = "无法获取你的角色", Type = "error", Duration = 2 })
            end
        end
    })
    table.insert(elements, walkBtn)
    local deleteBtn = waypointTab:AddButton({
        Text = "🗑️ 删除此路径点",
        Callback = function()
            local removed = table.remove(waypointsData, waypoint.id)
            if removed then
                local entry = waypointTitleMap[waypoint.id]
                if entry then waypointTitleMap[waypoint.id] = nil end
                local elements = waypointUIElements[waypoint.id]
                if elements then
                    for _, element in ipairs(elements) do
                        if element and element.Destroy then element:Destroy() end
                    end
                    table.remove(waypointUIElements, waypoint.id)
                end
                for i, data in ipairs(waypointsData) do
                    data["id"] = i
                    updateWaypointTitle(i)
                end
            end
            waypointConfig.waypointsData = waypointsData
            updateWaypointDisplay()
            ChronixUI:Notify({ Title = "已删除", Content = "路径点已移除", Type = "info", Duration = 1 })
        end
    })
    table.insert(elements, deleteBtn)
    return elements
end
function refreshWaypointList()
    clearWaypointList()
    for _, waypoint in ipairs(waypointsData) do
        local elements = buildWaypointElements(waypoint)
        table.insert(waypointUIElements, elements)
    end
    waypointConfig.waypointsData = waypointsData
    updateWaypointDisplay()
end
function addWaypoint(pos, note)
    local posTable = {
        X = pos.X,
        Y = pos.Y,
        Z = pos.Z
    }
    local waypoint = {
        id = #waypointsData + 1,
        position = posTable,
        note = note or ""
    }
    table.insert(waypointsData, waypoint)
    local elements = buildWaypointElements(waypoint)
    table.insert(waypointUIElements, elements)
    waypointConfig.waypointsData = waypointsData
    updateWaypointDisplay()
end
waypointTab:AddTitle("路径点管理")
waypointTab:AddDivider()
waypointTab:AddLabel("点击下方按钮保存当前位置作为路径点")
waypointTab:AddToggle({
    Label = "在世界中显示路径点",
    Default = false,
    Callback = function(v)
        waypointDisplayEnabled = v
        updateWaypointDisplay()
    end
})
waypointTab:AddButton({
    Text = "➕ 添加当前路径点",
    Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart then
            local position = LocalPlayer.Character.HumanoidRootPart.Position
            addWaypoint(position)
            ChronixUI:Notify({ Title = "路径点已添加", Content = string.format("位置: (%.1f, %.1f, %.1f)", position.X, position.Y, position.Z), Type = "success", Duration = 2 })
        else
            ChronixUI:Notify({ Title = "添加失败", Content = "无法获取当前位置", Type = "error", Duration = 2 })
        end
    end
})
waypointTab:AddDivider()
waypointTab:AddTitle("已保存的路径点")
waypointTab:AddDivider()
if #waypointsData > 0 then refreshWaypointList() end

-- ===== 音乐播放器 Tab =====
local musicislink = false
musicTab = mainWindow:CreateTab({ Name = "音乐播放器", HasIcon = true, IconName = "music" })
musicTab:AddTitle("音乐播放器")
musicTab:AddDivider()
musicTab:AddLabel("选择预设音乐 (rbxassetid)")
musicDropdown = musicTab:AddDropdown({
    Label = "预设音乐ID",
    Options = data["basicdata"]["otherdata"]["musicData"]["musicIds"],
    Default = data["basicdata"]["otherdata"]["musicData"]["currentId"],
    Callback = function(selected)
        data["basicdata"]["otherdata"]["musicData"]["currentId"] = selected
        if customIdInput then
            local textBox = customIdInput:FindFirstChildOfClass("TextBox")
            if textBox then
                textBox.Text = selected
            end
        end
    end
})
othermusicDropdown = musicTab:AddDropdown({
    Label = "外部音乐",
    Options = (function() local names = {}; for musicname, _ in pairs(musicList) do table.insert(names, musicname) end; return names end)(),
    Default = "",
    Callback = function(selected)
        for musicname, assid in pairs(musicList) do
            if musicname == selected then
                data["basicdata"]["otherdata"]["musicData"]["othermusicname"] = musicname
                data["basicdata"]["otherdata"]["musicData"]["currentId"] = assid
            end
        end
    end
})
local linkmusic = musicTab:AddInput({
    Label = "音乐直链",
    Default = "",
    Placeholder = "输入音乐直链",
    Callback = function(text)
        if text and text ~= "" then
            data["basicdata"]["otherdata"]["musicData"]["currentId"] = "link"
            data["basicdata"]["otherdata"]["musicData"]["currentlink"] = text
            musicislink = true
        end
    end
})
musicTab:AddDivider()
musicTab:AddLabel("或手动输入自定义ID")
customIdInput = musicTab:AddInput({
    Label = "自定义音乐ID",
    Default = data["basicdata"]["otherdata"]["musicData"]["currentId"],
    Placeholder = "输入 rbxassetid，例如: 142376088",
    Callback = function(text)
        if text and text ~= "" then
            data["basicdata"]["otherdata"]["musicData"]["currentId"] = text
        end
    end
})
musicTab:AddDivider()
musicTab:AddLabel("播放控制")
playStopButton = nil
pauseResumeButton = nil
playStopButton = musicTab:AddButton({
    Text = "▶️ 播放",
    Callback = function()
        if data["basicdata"]["otherdata"]["musicData"]["isPlay"] then
            data["basicdata"]["otherdata"]["musicbox"]:Stop()
            data["basicdata"]["otherdata"]["musicData"]["isPlay"] = false
            data["basicdata"]["otherdata"]["musicData"]["isPause"] = false
            playStopButton.Text = "▶️ 播放"
            if pauseResumeButton then
                pauseResumeButton.Text = "⏸️ 暂停"
            end
            ChronixUI:Notify({ Title = "已停止", Content = "音乐播放已停止", Type = "info", Duration = 2 })
        else
            if data["basicdata"]["otherdata"]["musicData"]["currentId"] == "link" then
                ChronixUI:Notify({ Title = "提示", Content = "正在读取链接内容，请稍等...", Type = "info", Duration = 3 })
                local errorCode, result = ConfigModule.downloadAudio(data["basicdata"]["otherdata"]["musicData"]["currentlink"])
                if errorCode == 0 then
                    data["basicdata"]["otherdata"]["musicData"]["currentId"] = tostring(result)
                elseif errorCode == 1 then
                    ChronixUI:Notify({ Title = "播放失败", Content = "不是一个有效的直链音频", Type = "error", Duration = 3 })
                elseif errorCode == 2 then
                    ChronixUI:Notify({ Title = "播放失败", Content = "缓存文件失败", Type = "error", Duration = 3 })
                elseif errorCode == 3 then
                    ChronixUI:Notify({ Title = "播放失败", Content = "获取资产ID失败", Type = "error", Duration = 3 })
                end
            end
            data["basicdata"]["otherdata"]["musicbox"]["SoundId"] = (not string.find(data["basicdata"]["otherdata"]["musicData"]["currentId"], "rbxasset://")) and ("rbxassetid://" .. data["basicdata"]["otherdata"]["musicData"]["currentId"]) or data["basicdata"]["otherdata"]["musicData"]["currentId"]
            local success, productInfo = pcall(function()
                if string.find(data["basicdata"]["otherdata"]["musicData"]["currentId"], "rbxasset://") then
                    return {}
                else
                    return MarketplaceService:GetProductInfo(tonumber(data["basicdata"]["otherdata"]["musicData"]["currentId"]))
                end
            end)
            if success and productInfo then
                data["basicdata"]["otherdata"]["musicbox"]:Play()
                data["basicdata"]["otherdata"]["musicData"]["isPlay"] = true
                data["basicdata"]["otherdata"]["musicData"]["isPause"] = false
                data["basicdata"]["otherdata"]["musicbox"].TimePosition = 0
                playStopButton.Text = "⏹️ 停止"
                if pauseResumeButton then
                    pauseResumeButton.Text = "⏸️ 暂停"
                end
                ChronixUI:Notify({ Title = "正在播放", Content = musicislink and data["basicdata"]["otherdata"]["musicData"]["currentlink"] or (productInfo.Name or ""), Type = "info", Duration = 3 })
            else
                ChronixUI:Notify({ Title = "播放失败", Content = "无效的rbxassetid", Type = "error", Duration = 3 })
                data["basicdata"]["otherdata"]["musicData"]["isPlay"] = false
            end
        end
    end
})
pauseResumeButton = musicTab:AddButton({
    Text = "⏸️ 暂停",
    Callback = function()
        if not data["basicdata"]["otherdata"]["musicData"]["isPlay"] then
            ChronixUI:Notify({ Title = "无法操作", Content = "请先播放音乐", Type = "warning", Duration = 2 })
            return
        end
        if data["basicdata"]["otherdata"]["musicData"]["isPause"] then
            data["basicdata"]["otherdata"]["musicbox"]["TimePosition"] = data["basicdata"]["otherdata"]["musicData"]["PlayLocation"]
            data["basicdata"]["otherdata"]["musicbox"]:Play()
            data["basicdata"]["otherdata"]["musicData"]["isPause"] = false
            pauseResumeButton.Text = "⏸️ 暂停"
            ChronixUI:Notify({ Title = "继续播放", Content = "音乐已恢复", Type = "info", Duration = 1 })
        else
            data["basicdata"]["otherdata"]["musicData"]["PlayLocation"] = data["basicdata"]["otherdata"]["musicbox"]["TimePosition"]
            data["basicdata"]["otherdata"]["musicbox"]:Stop()
            data["basicdata"]["otherdata"]["musicData"]["isPause"] = true
            pauseResumeButton.Text = "▶️ 继续"
            ChronixUI:Notify({ Title = "已暂停", Content = "音乐已暂停", Type = "info", Duration = 1 })
        end
    end
})
loopButton = musicTab:AddButton({
    Text = "🔄 循环播放",
    Callback = function()
        data["basicdata"]["otherdata"]["musicbox"]["Looped"] = not data["basicdata"]["otherdata"]["musicbox"]["Looped"]
        loopButton.Text = data["basicdata"]["otherdata"]["musicbox"]["Looped"] and "🔁 不循环播放" or "🔄 循环播放"
        ChronixUI:Notify({ Title = "设置已更改", Content = data["basicdata"]["otherdata"]["musicbox"]["Looped"] and "已开启循环播放" or "已关闭循环播放", Type = "info", Duration = 1 })
    end
})
musicTab:AddDivider()
musicTab:AddLabel("音量控制")
volumeLabel = musicTab:AddLabel(string.format("当前音量: %.0f%%", data["basicdata"]["otherdata"]["musicbox"]["Volume"] * 100))
musicTab:AddButton({
    Text = "🔊 音量 +",
    Callback = function()
        if data["basicdata"]["otherdata"]["musicbox"]["Volume"] < 1 then
            data["basicdata"]["otherdata"]["musicbox"]["Volume"] = math.min(1, data["basicdata"]["otherdata"]["musicbox"]["Volume"] + 0.1)
            volumeLabel.Text = string.format("当前音量: %.0f%%", data["basicdata"]["otherdata"]["musicbox"]["Volume"] * 100)
        end
    end
})
musicTab:AddButton({
    Text = "🔉 音量 -",
    Callback = function()
        if data["basicdata"]["otherdata"]["musicbox"]["Volume"] > 0 then
            data["basicdata"]["otherdata"]["musicbox"]["Volume"] = math.max(0, data["basicdata"]["otherdata"]["musicbox"]["Volume"] - 0.1)
            volumeLabel.Text = string.format("当前音量: %.0f%%", data["basicdata"]["otherdata"]["musicbox"]["Volume"] * 100)
        end
    end
})
musicTab:AddDivider()
musicTab:AddLabel("音高控制")
pitchLabel = musicTab:AddLabel(string.format("当前音高: %.1f", data["basicdata"]["otherdata"]["musicbox"]["Pitch"]))
musicTab:AddButton({
    Text = "🎵 音高 +",
    Callback = function()
        data["basicdata"]["otherdata"]["musicbox"]["Pitch"] = data["basicdata"]["otherdata"]["musicbox"]["Pitch"] + 0.1
        pitchLabel.Text = string.format("当前音高: %.1f", data["basicdata"]["otherdata"]["musicbox"]["Pitch"])
    end
})
musicTab:AddButton({
    Text = "🎵 音高 -",
    Callback = function()
        if data["basicdata"]["otherdata"]["musicbox"]["Pitch"] > 0.1 then
            data["basicdata"]["otherdata"]["musicbox"]["Pitch"] = data["basicdata"]["otherdata"]["musicbox"]["Pitch"] - 0.1
            pitchLabel.Text = string.format("当前音高: %.1f", data["basicdata"]["otherdata"]["musicbox"]["Pitch"])
        end
    end
})
musicTab:AddButton({
    Text = "🔄 重置音高",
    Callback = function()
        data["basicdata"]["otherdata"]["musicbox"]["Pitch"] = 1
        pitchLabel.Text = string.format("当前音高: %.1f", data["basicdata"]["otherdata"]["musicbox"]["Pitch"])
    end
})
musicTab:AddDivider()
musicTab:AddLabel("💡 提示：可从下拉框选择预设音乐，或手动输入自定义ID")
musicTab:AddLabel("📝 自定义ID格式：纯数字，如 142376088")

-- ===== 音频检查器 Tab =====
audioCheckerTab = mainWindow:CreateTab({ Name = "音频检查器", HasIcon = true, IconName = "audio-waveform" })
testIdLabel = nil
function getAllSounds(parent)
    local sounds = {}
    for _, child in ipairs(parent:GetDescendants()) do
        if child:IsA("Sound") then
            table.insert(sounds, child)
        end
    end
    return sounds
end
function extractSoundIdNumber(soundId)
    local number = string.match(soundId, "rbxassetid://(%d+)")
    return number or soundId
end
function getLoudSounds(threshold)
    local loudSounds = {}
    local allSounds = getAllSounds(cloneref(game))
    for _, sound in ipairs(allSounds) do
        if sound.IsPlaying and sound.PlaybackLoudness > threshold then
            local cleanSoundId = extractSoundIdNumber(sound.SoundId)
            table.insert(loudSounds, {
                SoundId = sound.SoundId,
                CleanSoundId = cleanSoundId,
                Name = sound.Name,
                Volume = sound.Volume,
                Loudness = sound.PlaybackLoudness,
                VolumeDB = sound.PlaybackLoudness,
                Parent = sound.Parent and sound.Parent.Name or "Unknown",
                FullPath = sound:GetFullName()
            })
        end
    end
    return loudSounds
end
function clearAudioList()
    for _, item in ipairs(data["basicdata"]["otherdata"]["audioData"]["audioListItems"]) do
        if item and item.Destroy then
            item:Destroy()
        end
    end
    data["basicdata"]["otherdata"]["audioData"]["audioListItems"] = {}
end
function refreshAudioList()
    if not data["basicdata"]["otherdata"]["audioData"]["enable"] then return end
    clearAudioList()
    local loudSounds = getLoudSounds(data["basicdata"]["otherdata"]["audioData"]["threshold"])
    if #loudSounds == 0 then
        local emptyLabel = audioCheckerTab:AddLabel("未检测到超过阈值的音频")
        table.insert(data["basicdata"]["otherdata"]["audioData"]["audioListItems"], emptyLabel)
    else
        for _, soundInfo in ipairs(loudSounds) do
            local displayText = string.format("ID: %s | 响度: %.1f dB | 来源: %s",
                soundInfo.CleanSoundId or "未知",
                soundInfo.Loudness,
                soundInfo.Parent
            )
            local soundButton = audioCheckerTab:AddButton({
                Text = displayText,
                Callback = function()
                    if soundInfo.CleanSoundId then
                        data["basicdata"]["otherdata"]["audioData"]["currentSelectedId"] = soundInfo.CleanSoundId
                        if testIdLabel then
                            testIdLabel.Text = "当前选中ID: " .. soundInfo.CleanSoundId
                        end
                        ChronixUI:Notify({ Title = "已选中", Content = "音频ID: " .. soundInfo.CleanSoundId .. "\n来源: " .. soundInfo.FullPath, Type = "info", Duration = 3 })
                    end
                end
            })
            table.insert(data["basicdata"]["otherdata"]["audioData"]["audioListItems"], soundButton)
        end
    end
end
function startAudioScanning()
    if data["basicdata"]["otherdata"]["audioData"]["scanConnection"] then
        data["basicdata"]["otherdata"]["audioData"]["scanConnection"]:Disconnect()
        data["basicdata"]["otherdata"]["audioData"]["scanConnection"] = nil
    end
    if data["basicdata"]["otherdata"]["audioData"]["enable"] then
        refreshAudioList()
        data["basicdata"]["otherdata"]["audioData"]["scanConnection"] = RunService.Heartbeat:Connect(function()
            if not data["basicdata"]["otherdata"]["audioData"]["enable"] then
                if data["basicdata"]["otherdata"]["audioData"]["scanConnection"] then
                    data["basicdata"]["otherdata"]["audioData"]["scanConnection"]:Disconnect()
                    data["basicdata"]["otherdata"]["audioData"]["scanConnection"] = nil
                end
                return
            end
            local currentTime = tick()
            if currentTime - data["basicdata"]["otherdata"]["audioData"]["lastScanTime"] >= 1.0 then
                data["basicdata"]["otherdata"]["audioData"]["lastScanTime"] = currentTime
                refreshAudioList()
            end
        end)
    end
end
audioCheckerTab:AddTitle("音频检查器")
audioCheckerTab:AddLabel("筛选响度阈值 (建议10-50)")
thresholdInput = audioCheckerTab:AddInput({
    Label = "响度阈值",
    Default = tostring(data["basicdata"]["otherdata"]["audioData"]["threshold"]),
    Placeholder = "输入阈值，例如: 30",
    Callback = function(text)
        local num = tonumber(text)
        if num then
            data["basicdata"]["otherdata"]["audioData"]["threshold"] = math.clamp(num, 0, 1000)
            if data["basicdata"]["otherdata"]["audioData"]["enable"] then
                refreshAudioList()
            end
        end
    end
})
local function clearAudioListUI()
    for _, item in ipairs(data["basicdata"]["otherdata"]["audioData"]["audioListItems"]) do
        if item and item.Destroy then
            pcall(function() item:Destroy() end)
        end
    end
    data["basicdata"]["otherdata"]["audioData"]["audioListItems"] = {}
end
audioCheckerTab:AddToggle({
    Label = "开始检测音频",
    Default = false,
    Callback = function(v)
        data["basicdata"]["otherdata"]["audioData"]["enable"] = v
        if v then
            data["basicdata"]["otherdata"]["audioData"]["lastScanTime"] = tick()
            startAudioScanning()
            ChronixUI:Notify({ Title = "已开启", Content = "开始检测游戏中播放的音频", Type = "success", Duration = 2 })
        else
            if data["basicdata"]["otherdata"]["audioData"]["scanConnection"] then
                data["basicdata"]["otherdata"]["audioData"]["scanConnection"]:Disconnect()
                data["basicdata"]["otherdata"]["audioData"]["scanConnection"] = nil
            end
            clearAudioListUI()
            ChronixUI:Notify({ Title = "已关闭", Content = "音频检测已停止", Type = "info", Duration = 2 })
        end
    end
})
audioCheckerTab:AddDivider()
audioCheckerTab:AddTitle("测试播放")
testIdLabel = audioCheckerTab:AddLabel("当前选中ID: 未选择")
audioCheckerTab:AddButton({
    Text = "📋 复制选中ID到剪贴板",
    Callback = function()
        if data["basicdata"]["otherdata"]["audioData"]["currentSelectedId"] then
            setclipboard(data["basicdata"]["otherdata"]["audioData"]["currentSelectedId"])
            ChronixUI:Notify({ Title = "已复制", Content = data["basicdata"]["otherdata"]["audioData"]["currentSelectedId"] .. " 已复制到剪贴板", Type = "info", Duration = 2 })
        else
            ChronixUI:Notify({ Title = "未选中", Content = "请先点击音频列表中的项目", Type = "warning", Duration = 2 })
        end
    end
})
testSoundEndedConn = nil
testPlayButton = audioCheckerTab:AddButton({
    Text = "🎵 尝试播放",
    Callback = function()
        if not data["basicdata"]["otherdata"]["audioData"]["currentSelectedId"] then
            ChronixUI:Notify({ Title = "无法播放", Content = "请先选中一个音频ID", Type = "warning", Duration = 2 })
            return
        end
        if data["basicdata"]["otherdata"]["audioData"]["isTesting"] then
            data["basicdata"]["otherdata"]["testSound"]:Stop()
            data["basicdata"]["otherdata"]["audioData"]["isTesting"] = false
            testPlayButton.Text = "🎵 尝试播放"
            if testSoundEndedConn then testSoundEndedConn:Disconnect(); testSoundEndedConn = nil end
            ChronixUI:Notify({ Title = "已停止", Content = "测试播放已停止", Type = "info", Duration = 1 })
        else
            local soundId = "rbxassetid://" .. data["basicdata"]["otherdata"]["audioData"]["currentSelectedId"]
            data["basicdata"]["otherdata"]["testSound"]["SoundId"] = soundId
            local success, productInfo = pcall(function()
                return MarketplaceService:GetProductInfo(tonumber(data["basicdata"]["otherdata"]["audioData"]["currentSelectedId"]))
            end)
            if success and productInfo then
                data["basicdata"]["otherdata"]["testSound"]:Play()
                data["basicdata"]["otherdata"]["audioData"]["isTesting"] = true
                testPlayButton.Text = "⏹️ 结束播放"
                testIdLabel.Text = "测试ID: " .. data["basicdata"]["otherdata"]["audioData"]["currentSelectedId"]
                ChronixUI:Notify({ Title = "正在播放", Content = productInfo.Name, Type = "info", Duration = 2 })
                if testSoundEndedConn then testSoundEndedConn:Disconnect() end
                testSoundEndedConn = data["basicdata"]["otherdata"]["testSound"]["Ended"]:Connect(function()
                    if data["basicdata"]["otherdata"]["audioData"]["isTesting"] then
                        data["basicdata"]["otherdata"]["audioData"]["isTesting"] = false
                        testPlayButton.Text = "🎵 尝试播放"
                        testSoundEndedConn = nil
                    end
                end)
            else
                ChronixUI:Notify({ Title = "播放失败", Content = data["basicdata"]["otherdata"]["audioData"]["currentSelectedId"] .. " 不是一个有效的音频ID", Type = "error", Duration = 2 })
            end
        end
    end
})
audioCheckerTab:AddDivider()
audioCheckerTab:AddTitle("检测到的音频")
audioCheckerTab:AddLabel("点击任意音频可选中并复制ID")
audioCheckerTab:AddDivider()

-- ===== 聊天接收器 Tab =====
chatReceiverTab = mainWindow:CreateTab({ Name = "聊天接收器", HasIcon = true, IconName = "messages-square" })
local CHAT_MAX = 100
chatMessages = {}
function clearChatMessages()
    for _, element in ipairs(chatMessages) do
        if element and element.Destroy then
            element:Destroy()
        end
    end
    chatMessages = {}
end
local function trimChatMessages()
    while #chatMessages > CHAT_MAX * 3 do
        local element = table.remove(chatMessages, 1)
        if element and element.Destroy then
            pcall(function() element:Destroy() end)
        end
    end
end
function addChatMessage(sender, text)
    local messageText = sender .. ": " .. text
    local messageLabel = chatReceiverTab:AddLabel(messageText)
    table.insert(chatMessages, messageLabel)
    local copyButton = chatReceiverTab:AddButton({
        Text = "📋 复制这条消息",
        Callback = function()
            local fullText = sender .. ": " .. text
            setclipboard(fullText)
            ChronixUI:Notify({ Title = "已复制", Content = "消息已复制到剪贴板", Type = "info", Duration = 2 })
        end
    })
    table.insert(chatMessages, copyButton)
    local divider = chatReceiverTab:AddDivider()
    table.insert(chatMessages, divider)
    trimChatMessages()
end
chatReceiverTab:AddTitle("📨 聊天接收器")
chatReceiverTab:AddDivider()
chatReceiverTab:AddLabel("实时接收游戏中所有玩家的聊天消息")
chatReceiverTab:AddDivider()
chatReceiverTab:AddTitle("消息列表")
chatReceiverTab:AddButton({
    Text = "🗑️ 清空所有消息",
    Callback = function()
        clearChatMessages()
        ChronixUI:Notify({ Title = "已清空", Content = "所有聊天消息已清除", Type = "info", Duration = 1 })
    end
})
chatReceiverTab:AddDivider()
chatReceiverTab:AddLabel("💡 提示：点击消息下方的按钮可复制该条消息")


-- ===== 滤镜控制器 Tab =====
filterTab = mainWindow:CreateTab({ Name = "滤镜控制器", HasIcon = true, IconName = "sparkles" })
dynamicControls = {}
staticControls = {}
function refreshFilterList(showNotification)
    for _, control in ipairs(dynamicControls) do
        if control and control.Destroy then
            pcall(function() control:Destroy() end)
        end
    end
    dynamicControls = {}
    local allEffects = getAllPostEffects()
    local colorCorrection = getColorCorrectionEffect()
    if #allEffects == 0 then
        local noEffectLabel = filterTab:AddLabel("未检测到任何后处理特效")
        table.insert(dynamicControls, noEffectLabel)
        return
    end
    local titleLabel = filterTab:AddTitle("后处理特效开关")
    table.insert(dynamicControls, titleLabel)
    for _, effect in ipairs(allEffects) do
        local displayName = string.format("%s (%s)", effect.Name, effect.ClassName)
        local toggle = filterTab:AddToggle({
            Label = displayName,
            Default = effect.Enabled,
            Callback = function(enabled)
                effect.Enabled = enabled
                local status = enabled and "启用" or "禁用"
                ChronixUI:Notify({ Title = "滤镜状态", Content = effect.Name .. " 已" .. status, Type = enabled and "success" or "info", Duration = 2 })
            end
        })
        table.insert(dynamicControls, toggle)
    end
    if colorCorrection then
        local divider = filterTab:AddDivider()
        table.insert(dynamicControls, divider)
        local colorTitle = filterTab:AddTitle("颜色微调")
        table.insert(dynamicControls, colorTitle)
        local saturationSlider = filterTab:AddSlider({
            Label = "饱和度 (Saturation)", Min = -1, Max = 1, Default = colorCorrection.Saturation,
            Callback = function(value) colorCorrection.Saturation = value end
        })
        table.insert(dynamicControls, saturationSlider)
        local brightnessSlider = filterTab:AddSlider({
            Label = "亮度 (Brightness)", Min = -1, Max = 1, Default = colorCorrection.Brightness,
            Callback = function(value) colorCorrection.Brightness = value end
        })
        table.insert(dynamicControls, brightnessSlider)
        local contrastSlider = filterTab:AddSlider({
            Label = "对比度 (Contrast)", Min = -1, Max = 1, Default = colorCorrection.Contrast,
            Callback = function(value) colorCorrection.Contrast = value end
        })
        table.insert(dynamicControls, contrastSlider)
        local tintColorPicker = filterTab:AddColorPicker({
            Label = "色调颜色 (TintColor)", Default = colorCorrection.TintColor,
            Callback = function(color) colorCorrection.TintColor = color end
        })
        table.insert(dynamicControls, tintColorPicker)
    end
    local resetDivider = filterTab:AddDivider()
    table.insert(dynamicControls, resetDivider)
    local resetButton = filterTab:AddButton({
        Text = "重置所有滤镜为默认状态",
        Callback = function()
            for _, effect in ipairs(getAllPostEffects()) do
                effect.Enabled = true
                if effect:IsA("ColorCorrectionEffect") then
                    effect.Saturation = 0
                    effect.Brightness = 0
                    effect.Contrast = 0
                    effect.TintColor = Color3.new(1, 1, 1)
                end
            end
            ChronixUI:Notify({ Title = "滤镜控制器", Content = "所有滤镜已重置为默认状态", Type = "success", Duration = 3 })
            refreshFilterList(true)
        end
    })
    table.insert(dynamicControls, resetButton)
    local colorBlindDivider = filterTab:AddDivider()
    table.insert(dynamicControls, colorBlindDivider)
    local colorBlindTitle = filterTab:AddTitle("🎨 色盲模拟器")
    table.insert(dynamicControls, colorBlindTitle)
    local colorBlindModes = {
        { name = "正常", config = { Saturation = 0, Brightness = 0, Contrast = 0, TintColor = Color3.new(1, 1, 1) } },
        { name = "红色弱", config = { Saturation = -0.3, Brightness = 0, Contrast = 0.1, TintColor = Color3.new(0.85, 1, 1) } },
        { name = "红色盲", config = { Saturation = -0.5, Brightness = 0, Contrast = 0.2, TintColor = Color3.new(0.7, 1, 1) } },
        { name = "绿色弱", config = { Saturation = -0.3, Brightness = 0, Contrast = 0.1, TintColor = Color3.new(1, 0.85, 1) } },
        { name = "绿色盲", config = { Saturation = -0.5, Brightness = 0, Contrast = 0.2, TintColor = Color3.new(1, 0.7, 1) } },
        { name = "蓝色弱", config = { Saturation = -0.3, Brightness = 0.1, Contrast = 0.1, TintColor = Color3.new(1, 1, 0.85) } },
        { name = "蓝色盲", config = { Saturation = -0.5, Brightness = 0.1, Contrast = 0.2, TintColor = Color3.new(1, 1, 0.7) } },
        { name = "全色弱", config = { Saturation = -0.8, Brightness = 0, Contrast = 0.3, TintColor = Color3.new(0.9, 0.9, 0.9) } },
        { name = "全色盲", config = { Saturation = -1, Brightness = 0, Contrast = 0.5, TintColor = Color3.new(0.8, 0.8, 0.8) } },
    }
    local currentColorBlindMode = "正常"
    local function applyColorBlindMode(modeConfig)
        local colorCorrection = getColorCorrectionEffect()
        if not colorCorrection then
            colorCorrection = Instance.new("ColorCorrectionEffect")
            colorCorrection.Name = "THub_ColorCorrection"
            colorCorrection.Parent = Lighting
        end
        colorCorrection.Enabled = true
        colorCorrection.Saturation = modeConfig.Saturation
        colorCorrection.Brightness = modeConfig.Brightness
        colorCorrection.Contrast = modeConfig.Contrast
        colorCorrection.TintColor = modeConfig.TintColor
    end
    local modeNames = {}
    for _, mode in ipairs(colorBlindModes) do
        table.insert(modeNames, mode.name)
    end
    local colorBlindDropdown = filterTab:AddDropdown({
        Label = "选择色盲模式",
        Options = modeNames,
        Default = "正常",
        Callback = function(selected)
            currentColorBlindMode = selected
            for _, mode in ipairs(colorBlindModes) do
                if mode.name == selected then
                    applyColorBlindMode(mode.config)
                    ChronixUI:Notify({ Title = "色盲模拟器", Content = "已切换到: " .. selected, Type = "info", Duration = 2 })
                    break
                end
            end
        end
    })
    table.insert(dynamicControls, colorBlindDropdown)
    local colorBlindNote = filterTab:AddLabel("💡 选择一种色盲模式来模拟对应的视觉体验")
    table.insert(dynamicControls, colorBlindNote)
    if mainWindow.RefreshContent then
        mainWindow:RefreshContent()
    end
    if showNotification == true then
        ChronixUI:Notify({ Title = "滤镜控制器", Content = "已刷新，找到 " .. #allEffects .. " 个特效", Type = "success", Duration = 2 })
    end
end
local refreshButton = filterTab:AddButton({
    Text = "手动刷新滤镜列表",
    Callback = function()
        refreshFilterList(true)
    end
})
table.insert(staticControls, refreshButton)
local staticDivider = filterTab:AddDivider()
table.insert(staticControls, staticDivider)
refreshFilterList(false)

-- ===== 自定义称号 Tab =====
playertitleTab = mainWindow:CreateTab({ Name = "自定义称号", HasIcon = true, IconName = "tag" })
playertitleTab:AddTitle("自定义你的称号")
playertitleTab:AddToggle({
    Label = "功能开关",
    Default = false,
    Callback = function(v)
        if v then
            data["basicdata"]["otherdata"]["playertitle"]["tag"]:enable()
        else
            data["basicdata"]["otherdata"]["playertitle"]["tag"]:disable()
        end
    end
})
playertitleTab:AddInput({
    Label = "称号文本",
    Placeholder = "",
    Default = data["basicdata"]["otherdata"]["playertitle"]["text"],
    Callback = function(text)
        data["basicdata"]["otherdata"]["playertitle"]["text"] = text
    end
})
playertitleTab:AddColorPicker({
    Label = "称号颜色",
    Default = hexToColor3(data["basicdata"]["otherdata"]["playertitle"]["color"]),
    Callback = function(color)
        data["basicdata"]["otherdata"]["playertitle"]["color"] = color3ToHex(color)
    end
})
playertitleTab:AddSlider({
    Label = "字号",
    Min = 1, Max = 50, Default = data["basicdata"]["otherdata"]["playertitle"]["size"],
    Callback = function(v) data["basicdata"]["otherdata"]["playertitle"]["size"] = v end
})
playertitleTab:AddToggle({
    Label = "加粗",
    Default = false,
    Callback = function(v) data["basicdata"]["otherdata"]["playertitle"]["bold"] = v end
})
playertitleTab:AddToggle({
    Label = "倾斜",
    Default = false,
    Callback = function(v) data["basicdata"]["otherdata"]["playertitle"]["italic"] = v end
})
playertitleTab:AddInput({
    Label = "字体",
    Placeholder = "",
    Default = data["basicdata"]["otherdata"]["playertitle"]["font"],
    Callback = function(text)
        data["basicdata"]["otherdata"]["playertitle"]["font"] = text
    end
})
playertitleTab:AddButton({
    Text = "应用更改",
    Callback = function()
        data["basicdata"]["otherdata"]["playertitle"]["tag"]:update({
            text = data["basicdata"]["otherdata"]["playertitle"]["text"],
            color = data["basicdata"]["otherdata"]["playertitle"]["color"],
            size = data["basicdata"]["otherdata"]["playertitle"]["size"],
            bold = data["basicdata"]["otherdata"]["playertitle"]["bold"],
            italic = data["basicdata"]["otherdata"]["playertitle"]["italic"],
            font = data["basicdata"]["otherdata"]["playertitle"]["font"],
        })
    end
})

-- ===== 服务器查询 Tab =====
serverQuery = ServerFinderModule.new()
serverTab = mainWindow:CreateTab({ Name = "服务器查询", HasIcon = true, IconName = "server" })
serverTab:AddTitle("公共服务器列表")
serverUIElements = {}
function clearServerList()
    for _, elementList in ipairs(serverUIElements) do
        for _, element in ipairs(elementList) do
            if element and element.Destroy then
                element:Destroy()
            end
        end
    end
    table.clear(serverUIElements)
end
isRefreshing = false
function refreshServerList()
    if isRefreshing then
        ChronixUI:Notify({ Title = "提示", Content = "正在刷新中，请稍候...", Type = "warning", Duration = 2 })
        return
    end
    clearServerList()
    isRefreshing = true
    local loadingLabel = serverTab:AddLabel("⏳ 正在获取服务器列表...")
    table.insert(serverUIElements, {loadingLabel})
    serverQuery:refreshAsync(function(servers)
        isRefreshing = false
        if loadingLabel and loadingLabel.Destroy then
            loadingLabel:Destroy()
        end
        clearServerList()
        if #servers == 0 then
            local emptyLabel = serverTab:AddLabel("⚠️ 没有找到公共服务器，或 API 出错。")
            table.insert(serverUIElements, {emptyLabel})
            return
        end
        local infoLabel = serverTab:AddLabel("点击下方按钮可加入对应服务器")
        table.insert(serverUIElements, {infoLabel})
        local divider1 = serverTab:AddDivider()
        table.insert(serverUIElements, {divider1})
        for _, serverData in ipairs(servers) do
            local entryElements = {}
            local players = serverData.playing or 0
            local maxPlayers = serverData.maxPlayers or 0
            local ping = serverData.ping or 0
            local fps = ping > 0 and math.floor(1000 / ping) or 0
            local quality = "普通"
            if ping > 250 then quality = "差"
            elseif ping < 100 then quality = "好"
            end
            local infoText = string.format("玩家: %d/%d | Ping: %dms | 质量: %s", players, maxPlayers, ping, quality)
            local sInfoLabel = serverTab:AddLabel(infoText)
            table.insert(entryElements, sInfoLabel)
            local idLabel = serverTab:AddLabel("ID: " .. tostring(serverData.id))
            table.insert(entryElements, idLabel)
            local joinBtn = serverTab:AddButton({
                Text = "🚀 加入此服务器",
                Callback = function()
                    local ok, err = pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, serverData.id, LocalPlayer)
                    end)
                    if not ok then
                        ChronixUI:Notify({ Title = "传送失败", Content = "无法加入服务器: " .. tostring(err), Type = "error", Duration = 3 })
                    end
                end
            })
            table.insert(entryElements, joinBtn)
            local sDivider = serverTab:AddDivider()
            table.insert(entryElements, sDivider)
            table.insert(serverUIElements, entryElements)
        end
        if mainWindow.RefreshContent then
            mainWindow:RefreshContent()
        end
    end)
end
serverTab:AddButton({
    Text = "🔄 刷新服务器列表",
    Callback = function()
        refreshServerList()
    end
})
serverTab:AddDivider()
serverTab:AddLabel("💡 点击刷新按钮获取当前游戏的公共服务器")
serverTab:AddLabel("⚠️ 服务器数据来自 Roblox 官方 API，可能会有延迟")
refreshServerList()

-- ===== 恶劣功能 Tab =====
hankerTab = mainWindow:CreateTab({ Name = "恶劣功能", HasIcon = true, IconName = "shield-alert" })
hankerTab:AddTitle("使用此部分的功能会导致封号")
hankerTab:AddDivider()
hankerTab:AddLabel("普通功能")
enableToggle(hankerTab, "循环OOF", function() LoopOofModule.enable() end, function() LoopOofModule.disable() end)
hankerTab:AddButton({ Text = "获得打飞机工具", Callback = function() getjerktool() end })
hankerTab:AddDivider()
hankerTab:AddLabel("背起了行囊")
hankerTab:AddInput({
    Label = "旋转速度",
    Placeholder = "",
    Default = 20,
    Callback = function(text)
        data["basicdata"]["hankermodule"]["spin"]["speed"] = tonumber(text)
        if SpinModule.isEnabled() then SpinModule.setSpeed(data["basicdata"]["hankermodule"]["spin"]["speed"]) end
    end
})
enableToggle(hankerTab, "开始旋转", function() SpinModule.enable(data["basicdata"]["hankermodule"]["spin"]["speed"]) end, function() SpinModule.disable() end)
hankerTab:AddDivider()
hankerTab:AddLabel("击飞功能")
enableToggle(hankerTab, "旋转击飞(Ctrl+G)", function() FlingModule.fling.setShortcutEnabled(true) end, function() FlingModule.fling.setShortcutEnabled(false) end)
enableToggle(hankerTab, "飞行击飞", function() FlingModule.flyfling.enable(2) end, function() FlingModule.flyfling.disable() end)
enableToggle(hankerTab, "走路击飞", function() FlingModule.walkfling.enable() end, function() FlingModule.walkfling.disable() end)
enableToggle(hankerTab, "隐身击飞", function() FlingModule.invisfling.enable() end, function() FlingModule.invisfling.disable() end)
hankerTab:AddDivider()
hankerTab:AddLabel("击杀玩家")
hankerTab:AddInput({
    Label = "要击杀的玩家名",
    Placeholder = "",
    Default = "PlayerName",
    Callback = function(text)
        data["basicdata"]["hankermodule"]["hkill"]["killname"] = text
    end
})
hankerTab:AddInput({
    Label = "距离",
    Placeholder = "",
    Default = 100,
    Callback = function(text)
        data["basicdata"]["hankermodule"]["hkill"]["killrange"] = tonumber(text) or 100
    end
})
hankerTab:AddToggle({
    Label = "全部玩家",
    Default = false,
    Callback = function(v) data["basicdata"]["hankermodule"]["hkill"]["killall"] = v end
})
hankerTab:AddToggle({
    Label = "全图",
    Default = false,
    Callback = function(v) data["basicdata"]["hankermodule"]["hkill"]["killany"] = v end
})
hankerTab:AddButton({ Text = "开始击杀", Callback = function()
    HandleKillModule.kill(data["basicdata"]["hankermodule"]["hkill"]["killall"] and "All" or data["basicdata"]["hankermodule"]["hkill"]["killname"], data["basicdata"]["hankermodule"]["hkill"]["killany"] and "Infinity" or data["basicdata"]["hankermodule"]["hkill"]["killrange"])
end })
hankerTab:AddDivider()
hankerTab:AddLabel("甩飞传送")
hankerTab:AddDivider()

local function executeFlingTeleport(player)
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then
        ChronixUI:Notify({ Title = "错误", Content = "无法获取你的角色", Type = "error", Duration = 2 })
        return
    end
    local targetChar = player.Character
    if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then
        ChronixUI:Notify({ Title = "错误", Content = "目标玩家角色不存在", Type = "error", Duration = 2 })
        return
    end
    local originalPos = myChar.HumanoidRootPart.CFrame
    local root = myChar.HumanoidRootPart
    myChar:SetPrimaryPartCFrame(CFrame.new(targetChar.HumanoidRootPart.Position))
    local humanoid = myChar:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.PlatformStand = true end
    for _, child in pairs(myChar:GetDescendants()) do
        if child:IsA("BasePart") then
            child.CanCollide = true
            child.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.3, 0.5)
        end
    end
    local angVel = Instance.new("BodyAngularVelocity")
    angVel.Name = "__FlingTeleportVelocity"
    angVel.Parent = root
    angVel.AngularVelocity = Vector3.new(99999, 99999, 99999)
    angVel.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    angVel.P = math.huge
    local bodyPos = Instance.new("BodyPosition")
    bodyPos.Name = "__FlingTeleportPos"
    bodyPos.Parent = root
    bodyPos.Position = targetChar.HumanoidRootPart.Position
    bodyPos.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyPos.D = 100
    bodyPos.P = 5000
    local steppedConn = RunService.Stepped:Connect(function()
        if not myChar or not myChar.Parent then return end
        for _, child in pairs(myChar:GetDescendants()) do
            if child:IsA("BasePart") and child.CanCollide == false then
                child.CanCollide = true
            end
        end
    end)
    local upDownConn = RunService.Heartbeat:Connect(function()
        if not myChar or not myChar.Parent or not root or not root.Parent then return end
        local osc = math.sin(tick() * 12) * 5
        root.Velocity = Vector3.new(root.Velocity.X, osc, root.Velocity.Z)
    end)
    local ok = pcall(task.wait, 1.5)
    steppedConn:Disconnect()
    upDownConn:Disconnect()
    if angVel and angVel.Parent then angVel:Destroy() end
    if bodyPos and bodyPos.Parent then bodyPos:Destroy() end
    if humanoid then humanoid.PlatformStand = false end
    if myChar and myChar.Parent then
        for _, child in pairs(myChar:GetDescendants()) do
            if child:IsA("BasePart") then
                child.CanCollide = true
                child.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
            end
        end
        if myChar:FindFirstChild("HumanoidRootPart") then
            myChar:SetPrimaryPartCFrame(originalPos)
        end
    end
end

local flingTeleportDropdown = nil
local flingTeleportPlayerMap = {}
local function getPlayerOptions()
    local names = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local label = player.DisplayName .. " (" .. player.Name .. ")"
            table.insert(names, label)
            flingTeleportPlayerMap[label] = player
        end
    end
    return names
end
flingTeleportDropdown = hankerTab:AddDropdown({
    Label = "选择要甩飞的玩家",
    Options = getPlayerOptions(),
    Default = "",
    Callback = function(selected)
        local player = flingTeleportPlayerMap[selected]
        if player then executeFlingTeleport(player) end
    end
})
function updateFlingTeleportPlayerList()
    if flingTeleportDropdown then
        local options = getPlayerOptions()
        flingTeleportDropdown:UpdateOptions(options)
    end
end

-- ===== 支持的游戏 Tab =====
supportedgamesTab = mainWindow:CreateTab({ Name = "支持的游戏", HasIcon = true, IconName = "swords" })
supportedgamesTab:AddTitle("支持的游戏")
for _, GetgameInfo in ipairs(data["Supported_Games"]) do
    if GetgameInfo.gameid then
        supportedgamesTab:AddButton({ Text = GetgameInfo.name .. "(点击进入)", Callback = function() if game.GameId == GetgameInfo.gameid then ChronixUI:Notify({ Title = "提示", Content = "你已经在这个游戏里了。", Type = "warning", Duration = 5 }) else GameTeleport.teleportByGameId(GetgameInfo.gameid) end end })
    end
end

-- ===== 执行器查询 Tab =====
weaoapiTab = mainWindow:CreateTab({ Name = "执行器查询", HasIcon = true, IconName = "section" })
weaoapiTab:AddTitle("Roblox版本")
local robloxLabels = {
    win = weaoapiTab:AddLabel("Windows: 加载中..."),
    winDate = weaoapiTab:AddLabel("Windows更新日期: 加载中..."),
    mac = weaoapiTab:AddLabel("Mac: 加载中..."),
    macDate = weaoapiTab:AddLabel("Mac更新日期: 加载中..."),
    android = weaoapiTab:AddLabel("Android: 加载中..."),
    androidDate = weaoapiTab:AddLabel("Android更新日期: 加载中..."),
    ios = weaoapiTab:AddLabel("iOS: 加载中..."),
    iosDate = weaoapiTab:AddLabel("iOS更新日期: 加载中..."),
}
weaoapiTab:AddDivider()
weaoapiTab:AddTitle("执行器状态")
local executorsTitle = weaoapiTab:AddTitle("加载中...")
local function rebuildExploiters()
    local ok, executors = pcall(parseExecutors, data["basicdata"]["otherdata"]["executordetecter"]["exploits"])
    if not ok or #executors == 0 then return end
    executorsTitle:Destroy()
    for _, exec in ipairs(executors) do
        weaoapiTab:AddTitle(string.format("[%s] %s (%s) | %s", exec.platform, exec.title, exec.version, exec.updateStatus and "已更新(有效)" or "未更新(失效)"))
        weaoapiTab:AddLabel("类型:" .. exec.extType .. " | " .. (exec.free and "免费" or ("付费(" .. exec.cost:gsub("Lifetime", "永久"):gsub("Weekly", "每周"):gsub("Monthly", "每月"):gsub("Private", "私人") .. ")")) .. " | " .. (exec.detected and "已被检测" or "未被检测"))
        weaoapiTab:AddLabel((exec.uncStatus and ("UNC: " .. (exec.uncPercent or 0) .. "%") or "") .. ", sUNC: " .. (exec.suncPercent or 0) .. "%")
        weaoapiTab:AddLabel("更新时间:" .. exec.updatedDate)
        weaoapiTab:AddLabel("密钥系统: " .. (exec.keysystem and "有" or "无") .. " 测试版:" .. (exec.beta and "是" or "否") .. " 反编译器: " .. (exec.decompiler and "有" or "无") .. " 多开支持: " .. (exec.multiInject and "支持" or "不支持"))
        weaoapiTab:AddButton({
            Text = "官网: " .. exec.website,
            Callback = function() setclipboard(exec.website); ChronixUI:Notify({ Title = "提示", Content = "已复制到剪切板", Type = "info", Duration = 5 }) end
        })
        weaoapiTab:AddButton({
            Text = "Discord: " .. exec.discord,
            Callback = function() setclipboard(exec.discord); ChronixUI:Notify({ Title = "提示", Content = "已复制到剪切板", Type = "info", Duration = 5 }) end
        })
        weaoapiTab:AddDivider()
    end
end
task.spawn(function()
    while true do
        local rd = data["basicdata"]["otherdata"]["executordetecter"]["robloxinfo"]
        if rd.Windows then
            robloxLabels.win.Text = "Windows: " .. rd.Windows
            robloxLabels.winDate.Text = "Windows更新日期: " .. toChineseDate(rd.WindowsDate, true)
            robloxLabels.mac.Text = "Mac: " .. rd.Mac
            robloxLabels.macDate.Text = "Mac更新日期: " .. toChineseDate(rd.MacDate, true)
            robloxLabels.android.Text = "Android: " .. rd.Android
            robloxLabels.androidDate.Text = "Android更新日期: " .. toChineseDate(rd.AndroidDate, true)
            robloxLabels.ios.Text = "iOS: " .. rd.iOS
            robloxLabels.iosDate.Text = "iOS更新日期: " .. toChineseDate(rd.iOSDate, true)
            break
        end
        task.wait(1)
    end
end)
task.spawn(function()
    while true do
        local ex = data["basicdata"]["otherdata"]["executordetecter"]["exploits"]
        if ex and type(ex) == "table" and #ex > 0 then
            rebuildExploiters()
            break
        end
        task.wait(1)
    end
end)

-- ===== 游戏专属标签页 =====
for _, GetgameInfo in ipairs(data["Supported_Games"]) do
    if GetgameInfo.gameid == game.GameId then
        local OtherGameTab = mainWindow:CreateTab({ Name = GetgameInfo.name, HasIcon = true, IconName = "gamepad-2" })
        OtherGameTab:AddTitle(GetgameInfo.name)
        if GetgameInfo.name == "死亡球" then
            OtherGameTab:AddToggle({
                Label = "主功能和界面",
                Default = false,
                Callback = function(v) if v then _G.DeathBallScript:Enable() else _G.DeathBallScript:Disable() end end
            })
        elseif GetgameInfo.name == "小屋角色扮演" then
            OtherGameTab:AddButton({ Text = "变正常", Callback = function() ChatControl:chat("/re") end })
            OtherGameTab:AddButton({ Text = "变小孩", Callback = function() ChatControl:chat("/kid") end })
            OtherGameTab:AddButton({ Text = "鲨鱼服装", Callback = function() ChatControl:chat("/shark") end })
            OtherGameTab:AddButton({ Text = "修狗服装", Callback = function() ChatControl:chat("/dog") end })
            OtherGameTab:AddButton({ Text = "修猫服装", Callback = function() ChatControl:chat("/cat") end })
        elseif GetgameInfo.name == "南极探险队" then
            OtherGameTab:AddLabel("基础操作")
            OtherGameTab:AddButton({ Text = "传送到 大本营", Callback = function() TeleportTo(-6015, -158, -35) end })
            OtherGameTab:AddButton({ Text = "传送到 营地1", Callback = function() TeleportTo(-3719, 226, 235) end })
            OtherGameTab:AddButton({ Text = "传送到 营地2", Callback = function() TeleportTo(1790, 106, -138) end })
            OtherGameTab:AddButton({ Text = "传送到 营地3", Callback = function() TeleportTo(5892, 321, -18) end })
            OtherGameTab:AddButton({ Text = "传送到 营地4", Callback = function() TeleportTo(8992, 596, 102) end })
            OtherGameTab:AddButton({ Text = "传送到 营地5", Callback = function() TeleportTo(10990, 550, 104) end })
            OtherGameTab:AddLabel("圣诞活动")
            OtherGameTab:AddButton({ Text = "获取所有礼物", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/SouthExpedition_Christmas_getallgifts.lua"))() end })
            OtherGameTab:AddInput({
                Label = "礼物号",
                Placeholder = "",
                Callback = function(text)
                    data["othergamedata"]["AntarcticExpedition"]["giftnumber"] = text
                end
            })
            OtherGameTab:AddButton({ Text = "传送到礼物", Callback = function() TeleportToPresent(tonumber(data["othergamedata"]["AntarcticExpedition"]["giftnumber"])) end })
        elseif GetgameInfo.name == "西部森林" then
            enableToggle(OtherGameTab, "怪物标签", function() data["othergamedata"]["west_wood"]["monster"]:enable() end, function() data["othergamedata"]["west_wood"]["monster"]:disable() end)
        elseif GetgameInfo.name == "警笛头:遗产" then
            local sl = data["othergamedata"]["sirenhead_legacy"]
            enableToggle(OtherGameTab, "透视盒子", function() sl.cratemodule.apply(); sl.cratenametagmodule:enable() end, function() sl.cratemodule.destroy(); sl.cratenametagmodule:disable() end)
            enableToggle(OtherGameTab, "透视浆果", function() sl.berrymodule.apply(); sl.berynametagmodule:enable() end, function() sl.berrymodule.destroy(); sl.berynametagmodule:disable() end)
            OtherGameTab:AddButton({ Text = "传送到树顶", Callback = function() TeleportTo(69, 206, -72) end })
        elseif GetgameInfo.name == "噩梦之行" then
            enableToggle(OtherGameTab, "高亮怪物", function() data["othergamedata"]["nightmare_run"]["monster"]:enable() end, function() data["othergamedata"]["nightmare_run"]["monster"]:disable() end)
            OtherGameTab:AddButton({ Text = "高亮芝士", Callback = function() data["othergamedata"]["nightmare_run"]["HLCheese"].apply() end })
            OtherGameTab:AddButton({ Text = "无敌(怪物不追不杀)", Callback = function()
                local ClientScripts = PlayerGui.ClientScripts
                local Events = ReplicatedStorage.Events
                if ClientScripts:FindFirstChild("SafeSpaceHandler") then
                    ClientScripts.SafeSpaceHandler:Destroy()
                end
                LocalPlayer:SetAttribute("Safe", true)
                Events.SetAttributeEvent:FireServer("Safe", true)
                ChronixUI:Notify({ Title = "提示", Content = "已设置玩家安全状态\n死亡前生效", Type = "info", Duration = 5 })
            end })
        elseif GetgameInfo.name == "兽化项目" then
            OtherGameTab:AddLabel("基础操作")
            local function deleteModelsByName(modelName, displayName)
                local deletedCount = 0
                for _, model in ipairs(Workspace:GetDescendants()) do
                    if model:IsA("Model") and model.Name == modelName then
                        model:Destroy()
                        deletedCount = deletedCount + 1
                    end
                end
                ChronixUI:Notify({ Title = "提示", Content = "已删除" .. deletedCount .. "个" .. displayName, Type = "info", Duration = 10 })
            end
            OtherGameTab:AddButton({ Text = "删除捕兽夹", Callback = function() deleteModelsByName("__SnarePhysical", "捕兽夹") end })
            OtherGameTab:AddButton({ Text = "删除地雷", Callback = function() deleteModelsByName("Landmine", "地雷") end })
            OtherGameTab:AddButton({ Text = "删除阔剑地雷", Callback = function() deleteModelsByName("__ClaymorePhysical", "阔剑地雷") end })
            OtherGameTab:AddLabel("透视功能")
            local pt = data["othergamedata"]["project_transfur"]
            enableToggle(OtherGameTab, "Bot兽", function() pt.bot.apply(); pt.botnt:enable() end, function() pt.bot.destroy(); pt.botnt:disable() end)
            enableToggle(OtherGameTab, "小保险箱", function() pt.smallsafe.apply(); pt.smallsafent:enable() end, function() pt.smallsafe.destroy(); pt.smallsafent:disable() end)
            enableToggle(OtherGameTab, "大保险箱", function() pt.largesafe.apply(); pt.largesafent:enable() end, function() pt.largesafe.destroy(); pt.largesafent:disable() end)
            enableToggle(OtherGameTab, "金保险箱", function() pt.goldensafe.apply(); pt.goldensafent:enable() end, function() pt.goldensafe.destroy(); pt.goldensafent:disable() end)
            enableToggle(OtherGameTab, "武器盒", function() pt.crate.apply(); pt.cratent:enable() end, function() pt.crate.destroy(); pt.cratent:disable() end)
            enableToggle(OtherGameTab, "空投", function() pt.sd.apply(); pt.sdnt:enable() end, function() pt.sd.destroy(); pt.sdnt:disable() end)
        elseif GetgameInfo.name == "妄想办公室" then
            OtherGameTab:AddToggle({
                Label = "实体警告",
                Default = false,
                Callback = function(v) if v then enableEntityWarning() else disableEntityWarning() end end
            })
            OtherGameTab:AddToggle({
                Label = "提醒他人",
                Default = false,
                Callback = function(v) data["othergamedata"]["delesions_office"]["tipotherplayer"] = v end
            })
            OtherGameTab:AddToggle({
                Label = "自动EN-013",
                Default = false,
                Callback = function(v) if v then enableAuto013() else disableAuto013() end end
            })
        elseif GetgameInfo.name == "格蕾丝" then
            OtherGameTab:AddToggle({
                Label = "自动拉杆",
                Default = false,
                Callback = function(v) if v then enableAutoLever() else disableAutoLever() end end
            })
            OtherGameTab:AddButton({ Text = "删除全部实体(无法关闭)", Callback = function() enableDeleteEntity() end })
        elseif GetgameInfo.name == "深渊" then
            OtherGameTab:AddButton({ Text = "一键获取全地图深渊能量和回音", Callback = function()
                OBOTeleportModule.TeleportToParts({"AbyssalEnergy", "BigAbyssalEnergy", "Echo"}, 0.01)
            end })
            OtherGameTab:AddButton({ Text = "一键解锁全地图路径点", Callback = function()
                OBOTeleportModule.TeleportToParts("SpawnLocation", 0.1)
            end })
            OtherGameTab:AddButton({ Text = "传送到 灯笼商店", Callback = function() TeleportTo(-375, -11932, -504) end })
        elseif GetgameInfo.name == "后院生存" then
            OtherGameTab:AddLabel("透视功能")
            local bs = data["othergamedata"]["backroomsurvival"]
            enableToggle(OtherGameTab, "窃皮者", function() bs.SkinStealer.apply(); bs.SkinStealernt:enable() end, function() bs.SkinStealer.destroy(); bs.SkinStealernt:disable() end)
            enableToggle(OtherGameTab, "瞎子", function() bs.Shrieker.apply(); bs.Shriekernt:enable() end, function() bs.Shrieker.destroy(); bs.Shriekernt:disable() end)
            enableToggle(OtherGameTab, "悲尸", function() bs.Wretch.apply(); bs.Wretchnt:enable() end, function() bs.Wretch.destroy(); bs.Wretchnt:disable() end)
            enableToggle(OtherGameTab, "梦魇", function() bs.Phantom.apply(); bs.Phantomnt:enable() end, function() bs.Phantom.destroy(); bs.Phantomnt:disable() end)
            enableToggle(OtherGameTab, "细菌", function() bs.Bacteria.apply(); bs.Bacteriant:enable() end, function() bs.Bacteria.destroy(); bs.Bacteriant:disable() end)
            enableToggle(OtherGameTab, "侦察兵", function() bs.Recon.apply(); bs.Reconnt:enable() end, function() bs.Recon.destroy(); bs.Reconnt:disable() end)
            enableToggle(OtherGameTab, "修理工", function() bs.Mechanic.apply(); bs.Mechanicnt:enable() end, function() bs.Mechanic.destroy(); bs.Mechanicnt:disable() end)
        elseif GetgameInfo.name == "最黑暗的时刻" then
            OtherGameTab:AddLabel("透视功能")
            local dh = data["othergamedata"]["DarkestHours"]
            enableToggle(OtherGameTab, "收集物", function() dh.Collectible.apply(); dh.Collectiblent:enable() end, function() dh.Collectible.destroy(); dh.Collectiblent:disable() end)
        elseif GetgameInfo.name == "后悔电梯" then
            OtherGameTab:AddLabel("通用")
            enableToggle(OtherGameTab, "自动舔冰淇凌（确保快捷栏中有冰淇凌）", function() Regretevator_AutoIceCream:enable() end, function() Regretevator_AutoIceCream:disable() end)
            local rg = data["othergamedata"]["Regretevator"]
            enableToggle(OtherGameTab, "透视硬币", function() rg.coins.apply(); rg.coinsnt:enable() end, function() rg.coins.destroy(); rg.coinsnt:disable() end)
            OtherGameTab:AddLabel("Bugbo楼层")
            enableToggle(OtherGameTab, "透视石头", function() rg.bugbo_rocks.apply(); rg.bugbo_rocksnt:enable() end, function() rg.bugbo_rocks.destroy(); rg.bugbo_rocksnt:disable() end)
            OtherGameTab:AddLabel("森林营地楼层")
            enableToggle(OtherGameTab, "透视木头", function() rg.firewood.apply(); rg.firewoodnt:enable() end, function() rg.firewood.destroy(); rg.firewoodnt:disable() end)
        end
    end
end

-- ===== 关于 Tab =====
infoTab = mainWindow:CreateTab({ Name = "关于", HasIcon = true, IconName = "info" })
infoTab:AddParagraph({
    Title = "关于 THub V3",
    Content = "THub V3 是一个功能强大的 Roblox 多功能工具集\n\n"
    .. "开发者: Furrycalin和0988\n"
    .. "版本: V3\n"
    .. "框架: 基于ChronixUI fork 库构建\n\n"
    .. "注意事项:\n"
    .. "• 请合理使用各项功能\n"
    .. "• 部分功能可能在游戏中被检测\n"
    .. "• 使用前请了解游戏规则"
})
infoTab:AddDivider()
local hwidlabel
if gethwid then hwidlabel = infoTab:AddLabel(string.format("设备唯一标识码(HWID): %s", maskStringMiddle(gethwid()))) end
rbxactivelabel = nil
if isrbxactive then rbxactivelabel = infoTab:AddLabel(string.format("焦点检测: %s", (isrbxactive() and "True" or "False"))) end
pingLabel = infoTab:AddLabel(string.format("网络延迟: %s", math.round(LocalPlayer:GetNetworkPing() * 1000) .. "ms"))
memLabel = infoTab:AddLabel(string.format("客户端脚本占用内存: %.2f MB", getMemoryUsage("MB")))
infoTab:AddButton({ Text = "强制内存垃圾回收", Callback = function()
    collectgarbage("collect")
    ChronixUI:Notify({ Title = "提示", Content = "已进行垃圾回收\n请不要频繁使用，可能会影响性能。", Type = "info", Duration = 5 })
end })
infoTab:AddLabel(data["basicdata"]["otherdata"]["yiyan"]["data"]["hitokoto"])

-- ===== 设置内容 =====
settingsContent = mainWindow.SettingsElements
settingsContent:AddInput({
    Label = "Roblox - 缩放倍率",
    Placeholder = "这里输入你的视角倍率",
    Default = LocalPlayer.CameraMaxZoomDistance,
    Callback = function(text)
        local num = tonumber(text)
        if num then
            LocalPlayer.CameraMaxZoomDistance = num
        end
    end
})
if getfpscap and setfpscap then
    settingsContent:AddInput({
        Label = "Roblox - 帧率上限",
        Placeholder = "这里输入你的最大帧率",
        Default = getfpscap(),
        Callback = function(text)
            local num = tonumber(text)
            if num then
                setfpscap(num)
            end
        end
    })
end
local mouseLockController = LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule") and LocalPlayer.PlayerScripts.PlayerModule:FindFirstChild("CameraModule") and LocalPlayer.PlayerScripts.PlayerModule.CameraModule:FindFirstChild("MouseLockController")
local boundKeys = mouseLockController and mouseLockController:FindFirstChild("BoundKeys")
if mouseLockController then
    settingsContent:AddKeybind({
        Label = "Roblox - 鼠标锁定键",
        Default = boundKeys and boundKeys.Value,
        Callback = function(key)
            if boundKeys then
                boundKeys.Value = key
            else
                boundKeys = Instance.new("StringValue")
                boundKeys.Name = "BoundKeys"
                boundKeys.Value = key
                boundKeys.Parent = mouseLockController
            end
        end
    })
end
settingsContent:AddDivider()
settingsContent:AddToggle({
    Label = "自动连接IRC",
    Default = data["basicdata"]["otherdata"]["autoconnirc"],
    Callback = function(v) mainConfig.autoconnirc = v end
})
settingsContent:AddKeybind({
    Label = "灵魂出窍",
    Default = FreecamModule.getKeybind().Name,
    Callback = function(key)
        local newKey = safeGetKeyCode(key)
        if newKey then
            FreecamModule.setKeybind(newKey)
        end
    end
})
settingsContent:AddKeybind({
    Label = "望远镜",
    Default = data["basicdata"]["releasetools"]["zoom"]:GetBindKey().Name,
    Callback = function(key)
        local newKey = safeGetKeyCode(key)
        if newKey then
            data["basicdata"]["releasetools"]["zoom"]:SetBindKey(newKey)
        end
    end
})
settingsContent:AddKeybind({
    Label = "锁定视角",
    Default = LockCameraModule.getBindKey().Name,
    Callback = function(key)
        if key then
            LockCameraModule.setBindKey(key)
        end
    end
})
settingsContent:AddKeybind({
    Label = "滚轮切换按键",
    Default = ScrollSwitch:getbind().Name,
    Callback = function(key)
        if key then
            local newKey = safeGetKeyCode(key)
            ScrollSwitch:setbind(newKey)
        end
    end
})
settingsContent:AddInput({
    Label = "TPWalk距离",
    Placeholder = "",
    Default = tpWalk:GetSpeed(),
    Callback = function(text)
        local num = tonumber(text)
        if num then
            tpWalk:SetSpeed(num)
        end
    end
})
settingsContent:AddInput({
    Label = "平移距离",
    Placeholder = "",
    Default = movementModule.GetDistance(),
    Callback = function(text)
        local num = tonumber(text)
        if num then
            movementModule.SetDistance(num)
        end
    end
})
settingsContent:AddKeybind({
    Label = "GUI删除工具",
    Default = GuiDeleter.getBindKey().Name,
    Callback = function(key)
        local newKey = safeGetKeyCode(key)
        if newKey then
            GuiDeleter.setBindKey(newKey)
        end
    end
})
settingsContent:AddKeybind({
    Label = "瞬间回头",
    Default = SnapReverse.GetKeyBind().Name,
    Callback = function(key)
        if key then
            local newKey = safeGetKeyCode(key)
            if newKey then
                SnapReverse.SetKeyBind(newKey)
            end
        end
    end
})
settingsContent:AddDivider()
settingsKeybindInput(settingsContent, "飞行 (Ctrl+)", FlyModule.getbindkey().Name, function(k) FlyModule.setbindkey(k) end, "飞行速度", FlyModule.getflyspeed(), function(v) FlyModule.setflyspeed(v) end)
settingsKeybindInput(settingsContent, "帧飞行 (Ctrl+)", CframeFly.getbindkey().Name, function(k) CframeFly.setbindkey(k) end, "帧飞行速度", CframeFly.getspeed(), function(v) CframeFly.setspeed(v) end)
settingsKeybindInput(settingsContent, "载具飞行 (Ctrl+)", VehicleFly.getbindkey().Name, function(k) VehicleFly.setbindkey(k) end, "载具飞行速度", VehicleFly.getspeed(), function(v) VehicleFly.setspeed(v) end)
settingsContent:AddDivider()
settingsContent:AddKeybind({
    Label = "自动瞄准-绑定按键",
    Default = AimBotModule.GetKey().Name,
    Callback = function(key)
        if key then
            local newKey = safeGetKeyCode(key)
            AimBotModule.SetKey(newKey)
        end
    end
})
settingsContent:AddToggle({
    Label = "自动瞄准-队伍检查",
    Default = false,
    Callback = function(v) AimBotModule.SetTeamCheck(v) end
})
settingsContent:AddToggle({
    Label = "自动瞄准-墙壁检查",
    Default = false,
    Callback = function(v) AimBotModule.SetWallCheck(v) end
})
settingsContent:AddDropdown({
    Label = "自动瞄准-命中部位",
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    Default = AimBotModule.GetHitScan(),
    Callback = function(selected) AimBotModule.SetHitScan(selected) end
})
settingsContent:AddToggle({
    Label = "自动瞄准-使用鼠标控制",
    Default = AimBotModule.GetUseMouse(),
    Callback = function(v) AimBotModule.SetUseMouse(v) end
})
settingsContent:AddDropdown({
    Label = "自动瞄准-鼠标模式",
    Options = {"MouseButton2", "MouseButton1"},
    Default = "MouseButton2",
    Callback = function(selected) AimBotModule.SetMouseBind(selected) end
})
settingsContent:AddToggle({
    Label = "自动瞄准-粘性瞄准",
    Default = false,
    Callback = function(v) AimBotModule.SetStickyAim(v) end
})
settingsContent:AddSlider({
    Label = "自动瞄准-平滑度",
    Min = 3, Max = 50, Default = 30,
    Callback = function(v) AimBotModule.SetSmoothing(v) end
})
settingsContent:AddToggle({
    Label = "自动瞄准-移动预测",
    Default = false,
    Callback = function(v) AimBotModule.SetPrediction(v) end
})
settingsContent:AddSlider({
    Label = "自动瞄准-预测值",
    Min = 0, Max = 1000, Default = 100,
    Callback = function(v) AimBotModule.SetPredictionAmount(v) end
})
settingsContent:AddDivider()

mainWindow:RefreshContent()
