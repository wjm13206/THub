--!native
--!optimize 2



local isMobile = UserInputService and UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

THubWindow = WindUI:CreateWindow({
    Title = "THub V3",
    Author = "by Furrycalin & 0988",
    Folder = "THub",
    Icon = "zap",
    Size = data["basicdata"]["window"]["windowSize"],
    ToggleKey = Enum.KeyCode.RightShift,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    HideSearchBar = false,
    ScrollBarEnabled = true,
})
local mainWindow = THubWindow

mainWindow:Tag({
    Title = "V3 WindUI",
    Icon = "github",
    Color = Color3.fromHex("#1c1c1c"),
})

-- 侧边栏分组
local SecCommon = mainWindow:Section({ Title = "常用" })
local SecTeleport = mainWindow:Section({ Title = "传送" })
local SecMedia = mainWindow:Section({ Title = "娱乐媒体" })
local SecVisual = mainWindow:Section({ Title = "视觉" })
local SecRisk = mainWindow:Section({ Title = "风险功能" })
local SecInfo = mainWindow:Section({ Title = "信息与设置" })

--=============================================================================================
-- Helpers
--=============================================================================================

local mobileHidden = {
    ["飞行"] = true, ["帧飞行"] = true, ["载具飞行"] = true,
    ["点击传送"] = true, ["鼠标解锁"] = true,
    ["瞬间回头"] = true, ["物品滚轮切换"] = true, ["望远镜"] = true,
    ["平移"] = true, ["摄像头穿墙"] = true,
    ["模型删除工具"] = true, ["GUI删除工具"] = true, ["模型信息查询工具"] = true,
}

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
 

local function keyName(key)
    if typeof(key) == "EnumItem" then
        return key.Name
    end
    if type(key) == "string" then
        return key
    end
    return "G"
end

local function sliderLock(tab, flagBase, sliderLabel, min, max, default, sliderCb, lockLabel, lockCb)
    local step = 1
    if (min % 1 ~= 0) or (max % 1 ~= 0) then
        step = 0.1
    end
    tab:Slider({
        Title = sliderLabel,
        Flag = flagBase,
        Step = step,
        Value = { Min = min, Max = max, Default = default },
        Callback = sliderCb,
    })
    tab:Toggle({
        Title = lockLabel,
        Flag = flagBase .. "_Lock",
        Value = false,
        Callback = lockCb,
    })
end

local function enableToggle(tab, flag, label, onFn, offFn)
    if isMobile and mobileHidden[label] then return end
    tab:Toggle({
        Title = label,
        Flag = flag,
        Value = false,
        Callback = function(v) if v then onFn() else offFn() end end,
    })
end

local function settingsKeybindInput(tab, flagBase, bindLabel, defaultKey, setKey, inputLabel, defaultVal, setVal)
    tab:Keybind({
        Title = bindLabel,
        Flag = flagBase .. "_Key",
        Value = keyName(defaultKey),
        Callback = function(key)
            if key then
                local nk = safeGetKeyCode(key)
                if nk then
                    setKey(nk)
                end
            end
        end,
    })
    tab:Input({
        Title = inputLabel,
        Flag = flagBase .. "_Val",
        Value = tostring(defaultVal),
        Placeholder = "",
        Callback = function(text)
            local n = tonumber(text); if n then setVal(n) end
        end,
    })
end

-- ===== 基础设置 Tab =====
local basicTab = SecCommon:Tab({ Title = "基础设置", Icon = "pencil-ruler" })
basicTab:Section({ Title = "基础数据修改", Opened = true })
sliderLock(basicTab, "THub_Basic_Speed", "玩家移速", 0, 1000, data["basicdata"]["player"]["speed"],
    function(v) LocalPlayer.Character.Humanoid.WalkSpeed = v; data["basicdata"]["player"]["speed"] = v end,
    "锁定玩家移速", function(v) data["basicdata"]["player"]["islockspeed"] = v; requestSpoofHooks() end)
sliderLock(basicTab, "THub_Basic_Jump", "跳跃力量", 0, 1000, data["basicdata"]["player"]["jump"],
    function(v) LocalPlayer.Character.Humanoid.JumpPower = v; data["basicdata"]["player"]["jump"] = v end,
    "锁定跳跃力量", function(v) data["basicdata"]["player"]["islockjump"] = v; requestSpoofHooks() end)
sliderLock(basicTab, "THub_Basic_MaxHealth", "最大血量", 0, 1000, data["basicdata"]["player"]["maxhealth"],
    function(v) LocalPlayer.Character.Humanoid.MaxHealth = v; data["basicdata"]["player"]["maxhealth"] = v end,
    "锁定最大血量", function(v) if v then enableLockMaxHealth() else disableLockMaxHealth() end end)
sliderLock(basicTab, "THub_Basic_Health", "当前血量", 0, 1000, data["basicdata"]["player"]["health"],
    function(v) LocalPlayer.Character.Humanoid.Health = v; data["basicdata"]["player"]["health"] = v end,
    "锁定当前血量", function(v) if v then enableLockHealth() else disableLockHealth() end end)
sliderLock(basicTab, "THub_Basic_Gravity", "世界重力", 0, 1000, data["basicdata"]["player"]["gravity"],
    function(v) Workspace.Gravity = v; data["basicdata"]["player"]["gravity"] = v end,
    "锁定世界重力", function(v) if v then enableLockGravity() else disableLockGravity() end end)

-- ===== 工具 Tab =====
local ToolsTab = SecCommon:Tab({ Title = "工具", Icon = "wrench" })
ToolsTab:Section({ Title = "各种实用工具", Opened = true })
ToolsTab:Toggle({
    Title = "防挂机",
    Flag = "THub_Tool_AntiAFK",
    Value = true,
    Callback = function(v) if v then enableAntiAFK() else disableAntiAFK() end end,
})
ToolsTab:Toggle({
    Title = "保留THub - 传送后自动执行",
    Flag = "THub_Tool_KeepTHub",
    Value = false,
    Callback = function(v) if v then enableKeepTHub() else disableKeepTHub() end end,
})
enableToggle(ToolsTab, "THub_Tool_Fly", "飞行", function()
    FlyModule.enable()
    WindUI:Notify({ Title = "提示", Content = "按住Ctrl+" .. FlyModule.getbindkey().Name .. "开关飞行状态", Icon = "info", Duration = 5 })
end, function() FlyModule.disable() end)
enableToggle(ToolsTab, "THub_Tool_CframeFly", "帧飞行", function()
    CframeFly.enable()
    WindUI:Notify({ Title = "提示", Content = "按住Ctrl+" .. CframeFly.getbindkey().Name .. "开关飞行状态", Icon = "info", Duration = 5 })
end, function() CframeFly.disable() end)
enableToggle(ToolsTab, "THub_Tool_VehicleFly", "载具飞行", function()
    VehicleFly.enable()
    WindUI:Notify({ Title = "提示", Content = "按住Ctrl+" .. VehicleFly.getbindkey().Name .. "开关飞行状态", Icon = "info", Duration = 5 })
end, function() VehicleFly.disable() end)
enableToggle(ToolsTab, "THub_Tool_ClickTP", "点击传送", function()
    TeleportModule.enable()
    WindUI:Notify({ Title = "提示", Content = "按住Ctrl并点击来传送", Icon = "info", Duration = 5 })
end, function() TeleportModule.disable() end)
enableToggle(ToolsTab, "THub_Tool_PlayerESP", "玩家透视", function() PlayerESP.enable() end, function() PlayerESP.disable() end)
enableToggle(ToolsTab, "THub_Tool_NPCESP", "NPC透视", function() data["basicdata"]["releasetools"]["npc"]:enable() end, function() data["basicdata"]["releasetools"]["npc"]:disable() end)
enableToggle(ToolsTab, "THub_Tool_TPWalk", "TPWalk", function() tpWalk:Enabled(true) end, function() tpWalk:Enabled(false) end)
enableToggle(ToolsTab, "THub_Tool_MouseUnlock", "鼠标解锁", function()
    MouseUnlockModule.enable()
    WindUI:Notify({ Title = "提示", Content = "按下K+L组合键开关解锁鼠标", Icon = "info", Duration = 5 })
end, function() MouseUnlockModule.disable() end)
enableToggle(ToolsTab, "THub_Tool_LockCamera", "锁定视角", function()
    LockCameraModule.enable()
    WindUI:Notify({ Title = "提示", Content = "按住" .. LockCameraModule.getBindKey().Name .. "键来锁定视角", Icon = "info", Duration = 5 })
end, function() LockCameraModule.disable() end)
enableToggle(ToolsTab, "THub_Tool_SnapTurn", "瞬间转向", function() SnapTurn.enable() end, function() SnapTurn.disable() end)
enableToggle(ToolsTab, "THub_Tool_SnapReverse", "瞬间回头", function()
    SnapReverse.enable()
    WindUI:Notify({ Title = "提示", Content = "按下" .. SnapReverse.GetKeyBind().Name .. "键来瞬间回头", Icon = "info", Duration = 5 })
end, function() SnapReverse.disable() end)
enableToggle(ToolsTab, "THub_Tool_Aimbot", "自动瞄准", function() AimBotModule.enable() end, function() AimBotModule.disable() end)
enableToggle(ToolsTab, "THub_Tool_ScrollSwitch", "物品滚轮切换", function()
    WindUI:Notify({ Title = "提示", Content = "按住" .. ScrollSwitch:getbind().Name .. "键并滚动鼠标滚轮来切换物品", Icon = "info", Duration = 5 })
    ScrollSwitch:enable()
end, function() ScrollSwitch:disable() end)
enableToggle(ToolsTab, "THub_Tool_Zoom", "望远镜", function()
    data["basicdata"]["releasetools"]["zoom"]:enable()
    WindUI:Notify({ Title = "提示", Content = "按住" .. tostring(data["basicdata"]["releasetools"]["zoom"]:GetBindKey()):gsub("^Enum%.%w+%.", "") .. "键放大", Icon = "info", Duration = 5 })
end, function() data["basicdata"]["releasetools"]["zoom"]:disable() end)
enableToggle(ToolsTab, "THub_Tool_Invisible", "隐身", function() PlayerVisibleModule.enable() end, function() PlayerVisibleModule.disable() end)
enableToggle(ToolsTab, "THub_Tool_Footstep", "查看落脚点", function() FootstepHighlighter.enable() end, function() FootstepHighlighter.disable() end)
enableToggle(ToolsTab, "THub_Tool_Landing", "落地特效", function() LandingEffect.enable() end, function() LandingEffect.disable() end)
ToolsTab:Toggle({
    Title = "夜视",
    Flag = "THub_Tool_NightVision",
    Value = false,
    Callback = function(v) if v then enableNightVision() else disableNightVision() end end,
})
ToolsTab:Toggle({
    Title = "超级夜视",
    Flag = "THub_Tool_SuperNightVision",
    Value = false,
    Callback = function(v) if v then enableSuperNightVision() else disableSuperNightVision() end end,
})
enableToggle(ToolsTab, "THub_Tool_AntiLookBlocker", "阻挡射线检测", function() AntiLookBlocker.enable() end, function() AntiLookBlocker.disable() end)
ToolsTab:Toggle({
    Title = "随身灯笼",
    Flag = "THub_Tool_Lantern",
    Value = false,
    Callback = function(v) data["basicdata"]["releasetools"]["Lantern"]["enable"] = v end,
})
ToolsTab:Toggle({
    Title = "超级光明",
    Flag = "THub_Tool_SuperLighter",
    Value = false,
    Callback = function(v) data["basicdata"]["releasetools"]["SuperLighter"]["enable"] = v end,
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
ToolsTab:Toggle({
    Title = "X光",
    Flag = "THub_Tool_Xray",
    Value = false,
    Callback = function(v)
        data["basicdata"]["releasetools"]["xray"] = v
        toggleXrayLoop(v)
        if v then xray(true) else xray(false) end
    end,
})
ToolsTab:Toggle({
    Title = "显示隐藏部件",
    Flag = "THub_Tool_ShowParts",
    Value = false,
    Callback = function(v) showpartsfunction(v) end,
})
ToolsTab:Toggle({
    Title = "灵魂出窍",
    Flag = "THub_Tool_Freecam",
    Value = false,
    Callback = function(v)
        FreecamModule.freecamenable = v
        if v and isMobile then
            WindUI:Notify({ Title = "提示", Content = "双击屏幕左上角加速、双击左下角减速", Icon = "info", Duration = 5 })
        end
    end,
})
enableToggle(ToolsTab, "THub_Tool_AirWalk", "空中移动", function() AirWalk.enable() end, function() AirWalk.disable() end)
enableToggle(ToolsTab, "THub_Tool_NoFall", "无摔落伤害", function() NoFall.enable() end, function() NoFall.disable() end)
enableToggle(ToolsTab, "THub_Tool_InstantInteract", "瞬间交互", function() InstantInteraction.enable() end, function() InstantInteraction.disable() end)
enableToggle(ToolsTab, "THub_Tool_Move", "平移", function()
    movementModule.enable()
    WindUI:Notify({ Title = "提示", Content = "按下↑↓←→键进行平移", Icon = "info", Duration = 5 })
end, function() movementModule.disable() end)
ToolsTab:Toggle({
    Title = "穿墙",
    Flag = "THub_Tool_Noclip",
    Value = false,
    Callback = function(v)
        if v then
            noclipenable(true)
        else
            noclipenable(false)
        end
    end,
})
ToolsTab:Toggle({
    Title = "连跳",
    Flag = "THub_Tool_InfJump",
    Value = false,
    Callback = function(v)
        if v then
            infjumpenable(true)
        else
            infjumpenable(false)
        end
    end,
})
local _autoJumpLast = 0
ToolsTab:Toggle({
    Title = "自动跳跃",
    Flag = "THub_Tool_AutoJump",
    Value = false,
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
    end,
})
enableToggle(ToolsTab, "THub_Tool_Anchor", "固定到世界", function()
    LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RootPart.Anchored = true
end, function()
    LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RootPart.Anchored = false
end)
enableToggle(ToolsTab, "THub_Tool_Spectate", "旁观模式", function() SpectatorModule.start() end, function() SpectatorModule.close() end)
enableToggle(ToolsTab, "THub_Tool_NoclipCam", "摄像头穿墙", function() NoclipCam.enable(LocalPlayer) end, function() NoclipCam.disable() end)
ToolsTab:Toggle({ Title = "防击倒", Flag = "THub_Tool_AntiFall", Value = false, Callback = function(v) if v then enableAntiFall() else disableAntiFall() end end })
enableToggle(ToolsTab, "THub_Tool_StandRecovery", "晕厥康复", function() StandRecovery:enableDetection() end, function() StandRecovery:disableDetection() end)
enableToggle(ToolsTab, "THub_Tool_FlingDetector", "防甩飞", function() FlingDetector.enable(LocalPlayer) end, function() FlingDetector.disable() end)
enableToggle(ToolsTab, "THub_Tool_AntiVoid", "反物理劫持", function() AntiVoidModule.enable() end, function() AntiVoidModule.disable() end)
enableToggle(ToolsTab, "THub_Tool_MovingPartCleaner", "移除移动部件", function() MovingPartCleaner.enable() end, function() MovingPartCleaner.disable() end)
enableToggle(ToolsTab, "THub_Tool_DefenseField", "防御立场", function() DefenseField.enable() end, function() DefenseField.disable() end)
ToolsTab:Toggle({
    Title = "管理员检测",
    Flag = "THub_Tool_StaffCheck",
    Value = false,
    Callback = function(v) if v then enableStaffCheck() else disableStaffCheck() end end,
})
enableToggle(ToolsTab, "THub_Tool_DeathAnnounce", "死亡播报", function() enableDeathAnnounce() end, function() disableDeathAnnounce() end)
ToolsTab:Toggle({
    Title = "防死亡",
    Flag = "THub_Tool_AntiDead",
    Value = false,
    Callback = function(v) if v then enableAntiDead() else disableAntiDead() end end,
})
ToolsTab:Toggle({
    Title = "聊天重发",
    Flag = "THub_Tool_ChatResend",
    Value = false,
    Callback = function(v) if v then enableChatResend() else disableChatResend() end end,
})
enableToggle(ToolsTab, "THub_Tool_ChatSpy", "聊天偷听", function() ChatSpy.enable() end, function() ChatSpy.disable() end)
enableToggle(ToolsTab, "THub_Tool_ChatSpammer", "自动喊话器", function() ChatSpammer.enable() end, function() ChatSpammer.disable() end)
ToolsTab:Input({
    Title = "喊话内容（每行一条）",
    Flag = "THub_Tool_SpamText",
    Value = ChatSpammer.getMessagesAsText(),
    Type = "Textarea",
    Placeholder = "每行一条喊话内容",
    Callback = function(text) ChatSpammer.setMessagesFromText(text) end,
})
ToolsTab:Slider({
    Title = "喊话间隔（秒）",
    Flag = "THub_Tool_SpamInterval",
    Step = 0.1,
    Value = { Min = 0.5, Max = 60, Default = ChatSpammer.getInterval() },
    Callback = function(v) ChatSpammer.setInterval(v) end,
})
ToolsTab:Toggle({ Title = "随机模式", Flag = "THub_Tool_SpamRandom", Value = ChatSpammer.isRandomMode(), Callback = function(v) ChatSpammer.setRandom(v) end })
enableToggle(ToolsTab, "THub_Tool_Sit", "坐下", function() LocalPlayer.Character:FindFirstChild("Humanoid").Sit = true end, function() LocalPlayer.Character:FindFirstChild("Humanoid").Sit = false end)
ToolsTab:Toggle({
    Title = "防踢出",
    Flag = "THub_Tool_AntiKick",
    Value = false,
    Callback = function(v)
        if v then
            local success, message = AntiKickModule.enable()
            if message == "Incompatible Exploit: missing hookmetamethod or LocalPlayer not accessible" then
                WindUI:Notify({ Title = "不支持的漏洞", Content = (identifyexecutor and identifyexecutor() or "UnKnown") .. "暂不支持此功能", Icon = "x", Duration = 5 })
            end
        else
            AntiKickModule.disable()
        end
    end,
})
enableToggle(ToolsTab, "THub_Tool_DeleteTool", "模型删除工具", function()
    DeleteTool.enable()
    WindUI:Notify({ Title = "提示", Content = "按住Ctrl键点击来删除指向的模型", Icon = "info", Duration = 5 })
end, function() DeleteTool.disable() end)
enableToggle(ToolsTab, "THub_Tool_GuiDeleter", "GUI删除工具", function()
    GuiDeleter.enable()
    WindUI:Notify({ Title = "提示", Content = "按下" .. GuiDeleter.getBindKey().Name .. "键来删除鼠标指向的UI", Icon = "info", Duration = 5 })
end, function() GuiDeleter.disable() end)
enableToggle(ToolsTab, "THub_Tool_ClickInspect", "模型信息查询工具", function()
    ClickInspectModule.enable()
    WindUI:Notify({ Title = "提示", Content = "按下Ctrl键点击来查看模型信息", Icon = "info", Duration = 5 })
end, function() ClickInspectModule.disable() end)
ToolsTab:Toggle({
    Title = "禁用购买提示框",
    Flag = "THub_Tool_NoPurchasePrompt",
    Value = false,
    Callback = function(v)
        if v then
            CoreGui.PurchasePromptApp.Enabled = false
        else
            CoreGui.PurchasePromptApp.Enabled = true
        end
    end,
})
ToolsTab:Toggle({
    Title = "禁用游戏暂停",
    Flag = "THub_Tool_NoPause",
    Value = false,
    Callback = function(v) if v then enableNetworkPauseDisable() else disableNetworkPauseDisable() end end,
})
enableToggle(ToolsTab, "THub_Tool_Translate", "游戏翻译", function()
    TranslationModule.enable()
    WindUI:Notify({ Title = "提示", Content = "正在翻译中，可能会比较慢\n速度限制2次/s", Icon = "info", Duration = 10 })
end, function() TranslationModule.disable() end)
enableToggle(ToolsTab, "THub_Tool_TCPTouch", "透视触点实例", function() TCPHighLight.touchinterest.enable() end, function() TCPHighLight.touchinterest.disable() end)
ToolsTab:Toggle({ Title = "禁用触点实例", Flag = "THub_Tool_NoTouch", Value = false, Callback = function(v) toggleInteraction("TouchTransmitter", v); WindUI:Notify({ Title = "提示", Content = v and "已禁用所有触点" or "已恢复所有触点", Icon = "info" }) end })
enableToggle(ToolsTab, "THub_Tool_TCPClick", "透视点击触发实例", function() TCPHighLight.clickdetectors.enable() end, function() TCPHighLight.clickdetectors.disable() end)
ToolsTab:Toggle({ Title = "禁用点击触发实例", Flag = "THub_Tool_NoClick", Value = false, Callback = function(v) toggleInteraction("ClickDetector", v) end })
enableToggle(ToolsTab, "THub_Tool_TCPrompt", "透视可交互实例", function() TCPHighLight.proximityprompts.enable() end, function() TCPHighLight.proximityprompts.disable() end)
ToolsTab:Toggle({ Title = "禁用可交互实例", Flag = "THub_Tool_NoPrompt", Value = false, Callback = function(v) toggleInteraction("ProximityPrompt", v) end })
ToolsTab:Button({ Title = "触发所有触点实例", Callback = function()
    local Root = LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RootPart or LocalPlayer.Character:FindFirstChildWhichIsA("BasePart")
    if not firetouchinterest then
        WindUI:Notify({ Title = "错误", Content = "你的执行器不支持此功能。", Icon = "x", Duration = 5 })
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
ToolsTab:Button({ Title = "触发所有点击触发实例", Callback = function()
    if fireclickdetector then
        for _, descendant in ipairs(Workspace:GetDescendants()) do
            if descendant:IsA("ClickDetector") then
                fireclickdetector(descendant)
            end
        end
    else
        WindUI:Notify({ Title = "错误", Content = "你的执行器不支持此功能。", Icon = "x", Duration = 5 })
    end
end })
ToolsTab:Button({ Title = "触发所有可交互实例", Callback = function()
    if fireproximityprompt then
        for _, descendant in ipairs(Workspace:GetDescendants()) do
            if descendant:IsA("ProximityPrompt") then
                fireproximityprompt(descendant)
            end
        end
    else
        WindUI:Notify({ Title = "错误", Content = "你的执行器不支持此功能。", Icon = "x", Duration = 5 })
    end
end })
ToolsTab:Button({ Title = "回满血", Callback = function() LocalPlayer.Character.Humanoid.Health = LocalPlayer.Character.Humanoid.MaxHealth end })
ToolsTab:Button({ Title = "自杀", Callback = function() LocalPlayer.Character.Humanoid.Health = 0 end })
ToolsTab:Button({ Title = "强制自杀", Callback = function() respawn() end })
ToolsTab:Button({ Title = "原地重生", Callback = function() refresh() end })
ToolsTab:Button({ Title = "设置当前位置为重生点", Callback = function() data["basicdata"]["releasetools"]["spawnpos"] = LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RootPart.CFrame end })
ToolsTab:Button({ Title = "恢复默认重生点", Callback = function() data["basicdata"]["releasetools"]["spawnpos"] = nil end })
ToolsTab:Button({ Title = "回到最后的死亡点", Callback = function() if data["basicdata"]["releasetools"]["lastDeath"] ~= nil then LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RootPart.CFrame = data["basicdata"]["releasetools"]["lastDeath"] else WindUI:Notify({ Title = "错误", Content = "没有记录的死亡点。", Icon = "x", Duration = 5 }) end end })
ToolsTab:Button({ Title = "获取游戏内全部工具", Callback = function() gettools() end })
ToolsTab:Button({ Title = "移除全部工具", Callback = function() removetools() end })
ToolsTab:Button({ Title = "丢弃手中工具", Callback = function() drophandtool(); WindUI:Notify({ Title = "掉落工具", Content = "已丢弃手中工具", Icon = "check", Duration = 3 }) end })
ToolsTab:Button({ Title = "丢弃全部工具", Callback = function() droptool(); WindUI:Notify({ Title = "掉落工具", Content = "已丢弃全部工具", Icon = "check", Duration = 3 }) end })
if not isMobile then
    ToolsTab:Button({ Title = "获得点击传送工具", Callback = function()
        local backpack = LocalPlayer:FindFirstChildWhichIsA("Backpack")
        if backpack and backpack:FindFirstChild("手持点击传送") then
            WindUI:Notify({ Title = "提示", Content = "点击传送工具已存在", Icon = "info", Duration = 2 })
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
end
ToolsTab:Button({ Title = "重新加入当前房间(服务器)", Callback = function() rejoinCurrentGame() end })
ToolsTab:Button({ Title = "切换角色为R6", Callback = function() promptNewRig("R6") end })
ToolsTab:Button({ Title = "切换角色为R15", Callback = function() promptNewRig("R15") end })
ToolsTab:Button({ Title = "切换时间为白天", Callback = function() setDay() end })
ToolsTab:Button({ Title = "切换时间为黑夜", Callback = function() setNight() end })
ToolsTab:Toggle({
    Title = "禁用雾效",
    Flag = "THub_Tool_NoFog",
    Value = false,
    Callback = function(v) RemoveFog(v) end,
})
ToolsTab:Button({ Title = "优化世界光效", Callback = function() loadstring(cloneref(game):HttpGet("https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/visual/WorldShader.lua"))() end })
ToolsTab:Button({ Title = "打印当前坐标", Callback = function()
    local position1 = LocalPlayer.Character.HumanoidRootPart.Position
    print(string.format("[THub] 玩家坐标: (%.2f, %.2f, %.2f)", position1.X, position1.Y, position1.Z))
end })
ToolsTab:Button({ Title = "开启控制台界面", Callback = function() StarterGui:SetCore("DevConsoleVisible", true) end })
ToolsTab:Button({ Title = "启用所有ROBLOXUI", Callback = function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end })
ToolsTab:Button({ Title = "获取建筑工具", Callback = function()
    local backpack = LocalPlayer:FindFirstChildWhichIsA("Backpack")
    if not backpack then return end
    local existing = 0
    for _, v in pairs(backpack:GetChildren()) do
        if v:IsA("HopperBin") then existing += 1 end
    end
    if existing >= 4 then
        WindUI:Notify({ Title = "提示", Content = "背包中已有建筑工具", Icon = "info", Duration = 2 })
        return
    end
    for i = 1, 4 do
        local Tool = Instance.new("HopperBin")
        Tool.BinType = i
        Tool.Name = randomString()
        Tool.Parent = backpack
    end
end })
if not isMobile then
    ToolsTab:Button({ Title = "终止当前游戏进程", Callback = function()
        if messagebox then
            local result = messagebox("Do you want to end the current game?\n\nIt may be used in situations where exit is not possible.", "Roblox", 4 + 32)
            if result == 6 then game:Shutdown() end
        else
            data["basicdata"]["releasetools"]["exitgame"] = data["basicdata"]["releasetools"]["exitgame"] + 1
            if data["basicdata"]["releasetools"]["exitgame"] == 1 then WindUI:Notify({ Title = "警告", Content = "你确定要终止游戏进程吗？", Icon = "triangle-alert", Duration = 10 }) end
            if data["basicdata"]["releasetools"]["exitgame"] == 2 then WindUI:Notify({ Title = "警告", Content = "再次确定？", Icon = "triangle-alert", Duration = 10 }) end
            if data["basicdata"]["releasetools"]["exitgame"] == 3 then WindUI:Notify({ Title = "警告", Content = "最终确定？", Icon = "triangle-alert", Duration = 10 }) end
            if data["basicdata"]["releasetools"]["exitgame"] == 4 then game:Shutdown() end
        end
    end })
end

-- ===== 脚本中心 Tab =====
local scripthubTab = SecCommon:Tab({ Title = "脚本中心", Icon = "monitor" })
scripthubTab:Section({ Title = "由作者推荐的脚本 - 注意大部分脚本未经过验证，请谨慎使用。", Opened = true })
local function addscripts(name, link)
    scripthubTab:Button({ Title = name, Callback = function()
        WindUI:Notify({ Title = "提示", Content = name .. "正在启动，请耐心等待。", Icon = "info", Duration = 5 })

        local content, success = AsyncFileFetcher.fetchSingle(link)
        if success then loadstring(content)() else WindUI:Notify({ Title = "提示", Content = name .. "启动失败。", Icon = "triangle-alert", Duration = 5 }) end
        WindUI:Notify({ Title = "提示", Content = name .. "启动成功。", Icon = "check", Duration = 5 })
    end })
end
for index, scriptInfo in ipairs(data["scriptlist"]) do
    addscripts(scriptInfo.name, scriptInfo.link)
end

-- ===== 玩家传送 Tab =====
local function createPlayerButton(player)
    return playerteleporterTab:Button({
        Title = player.DisplayName .. " (" .. player.Name .. ")",
        Callback = function()
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local targetCharacter = player.Character
                if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
                    character:SetPrimaryPartCFrame(CFrame.new(targetCharacter.HumanoidRootPart.Position))
                    WindUI:Notify({ Title = "传送成功", Content = "已传送到 " .. player.DisplayName, Icon = "check", Duration = 2 })
                else
                    WindUI:Notify({ Title = "传送失败", Content = "目标玩家角色不存在", Icon = "x", Duration = 2 })
                end
            else
                WindUI:Notify({ Title = "传送失败", Content = "无法获取你的角色", Icon = "x", Duration = 2 })
            end
        end
    })
end

playerteleporterTab = SecTeleport:Tab({ Title = "玩家传送", Icon = "contact-round" })
playerteleporterTab:Section({ Title = "玩家列表", Opened = true })
playerteleporterTab:Divider()
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
waypointTab = SecTeleport:Tab({ Title = "路径点传送", Icon = "map-pinned" })
waypointConfig = ConfigModule.createconfig("waypoint/data/" .. game.GameId)
waypointsData = waypointConfig.waypointsData and waypointConfig.waypointsData or {}
waypointUIElements = {}
waypointTitleMap = {}
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
end
local function updateWaypointTitle(id)
    local entry = waypointTitleMap[id]
    if not entry then return end
    local wp = waypointsData[id]
    if not wp then return end
    local noteStr = type(wp.note) == "string" and wp.note ~= "" and (" - " .. wp.note) or ""
    if entry.title and type(entry.title.SetTitle) == "function" then
        entry.title:SetTitle(string.format("📍 路径点 #%d%s", id, noteStr))
    end
end
local function buildWaypointElements(waypoint)
    local elements = {}
    if waypoint.id > 1 then
        local divider = waypointTab:Divider()
        table.insert(elements, divider)
    end
    local idNum = tonumber(waypoint.id) or 0
    local noteStr = type(waypoint.note) == "string" and waypoint.note or tostring(waypoint.note)
    local titleText = string.format("📍 路径点 #%d", idNum)
    if noteStr ~= "" then
        titleText = titleText .. " - " .. noteStr
    end
    local title = waypointTab:Section({ Title = titleText, Opened = true })
    table.insert(elements, title)
    waypointTitleMap[waypoint.id] = { title = title }
    local pos = waypoint.position
    local x = pos and pos.X or 0
    local y = pos and pos.Y or 0
    local z = pos and pos.Z or 0
    local coordText = string.format("坐标: X: %.1f, Y: %.1f, Z: %.1f", x, y, z)
    local coordLabel = waypointTab:Paragraph({ Title = coordText })
    table.insert(elements, coordLabel)
    local noteInput = waypointTab:Input({
        Title = "备注",
        Placeholder = "输入备注信息...",
        Value = noteStr,
        Callback = function(text)
            waypoint.note = text or ""
            waypointConfig.waypointsData = waypointsData
            updateWaypointTitle(waypoint.id)
        end
    })
    table.insert(elements, noteInput)
    local teleportBtn = waypointTab:Button({
        Title = "🚀 传送到此路径点",
        Callback = function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local targetPos = Vector3.new(pos.X, pos.Y, pos.Z)
                char:SetPrimaryPartCFrame(CFrame.new(targetPos))
                WindUI:Notify({ Title = "传送成功", Content = string.format("已传送到 %s", noteStr ~= "" and noteStr or "路径点"), Icon = "check", Duration = 2 })
            else
                WindUI:Notify({ Title = "传送失败", Content = "无法获取你的角色", Icon = "x", Duration = 2 })
            end
        end
    })
    table.insert(elements, teleportBtn)
    local tweenBtn = waypointTab:Button({
        Title = "🎯 缓动到此路径点",
        Callback = function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
                local targetPos = Vector3.new(pos.X, pos.Y, pos.Z)
                local root = char.HumanoidRootPart
                TweenService:Create(root, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)}):Play()
                WindUI:Notify({ Title = "缓动中", Content = string.format("正在缓动到 %s", noteStr ~= "" and noteStr or "路径点"), Icon = "info", Duration = 2 })
            else
                WindUI:Notify({ Title = "缓动失败", Content = "无法获取你的角色", Icon = "x", Duration = 2 })
            end
        end
    })
    table.insert(elements, tweenBtn)
    local walkBtn = waypointTab:Button({
        Title = "🚶 步行到此路径点",
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
                WindUI:Notify({ Title = "步行中", Content = string.format("正在走向 %s", noteStr ~= "" and noteStr or "路径点"), Icon = "info", Duration = 2 })
            else
                WindUI:Notify({ Title = "步行失败", Content = "无法获取你的角色", Icon = "x", Duration = 2 })
            end
        end
    })
    table.insert(elements, walkBtn)
    local deleteBtn = waypointTab:Button({
        Title = "🗑️ 删除此路径点",
        Callback = function()
            local removed = table.remove(waypointsData, waypoint.id)
            if removed then
                waypointTitleMap[waypoint.id] = nil
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
            WindUI:Notify({ Title = "已删除", Content = "路径点已移除", Icon = "info", Duration = 1 })
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
waypointTab:Section({ Title = "路径点管理", Opened = true })
waypointTab:Divider()
waypointTab:Paragraph({ Title = "点击下方按钮保存当前位置作为路径点" })
waypointTab:Toggle({
    Title = "在世界中显示路径点",
    Flag = "THub_Waypoint_Show",
    Value = false,
    Callback = function(v)
        waypointDisplayEnabled = v
        updateWaypointDisplay()
    end
})
waypointTab:Button({
    Title = "➕ 添加当前路径点",
    Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart then
            local position = LocalPlayer.Character.HumanoidRootPart.Position
            addWaypoint(position)
            WindUI:Notify({ Title = "路径点已添加", Content = string.format("位置: (%.1f, %.1f, %.1f)", position.X, position.Y, position.Z), Icon = "check", Duration = 2 })
        else
            WindUI:Notify({ Title = "添加失败", Content = "无法获取当前位置", Icon = "x", Duration = 2 })
        end
    end
})
waypointTab:Divider()
waypointTab:Section({ Title = "已保存的路径点", Opened = true })
waypointTab:Divider()
if #waypointsData > 0 then refreshWaypointList() end

-- ===== 音乐播放器 Tab =====
local musicislink = false
musicTab = SecMedia:Tab({ Title = "音乐播放器", Icon = "music" })
musicTab:Section({ Title = "音乐播放器", Opened = true })
musicTab:Divider()
musicTab:Paragraph({ Title = "选择预设音乐 (rbxassetid)" })
musicDropdown = musicTab:Dropdown({
    Title = "预设音乐ID",
    Values = data["basicdata"]["otherdata"]["musicData"]["musicIds"],
    Value = data["basicdata"]["otherdata"]["musicData"]["currentId"],
    Callback = function(selected)
        data["basicdata"]["otherdata"]["musicData"]["currentId"] = selected
        if customIdInput then
            customIdInput:Set(selected)
        end
    end
})
othermusicDropdown = musicTab:Dropdown({
    Title = "外部音乐",
    Values = (function() local names = {}; for musicname, _ in pairs(musicList) do table.insert(names, musicname) end; return names end)(),
    Value = nil,
    AllowNone = true,
    Callback = function(selected)
        for musicname, assid in pairs(musicList) do
            if musicname == selected then
                data["basicdata"]["otherdata"]["musicData"]["othermusicname"] = musicname
                data["basicdata"]["otherdata"]["musicData"]["currentId"] = assid
            end
        end
    end
})
local linkmusic = musicTab:Input({
    Title = "音乐直链",
    Value = "",
    Placeholder = "输入音乐直链",
    Callback = function(text)
        if text and text ~= "" then
            data["basicdata"]["otherdata"]["musicData"]["currentId"] = "link"
            data["basicdata"]["otherdata"]["musicData"]["currentlink"] = text
            musicislink = true
        end
    end
})
musicTab:Divider()
musicTab:Paragraph({ Title = "或手动输入自定义ID" })
customIdInput = musicTab:Input({
    Title = "自定义音乐ID",
    Value = tostring(data["basicdata"]["otherdata"]["musicData"]["currentId"]),
    Placeholder = "输入 rbxassetid，例如: 142376088",
    Callback = function(text)
        if text and text ~= "" then
            data["basicdata"]["otherdata"]["musicData"]["currentId"] = text
        end
    end
})
musicTab:Divider()
musicTab:Paragraph({ Title = "播放控制" })
playStopButton = nil
pauseResumeButton = nil
playStopButton = musicTab:Button({
    Title = "▶️ 播放",
    Callback = function()
        if data["basicdata"]["otherdata"]["musicData"]["isPlay"] then
            data["basicdata"]["otherdata"]["musicbox"]:Stop()
            data["basicdata"]["otherdata"]["musicData"]["isPlay"] = false
            data["basicdata"]["otherdata"]["musicData"]["isPause"] = false
            playStopButton:SetTitle("▶️ 播放")
            if pauseResumeButton then
                pauseResumeButton:SetTitle("⏸️ 暂停")
            end
            WindUI:Notify({ Title = "已停止", Content = "音乐播放已停止", Icon = "info", Duration = 2 })
        else
            if data["basicdata"]["otherdata"]["musicData"]["currentId"] == "link" then
                WindUI:Notify({ Title = "提示", Content = "正在读取链接内容，请稍等...", Icon = "info", Duration = 3 })
                local errorCode, result = ConfigModule.downloadAudio(data["basicdata"]["otherdata"]["musicData"]["currentlink"])
                if errorCode == 0 then
                    data["basicdata"]["otherdata"]["musicData"]["currentId"] = tostring(result)
                elseif errorCode == 1 then
                    WindUI:Notify({ Title = "播放失败", Content = "不是一个有效的直链音频", Icon = "x", Duration = 3 })
                elseif errorCode == 2 then
                    WindUI:Notify({ Title = "播放失败", Content = "缓存文件失败", Icon = "x", Duration = 3 })
                elseif errorCode == 3 then
                    WindUI:Notify({ Title = "播放失败", Content = "获取资产ID失败", Icon = "x", Duration = 3 })
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
                playStopButton:SetTitle("⏹️ 停止")
                if pauseResumeButton then
                    pauseResumeButton:SetTitle("⏸️ 暂停")
                end
                WindUI:Notify({ Title = "正在播放", Content = musicislink and data["basicdata"]["otherdata"]["musicData"]["currentlink"] or (productInfo.Name or ""), Icon = "info", Duration = 3 })
            else
                WindUI:Notify({ Title = "播放失败", Content = "无效的rbxassetid", Icon = "x", Duration = 3 })
                data["basicdata"]["otherdata"]["musicData"]["isPlay"] = false
            end
        end
    end
})
pauseResumeButton = musicTab:Button({
    Title = "⏸️ 暂停",
    Callback = function()
        if not data["basicdata"]["otherdata"]["musicData"]["isPlay"] then
            WindUI:Notify({ Title = "无法操作", Content = "请先播放音乐", Icon = "triangle-alert", Duration = 2 })
            return
        end
        if data["basicdata"]["otherdata"]["musicData"]["isPause"] then
            data["basicdata"]["otherdata"]["musicbox"]["TimePosition"] = data["basicdata"]["otherdata"]["musicData"]["PlayLocation"]
            data["basicdata"]["otherdata"]["musicbox"]:Play()
            data["basicdata"]["otherdata"]["musicData"]["isPause"] = false
            pauseResumeButton:SetTitle("⏸️ 暂停")
            WindUI:Notify({ Title = "继续播放", Content = "音乐已恢复", Icon = "info", Duration = 1 })
        else
            data["basicdata"]["otherdata"]["musicData"]["PlayLocation"] = data["basicdata"]["otherdata"]["musicbox"]["TimePosition"]
            data["basicdata"]["otherdata"]["musicbox"]:Stop()
            data["basicdata"]["otherdata"]["musicData"]["isPause"] = true
            pauseResumeButton:SetTitle("▶️ 继续")
            WindUI:Notify({ Title = "已暂停", Content = "音乐已暂停", Icon = "info", Duration = 1 })
        end
    end
})
loopButton = musicTab:Button({
    Title = "🔄 循环播放",
    Callback = function()
        data["basicdata"]["otherdata"]["musicbox"]["Looped"] = not data["basicdata"]["otherdata"]["musicbox"]["Looped"]
        loopButton:SetTitle(data["basicdata"]["otherdata"]["musicbox"]["Looped"] and "🔁 不循环播放" or "🔄 循环播放")
        WindUI:Notify({ Title = "设置已更改", Content = data["basicdata"]["otherdata"]["musicbox"]["Looped"] and "已开启循环播放" or "已关闭循环播放", Icon = "info", Duration = 1 })
    end
})
musicTab:Divider()
musicTab:Paragraph({ Title = "音量控制" })
volumeLabel = musicTab:Paragraph({ Title = string.format("当前音量: %.0f%%", data["basicdata"]["otherdata"]["musicbox"]["Volume"] * 100) })
musicTab:Button({
    Title = "🔊 音量 +",
    Callback = function()
        if data["basicdata"]["otherdata"]["musicbox"]["Volume"] < 1 then
            data["basicdata"]["otherdata"]["musicbox"]["Volume"] = math.min(1, data["basicdata"]["otherdata"]["musicbox"]["Volume"] + 0.1)
            volumeLabel:SetTitle(string.format("当前音量: %.0f%%", data["basicdata"]["otherdata"]["musicbox"]["Volume"] * 100))
        end
    end
})
musicTab:Button({
    Title = "🔉 音量 -",
    Callback = function()
        if data["basicdata"]["otherdata"]["musicbox"]["Volume"] > 0 then
            data["basicdata"]["otherdata"]["musicbox"]["Volume"] = math.max(0, data["basicdata"]["otherdata"]["musicbox"]["Volume"] - 0.1)
            volumeLabel:SetTitle(string.format("当前音量: %.0f%%", data["basicdata"]["otherdata"]["musicbox"]["Volume"] * 100))
        end
    end
})
musicTab:Divider()
musicTab:Paragraph({ Title = "音高控制" })
pitchLabel = musicTab:Paragraph({ Title = string.format("当前音高: %.1f", data["basicdata"]["otherdata"]["musicbox"]["Pitch"]) })
musicTab:Button({
    Title = "🎵 音高 +",
    Callback = function()
        data["basicdata"]["otherdata"]["musicbox"]["Pitch"] = data["basicdata"]["otherdata"]["musicbox"]["Pitch"] + 0.1
        pitchLabel:SetTitle(string.format("当前音高: %.1f", data["basicdata"]["otherdata"]["musicbox"]["Pitch"]))
    end
})
musicTab:Button({
    Title = "🎵 音高 -",
    Callback = function()
        if data["basicdata"]["otherdata"]["musicbox"]["Pitch"] > 0.1 then
            data["basicdata"]["otherdata"]["musicbox"]["Pitch"] = data["basicdata"]["otherdata"]["musicbox"]["Pitch"] - 0.1
            pitchLabel:SetTitle(string.format("当前音高: %.1f", data["basicdata"]["otherdata"]["musicbox"]["Pitch"]))
        end
    end
})
musicTab:Button({
    Title = "🔄 重置音高",
    Callback = function()
        data["basicdata"]["otherdata"]["musicbox"]["Pitch"] = 1
        pitchLabel:SetTitle(string.format("当前音高: %.1f", data["basicdata"]["otherdata"]["musicbox"]["Pitch"]))
    end
})
musicTab:Divider()
musicTab:Paragraph({ Title = "💡 提示：可从下拉框选择预设音乐，或手动输入自定义ID" })
musicTab:Paragraph({ Title = "📝 自定义ID格式：纯数字，如 142376088" })

-- ===== 音频检查器 Tab =====
audioCheckerTab = SecMedia:Tab({ Title = "音频检查器", Icon = "audio-waveform" })
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
        local emptyLabel = audioCheckerTab:Paragraph({ Title = "未检测到超过阈值的音频" })
        table.insert(data["basicdata"]["otherdata"]["audioData"]["audioListItems"], emptyLabel)
    else
        for _, soundInfo in ipairs(loudSounds) do
            local displayText = string.format("ID: %s | 响度: %.1f dB | 来源: %s",
                soundInfo.CleanSoundId or "未知",
                soundInfo.Loudness,
                soundInfo.Parent
            )
            local soundButton = audioCheckerTab:Button({
                Title = displayText,
                Callback = function()
                    if soundInfo.CleanSoundId then
                        data["basicdata"]["otherdata"]["audioData"]["currentSelectedId"] = soundInfo.CleanSoundId
                        if testIdLabel then
                            testIdLabel:SetTitle("当前选中ID: " .. soundInfo.CleanSoundId)
                        end
                        WindUI:Notify({ Title = "已选中", Content = "音频ID: " .. soundInfo.CleanSoundId .. "\n来源: " .. soundInfo.FullPath, Icon = "info", Duration = 3 })
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
audioCheckerTab:Section({ Title = "音频检查器", Opened = true })
audioCheckerTab:Paragraph({ Title = "筛选响度阈值 (建议10-50)" })
thresholdInput = audioCheckerTab:Input({
    Title = "响度阈值",
    Value = tostring(data["basicdata"]["otherdata"]["audioData"]["threshold"]),
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
audioCheckerTab:Toggle({
    Title = "开始检测音频",
    Flag = "THub_Audio_Enable",
    Value = false,
    Callback = function(v)
        data["basicdata"]["otherdata"]["audioData"]["enable"] = v
        if v then
            data["basicdata"]["otherdata"]["audioData"]["lastScanTime"] = tick()
            startAudioScanning()
            WindUI:Notify({ Title = "已开启", Content = "开始检测游戏中播放的音频", Icon = "check", Duration = 2 })
        else
            if data["basicdata"]["otherdata"]["audioData"]["scanConnection"] then
                data["basicdata"]["otherdata"]["audioData"]["scanConnection"]:Disconnect()
                data["basicdata"]["otherdata"]["audioData"]["scanConnection"] = nil
            end
            clearAudioListUI()
            WindUI:Notify({ Title = "已关闭", Content = "音频检测已停止", Icon = "info", Duration = 2 })
        end
    end
})
audioCheckerTab:Divider()
audioCheckerTab:Section({ Title = "测试播放", Opened = true })
testIdLabel = audioCheckerTab:Paragraph({ Title = "当前选中ID: 未选择" })
audioCheckerTab:Button({
    Title = "📋 复制选中ID到剪贴板",
    Callback = function()
        if data["basicdata"]["otherdata"]["audioData"]["currentSelectedId"] then
            setclipboard(data["basicdata"]["otherdata"]["audioData"]["currentSelectedId"])
            WindUI:Notify({ Title = "已复制", Content = data["basicdata"]["otherdata"]["audioData"]["currentSelectedId"] .. " 已复制到剪贴板", Icon = "info", Duration = 2 })
        else
            WindUI:Notify({ Title = "未选中", Content = "请先点击音频列表中的项目", Icon = "triangle-alert", Duration = 2 })
        end
    end
})
testSoundEndedConn = nil
testPlayButton = audioCheckerTab:Button({
    Title = "🎵 尝试播放",
    Callback = function()
        if not data["basicdata"]["otherdata"]["audioData"]["currentSelectedId"] then
            WindUI:Notify({ Title = "无法播放", Content = "请先选中一个音频ID", Icon = "triangle-alert", Duration = 2 })
            return
        end
        if data["basicdata"]["otherdata"]["audioData"]["isTesting"] then
            data["basicdata"]["otherdata"]["testSound"]:Stop()
            data["basicdata"]["otherdata"]["audioData"]["isTesting"] = false
            testPlayButton:SetTitle("🎵 尝试播放")
            if testSoundEndedConn then testSoundEndedConn:Disconnect(); testSoundEndedConn = nil end
            WindUI:Notify({ Title = "已停止", Content = "测试播放已停止", Icon = "info", Duration = 1 })
        else
            local soundId = "rbxassetid://" .. data["basicdata"]["otherdata"]["audioData"]["currentSelectedId"]
            data["basicdata"]["otherdata"]["testSound"]["SoundId"] = soundId
            local success, productInfo = pcall(function()
                return MarketplaceService:GetProductInfo(tonumber(data["basicdata"]["otherdata"]["audioData"]["currentSelectedId"]))
            end)
            if success and productInfo then
                data["basicdata"]["otherdata"]["testSound"]:Play()
                data["basicdata"]["otherdata"]["audioData"]["isTesting"] = true
                testPlayButton:SetTitle("⏹️ 结束播放")
                testIdLabel:SetTitle("测试ID: " .. data["basicdata"]["otherdata"]["audioData"]["currentSelectedId"])
                WindUI:Notify({ Title = "正在播放", Content = productInfo.Name, Icon = "info", Duration = 2 })
                if testSoundEndedConn then testSoundEndedConn:Disconnect() end
                testSoundEndedConn = data["basicdata"]["otherdata"]["testSound"]["Ended"]:Connect(function()
                    if data["basicdata"]["otherdata"]["audioData"]["isTesting"] then
                        data["basicdata"]["otherdata"]["audioData"]["isTesting"] = false
                        testPlayButton:SetTitle("🎵 尝试播放")
                        testSoundEndedConn = nil
                    end
                end)
            else
                WindUI:Notify({ Title = "播放失败", Content = data["basicdata"]["otherdata"]["audioData"]["currentSelectedId"] .. " 不是一个有效的音频ID", Icon = "x", Duration = 2 })
            end
        end
    end
})
audioCheckerTab:Divider()
audioCheckerTab:Section({ Title = "检测到的音频", Opened = true })
audioCheckerTab:Paragraph({ Title = "点击任意音频可选中并复制ID" })
audioCheckerTab:Divider()

-- ===== 聊天接收器 Tab =====
chatReceiverTab = SecMedia:Tab({ Title = "聊天接收器", Icon = "messages-square" })
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
    local messageLabel = chatReceiverTab:Paragraph({ Title = messageText })
    table.insert(chatMessages, messageLabel)
    local copyButton = chatReceiverTab:Button({
        Title = "📋 复制这条消息",
        Callback = function()
            local fullText = sender .. ": " .. text
            setclipboard(fullText)
            WindUI:Notify({ Title = "已复制", Content = "消息已复制到剪贴板", Icon = "info", Duration = 2 })
        end
    })
    table.insert(chatMessages, copyButton)
    local divider = chatReceiverTab:Divider()
    table.insert(chatMessages, divider)
    trimChatMessages()
end
chatReceiverTab:Section({ Title = "📨 聊天接收器", Opened = true })
chatReceiverTab:Divider()
chatReceiverTab:Paragraph({ Title = "实时接收游戏中所有玩家的聊天消息" })
chatReceiverTab:Divider()
chatReceiverTab:Section({ Title = "消息列表", Opened = true })
chatReceiverTab:Button({
    Title = "🗑️ 清空所有消息",
    Callback = function()
        clearChatMessages()
        WindUI:Notify({ Title = "已清空", Content = "所有聊天消息已清除", Icon = "info", Duration = 1 })
    end
})
chatReceiverTab:Divider()
chatReceiverTab:Paragraph({ Title = "💡 提示：点击消息下方的按钮可复制该条消息" })

-- ===== 滤镜控制器 Tab =====
filterTab = SecVisual:Tab({ Title = "滤镜控制器", Icon = "sparkles" })
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
        local noEffectLabel = filterTab:Paragraph({ Title = "未检测到任何后处理特效" })
        table.insert(dynamicControls, noEffectLabel)
        return
    end
    local titleLabel = filterTab:Section({ Title = "后处理特效开关", Opened = true })
    table.insert(dynamicControls, titleLabel)
    for _, effect in ipairs(allEffects) do
        local displayName = string.format("%s (%s)", effect.Name, effect.ClassName)
        local toggle = filterTab:Toggle({
            Title = displayName,
            Value = effect.Enabled,
            Callback = function(enabled)
                effect.Enabled = enabled
                local status = enabled and "启用" or "禁用"
                WindUI:Notify({ Title = "滤镜状态", Content = effect.Name .. " 已" .. status, Icon = enabled and "check" or "info", Duration = 2 })
            end
        })
        table.insert(dynamicControls, toggle)
    end
    if colorCorrection then
        local divider = filterTab:Divider()
        table.insert(dynamicControls, divider)
        local colorTitle = filterTab:Section({ Title = "颜色微调", Opened = true })
        table.insert(dynamicControls, colorTitle)
        local saturationSlider = filterTab:Slider({
            Title = "饱和度 (Saturation)", Step = 0.01,
            Value = { Min = -1, Max = 1, Default = colorCorrection.Saturation },
            Callback = function(value) colorCorrection.Saturation = value end
        })
        table.insert(dynamicControls, saturationSlider)
        local brightnessSlider = filterTab:Slider({
            Title = "亮度 (Brightness)", Step = 0.01,
            Value = { Min = -1, Max = 1, Default = colorCorrection.Brightness },
            Callback = function(value) colorCorrection.Brightness = value end
        })
        table.insert(dynamicControls, brightnessSlider)
        local contrastSlider = filterTab:Slider({
            Title = "对比度 (Contrast)", Step = 0.01,
            Value = { Min = -1, Max = 1, Default = colorCorrection.Contrast },
            Callback = function(value) colorCorrection.Contrast = value end
        })
        table.insert(dynamicControls, contrastSlider)
        local tintColorPicker = filterTab:Colorpicker({
            Title = "色调颜色 (TintColor)", Default = colorCorrection.TintColor,
            Callback = function(color) colorCorrection.TintColor = color end
        })
        table.insert(dynamicControls, tintColorPicker)
    end
    local resetDivider = filterTab:Divider()
    table.insert(dynamicControls, resetDivider)
    local resetButton = filterTab:Button({
        Title = "重置所有滤镜为默认状态",
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
            WindUI:Notify({ Title = "滤镜控制器", Content = "所有滤镜已重置为默认状态", Icon = "check", Duration = 3 })
            refreshFilterList(true)
        end
    })
    table.insert(dynamicControls, resetButton)
    local colorBlindDivider = filterTab:Divider()
    table.insert(dynamicControls, colorBlindDivider)
    local colorBlindTitle = filterTab:Section({ Title = "🎨 色盲模拟器", Opened = true })
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
        local cc = getColorCorrectionEffect()
        if not cc then
            cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "THub_ColorCorrection"
            cc.Parent = Lighting
        end
        cc.Enabled = true
        cc.Saturation = modeConfig.Saturation
        cc.Brightness = modeConfig.Brightness
        cc.Contrast = modeConfig.Contrast
        cc.TintColor = modeConfig.TintColor
    end
    local modeNames = {}
    for _, mode in ipairs(colorBlindModes) do
        table.insert(modeNames, mode.name)
    end
    local colorBlindDropdown = filterTab:Dropdown({
        Title = "选择色盲模式",
        Values = modeNames,
        Value = "正常",
        Callback = function(selected)
            currentColorBlindMode = selected
            for _, mode in ipairs(colorBlindModes) do
                if mode.name == selected then
                    applyColorBlindMode(mode.config)
                    WindUI:Notify({ Title = "色盲模拟器", Content = "已切换到: " .. selected, Icon = "info", Duration = 2 })
                    break
                end
            end
        end
    })
    table.insert(dynamicControls, colorBlindDropdown)
    local colorBlindNote = filterTab:Paragraph({ Title = "💡 选择一种色盲模式来模拟对应的视觉体验" })
    table.insert(dynamicControls, colorBlindNote)
    if showNotification == true then
        WindUI:Notify({ Title = "滤镜控制器", Content = "已刷新，找到 " .. #allEffects .. " 个特效", Icon = "check", Duration = 2 })
    end
end
local refreshButton = filterTab:Button({
    Title = "手动刷新滤镜列表",
    Callback = function()
        refreshFilterList(true)
    end
})
table.insert(staticControls, refreshButton)
local staticDivider = filterTab:Divider()
table.insert(staticControls, staticDivider)
refreshFilterList(false)

-- ===== 自定义称号 Tab =====
playertitleTab = SecVisual:Tab({ Title = "自定义称号", Icon = "tag" })
playertitleTab:Section({ Title = "自定义你的称号", Opened = true })
playertitleTab:Toggle({
    Title = "功能开关",
    Flag = "THub_Title_Enable",
    Value = false,
    Callback = function(v)
        if v then
            data["basicdata"]["otherdata"]["playertitle"]["tag"]:enable()
        else
            data["basicdata"]["otherdata"]["playertitle"]["tag"]:disable()
        end
    end
})
playertitleTab:Input({
    Title = "称号文本",
    Flag = "THub_Title_Text",
    Placeholder = "",
    Value = data["basicdata"]["otherdata"]["playertitle"]["text"],
    Callback = function(text)
        data["basicdata"]["otherdata"]["playertitle"]["text"] = text
    end
})
playertitleTab:Colorpicker({
    Title = "称号颜色",
    Default = hexToColor3(data["basicdata"]["otherdata"]["playertitle"]["color"]),
    Callback = function(color)
        data["basicdata"]["otherdata"]["playertitle"]["color"] = color3ToHex(color)
    end
})
playertitleTab:Slider({
    Title = "字号",
    Flag = "THub_Title_Size",
    Step = 1,
    Value = { Min = 1, Max = 50, Default = data["basicdata"]["otherdata"]["playertitle"]["size"] },
    Callback = function(v) data["basicdata"]["otherdata"]["playertitle"]["size"] = v end
})
playertitleTab:Toggle({
    Title = "加粗",
    Flag = "THub_Title_Bold",
    Value = false,
    Callback = function(v) data["basicdata"]["otherdata"]["playertitle"]["bold"] = v end
})
playertitleTab:Toggle({
    Title = "倾斜",
    Flag = "THub_Title_Italic",
    Value = false,
    Callback = function(v) data["basicdata"]["otherdata"]["playertitle"]["italic"] = v end
})
playertitleTab:Input({
    Title = "字体",
    Flag = "THub_Title_Font",
    Placeholder = "",
    Value = data["basicdata"]["otherdata"]["playertitle"]["font"],
    Callback = function(text)
        data["basicdata"]["otherdata"]["playertitle"]["font"] = text
    end
})
playertitleTab:Button({
    Title = "应用更改",
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
serverTab = SecTeleport:Tab({ Title = "服务器查询", Icon = "server" })
serverTab:Section({ Title = "公共服务器列表", Opened = true })
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
        WindUI:Notify({ Title = "提示", Content = "正在刷新中，请稍候...", Icon = "triangle-alert", Duration = 2 })
        return
    end
    clearServerList()
    isRefreshing = true
    local loadingLabel = serverTab:Paragraph({ Title = "⏳ 正在获取服务器列表..." })
    table.insert(serverUIElements, {loadingLabel})
    serverQuery:refreshAsync(function(servers)
        isRefreshing = false
        if loadingLabel and loadingLabel.Destroy then
            loadingLabel:Destroy()
        end
        clearServerList()
        if #servers == 0 then
            local emptyLabel = serverTab:Paragraph({ Title = "⚠️ 没有找到公共服务器，或 API 出错。" })
            table.insert(serverUIElements, {emptyLabel})
            return
        end
        local infoLabel = serverTab:Paragraph({ Title = "点击下方按钮可加入对应服务器" })
        table.insert(serverUIElements, {infoLabel})
        local divider1 = serverTab:Divider()
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
            local sInfoLabel = serverTab:Paragraph({ Title = infoText })
            table.insert(entryElements, sInfoLabel)
            local idLabel = serverTab:Paragraph({ Title = "ID: " .. tostring(serverData.id) })
            table.insert(entryElements, idLabel)
            local joinBtn = serverTab:Button({
                Title = "🚀 加入此服务器",
                Callback = function()
                    local ok, err = pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, serverData.id, LocalPlayer)
                    end)
                    if not ok then
                        WindUI:Notify({ Title = "传送失败", Content = "无法加入服务器: " .. tostring(err), Icon = "x", Duration = 3 })
                    end
                end
            })
            table.insert(entryElements, joinBtn)
            local sDivider = serverTab:Divider()
            table.insert(entryElements, sDivider)
            table.insert(serverUIElements, entryElements)
        end
    end)
end
serverTab:Button({
    Title = "🔄 刷新服务器列表",
    Callback = function()
        refreshServerList()
    end
})
serverTab:Divider()
serverTab:Paragraph({ Title = "💡 点击刷新按钮获取当前游戏的公共服务器" })
serverTab:Paragraph({ Title = "⚠️ 服务器数据来自 Roblox 官方 API，可能会有延迟" })
refreshServerList()

-- ===== 恶劣功能 Tab =====
hankerTab = SecRisk:Tab({ Title = "恶劣功能", Icon = "shield-alert" })
hankerTab:Section({ Title = "使用此部分的功能会导致封号", Opened = true })
hankerTab:Divider()
hankerTab:Paragraph({ Title = "普通功能" })
enableToggle(hankerTab, "THub_Hank_LoopOof", "循环OOF", function() LoopOofModule.enable() end, function() LoopOofModule.disable() end)
hankerTab:Button({ Title = "获得打飞机工具", Callback = function() getjerktool() end })
hankerTab:Divider()
hankerTab:Paragraph({ Title = "背起了行囊" })
hankerTab:Input({
    Title = "旋转速度",
    Flag = "THub_Hank_SpinSpeed",
    Placeholder = "",
    Value = "20",
    Callback = function(text)
        data["basicdata"]["hankermodule"]["spin"]["speed"] = tonumber(text)
        if SpinModule.isEnabled() then SpinModule.setSpeed(data["basicdata"]["hankermodule"]["spin"]["speed"]) end
    end
})
enableToggle(hankerTab, "THub_Hank_Spin", "开始旋转", function() SpinModule.enable(data["basicdata"]["hankermodule"]["spin"]["speed"]) end, function() SpinModule.disable() end)
hankerTab:Divider()
hankerTab:Paragraph({ Title = "击飞功能" })
enableToggle(hankerTab, "THub_Hank_FlingKey", "旋转击飞(Ctrl+G)", function() FlingModule.fling.setShortcutEnabled(true) end, function() FlingModule.fling.setShortcutEnabled(false) end)
enableToggle(hankerTab, "THub_Hank_FlyFling", "飞行击飞", function() FlingModule.flyfling.enable(2) end, function() FlingModule.flyfling.disable() end)
enableToggle(hankerTab, "THub_Hank_WalkFling", "走路击飞", function() FlingModule.walkfling.enable() end, function() FlingModule.walkfling.disable() end)
enableToggle(hankerTab, "THub_Hank_InvisFling", "隐身击飞", function() FlingModule.invisfling.enable() end, function() FlingModule.invisfling.disable() end)
hankerTab:Divider()
hankerTab:Paragraph({ Title = "击杀玩家" })
hankerTab:Input({
    Title = "要击杀的玩家名",
    Placeholder = "",
    Value = "PlayerName",
    Callback = function(text)
        data["basicdata"]["hankermodule"]["hkill"]["killname"] = text
    end
})
hankerTab:Input({
    Title = "距离",
    Placeholder = "",
    Value = "100",
    Callback = function(text)
        data["basicdata"]["hankermodule"]["hkill"]["killrange"] = tonumber(text) or 100
    end
})
hankerTab:Toggle({
    Title = "全部玩家",
    Value = false,
    Callback = function(v) data["basicdata"]["hankermodule"]["hkill"]["killall"] = v end
})
hankerTab:Toggle({
    Title = "全图",
    Value = false,
    Callback = function(v) data["basicdata"]["hankermodule"]["hkill"]["killany"] = v end
})
hankerTab:Button({ Title = "开始击杀", Callback = function()
    HandleKillModule.kill(data["basicdata"]["hankermodule"]["hkill"]["killall"] and "All" or data["basicdata"]["hankermodule"]["hkill"]["killname"], data["basicdata"]["hankermodule"]["hkill"]["killany"] and "Infinity" or data["basicdata"]["hankermodule"]["hkill"]["killrange"])
end })
hankerTab:Divider()
hankerTab:Paragraph({ Title = "甩飞传送" })
hankerTab:Divider()

local function executeFlingTeleport(player)
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then
        WindUI:Notify({ Title = "错误", Content = "无法获取你的角色", Icon = "x", Duration = 2 })
        return
    end
    local targetChar = player.Character
    if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then
        WindUI:Notify({ Title = "错误", Content = "目标玩家角色不存在", Icon = "x", Duration = 2 })
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
flingTeleportDropdown = hankerTab:Dropdown({
    Title = "选择要甩飞的玩家",
    Values = getPlayerOptions(),
    Value = nil,
    AllowNone = true,
    Callback = function(selected)
        local player = flingTeleportPlayerMap[selected]
        if player then executeFlingTeleport(player) end
    end
})
function updateFlingTeleportPlayerList()
    if flingTeleportDropdown then
        local options = getPlayerOptions()
        flingTeleportDropdown:Refresh(options)
    end
end

-- ===== 支持的游戏 Tab =====
supportedgamesTab = SecTeleport:Tab({ Title = "支持的游戏", Icon = "swords" })
supportedgamesTab:Section({ Title = "支持的游戏", Opened = true })
for _, GetgameInfo in ipairs(data["Supported_Games"]) do
    if GetgameInfo.gameid then
        supportedgamesTab:Button({ Title = GetgameInfo.name .. "(点击进入)", Callback = function() if game.GameId == GetgameInfo.gameid then WindUI:Notify({ Title = "提示", Content = "你已经在这个游戏里了。", Icon = "triangle-alert", Duration = 5 }) else GameTeleport.teleportByGameId(GetgameInfo.gameid) end end })
    end
end

-- ===== 执行器查询 Tab =====
weaoapiTab = SecInfo:Tab({ Title = "执行器查询", Icon = "cpu" })
weaoapiTab:Section({ Title = "Roblox版本", Opened = true })
local robloxLabels = {
    win = weaoapiTab:Paragraph({ Title = "Windows: 加载中..." }),
    winDate = weaoapiTab:Paragraph({ Title = "Windows更新日期: 加载中..." }),
    mac = weaoapiTab:Paragraph({ Title = "Mac: 加载中..." }),
    macDate = weaoapiTab:Paragraph({ Title = "Mac更新日期: 加载中..." }),
    android = weaoapiTab:Paragraph({ Title = "Android: 加载中..." }),
    androidDate = weaoapiTab:Paragraph({ Title = "Android更新日期: 加载中..." }),
    ios = weaoapiTab:Paragraph({ Title = "iOS: 加载中..." }),
    iosDate = weaoapiTab:Paragraph({ Title = "iOS更新日期: 加载中..." }),
}
weaoapiTab:Divider()
weaoapiTab:Section({ Title = "执行器状态", Opened = true })
local executorsTitle = weaoapiTab:Section({ Title = "加载中...", Opened = true })
local function rebuildExploiters()
    local ok, executors = pcall(parseExecutors, data["basicdata"]["otherdata"]["executordetecter"]["exploits"])
    if not ok or #executors == 0 then return end
    executorsTitle:Destroy()
    for _, exec in ipairs(executors) do
        weaoapiTab:Section({ Title = string.format("[%s] %s (%s) | %s", exec.platform, exec.title, exec.version, exec.updateStatus and "已更新(有效)" or "未更新(失效)"), Opened = false })
        weaoapiTab:Paragraph({ Title = "类型:" .. exec.extType .. " | " .. (exec.free and "免费" or ("付费(" .. exec.cost:gsub("Lifetime", "永久"):gsub("Weekly", "每周"):gsub("Monthly", "每月"):gsub("Private", "私人") .. ")")) .. " | " .. (exec.detected and "已被检测" or "未被检测") })
        weaoapiTab:Paragraph({ Title = (exec.uncStatus and ("UNC: " .. (exec.uncPercent or 0) .. "%") or "") .. ", sUNC: " .. (exec.suncPercent or 0) .. "%" })
        weaoapiTab:Paragraph({ Title = "更新时间:" .. exec.updatedDate })
        weaoapiTab:Paragraph({ Title = "密钥系统: " .. (exec.keysystem and "有" or "无") .. " 测试版:" .. (exec.beta and "是" or "否") .. " 反编译器: " .. (exec.decompiler and "有" or "无") .. " 多开支持: " .. (exec.multiInject and "支持" or "不支持") })
        weaoapiTab:Button({
            Title = "官网: " .. exec.website,
            Callback = function() setclipboard(exec.website); WindUI:Notify({ Title = "提示", Content = "已复制到剪切板", Icon = "info", Duration = 5 }) end
        })
        weaoapiTab:Button({
            Title = "Discord: " .. exec.discord,
            Callback = function() setclipboard(exec.discord); WindUI:Notify({ Title = "提示", Content = "已复制到剪切板", Icon = "info", Duration = 5 }) end
        })
        weaoapiTab:Divider()
    end
end
task.spawn(function()
    while true do
        local rd = data["basicdata"]["otherdata"]["executordetecter"]["robloxinfo"]
        if rd.Windows then
            robloxLabels.win:SetTitle("Windows: " .. rd.Windows)
            robloxLabels.winDate:SetTitle("Windows更新日期: " .. toChineseDate(rd.WindowsDate, true))
            robloxLabels.mac:SetTitle("Mac: " .. rd.Mac)
            robloxLabels.macDate:SetTitle("Mac更新日期: " .. toChineseDate(rd.MacDate, true))
            robloxLabels.android:SetTitle("Android: " .. rd.Android)
            robloxLabels.androidDate:SetTitle("Android更新日期: " .. toChineseDate(rd.AndroidDate, true))
            robloxLabels.ios:SetTitle("iOS: " .. rd.iOS)
            robloxLabels.iosDate:SetTitle("iOS更新日期: " .. toChineseDate(rd.iOSDate, true))
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
local SecGame = nil
for _, GetgameInfo in ipairs(data["Supported_Games"]) do
    if GetgameInfo.gameid == game.GameId then
        if not SecGame then
            SecGame = mainWindow:Section({ Title = "游戏专属" })
        end
        local OtherGameTab = SecGame:Tab({ Title = GetgameInfo.name, Icon = "gamepad-2" })
        OtherGameTab:Section({ Title = GetgameInfo.name, Opened = true })
        if GetgameInfo.name == "死亡球" then
            OtherGameTab:Toggle({
                Title = "主功能和界面",
                Flag = "THub_Game_DeathBall",
                Value = false,
                Callback = function(v) if v then _G.DeathBallScript:enable() else _G.DeathBallScript:disable() end end
            })
        elseif GetgameInfo.name == "小屋角色扮演" then
            OtherGameTab:Button({ Title = "变正常", Callback = function() ChatControl:chat("/re") end })
            OtherGameTab:Button({ Title = "变小孩", Callback = function() ChatControl:chat("/kid") end })
            OtherGameTab:Button({ Title = "鲨鱼服装", Callback = function() ChatControl:chat("/shark") end })
            OtherGameTab:Button({ Title = "修狗服装", Callback = function() ChatControl:chat("/dog") end })
            OtherGameTab:Button({ Title = "修猫服装", Callback = function() ChatControl:chat("/cat") end })
        elseif GetgameInfo.name == "南极探险队" then
            OtherGameTab:Paragraph({ Title = "基础操作" })
            OtherGameTab:Button({ Title = "传送到 大本营", Callback = function() TeleportTo(-6015, -158, -35) end })
            OtherGameTab:Button({ Title = "传送到 营地1", Callback = function() TeleportTo(-3719, 226, 235) end })
            OtherGameTab:Button({ Title = "传送到 营地2", Callback = function() TeleportTo(1790, 106, -138) end })
            OtherGameTab:Button({ Title = "传送到 营地3", Callback = function() TeleportTo(5892, 321, -18) end })
            OtherGameTab:Button({ Title = "传送到 营地4", Callback = function() TeleportTo(8992, 596, 102) end })
            OtherGameTab:Button({ Title = "传送到 营地5", Callback = function() TeleportTo(10990, 550, 104) end })
            OtherGameTab:Paragraph({ Title = "圣诞活动" })
            OtherGameTab:Button({ Title = "获取所有礼物", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/modules/games/SouthExpedition_Christmas_getallgifts.lua"))() end })
            OtherGameTab:Input({
                Title = "礼物号",
                Placeholder = "",
                Value = "",
                Callback = function(text)
                    data["othergamedata"]["AntarcticExpedition"]["giftnumber"] = text
                end
            })
            OtherGameTab:Button({ Title = "传送到礼物", Callback = function() TeleportToPresent(tonumber(data["othergamedata"]["AntarcticExpedition"]["giftnumber"])) end })
        elseif GetgameInfo.name == "西部森林" then
            enableToggle(OtherGameTab, "THub_Game_WestWood_Monster", "怪物标签", function() data["othergamedata"]["west_wood"]["monster"]:enable() end, function() data["othergamedata"]["west_wood"]["monster"]:disable() end)
        elseif GetgameInfo.name == "警笛头:遗产" then
            local sl = data["othergamedata"]["sirenhead_legacy"]
            enableToggle(OtherGameTab, "THub_Game_Siren_Crate", "透视盒子", function() sl.cratemodule.apply(); sl.cratenametagmodule:enable() end, function() sl.cratemodule.destroy(); sl.cratenametagmodule:disable() end)
            enableToggle(OtherGameTab, "THub_Game_Siren_Berry", "透视浆果", function() sl.berrymodule.apply(); sl.berynametagmodule:enable() end, function() sl.berrymodule.destroy(); sl.berynametagmodule:disable() end)
            OtherGameTab:Button({ Title = "传送到树顶", Callback = function() TeleportTo(69, 206, -72) end })
        elseif GetgameInfo.name == "噩梦之行" then
            enableToggle(OtherGameTab, "THub_Game_Nightmare_Monster", "高亮怪物", function() data["othergamedata"]["nightmare_run"]["monster"]:enable() end, function() data["othergamedata"]["nightmare_run"]["monster"]:disable() end)
            OtherGameTab:Button({ Title = "高亮芝士", Callback = function() data["othergamedata"]["nightmare_run"]["HLCheese"].apply() end })
            OtherGameTab:Button({ Title = "无敌(怪物不追不杀)", Callback = function()
                local ClientScripts = PlayerGui.ClientScripts
                local Events = ReplicatedStorage.Events
                if ClientScripts:FindFirstChild("SafeSpaceHandler") then
                    ClientScripts.SafeSpaceHandler:Destroy()
                end
                LocalPlayer:SetAttribute("Safe", true)
                Events.SetAttributeEvent:FireServer("Safe", true)
                WindUI:Notify({ Title = "提示", Content = "已设置玩家安全状态\n死亡前生效", Icon = "info", Duration = 5 })
            end })
        elseif GetgameInfo.name == "兽化项目" then
            OtherGameTab:Paragraph({ Title = "基础操作" })
            local function deleteModelsByName(modelName, displayName)
                local deletedCount = 0
                for _, model in ipairs(Workspace:GetDescendants()) do
                    if model:IsA("Model") and model.Name == modelName then
                        model:Destroy()
                        deletedCount = deletedCount + 1
                    end
                end
                WindUI:Notify({ Title = "提示", Content = "已删除" .. deletedCount .. "个" .. displayName, Icon = "info", Duration = 10 })
            end
            OtherGameTab:Button({ Title = "删除捕兽夹", Callback = function() deleteModelsByName("__SnarePhysical", "捕兽夹") end })
            OtherGameTab:Button({ Title = "删除地雷", Callback = function() deleteModelsByName("Landmine", "地雷") end })
            OtherGameTab:Button({ Title = "删除阔剑地雷", Callback = function() deleteModelsByName("__ClaymorePhysical", "阔剑地雷") end })
            OtherGameTab:Paragraph({ Title = "透视功能" })
            local pt = data["othergamedata"]["project_transfur"]
            enableToggle(OtherGameTab, "THub_Game_PT_Bot", "Bot兽", function() pt.bot.apply(); pt.botnt:enable() end, function() pt.bot.destroy(); pt.botnt:disable() end)
            enableToggle(OtherGameTab, "THub_Game_PT_SmallSafe", "小保险箱", function() pt.smallsafe.apply(); pt.smallsafent:enable() end, function() pt.smallsafe.destroy(); pt.smallsafent:disable() end)
            enableToggle(OtherGameTab, "THub_Game_PT_LargeSafe", "大保险箱", function() pt.largesafe.apply(); pt.largesafent:enable() end, function() pt.largesafe.destroy(); pt.largesafent:disable() end)
            enableToggle(OtherGameTab, "THub_Game_PT_GoldenSafe", "金保险箱", function() pt.goldensafe.apply(); pt.goldensafent:enable() end, function() pt.goldensafe.destroy(); pt.goldensafent:disable() end)
            enableToggle(OtherGameTab, "THub_Game_PT_Crate", "武器盒", function() pt.crate.apply(); pt.cratent:enable() end, function() pt.crate.destroy(); pt.cratent:disable() end)
            enableToggle(OtherGameTab, "THub_Game_PT_SupplyDrop", "空投", function() pt.sd.apply(); pt.sdnt:enable() end, function() pt.sd.destroy(); pt.sdnt:disable() end)
        elseif GetgameInfo.name == "妄想办公室" then
            OtherGameTab:Toggle({
                Title = "实体警告",
                Flag = "THub_Game_Office_EntityWarn",
                Value = false,
                Callback = function(v) if v then enableEntityWarning() else disableEntityWarning() end end
            })
            OtherGameTab:Toggle({
                Title = "提醒他人",
                Flag = "THub_Game_Office_TipOthers",
                Value = false,
                Callback = function(v) data["othergamedata"]["delesions_office"]["tipotherplayer"] = v end
            })
            OtherGameTab:Toggle({
                Title = "自动EN-013",
                Flag = "THub_Game_Office_Auto013",
                Value = false,
                Callback = function(v) if v then enableAuto013() else disableAuto013() end end
            })
        elseif GetgameInfo.name == "格蕾丝" then
            OtherGameTab:Toggle({
                Title = "自动拉杆",
                Flag = "THub_Game_Grace_AutoLever",
                Value = false,
                Callback = function(v) if v then enableAutoLever() else disableAutoLever() end end
            })
            OtherGameTab:Button({ Title = "删除全部实体(无法关闭)", Callback = function() enableDeleteEntity() end })
        elseif GetgameInfo.name == "深渊" then
            OtherGameTab:Button({ Title = "一键获取全地图深渊能量和回音", Callback = function()
                OBOTeleportModule.TeleportToParts({"AbyssalEnergy", "BigAbyssalEnergy", "Echo"}, 0.01)
            end })
            OtherGameTab:Button({ Title = "一键解锁全地图路径点", Callback = function()
                OBOTeleportModule.TeleportToParts("SpawnLocation", 0.1)
            end })
            OtherGameTab:Button({ Title = "传送到 灯笼商店", Callback = function() TeleportTo(-375, -11932, -504) end })
        elseif GetgameInfo.name == "后院生存" then
            OtherGameTab:Paragraph({ Title = "透视功能" })
            local bs = data["othergamedata"]["backroomsurvival"]
            enableToggle(OtherGameTab, "THub_Game_BS_SkinStealer", "窃皮者", function() bs.SkinStealer.apply(); bs.SkinStealernt:enable() end, function() bs.SkinStealer.destroy(); bs.SkinStealernt:disable() end)
            enableToggle(OtherGameTab, "THub_Game_BS_Shrieker", "瞎子", function() bs.Shrieker.apply(); bs.Shriekernt:enable() end, function() bs.Shrieker.destroy(); bs.Shriekernt:disable() end)
            enableToggle(OtherGameTab, "THub_Game_BS_Wretch", "悲尸", function() bs.Wretch.apply(); bs.Wretchnt:enable() end, function() bs.Wretch.destroy(); bs.Wretchnt:disable() end)
            enableToggle(OtherGameTab, "THub_Game_BS_Phantom", "梦魇", function() bs.Phantom.apply(); bs.Phantomnt:enable() end, function() bs.Phantom.destroy(); bs.Phantomnt:disable() end)
            enableToggle(OtherGameTab, "THub_Game_BS_Bacteria", "细菌", function() bs.Bacteria.apply(); bs.Bacteriant:enable() end, function() bs.Bacteria.destroy(); bs.Bacteriant:disable() end)
            enableToggle(OtherGameTab, "THub_Game_BS_Recon", "侦察兵", function() bs.Recon.apply(); bs.Reconnt:enable() end, function() bs.Recon.destroy(); bs.Reconnt:disable() end)
            enableToggle(OtherGameTab, "THub_Game_BS_Mechanic", "修理工", function() bs.Mechanic.apply(); bs.Mechanicnt:enable() end, function() bs.Mechanic.destroy(); bs.Mechanicnt:disable() end)
        elseif GetgameInfo.name == "最黑暗的时刻" then
            OtherGameTab:Paragraph({ Title = "透视功能" })
            local dh = data["othergamedata"]["DarkestHours"]
            enableToggle(OtherGameTab, "THub_Game_DH_Scrap", "收集物", function() dh.Collectible.apply(); dh.Collectiblent:enable() end, function() dh.Collectible.destroy(); dh.Collectiblent:disable() end)
        elseif GetgameInfo.name == "画我" then
            OtherGameTab:Section({ Title = "画我 - 图片绘制工具", Opened = true })
            OtherGameTab:Paragraph({ Title = "将本地图片或网络图片绘制到 EditableImage 画布上" })
            local drawmeStatusLabel = OtherGameTab:Paragraph({ Title = "就绪" })
            local drawmeFileDropdown = OtherGameTab:Dropdown({
                Title = "本地图片文件",
                Values = {},
                Value = nil,
                AllowNone = true,
                Callback = function(selected)
                    if selected and selected ~= "" then
                        data["basicdata"]["otherdata"]["drawme"]["linkorpath"] = "ChronixHubConfig/image/" .. selected
                    end
                end
            })
            local drawmeLinkInput = OtherGameTab:Input({
                Title = "图片直链/路径",
                Placeholder = "输入图片URL或文件路径",
                Value = data["basicdata"]["otherdata"]["drawme"]["linkorpath"] or "",
                Callback = function(text)
                    data["basicdata"]["otherdata"]["drawme"]["linkorpath"] = text
                end
            })
            local function refreshDrawmeFileList()
                local files = {}
                if listfiles then
                    local ok, fileList = pcall(listfiles, "ChronixHubConfig/image/")
                    if ok and fileList then
                        for _, f in ipairs(fileList) do
                            local name = string.match(f, "[^\\/]+$")
                            if name then table.insert(files, name) end
                        end
                    end
                end
                data["othergamedata"]["drawme"]["files"] = files
                if drawmeFileDropdown and drawmeFileDropdown.Refresh then
                    drawmeFileDropdown:Refresh(files)
                end
            end
            refreshDrawmeFileList()
            OtherGameTab:Button({
                Title = "刷新文件列表",
                Callback = function()
                    refreshDrawmeFileList()
                    drawmeStatusLabel:SetTitle("已刷新文件列表")
                end
            })
            OtherGameTab:Button({
                Title = "放置图片",
                Callback = function()
                    local source = data["basicdata"]["otherdata"]["drawme"]["linkorpath"]
                    if not source or source == "" then
                        drawmeStatusLabel:SetTitle("错误: 未指定图片路径")
                        return
                    end
                    drawmeStatusLabel:SetTitle("正在加载图片...")
                    local ok, err = pcall(function()
                        local result = DrawmeModule.loadAndDraw(source)
                        if result == 0 then
                            drawmeStatusLabel:SetTitle("成功: 图片已绘制")
                        elseif result == 1 then
                            drawmeStatusLabel:SetTitle("错误: 未找到 EditableImage 画布")
                        elseif result == 2 then
                            drawmeStatusLabel:SetTitle("错误: 文件不存在")
                        elseif result == 3 then
                            drawmeStatusLabel:SetTitle("错误: 网络请求失败")
                        elseif result == 4 then
                            drawmeStatusLabel:SetTitle("错误: 图片解码失败")
                        elseif result == 5 then
                            drawmeStatusLabel:SetTitle("错误: 写入画布失败")
                        else
                            drawmeStatusLabel:SetTitle("错误: 未知错误 (" .. tostring(result) .. ")")
                        end
                    end)
                    if not ok then
                        drawmeStatusLabel:SetTitle("错误: " .. tostring(err))
                    end
                end
            })
        elseif GetgameInfo.name == "后悔电梯" then
            OtherGameTab:Paragraph({ Title = "通用" })
            enableToggle(OtherGameTab, "THub_Game_Reg_IceCream", "自动舔冰淇凌（确保快捷栏中有冰淇凌）", function() Regretevator_AutoIceCream:enable() end, function() Regretevator_AutoIceCream:disable() end)
            local rg = data["othergamedata"]["Regretevator"]
            enableToggle(OtherGameTab, "THub_Game_Reg_Coins", "透视硬币", function() rg.coins.apply(); rg.coinsnt:enable() end, function() rg.coins.destroy(); rg.coinsnt:disable() end)
            OtherGameTab:Paragraph({ Title = "Bugbo楼层" })
            enableToggle(OtherGameTab, "THub_Game_Reg_Rocks", "透视石头", function() rg.bugbo_rocks.apply(); rg.bugbo_rocksnt:enable() end, function() rg.bugbo_rocks.destroy(); rg.bugbo_rocksnt:disable() end)
            OtherGameTab:Paragraph({ Title = "森林营地楼层" })
            enableToggle(OtherGameTab, "THub_Game_Reg_Wood", "透视木头", function() rg.firewood.apply(); rg.firewoodnt:enable() end, function() rg.firewood.destroy(); rg.firewoodnt:disable() end)
        end
    end
end

-- ===== 关于 Tab =====
infoTab = SecInfo:Tab({ Title = "关于", Icon = "info" })
infoTab:Paragraph({
    Title = "关于 THub V3",
    Desc = "THub V3 是一个功能强大的 Roblox 多功能工具集\n\n"
    .. "开发者: Furrycalin和0988\n"
    .. "版本: V3\n"
    .. "框架: 基于 WindUI 库构建\n\n"
    .. "注意事项:\n"
    .. "• 请合理使用各项功能\n"
    .. "• 部分功能可能在游戏中被检测\n"
    .. "• 使用前请了解游戏规则"
})
infoTab:Divider()
local hwidlabel
if gethwid then hwidlabel = infoTab:Paragraph({ Title = string.format("设备唯一标识码(HWID): %s", maskStringMiddle(gethwid())) }) end
rbxactivelabel = nil
if isrbxactive then rbxactivelabel = infoTab:Paragraph({ Title = string.format("焦点检测: %s", (isrbxactive() and "True" or "False")) }) end
pingLabel = infoTab:Paragraph({ Title = string.format("网络延迟: %s", math.round(LocalPlayer:GetNetworkPing() * 1000) .. "ms") })
memLabel = infoTab:Paragraph({ Title = string.format("客户端脚本占用内存: %.2f MB", getMemoryUsage("MB")) })
infoTab:Button({ Title = "强制内存垃圾回收", Callback = function()
    collectgarbage("collect")
    WindUI:Notify({ Title = "提示", Content = "已进行垃圾回收\n请不要频繁使用，可能会影响性能。", Icon = "info", Duration = 5 })
end })
infoTab:Paragraph({ Title = data["basicdata"]["otherdata"]["yiyan"]["data"]["hitokoto"] })

-- ===== 设置 Tab（原 ChronixUI 内置 SettingsElements，现为独立 WindUI Tab） =====
settingsTab = SecInfo:Tab({ Title = "设置", Icon = "settings" })
settingsTab:Section({ Title = "Roblox 设置", Opened = true })
settingsTab:Input({
    Title = "Roblox - 缩放倍率",
    Flag = "THub_Set_Zoom",
    Placeholder = "这里输入你的视角倍率",
    Value = tostring(LocalPlayer.CameraMaxZoomDistance),
    Callback = function(text)
        local num = tonumber(text)
        if num then
            LocalPlayer.CameraMaxZoomDistance = num
        end
    end
})
if getfpscap and setfpscap then
    settingsTab:Input({
        Title = "Roblox - 帧率上限",
        Flag = "THub_Set_FpsCap",
        Placeholder = "这里输入你的最大帧率",
        Value = tostring(getfpscap()),
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
    settingsTab:Keybind({
        Title = "Roblox - 鼠标锁定键",
        Flag = "THub_Set_MouseLock",
        Value = keyName(boundKeys and boundKeys.Value),
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
settingsTab:Divider()

settingsTab:Section({ Title = "UI 设置", Opened = true })
settingsTab:Keybind({
    Title = "UI 开关按键",
    Flag = "THub_Set_ToggleKey",
    Value = "RightShift",
    Callback = function(key)
        local nk = safeGetKeyCode(key)
        if nk then
            mainWindow:SetToggleKey(nk)
        end
    end
})
settingsTab:Divider()

settingsTab:Section({ Title = "功能按键绑定", Opened = true })
if not (isMobile and true) then
    -- 桌面端全量按键绑定（移动端隐藏部分触屏无意义的绑定）
end
local function settingKeybindVisible(label)
    if not isMobile then return true end
    local hiddenKeybindLabels = {
        ["灵魂出窍"] = true, ["望远镜"] = true, ["锁定视角"] = true,
        ["滚轮切换按键"] = true, ["GUI删除工具"] = true, ["瞬间回头"] = true,
        ["自动瞄准-绑定按键"] = true,
    }
    return not hiddenKeybindLabels[label]
end
if settingKeybindVisible("灵魂出窍") then
    settingsTab:Keybind({
        Title = "灵魂出窍",
        Flag = "THub_Set_Freecam",
        Value = keyName(FreecamModule.getKeybind()),
        Callback = function(key)
            local newKey = safeGetKeyCode(key)
            if newKey then
                FreecamModule.setKeybind(newKey)
            end
        end
    })
end
if settingKeybindVisible("望远镜") then
    settingsTab:Keybind({
        Title = "望远镜",
        Flag = "THub_Set_ZoomKey",
        Value = keyName(data["basicdata"]["releasetools"]["zoom"]:GetBindKey()),
        Callback = function(key)
            local newKey = safeGetKeyCode(key)
            if newKey then
                data["basicdata"]["releasetools"]["zoom"]:SetBindKey(newKey)
            end
        end
    })
end
if settingKeybindVisible("锁定视角") then
    settingsTab:Keybind({
        Title = "锁定视角",
        Flag = "THub_Set_LockCam",
        Value = keyName(LockCameraModule.getBindKey()),
        Callback = function(key)
            if key then
                LockCameraModule.setBindKey(key)
            end
        end
    })
end
if settingKeybindVisible("滚轮切换按键") then
    settingsTab:Keybind({
        Title = "滚轮切换按键",
        Flag = "THub_Set_ScrollSwitch",
        Value = keyName(ScrollSwitch:getbind()),
        Callback = function(key)
            if key then
                local newKey = safeGetKeyCode(key)
                ScrollSwitch:setbind(newKey)
            end
        end
    })
end
if settingKeybindVisible("GUI删除工具") then
    settingsTab:Keybind({
        Title = "GUI删除工具",
        Flag = "THub_Set_GuiDeleter",
        Value = keyName(GuiDeleter.getBindKey()),
        Callback = function(key)
            local newKey = safeGetKeyCode(key)
            if newKey then
                GuiDeleter.setBindKey(newKey)
            end
        end
    })
end
if settingKeybindVisible("瞬间回头") then
    settingsTab:Keybind({
        Title = "瞬间回头",
        Flag = "THub_Set_SnapReverse",
        Value = keyName(SnapReverse.GetKeyBind()),
        Callback = function(key)
            if key then
                local newKey = safeGetKeyCode(key)
                if newKey then
                    SnapReverse.SetKeyBind(newKey)
                end
            end
        end
    })
end
settingsTab:Divider()
settingsKeybindInput(settingsTab, "THub_Set_Fly", "飞行 (Ctrl+)", FlyModule.getbindkey().Name, function(k) FlyModule.setbindkey(k) end, "飞行速度", FlyModule.getflyspeed(), function(v) FlyModule.setflyspeed(v) end)
settingsKeybindInput(settingsTab, "THub_Set_CframeFly", "帧飞行 (Ctrl+)", CframeFly.getbindkey().Name, function(k) CframeFly.setbindkey(k) end, "帧飞行速度", CframeFly.getspeed(), function(v) CframeFly.setspeed(v) end)
settingsKeybindInput(settingsTab, "THub_Set_VehicleFly", "载具飞行 (Ctrl+)", VehicleFly.getbindkey().Name, function(k) VehicleFly.setbindkey(k) end, "载具飞行速度", VehicleFly.getspeed(), function(v) VehicleFly.setspeed(v) end)
settingsTab:Divider()
settingsTab:Input({
    Title = "TPWalk距离",
    Flag = "THub_Set_TPWalk",
    Placeholder = "",
    Value = tostring(tpWalk:GetSpeed()),
    Callback = function(text)
        local num = tonumber(text)
        if num then
            tpWalk:SetSpeed(num)
        end
    end
})
settingsTab:Input({
    Title = "平移距离",
    Flag = "THub_Set_MoveDist",
    Placeholder = "",
    Value = tostring(movementModule.GetDistance()),
    Callback = function(text)
        local num = tonumber(text)
        if num then
            movementModule.SetDistance(num)
        end
    end
})
local function aimbotVisible(label)
    if not isMobile then return true end
    local hidden = {
        ["自动瞄准-使用鼠标控制"] = true, ["自动瞄准-鼠标模式"] = true,
    }
    return not hidden[label]
end
if settingKeybindVisible("自动瞄准-绑定按键") then
    settingsTab:Keybind({
        Title = "自动瞄准-绑定按键",
        Flag = "THub_Set_AimKey",
        Value = keyName(AimBotModule.GetKey()),
        Callback = function(key)
            if key then
                local newKey = safeGetKeyCode(key)
                AimBotModule.SetKey(newKey)
            end
        end
    })
end
settingsTab:Toggle({
    Title = "自动瞄准-队伍检查",
    Flag = "THub_Set_AimTeam",
    Value = false,
    Callback = function(v) AimBotModule.SetTeamCheck(v) end
})
settingsTab:Toggle({
    Title = "自动瞄准-墙壁检查",
    Flag = "THub_Set_AimWall",
    Value = false,
    Callback = function(v) AimBotModule.SetWallCheck(v) end
})
settingsTab:Dropdown({
    Title = "自动瞄准-命中部位",
    Flag = "THub_Set_AimPart",
    Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    Value = AimBotModule.GetHitScan(),
    Callback = function(selected) AimBotModule.SetHitScan(selected) end
})
if aimbotVisible("自动瞄准-使用鼠标控制") then
    settingsTab:Toggle({
        Title = "自动瞄准-使用鼠标控制",
        Flag = "THub_Set_AimMouse",
        Value = AimBotModule.GetUseMouse(),
        Callback = function(v) AimBotModule.SetUseMouse(v) end
    })
end
if aimbotVisible("自动瞄准-鼠标模式") then
    settingsTab:Dropdown({
        Title = "自动瞄准-鼠标模式",
        Flag = "THub_Set_AimMouseBtn",
        Values = {"MouseButton2", "MouseButton1"},
        Value = "MouseButton2",
        Callback = function(selected) AimBotModule.SetMouseBind(selected) end
    })
end
settingsTab:Toggle({
    Title = "自动瞄准-粘性瞄准",
    Flag = "THub_Set_AimSticky",
    Value = false,
    Callback = function(v) AimBotModule.SetStickyAim(v) end
})
settingsTab:Slider({
    Title = "自动瞄准-平滑度",
    Flag = "THub_Set_AimSmooth",
    Step = 1,
    Value = { Min = 3, Max = 50, Default = 30 },
    Callback = function(v) AimBotModule.SetSmoothing(v) end
})
settingsTab:Toggle({
    Title = "自动瞄准-移动预测",
    Flag = "THub_Set_AimPredict",
    Value = false,
    Callback = function(v) AimBotModule.SetPrediction(v) end
})
settingsTab:Slider({
    Title = "自动瞄准-预测值",
    Flag = "THub_Set_AimPredictAmt",
    Step = 1,
    Value = { Min = 0, Max = 1000, Default = 100 },
    Callback = function(v) AimBotModule.SetPredictionAmount(v) end
})
settingsTab:Divider()

-- ===== WindUI 配置持久化（接管旧 ConfigModule 的 UI 设置部分） =====
settingsTab:Section({ Title = "界面配置存档", Opened = true })
THubConfig = mainWindow.ConfigManager:CreateConfig("THubConfig")
settingsTab:Button({
    Title = "💾 保存当前界面配置",
    Callback = function()
        if THubConfig:Save() then
            WindUI:Notify({ Title = "配置已保存", Content = "界面配置 'THubConfig' 已保存", Icon = "check", Duration = 3 })
        end
    end
})
settingsTab:Button({
    Title = "📂 读取界面配置",
    Callback = function()
        if THubConfig:Load() then
            WindUI:Notify({ Title = "配置已读取", Content = "界面配置 'THubConfig' 已读取", Icon = "check", Duration = 3 })
        end
    end
})
-- 启动时自动恢复上次保存的开关状态
pcall(function() THubConfig:Load() end)

-- 关闭 / 销毁窗口时卸载 THub（替代原 ChronixUI CloseCallback）
mainWindow:OnDestroy(function()
    unloadTHub()
end)

