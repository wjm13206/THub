-- LocalPlayerLightAttachmentFixed.lua
-- 最终版：保留.new/:unload命名 + 彻底解决布尔索引错误 + 智能适配身体部位
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))

local LocalPlayerLight = {}
LocalPlayerLight.__index = LocalPlayerLight

-- 全局存储所有实例（用于批量卸载）
LocalPlayerLight._allInstances = {}

-- 默认配置
local DEFAULT_CONFIG = {
    Enabled = false,
    Brightness = 2,
    Range = 10,
    Color = Color3.fromRGB(255, 255, 255),
    Shadows = false,
    Attachment_Name = "PlayerLightAttachment",
    Offset_Position = Vector3.new(0, 1.5, 0),
    Offset_Rotation = Vector3.new(0, 0, 0),
    AttachToBodyPart = "UpperTorso",
}

-- 生成唯一名称
local function getUniqueAttachmentName(baseName)
    local suffix = 1
    local newName = baseName
    local char = Players.LocalPlayer and Players.LocalPlayer.Character
    if char then
        -- 智能查找身体部位（兼容 R6/R15）
        local bodyPart = char:FindFirstChild("UpperTorso") 
            or char:FindFirstChild("Torso")
            or char:FindFirstChild("HumanoidRootPart")
        if bodyPart then
            while bodyPart:FindFirstChild(newName) do
                newName = baseName .. "_" .. suffix
                suffix += 1
            end
        end
    end
    return newName
end

-- 智能查找身体部位（兼容 R6/R15/自定义角色）
-- 修改返回值：返回身体部位 和 部位名称
local function findValidBodyPart(character, preferredPart)
    -- 优先查找指定部位
    local part = character:FindFirstChild(preferredPart)
    if part and part:IsA("BasePart") then
        return part, preferredPart  -- 返回部位和名称
    end
    
    -- R6/R15 兼容查找
    local alternativeParts = {
        "UpperTorso",       -- R15
        "Torso",            -- R6
        "HumanoidRootPart", -- 最后的备选
    }
    
    for _, name in ipairs(alternativeParts) do
        if name ~= preferredPart then  -- 避免重复查找
            part = character:FindFirstChild(name)
            if part and part:IsA("BasePart") then
                return part, name  -- 返回部位和名称
            end
        end
    end
    
    -- warn("找不到任何有效的身体部位来挂载光源")
    return nil, nil
end

-- 安全创建光源
local function attachLightToCharacter(self)
    self:cleanupLight()

    if not self.localPlayer or not self.localPlayer.Character then return end
    
    local character = self.localPlayer.Character
    
    -- 智能查找身体部位
    local bodyPart, usedPartName = findValidBodyPart(character, self.config.AttachToBodyPart)
    
    if not bodyPart then
        warn("在角色 " .. character.Name .. " 上找不到挂载光源的身体部位")
        return
    end

    -- 创建Attachment
    local attachment = Instance.new("Attachment")
    attachment.Name = getUniqueAttachmentName(self.config.Attachment_Name)
    attachment.CFrame = CFrame.new(self.config.Offset_Position) 
        * CFrame.Angles(
            math.rad(self.config.Offset_Rotation.X),
            math.rad(self.config.Offset_Rotation.Y),
            math.rad(self.config.Offset_Rotation.Z)
        )
    attachment.Parent = bodyPart

    -- 创建PointLight
    local pointLight = Instance.new("PointLight")
    pointLight.Enabled = self._enableCache
    pointLight.Brightness = self.config.Brightness
    pointLight.Range = self.config.Range
    pointLight.Color = self.config.Color
    
    -- ===== 在这里根据部位名称决定 Shadows =====
    if usedPartName == "Torso" then
        -- R6角色：关闭阴影，防止饰品遮挡
        pointLight.Shadows = false
    else
        -- R15或其他：使用配置中的设置
        pointLight.Shadows = self.config.Shadows
    end
    
    pointLight.Parent = attachment

    -- 保存数据
    self.lightData = {
        Attachment = attachment,
        PointLight = pointLight,
    }
    self._isLightCreated = true
end

-- 构造函数
function LocalPlayerLight.new(customConfig)
    local self = setmetatable({}, LocalPlayerLight)

    -- 初始化所有状态
    self.config = table.clone(DEFAULT_CONFIG)
    self.localPlayer = Players.LocalPlayer
    self.lightData = nil
    self.characterAddedConnection = nil
    self.isLoaded = true
    self._enableCache = false
    self._isLightCreated = false

    -- 合并用户配置
    if type(customConfig) == "table" then
        for k, v in pairs(customConfig) do
            if self.config[k] ~= nil then
                self.config[k] = v
            end
        end
    end

    -- 初始化缓存
    self._enableCache = self.config.Enabled

    -- 安全检查：本地玩家不存在
    if not self.localPlayer then
        warn("无法获取本地玩家，光源创建失败")
        self.isLoaded = false
        table.insert(LocalPlayerLight._allInstances, self)
        return self
    end

    -- 异步初始化光源
    task.spawn(function()
        local character = self.localPlayer.Character or self.localPlayer.CharacterAdded:Wait()
        if not character then return end
        
        -- 等待身体部位加载（最多等待10秒）
        local bodyPartName = self.config.AttachToBodyPart
        local waited = 0
        while waited < 10 do
            local bodyPart = findValidBodyPart(character, bodyPartName)
            if bodyPart then
                break
            end
            task.wait(0.5)
            waited = waited + 0.5
        end
        
        attachLightToCharacter(self)
    end)

    -- 监听角色重生
    self.characterAddedConnection = self.localPlayer.CharacterAdded:Connect(function(newCharacter)
        -- 等待新角色加载身体部位
        local bodyPartName = self.config.AttachToBodyPart
        local waited = 0
        while waited < 10 do
            task.wait(0.5)
            local bodyPart = findValidBodyPart(newCharacter, bodyPartName)
            if bodyPart then
                break
            end
            waited = waited + 0.5
        end
        
        attachLightToCharacter(self)
        -- 重生后恢复缓存的enable状态
        if self._isLightCreated and self.lightData and self.lightData.PointLight then
            self.lightData.PointLight.Enabled = self._enableCache
        end
    end)

    -- 加入全局列表
    table.insert(LocalPlayerLight._allInstances, self)
    return self
end

-- 内部清理方法
function LocalPlayerLight:cleanupLight()
    pcall(function() if self.lightData and self.lightData.PointLight then self.lightData.PointLight:Destroy() end end)
    pcall(function() if self.lightData and self.lightData.Attachment then self.lightData.Attachment:Destroy() end end)
    self.lightData = nil
    self._isLightCreated = false
end

-- 安全的元表逻辑
function LocalPlayerLight:__index(key)
    if key == "enable" then
        return self._enableCache
    end

    local value = LocalPlayerLight[key]
    if value then
        return value
    else
        return nil
    end
end

function LocalPlayerLight:__newindex(key, value)
    if key == "enable" then
        local boolValue = not not value
        self._enableCache = boolValue

        if not self.isLoaded then
            warn("光源实例已卸载，无法修改enable")
            return
        end

        if self._isLightCreated and self.lightData and self.lightData.PointLight then
            pcall(function()
                self.lightData.PointLight.Enabled = boolValue
            end)
        end
    else
        rawset(self, key, value)
    end
end

-- 实例卸载
function LocalPlayerLight:unload()
    if not self.isLoaded then
        return
    end

    -- 清理光源
    self:cleanupLight()

    -- 断开事件
    pcall(function() if self.characterAddedConnection then self.characterAddedConnection:Disconnect() end end)
    self.characterAddedConnection = nil

    -- 标记卸载
    self.isLoaded = false
    self._enableCache = false

    -- 从全局列表移除
    for i, inst in ipairs(LocalPlayerLight._allInstances) do
        if inst == self then
            table.remove(LocalPlayerLight._allInstances, i)
            break
        end
    end
end

-- 模块级卸载
function LocalPlayerLight:unloadAll()
    for i = #LocalPlayerLight._allInstances, 1, -1 do
        local inst = LocalPlayerLight._allInstances[i]
        if inst.isLoaded then
            inst:unload()
        end
    end
    LocalPlayerLight._allInstances = {}
end

return LocalPlayerLight