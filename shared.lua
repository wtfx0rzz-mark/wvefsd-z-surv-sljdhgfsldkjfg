-- shared.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")

local lp = Players.LocalPlayer

local State = {
    AutoHit = false,
    ItemMagnet = false,
    InfiniteJump = false,
    InstantInteract = true,
    WalkSpeed = 60,
    JumpPower = 50,
    MagnetRadius = 10,
    MagnetDropping = false,
}

local Connections = {}

local function getChar()
    return lp.Character
end

local function getRoot()
    local char = getChar()
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = getChar()
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function findWeaponTool(searchIn)
    if not searchIn then return nil end
    for _, tool in ipairs(searchIn:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("Swing") and tool:FindFirstChild("HitTargets") then
            return tool
        end
    end
    return nil
end

local function getWeaponRange(tool)
    if not tool then return 20 end
    local stats = tool:FindFirstChild("Stats")
    if stats then
        local range = stats:GetAttribute("Range")
        if range and type(range) == "number" then
            return range
        end
    end
    return 20
end

local function isValidTarget(child, myChar)
    if not child or not child.Parent then return false end
    if child == myChar then return false end
    local humanoid = child:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    if humanoid.Health <= 0 then return false end
    if humanoid:GetState() == Enum.HumanoidStateType.Dead then return false end
    if child:GetAttribute("Dead") == true then return false end
    if child:GetAttribute("Hibernating") == true then return false end
    return true
end

local function distTo(inst, rootPos)
    local pos
    if inst:IsA("Model") then
        local hrp = inst:FindFirstChild("HumanoidRootPart")
        if hrp then
            pos = hrp.Position
        elseif inst.PrimaryPart then
            pos = inst.PrimaryPart.Position
        else
            for _, v in ipairs(inst:GetDescendants()) do
                if v:IsA("BasePart") then pos = v.Position break end
            end
        end
    elseif inst:IsA("BasePart") then
        pos = inst.Position
    end
    if not pos then return math.huge end
    return (rootPos - pos).Magnitude
end

local function getItemHandle(item)
    if not item or not item.Parent then return nil end
    local handle = item:FindFirstChild("Handle")
    if handle and handle:IsA("BasePart") then return handle end
    for _, child in ipairs(item:GetChildren()) do
        if child:IsA("BasePart") then
            return child
        end
    end
    return nil
end

local function applyMovement()
    local hum = getHumanoid()
    if not hum then return end
    hum.WalkSpeed = State.WalkSpeed
    hum.UseJumpPower = true
    hum.JumpPower = State.JumpPower
end

_G.ZT.State = State
_G.ZT.Connections = Connections
_G.ZT.Util = {
    getChar = getChar,
    getRoot = getRoot,
    getHumanoid = getHumanoid,
    findWeaponTool = findWeaponTool,
    getWeaponRange = getWeaponRange,
    isValidTarget = isValidTarget,
    distTo = distTo,
    getItemHandle = getItemHandle,
    applyMovement = applyMovement,
    lp = lp,
    Services = {
        Players = Players,
        RunService = RunService,
        UserInputService = UserInputService,
        Workspace = Workspace,
        ProximityPromptService = ProximityPromptService,
    },
}

lp.CharacterAdded:Connect(function()
    task.wait(0.1)
    applyMovement()
end)

applyMovement()

return function() end
