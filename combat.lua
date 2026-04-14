-- combat.lua
return function()
    local ZT = _G.ZT
    local tab = ZT.Tabs.Combat
    local State = ZT.State
    local Connections = ZT.Connections
    local U = ZT.Util
    local RunService = U.Services.RunService
    local Workspace = U.Services.Workspace
    local lp = U.lp

    tab:Section({ Title = "Auto Hit" })

    tab:Toggle({
        Title = "Enable Auto Hit",
        Value = State.AutoHit,
        Callback = function(on)
            State.AutoHit = on
        end
    })

    local lastWeaponName = ""

    Connections.AutoHit = RunService.Heartbeat:Connect(function()
        local char = U.getChar()
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                if hum.WalkSpeed ~= State.WalkSpeed then
                    hum.WalkSpeed = State.WalkSpeed
                end
                if hum.JumpPower ~= State.JumpPower then
                    hum.UseJumpPower = true
                    hum.JumpPower = State.JumpPower
                end
            end
        end

        if not State.AutoHit then return end

        local rootPart = U.getRoot()
        if not rootPart then return end
        local rootPos = rootPart.Position

        local charsFolder = Workspace:FindFirstChild("Characters")
        if not charsFolder then return end

        local myChar = U.getChar()

        local tool = U.findWeaponTool(myChar)
        if not tool then
            local backpack = lp:FindFirstChildOfClass("Backpack")
            local backpackTool = U.findWeaponTool(backpack)
            if backpackTool then
                local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:EquipTool(backpackTool)
                    task.wait(0.05)
                    tool = U.findWeaponTool(myChar)
                end
            end
        end

        if not tool then return end

        local hitRange = U.getWeaponRange(tool)

        local weaponName = tool.Name
        if weaponName ~= lastWeaponName then
            lastWeaponName = weaponName
        end

        local swing = tool:FindFirstChild("Swing")
        local hitTargets = tool:FindFirstChild("HitTargets")
        if not swing or not hitTargets then return end

        local validTargets = {}
        for _, child in ipairs(charsFolder:GetChildren()) do
            if U.isValidTarget(child, myChar) then
                if U.distTo(child, rootPos) <= hitRange then
                    table.insert(validTargets, child)
                end
            end
        end

        if #validTargets == 0 then return end

        swing:FireServer()
        hitTargets:FireServer(validTargets)
    end)
end
