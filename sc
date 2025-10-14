local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Load Window
local Window = WindUI:CreateWindow({
    Title = "Luther's Playground",
    Icon = "door-open",
    Author = "by Luther",
    Folder = "CloudHub",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
    User = {
        Enabled = true, -- <- or false
        Callback = function() print("clicked") end, -- <- optional
        Anonymous = false -- <- or true
    },
    SideBarWidth = 200,
    HasOutline = true,
    KeySystem = { -- <- keysystem enabled
        Key = { "1234", "5678" },
        Note = "Example Key System. \n\nThe Key is '1234' or '5678",
        URL = "https://github.com/Footagesus/WindUI", -- remove this if the key is not obtained from the link.
        SaveKey = true, -- optional
    },
})

local Tabs = {
    Info = Window:Tab({ Title = "Information", Icon = "door-open" }),
    Main = Window:Tab({ Title = "Main", Icon = "folder" }),
    Auto = Window:Tab({ Title = "Automation", Icon = "shopping-cart" }),
    Shop = Window:Tab({ Title = "Shop", Icon = "door-open" }),
    Misc = Window:Tab({ Title = "Misc", Icon = "folder" }),
}

-- Global function


-- Information Tab
local InviteCode = "XErAwERk"
local DiscordAPI = "https://discord.com/api/v10/invites/" .. InviteCode .. "?with_counts=true&with_expiration=true"

xpcall(function()
    Response = game:GetService("HttpService"):JSONDecode(WindUI.Creator.Request({
        Url = DiscordAPI,
        Method = "GET",
        Headers = {
            ["User-Agent"] = "RobloxBot/1.0",
            ["Accept"] = "application/json"
        }
    }).Body)
end, function(err)
    warn("err fetching discord info: " .. tostring(err))
    ErrorMessage = tostring(err)
    Response = nil
end)

if Response and Response.guild then
    local DiscordInfo = Tabs.Info:Paragraph({
        Title = Response.guild.name,
        Desc = 
            ' <font color="#52525b">�</font> Member Count : ' .. tostring(Response.approximate_member_count) .. 
            '\n <font color="#16a34a">�</font> Online Count : ' .. tostring(Response.approximate_presence_count)
        ,
        Image = "https://cdn.discordapp.com/icons/" .. Response.guild.id .. "/" .. Response.guild.icon .. ".png?size=1024",
        ImageSize = 42,
        Buttons = {
            {
                Icon = "link",
                Title = "Copy Discord Invite",
                Callback = function()
                    pcall(function()
                        setclipboard("https://discord.gg/" .. InviteCode)
                    end)
                end
            },
            {
                Icon = "refresh-cw",
                Title = "Update Info",
                Callback = function()
                    xpcall(function()
                        local UpdatedResponse = game:GetService("HttpService"):JSONDecode(WindUI.Creator.Request({
                            Url = DiscordAPI,
                            Method = "GET",
                        }).Body)
                        if UpdatedResponse and UpdatedResponse.guild then
                            DiscordInfo:SetDesc(
                                ' <font color="#52525b">•</font> Member Count: ' .. tostring(UpdatedResponse.approximate_member_count) ..
                                '\n <font color="#16a34a">•</font> Online Count: ' .. tostring(UpdatedResponse.approximate_presence_count)
                            )
                        end
                    end, function(err)
                        warn("err updating discord info: " .. tostring(err))
                    end)
                end
            }
        }

    })

    if Response.guild.banner then
        ParagraphConfig.Thumbnail = "https://cdn.discordapp.com/banners/" .. Response.guild.id .. "/" .. Response.guild.banner .. ".png?size=256"
        ParagraphConfig.ThumbnailSize = 80
    end
    
    local DiscordInfo = Info:Paragraph(ParagraphConfig)
else
    Info:Paragraph({
        Title = "Error when receiving information about the Discord server",
        Desc = ErrorMessage or "Unknown error occurred",
        Image = "triangle-alert",
        ImageSize = 26,
        Color = "Red",
    })
end

-- Main Tab
local AutoFishTab = Window.Main:Section({
	Title = "Fishing Automation",
	Icon = "fish",
    Opened = true,
})
