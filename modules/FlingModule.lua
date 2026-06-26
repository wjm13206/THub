-- Fling Module for Infinite Yield
-- Provides fling, flyfling, walkfling, and invisfling functionality
-- Usage:
--   local flingModule = loadstring(game:HttpGet("raw_url_here"))()
--   flingModule.fling.enable()
--   flingModule.fling.disable()
--   flingModule.flyfling.enable(50) -- optional speed parameter
--   flingModule.flyfling.disable()
--   flingModule.walkfling.enable()
--   flingModule.walkfling.disable()
--   flingModule.invisfling.enable()
--   flingModule.invisfling.disable()
--   flingModule.unload() -- unload everything

local FlingModule = {}

-- Services
local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local Workspace = cloneref(game:GetService("Workspace"))
local Lighting = cloneref(game:GetService("Lighting"))

local LocalPlayer = Players.LocalPlayer
local function getRoot(char)
    if char and char:FindFirstChildOfClass("Humanoid") then
        return char:FindFirstChildOfClass("Humanoid").RootPart
    end
    return nil
end

local function breakVelocity()
    local V3 = Vector3.new(0, 0, 0)
    for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Velocity, v.RotVelocity = V3, V3
        end
    end
end

-- ============= FLING =============
local flingActive = false
local flingBodyVelocity = nil
local flingDiedConnection = nil
local flingLoopConnection = nil
local flingShortcutEnabled = false
local flingKeybind = Enum.KeyCode.G
local flingHotkeyConnection = nil

local function stopFling()
    if flingDiedConnection then
        flingDiedConnection:Disconnect()
        flingDiedConnection = nil
    end
    if flingLoopConnection then
        flingLoopConnection:Disconnect()
        flingLoopConnection = nil
    end
    if flingBodyVelocity and flingBodyVelocity.Parent then
        flingBodyVelocity:Destroy()
    end
    flingBodyVelocity = nil
    
    -- Restore collision and physical properties
    local char = LocalPlayer.Character
    if char then
        for _, child in pairs(char:GetDescendants()) do
            if child:IsA("BasePart") then
                child.CanCollide = true
                child.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
            end
        end
    end
    
    flingActive = false
end

local function startFling()
    if flingActive then return end
    stopFling()
    
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Set physical properties
    for _, child in pairs(char:GetDescendants()) do
        if child:IsA("BasePart") then
            child.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
        end
    end
    
    -- Noclip
    local function noclipLoop()
        if char and char.Parent then
            for _, child in pairs(char:GetDescendants()) do
                if child:IsA("BasePart") and child.CanCollide == true and child.Name ~= "FloatPart" then
                    child.CanCollide = false
                end
            end
        end
    end
    
    local noclipConnection = RunService.Stepped:Connect(noclipLoop)
    
    -- Create angular velocity for fling
    local root = getRoot(char)
    if not root then return end
    
    flingBodyVelocity = Instance.new("BodyAngularVelocity")
    flingBodyVelocity.Name = "__FlingVelocity"
    flingBodyVelocity.Parent = root
    flingBodyVelocity.AngularVelocity = Vector3.new(0, 99999, 0)
    flingBodyVelocity.MaxTorque = Vector3.new(0, math.huge, 0)
    flingBodyVelocity.P = math.huge
    
    -- Disable collisions on all parts
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
            v.Massless = true
            v.Velocity = Vector3.new(0, 0, 0)
        end
    end
    
    flingActive = true
    
    -- Handle death
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        flingDiedConnection = humanoid.Died:Connect(function()
            stopFling()
        end)
    end
    
    -- Fling loop
    flingLoopConnection = RunService.Heartbeat:Connect(function()
        if flingActive and flingBodyVelocity and flingBodyVelocity.Parent then
            flingBodyVelocity.AngularVelocity = Vector3.new(0, 99999, 0)
            task.wait(0.2)
            if flingBodyVelocity then
                flingBodyVelocity.AngularVelocity = Vector3.new(0, 0, 0)
            end
            task.wait(0.1)
        elseif flingActive then
            stopFling()
        end
    end)
    
    -- Cleanup noclip when fling stops
    task.spawn(function()
        while flingActive do
            task.wait(0.5)
        end
        noclipConnection:Disconnect()
    end)
end

local function toggleFling()
    if flingActive then
        stopFling()
    else
        startFling()
    end
end

local function onFlingHotkeyInput(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == flingKeybind and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        toggleFling()
        return Enum.ContextActionResult.Sink
    end
end

FlingModule.fling = {
    enable = startFling,
    disable = stopFling,
    isEnabled = function() return flingActive end,
    setShortcutEnabled = function(enabled)
        if enabled == flingShortcutEnabled then return end
        if enabled then
            if flingHotkeyConnection then
                flingHotkeyConnection:Disconnect()
            end
            flingHotkeyConnection = UserInputService.InputBegan:Connect(onFlingHotkeyInput)
            flingShortcutEnabled = true
        else
            if flingHotkeyConnection then
                flingHotkeyConnection:Disconnect()
                flingHotkeyConnection = nil
            end
            flingShortcutEnabled = false
        end
    end,
    isShortcutEnabled = function() return flingShortcutEnabled end,
    getKeybind = function() return flingKeybind end
}

-- ============= FLYFLING =============
local flyflingActive = false
local flyflingVehicleFly = nil
local flyflingWalkFling = nil
local flyflingSpeed = 20

local function stopFlyFling()
    if flyflingVehicleFly then
        flyflingVehicleFly.disable()
        flyflingVehicleFly = nil
    end
    if flyflingWalkFling then
        flyflingWalkFling.disable()
        flyflingWalkFling = nil
    end
    breakVelocity()
    flyflingActive = false
end

local function startFlyFling(speed)
    stopFlyFling()
    
    if speed and type(speed) == "number" then
        flyflingSpeed = speed
    end
    
    -- Load and start vehicle fly (using the fly function from original)
    -- Simplified vehicle fly implementation
    local function startVehicleFly()
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        local flyActive = true
        local flyBodyVelocity = nil
        local flyBodyGyro = nil
        local root = getRoot(char)
        
        if root then
            flyBodyGyro = Instance.new("BodyGyro")
            flyBodyGyro.P = 9e4
            flyBodyGyro.Parent = root
            flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            flyBodyGyro.CFrame = Workspace.CurrentCamera.CFrame
            
            flyBodyVelocity = Instance.new("BodyVelocity")
            flyBodyVelocity.Parent = root
            flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        end
        
        humanoid.PlatformStand = true
        
        local keyDownConnection
        local keyUpConnection
        local control = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
        
        keyDownConnection = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            local speedVal = flyflingSpeed
            if input.KeyCode == Enum.KeyCode.W then
                control.F = speedVal
            elseif input.KeyCode == Enum.KeyCode.S then
                control.B = -speedVal
            elseif input.KeyCode == Enum.KeyCode.A then
                control.L = -speedVal
            elseif input.KeyCode == Enum.KeyCode.D then
                control.R = speedVal
            end
        end)
        
        keyUpConnection = UserInputService.InputEnded:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.W then
                control.F = 0
            elseif input.KeyCode == Enum.KeyCode.S then
                control.B = 0
            elseif input.KeyCode == Enum.KeyCode.A then
                control.L = 0
            elseif input.KeyCode == Enum.KeyCode.D then
                control.R = 0
            end
        end)
        
        local renderConnection = RunService.RenderStepped:Connect(function()
            if not flyActive or not char or not char.Parent then
                return
            end
            local camera = Workspace.CurrentCamera
            if flyBodyVelocity then
                local velocity = ((camera.CFrame.LookVector * (control.F + control.B)) + 
                    ((camera.CFrame * CFrame.new(control.L + control.R, (control.F + control.B + control.Q + control.E) * 0.2, 0).p) - camera.CFrame.p)) * 50
                flyBodyVelocity.Velocity = velocity
            end
            if flyBodyGyro then
                flyBodyGyro.CFrame = camera.CFrame
            end
        end)
        
        return {
            disable = function()
                flyActive = false
                if keyDownConnection then keyDownConnection:Disconnect() end
                if keyUpConnection then keyUpConnection:Disconnect() end
                if renderConnection then renderConnection:Disconnect() end
                if flyBodyVelocity then flyBodyVelocity:Destroy() end
                if flyBodyGyro then flyBodyGyro:Destroy() end
                if humanoid then humanoid.PlatformStand = false end
            end
        }
    end
    
    -- Simplified walkfling
    local function startWalkFling()
        local walkActive = true
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        
        if humanoid then
            humanoid.Died:Connect(function()
                if walkActive then
                    stopFlyFling()
                end
            end)
        end
        
        -- Noclip
        for _, child in pairs(char:GetDescendants()) do
            if child:IsA("BasePart") then
                child.CanCollide = false
            end
        end
        
        local walkLoop = RunService.Heartbeat:Connect(function()
            if not walkActive or not char or not char.Parent then
                return
            end
            local root = getRoot(char)
            if root then
                local vel = root.Velocity
                root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
                
                task.wait()
                if root and root.Parent then
                    root.Velocity = vel
                end
                
                task.wait()
                if root and root.Parent then
                    local moveVal = 0.1
                    root.Velocity = vel + Vector3.new(0, moveVal, 0)
                end
            end
        end)
        
        return {
            disable = function()
                walkActive = false
                if walkLoop then walkLoop:Disconnect() end
                -- Restore noclip
                for _, child in pairs(char:GetDescendants()) do
                    if child:IsA("BasePart") then
                        child.CanCollide = true
                    end
                end
            end
        }
    end
    
    flyflingVehicleFly = startVehicleFly()
    flyflingWalkFling = startWalkFling()
    flyflingActive = true
end

FlingModule.flyfling = {
    enable = startFlyFling,
    disable = stopFlyFling,
    isEnabled = function() return flyflingActive end,
    setSpeed = function(speed) flyflingSpeed = speed end
}

-- ============= WALKFLING =============
local walkflingActive = false
local walkflingLoop = nil
local walkflingDiedConn = nil

local function stopWalkFling()
    if walkflingLoop then
        walkflingLoop:Disconnect()
        walkflingLoop = nil
    end
    if walkflingDiedConn then
        walkflingDiedConn:Disconnect()
        walkflingDiedConn = nil
    end
    
    local char = LocalPlayer.Character
    if char then
        for _, child in pairs(char:GetDescendants()) do
            if child:IsA("BasePart") then
                child.CanCollide = true
            end
        end
    end
    
    walkflingActive = false
end

local function startWalkFling()
    if walkflingActive then return end
    stopWalkFling()
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        walkflingDiedConn = humanoid.Died:Connect(function()
            stopWalkFling()
        end)
    end
    
    -- Noclip
    for _, child in pairs(char:GetDescendants()) do
        if child:IsA("BasePart") then
            child.CanCollide = false
        end
    end
    
    walkflingActive = true
    local moveVal = 0.1
    
    walkflingLoop = RunService.Heartbeat:Connect(function()
        if not walkflingActive then return end
        
        char = LocalPlayer.Character
        if not char or not char.Parent then
            stopWalkFling()
            return
        end
        
        local root = getRoot(char)
        if not root then return end
        
        local vel = root.Velocity
        root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
        
        RunService.RenderStepped:Wait()
        if char and char.Parent and root and root.Parent then
            root.Velocity = vel
        end
        
        RunService.Stepped:Wait()
        if char and char.Parent and root and root.Parent then
            root.Velocity = vel + Vector3.new(0, moveVal, 0)
            moveVal = moveVal * -1
        end
    end)
end

FlingModule.walkfling = {
    enable = startWalkFling,
    disable = stopWalkFling,
    isEnabled = function() return walkflingActive end
}

-- ============= INVISFLING =============
local invisflingActive = false
local invisflingCleanup = {}

local function stopInvisFling()
    if not invisflingActive then return end
    
    -- Restore character
    local char = LocalPlayer.Character
    if char and invisflingCleanup.originalChar then
        for _, v in pairs(char:GetChildren()) do
            if v ~= invisflingCleanup.originalRoot and v.Name ~= "Humanoid" then
                v:Destroy()
            end
        end
        
        if invisflingCleanup.originalRoot and invisflingCleanup.originalRoot.Parent then
            invisflingCleanup.originalRoot.Transparency = 0
            invisflingCleanup.originalRoot.Color = Color3.new(1, 1, 1)
        end
    end
    
    if invisflingCleanup.steppedConn then
        invisflingCleanup.steppedConn:Disconnect()
    end
    
    if invisflingCleanup.flyConn then
        invisflingCleanup.flyConn:Disconnect()
    end
    
    if invisflingCleanup.bodyThrust then
        invisflingCleanup.bodyThrust:Destroy()
    end
    
    Workspace.CurrentCamera.CameraSubject = LocalPlayer.Character
    invisflingActive = false
    invisflingCleanup = {}
end

local function startInvisFling()
    if invisflingActive then return end
    stopInvisFling()
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end
    
    -- Create invis model
    local fakeModel = Instance.new("Model")
    fakeModel.Parent = char
    
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.CanCollide = false
    torso.Anchored = true
    
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Parent = fakeModel
    head.Anchored = true
    head.CanCollide = false
    
    local fakeHumanoid = Instance.new("Humanoid")
    fakeHumanoid.Name = "Humanoid"
    fakeHumanoid.Parent = fakeModel
    
    torso.Position = Vector3.new(0, 9999, 0)
    
    -- Swap characters
    local originalRoot = getRoot(char)
    invisflingCleanup.originalRoot = originalRoot
    invisflingCleanup.originalChar = char
    
    LocalPlayer.Character = fakeModel
    task.wait(3)
    LocalPlayer.Character = char
    task.wait(3)
    
    -- Cleanup and setup new humanoid
    local newHumanoid = Instance.new("Humanoid")
    newHumanoid.Parent = char
    
    local root = getRoot(char)
    invisflingCleanup.root = root
    
    for _, v in pairs(char:GetChildren()) do
        if v ~= root and v.Name ~= "Humanoid" then
            v:Destroy()
        end
    end
    
    if root then
        root.Transparency = 0
        root.Color = Color3.new(1, 1, 1)
        root.CanCollide = false
    end
    
    -- Noclip loop
    invisflingCleanup.steppedConn = RunService.Stepped:Connect(function()
        if LocalPlayer.Character and getRoot(LocalPlayer.Character) then
            getRoot(LocalPlayer.Character).CanCollide = false
        end
    end)
    
    -- Fly
    local function startFly()
        local flyChar = LocalPlayer.Character
        local flyHumanoid = flyChar and flyChar:FindFirstChildOfClass("Humanoid")
        if not flyHumanoid then return end
        
        flyHumanoid.PlatformStand = true
        
        local flyRoot = getRoot(flyChar)
        local flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Parent = flyRoot
        flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        
        local flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.Parent = flyRoot
        flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBodyGyro.P = 9e4
        
        local flyControl = {F = 0, B = 0, L = 0, R = 0}
        local flySpeed = 50
        
        local keyDown = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.W then flyControl.F = flySpeed
            elseif input.KeyCode == Enum.KeyCode.S then flyControl.B = -flySpeed
            elseif input.KeyCode == Enum.KeyCode.A then flyControl.L = -flySpeed
            elseif input.KeyCode == Enum.KeyCode.D then flyControl.R = flySpeed
            end
        end)
        
        local keyUp = UserInputService.InputEnded:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.W then flyControl.F = 0
            elseif input.KeyCode == Enum.KeyCode.S then flyControl.B = 0
            elseif input.KeyCode == Enum.KeyCode.A then flyControl.L = 0
            elseif input.KeyCode == Enum.KeyCode.D then flyControl.R = 0
            end
        end)
        
        local renderConn = RunService.RenderStepped:Connect(function()
            if not flyChar or not flyChar.Parent then return end
            local camera = Workspace.CurrentCamera
            flyBodyGyro.CFrame = camera.CFrame
            flyBodyVelocity.Velocity = ((camera.CFrame.LookVector * (flyControl.F + flyControl.B)) + 
                ((camera.CFrame * CFrame.new(flyControl.L + flyControl.R, (flyControl.F + flyControl.B) * 0.2, 0).p) - camera.CFrame.p)) * flySpeed
        end)
        
        return function()
            keyDown:Disconnect()
            keyUp:Disconnect()
            renderConn:Disconnect()
            flyBodyVelocity:Destroy()
            flyBodyGyro:Destroy()
            if flyHumanoid then flyHumanoid.PlatformStand = false end
        end
    end
    
    invisflingCleanup.flyConn = startFly()
    
    -- Body thrust for fling
    Workspace.CurrentCamera.CameraSubject = root
    invisflingCleanup.bodyThrust = Instance.new("BodyThrust")
    invisflingCleanup.bodyThrust.Parent = root
    invisflingCleanup.bodyThrust.Force = Vector3.new(99999, 99999 * 10, 99999)
    invisflingCleanup.bodyThrust.Location = root.Position
    
    invisflingActive = true
end

FlingModule.invisfling = {
    enable = startInvisFling,
    disable = stopInvisFling,
    isEnabled = function() return invisflingActive end
}

-- ============= UNLOAD FUNCTION =============
FlingModule.unload = function()
    if FlingModule.fling.isShortcutEnabled() then
        FlingModule.fling.setShortcutEnabled(false)
    end
    if FlingModule.fling.isEnabled() then
        FlingModule.fling.disable()
    end
    if FlingModule.flyfling.isEnabled() then
        FlingModule.flyfling.disable()
    end
    if FlingModule.walkfling.isEnabled() then
        FlingModule.walkfling.disable()
    end
    if FlingModule.invisfling.isEnabled() then
        FlingModule.invisfling.disable()
    end
end

return FlingModule