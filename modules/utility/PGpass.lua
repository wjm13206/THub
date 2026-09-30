--!native
--!optimize 2
-- 通行证/开发者产品绕过：仅无服务端验证的服务器有效

local Module = {}

local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local MarketplaceService = cloneref(game:GetService("MarketplaceService"))
local HttpService = cloneref(game:GetService("HttpService"))

local LocalPlayer = Players.LocalPlayer

local productCache = {}   -- [name] = {id, name, price}
local gamepassCache = {}  -- [name] = {id, name, price}

-- 本地伪造购买成功回调
local function fireProductPurchase(productId)
    return pcall(function()
        MarketplaceService:SignalPromptProductPurchaseFinished(LocalPlayer.UserId, productId, true)
    end)
end

local function fireGamepassPurchase(passId)
    return pcall(function()
        MarketplaceService:SignalPromptGamePassPurchaseFinished(LocalPlayer, passId, true)
    end)
end

-- 开发者产品：翻页取全
function Module.GetProducts()
    table.clear(productCache)
    local ok, pages = pcall(function()
        return MarketplaceService:GetDeveloperProductsAsync()
    end)
    if not ok or not pages then return productCache end
    while true do
        local okPage, items = pcall(function() return pages:GetCurrentPage() end)
        if okPage and items then
            for _, product in ipairs(items) do
                pcall(function()
                    productCache[product.Name] = {
                        id = product.ProductId,
                        name = product.Name,
                        price = product.PriceInRobux,
                    }
                end)
            end
        end
        local isFinished = true
        pcall(function() isFinished = pages.IsFinished end)
        if isFinished then break end
        local okNext = pcall(function() pages:AdvanceToNextPageAsync() end)
        if not okNext then break end
    end
    return productCache
end

local function getUniverseId(placeId)
    local url = "https://apis.roblox.com/universes/v1/places/" .. tostring(placeId) .. "/universe"
    local ok, res = pcall(function()
        return cloneref(game):HttpGet(url)
    end)
    if not ok or not res then return nil end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, res)
    if ok2 and data and data.universeId then
        return data.universeId
    end
    return nil
end

local function fetchGamepasses(universeId)
    local url = "https://apis.roblox.com/game-passes/v1/universes/" .. tostring(universeId)
        .. "/game-passes?passView=Full&pageSize=100"
    local ok, res = pcall(function()
        return cloneref(game):HttpGet(url)
    end)
    if not ok or not res then return nil end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, res)
    if ok2 and data and data.data then
        return data.data
    end
    return nil
end

function Module.GetGamepasses()
    table.clear(gamepassCache)
    local universeId = getUniverseId(game.PlaceId)
    if not universeId then return gamepassCache end
    local list = fetchGamepasses(universeId)
    if not list then return gamepassCache end
    for _, gp in ipairs(list) do
        pcall(function()
            local displayName = gp.displayName or gp.name or ("Pass_" .. tostring(gp.id))
            gamepassCache[displayName] = {
                id = gp.id,
                name = displayName,
                price = gp.price,
            }
        end)
    end
    return gamepassCache
end

function Module.GetProductNames()
    local names = {}
    for name in pairs(productCache) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

function Module.GetGamepassNames()
    local names = {}
    for name in pairs(gamepassCache) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

-- 已拥有检测：避免对已拥有的重复发信号
function Module.OwnsGamepass(passId)
    local ok, owns = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, passId)
    end)
    if ok then return owns end
    return nil
end

function Module.BuyProduct(name)
    local entry = productCache[name]
    if not entry then return false, "未找到该产品，请先刷新列表" end
    return fireProductPurchase(entry.id)
end

function Module.BuyGamepass(name)
    local entry = gamepassCache[name]
    if not entry then return false, "未找到该通行证，请先刷新列表" end
    return fireGamepassPurchase(entry.id)
end

function Module.BuyAllProducts()
    local count = 0
    for _, entry in pairs(productCache) do
        local ok = fireProductPurchase(entry.id)
        if ok then count = count + 1 end
        task.wait(0.5)
    end
    return count
end

function Module.BuyAllGamepasses()
    local count = 0
    for _, entry in pairs(gamepassCache) do
        local ok = fireGamepassPurchase(entry.id)
        if ok then count = count + 1 end
        task.wait(0.5)
    end
    return count
end

-- 手填 ID：用于列表枚举不到的情况
function Module.AddManualGamepass(id, name)
    id = tonumber(id)
    if not id then return false, "ID 必须是数字" end
    name = name and tostring(name) ~= "" and tostring(name) or ("Pass_" .. tostring(id))
    gamepassCache[name] = { id = id, name = name, price = nil }
    return true
end

function Module.BuyGamepassById(passId)
    passId = tonumber(passId)
    if not passId then return false, "ID 必须是数字" end
    return fireGamepassPurchase(passId)
end

function Module.ClearCache()
    table.clear(productCache)
    table.clear(gamepassCache)
end

function Module.unload()
    Module.ClearCache()
end

return Module
