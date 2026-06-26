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

-- ===== 基础设置 Tab =====
local basicTab = mainWindow:CreateTab({ Name = "基础设置", HasIcon = true, IconName = "pencil-ruler" })
basicTab:AddTitle("基础数据修改")
basicTab:AddSlider({
    Label = "玩家移速",
    Min = 0, Max = 1000, Default = data["basicdata"]["player"]["speed"],
    Callback = function(v) LocalPlayer.Character.Humanoid.WalkSpeed = v; data["basicdata"]["player"]["speed"] = v end
})
basicTab:AddToggle({
    Label = "锁定玩家移速",
    Default = false,
    Callback = function(v) data["basicdata"]["player"]["islockspeed"] = v end
})
basicTab:AddSlider({
    Label = "跳跃力量",
    Min = 0, Max = 1000, Default = data["basicdata"]["player"]["jump"],
    Callback = function(v) LocalPlayer.Character.Humanoid.JumpPower = v; data["basicdata"]["player"]["jump"] = v end
})
basicTab:AddToggle({
    Label = "锁定跳跃力量",
    Default = false,
    Callback = function(v) data["basicdata"]["player"]["islockjump"] = v end
})
basicTab:AddSlider({
    Label = "最大血量",
    Min = 0, Max = 1000, Default = data["basicdata"]["player"]["maxhealth"],
    Callback = function(v) LocalPlayer.Character.Humanoid.MaxHealth = v; data["basicdata"]["player"]["maxhealth"] = v end
})
basicTab:AddToggle({
    Label = "锁定最大血量",
    Default = false,
    Callback = function(v) data["basicdata"]["player"]["islockmaxhealth"] = v end
})
basicTab:AddSlider({
    Label = "当前血量",
    Min = 0, Max = 1000, Default = data["basicdata"]["player"]["health"],
    Callback = function(v) LocalPlayer.Character.Humanoid.Health = v; data["basicdata"]["player"]["health"] = v end
})
basicTab:AddToggle({
    Label = "锁定当前血量",
    Default = false,
    Callback = function(v) data["basicdata"]["player"]["islockhealth"] = v end
})
basicTab:AddSlider({
    Label = "世界重力",
    Min = 0, Max = 1000, Default = data["basicdata"]["player"]["gravity"],
    Callback = function(v) Workspace.Gravity = v; data["basicdata"]["player"]["gravity"] = v end
})
basicTab:AddToggle({
    Label = "锁定世界重力",
    Default = false,
    Callback = function(v) data["basicdata"]["player"]["islockgravity"] = v end
})

-- ===== 工具 Tab =====
local ToolsTab = mainWindow:CreateTab({ Name = "工具", HasIcon = true, IconName = "wrench" })
ToolsTab:AddTitle("各种实用工具")
ToolsTab:AddToggle({
    Label = "防挂机",
    Default = true,
    Callback = function(v) data["basicdata"]["releasetools"]["antiafk"] = v end
})
ToolsTab:AddToggle({
    Label = "保留THub - 传送后自动执行",
    Default = false,
    Callback = function(v) data["basicdata"]["releasetools"]["keepthub"] = v end
})
ToolsTab:AddToggle({
    Label = "飞行",
    Default = false,
    Callback = function(v)
        if v then
            FlyModule.enable()
            ChronixUI:Notify({ Title = "提示", Content = "按住Ctrl+" .. FlyModule.getbindkey().Name .. "开关飞行状态", Type = "info", Duration = 5 })
        else
            FlyModule.disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "帧飞行",
    Default = false,
    Callback = function(v)
        if v then
            CframeFly.enable()
            ChronixUI:Notify({ Title = "提示", Content = "按住Ctrl+" .. CframeFly.getbindkey().Name .. "开关飞行状态", Type = "info", Duration = 5 })
        else
            CframeFly.disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "载具飞行",
    Default = false,
    Callback = function(v)
        if v then
            VehicleFly.enable()
            ChronixUI:Notify({ Title = "提示", Content = "按住Ctrl+" .. VehicleFly.getbindkey().Name .. "开关飞行状态", Type = "info", Duration = 5 })
        else
            VehicleFly.disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "点击传送",
    Default = false,
    Callback = function(v)
        if v then
            TeleportModule.enable()
            ChronixUI:Notify({ Title = "提示", Content = "按住Ctrl并点击来传送", Type = "info", Duration = 5 })
        else
            TeleportModule.disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "玩家透视",
    Default = false,
    Callback = function(v)
        if v then
            PlayerESP.enable()
        else
            PlayerESP.disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "NPC透视",
    Default = false,
    Callback = function(v)
        if v then
            data["basicdata"]["releasetools"]["npc"]:enable()
        else
            data["basicdata"]["releasetools"]["npc"]:disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "TPWalk",
    Default = false,
    Callback = function(v) tpWalk:Enabled(v) end
})
ToolsTab:AddToggle({
    Label = "鼠标解锁",
    Default = false,
    Callback = function(v)
        if v then
            MouseUnlockModule.Enable()
            ChronixUI:Notify({ Title = "提示", Content = "按下K+L组合键开关解锁鼠标", Type = "info", Duration = 5 })
        else
            MouseUnlockModule.Disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "锁定视角",
    Default = false,
    Callback = function(v)
        if v then
            LockCameraModule.enable()
            ChronixUI:Notify({ Title = "提示", Content = "按住" .. LockCameraModule.getBindKey().Name .. "键来锁定视角", Type = "info", Duration = 5 })
        else
            LockCameraModule.disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "瞬间转向",
    Default = false,
    Callback = function(v)
        if v then
            SnapTurn.Enable()
        else
            SnapTurn.Disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "瞬间回头",
    Default = false,
    Callback = function(v)
        if v then
            SnapReverse.Enable()
            ChronixUI:Notify({ Title = "提示", Content = "按下" .. SnapReverse.GetKeyBind().Name .. "键来瞬间回头", Type = "info", Duration = 5 })
        else
            SnapReverse.Disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "自动瞄准",
    Default = false,
    Callback = function(v)
        if v then
            AimBotModule.Enable()
        else
            AimBotModule.Disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "物品滚轮切换",
    Default = false,
    Callback = function(v)
        if v then
            ChronixUI:Notify({ Title = "提示", Content = "按住" .. ScrollSwitch:getbind().Name .. "键并滚动鼠标滚轮来切换物品", Type = "info", Duration = 5 })
            ScrollSwitch:enable()
        else
            ScrollSwitch:disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "望远镜",
    Default = false,
    Callback = function(v)
        if v then
            data["basicdata"]["releasetools"]["zoom"]:Enable()
            ChronixUI:Notify({ Title = "提示", Content = "按住" .. tostring(data["basicdata"]["releasetools"]["zoom"]:GetBindKey()):gsub("^Enum%.%w+%.", "") .. "键放大", Type = "info", Duration = 5 })
        else
            data["basicdata"]["releasetools"]["zoom"]:Disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "隐身",
    Default = false,
    Callback = function(v)
        if v then
            PlayerVisibleModule.enable()
        else
            PlayerVisibleModule.disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "查看落脚点",
    Default = false,
    Callback = function(v)
        if v then
            FootstepHighlighter.enable()
        else
            FootstepHighlighter.disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "落地特效",
    Default = false,
    Callback = function(v)
        if v then
            LandingEffect.enable()
        else
            LandingEffect.disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "夜视",
    Default = false,
    Callback = function(v)
        data["basicdata"]["releasetools"]["nightvision"] = v
        if v then
            game.Lighting.Ambient = Color3.new(1, 1, 1)
        else
            game.Lighting.Ambient = Color3.new(0, 0, 0)
        end
    end
})
ToolsTab:AddToggle({
    Label = "超级夜视",
    Default = false,
    Callback = function(v)
        data["basicdata"]["releasetools"]["supernightvision"] = v
        if v then
            data["basicdata"]["releasetools"]["originalBrightness"] = Lighting.Brightness
            data["basicdata"]["releasetools"]["originalExposureCompensation"] = Lighting.ExposureCompensation
            Lighting.Brightness = 2
            Lighting.ExposureCompensation = 2.5
        else
            Lighting.Brightness = data["basicdata"]["releasetools"]["originalBrightness"]
            Lighting.ExposureCompensation = data["basicdata"]["releasetools"]["originalExposureCompensation"]
        end
    end
})
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
xrayLoop = RunService.Heartbeat:Connect(function()
    if data["basicdata"]["releasetools"]["xray"] then
        local now = tick()
        if now - xrayLastUpdate >= 1 then
            xrayLastUpdate = now
            xray(true)
        end
    end
end)
ToolsTab:AddToggle({
    Label = "X光",
    Default = false,
    Callback = function(v)
        data["basicdata"]["releasetools"]["xray"] = v
        if not v then xray(false) end
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
ToolsTab:AddToggle({
    Label = "平移",
    Default = false,
    Callback = function(v)
        if v then
            movementModule.Enable()
            ChronixUI:Notify({ Title = "提示", Content = "按下↑↓←→键进行平移", Type = "info", Duration = 5 })
        else
            movementModule.Disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "空中移动",
    Default = false,
    Callback = function(v)
        if v then
            AirWalk.enable()
        else
            AirWalk.disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "无摔落伤害",
    Default = false,
    Callback = function(v)
        if v then
            NoFall.enable()
        else
            NoFall.disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "瞬间交互",
    Default = false,
    Callback = function(v)
        if v then
            InstantInteraction.enable()
        else
            InstantInteraction.disable()
        end
    end
})
noclipConnection = RunService.Stepped:Connect(function()
    if data["basicdata"]["releasetools"]["noclip"] then
        local char = Workspace:FindFirstChild(LocalPlayer.Name)
        if char then
            for _, v in pairs(char:GetChildren()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
        end
    end
end)
ToolsTab:AddToggle({
    Label = "穿墙",
    Default = false,
    Callback = function(v)
        data["basicdata"]["releasetools"]["noclip"] = v
        if not v then
            local char = Workspace:FindFirstChild(LocalPlayer.Name)
            if char then
                for _, part in pairs(char:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end
})
ToolsTab:AddToggle({
    Label = "连跳",
    Default = false,
    Callback = function(v)
        data["basicdata"]["releasetools"]["infjump"] = v
        JR = UserInputService.JumpRequest:Connect(function()
            if not data["basicdata"]["releasetools"]["infjump"] then
                JR:Disconnect()
            end
            if data["basicdata"]["releasetools"]["infjump"] then
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
ToolsTab:AddToggle({
    Label = "固定到世界",
    Default = false,
    Callback = function(v)
        if v then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RootPart.Anchored = true
        else
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RootPart.Anchored = false
        end
    end
})
ToolsTab:AddToggle({
    Label = "旁观模式",
    Default = false,
    Callback = function(v)
        if v then
            SpectatorModule.start()
        else
            SpectatorModule.close()
        end
    end
})
ToolsTab:AddToggle({
    Label = "摄像头穿墙",
    Default = false,
    Callback = function(v)
        if v then
            NoclipCam.enable(LocalPlayer)
        else
            NoclipCam.disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "防击倒",
    Default = false,
    Callback = function(v) data["basicdata"]["releasetools"]["antifall"] = v end
})
ToolsTab:AddToggle({
    Label = "晕厥康复",
    Default = false,
    Callback = function(v)
        if v then
            StandRecovery:enableDetection()
        else
            StandRecovery:disableDetection()
        end
    end
})
ToolsTab:AddToggle({
    Label = "防甩飞",
    Default = false,
    Callback = function(v)
        if v then
            FlingDetector.enable(LocalPlayer)
        else
            FlingDetector.disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "反物理劫持",
    Default = false,
    Callback = function(v)
        if v then
            AntiVoidModule.enable()
        else
            AntiVoidModule.disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "移除移动部件",
    Default = false,
    Callback = function(v)
        if v then
            MovingPartCleaner.Enable()
        else
            MovingPartCleaner.Disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "防御立场",
    Default = false,
    Callback = function(v)
        if v then
            DefenseField.Enable()
        else
            DefenseField.Disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "管理员检测",
    Default = false,
    Callback = function(v)
        data["basicdata"]["releasetools"]["staffcheck"] = v
        if v and game.CreatorType == Enum.CreatorType.Group then
            local found = {}
            for _, player in pairs(Players:GetPlayers()) do
                local result = getStaffRole(player)
                if result.Staff then
                    table.insert(found, formatUsername(player) .. " 是 " .. result.Role)
                end
            end
            if #found > 0 then
                for index, value in ipairs(found) do
                    ChronixUI:Notify({ Title = "警告", Content = value, Duration = 10 })
                end
            end
        else
            data["basicdata"]["releasetools"]["staffcheck"] = false
        end
    end
})
ToolsTab:AddToggle({
    Label = "死亡播报",
    Default = false,
    Callback = function(v)
        if v then
            enableDeathAnnounce()
        else
            disableDeathAnnounce()
        end
    end
})
ToolsTab:AddToggle({
    Label = "防死亡",
    Default = false,
    Callback = function(v)
        data["basicdata"]["releasetools"]["antidead"] = v
        if not v then LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end
    end
})
ToolsTab:AddToggle({
    Label = "聊天重发",
    Default = false,
    Callback = function(v) data["basicdata"]["releasetools"]["chatresend"] = v end
})
ToolsTab:AddToggle({
    Label = "聊天偷听",
    Default = false,
    Callback = function(v)
        if v then
            ChatSpy.enable()
        else
            ChatSpy.disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "坐下",
    Default = false,
    Callback = function(v)
        if v then
            LocalPlayer.Character:FindFirstChild("Humanoid").Sit = true
        else
            LocalPlayer.Character:FindFirstChild("Humanoid").Sit = false
        end
    end
})
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
ToolsTab:AddToggle({
    Label = "模型删除工具",
    Default = false,
    Callback = function(v)
        if v then
            DeleteTool.Enable()
            ChronixUI:Notify({ Title = "提示", Content = "按住Ctrl键点击来删除指向的模型", Type = "info", Duration = 5 })
        else
            DeleteTool.Disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "GUI删除工具",
    Default = false,
    Callback = function(v)
        if v then
            GuiDeleter.enable()
            ChronixUI:Notify({ Title = "提示", Content = "按下" .. GuiDeleter.getBindKey().Name .. "键来删除鼠标指向的UI", Type = "info", Duration = 5 })
        else
            GuiDeleter.disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "模型信息查询工具",
    Default = false,
    Callback = function(v)
        if v then
            ClickInspectModule.Enable()
            ChronixUI:Notify({ Title = "提示", Content = "按下Ctrl键点击来查看模型信息", Type = "info", Duration = 5 })
        else
            ClickInspectModule.Disable()
        end
    end
})
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
    Callback = function(v) data["basicdata"]["releasetools"]["networkpausedisable"] = v; pcall(function() CoreGui.RobloxGui["CoreScripts/NetworkPause"]:Destroy() end) end
})
ToolsTab:AddToggle({
    Label = "游戏翻译",
    Default = false,
    Callback = function(v)
        if v then
            TranslationModule.enable()
            ChronixUI:Notify({ Title = "提示", Content = "正在翻译中，可能会比较慢\n速度限制2次/s", Type = "info", Duration = 10 })
        else
            TranslationModule.disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "透视触点实例",
    Default = false,
    Callback = function(v)
        if v then
            TCPHighLight.touchinterest.enable()
        else
            TCPHighLight.touchinterest.disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "禁用触点实例",
    Default = false,
    Callback = function(v) toggleInteraction("TouchTransmitter", v) end
})
ToolsTab:AddToggle({
    Label = "透视点击触发实例",
    Default = false,
    Callback = function(v)
        if v then
            TCPHighLight.clickdetectors.enable()
        else
            TCPHighLight.clickdetectors.disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "禁用点击触发实例",
    Default = false,
    Callback = function(v) toggleInteraction("ClickDetector", v) end
})
ToolsTab:AddToggle({
    Label = "透视可交互实例",
    Default = false,
    Callback = function(v)
        if v then
            TCPHighLight.proximityprompts.enable()
        else
            TCPHighLight.proximityprompts.disable()
        end
    end
})
ToolsTab:AddToggle({
    Label = "禁用可交互实例",
    Default = false,
    Callback = function(v) toggleInteraction("ProximityPrompt", v) end
})
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
ToolsTab:AddButton({ Text = "丢弃手中工具", Callback = function() droptool() end })
ToolsTab:AddButton({ Text = "获得点击传送工具", Callback = function() mouse = LocalPlayer:GetMouse() tool = Instance.new("Tool") tool.RequiresHandle = false tool.Name = "手持点击传送" tool.Activated:connect(function() local pos = mouse.Hit+Vector3.new(0,2.5,0) pos = CFrame.new(pos.X,pos.Y,pos.Z) LocalPlayer.Character.HumanoidRootPart.CFrame = pos end) tool.Parent = LocalPlayer.Backpack end })
ToolsTab:AddButton({ Text = "重新加入当前房间(服务器)", Callback = function() rejoinCurrentGame() end })
ToolsTab:AddButton({ Text = "切换角色为R6", Callback = function() promptNewRig("R6") end })
ToolsTab:AddButton({ Text = "切换角色为R15", Callback = function() promptNewRig("R15") end })
ToolsTab:AddButton({ Text = "切换时间为白天", Callback = function() setDay() end })
ToolsTab:AddButton({ Text = "切换时间为黑夜", Callback = function() setNight() end })
ToolsTab:AddButton({ Text = "去除雾气", Callback = function() RemoveFog() end })
ToolsTab:AddButton({ Text = "优化世界光效", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/WorldShader.lua"))() end })
ToolsTab:AddButton({ Text = "打印当前坐标", Callback = function()
    local position1 = LocalPlayer.Character.HumanoidRootPart.Position
    print(string.format("[THub] 玩家坐标: (%.2f, %.2f, %.2f)", position1.X, position1.Y, position1.Z))
end })
ToolsTab:AddButton({ Text = "开启控制台界面", Callback = function() StarterGui:SetCore("DevConsoleVisible", true) end })
ToolsTab:AddButton({ Text = "启用所有ROBLOXUI", Callback = function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end })
ToolsTab:AddButton({ Text = "获取建筑工具", Callback = function()
    for i = 1, 4 do
		local Tool = Instance.new("HopperBin")
		Tool.BinType = i
		Tool.Name = randomString()
		Tool.Parent = LocalPlayer:FindFirstChildWhichIsA("Backpack")
	end
end })
ToolsTab:AddButton({ Text = "测试执行器UNC与WUNC", Callback = function()
    ChronixUI:Notify({ Title = "提示", Content = "正在测试中，请耐心等待。", Type = "info", Duration = 5 })
    local unc = UNCTestModule.getunc()
    local wunc = UNCTestModule.getwunc()
    ChronixUI:Notify({ Title = "执行器 - " .. (identifyexecutor and identifyexecutor() or "UnKnown"), Content = string.format("UNC: %d%%, WUNC: %d%%", unc, wunc), Type = "info", Duration = 5 })
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
end
function refreshWaypointList()
    clearWaypointList()
    for _, waypoint in ipairs(waypointsData) do
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
                refreshWaypointList()
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
                for i, data in ipairs(waypointsData) do
                    if data["id"] == waypoint.id then
                        table.remove(waypointsData, i)
                        break
                    end
                end
                for i, data in ipairs(waypointsData) do
                    data["id"] = i
                end
                refreshWaypointList()
                ChronixUI:Notify({ Title = "已删除", Content = "路径点已移除", Type = "info", Duration = 1 })
            end
        })
        table.insert(elements, deleteBtn)
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
    refreshWaypointList()
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
            data["basicdata"]["otherdata"]["musicbox"]["SoundId"] = (not string.find(data["basicdata"]["otherdata"]["musicData"]["currentId"], "rbxasset://")) and ("rbxassetid://" .. data["basicdata"]["otherdata"]["musicData"]["currentId"]) or data["basicdata"]["otherdata"]["musicData"]["currentId"]
            local success, productInfo = pcall(function()
                if string.find(data["basicdata"]["otherdata"]["musicData"]["currentId"], "rbxasset://") then
                    success = true
                    return {}
                else
                    return MarketplaceService:GetProductInfo(tonumber(data["basicdata"]["otherdata"]["musicData"]["currentId"]))
                end
            end)
            if success and productInfo then
                data["basicdata"]["otherdata"]["musicbox"]:Play()
                data["basicdata"]["otherdata"]["musicData"]["isPlay"] = true
                data["basicdata"]["otherdata"]["musicData"]["isPause"] = false
                playStopButton.Text = "⏹️ 停止"
                if pauseResumeButton then
                    pauseResumeButton.Text = "⏸️ 暂停"
                end
                ChronixUI:Notify({ Title = "正在播放", Content = (productInfo.Name and productInfo.Name or data["basicdata"]["otherdata"]["musicData"]["othermusicname"]) .. "\n" .. (productInfo.Description or ""), Type = "info", Duration = 3 })
            else
                ChronixUI:Notify({ Title = "播放失败", Content = data["basicdata"]["otherdata"]["musicData"]["currentId"] .. "\n不是一个有效的rbxassetid", Type = "error", Duration = 3 })
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
    local allSounds = getAllSounds(game)
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
                data["basicdata"]["otherdata"]["testSound"]["Ended"]:Connect(function()
                    if data["basicdata"]["otherdata"]["audioData"]["isTesting"] then
                        data["basicdata"]["otherdata"]["audioData"]["isTesting"] = false
                        testPlayButton.Text = "🎵 尝试播放"
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
chatMessages = {}
function clearChatMessages()
    for _, element in ipairs(chatMessages) do
        if element and element.Destroy then
            element:Destroy()
        end
    end
    chatMessages = {}
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

-- ===== 执行器 Tab =====
executerTab = mainWindow:CreateTab({ Name = "执行器", HasIcon = true, IconName = "braces" })
executerTab:AddTitle("执行器")
executerTab:AddInput({
    Label = "请输入代码",
    Placeholder = "",
    Height = 200,
    Callback = function(text)
        data["basicdata"]["releasetools"]["executecode"] = text
    end
})
executerTab:AddButton({
    Text = "执行",
    Callback = function()
        if data["basicdata"]["releasetools"]["executecode"] and data["basicdata"]["releasetools"]["executecode"] ~= "" then
            local success, errorMessage = pcall(function()
                loadstring(data["basicdata"]["releasetools"]["executecode"])()
            end)
            if not success then
                ChronixUI:Notify({ Title = "错误", Content = "脚本执行失败: " .. errorMessage, Type = "error", Duration = 5 })
            else
                ChronixUI:Notify({ Title = "提示", Content = "脚本执行成功!", Type = "success", Duration = 5 })
            end
        else
            ChronixUI:Notify({ Title = "错误", Content = "请输入有效的脚本!", Type = "error", Duration = 5 })
        end
    end
})

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
hankerTab:AddToggle({
    Label = "循环OOF",
    Default = false,
    Callback = function(v)
        if v then
            LoopOofModule.enable()
        else
            LoopOofModule.disable()
        end
    end
})
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
hankerTab:AddToggle({
    Label = "开始旋转",
    Default = false,
    Callback = function(v)
        if v then
            SpinModule.enable(data["basicdata"]["hankermodule"]["spin"]["speed"])
        else
            SpinModule.disable()
        end
    end
})
hankerTab:AddDivider()
hankerTab:AddLabel("击飞功能")
hankerTab:AddToggle({
    Label = "旋转击飞(Ctrl+G)",
    Default = false,
    Callback = function(v)
        FlingModule.fling.setShortcutEnabled(v)
    end
})
hankerTab:AddToggle({
    Label = "飞行击飞",
    Default = false,
    Callback = function(v)
        if v then
            FlingModule.flyfling.enable(2)
        else
            FlingModule.flyfling.disable()
        end
    end
})
hankerTab:AddToggle({
    Label = "走路击飞",
    Default = false,
    Callback = function(v)
        if v then
            FlingModule.walkfling.enable()
        else
            FlingModule.walkfling.disable()
        end
    end
})
hankerTab:AddToggle({
    Label = "隐身击飞",
    Default = false,
    Callback = function(v)
        if v then
            FlingModule.invisfling.enable()
        else
            FlingModule.invisfling.disable()
        end
    end
})
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
weaoapiTab:AddLabel("Windows: " .. data["basicdata"]["otherdata"]["executordetecter"]["robloxinfo"].Windows)
weaoapiTab:AddLabel("Windows更新日期: " .. toChineseDate(data["basicdata"]["otherdata"]["executordetecter"]["robloxinfo"].WindowsDate, true))
weaoapiTab:AddLabel("Mac: " .. data["basicdata"]["otherdata"]["executordetecter"]["robloxinfo"].Mac)
weaoapiTab:AddLabel("Mac更新日期: " .. toChineseDate(data["basicdata"]["otherdata"]["executordetecter"]["robloxinfo"].MacDate, true))
weaoapiTab:AddLabel("Android: " .. data["basicdata"]["otherdata"]["executordetecter"]["robloxinfo"].Android)
weaoapiTab:AddLabel("Android更新日期: " .. toChineseDate(data["basicdata"]["otherdata"]["executordetecter"]["robloxinfo"].AndroidDate, true))
weaoapiTab:AddLabel("iOS: " .. data["basicdata"]["otherdata"]["executordetecter"]["robloxinfo"].iOS)
weaoapiTab:AddLabel("iOS更新日期: " .. toChineseDate(data["basicdata"]["otherdata"]["executordetecter"]["robloxinfo"].iOSDate, true))
weaoapiTab:AddDivider()
weaoapiTab:AddTitle("执行器状态")
local executors = parseExecutors(data["basicdata"]["otherdata"]["executordetecter"]["exploits"])
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

-- ===== ChatGLM Tab =====
aichatTab = mainWindow:CreateTab({ Name = "ChatGLM", HasIcon = true, IconName = "bot" })
aichatTab:AddTitle("智谱清言 ChatGLM")
aichat_message = ""
lastSendTime = 0
aichatprefix = "<system>当前用户环境参数: 游戏: Roblox"
    .. "游戏ID："
    .. game.GameId
    .. "游戏数据："
    .. (function()
        local success, result = pcall(function()
            return HttpService:JSONEncode(getGameName(game.GameId))
        end)
        if success and result then
            return result
        else
            return ""
        end
    end)()
    .. "玩家昵称："
    .. data["basicdata"]["player"]["displayname"]
    .. "玩家用户名："
    .. data["basicdata"]["player"]["name"]
    .. "玩家ID："
    .. data["basicdata"]["player"]["userid"]
    .. "上述信息仅供参考，用户未主动提问相关信息切勿主动提供，且提供信息时皆为属于你已知道的，不要说'根据你提供的内容'之类的话。</system>"
aichatinput = aichatTab:AddInput({
    Label = "输入框",
    Placeholder = "请输入文本...",
    Default = "",
    Callback = function(text) aichat_message = text end
})
aichatTab:AddButton({
    Text = "发送",
    Callback = function()
        local currentTime = os.time()
        if currentTime - lastSendTime < 10 then
            local remainingTime = math.ceil(10 - (currentTime - lastSendTime))
            ChronixUI:Notify({
                Title = "提示",
                Content = "发送过于频繁，请等待 " .. remainingTime .. " 秒后再试。",
                Type = "warning",
                Duration = 5
            })
            return
        end
        if aichat_message == "" then
            ChronixUI:Notify({ Title = "提示", Content = "无法发送空白内容。", Type = "warning", Duration = 5 })
            return
        end
        aichatinput.Text = ""
        lastSendTime = currentTime
        aichatTab:AddParagraph({
            Title = data["basicdata"]["player"]["displayname"] .. ":",
            Content = aichat_message
        })
        local aithink = aichatTab:AddParagraph({
            Title = "ChatGLM:",
            Content = "思考中..."
        })
        local fullMessage = aichatprefix .. aichat_message
        local encodedMessage = HttpService:UrlEncode(fullMessage)
        local apiUrl = "https://api.52vmy.cn/api/chat/glm?msg=" .. encodedMessage
        local success, result = pcall(function()
            local response = AsyncFileFetcher.fetchSingle(apiUrl)
            return HttpService:JSONDecode(response)
        end)
        aithink:Destroy()
        if not success then
            aichatTab:AddParagraph({ Title = "ChatGLM:", Content = "请求失败: " .. tostring(result) })
        elseif type(result) ~= "table" then
            aichatTab:AddParagraph({ Title = "ChatGLM:", Content = "返回数据格式异常" })
        elseif result["code"] and result["code"] == 201 then
            aichatTab:AddParagraph({ Title = "ChatGLM:", Content = result["msg"] or "网络异常，请稍后重试。" })
        elseif result["data"] and result["data"]["answer"] then
            aichatTab:AddParagraph({ Title = "ChatGLM:", Content = result["data"]["answer"] })
        else
            aichatTab:AddParagraph({ Title = "ChatGLM:", Content = "返回数据格式异常" })
        end
        aichat_message = ""
    end
})
aichatTab:AddDivider()

-- ===== IRC Tab =====
genv = getgenv().ChronixUI
if not genv then
    genv = {}
    getgenv().ChronixUI = genv
end
if WebSocket and WebSocket.connect then
    task.spawn(function() pcall(function() genv.wsManager:Disconnect() end) end)
    chatmessage = ""
    genv.wsManager = WebSocketManager.new()
    local IRCTab = mainWindow:CreateTab({ Name = "IRC", HasIcon = true, IconName = "castle" })
    IRCTab:AddTitle("Hub聊天室")
    connsuccessinfo = IRCTab:AddLabel("未连接到THub聊天服务器")
    onlineplayernumber = IRCTab:AddLabel("在线玩家: ?")
    IRCTab:AddDivider()
    ircchatinput = IRCTab:AddInput({
        Label = "输入框",
        Placeholder = "请输入文本...",
        Default = "",
        Height = 100,
        Callback = function(text) chatmessage = text end
    })
    IRCTab:AddButton({
        Text = "发送",
        Callback = function()
            if connsuccessinfo.Text == "未连接到THub聊天服务器" then
                ChronixUI:Notify({ Title = "提示", Content = "未连接到服务器无法发送。", Type = "warning", Duration = 5 })
            elseif chatmessage == "" then
                ChronixUI:Notify({ Title = "提示", Content = "无法发送空白内容。", Type = "warning", Duration = 5 })
            else
                ircchatinput.Text = ""
                genv.wsManager:SendChatMessage(chatmessage)
                chatmessage = ""
            end
        end
    })
    IRCTab:AddDivider()
    connectbutton = IRCTab:AddButton({
        Text = "连接到IRC服务器",
        Callback = function() task.spawn(function() pcall(function() genv.wsManager:Connect() end) end) end
    })
    genv.wsManager.OnConnectionChanged.Event:Connect(function(connected)
        if connected then
            connsuccessinfo.Text = "已连接到THub聊天服务器"
            connectbutton:Destroy()
        else
            connsuccessinfo.Text = "未连接到THub聊天服务器"
        end
    end)
    selfJoined = false
    genv.wsManager.OnUserOnline.Event:Connect(function(userInfo)
        if not (selfJoined and data["basicdata"]["player"]["userid"] == tonumber(userInfo.userId)) then
            selfJoined = true
            IRCTab:AddLabel("🟢 " .. userInfo.username .. "加入了服务器。")
        end
    end)
    genv.wsManager.OnUserOffline.Event:Connect(function(userInfo)
        IRCTab:AddLabel("🔴 " .. userInfo.username .. "离开了服务器。")
    end)
    genv.wsManager.OnUserListUpdate.Event:Connect(function(users)
        onlineplayernumber.Text = "在线玩家: " .. #users
    end)
    genv.wsManager.OnMessageReceived.Event:Connect(function(message)
        IRCTab:AddParagraph({ Title = message.username .. ":", Content = message.content })
    end)
    if data["basicdata"]["otherdata"]["autoconnirc"] then task.spawn(function() pcall(function() genv.wsManager:Connect() end) end) end
end

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
            OtherGameTab:AddToggle({
                Label = "怪物标签",
                Default = false,
                Callback = function(v) if v then data["othergamedata"]["west_wood"]["monster"]:enable() else data["othergamedata"]["west_wood"]["monster"]:disable() end end
            })
        elseif GetgameInfo.name == "警笛头:遗产" then
            OtherGameTab:AddToggle({
                Label = "透视盒子",
                Default = false,
                Callback = function(v) if v then data["othergamedata"]["sirenhead_legacy"]["cratemodule"].apply(); data["othergamedata"]["sirenhead_legacy"]["cratenametagmodule"]:enable() else data["othergamedata"]["sirenhead_legacy"]["cratemodule"].destroy(); data["othergamedata"]["sirenhead_legacy"]["cratenametagmodule"]:disable() end end
            })
            OtherGameTab:AddToggle({
                Label = "透视浆果",
                Default = false,
                Callback = function(v) if v then data["othergamedata"]["sirenhead_legacy"]["berrymodule"].apply(); data["othergamedata"]["sirenhead_legacy"]["berrynametagmodule"]:enable() else data["othergamedata"]["sirenhead_legacy"]["berrymodule"].destroy(); data["othergamedata"]["sirenhead_legacy"]["berrynametagmodule"]:disable() end end
            })
            OtherGameTab:AddButton({ Text = "传送到树顶", Callback = function() TeleportTo(69, 206, -72) end })
        elseif GetgameInfo.name == "噩梦之行" then
            OtherGameTab:AddToggle({
                Label = "高亮怪物",
                Default = false,
                Callback = function(v)
                    if v then
                        data["othergamedata"]["nightmare_run"]["monster"]:enable()
                    else
                        data["othergamedata"]["nightmare_run"]["monster"]:disable()
                    end
                end
            })
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
            OtherGameTab:AddToggle({
                Label = "Bot兽",
                Default = false,
                Callback = function(v) if v then data["othergamedata"]["project_transfur"]["bot"].apply(); data["othergamedata"]["project_transfur"]["botnt"]:enable() else data["othergamedata"]["project_transfur"]["bot"].destroy(); data["othergamedata"]["project_transfur"]["botnt"]:disable() end end
            })
            OtherGameTab:AddToggle({
                Label = "小保险箱",
                Default = false,
                Callback = function(v) if v then data["othergamedata"]["project_transfur"]["smallsafe"].apply(); data["othergamedata"]["project_transfur"]["smallsafent"]:enable() else data["othergamedata"]["project_transfur"]["smallsafe"].destroy(); data["othergamedata"]["project_transfur"]["smallsafent"]:disable() end end
            })
            OtherGameTab:AddToggle({
                Label = "大保险箱",
                Default = false,
                Callback = function(v) if v then data["othergamedata"]["project_transfur"]["largesafe"].apply(); data["othergamedata"]["project_transfur"]["largesafent"]:enable() else data["othergamedata"]["project_transfur"]["largesafe"].destroy(); data["othergamedata"]["project_transfur"]["largesafent"]:disable() end end
            })
            OtherGameTab:AddToggle({
                Label = "金保险箱",
                Default = false,
                Callback = function(v) if v then data["othergamedata"]["project_transfur"]["goldensafe"].apply(); data["othergamedata"]["project_transfur"]["goldensafent"]:enable() else data["othergamedata"]["project_transfur"]["goldensafe"].destroy(); data["othergamedata"]["project_transfur"]["goldensafent"]:disable() end end
            })
            OtherGameTab:AddToggle({
                Label = "武器盒",
                Default = false,
                Callback = function(v) if v then data["othergamedata"]["project_transfur"]["crate"].apply(); data["othergamedata"]["project_transfur"]["cratent"]:enable() else data["othergamedata"]["project_transfur"]["crate"].destroy(); data["othergamedata"]["project_transfur"]["cratent"]:disable() end end
            })
            OtherGameTab:AddToggle({
                Label = "空投",
                Default = false,
                Callback = function(v) if v then data["othergamedata"]["project_transfur"]["sd"].apply(); data["othergamedata"]["project_transfur"]["sdnt"]:enable() else data["othergamedata"]["project_transfur"]["sd"].destroy(); data["othergamedata"]["project_transfur"]["sdnt"]:disable() end end
            })
        elseif GetgameInfo.name == "妄想办公室" then
            OtherGameTab:AddToggle({
                Label = "实体警告",
                Default = false,
                Callback = function(v) data["othergamedata"]["delesions_office"]["entitywarning"] = v end
            })
            OtherGameTab:AddToggle({
                Label = "提醒他人",
                Default = false,
                Callback = function(v) data["othergamedata"]["delesions_office"]["tipotherplayer"] = v end
            })
            OtherGameTab:AddToggle({
                Label = "自动EN-013",
                Default = false,
                Callback = function(v) data["othergamedata"]["delesions_office"]["auto013"] = v end
            })
        elseif GetgameInfo.name == "格蕾丝" then
            OtherGameTab:AddToggle({
                Label = "自动拉杆",
                Default = false,
                Callback = function(v) data["othergamedata"]["grace"]["autolever"] = v end
            })
            OtherGameTab:AddButton({ Text = "删除全部实体(无法关闭)", Callback = function() data["othergamedata"]["grace"]["deleteentity"] = true end })
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
            OtherGameTab:AddToggle({
                Label = "窃皮者",
                Default = false,
                Callback = function(v) if v then data["othergamedata"]["backroomsurvival"]["SkinStealer"].apply(); data["othergamedata"]["backroomsurvival"]["SkinStealernt"]:enable() else data["othergamedata"]["backroomsurvival"]["SkinStealer"].destroy(); data["othergamedata"]["backroomsurvival"]["SkinStealernt"]:disable() end end
            })
            OtherGameTab:AddToggle({
                Label = "瞎子",
                Default = false,
                Callback = function(v) if v then data["othergamedata"]["backroomsurvival"]["Shrieker"].apply(); data["othergamedata"]["backroomsurvival"]["Shriekernt"]:enable() else data["othergamedata"]["backroomsurvival"]["Shrieker"].destroy(); data["othergamedata"]["backroomsurvival"]["Shriekernt"]:disable() end end
            })
            OtherGameTab:AddToggle({
                Label = "悲尸",
                Default = false,
                Callback = function(v) if v then data["othergamedata"]["backroomsurvival"]["Wretch"].apply(); data["othergamedata"]["backroomsurvival"]["Wretchnt"]:enable() else data["othergamedata"]["backroomsurvival"]["Wretch"].destroy(); data["othergamedata"]["backroomsurvival"]["Wretchnt"]:disable() end end
            })
            OtherGameTab:AddToggle({
                Label = "梦魇",
                Default = false,
                Callback = function(v) if v then data["othergamedata"]["backroomsurvival"]["Phantom"].apply(); data["othergamedata"]["backroomsurvival"]["Phantomnt"]:enable() else data["othergamedata"]["backroomsurvival"]["Phantom"].destroy(); data["othergamedata"]["backroomsurvival"]["Phantomnt"]:disable() end end
            })
            OtherGameTab:AddToggle({
                Label = "细菌",
                Default = false,
                Callback = function(v) if v then data["othergamedata"]["backroomsurvival"]["Bacteria"].apply(); data["othergamedata"]["backroomsurvival"]["Bacteriant"]:enable() else data["othergamedata"]["backroomsurvival"]["Bacteria"].destroy(); data["othergamedata"]["backroomsurvival"]["Bacteriant"]:disable() end end
            })
            OtherGameTab:AddToggle({
                Label = "侦察兵",
                Default = false,
                Callback = function(v) if v then data["othergamedata"]["backroomsurvival"]["Recon"].apply(); data["othergamedata"]["backroomsurvival"]["Reconnt"]:enable() else data["othergamedata"]["backroomsurvival"]["Recon"].destroy(); data["othergamedata"]["backroomsurvival"]["Reconnt"]:disable() end end
            })
            OtherGameTab:AddToggle({
                Label = "修理工",
                Default = false,
                Callback = function(v) if v then data["othergamedata"]["backroomsurvival"]["Mechanic"].apply(); data["othergamedata"]["backroomsurvival"]["Mechanicnt"]:enable() else data["othergamedata"]["backroomsurvival"]["Mechanic"].destroy(); data["othergamedata"]["backroomsurvival"]["Mechanicnt"]:disable() end end
            })
        elseif GetgameInfo.name == "最黑暗的时刻" then
            OtherGameTab:AddLabel("透视功能")
            OtherGameTab:AddToggle({
                Label = "收集物",
                Default = false,
                Callback = function(v) if v then data["othergamedata"]["DarkestHours"]["Collectible"].apply(); data["othergamedata"]["DarkestHours"]["Collectiblent"]:enable() else data["othergamedata"]["DarkestHours"]["Collectible"].destroy(); data["othergamedata"]["DarkestHours"]["Collectiblent"]:disable() end end
            })
        elseif GetgameInfo.name == "后悔电梯" then
            OtherGameTab:AddLabel("通用")
            OtherGameTab:AddToggle({
                Label = "自动舔冰淇凌（确保快捷栏中有冰淇凌）",
                Default = false,
                Callback = function(v)
                    if v then
                        Regretevator_AutoIceCream:enable()
                    else
                        Regretevator_AutoIceCream:disable()
                    end
                end
            })
            OtherGameTab:AddToggle({
                Label = "透视硬币",
                Default = false,
                Callback = function(v) if v then data["othergamedata"]["Regretevator"]["coins"].apply(); data["othergamedata"]["Regretevator"]["coinsnt"]:enable() else data["othergamedata"]["Regretevator"]["coins"].destroy(); data["othergamedata"]["Regretevator"]["coinsnt"]:disable() end end
            })
            OtherGameTab:AddLabel("Bugbo楼层")
            OtherGameTab:AddToggle({
                Label = "透视石头",
                Default = false,
                Callback = function(v) if v then data["othergamedata"]["Regretevator"]["bugbo_rocks"].apply(); data["othergamedata"]["Regretevator"]["bugbo_rocksnt"]:enable() else data["othergamedata"]["Regretevator"]["bugbo_rocks"].destroy(); data["othergamedata"]["Regretevator"]["bugbo_rocksnt"]:disable() end end
            })
            OtherGameTab:AddLabel("森林营地楼层")
            OtherGameTab:AddToggle({
                Label = "透视木头",
                Default = false,
                Callback = function(v) if v then data["othergamedata"]["Regretevator"]["firewood"].apply(); data["othergamedata"]["Regretevator"]["firewoodnt"]:enable() else data["othergamedata"]["Regretevator"]["firewood"].destroy(); data["othergamedata"]["Regretevator"]["firewoodnt"]:disable() end end
            })
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
infoTab:AddTitle(">广告位招租<")

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
local mouseLockController = LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("CameraModule"):WaitForChild("MouseLockController")
local boundKeys = mouseLockController:FindFirstChild("BoundKeys")
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
        local newKey = Enum.KeyCode[key]
        if newKey then
            FreecamModule.setKeybind(newKey)
        end
    end
})
settingsContent:AddKeybind({
    Label = "望远镜",
    Default = data["basicdata"]["releasetools"]["zoom"]:GetBindKey().Name,
    Callback = function(key)
        local newKey = Enum.KeyCode[key]
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
            local newKey = Enum.KeyCode[key]
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
        local newKey = Enum.KeyCode[key]
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
            local newKey = Enum.KeyCode[key]
            if newKey then
                SnapReverse.SetKeyBind(newKey)
            end
        end
    end
})
settingsContent:AddDivider()
settingsContent:AddKeybind({
    Label = "飞行 (Ctrl+)",
    Default = FlyModule.getbindkey().Name,
    Callback = function(key)
        if key then
            local newKey = Enum.KeyCode[key]
            if newKey then
                FlyModule.setbindkey(newKey)
            end
        end
    end
})
settingsContent:AddInput({
    Label = "飞行速度",
    Placeholder = "",
    Default = FlyModule.getflyspeed(),
    Callback = function(text)
        local num = tonumber(text)
        if num then
            FlyModule.setflyspeed(num)
        end
    end
})
settingsContent:AddKeybind({
    Label = "帧飞行 (Ctrl+)",
    Default = CframeFly.getbindkey().Name,
    Callback = function(key)
        if key then
            local newKey = Enum.KeyCode[key]
            if newKey then
                CframeFly.setbindkey(newKey)
            end
        end
    end
})
settingsContent:AddInput({
    Label = "帧飞行速度",
    Placeholder = "",
    Default = CframeFly.getspeed(),
    Callback = function(text)
        local num = tonumber(text)
        if num then
            CframeFly.setspeed(num)
        end
    end
})
settingsContent:AddKeybind({
    Label = "载具飞行 (Ctrl+)",
    Default = VehicleFly.getbindkey().Name,
    Callback = function(key)
        if key then
            local newKey = Enum.KeyCode[key]
            if newKey then
                VehicleFly.setbindkey(newKey)
            end
        end
    end
})
settingsContent:AddInput({
    Label = "载具飞行速度",
    Placeholder = "",
    Default = VehicleFly.getspeed(),
    Callback = function(text)
        local num = tonumber(text)
        if num then
            VehicleFly.setspeed(num)
        end
    end
})
settingsContent:AddDivider()
settingsContent:AddKeybind({
    Label = "自动瞄准-绑定按键",
    Default = AimBotModule.GetKey().Name,
    Callback = function(key)
        if key then
            local newKey = Enum.KeyCode[key]
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
