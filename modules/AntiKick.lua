-- AntiKickModule.lua
-- 反踢出保护模块

local AntiKickModule = {}
AntiKickModule.Enabled = false
AntiKickModule.Loaded = false
AntiKickModule.Supported = nil -- nil = 未检测, true = 支持, false = 不支持
local cloneref = cloneref or clonereference or function(obj) return obj end

-- 内部状态
local oldhmmi = nil
local oldhmmnc = nil
local oldKickFunction = nil
local hooksInstalled = false

-- 检查支持性（仅检查一次）
local function checkSupport()
    if AntiKickModule.Supported ~= nil then
        return AntiKickModule.Supported
    end
    
    if not hookmetamethod then
        AntiKickModule.Supported = false
        return false
    end
    
    -- 可选：进一步检查 LocalPlayer 是否可访问
    local success = pcall(function()
        return cloneref(game:GetService("Players").LocalPlayer)
    end)
    if not success then
        AntiKickModule.Supported = false
        return false
    end
    
    AntiKickModule.Supported = true
    return true
end

-- 内部方法：安装钩子
local function installHooks()
    if hooksInstalled then return true end
    
    local LocalPlayer = cloneref(game:GetService("Players").LocalPlayer)
    if not LocalPlayer then return false end
    
    -- Hook __index
    oldhmmi = hookmetamethod(game, "__index", function(self, method)
        if AntiKickModule.Enabled and self == LocalPlayer and type(method) == "string" and method:lower() == "kick" then
            return error("Expected ':' not '.' calling member function Kick", 2)
        end
        return oldhmmi(self, method)
    end)
    
    -- Hook __namecall
    oldhmmnc = hookmetamethod(game, "__namecall", function(self, ...)
        if AntiKickModule.Enabled and self == LocalPlayer and getnamecallmethod():lower() == "kick" then
            return
        end
        return oldhmmnc(self, ...)
    end)
    
    -- Hook Kick function
    if hookfunction then
        oldKickFunction = hookfunction(LocalPlayer.Kick, function(...)
            if AntiKickModule.Enabled then return end
            return oldKickFunction(...)
        end)
    end
    
    hooksInstalled = true
    return true
end

-- 启用反踢出
function AntiKickModule.enable()
    -- 检查支持性
    local supported = checkSupport()
    if not supported then
        AntiKickModule.Enabled = false -- 明确设为 false
        AntiKickModule.Loaded = false
        return false, "Incompatible Exploit: missing hookmetamethod or LocalPlayer not accessible"
    end
    
    -- 检查是否已启用
    if AntiKickModule.Enabled then
        return true, "Anti-Kick is already enabled"
    end
    
    -- 安装钩子
    local success = installHooks()
    if not success then
        AntiKickModule.Enabled = false -- 明确设为 false
        return false, "Failed to install hooks: LocalPlayer not found"
    end
    
    AntiKickModule.Enabled = true
    AntiKickModule.Loaded = true
    return true, "Anti-Kick enabled"
end

-- 禁用反踢出
function AntiKickModule.disable()
    -- 检查是否已初始化
    if not AntiKickModule.Loaded then
        return true, "Module not initialized, nothing to disable"
    end
    
    -- 检查支持性（如果之前没检测过）
    if AntiKickModule.Supported == nil then
        checkSupport()
    end
    
    -- 检查是否已禁用
    if not AntiKickModule.Enabled then
        return true, "Anti-Kick is already disabled"
    end
    
    -- 如果根本不支持，直接返回
    if AntiKickModule.Supported == false then
        AntiKickModule.Enabled = false
        return true, "Anti-Kick disabled (was never functional due to incompatibility)"
    end
    
    AntiKickModule.Enabled = false
    return true, "Anti-Kick disabled"
end

-- 卸载模块
function AntiKickModule.unload()
    -- 不管之前什么状态，都安全处理
    local wasEnabled = AntiKickModule.Enabled
    
    -- 禁用功能
    AntiKickModule.Enabled = false
    
    -- 清理引用（即使 hooksInstalled 为 false 也安全）
    oldhmmi = nil
    oldhmmnc = nil
    oldKickFunction = nil
    hooksInstalled = false
    
    AntiKickModule.Loaded = false
    -- 注意：不重置 Supported，保留检测结果
    
    if wasEnabled then
        return true, "Anti-Kick unloaded and disabled"
    else
        return true, "Anti-Kick unloaded (was already disabled)"
    end
end

-- 获取详细状态
function AntiKickModule.getStatus()
    return {
        enabled = AntiKickModule.Enabled or false,
        loaded = AntiKickModule.Loaded or false,
        supported = AntiKickModule.Supported,
        hooksInstalled = hooksInstalled or false,
        functional = (AntiKickModule.Enabled and AntiKickModule.Supported and hooksInstalled) or false
    }
end

return AntiKickModule