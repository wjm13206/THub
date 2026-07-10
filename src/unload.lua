--!native
--!optimize 2

--======================================================================================

unloadTHub = function()
    disableDeathAnnounce()
    if LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RootPart.Anchored then LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RootPart.Anchored = false end
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
    for _, part in pairs(data["basicdata"]["releasetools"]["noclipParts"]) do
        part.CanCollide = true
    end
    data["basicdata"]["releasetools"]["noclipParts"] = {}
    data["basicdata"]["releasetools"]["noclip"] = false
    data["basicdata"]["releasetools"]["infjump"] = false
    if data["basicdata"]["releasetools"]["supernightvision"] then Lighting.Brightness = data["basicdata"]["releasetools"]["originalBrightness"]; data["basicdata"]["releasetools"]["supernightvision"] = false end
    if data["basicdata"]["releasetools"]["nightvision"] then game.Lighting.Ambient = Color3.new(0, 0, 0); data["basicdata"]["releasetools"]["nightvision"] = false end
    data["basicdata"]["otherdata"]["musicbox"]:Stop()
    data["basicdata"]["otherdata"]["testSound"]:Stop()
    local colorCorrection = Lighting:FindFirstChild("THub_ColorCorrection")
    if colorCorrection then colorCorrection:Destroy() end
    if data["basicdata"]["releasetools"]["xray"] then xray(false) end
    if #shownParts > 0 then showpartsfunction(false) end

    tpWalk:unload()
    StandRecovery:unload()
    HighlightModule.unload()
    PlayerLightModule:unloadAll()
    SpectatorModule.unload()
    FreecamModule.unload()
    LandingEffect.unload()
    NameTagModule.unload()
    PlayerVisibleModule.unload()
    movementModule.Unload()
    MouseUnlockModule.unload()
    if _G.DeathBallScript then _G.DeathBallScript:Unload() end
    data["basicdata"]["releasetools"]["zoom"]:Unload()
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
    DeleteTool.Unload()
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
    MovingPartCleaner.Unload()
    DefenseField.Unload()
    ClickInspectModule.Unload()
    TCPHighLight.unload()
    SnapTurn.Unload()
    SnapReverse.Unload()
    AimBotModule.Unload()
    ChatSpammer.unload()

    if data["basicdata"]["otherdata"]["audioData"]["scanConnection"] then data["basicdata"]["otherdata"]["audioData"]["scanConnection"]:Disconnect() end
    if prc then prc:Disconnect() end
    if pac then pac:Disconnect() end
    if WorkspaceDescendantAdded then WorkspaceDescendantAdded:Disconnect() end
    if noclipConnection then noclipConnection:Disconnect() end
    if noclipRespawn then noclipRespawn:Disconnect() end
    if autoJumpConnection then autoJumpConnection:Disconnect() end
    if JR then JR:Disconnect(); JR = nil end
    if AntiAFK then AntiAFK:Disconnect() end
    if RunStepped then RunStepped:Disconnect() end
    if keepthubconnect then keepthubconnect:Disconnect() end
    if networkPaused then networkPaused:Disconnect() end
    if staffwatchjoin then staffwatchjoin:Disconnect() end
    if playerListAddedConn then playerListAddedConn:Disconnect() end
    if playerListRemovingConn then playerListRemovingConn:Disconnect() end
    if testSoundEndedConn then testSoundEndedConn:Disconnect(); testSoundEndedConn = nil end
    if _G.UESP1_Cleanup then _G.UESP1_Cleanup() end
    clearAllConnections()
    pcall(restoreSpoofHooks)

    pcall(function() SystemNotification.UnloadedGradient("THub V3 Already Unload!") end)
    LogService:Info("[THub] 已成功卸载。")

    if modulesToFetch then for moduleName, _ in pairs(modulesToFetch) do (_ENV or getfenv())[moduleName] = nil end end; AsyncFileFetcher = nil

    data = nil
end
