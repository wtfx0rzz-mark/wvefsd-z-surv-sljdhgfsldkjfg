-- combat.lua
return function(C, R, UI)
    C = C or _G.C
    UI = UI or _G.UI

    local tab = UI.Tabs.Combat
    local lp = C.LocalPlayer
    local U = C.Util
    local RunService = C.Services.Run
    local WS = C.Services.WS

    tab:Section({ Title = "Auto Hit" })

    tab:Toggle({
        Title = "Enable Auto Hit",
        Value = C.State.Toggles.AutoHit,
        Callback = function(on)
            C.State.Toggles.AutoHit = on
        end
    })

    local lastWeaponName = ""

    C.Connections.AutoHit = RunService.Heartbeat:Connect(function()
        local char = U.getChar()
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                if hum.WalkSpeed ~= C.Config.WalkSpeed then
                    hum.WalkSpeed = C.Config.WalkSpeed
                end
                if hum.JumpPower ~= C.Config.JumpPower then
                    hum.UseJumpPower = true
                    hum.JumpPower = C.Config.JumpPower
                end
            end
        end

        if not C.State.Toggles.AutoHit then return end

        local rootPart = U.getRoot()
        if not rootPart then return end
        local rootPos = rootPart.Position

        local charsFolder = WS:FindFirstChild("Characters")
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
