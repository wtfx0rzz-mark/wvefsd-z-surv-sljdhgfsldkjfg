-- items.lua
return function(C, R, UI)
    C = C or _G.C
    UI = UI or _G.UI

    local tab = UI.Tabs.Items
    local U = C.Util
    local RunService = C.Services.Run
    local WS = C.Services.WS
    local WindUI = UI.Lib

    local MAGNET_OFFSET = CFrame.new(0, -2, -3)
    local DROP_OFFSET = CFrame.new(0, -3, -8)
    local DROP_COOLDOWN = 2
    local dropCooldownActive = false

    tab:Section({ Title = "Item Magnet" })

    tab:Toggle({
        Title = "Enable Item Magnet",
        Value = C.State.Toggles.ItemMagnet,
        Callback = function(on)
            C.State.Toggles.ItemMagnet = on
        end
    })

    tab:Slider({
        Title = "Magnet Radius",
        Value = {
            Min = 5,
            Max = 50,
            Default = C.Config.MagnetRadius,
        },
        Callback = function(v)
            local n = tonumber(type(v) == "table" and (v.Value or v.Current or v.Default) or v)
            if not n then return end
            C.Config.MagnetRadius = math.clamp(n, 5, 50)
        end
    })

    tab:Button({
        Title = "Drop All Magnetized Items",
        Callback = function()
            if dropCooldownActive then
                WindUI:Notify({
                    Title = "Items",
                    Content = "Drop on cooldown, wait a moment",
                    Duration = 1,
                    Icon = "clock",
                })
                return
            end

            dropCooldownActive = true
            C.State.Toggles.MagnetDropping = true

            local rootPart = U.getRoot()
            if not rootPart then
                C.State.Toggles.MagnetDropping = false
                dropCooldownActive = false
                return
            end

            local droppedItems = WS:FindFirstChild("DroppedItems")
            if not droppedItems then
                C.State.Toggles.MagnetDropping = false
                dropCooldownActive = false
                return
            end

            local count = 0
            for _, item in ipairs(droppedItems:GetChildren()) do
                local handle = U.getItemHandle(item)
                if handle then
                    local dist = (rootPart.Position - handle.Position).Magnitude
                    if dist < C.Config.MagnetRadius then
                        pcall(function()
                            handle.CFrame = rootPart.CFrame * DROP_OFFSET
                            handle.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            handle.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                        end)
                        count = count + 1
                    end
                end
            end

            task.delay(DROP_COOLDOWN, function()
                C.State.Toggles.MagnetDropping = false
                dropCooldownActive = false
            end)

            WindUI:Notify({
                Title = "Items",
                Content = "Dropped " .. count .. " items",
                Duration = 2,
                Icon = "package",
            })
        end
    })

    C.Connections.ItemMagnet = RunService.Heartbeat:Connect(function()
        if not C.State.Toggles.ItemMagnet then return end
        if C.State.Toggles.MagnetDropping then return end

        local rootPart = U.getRoot()
        if not rootPart then return end
        local rootPos = rootPart.Position

        local droppedItems = WS:FindFirstChild("DroppedItems")
        if not droppedItems then return end

        for _, item in ipairs(droppedItems:GetChildren()) do
            local handle = U.getItemHandle(item)
            if handle then
                local dist = (rootPos - handle.Position).Magnitude
                if dist <= C.Config.MagnetRadius then
                    pcall(function()
                        handle.Anchored = false
                        handle.CanCollide = false
                        handle.CFrame = rootPart.CFrame * MAGNET_OFFSET
                        handle.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        handle.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    end)
                end
            end
        end
    end)
end
