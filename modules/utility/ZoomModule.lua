-- ZoomModule.lua
-- 摄像机缩放模块，每次触发时重置缩放倍率，不保存手动调整的值

local ZoomModule = {}
ZoomModule.__index = ZoomModule

-- 依赖服务
local cloneref = cloneref or clonereference or function(obj) return obj end
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local Workspace = cloneref(game:GetService("Workspace"))

-- 构造函数
function ZoomModule.new()
    local self = setmetatable({}, ZoomModule)
    
    -- 配置参数
    self.config = {
        -- 按键绑定，默认为C键
        bindKey = Enum.KeyCode.C,
        -- 缩放过渡动画时间（秒）
        tweenTime = 0.15,
        -- 缩放调整步长（每次按 +/- 键改变的视野值）
        zoomStep = 5,
        -- 最小缩放视野（数值越小放大倍数越大）
        minZoomFOV = 5,               -- 修改为5
        -- 默认缩放视野（每次按下缩放键时的初始视野）
        defaultZoomFOV = 30,
    }
    
    -- 状态变量
    self.isEnabled = false
    self.isZooming = false
    self.normalFOV = 70              -- 正常视野，会在启用时从相机获取
    self.currentZoomFOV = self.config.defaultZoomFOV  -- 当前缩放时的视野
    
    -- 连接对象
    self.connections = {
        inputBegan = nil,
        inputEnded = nil,
    }
    
    self.camera = Workspace.CurrentCamera
    return self
end

-- 获取当前正常视野
function ZoomModule:GetNormalFOV()
    return self.normalFOV
end

-- 设置正常视野（谨慎使用）
function ZoomModule:SetNormalFOV(fov)
    self.normalFOV = fov
    if not self.isZooming and self.isEnabled then
        self.camera.FieldOfView = self.normalFOV
    end
end

-- 更新相机的视野（带动画）
function ZoomModule:UpdateCameraFOV(targetFOV)
    local tween = TweenService:Create(self.camera, TweenInfo.new(self.config.tweenTime), {FieldOfView = targetFOV})
    tween:Play()
end

-- 调整缩放程度（delta: +1 增加视野/缩小，-1 减小视野/放大）
function ZoomModule:AdjustZoom(delta)
    if not self.isZooming or not self.isEnabled then return end
    
    local step = delta * self.config.zoomStep
    local newZoomFOV = self.currentZoomFOV + step
    newZoomFOV = math.clamp(newZoomFOV, self.config.minZoomFOV, self.normalFOV)
    
    if newZoomFOV == self.currentZoomFOV then return end
    
    self.currentZoomFOV = newZoomFOV
    self:UpdateCameraFOV(self.currentZoomFOV)
end

-- 开始缩放（按下按键时触发）
function ZoomModule:StartZoom()
    if not self.isEnabled then return end
    
    self.isZooming = true
    -- 每次缩放都重置为默认缩放视野，不保存上次调整的值
    self.currentZoomFOV = self.config.defaultZoomFOV
    self:UpdateCameraFOV(self.currentZoomFOV)
end

-- 结束缩放（松开按键时触发）
function ZoomModule:StopZoom()
    if not self.isEnabled then return end
    
    self.isZooming = false
    self:UpdateCameraFOV(self.normalFOV)
end

-- 设置绑定的按键
function ZoomModule:SetBindKey(keyType)
    self.config.bindKey = keyType
end

-- 获取当前绑定的按键
function ZoomModule:GetBindKey()
    return self.config.bindKey
end

-- 设置最小缩放视野
function ZoomModule:SetMinZoomFOV(minFOV)
    self.config.minZoomFOV = minFOV
    -- 如果当前缩放视野小于新的最小值，进行调整（仅在缩放状态下）
    if self.isZooming and self.currentZoomFOV < minFOV then
        self.currentZoomFOV = minFOV
        self:UpdateCameraFOV(self.currentZoomFOV)
    end
end

-- 获取最小缩放视野
function ZoomModule:GetMinZoomFOV()
    return self.config.minZoomFOV
end

-- 设置默认缩放视野（每次按下时的初始值）
function ZoomModule:SetDefaultZoomFOV(defaultFOV)
    self.config.defaultZoomFOV = math.clamp(defaultFOV, self.config.minZoomFOV, self.normalFOV)
end

-- 获取默认缩放视野
function ZoomModule:GetDefaultZoomFOV()
    return self.config.defaultZoomFOV
end

-- 设置缩放调整步长
function ZoomModule:SetZoomStep(step)
    self.config.zoomStep = step
end

-- 获取缩放调整步长
function ZoomModule:GetZoomStep()
    return self.config.zoomStep
end

-- 设置动画时间
function ZoomModule:SetTweenTime(time)
    self.config.tweenTime = time
end

-- 获取动画时间
function ZoomModule:GetTweenTime()
    return self.config.tweenTime
end

-- 检查输入是否匹配绑定的按键
function ZoomModule:IsMatchingInput(input)
    return input.UserInputType == self.config.bindKey or input.KeyCode == self.config.bindKey
end

-- 启用模块
function ZoomModule:enable()
    if self.isEnabled then return end
    
    -- 获取当前玩家的正常视野
    self.normalFOV = self.camera.FieldOfView
    
    -- 确保默认缩放视野在有效范围内
    self.config.defaultZoomFOV = math.clamp(self.config.defaultZoomFOV, self.config.minZoomFOV, self.normalFOV)
    self.currentZoomFOV = self.config.defaultZoomFOV
    
    -- 连接输入事件
    self.connections.inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- 处理缩放按键开始
        if self:IsMatchingInput(input) then
            self:StartZoom()
        end
        
        -- 处理 +/- 调整缩放（仅在缩放状态下）
        if self.isZooming then
            if input.KeyCode == Enum.KeyCode.Minus then
                self:AdjustZoom(-1)   -- 放大（减小视野）
                input:Processed()
            elseif input.KeyCode == Enum.KeyCode.Equals then
                self:AdjustZoom(1)    -- 缩小（增大视野）
                input:Processed()
            end
        end
    end)
    
    self.connections.inputEnded = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- 处理缩放按键结束
        if self:IsMatchingInput(input) then
            self:StopZoom()
        end
    end)
    
    self.isEnabled = true
end

-- 禁用模块
function ZoomModule:disable()
    if not self.isEnabled then return end
    
    if self.isZooming then
        self:StopZoom()
        self.isZooming = false
    end
    
    -- 断开所有连接
    if self.connections.inputBegan then
        self.connections.inputBegan:Disconnect()
        self.connections.inputBegan = nil
    end
    
    if self.connections.inputEnded then
        self.connections.inputEnded:Disconnect()
        self.connections.inputEnded = nil
    end
    
    self.isEnabled = false
end

-- 卸载模块
function ZoomModule:unload()
    self:disable()
    self.camera = nil
    self.config = nil
    self.connections = nil
    self.isEnabled = nil
    self.isZooming = nil
    self.normalFOV = nil
    self.currentZoomFOV = nil
end

return ZoomModule