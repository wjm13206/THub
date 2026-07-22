-- LocalScript: 礼物“闪现”到玩家脚下，0.5秒后自动归位

local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local Workspace = cloneref(game:GetService("Workspace"))

local player = Players.LocalPlayer

-- ==============================
-- 🔁 核心函数：闪现并还原礼物
-- ==============================
local function FlashPresentsToPlayer(duration)
	duration = duration or 0.5 -- 默认 0.5 秒

	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		warn("[FlashPresents] 未找到 HumanoidRootPart")
		return false
	end

	-- 查找主模型
	local mainModel = Workspace:FindFirstChild("XMas_PresentHunt%") 
		or Workspace:FindFirstChild("XMas_PresentHunt")
	if not mainModel then
		warn("[FlashPresents] 未找到 'XMas_PresentHunt%' 模型")
		return false
	end

	local presentsFolder = mainModel:FindFirstChild("Presents")
	if not presentsFolder then
		warn("[FlashPresents] 未找到 'Presents' 文件夹")
		return false
	end

	-- 收集礼物并保存原始位置
	local giftsData = {} -- { gift = Model, originalCFrame = CFrame }
	for i = 1, 100 do
		local gift = presentsFolder:FindFirstChild(tostring(i))
		if gift and gift:IsA("Model") then
			-- 获取当前完整位姿（使用 GetPivot）
			local originalCFrame = gift:GetPivot()
			table.insert(giftsData, {
				gift = gift,
				originalCFrame = originalCFrame
			})
		end
	end

	if #giftsData == 0 then
		warn("[FlashPresents] 未找到任何可移动的礼物")
		return false
	end

	-- === 第一步：全部传送到玩家脚下 ===
	local targetPos = rootPart.Position + Vector3.new(0, 2, 0)
	local flashCFrame = CFrame.new(targetPos)

	for _, data in ipairs(giftsData) do
		data.gift:PivotTo(flashCFrame)
	end


	-- === 第二步：等待指定时间 ===
	task.wait(duration)

	-- === 第三步：全部还原原位 ===
	for _, data in ipairs(giftsData) do
		if data.gift and data.gift.Parent then -- 确保还存在
			data.gift:PivotTo(data.originalCFrame)
		end
	end

	return true
end

-- ==============================
-- 💡 使用方式：
-- 在 Command Bar 中运行：
--    FlashPresentsToPlayer()        -- 默认 0.5 秒
--    FlashPresentsToPlayer(1)       -- 停留 1 秒
-- ==============================

FlashPresentsToPlayer()