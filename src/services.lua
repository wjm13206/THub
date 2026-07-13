--!native
--!optimize 2
local cloneref = cloneref or clonereference or function(obj) return obj end

Services = setmetatable({}, { __index = function(self, name)
    local success, cache = pcall(function() return cloneref(game:GetService(name)) end)
    if success then rawset(self, name, cache); return cache
    else error("无效服务: "..tostring(name)) end
end})

UserInputService = Services.UserInputService
TweenService = Services.TweenService
Players = Services.Players
RunService = Services.RunService
SoundService = Services.SoundService
Lighting = Services.Lighting
MarketplaceService = Services.MarketplaceService
Workspace = Services.Workspace
StarterGui = Services.StarterGui
ReplicatedStorage = Services.ReplicatedStorage
TeleportService = Services.TeleportService
AvatarEditorService = Services.AvatarEditorService
LogService = Services.LogService
HttpService = Services.HttpService
LocalPlayer = Players.LocalPlayer
PlayerGui = LocalPlayer.PlayerGui or LocalPlayer:FindFirstChild("PlayerGui")
CoreGui = Services.CoreGui
