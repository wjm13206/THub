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
AsyncFileFetcher = loadstring(cloneref(game):HttpGet(baseUrl .. "/modules/core/AsyncFileFetcher.lua"))()
modulesToFetch = {
    ["ChronixUI"] = baseUrl .. "/modules/ui/ChronixUI%20Lib.lua",
    ["tpWalk"] = baseUrl .. "/modules/movement/SafeTPWalk.lua",
    ["StandRecovery"] = baseUrl .. "/modules/movement/StandRecovery.lua",
    ["HighlightModule"] = baseUrl .. "/modules/visual/HighlightModule.lua",
    ["PlayerLightModule"] = baseUrl .. "/modules/visual/PlayerLightModule.lua",
    ["SpectatorModule"] = baseUrl .. "/modules/utility/SpectatorModule.lua",
    ["FreecamModule"] = baseUrl .. "/modules/utility/FreecamModule.lua",
    ["LandingEffect"] = baseUrl .. "/modules/visual/LandingEffect.lua",
    ["NameTagModule"] = baseUrl .. "/modules/visual/NameTagModule.lua",
    ["PlayerVisibleModule"] = baseUrl .. "/modules/visual/PlayerVisibleModule.lua",
    ["movementModule"] = baseUrl .. "/modules/movement/MovementModule.lua",
    ["MouseUnlockModule"] = baseUrl .. "/modules/utility/MouseUnlockModule.lua",
    ["DeathballScripts"] = baseUrl .. "/modules/games/DeathBallScripts.lua",
    ["ZoomModule"] = baseUrl .. "/modules/utility/ZoomModule.lua",
    ["FlingDetector"] = baseUrl .. "/modules/utility/FlingDetector.lua",
    ["SystemNotification"] = baseUrl .. "/modules/utility/SystemNotification.lua",
    ["PlayerESP"] = baseUrl .. "/modules/visual/PlayerESP.lua",
    ["MovableHighlighter_NM"] = baseUrl .. "/modules/visual/MovableHighlighter-NM.lua",
    ["GameTeleport"] = baseUrl .. "/modules/utility/GameTeleport.lua",
    ["AntiVoidModule"] = baseUrl .. "/modules/utility/AntiVoid.lua",
    ["ChatSpy"] = baseUrl .. "/modules/chat/ChatSpy.lua",
    ["ChatControl"] = baseUrl .. "/modules/chat/ChatControl.lua",
    ["AirWalk"] = baseUrl .. "/modules/movement/AirWalk.lua",
    ["LockCameraModule"] = baseUrl .. "/modules/utility/LockCameraModule.lua",
    ["OBOTeleportModule"] = baseUrl .. "/modules/utility/OBOTeleportModule.lua",
    ["NPCHighLighter"] = baseUrl .. "/modules/visual/NPC_Highlighter.lua",
    ["ChatTagModule"] = baseUrl .. "/modules/visual/ChatTagModule.lua",
    ["FlyModule"] = baseUrl .. "/modules/movement/FlyModule.lua",
    ["ScrollSwitch"] = baseUrl .. "/modules/movement/ScrollSwitch.lua",
    ["Regretevator_AutoIceCream"] = baseUrl .. "/modules/games/Regretevator_AutoIceCream.lua",
    ["InstantInteraction"] = baseUrl .. "/modules/utility/InstantInteraction.lua",
    ["ServerFinderModule"] = baseUrl .. "/modules/utility/ServerFinderModule.lua",
    ["DeleteTool"] = baseUrl .. "/modules/utility/DeleteTool.lua",
    ["GuiDeleter"] = baseUrl .. "/modules/utility/GuiDeleter.lua",
    ["AntiKickModule"] = baseUrl .. "/modules/utility/AntiKick.lua",
    ["HandleKillModule"] = baseUrl .. "/modules/combat/HandleKillModule.lua",
    ["FlingModule"] = baseUrl .. "/modules/combat/FlingModule.lua",
    ["LoopOofModule"] = baseUrl .. "/modules/visual/LoopOofModule.lua",
    ["SpinModule"] = baseUrl .. "/modules/combat/SpinModule.lua",
    ["ConfigModule"] = baseUrl .. "/modules/utility/ConfigModule.lua",
    ["FootstepHighlighter"] = baseUrl .. "/modules/visual/FootstepHighlighter.lua",
    ["TeleportModule"] = baseUrl .. "/modules/utility/TeleportModule.lua",
    ["ChatSpammer"] = baseUrl .. "/modules/chat/ChatSpammer.lua",
    ["TranslationModule"] = baseUrl .. "/modules/utility/TranslationModule.lua",
    ["CframeFly"] = baseUrl .. "/modules/movement/CframeFly.lua",
    ["VehicleFly"] = baseUrl .. "/modules/movement/VehicleFly.lua",
    ["NoclipCam"] = baseUrl .. "/modules/movement/NoclipCam.lua",
    ["NoFall"] = baseUrl .. "/modules/movement/Nofall.lua",
    ["MovingPartCleaner"] = baseUrl .. "/modules/utility/MovingPartCleaner.lua",
    ["DefenseField"] = baseUrl .. "/modules/combat/DefenseField.lua",
    ["ClickInspectModule"] = baseUrl .. "/modules/utility/ClickInspectModule.lua",
    ["TCPHighLight"] = baseUrl .. "/modules/visual/TCPHighLight.lua",
    ["SnapTurn"] = baseUrl .. "/modules/movement/SnapTurn.lua",
    ["SnapReverse"] = baseUrl .. "/modules/movement/SnapReverse.lua",
    ["AntiLookBlocker"] = baseUrl .. "/modules/utility/AntiLookBlocker.lua",
    ["AimBotModule"] = baseUrl .. "/modules/combat/AimBotModule.lua",
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
modulesToFetch = nil
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
