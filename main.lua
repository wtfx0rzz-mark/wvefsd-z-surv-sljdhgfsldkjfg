-- main.lua
repeat task.wait() until game:IsLoaded()

local BASE_URL = "https://raw.githubusercontent.com/wtfx0rzz-mark/wvefsd-z-surv-sljdhgfsldkjfg/main/"

local function httpget(u)
    return game:HttpGet(u)
end

local UI = (function()
    local ok, ret = pcall(function()
        return loadstring(httpget(BASE_URL .. "ui.lua"))()
    end)
    if ok and type(ret) == "table" then
        return ret
    end
    warn("ui.lua load error: " .. tostring(ret))
    error("ui.lua failed to load")
end)()

local C = {}
C.Services = {
    Players = game:GetService("Players"),
    RS = game:GetService("ReplicatedStorage"),
    WS = game:GetService("Workspace"),
    Run = game:GetService("RunService"),
    UIS = game:GetService("UserInputService"),
    PPS = game:GetService("ProximityPromptService"),
}
C.LocalPlayer = C.Services.Players.LocalPlayer
C.Config = {}
C.State = {}
C.State.Toggles = {}
C.Connections = {}

_G.C = C
_G.R = _G.R or {}
_G.UI = UI

local modules = {
    { name = "shared",  url = BASE_URL .. "shared.lua" },
    { name = "combat",  url = BASE_URL .. "combat.lua" },
    { name = "player",  url = BASE_URL .. "player.lua" },
}

for _, mod in ipairs(modules) do
    local ok, ret = pcall(function()
        return loadstring(httpget(mod.url))()
    end)
    if ok and type(ret) == "function" then
        local ok2, err2 = pcall(ret, C, _G.R, UI)
        if not ok2 then
            warn("[ZT] Error running " .. mod.name .. ": " .. tostring(err2))
        end
    elseif not ok then
        warn("[ZT] Failed to load " .. mod.name .. ": " .. tostring(ret))
    end
end

UI.Window:SelectTab(1)
