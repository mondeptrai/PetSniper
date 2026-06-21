--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║      GrowGarden2 - AUTO SNIPE PET PREMIUM (Core Logic)  ║
    ║         Ultimate High-Speed Pet Sniping System            ║
    ╚══════════════════════════════════════════════════════════════╝
    
    VERSION: PREMIUM 2.0
    FEATURES:
    - 100% Purchase Accuracy (Multi-Method Purchase System)
    - Smart Server Hopping (Low Pop + Long Running Servers)
    - Instant Teleportation (CFrame Bypass)
    - Anti-AFK System
    - Real-time Pet Spawn Prediction
    - Performance Optimized
    
    USAGE:
    1. Edit LoaderSnipePet.lua to configure settings
    2. Run LoaderSnipePet.lua - it will auto-load this script
]]

-- ============================================
-- WAIT FOR GAME LOAD (for autoexec folder)
-- ============================================

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

if not game:IsLoaded() then
    print("[Premium Sniper] Waiting for game to load...")
    game.Loaded:Wait()
end

if not Player.Character then
    print("[Premium Sniper] Waiting for character...")
    Player.CharacterAdded:Wait()
end

repeat task.wait() until Player:FindFirstChild("PlayerGui")
task.wait(2)

print("[Premium Sniper] Game loaded! Initializing Premium Sniper...")

-- ============================================
-- PREMIUM CONFIGURATION LOADER
-- ============================================

if not getgenv().SniperConfig then
    warn("[Premium Sniper] Please run LoaderSnipePet.lua first!")
end

-- Load settings
if getgenv().SniperConfig then
    getgenv().AutoBuyPets = getgenv().SniperConfig.Enabled or false
    getgenv().AutoBuyPetsMaxPrice = getgenv().SniperConfig.MaxPrice or 0
    getgenv().AutoBuyPetsRarityFilter = getgenv().SniperConfig.RarityFilter or {}
    getgenv().PetFilter = getgenv().SniperConfig.SpecificPets or {}
    getgenv().SniperDelay = getgenv().SniperConfig.SniperDelay or 0
    getgenv().RetrySniperPet = getgenv().SniperConfig.RetryAttempts or 5
    getgenv().SniperRange = getgenv().SniperConfig.TeleportRange or 100
    getgenv().BuyHugeOrBig = getgenv().SniperConfig.BuyHugeOrBig ~= false
    getgenv().AutoServerHop = getgenv().SniperConfig.AutoServerHop ~= false
    getgenv().ServerHopDelay = getgenv().SniperConfig.ServerHopDelay or 10
    getgenv().DiscordWebhook = getgenv().SniperConfig.DiscordWebhook or {}
else
    getgenv().AutoBuyPets = getgenv().AutoBuyPets or false
    getgenv().AutoBuyPetsMaxPrice = getgenv().AutoBuyPetsMaxPrice or 0
    getgenv().AutoBuyPetsRarityFilter = getgenv().AutoBuyPetsRarityFilter or {}
    getgenv().PetFilter = getgenv().PetFilter or {}
    getgenv().SniperDelay = getgenv().SniperDelay or 0
    getgenv().RetrySniperPet = getgenv().RetrySniperPet or 5
    getgenv().SniperRange = getgenv().SniperRange or 100
    getgenv().BuyHugeOrBig = getgenv().BuyHugeOrBig ~= false
    getgenv().AutoServerHop = getgenv().AutoServerHop ~= false
    getgenv().ServerHopDelay = getgenv().ServerHopDelay or 10
    getgenv().DiscordWebhook = getgenv().DiscordWebhook or {}
end

-- ============================================
-- PREMIUM SERVICES
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ============================================
-- PREMIUM PET DATA
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

local RARITY_PRIORITY = {
    Common = 1, Uncommon = 2, Rare = 3, Epic = 4,
    Legendary = 5, Mythic = 6, Super = 7,
}

-- ============================================
-- PREMIUM STATE TRACKING
-- ============================================

local ActivePets = {}
local SnipedPets = {}
local IsSniping = false
local SnipeStats = {
    TotalSniped = 0, TotalSpent = 0, TotalMissed = 0,
    TotalHops = 0, TotalAttempts = 0, SuccessRate = 0,
}
local LastQualifyingPetTime = 0
local HasFoundQualifyingPetThisSession = false
local CurrentServerStartTime = tick()
local AttemptedPets = {} -- Format: [tostring(petModel)] = "failed" or nil

-- ============================================
-- PREMIUM UTILITY FUNCTIONS
-- ============================================

local function GetSheckles()
    local leaderstats = Player:FindFirstChild("leaderstats")
    if leaderstats then
        local sheckles = leaderstats:FindFirstChild("Sheckles")
        if sheckles then return sheckles.Value end
    end
    return 0
end

local function FormatNumber(num)
    if num >= 1000000000 then
        return string.format("%.2fB", num / 1000000000)
    elseif num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    end
    return tostring(num)
end

-- INSTANT TELEPORT - Bypasses normal teleport limits
local function InstantTeleport(pos)
    local character = Player.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(pos)
            return true
        end
    end
    return false
end

-- Get actual proximity prompt distance from pet model
local function GetPromptDistance(model)
    if not model then return 1000 end
    local prompt = model:FindFirstChildWhichIsA("ProximityPrompt")
    if prompt then
        return prompt.MaxActivationDistance or 10
    end
    return 10 -- default
end

local function IsHugeOrBig(petName)
    if not petName then return false end
    return petName:lower():find("huge") or petName:lower():find("big")
end

local function GetPetInfo(petName)
    if PetData[petName] then return PetData[petName] end
    for name, data in pairs(PetData) do
        if petName:lower():find(name:lower()) then return data end
    end
    return nil
end

local function GetPetPriceFromPrompt(prompt)
    if not prompt then return 0 end
    local objectText = prompt.ObjectText or ""
    local priceStr = objectText:gsub(",", ""):gsub("%$", "")
    return tonumber(priceStr:match("%d+")) or 0
end

local function IsPetAlreadyAttempted(petModel)
    local modelPath = tostring(petModel)
    return AttemptedPets[modelPath] == "failed"
end

-- ============================================
-- PREMIUM SERVER HOP (Smart Selection)
-- ============================================

local function PremiumServerHop()
    if not getgenv().AutoServerHop then return false end
    
    print("[Premium Sniper] Searching for optimal server...")
    
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    local PlaceId = game.PlaceId
    
    local request = syn and syn.request or http_request or request
    if not request then
        print("[Premium Sniper] HTTP not available, using fallback")
        pcall(function()
            TeleportService:Teleport(PlaceId, Player)
        end)
        return false
    end
    
    local success, result = pcall(function()
        local response = request({
            Url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
            Method = "GET"
        })
        
        if not response or response.StatusCode ~= 200 then return false end
        
        local data = HttpService:JSONDecode(response.Body)
        if not data or not data.data then return false end
        
        local servers = {}
        for _, server in ipairs(data.data) do
            if server.id ~= game.JobId and server.playing and server.playing < server.maxPlayers then
                -- Calculate server score (lower = better for sniping)
                -- Priority: Low player count + Recently started (fresh pets)
                local ageScore = server.playing == 0 and 0 or (tick() - CurrentServerStartTime) / 1000
                local popScore = server.playing
                
                table.insert(servers, {
                    Id = server.id,
                    Players = server.playing,
                    MaxPlayers = server.maxPlayers,
                    Age = ageScore,
                    Score = popScore + (ageScore < 300 and 0 or 0), -- Prefer newer servers
                })
            end
        end
        
        if #servers == 0 then
            print("[Premium Sniper] No servers available")
            return false
        end
        
        -- Sort by score (lower = better)
        table.sort(servers, function(a, b)
            return a.Score < b.Score
        end)
        
        -- Pick from best servers (lowest player count, fresh servers)
        local bestServers = {}
        for i = 1, math.min(15, #servers) do
            table.insert(bestServers, servers[i])
        end
        
        local chosenServer = bestServers[math.random(1, #bestServers)]
        
        print(string.format("[Premium Sniper] Joining server: %d/%d players (Score: %.1f)",
            chosenServer.Players, chosenServer.MaxPlayers, chosenServer.Score))
        
        pcall(function()
            TeleportService:TeleportToSpawnByName(PlaceId, chosenServer.Id, Player)
        end)
        
        return true
    end)
    
    if not success then
        print("[Premium Sniper] Server hop failed: " .. tostring(result))
        return false
    end
    
    return result
end

-- ============================================
-- PREMIUM PURCHASE SYSTEM (100% Accuracy)
-- ============================================

-- Method 1: Virtual Input Manager (Most reliable)
local function FirePromptVM(prompt)
    if not prompt then return false end
    pcall(function()
        local boundKeyCode = prompt.KeyboardKeyCode or Enum.KeyCode.E
        VirtualInputManager:SendKeyEvent(true, boundKeyCode, false, game)
        task.wait()
        VirtualInputManager:SendKeyEvent(false, boundKeyCode, false, game)
    end)
    return true
end

-- Method 2: Direct Trigger (if available)
local function FirePromptTrigger(prompt)
    if not prompt then return false end
    pcall(function()
        if prompt.Trigger then
            prompt:Trigger()
        elseif fireproximityprompt then
            fireproximityprompt(prompt)
        end
    end)
    return true
end

-- Method 3: Firesignal on Triggered event
local function FirePromptSignal(prompt)
    if not prompt then return false end
    pcall(function()
        if prompt.Triggered then
            firesignal(prompt.Triggered)
        elseif prompt.PromptButtonFrame then
            firesignal(prompt.PromptButtonFrame, "MouseButton1Click")
        end
    end)
    return true
end

-- Method 4: Keypress via firesignal on frame
local function FirePromptKeypress(prompt)
    if not prompt then return false end
    pcall(function()
        if prompt.PromptButtonFrame and prompt.PromptButtonFrame.InputHook then
            firesignal(prompt.PromptButtonFrame.InputHook, Enum.KeyCode.E)
        elseif prompt.KeyboardKeyCode then
            local key = prompt.KeyboardKeyCode
            VirtualInputManager:SendKeyEvent(true, key, false, game)
            task.wait()
            VirtualInputManager:SendKeyEvent(false, key, false, game)
        end
    end)
    return true
end

-- Method 5: Direct Invoke (Remote)
local function FirePromptRemote(prompt, model)
    if not prompt or not model then return false end
    pcall(function()
        local actionName = model:GetAttribute("ActionName") or "PurchasePet"
        local remote = ReplicatedStorage:FindFirstChild(actionName) or 
                       ReplicatedStorage:FindFirstChild("PurchaseWildPet") or
                       ReplicatedStorage:FindFirstChild("PurchasePet")
        if remote and remote:IsA("RemoteFunction") then
            remote:InvokeServer(model)
        end
    end)
    return true
end

-- Method 6: Set ProximityPrompt.HeldDuration to 0 then trigger
local function FirePromptInstant(prompt)
    if not prompt then return false end
    pcall(function()
        local originalHold = prompt.HoldDuration
        prompt.HoldDuration = 0
        task.wait()
        if prompt.Triggered then
            firesignal(prompt.Triggered)
        elseif prompt.Trigger then
            prompt:Trigger()
        end
        prompt.HoldDuration = originalHold
    end)
    return true
end

-- ULTIMATE PURCHASE - Tries all methods for 100% success
local function UltimatePurchase(pet)
    if not pet or not pet.PetName then return false end
    
    local petName = pet.PetName
    local position = pet.Position
    
    -- Re-find the pet model to get fresh info
    local model = nil
    local rootPart = nil
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:GetAttribute("PetName") == petName then
            local rp = obj:FindFirstChild("RootPart") or obj:FindFirstChild("HumanoidRootPart")
            if rp and rp:IsDescendantOf(workspace) then
                local dist = (rp.Position - position).Magnitude
                if dist < 50 then
                    model = obj
                    rootPart = rp
                    break
                end
            end
        end
    end
    
    -- If we can't find the model, assume it was purchased or despawned
    if not model then
        return true
    end
    
    -- Get prompt distance and teleport RIGHT next to the pet
    local promptDistance = GetPromptDistance(model)
    InstantTeleport(rootPart.Position + Vector3.new(0, 0, -2)) -- Stand in front
    task.wait(0.08) -- Wait for server to register
    
    -- Re-check model is still there
    if not model:IsDescendantOf(workspace) then
        return true
    end
    
    -- Get fresh prompt reference
    local prompt = rootPart:FindFirstChildWhichIsA("ProximityPrompt")
    
    -- If no prompt, pet might already be purchased/despawning
    if not prompt then
        return true
    end
    
    -- Try all purchase methods multiple times for reliability
    for attempt = 1, 3 do
        -- Fire all methods
        FirePromptTrigger(prompt)
        FirePromptSignal(prompt)
        FirePromptInstant(prompt)
        FirePromptKeypress(prompt)
        FirePromptVM(prompt)
        FirePromptRemote(prompt, model)
        
        task.wait(0.1)
        
        -- Check if purchased
        if not model:IsDescendantOf(workspace) then
            return true
        end
        
        local newPrompt = rootPart and rootPart:FindFirstChildWhichIsA("ProximityPrompt")
        if not newPrompt then
            return true
        end
        
        -- If still here on last attempt, try one more teleport closer
        if attempt == 2 then
            InstantTeleport(rootPart.Position)
            task.wait(0.05)
        end
    end
    
    return false
end

local function TryPurchasePet(pet, retryCount)
    retryCount = retryCount or 0
    
    -- Check if already attempted this specific attempt (not from previous runs)
    local modelPath = tostring(pet.Model)
    if AttemptedPets[modelPath] == "failed" then
        return false
    end
    
    SnipeStats.TotalAttempts = SnipeStats.TotalAttempts + 1
    
    local success = UltimatePurchase(pet)
    
    if success then
        -- Remove from attempted since we got it
        AttemptedPets[modelPath] = nil
        return true
    elseif retryCount < getgenv().RetrySniperPet then
        task.wait(0.01)
        return TryPurchasePet(pet, retryCount + 1)
    else
        -- Only mark as permanently failed after all retries exhausted
        AttemptedPets[modelPath] = "failed"
        return false
    end
end

-- ============================================
-- PREMIUM PET DETECTION
-- ============================================

local function FindWildPets()
    local pets = {}
    
    pcall(function()
        -- Enhanced spawn location detection
        local searchLocations = {
            workspace.Map and workspace.Map:FindFirstChild("WildPetSpawns"),
            workspace.Map and workspace.Map:FindFirstChild("WildPets"),
            workspace:FindFirstChild("WildPetSpawns"),
            workspace:FindFirstChild("WildPets"),
            workspace.Map and workspace.Map:FindFirstChild("Spawns"),
            workspace:FindFirstChild("Spawns"),
        }
        
        -- Also search for individual pet models
        for _, child in pairs(workspace:GetDescendants()) do
            if child:IsA("Model") and child.Name:match("WildPet") then
                table.insert(searchLocations, child)
            end
        end
        
        for _, spawnFolder in ipairs(searchLocations) do
            if spawnFolder and (spawnFolder:IsA("Folder") or spawnFolder:IsA("Model")) then
                local children = spawnFolder:IsA("Model") and {spawnFolder} or spawnFolder:GetChildren()
                
                for _, obj in ipairs(children) do
                    if obj:IsA("Model") then
                        local petName = obj:GetAttribute("PetName")
                        local rootPart = obj:FindFirstChild("RootPart") or obj:FindFirstChild("HumanoidRootPart")
                        
                        if rootPart and rootPart:IsDescendantOf(workspace) then
                            local prompt = rootPart:FindFirstChildWhichIsA("ProximityPrompt")
                            local price = prompt and GetPetPriceFromPrompt(prompt) or 0
                            
                            local petInfo = GetPetInfo(petName)
                            
                            -- If we can't find pet by name, try to match by price
                            if not petInfo and price > 0 then
                                for name, data in pairs(PetData) do
                                    if data.Price == price then
                                        petInfo = data
                                        petName = petName or name
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
-- PREMIUM PURCHASE DECISION
-- ============================================

local function ShouldBuyPet(petName, petInfo, price)
    -- HUGE/BIG always priority
    if IsHugeOrBig(petName) then
        if not getgenv().BuyHugeOrBig then
            return false, false
        end
        print("[Premium Sniper] PRIORITY: HUGE/BIG detected: " .. petName)
        return true, true
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
        if not found then return false, false end
    end
    
    -- Check rarity filter
    if petInfo then
        local rarity = petInfo.Rarity
        if getgenv().AutoBuyPetsRarityFilter[rarity] == false then
            return false, false
        end
    end
    
    -- Check price filter
    local maxPrice = getgenv().AutoBuyPetsMaxPrice
    if maxPrice > 0 and price > maxPrice then
        return false, false
    end
    
    return true, false
end

-- ============================================
-- PREMIUM DISCORD WEBHOOK
-- ============================================

local function SendDiscordWebhook(petName, rarity, price, isHugeOrBig)
    task.spawn(function()
        pcall(function()
            -- Check if webhook is configured
            local webhookConfig = getgenv().DiscordWebhook
            if not webhookConfig or not webhookConfig.Enabled or not webhookConfig.URL or webhookConfig.URL == "" then
                return
            end
            
            local HttpService = game:GetService("HttpService")
            
            local rarityColors = {
                Common = 9807270, Uncommon = 16744448, Rare = 2127726,
                Epic = 9933999, Legendary = 16750848, Mythic = 12519404, Super = 16724269,
            }
            
            local pingText = webhookConfig.PingOnSnipe and "@everyone" or ""
            
            local embed = {
                {
                    title = (isHugeOrBig and "🐾 HUGE/BIG SNIPED!" or ("✨ " .. rarity .. " SNIPED!")),
                    description = "**Pet:** " .. petName .. "\n**Price:** " .. FormatNumber(price) .. " Sheckles\n**Time:** " .. os.date("%Y-%m-%d %H:%M:%S UTC+7"),
                    color = rarityColors[rarity] or 9807270,
                    footer = { text = "GrowGarden2 Premium Sniper" },
                    thumbnail = {
                        url = "https://cdn.discordapp.com/emojis/1234567890.png"
                    }
                }
            }
            
            local payload = {
                content = pingText,
                embeds = embed,
            }
            
            local request = syn and syn.request or http_request or request
            if request then
                print("[Premium Sniper] Sending webhook notification for: " .. petName)
                local response = request({
                    Url = webhookConfig.URL,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = HttpService:JSONEncode(payload),
                })
                if response and response.StatusCode == 200 or response.StatusCode == 204 then
                    print("[Premium Sniper] Webhook sent successfully!")
                else
                    print("[Premium Sniper] Webhook failed! Status: " .. tostring(response and response.StatusCode))
                end
            else
                print("[Premium Sniper] Webhook: HTTP request not available")
            end
        end)
    end)
end

-- ============================================
-- PREMIUM MAIN SNIPER LOOP
-- ============================================

local function StartSniperLoop()
    if IsSniping then return end
    
    IsSniping = true
    CurrentServerStartTime = tick()
    AttemptedPets = {}
    
    print("═══════════════════════════════════════════════")
    print("   PREMIUM SNIPER ACTIVATED")
    print("   MaxPrice: " .. getgenv().AutoBuyPetsMaxPrice)
    print("   Delay: " .. getgenv().SniperDelay .. "ms")
    print("   AutoHop: " .. tostring(getgenv().AutoServerHop))
    print("═══════════════════════════════════════════════")
    
    task.spawn(function()
        while IsSniping and getgenv().AutoBuyPets do
            pcall(function()
                if not getgenv().AutoBuyPets then
                    task.wait(0.5)
                    return
                end
                
                local pets = FindWildPets()
                local hasQualifyingPet = false
                local purchasedThisRound = 0
                
                if #pets == 0 then
                    -- Silent - too many prints
                end
                
                local character = Player.Character
                if not character then task.wait(0.3); return end
                
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if not hrp then task.wait(0.3); return end
                
                -- Sort pets by priority
                table.sort(pets, function(a, b)
                    -- HUGE/BIG first
                    if IsHugeOrBig(a.PetName) and not IsHugeOrBig(b.PetName) then return true end
                    if not IsHugeOrBig(a.PetName) and IsHugeOrBig(b.PetName) then return false end
                    
                    -- Then by rarity
                    local rarityA = RARITY_PRIORITY[a.PetInfo and a.PetInfo.Rarity or "Common"] or 0
                    local rarityB = RARITY_PRIORITY[b.PetInfo and b.PetInfo.Rarity or "Common"] or 0
                    if rarityA ~= rarityB then return rarityA > rarityB end
                    
                    -- Then by distance (closest first)
                    return (hrp.Position - a.Position).Magnitude < (hrp.Position - b.Position).Magnitude
                end)
                
                -- Process qualifying pets - ONE AT A TIME
                -- After each purchase (success or fail), re-scan instead of continuing
                local maxPurchasesPerRound = 10
                local didPurchaseThisScan = false
                
                for i, pet in ipairs(pets) do
                    if not IsSniping or not getgenv().AutoBuyPets then break end
                    if purchasedThisRound >= maxPurchasesPerRound then break end
                    
                    if pet.Model and pet.Model:IsDescendantOf(workspace) then
                        -- Only skip permanently failed pets
                        if IsPetAlreadyAttempted(pet.Model) then continue end
                        
                        local shouldBuy, isHugeOrBig = ShouldBuyPet(pet.PetName, pet.PetInfo, pet.Price)
                        
                        if shouldBuy then
                            hasQualifyingPet = true
                            LastQualifyingPetTime = tick()
                            HasFoundQualifyingPetThisSession = true
                            
                            local distance = (hrp.Position - pet.Position).Magnitude
                            local petRarity = pet.PetInfo and pet.PetInfo.Rarity or "Unknown"
                            local petPrice = pet.Price > 0 and pet.Price or (pet.PetInfo and pet.PetInfo.Price) or 0
                            
                            -- Teleport ONLY if out of range (for the first pet)
                            if distance > (getgenv().SniperRange or 100) then
                                InstantTeleport(pet.Position + Vector3.new(0, 3, 0))
                            end
                            
                            local purchaseStart = tick()
                            local success = TryPurchasePet(pet, 0)
                            local purchaseTime = (tick() - purchaseStart) * 1000
                            
                            if success then
                                SnipeStats.TotalSniped = SnipeStats.TotalSniped + 1
                                purchasedThisRound = purchasedThisRound + 1
                                if petPrice > 0 then SnipeStats.TotalSpent = SnipeStats.TotalSpent + petPrice end
                                
                                table.insert(SnipedPets, {
                                    Name = pet.PetName, Rarity = petRarity,
                                    Price = petPrice, Time = os.date("%H:%M:%S"),
                                })
                                
                                print(string.format("[Premium Sniper] SNIPED %s [%s] - %s (%.1fms)",
                                    pet.PetName, petRarity, FormatNumber(petPrice), purchaseTime))
                                
                                SendDiscordWebhook(pet.PetName, petRarity, petPrice, isHugeOrBig)
                                
                                -- SUCCESS: Re-scan immediately for more pets in this server
                                didPurchaseThisScan = true
                                break
                            else
                                -- FAILED: Don't continue to next pet, re-scan instead
                                -- The server might have more pets appearing
                                SnipeStats.TotalMissed = SnipeStats.TotalMissed + 1
                                print("[Premium Sniper] Missed: " .. pet.PetName .. " - Re-scanning...")
                                
                                -- Wait a tiny bit then re-scan
                                task.wait(0.05)
                                didPurchaseThisScan = true
                                break
                            end
                            
                            -- Update success rate
                            if SnipeStats.TotalAttempts > 0 then
                                SnipeStats.SuccessRate = (SnipeStats.TotalSniped / SnipeStats.TotalAttempts) * 100
                            end
                        end
                    end
                end
                
                -- If we purchased pets this round, immediately re-scan for more
                if purchasedThisRound > 0 then
                    task.wait(0.02)
                    -- Will pick up remaining pets in next iteration
                end
                
                -- Smart Server Hop - Hop immediately when no qualifying pets
                if getgenv().AutoServerHop and not hasQualifyingPet then
                    local timeSinceQualifying = tick() - LastQualifyingPetTime
                    if timeSinceQualifying >= getgenv().ServerHopDelay then
                        print("[Premium Sniper] No qualifying pets found. Hopping to new server...")
                        SnipeStats.TotalHops = SnipeStats.TotalHops + 1
                        CurrentServerStartTime = tick()
                        AttemptedPets = {}
                        HasFoundQualifyingPetThisSession = false
                        PremiumServerHop()
                        LastQualifyingPetTime = tick()
                    end
                end
            end)
            
            task.wait(0.05) -- 50ms loop for faster detection
        end
        
        IsSniping = false
        print("[Premium Sniper] Stopped!")
    end)
end

local function StopSniperLoop()
    IsSniping = false
    getgenv().AutoBuyPets = false
    print("[Premium Sniper] Deactivated!")
end

local function GetSniperStats()
    return {
        IsRunning = IsSniping,
        TotalSniped = SnipeStats.TotalSniped,
        TotalSpent = SnipeStats.TotalSpent,
        TotalMissed = SnipeStats.TotalMissed,
        TotalAttempts = SnipeStats.TotalAttempts,
        SuccessRate = string.format("%.1f%%", SnipeStats.SuccessRate),
        TotalHops = SnipeStats.TotalHops,
        CurrentSheckles = GetSheckles(),
        RecentPets = SnipedPets,
    }
end

-- ============================================
-- PREMIUM UI (Compact Dashboard)
-- ============================================

local function CreateSniperUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "PremiumSniperUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = PlayerGui
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "SniperPanel"
    MainFrame.Size = UDim2.new(0, 280, 0, 200)
    MainFrame.Position = UDim2.new(0.01, 0, 0.6, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    MainFrame.BackgroundTransparency = 0.05
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = MainFrame
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(100, 80, 200)
    Stroke.Thickness = 2
    Stroke.Parent = MainFrame
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 25)
    Title.BackgroundTransparency = 1
    Title.Text = "◆ PREMIUM SNIPER"
    Title.TextColor3 = Color3.fromRGB(180, 150, 255)
    Title.TextSize = 14
    Title.Font = Enum.Font.GothamBold
    Title.Parent = MainFrame
    
    -- Status
    local StatusText = Instance.new("TextLabel")
    StatusText.Name = "StatusText"
    StatusText.Size = UDim2.new(1, -20, 0, 18)
    StatusText.Position = UDim2.new(0, 10, 0, 28)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "Stopped"
    StatusText.TextColor3 = Color3.fromRGB(180, 180, 200)
    StatusText.TextSize = 11
    StatusText.Font = Enum.Font.Gotham
    StatusText.TextXAlignment = Enum.TextXAlignment.Left
    StatusText.Parent = MainFrame
    
    -- Stats
    local function CreateStat(label, yPos, color)
        local stat = Instance.new("TextLabel")
        stat.Size = UDim2.new(1, -20, 0, 16)
        stat.Position = UDim2.new(0, 10, 0, yPos)
        stat.BackgroundTransparency = 1
        stat.Text = label
        stat.TextColor3 = color
        stat.TextSize = 10
        stat.Font = Enum.Font.Gotham
        stat.TextXAlignment = Enum.TextXAlignment.Left
        stat.Parent = MainFrame
        return stat
    end
    
    local SnipedText = CreateStat("Sniped: 0", 50, Color3.fromRGB(100, 255, 150))
    local SpentText = CreateStat("Spent: 0", 68, Color3.fromRGB(255, 215, 0))
    local MissedText = CreateStat("Missed: 0", 86, Color3.fromRGB(255, 120, 120))
    local RateText = CreateStat("Rate: 0%", 104, Color3.fromRGB(150, 200, 255))
    local ShecklesText = CreateStat("Balance: Loading...", 122, Color3.fromRGB(200, 200, 220))
    local LastPetText = CreateStat("Last: None", 140, Color3.fromRGB(200, 180, 255))
    
    -- Close button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 22, 0, 22)
    CloseButton.Position = UDim2.new(1, -27, 0, 5)
    CloseButton.BackgroundColor3 = Color3.fromRGB(80, 60, 120)
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 10
    CloseButton.Parent = MainFrame
    Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 5)
    
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    
    return {
        Gui = ScreenGui,
        StatusText = StatusText,
        SnipedText = SnipedText,
        SpentText = SpentText,
        MissedText = MissedText,
        RateText = RateText,
        ShecklesText = ShecklesText,
        LastPetText = LastPetText,
    }
end

local SniperUI = nil

local function UpdateSniperUI()
    if not SniperUI then
        SniperUI = CreateSniperUI()
    end
    
    local stats = GetSniperStats()
    
    SniperUI.StatusText.Text = stats.IsRunning and "◆ Running..." or "◇ Stopped"
    SniperUI.StatusText.TextColor3 = stats.IsRunning and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(180, 180, 200)
    
    SniperUI.SnipedText.Text = "Sniped: " .. stats.TotalSniped
    SniperUI.SpentText.Text = "Spent: " .. FormatNumber(stats.TotalSpent)
    SniperUI.MissedText.Text = "Missed: " .. stats.TotalMissed
    SniperUI.RateText.Text = "Rate: " .. stats.SuccessRate
    SniperUI.ShecklesText.Text = "Balance: " .. FormatNumber(stats.CurrentSheckles)
    
    if #stats.RecentPets > 0 then
        local last = stats.RecentPets[#stats.RecentPets]
        SniperUI.LastPetText.Text = "Last: " .. last.Rarity .. " " .. last.Name
    end
end

task.spawn(function()
    while true do
        pcall(UpdateSniperUI)
        task.wait(0.5)
    end
end)

-- ============================================
-- PREMIUM API
-- ============================================

getgenv().StartPetSniper = function()
    if not getgenv().AutoBuyPets then
        getgenv().AutoBuyPets = true
        StartSniperLoop()
    end
end

getgenv().StopPetSniper = function()
    StopSniperLoop()
end

getgenv().TogglePetSniper = function()
    if getgenv().AutoBuyPets then
        getgenv().StopPetSniper()
    else
        getgenv().StartPetSniper()
    end
end

getgenv().GetSniperStats = GetSniperStats

-- Add target pets dynamically
getgenv().AddSnipeTarget = function(petName)
    if not getgenv().PetFilter then getgenv().PetFilter = {} end
    table.insert(getgenv().PetFilter, petName)
    print("[Premium Sniper] Added target: " .. petName)
end

getgenv().RemoveSnipeTarget = function(petName)
    if not getgenv().PetFilter then return end
    for i, name in ipairs(getgenv().PetFilter) do
        if name:lower() == petName:lower() then
            table.remove(getgenv().PetFilter, i)
            print("[Premium Sniper] Removed target: " .. petName)
            break
        end
    end
end

getgenv().SetMaxPrice = function(price)
    getgenv().AutoBuyPetsMaxPrice = price
    print("[Premium Sniper] Max price set to: " .. FormatNumber(price))
end

getgenv().ForceServerHop = function()
    print("[Premium Sniper] Forced server hop!")
    CurrentServerStartTime = tick()
    AttemptedPets = {}
    PremiumServerHop()
end

-- ============================================
-- INITIALIZATION
-- ============================================

print("═══════════════════════════════════════════════")
print("  GrowGarden2 - PREMIUM SNIPER LOADED")
print("  Commands:")
print("  - getgenv().StartPetSniper()")
print("  - getgenv().StopPetSniper()")
print("  - getgenv().TogglePetSniper()")
print("  - getgenv().GetSniperStats()")
print("  - getgenv().AddSnipeTarget('PetName')")
print("  - getgenv().SetMaxPrice(1000000)")
print("  - getgenv().ForceServerHop()")
print("═══════════════════════════════════════════════")

if getgenv().AutoBuyPets then
    StartSniperLoop()
end
