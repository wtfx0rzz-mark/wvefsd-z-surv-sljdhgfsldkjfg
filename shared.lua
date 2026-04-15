-- shared.lua
return function(C, R, UI)
    C = C or _G.C
    UI = UI or _G.UI

    local Services = C.Services
    local lp = C.LocalPlayer

    C.Config.WalkSpeed = C.Config.WalkSpeed or 60
    C.Config.JumpPower = C.Config.JumpPower or 50
    C.Config.MagnetRadius = C.Config.MagnetRadius or 10

    C.State.Toggles.AutoHit = false
    C.State.Toggles.ItemMagnet = false
    C.State.Toggles.MagnetDropping = false
    C.State.Toggles.InfiniteJump = false
    C.State.Toggles.InstantInteract = true

    C.Util = {}

    function C.Util.getChar()
        return lp.Character
    end

    function C.Util.getRoot()
        local char = C.Util.getChar()
        if not char then return nil end
        return char:FindFirstChild("HumanoidRootPart")
    end

    function C.Util.getHumanoid()
        local char = C.Util.getChar()
        if not char then return nil end
        return char:FindFirstChildOfClass("Humanoid")
    end

    function C.Util.findWeaponTool(searchIn)
        if not searchIn then return nil end
        for _, tool in ipairs(searchIn:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("Swing") and tool:FindFirstChild("HitTargets") then
                return tool
            end
        end
        return nil
    end

    function C.Util.getWeaponRange(tool)
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

    function C.Util.isValidTarget(child, myChar)
        if not child or not child.Parent then return false end
        if child == myChar then return false end
        if child:GetAttribute("Player") == true then return false end
        local humanoid = child:FindFirstChildOfClass("Humanoid")
        if not humanoid then return false end
        if humanoid.Health <= 0 then return false end
        if humanoid:GetState() == Enum.HumanoidStateType.Dead then return false end
        if child:GetAttribute("Dead") == true then return false end
        if child:GetAttribute("Hibernating") == true then return false end
        return true
    end

    function C.Util.distTo(inst, rootPos)
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

    function C.Util.getItemHandle(item)
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

    function C.Util.applyMovement()
        local hum = C.Util.getHumanoid()
        if not hum then return end
        hum.WalkSpeed = C.Config.WalkSpeed
        hum.UseJumpPower = true
        hum.JumpPower = C.Config.JumpPower
    end

    lp.CharacterAdded:Connect(function()
        task.wait(0.1)
        C.Util.applyMovement()
    end)

    C.Util.applyMovement()
end
