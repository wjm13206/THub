-- TeleportModule (ModuleScript)
local cloneref = cloneref or clonereference or function(obj) return obj end
local TeleportService = cloneref(game:GetService("TeleportService"))
local Players = cloneref(game:GetService("Players"))
local HttpService = cloneref(game:GetService("HttpService"))

local Teleport = {}

-- 私有函数：根据游戏 ID（universeId）获取根场景 ID（rootPlaceId）
local function getRootPlaceIdFromUniverseId(universeId)
    local url = "https://games.roblox.com/v1/games?universeIds=" .. universeId
    local success, response = pcall(function()
        return game:HttpGet(url)  -- 使用 game:HttpGet 确保兼容性
    end)

    if not success then
        warn("HTTP 请求失败: " .. tostring(response))
        return nil
    end

    local data = HttpService:JSONDecode(response)
    if data and data.data and #data.data > 0 then
        local gameInfo = data.data[1]
        if gameInfo.rootPlaceId then
            return gameInfo.rootPlaceId
        end
    end

    warn("未找到游戏 ID " .. universeId .. " 对应的根场景 ID")
    return nil
end

-- 唯一公开函数：传入游戏 ID（universeId），传送当前玩家
function Teleport.teleportByGameId(universeId)
    local rootPlaceId = getRootPlaceIdFromUniverseId(universeId)
    if not rootPlaceId then
        return false, "无法获取根场景 ID"
    end

    local player = Players.LocalPlayer
    if not player then
        return false, "未找到本地玩家"
    end

    local success, err = pcall(function()
        TeleportService:Teleport(rootPlaceId, player)
    end)

    if not success then
        warn("传送失败: " .. tostring(err))
        return false, tostring(err)
    end

    return true
end

return Teleport