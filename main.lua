--!native
--!optimize 2
if not game:IsLoaded() then game.Loaded:Wait() end
local cloneref = cloneref or clonereference or function(obj) return obj end
if _G.THubisLoaded then warn("[THub] ⛔ THub 已经加载了！请不要重复执行。"); return end
if _G.THubLoading then warn("[THub] ⏳ 脚本正在加载中，请勿频繁执行！"); return else _G.THubLoading = true end
local startTime = tick()
local loadingTimedOut = false
task.spawn(function()
    task.wait(60)
    if not loadingTimedOut then
        _G.THubLoading = false
        StarterGui:SetCore("SendNotification", {
            Title = "THub",
            Text = "加载超时，请重试",
            Duration = 5
        })
        LogService:Info("[THub] 加载超时，请重试。")
    end
end)
cloneref(game.LogService):Info("[THub] 已开启初始化进程。")
local baseUrl = "https://raw.githubusercontent.com/wjm13206/THub/refs/heads/main"

-- 1. Services
loadstring(game:HttpGet(baseUrl .. "/src/services.lua"))()

-- 2. Load functional modules
AsyncFileFetcher = loadstring(game:HttpGet(baseUrl .. "/modules/AsyncFileFetcher.lua"))()
modulesToFetch = {
    ["ChronixUI"] = baseUrl .. "/modules/ChronixUI%20Lib.lua",
    ["tpWalk"] = baseUrl .. "/modules/SafeTPWalk.lua",
    ["StandRecovery"] = baseUrl .. "/modules/StandRecovery.lua",
    ["HighlightModule"] = baseUrl .. "/modules/HighlightModule.lua",
    ["PlayerLightModule"] = baseUrl .. "/modules/PlayerLightModule.lua",
    ["SpectatorModule"] = baseUrl .. "/modules/SpectatorModule.lua",
    ["FreecamModule"] = baseUrl .. "/modules/FreecamModule.lua",
    ["LandingEffect"] = baseUrl .. "/modules/LandingEffect.lua",
    ["NameTagModule"] = baseUrl .. "/modules/NameTagModule.lua",
    ["PlayerVisibleModule"] = baseUrl .. "/modules/PlayerVisibleModule.lua",
    ["movementModule"] = baseUrl .. "/modules/MovementModule.lua",
    ["MouseUnlockModule"] = baseUrl .. "/modules/MouseUnlockModule.lua",
    ["DeathballScripts"] = baseUrl .. "/modules/DeathBallScripts.lua",
    ["ZoomModule"] = baseUrl .. "/modules/ZoomModule.lua",
    ["FlingDetector"] = baseUrl .. "/modules/FlingDetector.lua",
    ["SystemNotification"] = baseUrl .. "/modules/SystemNotification.lua",
    ["PlayerESP"] = baseUrl .. "/modules/PlayerESP.lua",
    ["MovableHighlighter_NM"] = baseUrl .. "/modules/MovableHighlighter-NM.lua",
    ["GameTeleport"] = baseUrl .. "/modules/GameTeleport.lua",
    ["AntiVoidModule"] = baseUrl .. "/modules/AntiVoid.lua",
    ["ChatSpy"] = baseUrl .. "/modules/ChatSpy.lua",
    ["ChatControl"] = baseUrl .. "/modules/ChatControl.lua",
    ["AirWalk"] = baseUrl .. "/modules/AirWalk.lua",
    ["LockCameraModule"] = baseUrl .. "/modules/LockCameraModule.lua",
    ["OBOTeleportModule"] = baseUrl .. "/modules/OBOTeleportModule.lua",
    ["NPCHighLighter"] = baseUrl .. "/modules/NPC_Highlighter.lua",
    ["ChatTagModule"] = baseUrl .. "/modules/ChatTagModule.lua",
    ["FlyModule"] = baseUrl .. "/modules/FlyModule.lua",
    ["ScrollSwitch"] = baseUrl .. "/modules/ScrollSwitch.lua",
    ["Regretevator_AutoIceCream"] = baseUrl .. "/modules/Regretevator_AutoIceCream.lua",
    ["InstantInteraction"] = baseUrl .. "/modules/InstantInteraction.lua",
    ["UNCTestModule"] = baseUrl .. "/modules/UNCAndWUNCGet.lua",
    ["ServerFinderModule"] = baseUrl .. "/modules/ServerFinderModule.lua",
    ["DeleteTool"] = baseUrl .. "/modules/DeleteTool.lua",
    ["GuiDeleter"] = baseUrl .. "/modules/GuiDeleter.lua",
    ["AntiKickModule"] = baseUrl .. "/modules/AntiKick.lua",
    ["HandleKillModule"] = baseUrl .. "/modules/HandleKillModule.lua",
    ["FlingModule"] = baseUrl .. "/modules/FlingModule.lua",
    ["LoopOofModule"] = baseUrl .. "/modules/LoopOofModule.lua",
    ["SpinModule"] = baseUrl .. "/modules/SpinModule.lua",
    ["ConfigModule"] = baseUrl .. "/modules/ConfigModule.lua",
    ["FootstepHighlighter"] = baseUrl .. "/modules/FootstepHighlighter.lua",
    ["TeleportModule"] = baseUrl .. "/modules/TeleportModule.lua",
    ["ChatSpammer"] = baseUrl .. "/modules/ChatSpammer.lua",
    ["TranslationModule"] = baseUrl .. "/modules/TranslationModule.lua",
    ["CframeFly"] = baseUrl .. "/modules/CframeFly.lua",
    ["VehicleFly"] = baseUrl .. "/modules/VehicleFly.lua",
    ["NoclipCam"] = baseUrl .. "/modules/NoclipCam.lua",
    ["NoFall"] = baseUrl .. "/modules/Nofall.lua",
    ["MovingPartCleaner"] = baseUrl .. "/modules/MovingPartCleaner.lua",
    ["DefenseField"] = baseUrl .. "/modules/DefenseField.lua",
    ["ClickInspectModule"] = baseUrl .. "/modules/ClickInspectModule.lua",
    ["TCPHighLight"] = baseUrl .. "/modules/TCPHighLight.lua",
    ["SnapTurn"] = baseUrl .. "/modules/SnapTurn.lua",
    ["SnapReverse"] = baseUrl .. "/modules/SnapReverse.lua",
    ["AntiLookBlocker"] = baseUrl .. "/modules/AntiLookBlocker.lua",
}
local moduleContents = AsyncFileFetcher.fetchMultiple(modulesToFetch)
local moduleKeys = {}
for k in pairs(moduleContents) do
    table.insert(moduleKeys, k)
end

local BATCH_SIZE = 5
for i = 1, #moduleKeys, BATCH_SIZE do
    for j = i, math.min(i + BATCH_SIZE - 1, #moduleKeys) do
        local key = moduleKeys[j]
        local content = moduleContents[key]
        if content and type(content) == "string" and content ~= "" then
            local success, result = pcall(loadstring, content)
            if success and result then
                (_ENV or getfenv())[key] = result()
            else
                warn("模块加载失败: " .. key)
            end
        end
    end
    task.wait()
end
LogService:Info("[THub] 模块加载完毕，UI正在初始化中...")

-- 3. Config
loadstring(game:HttpGet(baseUrl .. "/src/config.lua"))()

-- 4. Utils
loadstring(game:HttpGet(baseUrl .. "/src/utils.lua"))()

-- 5. UI
loadstring(game:HttpGet(baseUrl .. "/src/ui.lua"))()

-- 6. Events
loadstring(game:HttpGet(baseUrl .. "/src/events.lua"))()

-- 7. Unload
loadstring(game:HttpGet(baseUrl .. "/src/unload.lua"))()

-- 8. Final notification
local loadTime = string.format("%.2f", tick() - startTime)
ChronixUI:Notify({ Title = "提示", Content = "THub 启动成功。用时: " .. loadTime .. "s\n防挂机已自动开启。", Type = "info", Duration = 10 })
LogService:Info("[THub] 已成功加载。用时: " .. loadTime .. "s")
pcall(function() SystemNotification.Rainbow("THub V3 已成功加载！\n欢迎 " .. data["basicdata"]["player"]["displayname"]) end)
_G.THubisLoaded = true; _G.THubLoading = false; loadingTimedOut = true
