--!native
--!optimize 2

--======================================================================================
-- Spoofing hooks: intercept WalkSpeed/JumpPower reads/writes to hide locked values
-- Installed on-demand (only when user enables lock) with delay to avoid detection
local checkcaller = checkcaller or function() return false end
local newcclosure = newcclosure or function(f) return f end
local getrawmetatable = getrawmetatable or function(t) return getmetatable(t) end

local mt = getrawmetatable(game)
local oldIndex = mt.__index
local oldNewindex = mt.__newindex
local spoofHooksInstalled = false

function installSpoofHooks()
    if spoofHooksInstalled then return end
    if not getrawmetatable then return end

    mt.__index = newcclosure(function(self, key)
        if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
            local char = LocalPlayer.Character
            if char and self:IsDescendantOf(char) then
                if key == "WalkSpeed" and data["basicdata"]["player"]["islockspeed"] then
                    return data["basicdata"]["player"]["speed"]
                end
                if key == "JumpPower" and data["basicdata"]["player"]["islockjump"] then
                    return data["basicdata"]["player"]["jump"]
                end
            end
        end
        return oldIndex(self, key)
    end)

    mt.__newindex = newcclosure(function(self, key, value)
        if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
            local char = LocalPlayer.Character
            if char and self:IsDescendantOf(char) then
                if key == "WalkSpeed" and data["basicdata"]["player"]["islockspeed"] then
                    return
                end
                if key == "JumpPower" and data["basicdata"]["player"]["islockjump"] then
                    return
                end
            end
        end
        return oldNewindex(self, key, value)
    end)

    spoofHooksInstalled = true
end

function uninstallSpoofHooks()
    if not spoofHooksInstalled then return end
    mt.__index = oldIndex
    mt.__newindex = oldNewindex
    spoofHooksInstalled = false
end

function requestSpoofHooks()
    if data["basicdata"]["player"]["islockspeed"] or data["basicdata"]["player"]["islockjump"] then
        installSpoofHooks()
    else
        uninstallSpoofHooks()
    end
end

restoreSpoofHooks = uninstallSpoofHooks

--======================================================================================
-- Per-feature on-demand connections
-- Each feature has enable/disable functions that create/destroy connections only when needed.

-- Track all dynamically created connections for cleanup
local dynamicConnections = {}

local function trackConnection(name, conn)
    if dynamicConnections[name] then
        dynamicConnections[name]:Disconnect()
    end
    dynamicConnections[name] = conn
end

--=== 1. AntiAFK ===
function enableAntiAFK()
    if dynamicConnections.antiafk then return end
    data["basicdata"]["releasetools"]["antiafk"] = true
    trackConnection("antiafk", LocalPlayer.Idled:Connect(function()
        Services.VirtualUser:CaptureController()
        Services.VirtualUser:ClickButton2(Vector2.new())
    end))
end
function disableAntiAFK()
    if dynamicConnections.antiafk then
        dynamicConnections.antiafk:Disconnect()
        dynamicConnections.antiafk = nil
    end
    data["basicdata"]["releasetools"]["antiafk"] = false
end

--=== 2. Staff Check ===
local staffWatchConn = nil
function enableStaffCheck()
    if staffWatchConn then return end
    data["basicdata"]["releasetools"]["staffcheck"] = true
    if game.CreatorType ~= Enum.CreatorType.Group then return end
    for _, player in pairs(Players:GetPlayers()) do
        local result = getStaffRole(player)
        if result.Staff then
            ChronixUI:Notify({ Title = "警告", Content = formatUsername(player) .. " 是 " .. result.Role, Duration = 10 })
        end
    end
    staffWatchConn = Players.PlayerAdded:Connect(function(player)
        local result = getStaffRole(player)
        if result.Staff then
            ChronixUI:Notify({ Title = "警告", Content = formatUsername(player) .. " 是 " .. result.Role, Type = "warning", Duration = 10 })
        end
    end)
end
function disableStaffCheck()
    if staffWatchConn then
        staffWatchConn:Disconnect()
        staffWatchConn = nil
    end
    data["basicdata"]["releasetools"]["staffcheck"] = false
end

--=== 3. Network Pause Disable ===
local networkPauseConn = nil
function enableNetworkPauseDisable()
    if networkPauseConn then return end
    data["basicdata"]["releasetools"]["networkpausedisable"] = true
    pcall(function() CoreGui.RobloxGui["CoreScripts/NetworkPause"]:Destroy() end)
    networkPauseConn = CoreGui.RobloxGui.ChildAdded:Connect(function(obj)
        if obj.Name == "CoreScripts/NetworkPause" then
            obj:Destroy()
        end
    end)
end
function disableNetworkPauseDisable()
    if networkPauseConn then
        networkPauseConn:Disconnect()
        networkPauseConn = nil
    end
    data["basicdata"]["releasetools"]["networkpausedisable"] = false
end

--=== 4. Keep THub on teleport ===
TeleportCheck = false
local keepthubConn = nil
function enableKeepTHub()
    if keepthubConn then return end
    data["basicdata"]["releasetools"]["keepthub"] = true
    TeleportCheck = false
    keepthubConn = LocalPlayer.OnTeleport:Connect(function(State)
        if not data["basicdata"]["releasetools"]["keepthub"] or TeleportCheck then return end
        TeleportCheck = true
        local teleportCode = [[
            if not game:IsLoaded() then game.Loaded:Wait() end
            local cloneref = cloneref or clonereference or function(obj) return obj end
            cloneref(game:GetService("StarterGui")):SetCore("SendNotification", {Title = "THub", Text = "检测到游戏被跳转\n正在重新载入中...", Duration = 10})
            loadstring(cloneref(game):HttpGet("https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/main.lua"))()
        ]]
        if queueteleport then
            queueteleport(teleportCode)
        elseif queueonteleport then
            queueonteleport(teleportCode)
        elseif queue_on_teleport then
            queue_on_teleport(teleportCode)
        end
    end)
end
function disableKeepTHub()
    if keepthubConn then
        keepthubConn:Disconnect()
        keepthubConn = nil
    end
    data["basicdata"]["releasetools"]["keepthub"] = false
end

--=== 5. Night Vision ===
local nvConn = nil
function enableNightVision()
    if nvConn then return end
    data["basicdata"]["releasetools"]["nightvision"] = true
    Lighting.Ambient = Color3.new(1, 1, 1)
    nvConn = RunService.Stepped:Connect(function()
        if not data["basicdata"]["releasetools"]["nightvision"] then
            disableNightVision()
            return
        end
        Lighting.Ambient = Color3.new(1, 1, 1)
    end)
end
function disableNightVision()
    if nvConn then nvConn:Disconnect(); nvConn = nil end
    data["basicdata"]["releasetools"]["nightvision"] = false
    Lighting.Ambient = Color3.new(0, 0, 0)
end

--=== 6. Super Night Vision ===
local snvConn = nil
function enableSuperNightVision()
    if snvConn then return end
    data["basicdata"]["releasetools"]["supernightvision"] = true
    data["basicdata"]["releasetools"]["originalBrightness"] = Lighting.Brightness
    data["basicdata"]["releasetools"]["originalExposureCompensation"] = Lighting.ExposureCompensation
    Lighting.Brightness = 2
    Lighting.ExposureCompensation = 2.5
    snvConn = RunService.Stepped:Connect(function()
        if not data["basicdata"]["releasetools"]["supernightvision"] then
            disableSuperNightVision()
            return
        end
        Lighting.Brightness = 2
        Lighting.ExposureCompensation = 2.5
    end)
end
function disableSuperNightVision()
    if snvConn then snvConn:Disconnect(); snvConn = nil end
    data["basicdata"]["releasetools"]["supernightvision"] = false
    Lighting.Brightness = data["basicdata"]["releasetools"]["originalBrightness"]
    Lighting.ExposureCompensation = data["basicdata"]["releasetools"]["originalExposureCompensation"]
end

--=== 7. Lock Gravity ===
local gravConn = nil
function enableLockGravity()
    if gravConn then return end
    data["basicdata"]["player"]["islockgravity"] = true
    Workspace.Gravity = data["basicdata"]["player"]["gravity"]
    gravConn = RunService.Stepped:Connect(function()
        if not data["basicdata"]["player"]["islockgravity"] then
            disableLockGravity()
            return
        end
        Workspace.Gravity = data["basicdata"]["player"]["gravity"]
    end)
end
function disableLockGravity()
    if gravConn then gravConn:Disconnect(); gravConn = nil end
    data["basicdata"]["player"]["islockgravity"] = false
end

--=== 8. Anti Dead ===
local adConn = nil
function enableAntiDead()
    if adConn then return end
    data["basicdata"]["releasetools"]["antidead"] = true
    adConn = RunService.Stepped:Connect(function()
        if not data["basicdata"]["releasetools"]["antidead"] then
            disableAntiDead()
            return
        end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end
        end
    end)
end
function disableAntiDead()
    if adConn then adConn:Disconnect(); adConn = nil end
    data["basicdata"]["releasetools"]["antidead"] = false
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end
    end
end

--=== 9. Grace: Delete Entity ===
local deleteEntityConn = nil
local lastEntityDeleteTime = 0
function enableDeleteEntity()
    if deleteEntityConn then return end
    data["othergamedata"]["grace"]["deleteentity"] = true
    deleteEntityConn = RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastEntityDeleteTime < 1 then return end
        lastEntityDeleteTime = now
        pcall(function() ReplicatedStorage.eyegui:Destroy() end)
        pcall(function() ReplicatedStorage.smilegui:Destroy() end)
        pcall(function() ReplicatedStorage.SendRush:Destroy() end)
        pcall(function() ReplicatedStorage.SendWorm:Destroy() end)
        pcall(function() ReplicatedStorage.SendSorrow:Destroy() end)
        pcall(function() ReplicatedStorage.Worm:Destroy() end)
        pcall(function() ReplicatedStorage.elkman:Destroy() end)
        pcall(function() ReplicatedStorage.QuickNotes.Eye:Destroy() end)
        pcall(function() ReplicatedStorage.QuickNotes.Rush:Destroy() end)
        pcall(function() ReplicatedStorage.QuickNotes.Sorrow:Destroy() end)
        pcall(function() ReplicatedStorage.QuickNotes.elkman:Destroy() end)
        pcall(function() ReplicatedStorage.QuickNotes.EyePrime:Destroy() end)
        pcall(function() ReplicatedStorage.QuickNotes.SlugFish:Destroy() end)
        pcall(function() ReplicatedStorage.QuickNotes.FakeDoor:Destroy() end)
        pcall(function() ReplicatedStorage.QuickNotes.SleepyHead:Destroy() end)
        local SmileGui = PlayerGui:FindFirstChild("smilegui")
        if SmileGui then SmileGui:Destroy() end
    end)
end
function disableDeleteEntity()
    if deleteEntityConn then deleteEntityConn:Disconnect(); deleteEntityConn = nil end
    data["othergamedata"]["grace"]["deleteentity"] = false
end

--=== 10. Grace: Auto Lever ===
local autoLeverConn = nil
local GGcount = 0
function enableAutoLever()
    if autoLeverConn then return end
    data["othergamedata"]["grace"]["autolever"] = true
    GGcount = 0
    autoLeverConn = Workspace.DescendantAdded:Connect(function(descendant)
        if descendant.Name == "base" and descendant:IsA("BasePart") then
            if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart then
                descendant.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                GGcount = GGcount + 1
                if GGcount >= 3 then
                    ChronixUI:Notify({ Title = "提示", Content = "全部拉杆已被激活\n门已打开", Type = "info", Duration = 5 })
                    GGcount = 0
                end
                task.wait(1)
                descendant.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
            end
        end
    end)
end
function disableAutoLever()
    if autoLeverConn then autoLeverConn:Disconnect(); autoLeverConn = nil end
    data["othergamedata"]["grace"]["autolever"] = false
end

--=== 11. Entity Warning (妄想办公室) ===
local entityWarningConn = nil
local relevantTypes = {["BasePart"] = true, ["ClickDetector"] = true, ["TouchTransmitter"] = true, ["ProximityPrompt"] = true}
function enableEntityWarning()
    if entityWarningConn then return end
    data["othergamedata"]["delesions_office"]["entitywarning"] = true
    entityWarningConn = Workspace.DescendantAdded:Connect(function(descendant)
        detectEntity(descendant)
    end)
end
function disableEntityWarning()
    if entityWarningConn then entityWarningConn:Disconnect(); entityWarningConn = nil end
    data["othergamedata"]["delesions_office"]["entitywarning"] = false
end

--=== 12. Auto 013 (妄想办公室) ===
function enableAuto013()
    data["othergamedata"]["delesions_office"]["auto013"] = true
    if not entityWarningConn then enableEntityWarning() end
end
function disableAuto013()
    data["othergamedata"]["delesions_office"]["auto013"] = false
    if not data["othergamedata"]["delesions_office"]["entitywarning"] then
        disableEntityWarning()
    end
end

--=== 13. Disabled Types listener (new descendants) ===
local disabledTypesRefCount = 0
local disabledTypesConn = nil
local function refreshDisabledTypesConn()
    if disabledTypesRefCount > 0 and not disabledTypesConn then
        disabledTypesConn = Workspace.DescendantAdded:Connect(function(descendant)
            if not relevantTypes[descendant.ClassName] then return end
            if disabledTypes[descendant.ClassName] then
                applySetting(descendant, descendant.ClassName, disabledTypes[descendant.ClassName])
            end
        end)
    elseif disabledTypesRefCount <= 0 and disabledTypesConn then
        disabledTypesConn:Disconnect()
        disabledTypesConn = nil
    end
end
-- Called from utils.lua toggleInteraction
function onDisabledTypeChanged()
    local count = 0
    for _, v in pairs(disabledTypes) do
        if v then count = count + 1 end
    end
    disabledTypesRefCount = count
    refreshDisabledTypesConn()
end

--=== 14. Disable Tip Other Player (妄想办公室) ===
-- (Just a flag, no connection needed)

--=== 15. Chat Resend ===
function enableChatResend()
    data["basicdata"]["releasetools"]["chatresend"] = true
end
function disableChatResend()
    data["basicdata"]["releasetools"]["chatresend"] = false
end

--======================================================================================
-- Character management (always-on lightweight skeleton)
-- CharacterAdded stays connected; individual features attach/detach on respawn.

connections = {}
humanoidConnections = {}
local humanoid = nil

function disconnectHumanoidConnections()
    for _, connection in pairs(humanoidConnections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    humanoidConnections = {}
end

function attachDeathTracker(hum)
    humanoidConnections.OnDies = hum.Died:Connect(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") and LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RootPart then
            data["basicdata"]["releasetools"]["lastDeath"] = LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RootPart.CFrame
        end
    end)
end

local healthLockConn = nil
local healthHeartbeatConn = nil
local maxHealthLockConn = nil
local maxHealthHeartbeatConn = nil
local antiFallConn = nil

function attachHealthLock(hum)
    if healthLockConn then healthLockConn:Disconnect() end
    if healthHeartbeatConn then healthHeartbeatConn:Disconnect() end
    healthLockConn = hum:GetPropertyChangedSignal("Health"):Connect(function()
        if data["basicdata"]["player"]["islockhealth"] then
            hum.Health = data["basicdata"]["player"]["health"]
        end
    end)
    healthHeartbeatConn = RunService.Heartbeat:Connect(function()
        if not data["basicdata"]["player"]["islockhealth"] then
            detachHealthLock()
            return
        end
        if hum and hum.Parent and hum.Health ~= data["basicdata"]["player"]["health"] then
            hum.Health = data["basicdata"]["player"]["health"]
        end
    end)
end
function detachHealthLock()
    if healthLockConn then healthLockConn:Disconnect(); healthLockConn = nil end
    if healthHeartbeatConn then healthHeartbeatConn:Disconnect(); healthHeartbeatConn = nil end
end

function attachMaxHealthLock(hum)
    if maxHealthLockConn then maxHealthLockConn:Disconnect() end
    if maxHealthHeartbeatConn then maxHealthHeartbeatConn:Disconnect() end
    maxHealthLockConn = hum:GetPropertyChangedSignal("MaxHealth"):Connect(function()
        if data["basicdata"]["player"]["islockmaxhealth"] then
            hum.MaxHealth = data["basicdata"]["player"]["maxhealth"]
        end
    end)
    maxHealthHeartbeatConn = RunService.Heartbeat:Connect(function()
        if not data["basicdata"]["player"]["islockmaxhealth"] then
            detachMaxHealthLock()
            return
        end
        if hum and hum.Parent and hum.MaxHealth ~= data["basicdata"]["player"]["maxhealth"] then
            hum.MaxHealth = data["basicdata"]["player"]["maxhealth"]
        end
    end)
end
function detachMaxHealthLock()
    if maxHealthLockConn then maxHealthLockConn:Disconnect(); maxHealthLockConn = nil end
    if maxHealthHeartbeatConn then maxHealthHeartbeatConn:Disconnect(); maxHealthHeartbeatConn = nil end
end

function attachAntiFall(hum)
    if antiFallConn then antiFallConn:Disconnect() end
    antiFallConn = hum.StateChanged:Connect(function(oldState, newState)
        if data["basicdata"]["releasetools"]["antifall"] then
            if newState == Enum.HumanoidStateType.FallingDown or newState == Enum.HumanoidStateType.Ragdoll or newState == Enum.HumanoidStateType.Freefall then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                ChronixUI:Notify({ Title = "提示", Content = "检测到被击倒，已恢复站立状态", Type = "info", Duration = 5 })
            end
        end
    end)
end
function detachAntiFall()
    if antiFallConn then antiFallConn:Disconnect(); antiFallConn = nil end
end

-- Re-apply enabled humanoid features on respawn
local function refreshHumanoidFeatures(hum)
    if not hum then return end
    if data["basicdata"]["player"]["islockhealth"] then
        attachHealthLock(hum)
    else
        detachHealthLock()
    end
    if data["basicdata"]["player"]["islockmaxhealth"] then
        attachMaxHealthLock(hum)
    else
        detachMaxHealthLock()
    end
    if data["basicdata"]["releasetools"]["antifall"] then
        attachAntiFall(hum)
    else
        detachAntiFall()
    end
end

--=== Lock Health on-demand ===
function enableLockHealth()
    data["basicdata"]["player"]["islockhealth"] = true
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then attachHealthLock(hum) end
    end
end
function disableLockHealth()
    data["basicdata"]["player"]["islockhealth"] = false
    detachHealthLock()
end

--=== Lock MaxHealth on-demand ===
function enableLockMaxHealth()
    data["basicdata"]["player"]["islockmaxhealth"] = true
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then attachMaxHealthLock(hum) end
    end
end
function disableLockMaxHealth()
    data["basicdata"]["player"]["islockmaxhealth"] = false
    detachMaxHealthLock()
end

--=== Anti Fall on-demand ===
function enableAntiFall()
    data["basicdata"]["releasetools"]["antifall"] = true
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then attachAntiFall(hum) end
    end
end
function disableAntiFall()
    data["basicdata"]["releasetools"]["antifall"] = false
    detachAntiFall()
end

--=== Character Added (always on - lightweight) ===
function checkAndSetupHumanoid(character)
    if not character then return end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum then
        disconnectHumanoidConnections()
        attachDeathTracker(hum)
        refreshHumanoidFeatures(hum)
    else
        local childAddedConnection
        childAddedConnection = character.ChildAdded:Connect(function(child)
            if child:IsA("Humanoid") then
                task.wait(0.1)
                disconnectHumanoidConnections()
                attachDeathTracker(child)
                refreshHumanoidFeatures(child)
                if childAddedConnection then childAddedConnection:Disconnect() end
            end
        end)
        for _, child in pairs(character:GetChildren()) do
            if child:IsA("Humanoid") then
                disconnectHumanoidConnections()
                attachDeathTracker(child)
                refreshHumanoidFeatures(child)
                if childAddedConnection then childAddedConnection:Disconnect() end
                break
            end
        end
    end
end

connections.characterChildRemoved = LocalPlayer.CharacterRemoving:Connect(function()
    disconnectHumanoidConnections()
    detachHealthLock()
    detachMaxHealthLock()
    detachAntiFall()
end)
connections.characterAdded = LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    newCharacter:WaitForChild("HumanoidRootPart")
    checkAndSetupHumanoid(newCharacter)
    pcall(function()
        if data["basicdata"]["releasetools"]["spawnpos"] ~= nil then
            task.wait(0.1)
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RootPart.CFrame = data["basicdata"]["releasetools"]["spawnpos"]
        end
    end)
end)
if LocalPlayer.Character then
    LocalPlayer.Character:WaitForChild("HumanoidRootPart")
    checkAndSetupHumanoid(LocalPlayer.Character)
end

function clearAllConnections()
    for _, connection in pairs(connections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    connections = {}
    disconnectHumanoidConnections()
    detachHealthLock()
    detachMaxHealthLock()
    detachAntiFall()
    for name, conn in pairs(dynamicConnections) do
        if conn then conn:Disconnect() end
    end
    dynamicConnections = {}
    if staffWatchConn then staffWatchConn:Disconnect(); staffWatchConn = nil end
    if networkPauseConn then networkPauseConn:Disconnect(); networkPauseConn = nil end
    if keepthubConn then keepthubConn:Disconnect(); keepthubConn = nil end
    if nvConn then nvConn:Disconnect(); nvConn = nil end
    if snvConn then snvConn:Disconnect(); snvConn = nil end
    if gravConn then gravConn:Disconnect(); gravConn = nil end
    if adConn then adConn:Disconnect(); adConn = nil end
    if deleteEntityConn then deleteEntityConn:Disconnect(); deleteEntityConn = nil end
    if autoLeverConn then autoLeverConn:Disconnect(); autoLeverConn = nil end
    if entityWarningConn then entityWarningConn:Disconnect(); entityWarningConn = nil end
    if disabledTypesConn then disabledTypesConn:Disconnect(); disabledTypesConn = nil end
    if labelUpdateConn then labelUpdateConn:Disconnect(); labelUpdateConn = nil end
    if pac then pac:Disconnect(); pac = nil end
    if prc then prc:Disconnect(); prc = nil end
end

--======================================================================================
-- Player list update (always on - needed for player teleport tab UI)
pac = Players.PlayerAdded:Connect(function()
    updatePlayerList()
    if updateFlingTeleportPlayerList then updateFlingTeleportPlayerList() end
end)
prc = Players.PlayerRemoving:Connect(function()
    updatePlayerList()
    if updateFlingTeleportPlayerList then updateFlingTeleportPlayerList() end
end)

--======================================================================================
-- Chat receiver (always on - needed for chat receiver tab)
ChatControl:MessageReceiver(function(msgData)
    addChatMessage(msgData.sender, msgData.text)
    if data["basicdata"]["releasetools"]["chatresend"] and msgData.sender == data["basicdata"]["player"]["name"] and hasNoSmallCapsAndHasLetters(msgData.text) then
        ChatControl:chat(convertToSmallCaps(msgData.text))
    end
end)

--======================================================================================
-- Memory/Ping/Rbxactive label updater (always on - lightweight, once per second)
local lastTime = 0
local memFormat = "客户端脚本占用内存: %.2f MB"
local pingFormat = "网络延迟: %s"
local rbxactiveFormat = "焦点检测: %s"
local labelUpdateConn = RunService.Stepped:Connect(function()
    local now = tick()
    if now - lastTime >= 1 then
        lastTime = now
        if memLabel then memLabel.Text = string.format(memFormat, getMemoryUsage("MB")) end
        local ping = LocalPlayer:GetNetworkPing()
        if pingLabel then pingLabel.Text = string.format(pingFormat, math.floor(ping * 1000 + 0.5) .. "ms") end
        if isrbxactive and rbxactivelabel then rbxactivelabel.Text = string.format(rbxactiveFormat, isrbxactive() and "True" or "False") end
    end
end)

-- Initialize default-on features
enableAntiAFK()
