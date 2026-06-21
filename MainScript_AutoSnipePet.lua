--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║     GrowGarden2 - SUPER ULTRA Auto Sniper Pet     ║
    ║        Ultimate High-Speed Pet Sniping System      ║
    ╚══════════════════════════════════════════════════════════════╝
    
    Features:
    - Ultra-fast pet detection
    - Direct BuyPrompt triggering (no E key needed)
    - Multi-method purchase attempts
    - Priority sorting (Huge/Big > Rarity > Distance)
    - Real-time stats tracking
]]

-- ============================================
-- CONFIGURATION (with SniperConfig support)
-- ============================================

-- Check for SniperConfig from Loader
if getgenv().SniperConfig then
    local cfg = getgenv().SniperConfig
    getgenv().AutoBuyPets = cfg.Enabled or false
    getgenv().AutoBuyPetsMaxPrice = cfg.MaxPrice or 0
    getgenv().SniperDelay = cfg.SniperDelay or 0.05
    getgenv().RetrySniperPet = cfg.RetryAttempts or 5
    getgenv().SniperRange = cfg.TeleportRange or 100
    
    if cfg.RarityFilter then
        getgenv().AutoBuyPetsRarityFilter = cfg.RarityFilter
    end
else
    getgenv().AutoBuyPets = getgenv().AutoBuyPets or false
    getgenv().AutoBuyPetsMaxPrice = getgenv().AutoBuyPetsMaxPrice or 0
    getgenv().SniperDelay = getgenv().SniperDelay or 0.05
    getgenv().RetrySniperPet = getgenv().RetrySniperPet or 5
    getgenv().SniperRange = getgenv().SniperRange or 100
end

-- Rarity Filter (true = buy, false = skip)
getgenv().AutoBuyPetsRarityFilter = getgenv().AutoBuyPetsRarityFilter or {
    ["Common"] = false,
    ["Uncommon"] = false,
    ["Rare"] = false,
    ["Epic"] = false,
    ["Legendary"] = true,
    ["Mythic"] = true,
    ["Super"] = true,
}

-- ============================================
-- PET DATA (Official from Game Data)
-- ============================================

local PetData = {
    -- Common Pets
    ["Frog"] = { Rarity = "Common", Price = 10000, SpawnChance = 11.9 },
    ["Bunny"] = { Rarity = "Common", Price = 20000, SpawnChance = 11.9 },
    
    -- Uncommon Pets
    ["Owl"] = { Rarity = "Uncommon", Price = 25000, SpawnChance = 7.14 },
    
    -- Rare Pets
    ["Deer"] = { Rarity = "Rare", Price = 50000, SpawnChance = 4.29 },
    
    -- Legendary Pets
    ["Robin"] = { Rarity = "Legendary", Price = 75000, SpawnChance = 2.86 },
    ["Bee"] = { Rarity = "Legendary", Price = 1000000, SpawnChance = 2.38 },
    
    -- Mythic Pets
    ["Monkey"] = { Rarity = "Mythic", Price = 1000000, SpawnChance = 0.2 },
    ["GoldenDragonfly"] = { Rarity = "Mythic", Price = 3000000, SpawnChance = 0.6 },
    ["Golden Dragonfly"] = { Rarity = "Mythic", Price = 3000000, SpawnChance = 0.6 },
    ["Unicorn"] = { Rarity = "Mythic", Price = 4000000, SpawnChance = 0.71 },
    ["Bear"] = { Rarity = "Mythic", Price = 5000000, SpawnChance = 0.225 },
    
    -- Super Pets
    ["Raccoon"] = { Rarity = "Super", Price = 5000000, SpawnChance = 0.24 },
    ["BlackDragon"] = { Rarity = "Super", Price = 1000000, SpawnChance = 0 },
    ["Black Dragon"] = { Rarity = "Super", Price = 1000000, SpawnChance = 0 },
    ["IceSerpent"] = { Rarity = "Super", Price = 20000000, SpawnChance = 0 },
    ["Ice Serpent"] = { Rarity = "Super", Price = 20000000, SpawnChance = 0 },
}

local RARITY_PRIORITY = {
    Common = 1,
    Uncommon = 2,
    Rare = 3,
    Epic = 4,
    Legendary = 5,
    Mythic = 6,
    Super = 7,
    Huge = 10,
    Big = 9,
}

-- Load PetData from game (if available)
task.spawn(function()
    pcall(function()
        local gamePetData = require(game.ReplicatedStorage.SharedData.PetData)
        if gamePetData then
            for petName, petInfo in pairs(gamePetData) do
                if type(petInfo) == "table" and petInfo.Rarity and petInfo.BasePrice then
                    PetData[petName] = {
                        Rarity = petInfo.Rarity,
                        Price = tonumber(petInfo.BasePrice) or 0,
                        SpawnChance = tonumber(petInfo.SpawnChance) or 0,
                        DisplayName = petInfo.DisplayName
                    }
                    -- Also add DisplayName variant
                    if petInfo.DisplayName and petInfo.DisplayName ~= petName then
                        PetData[petInfo.DisplayName] = PetData[petName]
                    end
                end
            end
            print("[Sniper] Loaded " .. (#game.GetChildren(game.ReplicatedStorage.SharedData.PetData) or 0) .. " pets from game data")
        end
    end)
end)

-- ============================================
-- SERVICES
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = nil

pcall(function()
    VirtualInputManager = getsenv and getsenv(game.Players.LocalPlayer).VirtualInputManager
end)

local Player = Players.LocalPlayer

-- ============================================
-- STATE TRACKING
-- ============================================

local SnipedPets = {}
local SnipeStats = {
    TotalSniped = 0,
    TotalSpent = 0,
    TotalMissed = 0,
    TotalAttempts = 0,
    SuccessRate = 0,
}
local AttemptedPets = {}
local IsSniping = false
local PurchaseInProgress = false

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

local function GetSheckles()
    local success, result = pcall(function()
        local leaderstats = Player:FindFirstChild("leaderstats")
        if leaderstats then
            local sheckles = leaderstats:FindFirstChild("Sheckles")
            if sheckles then
                return sheckles.Value
            end
        end
    end)
    return success and result or 0
end

local function FormatNumber(num)
    if not num then return "0" end
    if num >= 1000000000 then
        return string.format("%.1fB", num / 1000000000)
    elseif num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(num)
    end
end

local function IsHugeOrBig(petName)
    if not petName then return false, "Normal" end
    local nameLower = petName:lower()
    if nameLower:find("huge") then
        return true, "Huge"
    elseif nameLower:find("big") then
        return true, "Big"
    end
    return false, "Normal"
end

local function GetPetInfo(petName)
    if not petName then return nil end
    
    -- Direct match
    if PetData[petName] then
        return PetData[petName]
    end
    
    -- Try without space
    local withoutSpace = petName:gsub(" ", "")
    if PetData[withoutSpace] then
        return PetData[withoutSpace]
    end
    
    -- Partial match (case insensitive)
    for name, data in pairs(PetData) do
        if type(name) == "string" then
            if petName:lower():find(name:lower()) or name:lower():find(petName:lower()) then
                return data
            end
        end
    end
    
    return nil
end

-- ============================================
-- TELEPORT SYSTEM (Instant)
-- ============================================

local function InstantTeleport(pos)
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

-- ============================================
-- ULTRA-FAST PET DETECTION
-- ============================================

local function FindWildPets()
    local pets = {}
    
    pcall(function()
        -- Find WildPetSpawns folder
        local map = workspace:FindFirstChild("Map")
        if not map then return end
        
        local wildPetSpawns = map:FindFirstChild("WildPetSpawns")
        if not wildPetSpawns then return end
        
        -- Get all children (pet models)
        for _, petModel in ipairs(wildPetSpawns:GetChildren()) do
            if petModel:IsA("Model") and petModel.Name:find("WildPet") then
                -- Extract pet name from model name (format: WildPet_Type_WildPet_GUID)
                local petName = nil
                local nameParts = string.split(petModel.Name, "_")
                if #nameParts >= 2 then
                    petName = nameParts[2]
                    -- Handle names with spaces (e.g., "GoldenDragonfly" -> "Golden Dragonfly")
                    if petName == "GoldenDragonfly" then
                        petName = "Golden Dragonfly"
                    elseif petName == "BlackDragon" then
                        petName = "Black Dragon"
                    elseif petName == "IceSerpent" then
                        petName = "Ice Serpent"
                    end
                end
                
                -- Find RootPart
                local rootPart = petModel:FindFirstChild("RootPart")
                if not rootPart then
                    rootPart = petModel:FindFirstChild("HumanoidRootPart")
                end
                
                if rootPart and rootPart:IsDescendantOf(workspace) then
                    -- Find BuyPrompt
                    local buyPrompt = rootPart:FindFirstChild("BuyPrompt")
                    
                    -- Get pet info from PetData (supports both formats)
                    local petInfo = GetPetInfo(petName)
                    if not petInfo then
                        -- Try without space
                        petInfo = GetPetInfo(nameParts[2])
                    end
                    
                    local price = petInfo and petInfo.Price or 0
                    local rarity = petInfo and petInfo.Rarity or "Common"
                    
                    table.insert(pets, {
                        Model = petModel,
                        RootPart = rootPart,
                        BuyPrompt = buyPrompt,
                        PetName = petName or "Unknown",
                        PetInfo = petInfo,
                        Price = price,
                        Rarity = rarity,
                        Position = rootPart.Position,
                        SpawnTime = 0,
                    })
                end
            end
        end
    end)
    
    return pets
end

-- ============================================
-- CONFIGURATION CHECK
-- ============================================

local function ShouldBuyPet(petName, petInfo, price)
    -- Check for Huge/Big (absolute priority)
    local isHugeOrBig, specialType = IsHugeOrBig(petName)
    if isHugeOrBig then
        return true, true, specialType
    end
    
    -- Check rarity filter
    if petInfo then
        local rarity = petInfo.Rarity
        if getgenv().AutoBuyPetsRarityFilter[rarity] == false then
            return false, false, "Normal"
        end
    end
    
    -- Check price filter
    local maxPrice = getgenv().AutoBuyPetsMaxPrice
    if maxPrice > 0 and price > maxPrice then
        return false, false, "Normal"
    end
    
    return true, false, "Normal"
end

-- ============================================
-- ULTRA-FAST PURCHASE SYSTEM
-- ============================================

local function ExecutePurchase(pet)
    local model = pet.Model
    local petName = pet.PetName
    local buyPrompt = pet.BuyPrompt
    
    if not model then return false end
    
    -- Find RootPart
    local rootPart = model:FindFirstChild("RootPart") or model:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    -- Find BuyPrompt if not cached
    if not buyPrompt then
        buyPrompt = rootPart:FindFirstChild("BuyPrompt")
    end
    
    if not buyPrompt then
        return false
    end
    
    -- Maximize activation distance
    pcall(function()
        buyPrompt.MaxActivationDistance = 200
        buyPrompt.Enabled = true
    end)
    
    -- ULTRA-RAPID PURCHASE ATTEMPTS (30 attempts in 0.1s)
    for attempt = 1, 30 do
        -- Check if pet was purchased
        if not model:IsDescendantOf(workspace) then
            return true
        end
        
        -- METHOD 1: Direct Trigger() - fastest
        pcall(function()
            if buyPrompt.Trigger then
                buyPrompt:Trigger()
            end
        end)
        
        -- METHOD 2: Firesignal Triggered event
        pcall(function()
            if buyPrompt.Triggered then
                firesignal(buyPrompt.Triggered)
            end
        end)
        
        -- METHOD 3: Complete lifecycle
        pcall(function()
            local btn = buyPrompt.PromptButtonFrame
            if btn then
                local keyCode = buyPrompt.KeyboardKeyCode or Enum.KeyCode.E
                if btn.InputBegan then
                    firesignal(btn.InputBegan, btn, Enum.UserInputType.Keyboard, keyCode)
                end
                if buyPrompt.Triggered then
                    firesignal(buyPrompt.Triggered)
                end
                if btn.InputEnded then
                    firesignal(btn.InputEnded, btn, Enum.UserInputType.Keyboard, keyCode)
                end
            end
        end)
        
        -- METHOD 4: VirtualInputManager
        pcall(function()
            if VirtualInputManager then
                local keyCode = buyPrompt.KeyboardKeyCode or Enum.KeyCode.E
                VirtualInputManager:SendKeyDown(keyCode)
                task.wait(0.001)
                VirtualInputManager:SendKeyUp(keyCode)
            end
        end)
        
        -- METHOD 5: Fire to Packet Remote
        pcall(function()
            local sharedModules = ReplicatedStorage:FindFirstChild("SharedModules")
            if sharedModules then
                local packetFolder = sharedModules:FindFirstChild("Packet")
                if packetFolder then
                    local packetRemote = packetFolder:FindFirstChild("RemoteEvent")
                    if packetRemote then
                        -- Try various formats
                        local guid = string.match(model.Name, "[%w-]+$")
                        packetRemote:FireServer(guid)
                        packetRemote:FireServer(petName)
                    end
                end
            end
        end)
    end
    
    -- Final check
    task.wait(0.01)
    return not model:IsDescendantOf(workspace)
end

-- ============================================
-- PURCHASE WRAPPER WITH RETRY
-- ============================================

local function TryPurchasePet(pet)
    if not pet or not pet.Model then
        return false
    end
    
    -- Check if already despawned
    if not pet.Model:IsDescendantOf(workspace) then
        return true
    end
    
    -- Prevent concurrent purchases
    if PurchaseInProgress then
        return false
    end
    PurchaseInProgress = true
    
    -- Teleport to pet
    InstantTeleport(pet.Position + Vector3.new(0, 3, 0))
    task.wait(0.02)
    
    -- Rapid purchase attempts with retries
    local maxRetries = getgenv().RetrySniperPet or 5
    
    for retry = 1, maxRetries do
        -- Check if pet still exists
        if not pet.Model:IsDescendantOf(workspace) then
            PurchaseInProgress = false
            return true
        end
        
        if ExecutePurchase(pet) then
            PurchaseInProgress = false
            return true
        end
        
        task.wait(0.01)
    end
    
    PurchaseInProgress = false
    return false
end

-- ============================================
-- MAIN SNIPER LOOP
-- ============================================

local function StartSniperLoop()
    if IsSniping then return end
    
    IsSniping = true
    getgenv().AutoBuyPets = true
    
    print("═══════════════════════════════════════════════════")
    print("   🏹 SUPER ULTRA Pet Sniper Started!")
    print("═══════════════════════════════════════════════════")
    print("   Max Price: " .. FormatNumber(getgenv().AutoBuyPetsMaxPrice))
    print("   Retry: " .. (getgenv().RetrySniperPet or 5))
    print("   Range: " .. (getgenv().SniperRange or 100))
    print("═══════════════════════════════════════════════════")
    
    task.spawn(function()
        while IsSniping and getgenv().AutoBuyPets do
            pcall(function()
                -- Find all wild pets
                local pets = FindWildPets()
                
                if #pets == 0 then
                    task.wait(0.1)
                    return
                end
                
                -- Get player position
                local character = Player.Character
                if not character then
                    task.wait(0.1)
                    return
                end
                
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if not hrp then
                    task.wait(0.1)
                    return
                end
                
                -- Sort pets by priority
                table.sort(pets, function(a, b)
                    -- Huge/Big first
                    local aIsHuge, aType = IsHugeOrBig(a.PetName)
                    local bIsHuge, bType = IsHugeOrBig(b.PetName)
                    if aIsHuge and not bIsHuge then return true end
                    if not aIsHuge and bIsHuge then return false end
                    
                    -- Then by rarity
                    local rarityA = RARITY_PRIORITY[a.Rarity] or 0
                    local rarityB = RARITY_PRIORITY[b.Rarity] or 0
                    if rarityA ~= rarityB then
                        return rarityA > rarityB
                    end
                    
                    -- Then by distance (closer first)
                    local distA = (hrp.Position - a.Position).Magnitude
                    local distB = (hrp.Position - b.Position).Magnitude
                    return distA < distB
                end)
                
                -- Process pets
                for _, pet in ipairs(pets) do
                    if not IsSniping or not getgenv().AutoBuyPets then
                        break
                    end
                    
                    -- Verify pet still exists
                    if not pet.Model or not pet.Model:IsDescendantOf(workspace) then
                        continue
                    end
                    
                    -- Check if should buy
                    local shouldBuy, isHugeOrBig, specialType = ShouldBuyPet(pet.PetName, pet.PetInfo, pet.Price)
                    
                    if not shouldBuy then
                        continue
                    end
                    
                    -- Calculate distance
                    local distance = (hrp.Position - pet.Position).Magnitude
                    
                    -- Log purchase attempt
                    local prefix = isHugeOrBig and "🚀" or "🎯"
                    local specialStr = isHugeOrBig and (" [" .. specialType .. "]") or ""
                    print(prefix .. " SNIPING" .. specialStr .. ": " .. pet.PetName .. " [" .. pet.Rarity .. "] - " .. FormatNumber(pet.Price))
                    
                    SnipeStats.TotalAttempts = SnipeStats.TotalAttempts + 1
                    
                    -- Attempt purchase
                    local startTime = tick()
                    local success = TryPurchasePet(pet)
                    local purchaseTime = (tick() - startTime) * 1000
                    
                    if success then
                        SnipeStats.TotalSniped = SnipeStats.TotalSniped + 1
                        if pet.Price > 0 then
                            SnipeStats.TotalSpent = SnipeStats.TotalSpent + pet.Price
                        end
                        
                        table.insert(SnipedPets, {
                            Name = pet.PetName,
                            Rarity = pet.Rarity,
                            Price = pet.Price,
                            Time = os.date("%H:%M:%S"),
                        })
                        
                        print("✅ SUCCESS! " .. pet.PetName .. " [" .. pet.Rarity .. "] - " .. FormatNumber(pet.Price) .. " (" .. string.format("%.1fms", purchaseTime) .. ")")
                    else
                        SnipeStats.TotalMissed = SnipeStats.TotalMissed + 1
                        print("❌ MISSED: " .. pet.PetName)
                    end
                    
                    -- Update success rate
                    if SnipeStats.TotalAttempts > 0 then
                        SnipeStats.SuccessRate = (SnipeStats.TotalSniped / SnipeStats.TotalAttempts) * 100
                    end
                    
                    -- Small delay between purchases
                    task.wait(getgenv().SniperDelay or 0.05)
                end
            end)
            
            task.wait(0.05)
        end
        
        IsSniping = false
        print("═══════════════════════════════════════════════════")
        print("   🏹 Pet Sniper Stopped!")
        print("═══════════════════════════════════════════════════")
    end)
end

local function StopSniperLoop()
    IsSniping = false
    getgenv().AutoBuyPets = false
    print("[Sniper] Stopped!")
end

-- ============================================
-- API FUNCTIONS
-- ============================================

getgenv().StartPetSniper = StartSniperLoop
getgenv().StopPetSniper = StopSniperLoop
getgenv().TogglePetSniper = function()
    if IsSniping then
        StopSniperLoop()
    else
        StartSniperLoop()
    end
end

getgenv().GetSniperStats = function()
    return {
        IsRunning = IsSniping,
        TotalSniped = SnipeStats.TotalSniped,
        TotalSpent = SnipeStats.TotalSpent,
        TotalMissed = SnipeStats.TotalMissed,
        TotalAttempts = SnipeStats.TotalAttempts,
        SuccessRate = SnipeStats.SuccessRate,
        CurrentSheckles = GetSheckles(),
        RecentPets = SnipedPets,
    }
end

-- ============================================
-- CUSTOM CONFIG FUNCTION
-- ============================================

getgenv().ConfigureSniper = function(config)
    if not config then return end
    
    if config.Enabled ~= nil then getgenv().AutoBuyPets = config.Enabled end
    if config.MaxPrice ~= nil then getgenv().AutoBuyPetsMaxPrice = config.MaxPrice end
    if config.SniperDelay ~= nil then getgenv().SniperDelay = config.SniperDelay end
    if config.RetryAttempts ~= nil then getgenv().RetrySniperPet = config.RetryAttempts end
    if config.TeleportRange ~= nil then getgenv().SniperRange = config.TeleportRange end
    if config.RarityFilter ~= nil then
        for rarity, enabled in pairs(config.RarityFilter) do
            getgenv().AutoBuyPetsRarityFilter[rarity] = enabled
        end
    end
    
    print("[Sniper] Configuration updated!")
    print("   Enabled: " .. tostring(getgenv().AutoBuyPets))
    print("   Max Price: " .. FormatNumber(getgenv().AutoBuyPetsMaxPrice))
    print("   Mythic: " .. tostring(getgenv().AutoBuyPetsRarityFilter["Mythic"]))
    print("   Super: " .. tostring(getgenv().AutoBuyPetsRarityFilter["Super"]))
end

-- ============================================
-- AUTO-START
-- ============================================

if getgenv().AutoBuyPets then
    StartSniperLoop()
end

print([[
╔══════════════════════════════════════════════════════════════╗
║        GrowGarden2 - SUPER ULTRA Pet Sniper Loaded!       ║
╠══════════════════════════════════════════════════════════════╣
║  COMMANDS:                                                 ║
║  • getgenv().StartPetSniper()  - Start sniping           ║
║  • getgenv().StopPetSniper()   - Stop sniping            ║
║  • getgenv().TogglePetSniper() - Toggle sniping           ║
║  • getgenv().GetSniperStats()  - Get statistics          ║
║                                                              ║
║  CONFIG:                                                    ║
║  • getgenv().AutoBuyPets = true/false                    ║
║  • getgenv().AutoBuyPetsMaxPrice = 0                      ║
║  • getgenv().SniperDelay = 0.05                           ║
║  • getgenv().RetrySniperPet = 5                           ║
║  • getgenv().SniperRange = 100                           ║
╚══════════════════════════════════════════════════════════════╝
]])
