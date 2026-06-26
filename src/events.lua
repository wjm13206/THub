--!native
--!optimize 2

--======================================================================================

staffwatchjoin = nil
if game.CreatorType == Enum.CreatorType.Group then
    staffwatchjoin = Players.PlayerAdded:Connect(function(player)
        if data["basicdata"]["releasetools"]["staffcheck"] then
            local result = getStaffRole(player)
            if result.Staff then
                ChronixUI:Notify({ Title = "警告", Content = formatUsername(player) .. " 是 " .. result.Role, Type = "warning", Duration = 10 })
            end
        end
    end)
end

networkPaused = CoreGui.RobloxGui.ChildAdded:Connect(function(obj)
    if obj.Name == "CoreScripts/NetworkPause" and data["basicdata"]["releasetools"]["networkpausedisable"] then
        obj:Destroy()
    end
end)

TeleportCheck = false
keepthubconnect = LocalPlayer.OnTeleport:Connect(function(State)
	if data["basicdata"]["releasetools"]["keepthub"] and (not TeleportCheck) then
		TeleportCheck = true
        local teleportCode = [[
            if not game:IsLoaded() then game.Loaded:Wait() end
            local cloneref = cloneref or clonereference or function(obj) return obj end
            cloneref(game:GetService("StarterGui")):SetCore("SendNotification", {Title = "THub", Text = "检测到游戏被跳转\n正在重新载入中...", Duration = 10})
            loadstring(game:HttpGet("https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main/mainv3.lua"))()
        ]]
        if queueteleport then
            queueteleport(teleportCode)
        elseif queueonteleport then
            queueonteleport(teleportCode)
        elseif queue_on_teleport then
            queue_on_teleport(teleportCode)
        end
	end
end)

AntiAFK = LocalPlayer.Idled:connect(function()
    if data["basicdata"]["releasetools"]["antiafk"] then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

connections = {}
humanoidConnections = {}
function disconnectHumanoidConnections()
    for _, connection in pairs(humanoidConnections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    humanoidConnections = {}
end
function setupHumanoidListeners(humanoid)
    disconnectHumanoidConnections()
    humanoidConnections.OnDies = humanoid.Died:Connect(function()
        if LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RootPart then
            data["basicdata"]["releasetools"]["lastDeath"] = LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RootPart.CFrame
        end
    end)
    humanoidConnections.walkSpeed = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if data["basicdata"]["player"]["islockspeed"] then
            humanoid.WalkSpeed = data["basicdata"]["player"]["speed"]
        end
    end)
    humanoidConnections.jumpPower = humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if data["basicdata"]["player"]["islockjump"] then
            humanoid.JumpPower = data["basicdata"]["player"]["jump"]
        end
    end)
    humanoidConnections.health = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if data["basicdata"]["player"]["islockhealth"] then
            humanoid.Health = data["basicdata"]["player"]["health"]
        end
    end)
    humanoidConnections.maxHealth = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
        if data["basicdata"]["player"]["islockmaxhealth"] then
            humanoid.MaxHealth = data["basicdata"]["player"]["maxhealth"]
        end
    end)
    humanoidConnections.forceUpdates = RunService.Heartbeat:Connect(function()
        if data["basicdata"]["player"]["islockspeed"] then
            if humanoid.WalkSpeed ~= data["basicdata"]["player"]["speed"] then
                humanoid.WalkSpeed = data["basicdata"]["player"]["speed"]
            end
        end
        if data["basicdata"]["player"]["islockjump"] then
            if humanoid.JumpPower ~= data["basicdata"]["player"]["jump"] then
                humanoid.JumpPower = data["basicdata"]["player"]["jump"]
            end
        end
        if data["basicdata"]["player"]["islockhealth"] then
            if humanoid.Health ~= data["basicdata"]["player"]["health"] then
                humanoid.Health = data["basicdata"]["player"]["health"]
            end
        end
        if data["basicdata"]["player"]["islockmaxhealth"] then
            if humanoid.MaxHealth ~= data["basicdata"]["player"]["maxhealth"] then
                humanoid.MaxHealth = data["basicdata"]["player"]["maxhealth"]
            end
        end
    end)
    humanoidConnections.hscc = humanoid.StateChanged:Connect(function(oldState, newState)
        if data["basicdata"]["releasetools"]["antifall"] then
            if newState == Enum.HumanoidStateType.FallingDown or newState == Enum.HumanoidStateType.Ragdoll or newState == Enum.HumanoidStateType.Freefall then
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                ChronixUI:Notify({ Title = "提示", Content = "检测到被击倒，已恢复站立状态", Type = "info", Duration = 5 })
            end
        end
    end)
end
function checkAndSetupHumanoid(character)
    if not character then
        return
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        setupHumanoidListeners(humanoid)
    else
        local childAddedConnection
        childAddedConnection = character.ChildAdded:Connect(function(child)
            if child:IsA("Humanoid") then
                task.wait(0.1)
                setupHumanoidListeners(child)
                if childAddedConnection then
                    childAddedConnection:Disconnect()
                end
            end
        end)
        for _, child in pairs(character:GetChildren()) do
            if child:IsA("Humanoid") then
                setupHumanoidListeners(child)
                if childAddedConnection then
                    childAddedConnection:Disconnect()
                end
                break
            end
        end
    end
end
connections.characterChildRemoved = LocalPlayer.CharacterRemoving:Connect(function(oldCharacter) disconnectHumanoidConnections() end)
connections.characterAdded = LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    newCharacter:WaitForChild("HumanoidRootPart")
    checkAndSetupHumanoid(newCharacter)
    pcall(function() if data["basicdata"]["releasetools"]["spawnpos"] ~= nil then task.wait(0.1); LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RootPart.CFrame = data["basicdata"]["releasetools"]["spawnpos"] end end)
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
end

pac = Players.PlayerAdded:Connect(updatePlayerList)
prc = Players.PlayerRemoving:Connect(updatePlayerList)

ChatControl:MessageReceiver(function(msgData)
    addChatMessage(msgData.sender, msgData.text)
    if data["basicdata"]["releasetools"]["chatresend"] and msgData.sender == data["basicdata"]["player"]["name"] and hasNoSmallCapsAndHasLetters(msgData.text) then ChatControl:chat(convertToSmallCaps(msgData.text)) end
end)

GGcount = 0
local relevantTypes = {["BasePart"] = true, ["ClickDetector"] = true, ["TouchTransmitter"] = true, ["ProximityPrompt"] = true}
WorkspaceDescendantAdded = Workspace.DescendantAdded:Connect(function(descendant)
    if not relevantTypes[descendant.ClassName] then return end
    if disabledTypes[descendant.ClassName] then
        applySetting(descendant, descendant.ClassName, disabledTypes[descendant.ClassName])
    end
    detectEntity(descendant)
    if descendant.Name == "base" and descendant:IsA("BasePart") and data["othergamedata"]["grace"]["autolever"] then
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
    if data["othergamedata"]["grace"]["deleteentity"] then
        if descendant.Name == "eye" or descendant.Name == "elkman" or descendant.Name == "Rush" or descendant.Name == "Worm" or descendant.Name == "eyePrime" then
            descendant:Destroy()
        end
    end
end)

lastTime = 0
RunStepped = RunService.Stepped:Connect(function()
    if data["basicdata"]["releasetools"]["nightvision"] then game.Lighting.Ambient = Color3.new(1, 1, 1) end
    if data["basicdata"]["releasetools"]["supernightvision"] then Lighting.Brightness = 2; Lighting.ExposureCompensation = 2.5 end
    if data["basicdata"]["player"]["islockgravity"] then Workspace.Gravity = data["basicdata"]["player"]["gravity"] end
    if data["basicdata"]["releasetools"]["antidead"] then LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end
    local now = tick()
    if now - lastTime >= 1 then
        lastTime = now
        if memLabel then memLabel.Text = string.format("客户端脚本占用内存: %.2f MB", getMemoryUsage("MB")) end
        local ping = LocalPlayer:GetNetworkPing()
        if pingLabel then pingLabel.Text = string.format("网络延迟: %s", math.floor(ping * 1000 + 0.5) .. "ms") end
        if isrbxactive and rbxactivelabel then rbxactivelabel.Text = string.format("焦点检测: %s", (isrbxactive() and "True" or "False")) end
    end
    if data["othergamedata"]["grace"]["deleteentity"] then
        ReplicatedStorage.eyegui:Destroy()
        ReplicatedStorage.smilegui:Destroy()
        ReplicatedStorage.SendRush:Destroy()
        ReplicatedStorage.SendWorm:Destroy()
        ReplicatedStorage.SendSorrow:Destroy()
        task.wait(0.1)
        ReplicatedStorage.Worm:Destroy()
        ReplicatedStorage.elkman:Destroy()
        task.wait(0.1)
        ReplicatedStorage.QuickNotes.Eye:Destroy()
        ReplicatedStorage.QuickNotes.Rush:Destroy()
        ReplicatedStorage.QuickNotes.Sorrow:Destroy()
        ReplicatedStorage.QuickNotes.elkman:Destroy()
        ReplicatedStorage.QuickNotes.EyePrime:Destroy()
        ReplicatedStorage.QuickNotes.SlugFish:Destroy()
        ReplicatedStorage.QuickNotes.FakeDoor:Destroy()
        ReplicatedStorage.QuickNotes.SleepyHead:Destroy()
        local SmileGui = PlayerGui:FindFirstChild("smilegui")
        if SmileGui then
            SmileGui:Destroy()
        end
    end
end)
