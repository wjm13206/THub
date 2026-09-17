--!native
--!optimize 2

--======================================================================================

unloadTHub = function()
    RemoveFog(false)
    if data["basicdata"]["releasetools"]["infjump"] then infjumpenable(false) end
    if data["basicdata"]["releasetools"]["noclip"] then noclipenable(false) end
    disableDeathAnnounce()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.RootPart and hum.RootPart.Anchored then
            hum.RootPart.Anchored = false
        end
    end
    stopWaypointHeartbeat()
    if waypointBeams then
        for _, beamData in pairs(waypointBeams) do
            if beamData.anchorPart and beamData.anchorPart.Parent then beamData.anchorPart:Destroy() end
            if beamData.indicatorPart and beamData.indicatorPart.Parent then beamData.indicatorPart:Destroy() end
        end
    end
    toggleInteraction("TouchTransmitter", false); toggleInteraction("ClickDetector", false); toggleInteraction("ProximityPrompt", false)
    waypointDisplayEnabled = false
    _G.THubisLoaded = false; _G.THubLoading = false; loadingTimedOut = true
    if data["basicdata"]["releasetools"]["supernightvision"] then Lighting.Brightness = data["basicdata"]["releasetools"]["originalBrightness"]; data["basicdata"]["releasetools"]["supernightvision"] = false end
    if data["basicdata"]["releasetools"]["nightvision"] then Lighting.Ambient = Color3.new(0, 0, 0); data["basicdata"]["releasetools"]["nightvision"] = false end
    data["basicdata"]["otherdata"]["musicbox"]:Stop()
    if musicEndedConn then pcall(function() musicEndedConn:Disconnect() end); musicEndedConn = nil end
    data["basicdata"]["otherdata"]["testSound"]:Stop()
    local colorCorrection = Lighting:FindFirstChild("THub_ColorCorrection")
    if colorCorrection then colorCorrection:Destroy() end
    if data["basicdata"]["releasetools"]["xray"] then xray(false) end
    if next(shownParts) ~= nil then showpartsfunction(false) end

    tpWalk:unload()
    for _, conn in ipairs(data["basicdata"]["modify"]["PDND_Connect"]) do conn:Disconnect() end
    for _, conn in ipairs(data["basicdata"]["modify"]["PHD_Connect"]) do conn:Disconnect() end
    for _, conn in ipairs(data["basicdata"]["modify"]["ASPH_Connect"]) do conn:Disconnect() end
    if data["basicdata"]["releasetools"]["edgejump"] then edgeJumpEnable(false) end
    if data["othergamedata"]["abyss"]["enableinfdoublejump"] then abyssDoubleJumpEnable(false) end
    TPJump:unload()
    TornadoModule:unload()
    OrbitTools:Unload()
    HighlightModule.unload()
    PlayerLightModule:unloadAll()
    SpectatorModule.unload()
    FreecamModule.unload()
    LandingEffect.unload()
    NameTagModule.unload()
    PlayerVisibleModule.unload()
    movementModule.unload()
    MouseUnlockModule.unload()
    if _G.DeathBallScript then _G.DeathBallScript:unload() end
    data["basicdata"]["releasetools"]["zoom"]:unload()
    FlingDetector.unload()
    PlayerESP.unload()
    MovableHighlighter_NM.unloadAll()
    AntiVoidModule.unload()
    ChatSpy.unload()
    ChatControl:unload()
    AirWalk.unload()
    LockCameraModule.unload()
    data["basicdata"]["releasetools"]["npc"]:unload()
    ChatTagModule.unload()
    FlyModule.unload()
    ScrollSwitch:unload()
    Regretevator_AutoIceCream:unload()
    InstantInteraction.unload()
    TCPTrigger.unload()
    DeleteTool.unload()
    GuiDeleter.unload()
    AntiKickModule.unload()
    HandleKillModule.unload()
    FlingModule.unload()
    LoopOofModule.unload()
    SpinModule.unload()
    FootstepHighlighter.unload()
    TeleportModule.unload()
    TranslationModule.unload()
    CframeFly.unload()
    VehicleFly.unload()
    NoclipCam.unload()
    NoFall.unload()
    MovingPartCleaner.unload()
    DefenseField.unload()
    ClickInspectModule.unload()
    TCPHighLight.unload()
    SnapTurn.unload()
    SnapReverse.unload()
    AimBotModule.unload()
    ChatSpammer.unload()
    if DrawmeModule then DrawmeModule.unload() end

    if data["basicdata"]["otherdata"]["audioData"]["scanConnection"] then data["basicdata"]["otherdata"]["audioData"]["scanConnection"]:Disconnect() end
    if noclipConnection then noclipConnection:Disconnect() end
    if noclipRespawn then noclipRespawn:Disconnect() end
    if autoJumpActive ~= nil then autoJumpActive = false end
    if autoJumpThread then pcall(task.cancel, autoJumpThread); autoJumpThread = nil end
    if autoJumpConnection then pcall(function() autoJumpConnection:Disconnect() end); autoJumpConnection = nil end
    if JR then JR:Disconnect(); JR = nil end
    if testSoundEndedConn then testSoundEndedConn:Disconnect(); testSoundEndedConn = nil end
    if playerListAddedConn then playerListAddedConn:Disconnect() end
    if playerListRemovingConn then playerListRemovingConn:Disconnect() end
    if _G.UESP1_Cleanup then _G.UESP1_Cleanup() end
    clearAllConnections()
    pcall(restoreSpoofHooks)

    pcall(function() SystemNotification.UnloadedGradient("THub V3 Already Unload!") end)
    LogService:Info("[THub] 已成功卸载。")

    if modulesToFetch then for moduleName, _ in pairs(modulesToFetch) do (_ENV or getfenv())[moduleName] = nil end end; AsyncFileFetcher = nil

    data = nil
end
