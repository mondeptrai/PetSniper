--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║           GrowGarden2 - Auto Sniper Pet (Standalone)    ║
    ║              High-Speed Pet Sniping System               ║
    ╚══════════════════════════════════════════════════════════════╝
    
    CONFIGURATION: Modify the _G settings below to customize behavior
]]

-- ============================================
-- CONFIGURATION LOADER (ConfigLoaderSnipePet)
-- ============================================

-- Master toggle for auto pet sniping
getgenv().AutoBuyPets = getgenv().AutoBuyPets or false

-- Maximum price to pay for a pet (0 = no limit)
getgenv().AutoBuyPetsMaxPrice = getgenv().AutoBuyPetsMaxPrice or 0

-- Rarity filter: Only buy pets of these rarities (true = enabled, false = disabled)
-- Example: Only buy Mythic and Super pets
getgenv().AutoBuyPetsRarityFilter = getgenv().AutoBuyPetsRarityFilter or {
    ["Common"] = false,
    ["Uncommon"] = false,
    ["Rare"] = false,
    ["Epic"] = false,
    ["Legendary"] = false,
    ["Mythic"] = true,
    ["Super"] = true,
}

-- Specific pet names to filter (if empty, buy any pet that passes rarity/price)
-- Example: {"Frog", "Bunny", "Owl"} - only buy these pets
getgenv().PetFilter = getgenv().PetFilter or {}

-- Delay between purchase attempts (prevents spam/detection)
getgenv().SniperDelay = getgenv().SniperDelay or 0.1

-- Max retry attempts if purchase fails
getgenv().RetrySniperPet = getgenv().RetrySniperPet or 3

-- Teleport range (how close player needs to be)
getgenv().SniperRange = getgenv().SniperRange or 50

-- ============================================
-- PET DATA (Reference Table)
-- ============================================

local PetData = {
    ["Frog"] = { Rarity = "Common", Price = 10000 },
    ["Bunny"] = { Rarity = "Common", Price = 20000 },
    ["Owl"] = { Rarity = "Uncommon", Price = 25000 },
    ["Deer"] = { Rarity = "Rare", Price = 50000 },
    ["Robin"] = { Rarity = "Legendary", Price = 75000 },
    ["Bee"] = { Rarity = "Legendary", Price = 1000000 },
    ["Monkey"] = { Rarity = "Mythic", Price = 3000000 },
    ["Bear"] = { Rarity = "Mythic", Price = 5000000 },
    ["Golden Dragonfly"] = { Rarity = "Mythic", Price = 9000000 },
    ["Unicorn"] = { Rarity = "Mythic", Price = 12000000 },
    ["Raccoon"] = { Rarity = "Super", Price = 15000000 },
    ["Black Dragon"] = { Rarity = "Super", Price = 1000000 },
}

-- Rarity priority (higher = more valuable)
local RARITY_PRIORITY = {
    Common = 1,
    Uncommon = 2,
    Rare = 3,
    Epic = 4,
    Legendary = 5,
    Mythic = 6,
    Super = 7,
}

-- ============================================
-- SERVICES
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ============================================
-- STATE TRACKING
-- ============================================

local ActivePets = {} -- Currently spawned pets
local SnipedPets = {} -- Successfully sniped pets this session
local LastSnipeTime = 0
local IsSniping = false
local SnipeStats = {
    TotalSniped = 0,
    TotalSpent = 0,
    TotalMissed = 0,
}

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

local function GetSheckles()
    pcall(function()
        local leaderstats = Player:FindFirstChild("leaderstats")
        if leaderstats then
            local sheckles = leaderstats:FindFirstChild("Sheckles")
            if sheckles then
                return sheckles.Value
            end
        end
    end)
    return 0
end

local function FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(num)
    end
end

local function TeleportTo(pos)
    pcall(function()
        local character = Player.Character
        if character then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(pos)
            end
        end
    end)
end

local function IsHugeOrBig(petName)
    if not petName then return false end
    local nameLower = petName:lower()
    return nameLower:find("huge") or nameLower:find("big")
end

local function GetPetInfo(petName)
    -- First check PetData table
    if PetData[petName] then
        return PetData[petName]
    end
    
    -- Fallback: Try to find partial match
    for name, data in pairs(PetData) do
        if petName:lower():find(name:lower()) then
            return data
        end
    end
    
    return nil
end

local function GetPetPriceFromPrompt(prompt)
    if not prompt then return 0 end
    local objectText = prompt.ObjectText or ""
    local priceStr = objectText:gsub(",", ""):gsub("%$", "")
    local price = tonumber(priceStr:match("%d+")) or 0
    return price
end

-- ============================================
-- CONFIGURATION CHECK FUNCTIONS
-- ============================================

local function ShouldBuyPet(petName, petInfo, price)
    -- Check for Huge/Big (absolute priority)
    if IsHugeOrBig(petName) then
        print("[Sniper] Detected HUGE/BIG pet: " .. petName .. " - PRIORITY BUY!")
        return true, true -- (shouldBuy, isHugeOrBig)
    end
    
    -- Check specific pet filter
    if next(getgenv().PetFilter) then
        local found = false
        for _, filterName in ipairs(getgenv().PetFilter) do
            if petName:lower() == filterName:lower() then
                found = true
                break
            end
        end
        if not found then
            return false, false
        end
    end
    
    -- Check rarity filter
    if petInfo then
        local rarity = petInfo.Rarity
        local rarityEnabled = getgenv().AutoBuyPetsRarityFilter[rarity]
        if rarityEnabled == false then
            return false, false
        end
    end
    
    -- Check price filter (0 = no limit)
    local maxPrice = getgenv().AutoBuyPetsMaxPrice
    if maxPrice > 0 and price > maxPrice then
        return false, false
    end
    
    return true, false
end

-- ============================================
-- PET DETECTION (Mainscript_AutoSnipePet)
-- ============================================

local function FindWildPets()
    local pets = {}
    
    pcall(function()
        -- Try common spawn locations
        local spawnLocations = {
            workspace.Map and workspace.Map:FindFirstChild("WildPetSpawns"),
            workspace:FindFirstChild("WildPetSpawns"),
            workspace.Map and workspace.Map:FindFirstChild("WildPets"),
        }
        
        for _, spawnFolder in ipairs(spawnLocations) do
            if spawnFolder and spawnFolder:IsA("Folder") or spawnFolder:IsA("Model") then
                for _, obj in pairs(spawnFolder:GetChildren()) do
                    if obj:IsA("Model") and obj.Name:find("WildPet") then
                        local petName = obj:GetAttribute("PetName")
                        local rootPart = obj:FindFirstChild("RootPart")
                        
                        if rootPart and rootPart:IsDescendantOf(workspace) then
                            local prompt = rootPart:FindFirstChildWhichIsA("ProximityPrompt")
                            local price = prompt and GetPetPriceFromPrompt(prompt) or 0
                            
                            -- Get pet info from our data or from prompt
                            local petInfo = GetPetInfo(petName)
                            if not petInfo and price > 0 then
                                -- Try to infer from price
                                for name, data in pairs(PetData) do
                                    if data.Price == price then
                                        petInfo = data
                                        petName = name
                                        break
                                    end
                                end
                            end
                            
                            table.insert(pets, {
                                Model = obj,
                                RootPart = rootPart,
                                PetName = petName or "Unknown",
                                PetInfo = petInfo,
                                Price = price,
                                Prompt = prompt,
                                Position = rootPart.Position,
                                SpawnTime = tick(),
                            })
                        end
                    end
                end
            end
        end
    end)
    
    return pets
end

-- ============================================
-- PURCHASE EXECUTION
-- ============================================

local function FireProximityPrompt(prompt)
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
        else
            -- Alternative method using VirtualInputManager
            if prompt and prompt:IsA("ProximityPrompt") then
                firesignal(prompt.PromptButtonFrame.Triggered)
            end
        end
    end)
end

local function TryPurchasePet(pet, retryCount)
    retryCount = retryCount or 0
    
    pcall(function()
        -- Teleport to pet
        local targetPos = pet.Position + Vector3.new(0, 3, 0)
        TeleportTo(targetPos)
        
        -- Small delay to ensure teleportation
        task.wait(0.02)
        
        -- Try to fire proximity prompt
        if pet.Prompt then
            FireProximityPrompt(pet.Prompt)
        end
    end)
    
    -- Wait for sniper delay
    task.wait(getgenv().SniperDelay or 0.1)
    
    -- Check if pet was successfully purchased (no longer in workspace)
    local stillExists = pet.Model and pet.Model:IsDescendantOf(workspace)
    
    if not stillExists then
        return true -- Successfully purchased
    elseif retryCount < getgenv().RetrySniperPet then
        -- Retry
        return TryPurchasePet(pet, retryCount + 1)
    end
    
    return false -- Failed
end

-- ============================================
-- MAIN SNIPER LOOP
-- ============================================

local function StartSniperLoop()
    IsSniping = true
    print("[Sniper] Auto Sniper Pet started!")
    print("[Sniper] Config - MaxPrice: " .. getgenv().AutoBuyPetsMaxPrice .. ", Delay: " .. getgenv().SniperDelay)
    
    task.spawn(function()
        while IsSniping and getgenv().AutoBuyPets do
            pcall(function()
                -- Check if main toggle is enabled
                if not getgenv().AutoBuyPets then
                    task.wait(0.5)
                    return
                end
                
                -- Find all wild pets
                local pets = FindWildPets()
                
                if #pets == 0 then
                    task.wait(0.3)
                    return
                end
                
                -- Get player position
                local character = Player.Character
                if not character then
                    task.wait(0.3)
                    return
                end
                
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if not hrp then
                    task.wait(0.3)
                    return
                end
                
                -- Sort pets by priority (Huge/Big > High rarity > Close distance)
                table.sort(pets, function(a, b)
                    local aIsSpecial = IsHugeOrBig(a.PetName)
                    local bIsSpecial = IsHugeOrBig(b.PetName)
                    
                    if aIsSpecial and not bIsSpecial then return true end
                    if not aIsSpecial and bIsSpecial then return false end
                    
                    -- Then by rarity
                    local rarityA = RARITY_PRIORITY[a.PetInfo and a.PetInfo.Rarity or "Common"] or 0
                    local rarityB = RARITY_PRIORITY[b.PetInfo and b.PetInfo.Rarity or "Common"] or 0
                    if rarityA ~= rarityB then
                        return rarityA > rarityB
                    end
                    
                    -- Then by distance
                    local distA = (hrp.Position - a.Position).Magnitude
                    local distB = (hrp.Position - b.Position).Magnitude
                    return distA < distB
                end)
                
                -- Process each pet
                for _, pet in ipairs(pets) do
                    if not IsSniping or not getgenv().AutoBuyPets then
                        break
                    end
                    
                    -- Check if pet is still valid
                    if pet.Model and pet.Model:IsDescendantOf(workspace) then
                        local shouldBuy, isHugeOrBig = ShouldBuyPet(pet.PetName, pet.PetInfo, pet.Price)
                        
                        if shouldBuy then
                            local distance = (hrp.Position - pet.Position).Magnitude
                            local petRarity = pet.PetInfo and pet.PetInfo.Rarity or "Unknown"
                            local petPrice = pet.Price > 0 and pet.Price or (pet.PetInfo and pet.PetInfo.Price) or 0
                            
                            -- Log attempt
                            if isHugeOrBig then
                                print("[Sniper] 🚀 SNIPING HUGE/BIG PET: " .. pet.PetName .. " (Rarity: " .. petRarity .. ", Price: " .. petPrice .. ")")
                            else
                                print("[Sniper] 🎯 Sniping: " .. pet.PetName .. " [Rarity: " .. petRarity .. ", Price: " .. petPrice .. "]")
                            end
                            
                            -- Teleport if needed
                            if distance > (getgenv().SniperRange or 50) then
                                TeleportTo(pet.Position + Vector3.new(0, 3, 0))
                                task.wait(0.05)
                            end
                            
                            -- Attempt purchase
                            local success = TryPurchasePet(pet, 0)
                            
                            if success then
                                SnipeStats.TotalSniped = SnipeStats.TotalSniped + 1
                                if petPrice > 0 then
                                    SnipeStats.TotalSpent = SnipeStats.TotalSpent + petPrice
                                end
                                table.insert(SnipedPets, {
                                    Name = pet.PetName,
                                    Rarity = petRarity,
                                    Price = petPrice,
                                    Time = os.date("%H:%M:%S"),
                                })
                                print("[Sniper] ✅ Successfully sniped: " .. pet.PetName)
                            else
                                SnipeStats.TotalMissed = SnipeStats.TotalMissed + 1
                                print("[Sniper] ❌ Failed to snipe: " .. pet.PetName)
                            end
                            
                            -- Small delay between purchases
                            task.wait(getgenv().SniperDelay or 0.1)
                        end
                    end
                end
            end)
            
            -- Small loop delay
            task.wait(0.1)
        end
        
        IsSniping = false
        print("[Sniper] Auto Sniper Pet stopped!")
    end)
end

local function StopSniperLoop()
    IsSniping = false
    getgenv().AutoBuyPets = false
    print("[Sniper] Sniper stopped!")
end

local function GetSniperStats()
    return {
        IsRunning = IsSniping,
        TotalSniped = SnipeStats.TotalSniped,
        TotalSpent = SnipeStats.TotalSpent,
        TotalMissed = SnipeStats.TotalMissed,
        CurrentSheckles = GetSheckles(),
        RecentPets = SnipedPets,
    }
end

-- ============================================
-- UI CREATION (Optional Status Display)
-- ============================================

local function CreateSniperUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "GrowGarden2_SniperUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = PlayerGui
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "SniperPanel"
    MainFrame.Size = UDim2.new(0, 300, 0, 180)
    MainFrame.Position = UDim2.new(0.01, 0, 0.7, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    MainFrame.BackgroundTransparency = 0.1
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = MainFrame
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(80, 80, 120)
    Stroke.Thickness = 1
    Stroke.Parent = MainFrame
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundTransparency = 1
    Title.Text = "🎯 Pet Sniper Status"
    Title.TextColor3 = Color3.fromRGB(255, 200, 75)
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.Parent = MainFrame
    
    local StatusText = Instance.new("TextLabel")
    StatusText.Name = "StatusText"
    StatusText.Size = UDim2.new(1, -20, 0, 20)
    StatusText.Position = UDim2.new(0, 10, 0, 35)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "⏸️ Stopped"
    StatusText.TextColor3 = Color3.fromRGB(150, 150, 170)
    StatusText.TextSize = 12
    StatusText.Font = Enum.Font.Gotham
    StatusText.TextXAlignment = Enum.TextXAlignment.Left
    StatusText.Parent = MainFrame
    
    local SnipedText = Instance.new("TextLabel")
    SnipedText.Name = "SnipedText"
    SnipedText.Size = UDim2.new(1, -20, 0, 20)
    SnipedText.Position = UDim2.new(0, 10, 0, 55)
    SnipedText.BackgroundTransparency = 1
    SnipedText.Text = "🐾 Sniped: 0"
    SnipedText.TextColor3 = Color3.fromRGB(100, 255, 150)
    SnipedText.TextSize = 12
    SnipedText.Font = Enum.Font.Gotham
    SnipedText.TextXAlignment = Enum.TextXAlignment.Left
    SnipedText.Parent = MainFrame
    
    local SpentText = Instance.new("TextLabel")
    SpentText.Name = "SpentText"
    SpentText.Size = UDim2.new(1, -20, 0, 20)
    SpentText.Position = UDim2.new(0, 10, 0, 75)
    SpentText.BackgroundTransparency = 1
    SpentText.Text = "💰 Spent: 0"
    SpentText.TextColor3 = Color3.fromRGB(255, 215, 0)
    SpentText.TextSize = 12
    SpentText.Font = Enum.Font.Gotham
    SpentText.TextXAlignment = Enum.TextXAlignment.Left
    SpentText.Parent = MainFrame
    
    local MissedText = Instance.new("TextLabel")
    MissedText.Name = "MissedText"
    MissedText.Size = UDim2.new(1, -20, 0, 20)
    MissedText.Position = UDim2.new(0, 10, 0, 95)
    MissedText.BackgroundTransparency = 1
    MissedText.Text = "❌ Missed: 0"
    MissedText.TextColor3 = Color3.fromRGB(255, 100, 100)
    MissedText.TextSize = 12
    MissedText.Font = Enum.Font.Gotham
    MissedText.TextXAlignment = Enum.TextXAlignment.Left
    MissedText.Parent = MainFrame
    
    local ShecklesText = Instance.new("TextLabel")
    ShecklesText.Name = "ShecklesText"
    ShecklesText.Size = UDim2.new(1, -20, 0, 20)
    ShecklesText.Position = UDim2.new(0, 10, 0, 115)
    ShecklesText.BackgroundTransparency = 1
    ShecklesText.Text = "💎 Sheckles: Loading..."
    ShecklesText.TextColor3 = Color3.fromRGB(180, 180, 200)
    ShecklesText.TextSize = 12
    ShecklesText.Font = Enum.Font.Gotham
    ShecklesText.TextXAlignment = Enum.TextXAlignment.Left
    ShecklesText.Parent = MainFrame
    
    local LastPetText = Instance.new("TextLabel")
    LastPetText.Name = "LastPetText"
    LastPetText.Size = UDim2.new(1, -20, 0, 20)
    LastPetText.Position = UDim2.new(0, 10, 0, 135)
    LastPetText.BackgroundTransparency = 1
    LastPetText.Text = "✨ Last: None"
    LastPetText.TextColor3 = Color3.fromRGB(200, 150, 255)
    LastPetText.TextSize = 12
    LastPetText.Font = Enum.Font.Gotham
    LastPetText.TextXAlignment = Enum.TextXAlignment.Left
    LastPetText.Parent = MainFrame
    
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 25, 0, 25)
    CloseButton.Position = UDim2.new(1, -30, 0, 5)
    CloseButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 12
    CloseButton.Parent = MainFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = CloseButton
    
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    
    return ScreenGui
end

local SniperGui = nil

local function UpdateSniperUI()
    if not SniperGui then
        SniperGui = CreateSniperUI()
    end
    
    local panel = SniperGui:FindFirstChild("SniperPanel")
    if not panel then return end
    
    local stats = GetSniperStats()
    
    local statusText = panel:FindFirstChild("StatusText")
    local snipedText = panel:FindFirstChild("SnipedText")
    local spentText = panel:FindFirstChild("SpentText")
    local missedText = panel:FindFirstChild("MissedText")
    local shecklesText = panel:FindFirstChild("ShecklesText")
    local lastPetText = panel:FindFirstChild("LastPetText")
    
    if statusText then
        statusText.Text = stats.IsRunning and "▶️ Running..." or "⏸️ Stopped"
        statusText.TextColor3 = stats.IsRunning and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(150, 150, 170)
    end
    
    if snipedText then
        snipedText.Text = "🐾 Sniped: " .. stats.TotalSniped
    end
    
    if spentText then
        spentText.Text = "💰 Spent: " .. FormatNumber(stats.TotalSpent)
    end
    
    if missedText then
        missedText.Text = "❌ Missed: " .. stats.TotalMissed
    end
    
    if shecklesText then
        shecklesText.Text = "💎 Sheckles: " .. FormatNumber(stats.CurrentSheckles)
    end
    
    if lastPetText and #stats.RecentPets > 0 then
        local last = stats.RecentPets[#stats.RecentPets]
        lastPetText.Text = "✨ Last: " .. last.Rarity .. " " .. last.Name
    end
end

-- Update UI periodically
task.spawn(function()
    while true do
        pcall(UpdateSniperUI)
        task.wait(1)
    end
end)

-- ============================================
-- COMMANDS / API
-- ============================================

-- Start the sniper
getgenv().StartPetSniper = function()
    if not getgenv().AutoBuyPets then
        getgenv().AutoBuyPets = true
        StartSniperLoop()
        print("[Sniper] Started! Toggle: true")
    end
end

-- Stop the sniper
getgenv().StopPetSniper = function()
    StopSniperLoop()
    print("[Sniper] Stopped!")
end

-- Toggle the sniper
getgenv().TogglePetSniper = function()
    if getgenv().AutoBuyPets then
        getgenv().StopPetSniper()
    else
        getgenv().StartPetSniper()
    end
end

-- Get sniper stats
getgenv().GetSniperStats = GetSniperStats

-- ============================================
-- INITIALIZATION
-- ============================================

print([[
╔══════════════════════════════════════════════════════════════╗
║           GrowGarden2 - Auto Sniper Pet Loaded!              ║
╠══════════════════════════════════════════════════════════════╣
║  COMMANDS:                                                   ║
║  - getgenv().StartPetSniper()  - Start sniping              ║
║  - getgenv().StopPetSniper()   - Stop sniping               ║
║  - getgenv().TogglePetSniper() - Toggle sniping              ║
║  - getgenv().GetSniperStats() - Get statistics              ║
║                                                              ║
║  CONFIGURATION (modify these globals):                        ║
║  - getgenv().AutoBuyPets = true/false                        ║
║  - getgenv().AutoBuyPetsMaxPrice = 0 (0 = no limit)         ║
║  - getgenv().AutoBuyPetsRarityFilter = {...}                 ║
║  - getgenv().PetFilter = {} (empty = all pets)               ║
║  - getgenv().SniperDelay = 0.1                               ║
║  - getgenv().RetrySniperPet = 3                              ║
╚══════════════════════════════════════════════════════════════╝
]])

-- Auto-start if enabled in config
if getgenv().AutoBuyPets then
    StartSniperLoop()
end
