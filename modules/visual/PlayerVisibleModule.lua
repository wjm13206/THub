-- 感谢K6提供的源码

local Module = {}

local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))

local player = Players.LocalPlayer
local character = nil
local humanoid = nil
local rootPart = nil
local parts = {}
local enabled = false
local connections = {}
local heartbeatConnection = nil

local function updateParts()
    if not player then
        repeat task.wait() until Players.LocalPlayer
        player = Players.LocalPlayer
    end

    character = player.Character or player.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")

    parts = {}
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Transparency == 0 then
            table.insert(parts, descendant)
        end
    end
end

local function setPartsTransparency(transparency)
    for _, part in ipairs(parts) do
        part.Transparency = transparency
    end
end

local function onHeartbeat()
    if not enabled then return end

    if not (rootPart and humanoid) then
        if player.Character then
            character = player.Character
            humanoid = character:FindFirstChild("Humanoid")
            rootPart = character:FindFirstChild("HumanoidRootPart")
        end
        if not (rootPart and humanoid) then
            return
        end
    end

    local originalCFrame = rootPart.CFrame
    local originalCameraOffset = humanoid.CameraOffset

    local downCFrame = originalCFrame * CFrame.new(0, 200000, 0)
    rootPart.CFrame = downCFrame

    local cameraOffsetGoal = downCFrame:ToObjectSpace(CFrame.new(originalCFrame.Position)).Position
    humanoid.CameraOffset = cameraOffsetGoal

    RunService.RenderStepped:Wait()

    rootPart.CFrame = originalCFrame
    humanoid.CameraOffset = originalCameraOffset
end

local function onCharacterAdded(char)
    character = char
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    updateParts()
    if enabled then
        setPartsTransparency(0.5)
    end
end

local function initialize()
    repeat task.wait() until Players.LocalPlayer
    player = Players.LocalPlayer

    if player.Character then
        onCharacterAdded(player.Character)
    end

    local charAddedConn = player.CharacterAdded:Connect(onCharacterAdded)
    table.insert(connections, charAddedConn)
end

initialize()

function Module.enable()
    if enabled then return end
    enabled = true

    updateParts()

    setPartsTransparency(0.5)

    if not heartbeatConnection then
        heartbeatConnection = RunService.Heartbeat:Connect(onHeartbeat)
        table.insert(connections, heartbeatConnection)
    end
end

function Module.disable()
    if not enabled then return end
    enabled = false

    setPartsTransparency(0)

    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
end

function Module.unload()
    Module.disable()

    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
    connections = {}

    parts = {}
    character = nil
    humanoid = nil
    rootPart = nil
    player = nil
    enabled = false
end

return Module