-- player.lua
return function(C, R, UI)
    C = C or _G.C
    UI = UI or _G.UI

    local tab = UI.Tabs.Player
    local lp = C.LocalPlayer
    local U = C.Util
    local UIS = C.Services.UIS
    local PPS = C.Services.PPS

    tab:Section({ Title = "Movement" })

    tab:Slider({
        Title = "Walk Speed",
        Value = {
            Min = 8,
            Max = 120,
            Default = C.Config.WalkSpeed,
        },
        Callback = function(v)
            local n = tonumber(type(v) == "table" and (v.Value or v.Current or v.Default) or v)
            if not n then return end
            C.Config.WalkSpeed = math.clamp(n, 8, 120)
            local hum = U.getHumanoid()
            if hum then hum.WalkSpeed = C.Config.WalkSpeed end
        end
    })

    tab:Slider({
        Title = "Jump Power",
        Value = {
            Min = 25,
            Max = 200,
            Default = C.Config.JumpPower,
        },
        Callback = function(v)
            local n = tonumber(type(v) == "table" and (v.Value or v.Current or v.Default) or v)
            if not n then return end
            C.Config.JumpPower = math.clamp(n, 25, 200)
            local hum = U.getHumanoid()
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = C.Config.JumpPower
            end
        end
    })

    tab:Toggle({
        Title = "Infinite Jump",
        Value = C.State.Toggles.InfiniteJump,
        Callback = function(on)
            C.State.Toggles.InfiniteJump = on
            if on then
                if C.Connections.InfJump then
                    C.Connections.InfJump:Disconnect()
                    C.Connections.InfJump = nil
                end
                C.Connections.InfJump = UIS.JumpRequest:Connect(function()
                    if not C.State.Toggles.InfiniteJump then return end
                    local hum = U.getHumanoid()
                    if hum then
                        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
                    end
                end)
            else
                if C.Connections.InfJump then
                    C.Connections.InfJump:Disconnect()
                    C.Connections.InfJump = nil
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
            if strfindAny(a.Na
