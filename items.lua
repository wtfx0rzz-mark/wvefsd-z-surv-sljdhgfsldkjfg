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
    local PICKUP_DISTANCE = 4
    C.Config.OwnershipRefreshDistance = C.Config.OwnershipRefreshDistance or 10
    local ownedItems = {}
    local itemStartPositions = {}
    local releasedItems = {}

    local function claimOwnership(item)
        if releasedItems[item] then return false end
        local drag = item:FindFirstChild("ItemDrag")
        if not drag then return false end
        local remote = drag:FindFirstChild("RequestNetworkOwnership")
        if not remote then return false end
        local mainPart = item:FindFirstChild("MainPart") or item:FindFirstChild("Handle")
        if not mainPart then
            for _, child in ipairs(item:GetChildren()) do
                if child:IsA("BasePart") then
                    mainPart = child
                    break
                end
            end
        end
        if not mainPart then return false end
        local ok = pcall(function()
            remote:FireServer(mainPart)
        end)
        if ok then
            ownedItems[item] = true
            itemStartPositions[item] = mainPart.Position
        end
        return ok
    end

    local function releaseOwnership(item)
        if releasedItems[item] then return end
        
        local handle = U.getItemHandle(item)
        if handle then
            pcall(function()
                handle.Anchored = true
                handle.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                handle.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end)
            task.wait(0.1)
            pcall(function()
                handle.Anchored = false
            end)
        end
        
        ownedItems[item] = nil
        itemStartPositions[item] = nil
        releasedItems[item] = true
        
        task.delay(5, function()
            releasedItems[item] = nil
        end)
    end

    local function shouldRefreshOwnership(item, handle)
        local startPos = itemStartPositions[item]
        if not startPos then return false end
        local distTraveled = (handle.Position - startPos).Magnitude
        return distTraveled >= C.Config.OwnershipRefreshDistance
    end

    tab:Section({ Title = "Item Magnet" })

    tab:Toggle({
        Title = "Enable Item Magnet",
        Value = C.State.Toggles.ItemMagnet,
        Callback = function(on)
            C.State.Toggles.ItemMagnet = on
            if not on then
                for item, _ in pairs(ownedItems) do
                    releaseOwnership(item)
                end
                ownedItems = {}
                itemStartPositions = {}
            end
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

    tab:Slider({
        Title = "Refresh Distance:",
        Value = {
            Min = 5,
            Max = 50,
            Default = C.Config.OwnershipRefreshDistance,
        },
        Callback = function(v)
            local n = tonumber(type(v) == "table" and (v.Value or v.Current or v.Default) or v)
            if not n then return end
            C.Config.OwnershipRefreshDistance = math.clamp(n, 5, 50)
        end
    })

    C.Connections.ItemMagnet = RunService.Heartbeat:Connect(function()
        if not C.State.Toggles.ItemMagnet then return end

        local rootPart = U.getRoot()
        if not rootPart then return end
        local rootPos = rootPart.Position

        local droppedItems = WS:FindFirstChild("DroppedItems")
        if not droppedItems then return end

        for _, item in ipairs(droppedItems:GetChildren()) do
            local handle = U.getItemHandle(item)
            if handle then
                local dist = (rootPos - handle.Position).Magnitude
                
                if dist <= PICKUP_DISTANCE then
                    if ownedItems[item] then
                        releaseOwnership(item)
                    end
                elseif dist <= C.Config.MagnetRadius then
                    if ownedItems[item] and shouldRefreshOwnership(item, handle) then
                        ownedItems[item] = nil
                        itemStartPositions[item] = nil
                    end
                    
                    if claimOwnership(item) then
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
        end
    end)
end
