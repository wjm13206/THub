local cloneref = cloneref or clonereference or function(obj) return obj end
local Players = cloneref(game:GetService("Players"))
local ContextActionService = cloneref(game:GetService("ContextActionService"))
local UserInputService = cloneref(game:GetService("UserInputService"))

local localPlayer = Players.LocalPlayer
local module = {}

-- 内部状态
local enabled = false          -- 功能开关
local moveDistance = 10        -- 默认平移距离

-- 动作名称（用于绑定）
local ACTION_MOVE_FORWARD = "MoveForward"
local ACTION_MOVE_BACKWARD = "MoveBackward"
local ACTION_MOVE_LEFT = "MoveLeft"
local ACTION_MOVE_RIGHT = "MoveRight"

-- 获取玩家角色的根部件（HumanoidRootPart 或 PrimaryPart）
local function getRootPart(character)
    return character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
end

-- 动作处理函数：只在按键按下时执行一次平移，并返回 Sink 阻止默认移动
local function onAction(actionName, inputState, input)
    -- 仅当按键刚按下时执行
    if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
    -- 如果正在输入文字（如聊天框），忽略平移
    if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end

    -- 获取当前角色和根部件
    local character = localPlayer.Character
    if not character then return Enum.ContextActionResult.Pass end
    local rootPart = getRootPart(character)
    if not rootPart then return Enum.ContextActionResult.Pass end

    -- 根据动作计算位移向量（基于当前朝向，Y 轴不变）
    local moveVec
    if actionName == ACTION_MOVE_FORWARD then
        moveVec = rootPart.CFrame.LookVector * moveDistance      -- 前
    elseif actionName == ACTION_MOVE_BACKWARD then
        moveVec = -rootPart.CFrame.LookVector * moveDistance     -- 后
    elseif actionName == ACTION_MOVE_LEFT then
        moveVec = -rootPart.CFrame.RightVector * moveDistance    -- 左
    elseif actionName == ACTION_MOVE_RIGHT then
        moveVec = rootPart.CFrame.RightVector * moveDistance     -- 右
    end

    -- 保持 Y 轴高度不变
    moveVec = Vector3.new(moveVec.X, 0, moveVec.Z)

    -- 执行平移
    rootPart.CFrame = rootPart.CFrame + moveVec

    -- 消耗输入，阻止默认的方向键移动/旋转
    return Enum.ContextActionResult.Sink
end

-- 启用平移功能（绑定方向键，高优先级覆盖默认行为）
function module.Enable()
    if enabled then return end
    enabled = true

    -- 使用 BindActionAtPriority 设置高优先级，确保能拦截默认移动
    -- 第三个参数 false 表示不创建触摸按钮，后面依次为优先级和按键列表
    ContextActionService:BindActionAtPriority(
        ACTION_MOVE_FORWARD,
        onAction,
        false,
        Enum.ContextActionPriority.High.Value,
        Enum.KeyCode.Up
    )
    ContextActionService:BindActionAtPriority(
        ACTION_MOVE_BACKWARD,
        onAction,
        false,
        Enum.ContextActionPriority.High.Value,
        Enum.KeyCode.Down
    )
    ContextActionService:BindActionAtPriority(
        ACTION_MOVE_LEFT,
        onAction,
        false,
        Enum.ContextActionPriority.High.Value,
        Enum.KeyCode.Left
    )
    ContextActionService:BindActionAtPriority(
        ACTION_MOVE_RIGHT,
        onAction,
        false,
        Enum.ContextActionPriority.High.Value,
        Enum.KeyCode.Right
    )
end

-- 禁用平移功能（解绑所有方向键动作）
function module.Disable()
    if not enabled then return end
    enabled = false

    ContextActionService:UnbindAction(ACTION_MOVE_FORWARD)
    ContextActionService:UnbindAction(ACTION_MOVE_BACKWARD)
    ContextActionService:UnbindAction(ACTION_MOVE_LEFT)
    ContextActionService:UnbindAction(ACTION_MOVE_RIGHT)
end

-- 完全卸载模块（清理所有资源并重置状态）
function module.Unload()
    -- 先禁用功能
    module.Disable()
    
    -- 重置所有内部状态到初始值
    moveDistance = 10
    
    -- 清空模块函数（可选，防止后续调用）
    module.Enable = nil
    module.Disable = nil
    module.SetDistance = nil
    module.GetDistance = nil
    module.Unload = nil
    
    -- 注意：不将 module 本身设为 nil，因为外部可能持有引用
    -- 但清空了所有方法后，模块实际上已无法使用
end

-- 设置每次平移的距离（非负数）
function module.SetDistance(distance)
    assert(type(distance) == "number" and distance >= 0, "Distance must be a non-negative number")
    moveDistance = distance
end

-- 获取当前平移距离
function module.GetDistance()
    return moveDistance
end

return module