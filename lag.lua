-- Script Anti Lag untuk Roblox
-- Paste script ini di Executor kalian

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Terrain = workspace.Terrain
local RunService = game:GetService("RunService")

print("=== Anti Lag Script Loading ===")

-- Fungsi untuk mengoptimalkan grafis
local function OptimizeGraphics()
    print("Mengoptimalkan Grafis...")
    
    -- Kurangi kualitas lighting
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("BloomEffect") or 
           effect:IsA("BlurEffect") or 
           effect:IsA("ColorCorrectionEffect") or 
           effect:IsA("DepthOfFieldEffect") or
           effect:IsA("SunRaysEffect") then
            effect.Enabled = false
        end
    end
    
    -- Setting lighting sederhana
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 0
    
    -- Optimalkan terrain
    Terrain.WaterWaveSize = 0
    Terrain.WaterWaveSpeed = 0
    Terrain.WaterReflectance = 0
    Terrain.WaterTransparency = 0
    
    settings().Rendering.QualityLevel = 1
end

-- Fungsi untuk menghapus objek yang tidak perlu
local function RemoveUnnecessaryObjects()
    print("Menghapus objek tidak penting...")
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or 
           obj:IsA("Trail") or 
           obj:IsA("Smoke") or 
           obj:IsA("Fire") or
           obj:IsA("Sparkles") then
            obj.Enabled = false
        end
        
        -- Hapus decals dan textures
        if obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        end
    end
end

-- Fungsi untuk optimasi karakter
local function OptimizeCharacter(character)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Material = Enum.Material.SmoothPlastic
            part.Reflectance = 0
        elseif part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 1
        end
    end
end

-- Fungsi untuk optimasi objek baru
local function OptimizeNewObjects(obj)
    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
        obj.Enabled = false
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        obj.Transparency = 1
    elseif obj:IsA("BasePart") then
        obj.Material = Enum.Material.SmoothPlastic
        obj.Reflectance = 0
    end
end

-- Apply optimasi awal
OptimizeGraphics()
RemoveUnnecessaryObjects()

-- Optimasi karakter player
local player = Players.LocalPlayer
if player.Character then
    OptimizeCharacter(player.Character)
end

-- Monitor karakter baru
player.CharacterAdded:Connect(function(character)
    wait(0.5)
    OptimizeCharacter(character)
end)

-- Monitor objek baru yang ditambahkan
workspace.DescendantAdded:Connect(function(obj)
    OptimizeNewObjects(obj)
end)

-- FPS Booster dengan Connection Management
local connections = {}
for _, connection in pairs(getconnections(RunService.Heartbeat)) do
    if connection.Enabled and not connection.Foreign then
        connection:Disable()
        table.insert(connections, connection)
    end
end

-- Garbage Collection periodik
spawn(function()
    while wait(60) do
        pcall(function()
            for i = 1, 10 do
                game:GetService("RunService").Heartbeat:Wait()
            end
        end)
    end
end)

print("=== Anti Lag Script Loaded Successfully! ===")
print("FPS Boost: Aktif")
print("Graphics: Optimized")
print("Effects: Disabled")

-- Notifikasi
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Anti Lag";
    Text = "Script berhasil dimuat!";
    Duration = 5;
})
