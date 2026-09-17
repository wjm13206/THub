--!native
--!optimize 2
-- TPJump 模块
local TPJump = {}

-- 私有变量
local cloneref = cloneref or clonereference or function(obj) return obj end
local Services = setmetatable({}, { __index = function(self, name) local success, cache = pcall(function() return cloneref(game:GetService(name)) end); if success then rawset(self, name, cache); return cache else error("无效服务: "..tostring(name)) end end})
local RunService = Services.RunService
local Players = Services.Players
local UserInputService = Services.UserInputService

local _enabled = false
local _boostPower = 40 -- 跳跃爆发增量 (单位: studs/s)
local _jumpConnection = nil
local _player = Players.LocalPlayer

-- 内部跳跃处理函数
local function onJumpRequest()
    if not _enabled then return end
    
    local character = _player.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    
    if not (character and humanoid and humanoid.Parent) then
        return
    end
    
    -- 仅在角色在地面或刚起跳时生效，防止空中连续触发
    local state = humanoid:GetState()
    if state == Enum.HumanoidStateType.Jumping then
        
        -- 直接给 RootPart 一个向上的速度脉冲
        -- 这会叠加在引擎原有 JumpPower 之上，形成更高的抛物线起点
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity 
                + Vector3.new(0, _boostPower, 0)
        end
    end
end

-- 内部启动连接
local function start()
    if _jumpConnection then return end
    _jumpConnection = UserInputService.JumpRequest:Connect(onJumpRequest)
end

-- 内部停止连接
local function stop()
    if _jumpConnection then
        _jumpConnection:Disconnect()
        _jumpConnection = nil
    end
end

-- 公开方法
function TPJump:Enabled(state)
    if state == nil then
        return _enabled
    end
    _enabled = state
    if _enabled then
        start()
    else
        stop()
    end
end

function TPJump:GetBoostPower()
    return _boostPower
end

function TPJump:SetBoostPower(num)
    if type(num) == "number" and num >= 0 then
        _boostPower = num
    end
end

function TPJump:unload()
    stop()
    _enabled = false
    _boostPower = 40
end

return TPJump