-- ServerQueryModule.lua
-- 独立模块，用于查询 Roblox 游戏的公共服务器列表
-- 使用方法: local finder = require(module); local instance = finder.new(game.PlaceId)

local cloneref = cloneref or clonereference or function(obj) return obj end
local HttpService = cloneref(game:GetService("HttpService"))

local ServerQuery = {}
ServerQuery.__index = ServerQuery

-- 构造函数，可传入 PlaceId（默认当前游戏）
function ServerQuery.new(placeId)
	local self = setmetatable({}, ServerQuery)
	self._placeId = placeId or game.PlaceId
	self._servers = {}      -- 存储所有服务器数据（扁平化）
	self._scanning = false  -- 是否正在扫描
	return self
end

-- 内部方法：请求一页数据
function ServerQuery:_fetchPage(cursor)
	local url = "https://games.roblox.com/v1/games/" .. self._placeId .. "/servers/Public?sortOrder=Desc&limit=100"
	if cursor and cursor ~= "null" then
		url = url .. "&cursor=" .. cursor
	end

	local success, result = pcall(function()
		return HttpService:JSONDecode(game:HttpGet(url))
	end)

	if not success then
		return nil, result  -- 返回错误
	end
	return result
end

-- 刷新/获取所有公共服务器
-- 完成后返回服务器列表，同时更新内部缓存
function ServerQuery:refresh()
	if self._scanning then
		return self._servers  -- 防止重复扫描
	end

	self._scanning = true
	self._servers = {}

	local cursor = nil
	repeat
		local page, err = self:_fetchPage(cursor)
		if not page then
			warn("ServerQuery: 获取服务器列表出错:", err)
			break
		end

		if page.data then
			for _, server in ipairs(page.data) do
				table.insert(self._servers, server)
			end
		end

		cursor = page.nextPageCursor
		if cursor == "null" then
			cursor = nil
		end

		-- 短暂让出，避免长时间阻塞（某些环境下可能不需要）
		task.wait()
	until not cursor

	self._scanning = false
	return self._servers
end

-- 获取当前缓存的服务器列表
function ServerQuery:getServers()
	return self._servers
end

-- 根据服务器 ID 查找特定服务器信息
function ServerQuery:getServerById(serverId)
	for _, server in ipairs(self._servers) do
		if server.id == serverId then
			return server
		end
	end
	return nil
end

-- 查询是否正在扫描
function ServerQuery:isScanning()
	return self._scanning
end

-- 可选的异步刷新（通过回调通知）
-- callback 将在扫描完成时被调用，参数为服务器列表
function ServerQuery:refreshAsync(callback)
	if self._scanning then
		if callback then
			callback(self._servers)
		end
		return
	end

	self._scanning = true
	self._servers = {}

	local function scan(cursor)
		local page, err = self:_fetchPage(cursor)
		if not page then
			warn("ServerQuery: 获取服务器列表出错:", err)
			self._scanning = false
			if callback then callback(self._servers) end
			return
		end

		if page.data then
			for _, server in ipairs(page.data) do
				table.insert(self._servers, server)
			end
		end

		local nextCursor = page.nextPageCursor
		if nextCursor and nextCursor ~= "null" then
			-- 继续下一页（通过 task.spawn 避免递归过深）
			task.spawn(function()
				scan(nextCursor)
			end)
		else
			self._scanning = false
			if callback then callback(self._servers) end
		end
	end

	task.spawn(function()
		scan(nil)
	end)
end

return ServerQuery