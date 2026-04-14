-- player.lua
return function()
    local ZT = _G.ZT
    local tab = ZT.Tabs.Player
    local State = ZT.State
    local Connections = ZT.Connections
    local U = ZT.Util
    local lp = U.lp
    local UIS = U.Services.UserInputService
    local PPS = U.Services.ProximityPromptService

    -- =================================================================
    -- Movement
    -- =================================================================

    tab:Section({ Title = "Movement" })

    tab:Slider({
        Title = "Walk Speed",
        Value = {
            Min = 8,
            Max = 120,
            Default = State.WalkSpeed,
        },
        Callback = function(v)
            local n = tonumber(type(v) == "table" and (v.Value or v.Current or v.Default) or v)
            if not n then return end
            State.WalkSpeed = math.clamp(n, 8, 120)
            local hum = U.getHumanoid()
            if hum then hum.WalkSpeed = State.WalkSpeed end
        end
    })

    tab:Slider({
        Title = "Jump Power",
        Value = {
            Min = 25,
            Max = 200,
            Default = State.JumpPower,
        },
        Callback = function(v)
            local n = tonumber(type(v) == "table" and (v.Value or v.Current or v.Default) or v)
            if not n then return end
            State.JumpPower = math.clamp(n, 25, 200)
            local hum = U.getHumanoid()
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = State.JumpPower
            end
        end
    })

    tab:Toggle({
        Title = "Infinite Jump",
        Value = State.InfiniteJump,
        Callback = function(on)
            State.InfiniteJump = on
            if on then
                if Connections.InfJump then
                    Connections.InfJump:Disconnect()
                    Connections.InfJump = nil
                end
                Connections.InfJump = UIS.JumpRequest:Connect(function()
                    if not State.InfiniteJump then return end
                    local hum = U.getHumanoid()
                    if hum then
                        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
                    end
                end)
            else
                if Connections.InfJump then
                    Connections.InfJump:Disconnect()
                    Connections.InfJump = nil
                end
            end
        end
    })

    -- =================================================================
    -- Instant Interact
    -- =================================================================

    tab:Section({ Title = "Interactions" })

    local INSTANT_HOLD = 0.2
    local TRIGGER_COOLDOWN = 0.2
    local EXCLUDE_NAME_SUBSTR = { "door", "closet", "gate", "hatch" }
    local EXCLUDE_ANCESTOR_SUBSTR = { "closetdoors", "closet", "door", "landmarks" }
    local UID_OPEN_KEY = tostring(lp.UserId) .. "Opened"

    local promptDurations = setmetatable({}, { __mode = "k" })

    local function strfindAny(s, list)
        s = string.lower(s or "")
        for _, w in ipairs(list) do
            if string.find(s, w, 1, true) then return true end
        end
        return false
    end

    local function shouldSkipPrompt(p)
        if not p or not p.Parent then return true end
        if strfindAny(p.Name, EXCLUDE_NAME_SUBSTR) then return true end
        pcall(function()
            if strfindAny(p.ObjectText, EXCLUDE_NAME_SUBSTR) then error(true) end
            if strfindAny(p.ActionText, EXCLUDE_NAME_SUBSTR) then error(true) end
        end)
        local a = p.Parent
        while a and a ~= workspace do
            if strfindAny(a.Name, EXCLUDE_ANCESTOR_SUBSTR) then return true end
            a = a.Parent
        end
        return false
    end

    local function restorePrompt(prompt)
        local orig = promptDurations[prompt]
        if orig ~= nil and prompt and prompt.Parent then
            pcall(function() prompt.HoldDuration = orig end)
        end
        promptDurations[prompt] = nil
    end

    local function tagChestFromPrompt(prompt)
        if not prompt then return end
        local node = prompt
        for _ = 1, 8 do
            if not node then break end
            if node:IsA("Model") then
                local n = node.Name
                if type(n) == "string" and (n:match("Chest%d*$") or n:match("Chest$")) then
                    pcall(function()
                        node:SetAttribute(UID_OPEN_KEY, true)
                    end)
                    break
                end
            end
            node = node.Parent
        end
    end

    local function onPromptShown(prompt)
        if not prompt or not prompt:IsA("ProximityPrompt") then return end
        if not State.InstantInteract then return end
        if shouldSkipPrompt(prompt) then return end
        if promptDurations[prompt] == nil then
            promptDurations[prompt] = prompt.HoldDuration
        end
        if prompt and prompt.Parent then
            pcall(function() prompt.HoldDuration = INSTANT_HOLD end)
        end
    end

    local function enableInstantInteract()
        if Connections.PromptShown then return end

        Connections.PromptShown = PPS.PromptShown:Connect(onPromptShown)

        Connections.PromptTriggered = PPS.PromptTriggered:Connect(function(prompt, player)
            if player ~= lp or shouldSkipPrompt(prompt) then return end
            tagChestFromPrompt(prompt)
            if TRIGGER_COOLDOWN and TRIGGER_COOLDOWN > 0 then
                pcall(function() prompt.Enabled = false end)
                task.delay(TRIGGER_COOLDOWN, function()
                    if prompt and prompt.Parent then
                        pcall(function() prompt.Enabled = true end)
                    end
                end)
            end
            restorePrompt(prompt)
        end)

        Connections.PromptHidden = PPS.PromptHidden:Connect(function(prompt)
            if shouldSkipPrompt(prompt) then return end
            restorePrompt(prompt)
        end)
    end

    local function disableInstantInteract()
        if Connections.PromptShown then
            Connections.PromptShown:Disconnect()
            Connections.PromptShown = nil
        end
        if Connections.PromptTriggered then
            Connections.PromptTriggered:Disconnect()
            Connections.PromptTriggered = nil
        end
        if Connections.PromptHidden then
            Connections.PromptHidden:Disconnect()
            Connections.PromptHidden = nil
        end
        for p, _ in pairs(promptDurations) do
            restorePrompt(p)
        end
    end

    if State.InstantInteract then
        enableInstantInteract()
    end

    tab:Toggle({
        Title = "Instant Interact",
        Value = State.InstantInteract,
        Callback = function(on)
            State.InstantInteract = on
            if on then
                enableInstantInteract()
            else
                disableInstantInteract()
            end
        end
    })
end
