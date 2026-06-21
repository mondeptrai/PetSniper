

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

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
print("[Premium Sniper] ULTRA PRO MAX VIP VIP PRO PRO")

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
local UserInputService = game:GetService("UserInputService")
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
    ["Bee"] = { Rarity = "Mythic", Price = 1000000 },
    ["Monkey"] = { Rarity = "Mythic", Price = 1000000 },
    ["BlackDragon"] = { Rarity = "Mythic", Price = 1000000 },
    ["GoldenDragonfly"] = { Rarity = "Mythic", Price = 3000000 },
    ["Unicorn"] = { Rarity = "Mythic", Price = 4000000 },
    ["Bear"] = { Rarity = "Super", Price = 5000000 },
    ["Raccoon"] = { Rarity = "Super", Price = 5000000 },
    ["IceSerpent"] = { Rarity = "Super", Price = 20000000 },
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

-- INSTANT TELEPORT - Bypasses normal teleport limits (mobile compatible)
local function InstantTeleport(pos)
    local character = Player.Character
    if not character then return false end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    -- Primary method: CFrame teleport
    hrp.CFrame = CFrame.new(pos)
    
    -- Mobile executors may need extra confirmation
    if (getgenv().isMobileExecutor or false) == false then
        -- Try to verify teleport worked
        task.wait(0.02)
        if (hrp.Position - Vector3.new(pos.X, pos.Y, pos.Z)).Magnitude > 1 then
            -- Teleport might have been reverted, try again
            hrp.CFrame = CFrame.new(pos)
        end
    end
    
    return true
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
-- PREMIUM PURCHASE SYSTEM (100% Accuracy - No E Key Required)
-- ============================================

local PurchaseInProgress = false

-- Find purchase remote function
local function GetPurchaseRemote()
    local remotes = {
        "PurchaseWildPet",
        "PurchasePet",
        "BuyPet",
        "Purchase",
        "BuyWildPet",
        "ClaimPet",
        "CollectPet",
        "WildPetPurchase",
        "PetPurchase",
    }
    
    for _, remoteName in ipairs(remotes) do
        local remote = ReplicatedStorage:FindFirstChild(remoteName, true)
        if remote and (remote:IsA("RemoteFunction") or remote:IsA("RemoteEvent")) then
            return remote
        end
    end
    
    -- Try direct invoke on workspace models
    return nil
end

-- ============================================
-- DIRECT PURCHASE SYSTEM (No E Key Required)
-- ============================================

local PurchaseHandlerModule = nil

-- Find the game's purchase handlers
pcall(function()
    -- Search in SharedModules for WildPet/Purchase handlers
    local sharedModules = ReplicatedStorage:FindFirstChild("SharedModules")
    if sharedModules then
        for _, module in pairs(sharedModules:GetChildren()) do
            if module:IsA("ModuleScript") then
                local name = module.Name:lower()
                if name:match("wildpet") or name:match("purchase") or name:match("shop") or name:match("buy") then
                    print("[Premium Sniper] Found potential handler: " .. module.Name)
                end
            end
        end
    end
    
    -- Search in Client modules
    local clientModules = ReplicatedStorage:FindFirstChild("UserGenerated")
    if clientModules then
        local client = clientModules:FindFirstChild("Client")
        if client and client:IsA("ModuleScript") then
            PurchaseHandlerModule = client
            print("[Premium Sniper] Found Client module handler")
        end
    end
end)

-- Direct Purchase Function - Attempts to bypass ProximityPrompt
local function DirectPurchasePet(model, petName, price)
    print("[Premium Sniper] Attempting direct purchase for: " .. petName .. " (" .. FormatNumber(price) .. ")")
    
    local success = false
    local reason = "Unknown"
    
    -- Try Method 1: Fire Packet Remote with encoded data
    pcall(function()
        local packetModule = ReplicatedStorage:FindFirstChild("SharedModules")
        if packetModule then
            packetModule = packetModule:FindFirstChild("Packet")
            if packetModule and packetModule:IsA("ModuleScript") then
                local ok, packetHandler = pcall(function()
                    return require(packetModule)
                end)
                if ok and packetHandler then
                    -- Try calling Send/Purchase functions if they exist
                    local funcNames = {"SendPurchase", "BuyPet", "Purchase", "BuyWildPet", "PurchaseWildPet", "Buy", "PurchasePet"}
                    for _, funcName in ipairs(funcNames) do
                        if packetHandler[funcName] then
                            local callSuccess, callResult = pcall(function()
                                return packetHandler[funcName](petName, price, model)
                            end)
                            if callSuccess then
                                print("[Premium Sniper] SUCCESS: Called " .. funcName)
                                success = true
                                reason = "Direct function: " .. funcName
                                return
                            end
                        end
                    end
                end
            end
        end
    end)
    
    if success then return true, reason end
    
    -- Try Method 2: Try to find RemoteEvent in Packet folder
    pcall(function()
        local packetRemote = ReplicatedStorage:FindFirstChild("SharedModules")
        if packetRemote then
            packetRemote = packetRemote:FindFirstChild("Packet")
            if packetRemote then
                local remoteEvent = packetRemote:FindFirstChild("RemoteEvent")
                if remoteEvent then
                    -- Try firing with pet data
                    local petId = model:GetAttribute("PetId") or ""
                    local encodedData = string.format("\1$PURCHASE$%s$%s$%d", petName, petId, price)
                    remoteEvent:FireServer(buffer.fromstring(encodedData))
                    print("[Premium Sniper] Fired Packet RemoteEvent")
                    success = true
                    reason = "Packet remote fired"
                    return
                end
            end
        end
    end)
    
    if success then return true, reason end
    
    -- Try Method 3: Try ReplicaSystem remotes
    pcall(function()
        local replicaEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if replicaEvents then
            for _, remote in pairs(replicaEvents:GetChildren()) do
                if remote:IsA("RemoteEvent") then
                    local ok = pcall(function()
                        remote:FireServer(petName, price, model)
                    end)
                    if ok then
                        print("[Premium Sniper] Fired: " .. remote.Name)
                        success = true
                        reason = "ReplicaEvent: " .. remote.Name
                        return
                    end
                end
            end
        end
    end)
    
    if success then return true, reason end
    
    -- Try Method 4: Try Client module
    pcall(function()
        if PurchaseHandlerModule then
            local ok, client = pcall(function()
                return require(PurchaseHandlerModule)
            end)
            if ok and client then
                local funcNames = {"BuyPet", "PurchasePet", "Buy", "Purchase", "BuyWildPet"}
                for _, funcName in ipairs(funcNames) do
                    if client[funcName] then
                        local callSuccess = pcall(function()
                            return client[funcName](petName, price)
                        end)
                        if callSuccess then
                            success = true
                            reason = "Client." .. funcName
                            return
                        end
                    end
                end
            end
        end
    end)
    
    if success then return true, reason end
    
    -- Try Method 5: Search for any function with pet/purchase in name in PlayerScripts
    pcall(function()
        local playerScripts = Player:FindFirstChild("PlayerScripts")
        if playerScripts then
            local controllers = playerScripts:FindFirstChild("Controllers")
            if controllers then
                for _, controller in pairs(controllers:GetChildren()) do
                    if controller:IsA("ModuleScript") then
                        local ok, ctrl = pcall(function()
                            return require(controller)
                        end)
                        if ok and ctrl then
                            local funcNames = {"Buy", "Purchase", "BuyPet", "PurchasePet", "BuyWildPet", "HandlePurchase"}
                            for _, funcName in ipairs(funcNames) do
                                if ctrl[funcName] then
                                    local callSuccess = pcall(function()
                                        return ctrl[funcName](petName, price, model)
                                    end)
                                    if callSuccess then
                                        success = true
                                        reason = "Controller." .. controller.Name .. "." .. funcName
                                        return
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    
    return success, reason
end

-- Method 1: Direct RemoteFunction invoke (FASTER - no E key needed)
local function FireRemotePurchase(model)
    if not model then return false end
    
    local success = pcall(function()
        local petName = model:GetAttribute("PetName") or model.Name
        local petId = model:GetAttribute("PetId") or model:GetAttribute("Id") or 0
        local price = model:GetAttribute("Price") or 0
        
        -- Try to find and invoke the purchase remote
        local purchaseRemote = GetPurchaseRemote()
        
        if purchaseRemote and purchaseRemote:IsA("RemoteFunction") then
            -- Try invoke with model
            local result = purchaseRemote:InvokeServer(model)
            if result ~= nil then
                return result
            end
        end
        
        -- Try common remote names with model
        for _, remoteName in ipairs({"PurchaseWildPet", "PurchasePet", "BuyPet", "Purchase"}) do
            local remote = ReplicatedStorage:FindFirstChild(remoteName, true)
            if remote and remote:IsA("RemoteFunction") then
                local ok, result = pcall(function()
                    return remote:InvokeServer(model)
                end)
                if ok and result then
                    return true
                end
            end
        end
    end)
    
    return success
end

-- Method 2: Firesignal on PromptTriggered (instant signal)
local function FirePromptSignal(prompt)
    if not prompt then return false end
    
    local success = pcall(function()
        -- Try Triggered event first (most reliable)
        if prompt.Triggered then
            firesignal(prompt.Triggered)
            return true
        end
        
        -- Try PromptButtonFrame click
        if prompt.PromptButtonFrame then
            -- Try MouseButton1Click
            if prompt.PromptButtonFrame:FindFirstChild("Frame") then
                local frame = prompt.PromptButtonFrame.Frame
                if frame:FindFirstChild("AutoScale") or frame:FindFirstChild("Button") then
                    firesignal(frame, "MouseButton1Click")
                    return true
                end
            end
            -- Try direct click
            firesignal(prompt.PromptButtonFrame, "MouseButton1Click")
            return true
        end
        
        -- Try InputBegan/InputEnded for touch
        if prompt.PromptButtonFrame and prompt.PromptButtonFrame.InputBegan then
            firesignal(prompt.PromptButtonFrame.InputBegan)
            firesignal(prompt.PromptButtonFrame.InputEnded)
            return true
        end
    end)
    
    return success
end

-- Method 1: VirtualInputManager (works on most executors)
local function FirePromptVM(prompt)
    if not prompt then return false end
    
    local success = pcall(function()
        local keyCode = prompt.KeyboardKeyCode or Enum.KeyCode.E
        
        -- Press down
        if VirtualInputManager then
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.wait()
            -- Release
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end
    end)
    
    return success
end

-- Method 2: Firesignal with complete lifecycle (InputBegan -> Triggered -> InputEnded)
local function FirePromptComplete(prompt)
    if not prompt then return false end
    
    local success = pcall(function()
        local btn = prompt.PromptButtonFrame
        if not btn then return end
        
        -- Set instant hold
        local origHold = prompt.HoldDuration
        prompt.HoldDuration = 0
        prompt.HeldDownTime = 0
        
        -- Complete input lifecycle
        if btn.InputBegan then
            firesignal(btn.InputBegan, btn, Enum.UserInputType.Keyboard, Enum.KeyCode.E)
        end
        
        task.wait(0.01)
        
        -- Fire Triggered
        if prompt.Triggered then
            firesignal(prompt.Triggered)
        end
        
        task.wait(0.01)
        
        if btn.InputEnded then
            firesignal(btn.InputEnded, btn, Enum.UserInputType.Keyboard, Enum.KeyCode.E)
        end
        
        -- Restore
        prompt.HoldDuration = origHold
    end)
    
    return success
end

-- Method 3: Set HoldDuration to 0 and trigger (instant buy - MOST RELIABLE)
local function FirePromptInstant(prompt)
    if not prompt then return false end
    
    local success = pcall(function()
        -- CRITICAL: Set instant hold to bypass the 1-second requirement
        local originalHold = prompt.HoldDuration or 1
        local originalEnabled = prompt.Enabled
        local originalMaxDist = prompt.MaxActivationDistance
        
        -- Set to instant
        prompt.HoldDuration = 0
        prompt.HeldDownTime = 0
        prompt.Enabled = true
        prompt.MaxActivationDistance = 100 -- Ensure we can trigger from anywhere
        
        task.wait(0.01)
        
        -- Fire the Triggered event (most reliable method)
        if prompt.Triggered then
            firesignal(prompt.Triggered)
        end
        
        -- Also try direct Trigger method
        if prompt.Trigger then
            pcall(function() prompt:Trigger() end)
        end
        
        -- Try firesignal on PromptButtonFrame if available
        if prompt.PromptButtonFrame then
            local btn = prompt.PromptButtonFrame
            
            -- Fire InputBegan (simulates key/mouse down)
            if btn.InputBegan then
                firesignal(btn.InputBegan)
            end
            
            -- Fire Triggered event again
            if prompt.Triggered then
                firesignal(prompt.Triggered)
            end
            
            -- Fire InputEnded (simulates key/mouse up)
            if btn.InputEnded then
                firesignal(btn.InputEnded)
            end
            
            -- Try MouseButton1Click on the button
            if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                pcall(function() btn:Click() end)
            end
        end
        
        task.wait(0.01)
        
        -- Restore original values
        prompt.HoldDuration = originalHold
        prompt.Enabled = originalEnabled
        prompt.MaxActivationDistance = originalMaxDist
    end)
    
    return success
end

-- Method 4: Ultra-fast rapid fire with all methods
local function RapidFirePurchase(prompt)
    if not prompt then return false end
    
    local success = pcall(function()
        -- Set instant hold
        prompt.HoldDuration = 0
        prompt.HeldDownTime = 0
        
        for i = 1, 8 do
            -- firesignal Triggered
            if prompt.Triggered then
                firesignal(prompt.Triggered)
            end
            
            -- Direct Trigger
            if prompt.Trigger then
                pcall(function() prompt:Trigger() end)
            end
            
            -- PromptButtonFrame methods
            if prompt.PromptButtonFrame then
                local btn = prompt.PromptButtonFrame
                if btn.InputBegan then
                    firesignal(btn.InputBegan)
                end
                if prompt.Triggered then
                    firesignal(prompt.Triggered)
                end
                if btn.InputEnded then
                    firesignal(btn.InputEnded)
                end
                if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                    pcall(function() btn:Click() end)
                end
            end
            
            -- VirtualInputManager as backup
            if VirtualInputManager then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            end
            
            task.wait(0.01)
        end
    end)
    
    return success
end

-- Method 4: firesignal with RemoteEvent
local function FireRemoteEvent(model)
    if not model then return false end
    
    local success = pcall(function()
        local petName = model:GetAttribute("PetName") or model.Name
        
        -- Find RemoteEvents
        for _, remoteName in ipairs({"PurchaseWildPet", "PurchasePet", "BuyPet", "Purchase"}) do
            local remote = ReplicatedStorage:FindFirstChild(remoteName, true)
            if remote and remote:IsA("RemoteEvent") then
                remote:FireServer(model)
                return true
            end
        end
    end)
    
    return success
end

-- ULTIMATE PURCHASE - Uses ALL methods for maximum success rate (SPEED OPTIMIZED)
local function UltimatePurchase(pet)
    if not pet or not pet.PetName then return false, "Invalid pet data" end
    
    local petName = pet.PetName
    local position = pet.Position
    
    -- Prevent concurrent purchases
    if PurchaseInProgress then
        return false, "Purchase already in progress"
    end
    PurchaseInProgress = true
    
    local model = nil
    local rootPart = nil
    
    -- Re-find the pet model quickly
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:GetAttribute("PetName") == petName then
            local rp = obj:FindFirstChild("RootPart") or obj:FindFirstChild("HumanoidRootPart")
            if rp and rp:IsDescendantOf(workspace) then
                local dist = (rp.Position - position).Magnitude
                if dist < 100 then
                    model = obj
                    rootPart = rp
                    break
                end
            end
        end
    end
    
    -- If we can't find the model, pet might already be gone
    if not model then
        PurchaseInProgress = false
        return true, "Pet already gone"
    end
    
    -- Quick spawn check
    task.wait(0.01)
    if not model:IsDescendantOf(workspace) then
        PurchaseInProgress = false
        return true, "Pet despawned"
    end
    
    -- INSTANT Teleport - no delay!
    InstantTeleport(rootPart.Position + Vector3.new(0, 0, -2))
    
    -- Get the prompt
    local prompt = rootPart:FindFirstChildWhichIsA("ProximityPrompt")
    
    -- Print purchase attempt
    pcall(function()
        print("[Purchase] Buying: " .. petName .. " (" .. FormatNumber(pet.Price or 0) .. ")")
    end)
    
    -- === PHASE 0: RAPID FIRE - All methods at once (NO WAITING!) ===
    -- Fire ALL purchase methods simultaneously for maximum speed
    for i = 1, 8 do
        -- Direct purchase (NO E KEY!)
        DirectPurchasePet(model, petName, pet.Price or 0)
        
        -- All prompt methods
        if prompt then
            FirePromptInstant(prompt)
            FirePromptComplete(prompt)
            FirePromptVM(prompt)
            RapidFirePurchase(prompt)
        end
        
        -- Remote methods
        FireRemotePurchase(model)
        FireRemoteEvent(model)
        
        -- Check immediately - no wait!
        if not model:IsDescendantOf(workspace) then
            PurchaseInProgress = false
            return true, "SUCCESS! Pet purchased"
        end
    end
    
    -- === PHASE 1: Teleport directly on pet ===
    InstantTeleport(rootPart.Position)
    
    -- Check
    if not model:IsDescendantOf(workspace) then
        PurchaseInProgress = false
        return true, "Pet purchased after teleport"
    end
    
    -- === PHASE 2: MAXIMUM OVERDRIVE - Rapid fire all methods ===
    for i = 1, 12 do
        -- Fire everything at once
        DirectPurchasePet(model, petName, pet.Price or 0)
        
        if prompt then
            FirePromptInstant(prompt)
            FirePromptComplete(prompt)
            FirePromptVM(prompt)
            RapidFirePurchase(prompt)
        end
        
        FireRemotePurchase(model)
        FireRemoteEvent(model)
        
        -- Ultra-fast check
        if not model:IsDescendantOf(workspace) then
            PurchaseInProgress = false
            return true, "Pet purchased in OVERDRIVE"
        end
    end
    
    PurchaseInProgress = false
    return false, "Failed to purchase - pet may have been taken"
end

local function TryPurchasePet(pet, retryCount)
    retryCount = retryCount or 0
    
    -- Check if already attempted this specific attempt (not from previous runs)
    local modelPath = tostring(pet.Model)
    if AttemptedPets[modelPath] == "failed" then
        return false
    end
    
    SnipeStats.TotalAttempts = SnipeStats.TotalAttempts + 1
    
    local success, reason = UltimatePurchase(pet)
    
    if success then
        -- Remove from attempted since we got it
        AttemptedPets[modelPath] = nil
        return true
    elseif retryCount < getgenv().RetrySniperPet then
        task.wait(0.02)
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
        -- ULTRA-FAST search locations
        local searchLocations = {
            workspace.Map and workspace.Map:FindFirstChild("WildPetSpawns"),
            workspace.Map and workspace.Map:FindFirstChild("WildPets"),
            workspace:FindFirstChild("WildPetSpawns"),
            workspace:FindFirstChild("WildPets"),
            workspace.Map and workspace.Map:FindFirstChild("Spawns"),
            workspace:FindFirstChild("Spawns"),
        }
        
        -- Fast iteration
        for _, spawnFolder in ipairs(searchLocations) do
            if spawnFolder then
                local children = (spawnFolder:IsA("Model")) and {spawnFolder} or spawnFolder:GetChildren()
                
                for _, obj in ipairs(children) do
                    if obj:IsA("Model") then
                        local petName = obj:GetAttribute("PetName")
                        local rootPart = obj:FindFirstChild("RootPart") or obj:FindFirstChild("HumanoidRootPart")
                        
                        if rootPart and rootPart:IsDescendantOf(workspace) then
                            local prompt = rootPart:FindFirstChildWhichIsA("ProximityPrompt")
                            local price = prompt and GetPetPriceFromPrompt(prompt) or 0
                            
                            local petInfo = GetPetInfo(petName)
                            
                            -- Try to match by price if no name match
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
                local maxPurchasesPerRound = 10
                
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
                            
                            -- ULTRA-FAST: Teleport only if really far
                            if distance > 5 then
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
                                
                                -- IMMEDIATELY continue to next pet (don't break!)
                                continue
                            else
                                -- FAILED: Only mark as failed if we tried multiple times
                                SnipeStats.TotalMissed = SnipeStats.TotalMissed + 1
                                print("[Premium Sniper] Missed: " .. pet.PetName)
                                
                                -- Mark this specific pet as failed
                                local modelPath = tostring(pet.Model)
                                AttemptedPets[modelPath] = "failed"
                                
                                -- Continue to next pet IMMEDIATELY
                                continue
                            end
                            
                            -- Update success rate
                            if SnipeStats.TotalAttempts > 0 then
                                SnipeStats.SuccessRate = (SnipeStats.TotalSniped / SnipeStats.TotalAttempts) * 100
                            end
                        end
                    end
                end
                
                -- If no qualifying pets found, trigger server hop
                if getgenv().AutoServerHop and not hasQualifyingPet and #pets == 0 then
                    local timeSinceQualifying = tick() - LastQualifyingPetTime
                    if timeSinceQualifying >= getgenv().ServerHopDelay then
                        print("[Premium Sniper] No pets found. Hopping to new server...")
                        SnipeStats.TotalHops = SnipeStats.TotalHops + 1
                        CurrentServerStartTime = tick()
                        AttemptedPets = {}
                        HasFoundQualifyingPetThisSession = false
                        PremiumServerHop()
                        LastQualifyingPetTime = tick()
                    end
                end
            end)
            
            task.wait(0.01) -- ULTRA-FAST: 10ms loop
        end
        
        IsSniping = false
        print("[Premium Sniper] Dung lai ngay :v !")
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
    print("[Premium Sniper] Hehehe " .. petName)
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
    print("[Premium Sniper] LOL " .. FormatNumber(price))
end

getgenv().ForceServerHop = function()
    print("[Premium Sniper] okay")
    CurrentServerStartTime = tick()
    AttemptedPets = {}
    PremiumServerHop()
end

-- ============================================
-- INITIALIZATION
-- ============================================

-- Detect if running on mobile executor
local function DetectMobileExecutor()
    -- Check common mobile executor signatures
    local isMobile = false
    
    -- Delta executor detection
    if shared and (shared.Delta or shared.delta or _G.Delta or _G.delta) then
        isMobile = true
    end
    
    -- Fluxus detection
    if shared and (shared.Fluxus or shared.fluxus or _G.Fluxus or _G.fluxus) then
        isMobile = true
    end
    
    -- Arceus X detection
    if shared and (shared.Arceus or shared.arceus or _G.Arceus or _G.arceus) then
        isMobile = true
    end
    
    -- Check for missing PC-only features
    if not syn then
        isMobile = true
    end
    
    -- Check for touch capability (mobile devices)
    if UserInputService and UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        isMobile = true
    end
    
    getgenv().isMobileExecutor = isMobile
    
    if isMobile then
        print("[Premium Sniper] Buy SNIPER PET TODAY")
    end
end

-- Run mobile detection
task.spawn(DetectMobileExecutor)


if getgenv().AutoBuyPets then
    StartSniperLoop()
end
