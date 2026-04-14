-- items.lua
return function()
    local ZT = _G.ZT
    local tab = ZT.Tabs.Items
    local State = ZT.State
    local Connections = ZT.Connections
    local U = ZT.Util
    local RunService = U.Services.RunService
    local Workspace = U.Services.Workspace
    local WindUI = ZT.WindUI

    local MAGNET_OFFSET = CFrame.new(0, -2, -3)
    local DROP_OFFSET = CFrame.new(0, -3, -8)
    local DROP_COOLDOWN = 2
    local dropCooldownActive = false

    tab:Section({ Title = "Item Magnet" })

    tab:Toggle({
        Title = "Enable Item Magnet",
        Value = State.ItemMagnet,
        Callback = function(on)
            State.ItemMagnet = on
        end
    })

    tab:Slider({
        Title = "Magnet Radius",
        Value = {
            Min = 5,
            Max = 50,
            Default = State.MagnetRadius,
        },
        Callback = function(v)
            local n = tonumber(type(v) == "table" and (v.Value or v.Current or v.Default) or v)
            if not n then return end
            State.MagnetRadius = math.clamp(n, 5, 50)
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
            State.MagnetDropping = true

            local rootPart = U.getRoot()
            if not rootPart then
                State.MagnetDropping = false
                dropCooldownActive = false
                return
            end

            local droppedItems = Workspace:FindFirstChild("DroppedItems")
            if not droppedItems then
                State.MagnetDropping = false
                dropCooldownActive = false
                return
            end

            local count = 0
            for _, item in ipairs(droppedItems:GetChildren()) do
                local handle = U.getItemHandle(item)
                if handle then
                    local dist = (rootPart.Position - handle.Position).Magnitude
                    if dist < State.MagnetRadius then
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
                State.MagnetDropping = false
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

    Connections.ItemMagnet = RunService.Heartbeat:Connect(function()
        if not State.ItemMagnet then return end
        if State.MagnetDropping then return end

        local rootPart = U.getRoot()
        if not rootPart then return end
        local rootPos = rootPart.Position

        local droppedItems = Workspace:FindFirstChild("DroppedItems")
        if not droppedItems then return end

        for _, item in ipairs(droppedItems:GetChildren()) do
            local handle = U.getItemHandle(item)
            if handle then
                local dist = (rootPos - handle.Position).Magnitude
                if dist <= State.MagnetRadius then
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
