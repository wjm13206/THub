--!native
--!optimize 2
local cloneref = cloneref or clonereference or function(obj) return obj end

UserInputService = cloneref(game:GetService("UserInputService"))
TweenService = cloneref(game:GetService("TweenService"))
Players = cloneref(game:GetService("Players"))
RunService = cloneref(game:GetService("RunService"))
SoundService = cloneref(game:GetService("SoundService"))
Lighting = cloneref(game:GetService("Lighting"))
MarketplaceService = cloneref(game:GetService("MarketplaceService"))
Workspace = cloneref(game:GetService("Workspace"))
VirtualInputManager = cloneref(game:GetService("VirtualInputManager"))
StarterGui = cloneref(game:GetService("StarterGui"))
ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
TeleportService = cloneref(game:GetService("TeleportService"))
VirtualUser = cloneref(game:GetService('VirtualUser'))
AvatarEditorService = cloneref(game:GetService("AvatarEditorService"))
LogService = cloneref(game:GetService("LogService"))
HttpService = cloneref(game:GetService("HttpService"))
LocalPlayer = Players.LocalPlayer
PlayerGui = LocalPlayer.PlayerGui or LocalPlayer:FindFirstChild("PlayerGui")
CoreGui = cloneref(game:GetService('CoreGui')) or PlayerGui
