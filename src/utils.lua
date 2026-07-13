--!native
--!optimize 2

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
            parent.CanTouch = not disable
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
        return game:HttpGet(url)
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
                if not table.find(shownParts,v) then
                    table.insert(shownParts,v)
                end
                v.Transparency = 0
            end
        end
    else
        for i,v in pairs(shownParts) do
            v.Transparency = 1
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

function xray(enabled)
	for _, v in pairs(Workspace:GetDescendants()) do
		if v:IsA("BasePart") and not v.Parent:FindFirstChildWhichIsA("Humanoid") and not v.Parent.Parent:FindFirstChildWhichIsA("Humanoid") then
			v.LocalTransparencyModifier = enabled and 0.5 or 0
		end
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

function convertToSmallCaps(text)
    local map = {
        a='ᴀ', b='ʙ', c='ᴄ', d='ᴅ', e='ᴇ', f='ғ', g='ɢ', h='ʜ', i='ɪ', j='ᴊ',
        k='ᴋ', l='ʟ', m='ᴍ', n='ɴ', o='ᴏ', p='ᴘ', q='ǫ', r='ʀ', s='s', t='ᴛ',
        u='ᴜ', v='ᴠ', w='ᴡ', x='x', y='ʏ', z='ᴢ',
        A='ᴀ', B='ʙ', C='ᴄ', D='ᴅ', E='ᴇ', F='ғ', G='ɢ', H='ʜ', I='ɪ', J='ᴊ',
        K='ᴋ', L='ʟ', M='ᴍ', N='ɴ', O='ᴏ', P='ᴘ', Q='ǫ', R='ʀ', S='s', T='ᴛ',
        U='ᴜ', V='ᴠ', W='ᴡ', X='x', Y='ʏ', Z='ᴢ'
    }
    return (text:gsub('[a-zA-Z]', map))
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
                            VirtualInputManager:SendKeyEvent(true, char, false, game)
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
