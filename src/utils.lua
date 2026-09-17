--!native
--!optimize 2
local cloneref = cloneref or clonereference or function(obj) return obj end

--=============================================================================================

function enableDeathAnnounce()
    if data["basicdata"]["releasetools"]["deathAnnounceConnections"] then
        disableDeathAnnounce()
    end

    local connections = {}
    local function onPlayerDied(player)
        ChronixUI:Notify({
            Title = "死亡播报",
            Content = string.format("%s (%s) 死亡", player.DisplayName, player.Name),
            Type = "info",
            Duration = 3
        })
    end

    local function bindCurrentDied(player)
        local oldDied = data["basicdata"]["releasetools"]["deathAnnounceDied_" .. player.UserId]
        if oldDied then
            pcall(function() oldDied:Disconnect() end)
        end
        local char = player.Character
        if char then
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            if hum then
                local conn = hum.Died:Connect(function()
                    onPlayerDied(player)
                end)
                data["basicdata"]["releasetools"]["deathAnnounceDied_" .. player.UserId] = conn
                table.insert(connections, conn)
            end
        end
    end

    local function bindCharacterAdded(player)
        local oldCharAdded = data["basicdata"]["releasetools"]["deathAnnounceCharAdded_" .. player.UserId]
        if oldCharAdded then
            pcall(function() oldCharAdded:Disconnect() end)
        end
        local conn = player.CharacterAdded:Connect(function(char)
            local hum = char:WaitForChild("Humanoid")
            local diedConn = hum.Died:Connect(function()
                onPlayerDied(player)
            end)
            local oldDied = data["basicdata"]["releasetools"]["deathAnnounceDied_" .. player.UserId]
            if oldDied then
                pcall(function() oldDied:Disconnect() end)
            end
            data["basicdata"]["releasetools"]["deathAnnounceDied_" .. player.UserId] = diedConn
            table.insert(connections, diedConn)
        end)
        data["basicdata"]["releasetools"]["deathAnnounceCharAdded_" .. player.UserId] = conn
        table.insert(connections, conn)
    end

    for _, player in ipairs(Players:GetPlayers()) do
        bindCharacterAdded(player)
        bindCurrentDied(player)
    end

    local playerAddedConn = Players.PlayerAdded:Connect(function(player)
        bindCharacterAdded(player)
        bindCurrentDied(player)
    end)
    table.insert(connections, playerAddedConn)

    local playerRemovingConn = Players.PlayerRemoving:Connect(function(player)
        local diedKey = "deathAnnounceDied_" .. player.UserId
        local charKey = "deathAnnounceCharAdded_" .. player.UserId
        local diedConn = data["basicdata"]["releasetools"][diedKey]
        if diedConn then pcall(function() diedConn:Disconnect() end); data["basicdata"]["releasetools"][diedKey] = nil end
        local charConn = data["basicdata"]["releasetools"][charKey]
        if charConn then pcall(function() charConn:Disconnect() end); data["basicdata"]["releasetools"][charKey] = nil end
    end)
    table.insert(connections, playerRemovingConn)

    data["basicdata"]["releasetools"]["deathAnnounceConnections"] = connections
end

function disableDeathAnnounce()
    local connections = data["basicdata"]["releasetools"]["deathAnnounceConnections"]
    if connections then
        for _, conn in ipairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
        data["basicdata"]["releasetools"]["deathAnnounceConnections"] = nil
    end
    for key, value in pairs(data["basicdata"]["releasetools"]) do
        if type(key) == "string" and (key:find("deathAnnounceDied_") or key:find("deathAnnounceCharAdded_")) then
            pcall(function() value:Disconnect() end)
            data["basicdata"]["releasetools"][key] = nil
        end
    end
end

disabledTypes = {}
local disabledTouchInfo = {}
function applySetting(obj, componentType, disable)
    if componentType == "ClickDetector" then
        if disable then
            obj:SetAttribute("OriginalMaxDist", obj.MaxActivationDistance)
            obj.MaxActivationDistance = 0
        else
            local originalDist = obj:GetAttribute("OriginalMaxDist")
            obj.MaxActivationDistance = originalDist or 32
        end
    elseif componentType == "TouchTransmitter" then
        local parent = obj.Parent
        if parent and parent:IsA("BasePart") then
            if disable then
                if disabledTouchInfo[parent] == nil then
                    disabledTouchInfo[parent] = parent.CanTouch
                    parent.CanTouch = false
                end
            else
                if disabledTouchInfo[parent] ~= nil then
                    parent.CanTouch = disabledTouchInfo[parent]
                    disabledTouchInfo[parent] = nil
                end
            end
        end
    else
        obj.Enabled = not disable
    end
end
function toggleInteraction(componentType, disable)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA(componentType) then
            applySetting(obj, componentType, disable)
        end
    end
    disabledTypes[componentType] = disable
    if onDisabledTypeChanged then onDisabledTypeChanged() end
end

-- 击杀贴身者：带自己瞬移到虚空下25码停1秒（贴身的人掉落摔死），再传回原位
function fakeout()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local oldpos = root.CFrame
    local needRestore = false
    if Workspace.FallenPartsDestroyHeight == Workspace.FallenPartsDestroyHeight then
        Workspace.FallenPartsDestroyHeight = 0 / 0
        needRestore = true
    end
    root.CFrame = CFrame.new(Vector3.new(0, data["basicdata"]["otherdata"]["FallenPartsDestroyHeight"] - 25, 0))
    task.wait(1)
    if root.Parent then
        root.CFrame = oldpos
    end
    if needRestore then
        Workspace.FallenPartsDestroyHeight = data["basicdata"]["otherdata"]["FallenPartsDestroyHeight"]
    end
end

function getjerktool()
    local humanoid = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
	local backpack = LocalPlayer:FindFirstChildWhichIsA("Backpack")
	if not humanoid or not backpack then return end
	local tool = Instance.new("Tool")
	tool.Name = "打... "
	tool.ToolTip = ".?"
	tool.RequiresHandle = false
	tool.Parent = backpack
	local jorkin = false
	local track = nil
	local function stopTomfoolery()
		jorkin = false
		if track then
			track:Stop()
			track = nil
		end
	end
	tool.Equipped:Connect(function() jorkin = true end)
	tool.Unequipped:Connect(stopTomfoolery)
	humanoid.Died:Connect(stopTomfoolery)
	while task.wait() do
		if not jorkin then continue end
		local isR15 = LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R15
		if not track then
			local anim = Instance.new("Animation")
			anim.AnimationId = not isR15 and "rbxassetid://72042024" or "rbxassetid://698251653"
			track = humanoid:LoadAnimation(anim)
		end
		track:Play()
		track:AdjustSpeed(isR15 and 0.7 or 0.65)
		track.TimePosition = 0.6
		task.wait(0.1)
		while track and track.TimePosition < (not isR15 and 0.65 or 0.7) do task.wait(0.1) end
		if track then
			track:Stop()
			track = nil
		end
	end
end

function drophandtool()
    local currentTool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
    if currentTool then
        currentTool.Parent = Workspace
    end
end

function droptool()
    for i,v in pairs(LocalPlayer.Backpack:GetChildren()) do
		if v:IsA("Tool") then
			v.Parent = LocalPlayer.Character
		end
	end
	task.wait()
	for i,v in pairs(LocalPlayer.Character:GetChildren()) do
		if v:IsA("Tool") then
			v.Parent = Workspace
		end
	end
end

function removetools()
    for i,v in pairs(LocalPlayer:FindFirstChildOfClass("Backpack"):GetDescendants()) do
		if v:IsA('Tool') or v:IsA('HopperBin') then
			v:Destroy()
		end
	end
	for i,v in pairs(LocalPlayer.Character:GetDescendants()) do
		if v:IsA('Tool') or v:IsA('HopperBin') then
			v:Destroy()
		end
	end
end

function gettools()
    local function copy(instance)
		for i,c in pairs(instance:GetChildren())do
			if c:IsA('Tool') or c:IsA('HopperBin') then
				c:Clone().Parent = LocalPlayer:FindFirstChildOfClass("Backpack")
			end
			copy(c)
		end
	end
	copy(Lighting)
    copy(ReplicatedStorage)
end

gameInfoCache = nil
function getGameName(universeId)
    if gameInfoCache then return gameInfoCache end
    local url = "https://games.roblox.com/v1/games?universeIds=" .. universeId
    local success, response = pcall(function()
        return cloneref(game):HttpGet(url)
    end)
    if success then
        local dataResp = HttpService:JSONDecode(response)
        if dataResp.data and #dataResp.data > 0 then
            gameInfoCache = dataResp.data[1]
            return gameInfoCache
        end
    end
    return nil
end

function toChineseDate(dateStr, toBeijingTime)
    if not dateStr or type(dateStr) ~= "string" then return "" end
    local m, d, y, h, min, s, ap = dateStr:match("(%d+)%D+(%d+)%D+(%d+)%D+(%d+)%D+(%d+)%D*(%d*)%D*([AP]M)")
    if not m then return dateStr end
    s = s ~= "" and s or "0"
    local hour = tonumber(h)
    if ap == "PM" and hour ~= 12 then
        hour = hour + 12
    elseif ap == "AM" and hour == 12 then
        hour = 0
    end
    if toBeijingTime then
        hour = hour + 8
        if hour >= 24 then hour = hour - 24 end
    end
    return string.format("%d年%d月%d日 %02d:%02d:%02d",
        tonumber(y), tonumber(m), tonumber(d),
        hour, tonumber(min), tonumber(s))
end

function parseExecutors(jsonString)
    local result = {}
    for _, item in ipairs(jsonString) do
        if type(item) == "table" then
            local flat = {
                title          = item.title,
                version        = item.version,
                platform       = item.platform,
                extType        = item.extype,
                free           = item.free,
                detected       = item.detected,
                uncStatus      = item.uncStatus,
                uncPercent     = item.uncPercentage,
                suncPercent    = item.suncPercentage,
                updatedDate    = toChineseDate(item.updatedDate or "", true),
                rbxversion     = item.rbxversion,
                updateStatus   = item.updateStatus,
                beta           = item.beta,
                hidden         = item.hidden,
                unlinked       = item.unlinked,
                elementCertified= item.elementCertified,
                decompiler     = item.decompiler,
                multiInject    = item.multiInject,
                keysystem      = item.keysystem,
                clientmods     = item.clientmods,
                cost           = item.cost,
                hasIssues      = item.hasIssues,
                detectionReason= item.detectionReason,
                longestRunning = item.longestRunning,
                possibleBanwave= item.possibleBanwave,
                unknown        = item.unknown,
                unknownDetection= item.unknownDetection,
                raknet         = item.raknet,
                private        = item.private,
                index          = item.index,
                trackerId      = item.trackerId,
                website        = item.websitelink,
                discord        = item.discordlink,
                purchase       = item.purchaselink,
                roleId         = item.roleId,
                suncScrap      = item.sunc and item.sunc.suncScrap,
                suncKey        = item.sunc and item.sunc.suncKey,
                slugHidden     = item.slug and item.slug.hidden,
                description    = item.slug and item.slug.fullDescription,
                logo           = item.slug and item.slug.logo,
                owner          = item.slug and item.slug.owner,
                screenshots    = item.slug and item.slug.screenshots or {},
                recommendedFeatures = item.recommendedReason and item.recommendedReason.features or {},
            }
            table.insert(result, flat)
        end
    end
    return result
end

shownParts = {}
function showpartsfunction(enable)
    if enable then
        for i,v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and v.Transparency == 1 then
                shownParts[v] = true
                v.Transparency = 0
            end
        end
    else
        for part in pairs(shownParts) do
            if part and part.Parent then
                part.Transparency = 1
            end
        end
        shownParts = {}
    end
end

function formatUsername(player)
	if player.DisplayName ~= player.Name then
		return string.format("%s (%s)", player.Name, player.DisplayName)
	end
	return player.Name
end



local xrayApplied = {}
local xrayAddedConn = nil
local xrayRemovingConn = nil
local function isXrayTarget(part)
    if not part:IsA("BasePart") then return false end
    local parent = part.Parent
    if not parent then return false end
    if parent:FindFirstChildWhichIsA("Humanoid") then return false end
    local grand = parent.Parent
    if grand and grand:FindFirstChildWhichIsA("Humanoid") then return false end
    return true
end
function xray(enabled)
    if enabled then
        for _, v in pairs(Workspace:GetDescendants()) do
            if isXrayTarget(v) then
                v.LocalTransparencyModifier = 0.5
                xrayApplied[v] = true
            end
        end
        if not xrayAddedConn then
            xrayAddedConn = Workspace.DescendantAdded:Connect(function(d)
                if xrayApplied[d] == nil and isXrayTarget(d) then
                    d.LocalTransparencyModifier = 0.5
                    xrayApplied[d] = true
                end
            end)
        end
        if not xrayRemovingConn then
            xrayRemovingConn = Workspace.DescendantRemoving:Connect(function(d)
                xrayApplied[d] = nil
            end)
        end
    else
        for part in pairs(xrayApplied) do
            if part and part.Parent then
                pcall(function() part.LocalTransparencyModifier = 0 end)
            end
        end
        xrayApplied = {}
        if xrayAddedConn then xrayAddedConn:Disconnect(); xrayAddedConn = nil end
        if xrayRemovingConn then xrayRemovingConn:Disconnect(); xrayRemovingConn = nil end
    end
end

function maskStringMiddle(str)
    if not str or type(str) ~= "string" then
        return ""
    end
    local strLength = string.len(str)
    if strLength <= 10 then
        return str
    else
        local firstFive = string.sub(str, 1, 5)
        local lastFive = string.sub(str, -5)
        local middleCount = strLength - 10
        local hashString = string.rep("#", middleCount)
        return firstFive .. hashString .. lastFive
    end
end

function respawn()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if hum then
        hum:ChangeState(Enum.HumanoidStateType.Dead)
        hum.Health = 0
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        task.wait(0.01)
        hum:Destroy()
    end
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("BasePart") or v:IsA("Humanoid") then
            v:Destroy()
        end
    end
    task.wait(0.05)
    char:BreakJoints()
    char:Destroy()
end

-- 强制自杀2（秒重生）：相机切脚本模式防黑屏，传到虚空摔死后恢复
function respawn2()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if not hum or not hum.RootPart then return end
    local camType = Workspace.CurrentCamera.CameraType
    Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
    local needRestore = false
    if Workspace.FallenPartsDestroyHeight == Workspace.FallenPartsDestroyHeight then
        Workspace.FallenPartsDestroyHeight = 0 / 0
        needRestore = true
    end
    hum.RootPart.Position = Vector3.yAxis * data["basicdata"]["otherdata"]["FallenPartsDestroyHeight"]
    task.wait(LocalPlayer:GetNetworkPing())
    if needRestore then
        Workspace.FallenPartsDestroyHeight = data["basicdata"]["otherdata"]["FallenPartsDestroyHeight"]
    end
    repeat task.wait() until not char.Parent or not hum.Parent or hum.Health <= 0
    if hum.Parent then
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
    end
end

function refresh()
    local char = LocalPlayer.Character
    if not char then
        char = LocalPlayer.CharacterAdded:Wait()
    end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local root = humanoid and humanoid.RootPart
    if not root then
        repeat
            task.wait()
            humanoid = char:FindFirstChildOfClass("Humanoid")
            root = humanoid and humanoid.RootPart
        until root
    end
    local pos = root.CFrame
    local pos1 = Workspace.CurrentCamera.CFrame
    respawn()
    task.spawn(function()
        local newChar = LocalPlayer.CharacterAdded:Wait()
        local newHumanoid
        local newRoot
        repeat
            task.wait()
            newHumanoid = newChar:FindFirstChildOfClass("Humanoid")
            newRoot = newHumanoid and newHumanoid.RootPart
        until newRoot
        newRoot.CFrame = pos
        Workspace.CurrentCamera.CFrame = pos1
    end)
end

staffRoles = {"mod", "admin", "staff", "dev", "founder", "owner", "supervis", "manager", "management", "executive", "president", "chairman", "chairwoman", "chairperson", "director"}
function getStaffRole(player)
	local playerRole = player:GetRoleInGroup(game.CreatorId)
	local result = {Role = playerRole, Staff = false}
	if player:IsInGroup(1200769) then
		result.Role = "Roblox Employee"
		result.Staff = true
	end
	for _, role in pairs(staffRoles) do
		if string.find(string.lower(playerRole), role) then
			result.Staff = true
		end
	end
	return result
end

function randomString()
	local length = math.random(10,20)
	local array = {}
	for i = 1, length do
		array[i] = string.char(math.random(32, 126))
	end
	return table.concat(array)
end

function promptNewRig(rig)
	local humanoid = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		AvatarEditorService:PromptSaveAvatar(humanoid.HumanoidDescription, Enum.HumanoidRigType[rig])
		local result = AvatarEditorService.PromptSaveAvatarCompleted:Wait()
		if result == Enum.AvatarPromptResult.Success then
			if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Dead)
            else
                LocalPlayer.Character:BreakJoints()
            end
		end
	end
end

local fogBackup = {
    FogEnd = nil,
    AtmosphereData = {}
}
local isFogRemoved = false

local function RemoveFog(remove)
    if remove then
        if not isFogRemoved then
            fogBackup.FogEnd = Lighting.FogEnd or 100000
            fogBackup.AtmosphereData = {}
            for _, atm in ipairs(Lighting:GetDescendants()) do
                if atm:IsA("Atmosphere") then
                    table.insert(fogBackup.AtmosphereData, {
                        instance = atm,
                        parent = atm.Parent
                    })
                    atm.Parent = nil
                end
            end
            Lighting.FogEnd = 100000
            isFogRemoved = true
        end
    else
        if isFogRemoved then
            Lighting.FogEnd = fogBackup.FogEnd
            for _, data in ipairs(fogBackup.AtmosphereData) do
                local atm = data.instance
                local parent = data.parent
                if atm and atm:IsA("Atmosphere") and parent and parent:IsA("Instance") then
                    atm.Parent = parent
                end
            end
            fogBackup.AtmosphereData = {}
            isFogRemoved = false
        end
    end
end

local noclipConnection = nil
local noclipRespawn = nil

function noclipenable(state)
    if state then
        if noclipConnection then return end
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
        noclipRespawn = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.1)
            scanAndDisable()
        end)
        noclipConnection = game:GetService("RunService").Stepped:Connect(function()
            local parts = data["basicdata"]["releasetools"]["noclipParts"]
            if #parts == 0 then
                scanAndDisable()
            end
            for _, part in ipairs(parts) do
                if part and part.Parent then
                    part.CanCollide = false
                end
            end
        end)
        data["basicdata"]["releasetools"]["noclip"] = true
    else
        if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
        if noclipRespawn then noclipRespawn:Disconnect(); noclipRespawn = nil end
        for _, part in pairs(data["basicdata"]["releasetools"]["noclipParts"]) do
            if part and part.Parent then part.CanCollide = true end
        end
        data["basicdata"]["releasetools"]["noclipParts"] = {}
        data["basicdata"]["releasetools"]["noclip"] = false
    end
end

local JR = nil
local infJumpDebounce = false
function infjumpenable(state)
    if state then
        if JR then return end
        infJumpDebounce = false
        JR = UserInputService.JumpRequest:Connect(function()
            if not data["basicdata"]["releasetools"]["infjump"] or infJumpDebounce then return end
            infJumpDebounce = true
            local c = LocalPlayer.Character
            if c and c.Parent then
                local hum = c:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState("Jumping")
                end
            end
            task.wait(0.25)
            infJumpDebounce = false
        end)
        data["basicdata"]["releasetools"]["infjump"] = true
    else
        if JR then JR:Disconnect(); JR = nil end
        data["basicdata"]["releasetools"]["infjump"] = false
    end
end

-- 边缘跳跃：离开平台边缘进入 Freefall 时拉回上一帧位置并给向上速度，实现 coyote-time 式补跳
local edgeJumpConn = nil
local edgejump_state = nil
local edgejump_laststate = nil
local edgejump_lastcf = nil
local function edgejumpStep()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (char and hum) then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    edgejump_laststate = edgejump_state
    edgejump_state = hum:GetState()
    if edgejump_laststate ~= edgejump_state and edgejump_state == Enum.HumanoidStateType.Freefall and edgejump_laststate ~= Enum.HumanoidStateType.Jumping then
        if edgejump_lastcf then
            root.CFrame = edgejump_lastcf
            local vel = root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity = Vector3.new(vel.X, hum.JumpPower or hum.JumpHeight or 50, vel.Z)
        end
    end
    edgejump_lastcf = root.CFrame
end

function edgeJumpEnable(state)
    if state then
        if edgeJumpConn then return end
        edgejump_state = nil
        edgejump_laststate = nil
        edgejump_lastcf = nil
        edgeJumpConn = game:GetService("RunService").Heartbeat:Connect(edgejumpStep)
        data["basicdata"]["releasetools"]["edgejump"] = true
    else
        if edgeJumpConn then edgeJumpConn:Disconnect(); edgeJumpConn = nil end
        data["basicdata"]["releasetools"]["edgejump"] = false
    end
end

-- 角色密度：质量/体积
function getLocalPlayerDensity()
    local character = LocalPlayer.Character
    if not character then return 0.7 end
    local totalMass = 0
    local totalVolume = 0
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            totalMass = totalMass + part:GetMass()
            totalVolume = totalVolume + (part.Size.X * part.Size.Y * part.Size.Z)
        end
    end
    if totalVolume > 0 then return totalMass / totalVolume end
    return 0.7
end

local Densitysaved = {}
function setDensity(density)
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and not Densitysaved[part] then
            Densitysaved[part] = part.CustomPhysicalProperties
        end
    end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            local old = part.CustomPhysicalProperties or PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)
            part.CustomPhysicalProperties = PhysicalProperties.new(density, old.Friction, old.Elasticity, old.FrictionWeight, old.ElasticityWeight)
        end
    end
end

function restoreDensity()
    for part, props in pairs(Densitysaved) do
        if part and part.Parent then
            part.CustomPhysicalProperties = props
        end
    end
    table.clear(Densitysaved)
end

function setCharacterTypeStatus(character, propName, value)
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        pcall(function() humanoid[propName] = value end)
    end
end

function pdhdset()
    local modify = data["basicdata"]["modify"]
    if modify["PlayerDisplayNameDistance"] then
        for _, conn in ipairs(modify["PDND_Connect"]) do conn:Disconnect() end
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                setCharacterTypeStatus(player.Character, "NameDisplayDistance", modify["AllPlayerDisplayNameDistance"])
            end
            modify["PDND_Connect"][player.UserId .. "_Conn"] = player.CharacterAdded:Connect(function(character)
                if modify["PlayerDisplayNameDistance"] then
                    setCharacterTypeStatus(character, "NameDisplayDistance", modify["AllPlayerDisplayNameDistance"])
                end
            end)
        end
    else
        for _, conn in ipairs(modify["PDND_Connect"]) do conn:Disconnect() end
    end
end

function phdset()
    local modify = data["basicdata"]["modify"]
    if modify["PlayerHealthDistance"] then
        for _, conn in ipairs(modify["PHD_Connect"]) do conn:Disconnect() end
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                setCharacterTypeStatus(player.Character, "HealthDisplayDistance", modify["AllPlayerHealthDistance"])
            end
            modify["PHD_Connect"][player.UserId .. "_Conn"] = player.CharacterAdded:Connect(function(character)
                if modify["PlayerHealthDistance"] then
                    setCharacterTypeStatus(character, "HealthDisplayDistance", modify["AllPlayerHealthDistance"])
                end
            end)
        end
    else
        for _, conn in ipairs(modify["PHD_Connect"]) do conn:Disconnect() end
    end
end

function asphset()
    local modify = data["basicdata"]["modify"]
    if modify["AlwayShowPlayerHealth"] then
        for _, conn in ipairs(modify["ASPH_Connect"]) do conn:Disconnect() end
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                setCharacterTypeStatus(player.Character, "HealthDisplayType", Enum.HumanoidHealthDisplayType.AlwaysOn)
            end
            modify["ASPH_Connect"][player.UserId .. "_Conn"] = player.CharacterAdded:Connect(function(character)
                if modify["AlwayShowPlayerHealth"] then
                    setCharacterTypeStatus(character, "HealthDisplayType", Enum.HumanoidHealthDisplayType.AlwaysOn)
                end
            end)
        end
    else
        for _, conn in ipairs(modify["ASPH_Connect"]) do conn:Disconnect() end
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                setCharacterTypeStatus(player.Character, "HealthDisplayType", Enum.HumanoidHealthDisplayType.DisplayWhenDamaged)
            end
        end
    end
end

-- 深渊：无限二段跳能量（每帧补能量事件）
local abyssDoubleJumpConn = nil
function abyssDoubleJumpEnable(state)
    if state then
        if abyssDoubleJumpConn then return end
        abyssDoubleJumpConn = game:GetService("RunService").Heartbeat:Connect(function()
            local evt = ReplicatedStorage:FindFirstChild("JumpSuperHighwayEvent")
            if evt then
                pcall(firesignal, evt.OnClientEvent)
            end
        end)
        data["othergamedata"]["abyss"]["enableinfdoublejump"] = true
    else
        if abyssDoubleJumpConn then abyssDoubleJumpConn:Disconnect(); abyssDoubleJumpConn = nil end
        data["othergamedata"]["abyss"]["enableinfdoublejump"] = false
    end
end



local SMALL_CAPS_MAP = {
    a='ᴀ', b='ʙ', c='ᴄ', d='ᴅ', e='ᴇ', f='ғ', g='ɢ', h='ʜ', i='ɪ', j='ᴊ',
    k='ᴋ', l='ʟ', m='ᴍ', n='ɴ', o='ᴏ', p='ᴘ', q='ǫ', r='ʀ', s='s', t='ᴛ',
    u='ᴜ', v='ᴠ', w='ᴡ', x='x', y='ʏ', z='ᴢ',
    A='ᴀ', B='ʙ', C='ᴄ', D='ᴅ', E='ᴇ', F='ғ', G='ɢ', H='ʜ', I='ɪ', J='ᴊ',
    K='ᴋ', L='ʟ', M='ᴍ', N='ɴ', O='ᴏ', P='ᴘ', Q='ǫ', R='ʀ', S='s', T='ᴛ',
    U='ᴜ', V='ᴠ', W='ᴡ', X='x', Y='ʏ', Z='ᴢ'
}
function convertToSmallCaps(text)
    return (text:gsub('[a-zA-Z]', SMALL_CAPS_MAP))
end

function hasNoSmallCapsAndHasLetters(text)
    local smallCapsChars = "ᴀʙᴄᴅᴇғɢʜɪᴊᴋʟᴍɴᴏᴘǫʀsᴛᴜᴠᴡxʏᴢ"
    for i = 1, #smallCapsChars do
        local char = smallCapsChars:sub(i, i)
        if text:find(char, 1, true) then
            return false
        end
    end
    if not text:find("[a-zA-Z]") then
        return false
    end
    return true
end

function rejoinCurrentGame()
    local placeId1 = game.PlaceId
    local jobId1 = game.JobId
    if jobId1 and jobId1 ~= "" then
        TeleportService:TeleportToPlaceInstance(placeId1, jobId1, LocalPlayer)
    else
        warn("[THub] 无法获取 JobId，将使用普通传送，可能不会回到同一个房间。")
        TeleportService:Teleport(placeId1, LocalPlayer)
    end
end

function setDay()
    for property, value in pairs(data["basicdata"]["otherdata"]["daySettings"]) do
        local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(Lighting, tweenInfo, { [property] = value })
        tween:Play()
    end
end

function setNight()
    for property, value in pairs(data["basicdata"]["otherdata"]["nightSettings"]) do
        local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(Lighting, tweenInfo, { [property] = value })
        tween:Play()
    end
end

function TeleportTo(x, y, z)
	if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
		warn("[THub] 请传入三个数字：TeleportTo(x, y, z)")
		return false
	end
	local character = LocalPlayer.Character
 	if not character then
 		character = LocalPlayer.CharacterAdded:Wait()
 	end
 	local rootPart = character:FindFirstChild("HumanoidRootPart")
 	if not rootPart then
 		warn("[Teleport] 未找到 HumanoidRootPart")
 		return false
 	end
 	rootPart.CFrame = CFrame.new(Vector3.new(x, y, z))
    ChronixUI:Notify({ Title = "提示", Content = string.format("✅ 已传送到 (%.1f, %.1f, %.1f)", x, y, z), Type = "success", Duration = 5 })
	return true
end

function TeleportToPresent(presentNumber)
	if type(presentNumber) ~= "number" then
		return false
	end
	local mainModel = Workspace:FindFirstChild("XMas_PresentHunt%")
		or Workspace:FindFirstChild("XMas_PresentHunt")
	if not mainModel then
		return false
	end
	local presents = mainModel:FindFirstChild("Presents")
	if not presents then
		return false
	end
	local gift = presents:FindFirstChild(tostring(presentNumber))
	if not gift or not gift:IsA("Model") then
		return false
	end
	local giftCFrame = gift:GetPivot()
	local character = LocalPlayer.Character
 	if not character then
 		return false
 	end
 	local rootPart = character:FindFirstChild("HumanoidRootPart")
 	if not rootPart then
 		return false
 	end
	local targetCFrame = CFrame.new(giftCFrame.Position + Vector3.new(0, 3, 0))
	rootPart.CFrame = targetCFrame
    ChronixUI:Notify({ Title = "提示", Content = string.format("✅ 已传送到礼物 #%d！", presentNumber), Type = "success", Duration = 5 })
	return true
end

local function pressKey(letter)
    if not keytap then return end
    local keyChar = string.sub(letter, 1, 1)
    local keyCode = string.byte(string.upper(keyChar))
    if keyCode then keytap(keyCode)
    else warn("[ChronixHub] 无效的按键字符: " .. letter) end
end

function detectEntity(instance)
    if instance:IsA("BasePart") then
        for entityName, entityInfo in pairs(data["othergamedata"]["delesions_office"]["entitys"]) do
            if instance.Name == entityName then
                if data["othergamedata"]["delesions_office"]["entitywarning"] then
                    ChronixUI:Notify({ Title = "！警告！", Content = "实体" .. entityInfo.name .. "已生成！\n" .. entityInfo.tip, Type = "warning", Duration = 5 })
                    if data["othergamedata"]["delesions_office"]["tipotherplayer"] then ChatControl:chat("警告！实体" .. entityInfo.name .. "已生成！" .. entityInfo.tip) end
                end
                if data["othergamedata"]["delesions_office"]["auto013"] then
                    if instance.Name == "UnknownEntity" then
                        ChronixUI:Notify({ Title = "自动EN-013", Content = "正在自动键入'staycalmstayfocused'...", Type = "warning", Duration = 5 })
                        task.wait(2)
                        local str = "staycalmstayfocused"
                        for i = 1, #str do
                            local char = string.sub(str, i, i)
                            pressKey(char)
                            task.wait(0.2)
                        end
                    end
                end
                break
            end
        end
    end
end

function getAllPostEffects()
    local effects = {}
    for _, obj in ipairs(Lighting:GetDescendants()) do
        if obj:IsA("PostEffect") then
            table.insert(effects, obj)
        end
    end
    local camera = Workspace.CurrentCamera
    if camera then
        for _, obj in ipairs(camera:GetDescendants()) do
            if obj:IsA("PostEffect") then
                table.insert(effects, obj)
            end
        end
    end
    return effects
end

function getColorCorrectionEffect()
    for _, effect in ipairs(getAllPostEffects()) do
        if effect:IsA("ColorCorrectionEffect") then
            return effect
        end
    end
    return nil
end

function getMemoryUsage(unit)
    unit = unit or "MB"
    local success, result = pcall(function()
        return collectgarbage("count")
    end)
    local memoryKB
    if success then
        memoryKB = result
    else
        local current, total = gcinfo()
        memoryKB = current
    end
    if unit == "KB" then
        return memoryKB
    elseif unit == "MB" then
        return memoryKB / 1024
    elseif unit == "GB" then
        return memoryKB / (1024 * 1024)
    else
        return memoryKB / 1024
    end
end

function color3ToHex(color)
	local r = math.floor(color.R * 255 + 0.5)
	local g = math.floor(color.G * 255 + 0.5)
	local b = math.floor(color.B * 255 + 0.5)
	return string.format("#%02X%02X%02X", r, g, b)
end

function hexToColor3(hex)
	hex = hex:gsub("#", "")
	local r = tonumber(hex:sub(1, 2), 16) / 255
	local g = tonumber(hex:sub(3, 4), 16) / 255
	local b = tonumber(hex:sub(5, 6), 16) / 255
	return Color3.new(r, g, b)
end
