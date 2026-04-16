-- combat.lua
return function(C, R, UI)
    C = C or _G.C
    UI = UI or _G.UI

    local tab = UI.Tabs.Combat
    local lp = C.LocalPlayer
    local U = C.Util
    local RunService = C.Services.Run
    local WS = C.Services.WS

    C.Config.HitRangeBonus = C.Config.HitRangeBonus or 0

    tab:Section({ Title = "Auto Hit" })

    tab:Toggle({
        Title = "Enable Auto Hit",
        Value = C.State.Toggles.AutoHit,
        Callback = function(on)
            C.State.Toggles.AutoHit = on
        end
    })

    tab:Toggle({
        Title = "Weapon Cycling",
        Value = C.State.Toggles.WeaponCycling,
        Callback = function(on)
            C.State.Toggles.WeaponCycling = on
        end
    })

    tab:Slider({
        Title = "Hit Range Bonus",
        Value = {
            Min = 0,
            Max = 50,
            Default = C.Config.HitRangeBonus,
        },
        Callback = function(v)
            local n = tonumber(type(v) == "table" and (v.Value or v.Current or v.Default) or v)
            if not n then return end
            C.Config.HitRangeBonus = math.clamp(n, 0, 50)
        end
    })

    local lastWeaponName = ""
    local lastManualTool = nil
    local weaponCycleIndex = 1

    local function setupCharacterTracking()
        local char = U.getChar()
        if not char then return end
        
        char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") and U.findWeaponTool(char) == child then
                if not C.State.Toggles.AutoHit then
                    lastManualTool = child
                end
            end
        end)
    end

    lp.CharacterAdded:Connect(function()
        task.wait(0.1)
        setupCharacterTracking()
    end)
    
    setupCharacterTracking()

    local function getAllWeapons()
        local weapons = {}
        local backpack = lp:FindFirstChildOfClass("Backpack")
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") and tool:FindFirstChild("Swing") and tool:FindFirstChild("HitTargets") then
                    table.insert(weapons, tool)
                end
            end
        end
        local char = U.getChar()
        if char then
            local equipped = U.findWeaponTool(char)
            if equipped then
                table.insert(weapons, equipped)
            end
        end
        return weapons
    end

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

        if C.State.Toggles.WeaponCycling then
            local weapons = getAllWeapons()
            if #weapons == 0 then return end

            weaponCycleIndex = (weaponCycleIndex % #weapons) + 1
            local targetWeapon = weapons[weaponCycleIndex]
            
            if not targetWeapon then return end

            local potentialRange = U.getWeaponRange(targetWeapon) + C.Config.HitRangeBonus

            local validTargets = {}
            for _, child in ipairs(charsFolder:GetChildren()) do
                if U.isValidTarget(child, myChar) then
                    if U.distTo(child, rootPos) <= potentialRange then
                        table.insert(validTargets, child)
                    end
                end
            end

            if #validTargets == 0 then return end

            if targetWeapon.Parent ~= myChar then
                local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:EquipTool(targetWeapon)
                    task.wait(0.05)
                end
            end

            local swing = targetWeapon:FindFirstChild("Swing")
            local hitTargets = targetWeapon:FindFirstChild("HitTargets")
            if swing and hitTargets then
                swing:FireServer()
                hitTargets:FireServer(validTargets)
            end
        else
            local tool = U.findWeaponTool(myChar)

            local potentialRange
            if tool then
                potentialRange = U.getWeaponRange(tool) + C.Config.HitRangeBonus
            else
                local targetTool = lastManualTool
                if not targetTool or not targetTool.Parent then
                    local backpack = lp:FindFirstChildOfClass("Backpack")
                    targetTool = U.findWeaponTool(backpack)
                end
                if targetTool then
                    potentialRange = U.getWeaponRange(targetTool) + C.Config.HitRangeBonus
                else
                    return
                end
            end

            local validTargets = {}
            for _, child in ipairs(charsFolder:GetChildren()) do
                if U.isValidTarget(child, myChar) then
                    if U.distTo(child, rootPos) <= potentialRange then
                        table.insert(validTargets, child)
                    end
                end
            end

            if #validTargets == 0 then return end

            if not tool then
                local targetTool = lastManualTool
                if not targetTool or not targetTool.Parent then
                    local backpack = lp:FindFirstChildOfClass("Backpack")
                    targetTool = U.findWeaponTool(backpack)
                end
                
                if targetTool and targetTool.Parent == lp:FindFirstChildOfClass("Backpack") then
                    local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum:EquipTool(targetTool)
                        task.wait(0.05)
                        tool = U.findWeaponTool(myChar)
                    end
                end
            end

            if not tool then return end

            local weaponName = tool.Name
            if weaponName ~= lastWeaponName then
                lastWeaponName = weaponName
            end

            local swing = tool:FindFirstChild("Swing")
            local hitTargets = tool:FindFirstChild("HitTargets")
            if not swing or not hitTargets then return end

            swing:FireServer()
            hitTargets:FireServer(validTargets)
        end
    end)
end
