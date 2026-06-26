local TeleportModule = {}

local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local Workspace = cloneref(game:GetService("Workspace"))

-- 内部函数：检查角色是否有效
local function isValidCharacter(player)
    local character = player.Character
    if not character then
        return false, nil, nil
    end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not hrp or not humanoid or humanoid.Health <= 0 then
        return false, nil, nil
    end
    return true, hrp, character
end

-- 内部函数：收集目标零件
local function collectTargets(partNames)
    local targets = {}
    -- 将输入统一转为字符串数组
    local nameList = {}
    if type(partNames) == "string" then
        nameList = {partNames}
    elseif type(partNames) == "table" then
        nameList = partNames
    else
        return targets
    end
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            for _, targetName in ipairs(nameList) do
                if obj.Name == targetName then
                    table.insert(targets, obj)
                    break
                end
            end
        end
    end
    return targets
end

-- 内部函数：按距离从近到远排序
local function sortByDistance(hrp, targets)
    local playerPos = hrp.Position
    table.sort(targets, function(a, b)
        local distA = (a.Position - playerPos).Magnitude
        local distB = (b.Position - playerPos).Magnitude
        return distA < distB
    end)
end

-- 主函数：传送到所有匹配的零件（从近到远）
-- 参数 partNames: 字符串或字符串数组，如 "Echo" 或 {"AbyssalEnergy", "BigAbyssalEnergy"}
-- 参数 delay: 每次传送后的等待时间（秒），默认 0.1
function TeleportModule.TeleportToParts(partNames, delay)
    delay = delay or 0.1
    local player = Players.LocalPlayer
    
    -- 验证角色
    local valid, hrp = isValidCharacter(player)
    if not valid then
        return
    end
    
    -- 收集目标
    local targets = collectTargets(partNames)
    if #targets == 0 then
        return
    end
    
    -- 按距离从近到远排序
    sortByDistance(hrp, targets)
    
    for i, part in ipairs(targets) do
        -- 每次传送前重新验证角色
        local validNow, currentHrp = isValidCharacter(player)
        if not validNow then
            break
        end
        hrp = currentHrp
        
        local targetPos = part.Position + Vector3.new(0, 2, 0)
        hrp.CFrame = CFrame.new(targetPos)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        
        task.wait(delay)
    end
end

return TeleportModule