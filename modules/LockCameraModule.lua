-- 修正后的模块代码
local LockCameraModule = {}

local cloneref = cloneref or clonereference or function(obj) return obj end
local UserInputService = cloneref(game:GetService("UserInputService"))
local ContextActionService = cloneref(game:GetService("ContextActionService"))
local RunService = cloneref(game:GetService("RunService"))
local Players = cloneref(game:GetService("Players"))
local Workspace = cloneref(game:GetService("Workspace"))
local camera = Workspace.CurrentCamera

local isEnabled = false
local isLocking = false
local bindKey = Enum.KeyCode.Tab
local actionName = "LockCameraAction"  -- ContextAction 的唯一名称

local lockedCameraCFrame = nil
local lockedCharacterHRP = nil

local function getHRP()
    local char = Players.LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function updateCamera()
    if not isLocking then return end
    local hrp = getHRP()
    if not hrp or not lockedCharacterHRP or not lockedCameraCFrame then return end

    local offsetVector = lockedCameraCFrame.Position - lockedCharacterHRP.Position
    local newPosition = hrp.Position + offsetVector
    local newCFrame = CFrame.lookAt(newPosition, newPosition + lockedCameraCFrame.LookVector)
    camera.CFrame = newCFrame
end

-- ContextAction 的处理函数
local function onAction(actionName, inputState, inputObject)
    if not isEnabled then return Enum.ContextActionResult.Pass end

    if inputState == Enum.UserInputState.Begin then
        local hrp = getHRP()
        if hrp then
            lockedCharacterHRP = hrp.CFrame
            lockedCameraCFrame = camera.CFrame
            isLocking = true

            if not renderStepConn then
                renderStepConn = RunService:BindToRenderStep("CameraLock", Enum.RenderPriority.Camera.Value + 1, updateCamera)
            end
        end
        return Enum.ContextActionResult.Sink  -- 吞掉事件，阻止默认行为
    elseif inputState == Enum.UserInputState.End then
        isLocking = false
        lockedCharacterHRP = nil
        lockedCameraCFrame = nil
        if renderStepConn then
            RunService:UnbindFromRenderStep("CameraLock")
            renderStepConn = nil
        end
        return Enum.ContextActionResult.Sink
    end

    return Enum.ContextActionResult.Pass
end

local function setupBind()
    if isEnabled then
        ContextActionService:BindActionAtPriority(
            actionName,
            onAction,
            false,  -- 不创建按钮
            Enum.ContextActionPriority.High.Value,  -- 高优先级，确保拦截
            bindKey
        )
    else
        ContextActionService:UnbindAction(actionName)
    end
end

local function cleanupBind()
    ContextActionService:UnbindAction(actionName)
end

function LockCameraModule.enable()
    if isEnabled then return end
    isEnabled = true
    setupBind()
end

function LockCameraModule.disable()
    if not isEnabled then return end
    isEnabled = false
    if isLocking then
        isLocking = false
        lockedCharacterHRP = nil
        lockedCameraCFrame = nil
        if renderStepConn then
            RunService:UnbindFromRenderStep("CameraLock")
            renderStepConn = nil
        end
    end
    cleanupBind()
end

function LockCameraModule.getBindKey()
    return bindKey
end

function LockCameraModule.setBindKey(newKey)
    if type(newKey) == "string" then
        newKey = Enum.KeyCode[newKey]
    end
    if not newKey or not newKey.Name then
        error("无效的按键，请传入 Enum.KeyCode 或字符串名称")
    end
    if bindKey == newKey then return end
    bindKey = newKey
    if isEnabled then
        setupBind()
    end
end

function LockCameraModule.unload()
    LockCameraModule.disable()
    LockCameraModule.enable = nil
    LockCameraModule.disable = nil
    LockCameraModule.getBindKey = nil
    LockCameraModule.setBindKey = nil
    LockCameraModule.unload = nil
end

return LockCameraModule