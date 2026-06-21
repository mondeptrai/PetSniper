-- ╔══════════════════════════════════════════════════════════════╗
-- ║     GrowGarden2 - Working Pet Sniper     ║
-- ║        Auto-Snipe Pets Using ProximityPrompt         ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ============================================
-- CONFIGURATION
-- ============================================

getgenv().SniperConfig = {
    
    -- Main toggle
    Enabled = true,                
    
    -- Maximum price (0 = no limit)
    MaxPrice = 0,                  
    
    -- Rarity Filter (true = buy, false = skip)
    RarityFilter = {
        ["Common"] = true,         
        ["Uncommon"] = true,      
        ["Rare"] = true,          
        ["Epic"] = true,
        ["Legendary"] = true,      
        ["Mythic"] = true,         
        ["Super"] = true,          
    },
    
    -- Performance settings
    SniperDelay = 0.1,            
    TeleportDelay = 0.05,          
}

-- ============================================
-- PET DATA
-- ============================================

local PetData = {
    -- Common Pets
    ["Frog"] = { Rarity = "Common", Price = 10000 },
    ["Bunny"] = { Rarity = "Common", Price = 20000 },
    
    -- Uncommon Pets
    ["Owl"] = { Rarity = "Uncommon", Price = 25000 },
    
    -- Rare Pets
    ["Deer"] = { Rarity = "Rare", Price = 50000 },
    
    -- Legendary Pets
    ["Robin"] = { Rarity = "Legendary", Price = 75000 },
    ["Bee"] = { Rarity = "Legendary", Price = 1000000 },
    
    -- Mythic Pets
    ["Monkey"] = { Rarity = "Mythic", Price = 1000000 },
    ["GoldenDragonfly"] = { Rarity = "Mythic", Price = 3000000 },
    ["Golden Dragonfly"] = { Rarity = "Mythic", Price = 3000000 },
    ["Unicorn"] = { Rarity = "Mythic", Price = 4000000 },
    ["Bear"] = { Rarity = "Mythic", Price = 5000000 },
    
    -- Super Pets
    ["Raccoon"] = { Rarity = "Super", Price = 5000000 },
    ["BlackDragon"] = { Rarity = "Super", Price = 1000000 },
    ["Black Dragon"] = { Rarity = "Super", Price = 1000000 },
    ["IceSerpent"] = { Rarity = "Super", Price = 20000000 },
    ["Ice Serpent"] = { Rarity = "Super", Price = 20000000 },
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

-- ============================================
-- SERVICES
-- ============================================

local Players = game:GetService("Players")
local VirtualInputManager = nil

pcall(function()
    local env = getsenv and getsenv(game.Players.LocalPlayer)
    if env then
        VirtualInputManager = env.VirtualInputManager
    end
end)

local Player = Players.LocalPlayer

-- Purchase Remote
local PurchaseRemote = nil
pcall(function()
    PurchaseRemote = game:GetService("ReplicatedStorage"):FindFirstChild("SharedModules"):FindFirstChild("Packet")
end)

-- ============================================
-- STATE TRACKING
-- ============================================

local SnipedPets = {}
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
    
    if PetData[petName] then
        return PetData[petName]
    end
    
    local withoutSpace = petName:gsub(" ", "")
    if PetData[withoutSpace] then
        return PetData[withoutSpace]
    end
    
    return nil
end

-- ============================================
-- TELEPORT SYSTEM
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
-- PET DETECTION - FIXED FOR PROXIMITYPROMPT
-- ============================================

local function FindWildPets()
    local pets = {}
    
    pcall(function()
        local map = workspace:FindFirstChild("Map")
        if not map then return end
        
        -- Check WildPetSpawns first
        local wildPetSpawns = map:FindFirstChild("WildPetSpawns")
        if wildPetSpawns then
            for _, petModel in ipairs(wildPetSpawns:GetChildren()) do
                if petModel:IsA("Model") and petModel.Name:find("WildPet") then
                    -- Extract pet name from model name
                    local petName = nil
                    local nameParts = string.split(petModel.Name, "_")
                    if #nameParts >= 2 then
                        petName = nameParts[2]
                        -- Handle names with spaces
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
                        -- Find ProximityPrompt (BuyPrompt)
                        local buyPrompt = rootPart:FindFirstChild("BuyPrompt")
                        
                        -- Get pet info
                        local petInfo = GetPetInfo(petName)
                        if not petInfo then
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
                        })
                    end
                end
            end
        end
        
        -- Also check WildPetRef (used by purchase remote)
        local wildPetRef = map:FindFirstChild("WildPetRef")
        if wildPetRef then
            for _, petModel in ipairs(wildPetRef:GetChildren()) do
                if petModel:IsA("Model") and petModel.Name:find("WildPet") then
                    -- Check if already in list
                    local alreadyExists = false
                    for _, existingPet in ipairs(pets) do
                        if existingPet.Model == petModel then
                            alreadyExists = true
                            break
                        end
                    end
                    
                    if not alreadyExists then
                        -- Extract pet name from model name
                        local petName = nil
                        local nameParts = string.split(petModel.Name, "_")
                        if #nameParts >= 2 then
                            petName = nameParts[2]
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
                            local buyPrompt = rootPart and rootPart:FindFirstChild("BuyPrompt")
                            
                            local petInfo = GetPetInfo(petName)
                            if not petInfo then
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
-- CONFIGURATION CHECK
-- ============================================

local function ShouldBuyPet(petName, petInfo, price, config)
    local cfg = config or getgenv().SniperConfig
    
    -- Check for Huge/Big (absolute priority)
    local isHugeOrBig, specialType = IsHugeOrBig(petName)
    if isHugeOrBig then
        return true, true, specialType
    end
    
    -- Check rarity filter
    if petInfo and cfg.RarityFilter then
        local rarity = petInfo.Rarity
        if cfg.RarityFilter[rarity] == false then
            return false, false, "Normal"
        end
    end
    
    -- Check price filter
    local maxPrice = cfg.MaxPrice or 0
    if maxPrice > 0 and price > maxPrice then
        return false, false, "Normal"
    end
    
    return true, false, "Normal"
end

-- ============================================
-- PROXIMITYPROMPT PURCHASE SYSTEM - FIXED
-- ============================================

local function FireProximityPrompt(prompt)
    if not prompt then return false end
    
    pcall(function()
        -- Set MaxActivationDistance to be very high
        prompt.MaxActivationDistance = 1000
        
        -- Fire the prompt's HoldCompleted event
        if prompt.HoldCompleted then
            firesignal(prompt.HoldCompleted)
        end
        
        -- Also try triggering the trigger
        if prompt.Trigger then
            firesignal(prompt.Trigger)
        end
        
        -- Fire input events
        if VirtualInputManager then
            -- Try E key
            VirtualInputManager:SendKeyDown(Enum.KeyCode.E)
            task.wait(0.01)
            VirtualInputManager:SendKeyUp(Enum.KeyCode.E)
        end
    end)
    
    return true
end

local function TryTriggerProximityPrompt(prompt)
    if not prompt then return false end
    
    local success = false
    
    pcall(function()
        -- Check if prompt exists and is valid
        if not prompt.Parent then return end
        
        -- Set max distance
        prompt.MaxActivationDistance = 1000
        prompt.Enabled = true
        
        -- Get keyboard keycode
        local keyCode = Enum.KeyCode.E
        pcall(function()
            keyCode = prompt.KeyboardKeyCode or Enum.KeyCode.E
        end)
        
        -- Get HoldDuration (if any)
        local holdDuration = 0
        pcall(function()
            holdDuration = prompt.HoldDuration or 0
        end)
        
        -- Method 1: VirtualInputManager with hold
        if VirtualInputManager then
            -- Hold the key for the duration
            VirtualInputManager:SendKeyDown(keyCode)
            if holdDuration > 0 then
                task.wait(holdDuration + 0.05)
            else
                task.wait(0.05)
            end
            VirtualInputManager:SendKeyUp(keyCode)
        end
        
        -- Method 2: Firesignal on Trigger
        if prompt.Trigger then
            for i = 1, 5 do
                firesignal(prompt.Trigger)
                task.wait(0.01)
            end
        end
        
        -- Method 3: Fire HoldCompleted directly
        if holdDuration > 0 and prompt.HoldCompleted then
            firesignal(prompt.HoldCompleted)
        end
        
        -- Method 4: Fire PromptButton if exists
        local button = prompt:FindFirstChild("PromptButtonFrame")
        if button then
            local buttonClick = button:FindFirstChildOfClass("TextButton") or button:FindFirstChildOfClass("ImageButton")
            if buttonClick then
                for i = 1, 3 do
                    firesignal(buttonClick.Activated)
                    task.wait(0.01)
                end
            end
        end
        
        success = true
    end)
    
    return success
end

local function ExecutePurchase(pet)
    local model = pet.Model
    if not model then return false end
    
    -- Try to find the RemoteEvent for purchasing
    local remote = PurchaseRemote
    if not remote then
        pcall(function()
            remote = game:GetService("ReplicatedStorage"):FindFirstChild("SharedModules"):FindFirstChild("Packet")
        end)
    end
    
    if not remote then
        -- Fallback: try ProximityPrompt method
        return ExecutePurchaseProximityPrompt(pet)
    end
    
    -- Try multiple times
    for attempt = 1, 10 do
        -- Check if pet was already purchased (removed from workspace)
        if not model:IsDescendantOf(workspace) then
            return true
        end
        
        -- Fire the purchase remote with the pet model
        pcall(function()
            remote:FireServer(model)
        end)
        
        -- Wait a bit between attempts
        task.wait(0.05)
    end
    
    -- Check if pet was purchased
    return not model:IsDescendantOf(workspace)
end

-- Fallback ProximityPrompt purchase method
local function ExecutePurchaseProximityPrompt(pet)
    local model = pet.Model
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
    
    -- Get HoldDuration
    local holdDuration = 0
    pcall(function()
        holdDuration = buyPrompt.HoldDuration or 0
    end)
    
    -- Try multiple times
    for attempt = 1, 10 do
        -- Check if pet was already purchased (removed from workspace)
        if not model:IsDescendantOf(workspace) then
            return true
        end
        
        -- Teleport very close to the pet (in front of it)
        local petPos = rootPart.Position
        local lookDir = rootPart.CFrame.LookVector
        InstantTeleport(petPos + Vector3.new(0, 2, 0) + (lookDir * 5))
        
        -- Wait for proximity prompt to activate
        task.wait(getgenv().SniperConfig.TeleportDelay or 0.1)
        
        -- Wait for prompt to appear (proximity prompt has fade in)
        task.wait(0.15)
        
        -- Try to trigger the ProximityPrompt with proper hold
        TryTriggerProximityPrompt(buyPrompt)
        
        -- If has HoldDuration, wait for it
        if holdDuration > 0 then
            task.wait(holdDuration + 0.1)
        end
        
        task.wait(0.05)
    end
    
    -- Check if pet was purchased
    return not model:IsDescendantOf(workspace)
end

-- ============================================
-- MAIN SNIPER LOOP
-- ============================================

local function StartSniperLoop()
    if IsSniping then return end
    
    IsSniping = true
    local config = getgenv().SniperConfig or {}
    
    print("═══════════════════════════════════════════════════")
    print("   🏹 Pet Sniper Started!")
    print("═══════════════════════════════════════════════════")
    print("   Max Price: " .. FormatNumber(config.MaxPrice or 0))
    print("═══════════════════════════════════════════════════")
    
    task.spawn(function()
        while IsSniping do
            pcall(function()
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
                    
                    -- Then by distance
                    local distA = (hrp.Position - a.Position).Magnitude
                    local distB = (hrp.Position - b.Position).Magnitude
                    return distA < distB
                end)
                
                -- Process the highest priority pet
                local pet = pets[1]
                if not pet or not pet.Model then
                    task.wait(0.1)
                    return
                end
                
                -- Verify pet still exists
                if not pet.Model:IsDescendantOf(workspace) then
                    return
                end
                
                -- Check if should buy
                local shouldBuy, isHugeOrBig, specialType = ShouldBuyPet(pet.PetName, pet.PetInfo, pet.Price, config)
                
                if not shouldBuy then
                    task.wait(0.1)
                    return
                end
                
                -- Log purchase attempt
                local prefix = isHugeOrBig and "🚀" or "🎯"
                local specialStr = isHugeOrBig and (" [" .. specialType .. "]") or ""
                print(prefix .. " SNIPING" .. specialStr .. ": " .. pet.PetName .. " [" .. pet.Rarity .. "] - " .. FormatNumber(pet.Price))
                
                -- Prevent concurrent purchases
                if not PurchaseInProgress then
                    PurchaseInProgress = true
                    
                    -- Attempt purchase
                    local startTime = tick()
                    local success = ExecutePurchase(pet)
                    local purchaseTime = (tick() - startTime) * 1000
                    
                    PurchaseInProgress = false
                    
                    if success then
                        table.insert(SnipedPets, {
                            Name = pet.PetName,
                            Rarity = pet.Rarity,
                            Price = pet.Price,
                            Time = os.date("%H:%M:%S"),
                        })
                        print("✅ SUCCESS! " .. pet.PetName .. " [" .. pet.Rarity .. "] - " .. FormatNumber(pet.Price) .. " (" .. string.format("%.1fms", purchaseTime) .. ")")
                    else
                        print("❌ MISSED: " .. pet.PetName)
                    end
                end
            end)
            
            task.wait(config.SniperDelay or 0.1)
        end
        
        IsSniping = false
        print("═══════════════════════════════════════════════════")
        print("   🏹 Pet Sniper Stopped!")
        print("═══════════════════════════════════════════════════")
    end)
end

local function StopSniperLoop()
    IsSniping = false
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
        TotalSniped = #SnipedPets,
        CurrentSheckles = GetSheckles(),
        RecentPets = SnipedPets,
    }
end

getgenv().ConfigureSniper = function(config)
    if not config then return end
    local current = getgenv().SniperConfig or {}
    getgenv().SniperConfig = {
        Enabled = config.Enabled ~= nil and config.Enabled or current.Enabled,
        MaxPrice = config.MaxPrice or current.MaxPrice or 0,
        RarityFilter = config.RarityFilter or current.RarityFilter or {},
        SniperDelay = config.SniperDelay or current.SniperDelay or 0.1,
        TeleportDelay = config.TeleportDelay or current.TeleportDelay or 0.05,
    }
    print("[Sniper] Configuration updated!")
end

-- ============================================
-- AUTO-START
-- ============================================

if getgenv().SniperConfig and getgenv().SniperConfig.Enabled then
    task.wait(1) -- Wait for game to load
    StartSniperLoop()
end

print([[
╔══════════════════════════════════════════════════════════════╗
║        GrowGarden2 - Pet Sniper Loaded!                 ║
╠══════════════════════════════════════════════════════════════╣
║  COMMANDS:                                                 ║
║  • getgenv().StartPetSniper()  - Start sniping           ║
║  • getgenv().StopPetSniper()   - Stop sniping            ║
║  • getgenv().TogglePetSniper() - Toggle sniping          ║
║  • getgenv().GetSniperStats()  - Get statistics          ║
║                                                              ║
║  CONFIG:                                                    ║
║  • getgenv().SniperConfig.Enabled = true/false            ║
║  • getgenv().SniperConfig.MaxPrice = 0 (0 = no limit)    ║
║  • getgenv().SniperConfig.RarityFilter["Mythic"] = true   ║
║                                                              ║
║  NOTE: Set Enabled = false before editing config!           ║
╚══════════════════════════════════════════════════════════════╝
]])
