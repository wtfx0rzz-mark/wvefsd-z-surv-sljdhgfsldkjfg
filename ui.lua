-- ui.lua
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

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
    Player = Window:Tab({
        Title = "Player",
        Icon = "user",
        Desc = "Movement / jump / interactions",
    }),
}

return {
    Lib = WindUI,
    Window = Window,
    Tabs = Tabs,
}
