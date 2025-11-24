-- Load Fluent UI Library (Alternative yang lebih stabil)
print("Loading UI Library...")

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

print("UI Library loaded!")

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Find Remotes
local ItemsRemote, ReplicatorRemote

local function findRemotes()
    local success = pcall(function()
        ItemsRemote = ReplicatedStorage.Shared.Utilities.NetworkUtility.Events.Items
        ReplicatorRemote = ReplicatedStorage.Shared.Utilities.NetworkUtility.Events.Replicator
    end)
    return success and ItemsRemote ~= nil
end

print("Finding remotes...")
local remotesFound = findRemotes()
print(remotesFound and "Remotes found!" or "Remotes not found yet")

-- Auto Pack Config
local Config = {
    Enabled = false,
    OpenDelay = 0.5,
    MaxPacks = 100,
    PacksOpened = 0,
    TotalCards = {}
}

-- Create Window
print("Creating UI Window...")

local Window = Fluent:CreateWindow({
    Title = "Card Shop Auto Opener",
    SubTitle = "by PackDev",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Create Tabs
local Tabs = {
    AutoPack = Window:AddTab({ Title = "Auto Pack", Icon = "package" }),
    Manual = Window:AddTab({ Title = "Manual", Icon = "hand" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

print("Window created!")

Fluent:Notify({
    Title = "Script Loaded",
    Content = remotesFound and "All systems ready!" or "Warning: Remotes not found!",
    Duration = 5
})

-- ============================================
-- FUNCTIONS
-- ============================================

local function openPack()
    if not ItemsRemote then
        return false
    end
    
    local success = pcall(function()
        ItemsRemote:FireServer("Unpack")
    end)
    
    if success then
        Config.PacksOpened = Config.PacksOpened + 1
        return true
    end
    return false
end

-- Monitor cards
if ReplicatorRemote then
    ReplicatorRemote.OnClientEvent:Connect(function(eventType, action, data)
        pcall(function()
            if eventType == "Cards" and action == "Update" and type(data) == "table" then
                for cardName, _ in pairs(data) do
                    if type(cardName) == "string" then
                        Config.TotalCards[cardName] = (Config.TotalCards[cardName] or 0) + 1
                    end
                end
            end
        end)
    end)
end

local function startAutoOpen()
    if not ItemsRemote then
        Fluent:Notify({
            Title = "Error",
            Content = "Items remote not found!",
            Duration = 3
        })
        return
    end
    
    if Config.Enabled then
        Fluent:Notify({
            Title = "Warning",
            Content = "Auto open already running!",
            Duration = 3
        })
        return
    end
    
    Config.Enabled = true
    Config.PacksOpened = 0
    
    Fluent:Notify({
        Title = "Started",
        Content = string.format("Opening %d packs...", Config.MaxPacks),
        Duration = 3
    })
    
    task.spawn(function()
        while Config.Enabled and Config.PacksOpened < Config.MaxPacks do
            if openPack() then
                if Config.PacksOpened % 10 == 0 and Config.PacksOpened > 0 then
                    Fluent:Notify({
                        Title = "Progress",
                        Content = string.format("%d/%d packs opened", Config.PacksOpened, Config.MaxPacks),
                        Duration = 2
                    })
                end
                task.wait(Config.OpenDelay)
            else
                task.wait(2)
            end
        end
        
        Config.Enabled = false
        Fluent:Notify({
            Title = "Complete",
            Content = string.format("Opened %d packs!", Config.PacksOpened),
            Duration = 5
        })
    end)
end

local function stopAutoOpen()
    Config.Enabled = false
    Fluent:Notify({
        Title = "Stopped",
        Content = string.format("Total: %d packs opened", Config.PacksOpened),
        Duration = 3
    })
end

-- ============================================
-- AUTO PACK TAB
-- ============================================

local AutoPackSection = Tabs.AutoPack:AddSection("Auto Pack Opener")

local EnableToggle = Tabs.AutoPack:AddToggle("AutoPackToggle", {
    Title = "Enable Auto Unpack",
    Description = "Automatically open packs",
    Default = false,
    Callback = function(value)
        if value then
            startAutoOpen()
        else
            stopAutoOpen()
        end
    end
})

local MaxPacksSlider = Tabs.AutoPack:AddSlider("MaxPacksSlider", {
    Title = "Max Packs",
    Description = "Maximum packs to open",
    Default = 100,
    Min = 1,
    Max = 1000,
    Rounding = 0,
    Callback = function(value)
        Config.MaxPacks = value
    end
})

local DelaySlider = Tabs.AutoPack:AddSlider("DelaySlider", {
    Title = "Open Delay (seconds)",
    Description = "Delay between pack openings",
    Default = 0.5,
    Min = 0.1,
    Max = 5,
    Rounding = 1,
    Callback = function(value)
        Config.OpenDelay = value
    end
})

local StatusSection = Tabs.AutoPack:AddSection("Status")

Tabs.AutoPack:AddButton({
    Title = "Check Progress",
    Description = "View current progress",
    Callback = function()
        local cardInfo = ""
        local count = 0
        for cardName, amount in pairs(Config.TotalCards) do
            if count < 3 then
                cardInfo = cardInfo .. cardName .. ": " .. amount .. "\n"
                count = count + 1
            end
        end
        
        Fluent:Notify({
            Title = "Progress",
            Content = string.format("Packs: %d/%d\nStatus: %s\n\nTop Cards:\n%s", 
                Config.PacksOpened,
                Config.MaxPacks,
                Config.Enabled and "Running" or "Stopped",
                cardInfo ~= "" and cardInfo or "No cards yet"),
            Duration = 7
        })
    end
})

Tabs.AutoPack:AddButton({
    Title = "Reset Counter",
    Description = "Reset all counters",
    Callback = function()
        Config.PacksOpened = 0
        Config.TotalCards = {}
        Fluent:Notify({
            Title = "Reset",
            Content = "All counters reset!",
            Duration = 3
        })
    end
})

Tabs.AutoPack:AddButton({
    Title = "Show All Cards",
    Description = "Print all cards to console",
    Callback = function()
        print("=== ALL CARDS ===")
        for card, amount in pairs(Config.TotalCards) do
            print(card .. ": " .. amount)
        end
        print("================")
        Fluent:Notify({
            Title = "Cards Listed",
            Content = "Check console (F9) for full list",
            Duration = 3
        })
    end
})

-- ============================================
-- MANUAL TAB
-- ============================================

local ManualSection = Tabs.Manual:AddSection("Manual Opening")

Tabs.Manual:AddButton({
    Title = "Open 1 Pack",
    Description = "Open a single pack",
    Callback = function()
        if openPack() then
            Fluent:Notify({
                Title = "Success",
                Content = "Opened 1 pack!",
                Duration = 2
            })
        else
            Fluent:Notify({
                Title = "Failed",
                Content = "Could not open pack",
                Duration = 2
            })
        end
    end
})

Tabs.Manual:AddButton({
    Title = "Open 10 Packs",
    Description = "Open 10 packs quickly",
    Callback = function()
        task.spawn(function()
            for i = 1, 10 do
                openPack()
                task.wait(0.3)
            end
            Fluent:Notify({
                Title = "Complete",
                Content = "Opened 10 packs!",
                Duration = 3
            })
        end)
    end
})

Tabs.Manual:AddButton({
    Title = "Open 50 Packs",
    Description = "Open 50 packs quickly",
    Callback = function()
        task.spawn(function()
            for i = 1, 50 do
                openPack()
                task.wait(0.2)
            end
            Fluent:Notify({
                Title = "Complete",
                Content = "Opened 50 packs!",
                Duration = 3
            })
        end)
    end
})

local DebugSection = Tabs.Manual:AddSection("Debug Tools")

Tabs.Manual:AddButton({
    Title = "Check Remote Status",
    Description = "Check if remotes are connected",
    Callback = function()
        local status = string.format(
            "Items Remote: %s\nReplicator Remote: %s",
            ItemsRemote and "✓ Found" or "✗ Not Found",
            ReplicatorRemote and "✓ Found" or "✗ Not Found"
        )
        
        Fluent:Notify({
            Title = "Remote Status",
            Content = status,
            Duration = 4
        })
    end
})

Tabs.Manual:AddButton({
    Title = "Retry Find Remotes",
    Description = "Try to find remotes again",
    Callback = function()
        if findRemotes() then
            Fluent:Notify({
                Title = "Success",
                Content = "Remotes found!",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "Failed",
                Content = "Could not find remotes",
                Duration = 3
            })
        end
    end
})

-- ============================================
-- SETTINGS TAB
-- ============================================

local SettingsSection = Tabs.Settings:AddSection("Options")

Tabs.Settings:AddButton({
    Title = "Rejoin Server",
    Description = "Rejoin current server",
    Callback = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(
            game.PlaceId, 
            game.JobId, 
            player
        )
    end
})

Tabs.Settings:AddButton({
    Title = "Copy Remote Path",
    Description = "Copy Items remote path",
    Callback = function()
        if ItemsRemote then
            setclipboard(ItemsRemote:GetFullName())
            Fluent:Notify({
                Title = "Copied",
                Content = "Remote path copied!",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "Error",
                Content = "Remote not found",
                Duration = 3
            })
        end
    end
})

Tabs.Settings:AddParagraph({
    Title = "Remote Information",
    Content = "Items Remote: ReplicatedStorage.Shared.Utilities.NetworkUtility.Events.Items\n\nEvent: Unpack"
})

print("======================")
print("GUI Successfully Created!")
print("Items Remote:", ItemsRemote and "✓" or "✗")
print("Replicator Remote:", ReplicatorRemote and "✓" or "✗")
print("======================")
