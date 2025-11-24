-- Load Fluent UI Library
print("Loading UI Library...")
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
print("UI Library loaded!")

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

-- Find Remotes
local ItemsRemote, ReplicatorRemote, UpdateFeedbackRemote

local function findRemotes()
    local success = pcall(function()
        ItemsRemote = ReplicatedStorage.Shared.Utilities.NetworkUtility.Events.Items
        ReplicatorRemote = ReplicatedStorage.Shared.Utilities.NetworkUtility.Events.Replicator
        UpdateFeedbackRemote = ReplicatedStorage.Shared.Utilities.NetworkUtility.Events.UpdateFeedback
    end)
    return success and ItemsRemote ~= nil
end

print("Finding remotes...")
local remotesFound = findRemotes()
print(remotesFound and "Remotes found!" or "Remotes not found yet")

-- Auto Pack Config
local Config = {
    Enabled = false,
    OpenDelay = 1,
    MaxPacks = 100,
    PacksOpened = 0,
    TotalCards = {},
    WaitingForReveal = false
}

-- Create Window
print("Creating UI Window...")
local Window = Fluent:CreateWindow({
    Title = "Card Shop Auto Opener",
    SubTitle = "by PackDev v2.0",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    AutoPack = Window:AddTab({ Title = "Auto Pack", Icon = "package" }),
    Manual = Window:AddTab({ Title = "Manual", Icon = "hand" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

print("Window created!")

Fluent:Notify({
    Title = "Script Loaded",
    Content = "Ready to auto open packs!",
    Duration = 5
})

-- ============================================
-- CARD REVEAL DETECTION & AUTO SWIPE
-- ============================================

local function findSwipeButton()
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Common locations for swipe/skip buttons
    local possiblePaths = {
        playerGui:FindFirstChild("Feedback"),
        playerGui:FindFirstChild("PackOpening"),
        playerGui:FindFirstChild("CardReveal"),
        playerGui:FindFirstChild("UnpackGui")
    }
    
    for _, gui in pairs(possiblePaths) do
        if gui and gui.Enabled then
            -- Look for swipe or skip buttons
            for _, descendant in pairs(gui:GetDescendants()) do
                if descendant:IsA("GuiButton") or descendant:IsA("TextButton") or descendant:IsA("ImageButton") then
                    local name = string.lower(descendant.Name)
                    local text = ""
                    
                    if descendant:FindFirstChildOfClass("TextLabel") then
                        text = string.lower(descendant:FindFirstChildOfClass("TextLabel").Text)
                    end
                    
                    -- Check for swipe/skip/next/claim keywords
                    if string.find(name, "swipe") or string.find(name, "skip") or 
                       string.find(name, "next") or string.find(name, "claim") or
                       string.find(name, "continue") or string.find(text, "swipe") or
                       string.find(text, "skip") then
                        return descendant
                    end
                end
            end
            
            -- If no button found, try to find any clickable frame
            for _, descendant in pairs(gui:GetDescendants()) do
                if descendant:IsA("Frame") and descendant.Active then
                    return descendant
                end
            end
        end
    end
    
    return nil
end

local function performSwipe()
    -- Method 1: Find and click swipe button
    local swipeButton = findSwipeButton()
    
    if swipeButton then
        pcall(function()
            local pos = swipeButton.AbsolutePosition
            local size = swipeButton.AbsoluteSize
            
            -- Click the button
            VirtualInputManager:SendMouseButtonEvent(
                pos.X + size.X/2,
                pos.Y + size.Y/2,
                0, true, game, 0
            )
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(
                pos.X + size.X/2,
                pos.Y + size.Y/2,
                0, false, game, 0
            )
            
            print("Clicked swipe button!")
            return true
        end)
    end
    
    -- Method 2: Simulate swipe gesture (drag from left to right)
    pcall(function()
        local camera = workspace.CurrentCamera
        local screenSize = camera.ViewportSize
        
        local startX = screenSize.X * 0.2
        local endX = screenSize.X * 0.8
        local midY = screenSize.Y * 0.2
        
        -- Mouse down
        VirtualInputManager:SendMouseButtonEvent(startX, midY, 0, true, game, 0)
        task.wait(0.05)
        
        -- Move right (simulate swipe)
        for i = 1, 10 do
            local x = startX + (endX - startX) * (i / 10)
            VirtualInputManager:SendMouseMoveEvent(x, midY, game)
            task.wait(0.01)
        end
        
        -- Mouse up
        VirtualInputManager:SendMouseButtonEvent(endX, midY, 0, false, game, 0)
        
        print("Performed swipe gesture!")
    end)
    
    return true
end

local function waitForRevealComplete()
    -- Wait for reveal animation to complete
    local startTime = tick()
    local maxWait = 5 -- Maximum 5 seconds wait
    
    while (tick() - startTime) < maxWait do
        -- Check if we can open another pack (feedback GUI closed)
        local playerGui = player.PlayerGui
        local feedbackGui = playerGui:FindFirstChild("Feedback")
        
        if not feedbackGui or not feedbackGui.Enabled then
            print("Reveal complete, ready for next pack!")
            return true
        end
        
        -- Try to skip/swipe
        performSwipe()
        task.wait(0.5)
    end
    
    print("Timeout waiting for reveal")
    return false
end

-- Monitor UpdateFeedback for pack reveal
if UpdateFeedbackRemote then
    UpdateFeedbackRemote.OnClientEvent:Connect(function(action, data)
        if action == "Unpack" then
            print("Pack revealed! Cards:", data)
            Config.WaitingForReveal = true
            
            -- Auto swipe after short delay
            task.wait(0.3)
            performSwipe()
            task.wait(0.5)
            performSwipe() -- Try twice to make sure
            
            Config.WaitingForReveal = false
        end
    end)
end

-- ============================================
-- PACK OPENING FUNCTIONS
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
        print("Pack #" .. Config.PacksOpened .. " opened!")
        return true
    end
    return false
end

-- Monitor cards received
if ReplicatorRemote then
    ReplicatorRemote.OnClientEvent:Connect(function(eventType, action, data)
        pcall(function()
            if eventType == "Cards" and action == "Update" and type(data) == "table" then
                for cardName, cardData in pairs(data) do
                    if type(cardName) == "string" then
                        Config.TotalCards[cardName] = (Config.TotalCards[cardName] or 0) + 1
                        print("Got card:", cardName)
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
            -- Open pack
            if openPack() then
                print("Waiting for reveal animation...")
                
                -- Wait for reveal and auto swipe
                task.wait(1) -- Wait for pack to open
                
                -- Perform multiple swipes to ensure we get through
                for i = 1, 3 do
                    performSwipe()
                    task.wait(0.3)
                end
                
                -- Wait for animation to complete
                waitForRevealComplete()
                
                -- Notification every 10 packs
                if Config.PacksOpened % 10 == 0 then
                    Fluent:Notify({
                        Title = "Progress",
                        Content = string.format("%d/%d packs", Config.PacksOpened, Config.MaxPacks),
                        Duration = 2
                    })
                end
                
                -- Additional delay before next pack
                task.wait(Config.OpenDelay)
            else
                print("Failed to open pack, retrying...")
                task.wait(2)
            end
        end
        
        Config.Enabled = false
        Fluent:Notify({
            Title = "Complete!",
            Content = string.format("Opened %d packs!", Config.PacksOpened),
            Duration = 5
        })
        
        print("=== SUMMARY ===")
        for card, count in pairs(Config.TotalCards) do
            print(card .. ": " .. count)
        end
    end)
end

local function stopAutoOpen()
    Config.Enabled = false
    Fluent:Notify({
        Title = "Stopped",
        Content = string.format("Stopped at %d packs", Config.PacksOpened),
        Duration = 3
    })
end

-- ============================================
-- AUTO PACK TAB
-- ============================================

Tabs.AutoPack:AddSection("Auto Pack Opener")

Tabs.AutoPack:AddToggle("AutoPackToggle", {
    Title = "Enable Auto Unpack",
    Description = "Automatically open and swipe packs",
    Default = false,
    Callback = function(value)
        if value then
            startAutoOpen()
        else
            stopAutoOpen()
        end
    end
})

Tabs.AutoPack:AddSlider("MaxPacksSlider", {
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

Tabs.AutoPack:AddSlider("DelaySlider", {
    Title = "Delay After Swipe",
    Description = "Extra delay after swipe (seconds)",
    Default = 1,
    Min = 0.5,
    Max = 3,
    Rounding = 1,
    Callback = function(value)
        Config.OpenDelay = value
    end
})

Tabs.AutoPack:AddSection("Status")

Tabs.AutoPack:AddButton({
    Title = "Check Progress",
    Description = "View current progress",
    Callback = function()
        local cardInfo = ""
        local count = 0
        for cardName, amount in pairs(Config.TotalCards) do
            if count < 5 then
                cardInfo = cardInfo .. cardName .. ": " .. amount .. "\n"
                count = count + 1
            end
        end
        
        Fluent:Notify({
            Title = "Progress",
            Content = string.format("Packs: %d/%d\nStatus: %s\n\nCards:\n%s", 
                Config.PacksOpened,
                Config.MaxPacks,
                Config.Enabled and "Running" or "Stopped",
                cardInfo ~= "" and cardInfo or "None yet"),
            Duration = 7
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
            Content = "Check console (F9)",
            Duration = 3
        })
    end
})

-- ============================================
-- MANUAL TAB
-- ============================================

Tabs.Manual:AddSection("Manual Testing")

Tabs.Manual:AddButton({
    Title = "Test Swipe",
    Description = "Test the swipe gesture",
    Callback = function()
        if performSwipe() then
            Fluent:Notify({
                Title = "Swipe Performed",
                Content = "Check if cards revealed!",
                Duration = 3
            })
        end
    end
})

Tabs.Manual:AddButton({
    Title = "Open 1 Pack (Manual)",
    Description = "Open pack without auto swipe",
    Callback = function()
        if openPack() then
            Fluent:Notify({
                Title = "Pack Opened",
                Content = "Swipe manually to see cards!",
                Duration = 3
            })
        end
    end
})

Tabs.Manual:AddButton({
    Title = "Open + Auto Swipe",
    Description = "Open pack with auto swipe",
    Callback = function()
        task.spawn(function()
            if openPack() then
                task.wait(1)
                for i = 1, 3 do
                    performSwipe()
                    task.wait(0.3)
                end
                Fluent:Notify({
                    Title = "Complete",
                    Content = "Pack opened and swiped!",
                    Duration = 3
                })
            end
        end)
    end
})

Tabs.Manual:AddSection("Debug")

Tabs.Manual:AddButton({
    Title = "Find Swipe Button",
    Description = "Try to find the swipe button",
    Callback = function()
        local button = findSwipeButton()
        if button then
            print("Found button:", button:GetFullName())
            Fluent:Notify({
                Title = "Button Found",
                Content = "Check console for details",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "Not Found",
                Content = "No swipe button found",
                Duration = 3
            })
        end
    end
})

-- ============================================
-- SETTINGS TAB
-- ============================================

Tabs.Settings:AddSection("Options")

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

Tabs.Settings:AddParagraph({
    Title = "How It Works",
    Content = "1. Opens pack via Items remote\n2. Waits 1 second for animation\n3. Performs swipe gesture 3 times\n4. Waits for reveal to complete\n5. Repeats until max packs reached"
})

print("======================")
print("GUI Created!")
print("Auto-swipe enabled!")
print("======================")
