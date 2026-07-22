-- ================================================
-- 文件名：NameTagModule.lua
-- 放置位置：ReplicatedStorage（客户端 require 使用）
-- 支持匹配模式: "only", "fuzzy", "path", "pathFuzzy"
-- ================================================

local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local Workspace = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))

local NameTagModule = {}
local instances = {}

local LocalPlayer = Players.LocalPlayer

-- -------------------------------------------------
-- 内部工具函数：构建对象的完整路径
-- -------------------------------------------------
local function getFullPath(obj)
	local parts = {}
	local current = obj
	while current do
		table.insert(parts, 1, current.Name)
		current = current.Parent
	end
	return table.concat(parts, ".")
end

-- -------------------------------------------------
-- 内部工具函数：路径绝对匹配 - 找到指定路径的对象
-- -------------------------------------------------
local function findObjectByAbsolutePath(pathStr)
	local parts = {}
	for part in string.gmatch(pathStr, "[^%.]+") do
		table.insert(parts, part)
	end
	if #parts == 0 then return nil end

	local current = game
	for i = 1, #parts do
		current = current:FindFirstChild(parts[i])
		if not current then
			return nil
		end
	end
	return current
end

-- -------------------------------------------------
-- 内部工具函数：路径模糊匹配 - 在路径中查找匹配层级
-- -------------------------------------------------
local function findDeepestMatchLevel(pathStr, patterns)
	local pathParts = {}
	for part in string.gmatch(pathStr, "[^%.]+") do
		table.insert(pathParts, part)
	end

	local searchTerms
	if type(patterns) == "table" then
		searchTerms = patterns
	else
		searchTerms = {patterns}
	end

	if #searchTerms == 1 then
		local term = searchTerms[1]
		local deepestLevel = 0
		for i, part in ipairs(pathParts) do
			if i > 1 and string.find(part, term) then
				deepestLevel = i - 1
			end
		end
		return deepestLevel
	end

	local matchedLevels = {}
	for _, term in ipairs(searchTerms) do
		local deepestForTerm = 0
		for i, part in ipairs(pathParts) do
			if i > 1 and string.find(part, term) then
				deepestForTerm = i - 1
			end
		end
		if deepestForTerm == 0 then
			return 0
		end
		table.insert(matchedLevels, deepestForTerm)
	end

	local maxLevel = 0
	for _, level in ipairs(matchedLevels) do
		if level > maxLevel then
			maxLevel = level
		end
	end
	return maxLevel
end

-- -------------------------------------------------
-- 创建 NameTag 实例
-- -------------------------------------------------
local function createNameTagInstance(modelName, matchMode, fontSize, showDistance, customText)
	local self = {}

	self.modelName = modelName
	self.matchMode = matchMode or "fuzzy"
	self.fontSize = fontSize
	self.showDistance = showDistance or false
	self.customText = customText

	self.enabled = false
	self.connections = {}
	self.activeTags = {}           -- { [model] = {billboard, label} }
	self.modelToTag = {}           -- Model -> true（防重复）
	self.scanConnection = nil
	self.descendantConnection = nil
	self.modelConns = {}           -- 模型内部的 DescendantAdded 连接
	self.currentApplyTaskId = nil
	self.isApplying = false

	-- 任务ID生成器
	local taskCounter = 0
	local function getNewTaskId()
		taskCounter = taskCounter + 1
		return taskCounter
	end

	-- 内部：为模型添加标签
	local function addTagToModel(model)
		if not model:IsA("Model") then return end
		if self.modelToTag[model] then return end
		if Players:GetPlayerFromCharacter(model) then return end

		-- 找任意 BasePart 作为 Adornee（递归找）
		local adornee = nil
		for _, child in ipairs(model:GetDescendants()) do
			if child:IsA("BasePart") then
				adornee = child
				break
			end
		end

		-- 创建 BillboardGui
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "NameTag_" .. model.Name
		billboard.Size = UDim2.new(0, 200, 0, 50)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = model

		if adornee then
			billboard.Adornee = adornee
		end

		-- 创建 TextLabel
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0.5
		label.Font = Enum.Font.SourceSansBold
		label.Parent = billboard

		if self.customText then
			label.Text = self.customText
		else
			label.Text = model.Name
		end

		if self.fontSize then
			label.TextScaled = false
			label.TextSize = self.fontSize
		else
			label.TextScaled = true
		end

		-- 记录
		self.activeTags[model] = { billboard = billboard, label = label }
		self.modelToTag[model] = true

		-- 如果没有 adornee，监听模型内部新增部件，等部件出现时补上
		if not adornee then
			local childConn = model.DescendantAdded:Connect(function(child)
				if child:IsA("BasePart") and not billboard.Adornee then
					billboard.Adornee = child
					childConn:Disconnect()
				end
			end)
			table.insert(self.modelConns, childConn)
		end
	end

	-- 内部：移除模型上的标签
	local function removeTagFromModel(model)
		local tagData = self.activeTags[model]
		if not tagData then return end

		if tagData.billboard and tagData.billboard.Parent then
			tagData.billboard:Destroy()
		end
		self.activeTags[model] = nil
		self.modelToTag[model] = nil
	end

	-- 内部：移除所有标签
	local function removeAllTags()
		for model, _ in pairs(self.activeTags) do
			removeTagFromModel(model)
		end
	end

	-- 内部：检查对象是否匹配（跟高亮模块一致）
	local function isMatch(obj)
		if self.matchMode == "only" then
			return obj.Name == self.modelName
		elseif self.matchMode == "fuzzy" then
			return string.find(obj.Name, self.modelName) ~= nil
		elseif self.matchMode == "path" then
			return getFullPath(obj) == self.modelName
		elseif self.matchMode == "pathFuzzy" then
			return findDeepestMatchLevel(getFullPath(obj), self.modelName) > 0
		end
		return false
	end

	-- 内部：检查对象是否是目标路径对象的后代（path/pathFuzzy 扫描时用）
	local function isDescendantOfTarget(obj, targetObj)
		local current = obj
		while current do
			if current == targetObj then
				return true
			end
			current = current.Parent
		end
		return false
	end

	-- 内部：异步扫描核心（分帧处理）
	local function asyncScanCore(taskId)
		if self.scanConnection then
			self.scanConnection:Disconnect()
			self.scanConnection = nil
		end

		local allObjects = Workspace:GetDescendants()
		local total = #allObjects
		local processed = 0
		local batch = 100

		self.scanConnection = RunService.RenderStepped:Connect(function()
			if taskId ~= self.currentApplyTaskId then
				if self.scanConnection then
					self.scanConnection:Disconnect()
					self.scanConnection = nil
				end
				return
			end

			local endIdx = math.min(processed + batch, total)
			for i = processed + 1, endIdx do
				local obj = allObjects[i]
				if not obj:IsA("Model") then continue end

				if self.matchMode == "path" then
					local targetObj = findObjectByAbsolutePath(self.modelName)
					if targetObj and isDescendantOfTarget(obj, targetObj) then
						addTagToModel(obj)
					end
				elseif self.matchMode == "pathFuzzy" then
					if findDeepestMatchLevel(getFullPath(obj), self.modelName) > 0 then
						addTagToModel(obj)
					end
				else
					if isMatch(obj) then
						addTagToModel(obj)
					end
				end
			end
			processed = endIdx

			if processed >= total then
				if self.scanConnection then
					self.scanConnection:Disconnect()
					self.scanConnection = nil
				end
				self.isApplying = false
			end
		end)
	end

	-- 公共方法：启用
	self.enable = function()
		if self.enabled then return end
		self.enabled = true

		self.currentApplyTaskId = getNewTaskId()
		if self.scanConnection then
			self.scanConnection:Disconnect()
			self.scanConnection = nil
		end

		if self.descendantConnection then
			self.descendantConnection:Disconnect()
			self.descendantConnection = nil
		end
		for _, conn in pairs(self.modelConns) do
			conn:Disconnect()
		end
		self.modelConns = {}

		self.isApplying = true
		asyncScanCore(self.currentApplyTaskId)

		-- 监听新加入的对象
		self.descendantConnection = Workspace.DescendantAdded:Connect(function(descendant)
			if not self.enabled then return end

			if self.matchMode == "path" then
				local targetObj = findObjectByAbsolutePath(self.modelName)
				if targetObj then
					local current = descendant
					while current do
						if current == targetObj then
							if descendant:IsA("Model") then
								addTagToModel(descendant)
								local childConn = descendant.DescendantAdded:Connect(function(child)
									if child:IsA("Model") then
										addTagToModel(child)
									end
								end)
								table.insert(self.modelConns, childConn)
							end
							break
						end
						current = current.Parent
					end
				end
			elseif self.matchMode == "pathFuzzy" then
				if descendant:IsA("Model") and findDeepestMatchLevel(getFullPath(descendant), self.modelName) > 0 then
					addTagToModel(descendant)
					local childConn = descendant.DescendantAdded:Connect(function(child)
						if child:IsA("Model") then
							addTagToModel(child)
						end
					end)
					table.insert(self.modelConns, childConn)
				end
			else
				-- only/fuzzy 模式
				local current = descendant
				while current do
					if current:IsA("Model") and isMatch(current) then
						addTagToModel(current)
						local childConn = current.DescendantAdded:Connect(function(child)
							if child:IsA("Model") then
								addTagToModel(child)
							end
						end)
						table.insert(self.modelConns, childConn)
						break
					end
					current = current.Parent
				end
			end
		end)

		-- 距离更新
		if self.showDistance then
			local heartbeatConn = RunService.Heartbeat:Connect(function()
				self:_updateDistances()
			end)
			table.insert(self.connections, heartbeatConn)
		end
	end

	-- 公共方法：禁用
	self.disable = function()
		if not self.enabled then return end
		self.enabled = false

		for _, conn in ipairs(self.connections) do
			conn:Disconnect()
		end
		self.connections = {}

		if self.scanConnection then
			self.scanConnection:Disconnect()
			self.scanConnection = nil
		end
		if self.descendantConnection then
			self.descendantConnection:Disconnect()
			self.descendantConnection = nil
		end
		for _, conn in pairs(self.modelConns) do
			conn:Disconnect()
		end
		self.modelConns = {}

		if self.isApplying then
			self.currentApplyTaskId = getNewTaskId()
			self.isApplying = false
		end

		removeAllTags()
	end

	-- 公共方法：销毁
	self.destroy = function()
		self:disable()

		for i, inst in ipairs(instances) do
			if inst == self then
				table.remove(instances, i)
				break
			end
		end

		setmetatable(self, nil)
	end

	-- 内部方法：更新距离显示
	self._updateDistances = function()
		if not self.enabled or not self.showDistance then return end

		local character = LocalPlayer and LocalPlayer.Character
		local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
		if not rootPart then return end

		for model, tag in pairs(self.activeTags) do
			if not model or not model.Parent then
				removeTagFromModel(model)
				continue
			end

			local adornee = tag.billboard.Adornee
			if adornee and adornee.Parent then
				local dist = (adornee.Position - rootPart.Position).Magnitude
				local baseText = self.customText or model.Name
				tag.label.Text = string.format("%s (%.1f)", baseText, dist)
			end
		end
	end

	table.insert(instances, self)
	return self
end

-- 对外接口
NameTagModule.new = createNameTagInstance

-- 全局卸载所有实例
NameTagModule.unload = function()
	for i = #instances, 1, -1 do
		local inst = instances[i]
		if inst and inst.destroy then
			inst:destroy()
		end
	end
	instances = {}
end

return NameTagModule