-- loader.lua
repeat task.wait() until game:IsLoaded()

local BASE_URL = "https://raw.githubusercontent.com/YOUR_REPO_PATH/main/"

local function httpget(u)
    return game:HttpGet(u)
end

local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local WindUI = loadstring(httpget("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Zombie Testing",
    Icon = "crosshair",
    Author = "Mark",
    Folder = "zombietest",
    Size = UDim2.fromOffset(520, 360),
    Transparent = false,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 150,
    HideSearchBar = false,
    ScrollBarEnabled = true,
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            WindUI:Notify({
                Title = "User Info",
                Content = "Logged In As: " .. (lp.DisplayName or lp.Name),
                Duration = 2,
                Icon = "user",
            })
        end,
    },
})

Window:SetToggleKey(Enum.KeyCode.V)

local Tabs = {
    Combat = Window:Tab({
        Title = "Combat",
        Icon = "swords",
        Desc = "Auto hit / targeting",
    }),
    Items = Window:Tab({
        Title = "Items",
        Icon = "package",
        Desc = "Item magnet / pickup",
    }),
    Player = Window:Tab({
        Title = "Player",
        Icon = "user",
        Desc = "Movement / jump / interactions",
    }),
}

_G.ZT = {
    WindUI = WindUI,
    Window = Window,
    Tabs = Tabs,
}

local modules = {
    { name = "shared",  url = BASE_URL .. "shared.lua" },
    { name = "combat",  url = BASE_URL .. "combat.lua" },
    { name = "items",   url = BASE_URL .. "items.lua" },
    { name = "player",  url = BASE_URL .. "player.lua" },
}

for _, mod in ipairs(modules) do
    local ok, ret = pcall(function()
        return loadstring(httpget(mod.url))()
    end)
    if ok and type(ret) == "function" then
        local ok2, err2 = pcall(ret)
        if not ok2 then
            warn("[ZT] Error running " .. mod.name .. ": " .. tostring(err2))
        end
    elseif not ok then
        warn("[ZT] Failed to load " .. mod.name .. ": " .. tostring(ret))
    end
end

Window:SelectTab(1)
