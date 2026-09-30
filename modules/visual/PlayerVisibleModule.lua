--!native
--!optimize 2

local Module = {}

local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local Workspace = cloneref(game:GetService("Workspace"))
local Lighting = cloneref(game:GetService("Lighting"))

local player = Players.LocalPlayer

-- 状态机
local S = {
    isInvis = false,
    isRunning = false,
    character = nil,           -- 真身
    invisibleCharacter = nil,  -- 假身（仅本地）
    invisFix = nil,            -- Stepped 防虚空连接
    invisDied = nil,           -- 假身 Died 连接
    origDied = nil,            -- 真身 Died 连接（恢复可见时用）
    charAddedConn = nil,
    savedCFrame = nil,
}

local function disconnectConn(conn)
    if conn then
        pcall(function() conn:Disconnect() end)
    end
    return nil
end

local function getRoot(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(char)
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function fixCamera(fakeChar)
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local fakeHum = getHumanoid(fakeChar)
    pcall(function()
        cam.CameraSubject = fakeHum or fakeChar:FindFirstChild("HumanoidRootPart") or fakeChar:FindFirstChildWhichIsA("BasePart")
        cam.CameraType = Enum.CameraType.Custom
    end)
end

local function refreshAnimate(char)
    -- 翻转 Animate.Disabled 一次以恢复动画（IY 常用技巧）
    local animate = char and char:FindFirstChildOfClass("LocalScript", true)
    -- 更稳妥：按名查找 Animate
    local anim = char and char:FindFirstChild("Animate")
    if anim and anim:IsA("LocalScript") then
        anim.Disabled = true
        task.wait()
        anim.Disabled = false
    end
end

-- 掉虚空 / 死亡时重建：销毁假身，把真身放回 workspace 重生点逻辑
function respawnState()
    -- 仅内部使用：清理假身，恢复真身可见性状态机为未隐身
    disconnectConn(S.invisFix); S.invisFix = nil
    disconnectConn(S.invisDied); S.invisDied = nil
    local fake = S.invisibleCharacter
    local real = S.character
    S.invisibleCharacter = nil
    S.isInvis = false
    S.isRunning = false
    if fake and fake.Parent then
        pcall(function() fake:Destroy() end)
    end
    if real then
        pcall(function()
            real.Parent = Workspace
            player.Character = real
            fixCamera(real)
            refreshAnimate(real)
        end)
        -- 重新绑定真身死亡事件（下次 enable 时会重绑，这里先清）
        disconnectConn(S.origDied); S.origDied = nil
        local hum = getHumanoid(real)
        if hum then
            S.origDied = hum.Died:Connect(function()
                -- 真身死亡后状态机已复位，无需额外处理
            end)
        end
    end
end

local function bindVoidCheck(fakeChar)
    disconnectConn(S.invisFix)
    local root = getRoot(fakeChar)
    if not root then return end
    S.invisFix = RunService.Stepped:Connect(function()
        if not S.isInvis then return end
        local r = getRoot(S.invisibleCharacter)
        if not r or not r.Parent then return end
        local ok, y = pcall(function() return r.Position.Y end)
        if not ok then return end
        local fallHeight = Workspace.FallenPartsDestroyHeight
        -- 正负两种虚空都处理
        if y < fallHeight or y > math.abs(fallHeight) + 100000 then
            respawnState()
        end
    end)
end

function Module.enable()
    if S.isInvis or S.isRunning then return end
    S.isRunning = true

    local Character = player.Character
    local Humanoid = getHumanoid(Character)
    local Root = getRoot(Character)
    if not (Character and Humanoid and Root) then
        S.isRunning = false
        return
    end

    -- 下装所有手持工具到背包，避免隐身期间工具丢失在假身上
    pcall(function()
        local backpack = player:FindFirstChildOfClass("Backpack")
        for _, tool in ipairs(Character:GetChildren()) do
            if tool:IsA("Tool") and backpack then
                tool.Parent = backpack
            end
        end
    end)

    S.character = Character
    S.savedCFrame = Root.CFrame

    -- 真身允许克隆
    pcall(function() Character.Archivable = true end)

    local InvisibleCharacter = Character:Clone()
    -- 先藏到 Lighting，避免克隆瞬间被其他客户端采样
    InvisibleCharacter.Parent = Lighting

    -- 假身半透明提示本地已隐身：HRP 全透明，其他 0.5
    for _, v in ipairs(InvisibleCharacter:GetDescendants()) do
        if v:IsA("BasePart") then
            if v.Name == "HumanoidRootPart" then
                v.Transparency = 1
            else
                -- 只动不透明部件，避免破坏原本就半透明的饰品
                if v.Transparency == 0 then
                    v.Transparency = 0.5
                end
            end
            v.Anchored = false
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 0.5
        end
    end

    local CF_1 = Root.CFrame

    -- 真身丢到无穷远，避开常规虚空高度
    pcall(function()
        Character:MoveTo(Vector3.new(0, math.pi * 1000000, 0))
    end)

    -- 相机重建：切 Scriptable 再切回 Custom，断开旧 Subject 绑定
    local cam = Workspace.CurrentCamera
    if cam then
        pcall(function() cam.CameraType = Enum.CameraType.Scriptable end)
    end
    task.wait(0.2)
    if cam then
        pcall(function() cam.CameraType = Enum.CameraType.Custom end)
    end

    -- 真身藏 Lighting，假身上场
    pcall(function() Character.Parent = Lighting end)
    InvisibleCharacter.Parent = Workspace
    -- 假身放到原位置
    local fakeRoot = getRoot(InvisibleCharacter)
    local fakeHum = getHumanoid(InvisibleCharacter)
    if fakeRoot then
        pcall(function() fakeRoot.CFrame = CF_1 end)
    end
    -- 切换本地 Character 指向假身
    player.Character = InvisibleCharacter
    S.invisibleCharacter = InvisibleCharacter
    fixCamera(InvisibleCharacter)
    refreshAnimate(InvisibleCharacter)

    -- 假身死亡 -> 走 respawnState（避免顶着假身尸体）
    if fakeHum then
        S.invisDied = fakeHum.Died:Connect(function()
            respawnState()
        end)
    end

    bindVoidCheck(InvisibleCharacter)

    S.isInvis = true
    S.isRunning = false
end

local function TurnVisible()
    if not S.isInvis then return end
    local fake = S.invisibleCharacter
    local real = S.character
    local fakeCF = nil
    if fake then
        local r = getRoot(fake)
        if r then
            pcall(function() fakeCF = r.CFrame end)
        end
    end

    disconnectConn(S.invisFix); S.invisFix = nil
    disconnectConn(S.invisDied); S.invisDied = nil

    if real and fakeCF then
        local realRoot = getRoot(real)
        if realRoot then
            pcall(function() realRoot.CFrame = fakeCF end)
        end
    end
    if fake and fake.Parent then
        pcall(function() fake:Destroy() end)
    end
    S.invisibleCharacter = nil

    if real then
        pcall(function()
            real.Parent = Workspace
            player.Character = real
        end)
        fixCamera(real)
        refreshAnimate(real)
        -- 真身恢复后重绑 Died（供下次使用）
        disconnectConn(S.origDied); S.origDied = nil
        local hum = getHumanoid(real)
        if hum then
            S.origDied = hum.Died:Connect(function() end)
        end
    end

    S.character = nil
    S.isInvis = false
    S.isRunning = false
end

function Module.disable()
    TurnVisible()
end

-- 重生后若仍处于隐身态：复位状态机（真身已换新角色，旧假身作废）
local function onCharacterAdded(newChar)
    if S.isInvis then
        disconnectConn(S.invisFix); S.invisFix = nil
        disconnectConn(S.invisDied); S.invisDied = nil
        local fake = S.invisibleCharacter
        S.invisibleCharacter = nil
        if fake and fake.Parent then
            pcall(function() fake:Destroy() end)
        end
        S.character = newChar
        S.isInvis = false
        S.isRunning = false
    else
        S.character = newChar
    end
    -- 重绑真身死亡（空实现，仅占位避免泄漏叠加）
    disconnectConn(S.origDied); S.origDied = nil
    local hum = newChar and newChar:WaitForChild("Humanoid", 5)
    if hum and hum:IsA("Humanoid") then
        S.origDied = hum.Died:Connect(function() end)
    end
end

if not S.charAddedConn then
    S.charAddedConn = player.CharacterAdded:Connect(onCharacterAdded)
end

function Module.unload()
    disconnectConn(S.charAddedConn); S.charAddedConn = nil
    -- 若卸载时仍隐身，先恢复可见再清理
    if S.isInvis then
        TurnVisible()
    end
    disconnectConn(S.invisFix); S.invisFix = nil
    disconnectConn(S.invisDied); S.invisDied = nil
    disconnectConn(S.origDied); S.origDied = nil
    S.character = nil
    S.invisibleCharacter = nil
    S.isInvis = false
    S.isRunning = false
    player = nil
end

return Module
