--!native
--!optimize 2

local AntiKickModule = {}
AntiKickModule.Enabled = false
AntiKickModule.Loaded = false
AntiKickModule.Supported = nil

local cloneref = cloneref or clonereference or function(obj) return obj end
local checkcaller = checkcaller or function() return false end
local newcclosure = newcclosure or function(f) return f end
local hookmetamethod = hookmetamethod or nil
local getnamecallmethod = getnamecallmethod or get_namecall_method or function() return "" end

local hookOrig = {}
local LocalPlayerRef = nil
local TeleportServiceRef = nil

local function checkSupport()
    if AntiKickModule.Supported ~= nil then
        return AntiKickModule.Supported
    end
    if not hookmetamethod then
        AntiKickModule.Supported = false
        return false
    end
    local ok = pcall(function()
        return cloneref(game:GetService("Players").LocalPlayer)
    end)
    if not ok then
        AntiKickModule.Supported = false
        return false
    end
    AntiKickModule.Supported = true
    return true
end

local function installHooks()
    if hookOrig.namecall then return true end

    local Players = cloneref(game:GetService("Players"))
    LocalPlayerRef = Players.LocalPlayer
    TeleportServiceRef = cloneref(game:GetService("TeleportService"))

    hookOrig.namecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if not checkcaller() then
            local mn = getnamecallmethod():lower()
            if self == LocalPlayerRef and mn == "kick" then
                return
            end
            if self == TeleportServiceRef and (mn == "teleport" or mn == "teleporttoplaceinstance") then
                return
            end
        end
        return hookOrig.namecall(self, ...)
    end))

    local hookfunction = hookfunction
    if LocalPlayerRef and hookfunction then
        hookOrig.kickFunc = hookfunction(LocalPlayerRef.Kick, newcclosure(function(...)
            if AntiKickModule.Enabled and not checkcaller() then
                return
            end
            return hookOrig.kickFunc(...)
        end))
    end

    return true
end

function AntiKickModule.enable()
    local ok = checkSupport()
    if not ok then
        AntiKickModule.Enabled = false
        AntiKickModule.Loaded = false
        return false, "不兼容的注入器：缺少 hookmetamethod"
    end
    if AntiKickModule.Enabled then
        return true, "反检测已启用"
    end
    installHooks()
    AntiKickModule.Enabled = true
    AntiKickModule.Loaded = true
    return true, "反检测已启用（防踢 + 防传送）"
end

function AntiKickModule.disable()
    if not AntiKickModule.Loaded then
        return true, "模块未初始化"
    end
    AntiKickModule.Enabled = false
    return true, "反检测已禁用"
end

function AntiKickModule.unload()
    AntiKickModule.Enabled = false
    AntiKickModule.Loaded = false

    if hookOrig.namecall then
        pcall(hookmetamethod, game, "__namecall", hookOrig.namecall)
        hookOrig.namecall = nil
    end
    if hookOrig.kickFunc and hookfunction then
        pcall(hookfunction, LocalPlayerRef and LocalPlayerRef.Kick, hookOrig.kickFunc)
        hookOrig.kickFunc = nil
    end

    LocalPlayerRef = nil
    TeleportServiceRef = nil
    return true, "反检测已卸载（钩子已恢复）"
end

function AntiKickModule.getStatus()
    return {
        enabled = AntiKickModule.Enabled,
        loaded = AntiKickModule.Loaded,
        supported = AntiKickModule.Supported,
    }
end

return AntiKickModule
