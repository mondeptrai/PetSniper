--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║           GrowGarden2 - Auto Sniper Pet (Core Logic)  ║
    ║              High-Speed Pet Sniping System               ║
    ╚══════════════════════════════════════════════════════════════╝
    
    USAGE:
    1. First edit LoaderSnipePet.lua to configure settings
    2. Run LoaderSnipePet.lua BEFORE this script
    3. Then run this script (MainScript_AutoSnipePet.lua)
    
    OR simply run LoaderSnipePet.lua - it will auto-load this script
]]

-- ============================================
-- AUTO-LOADER (Run LoaderSnipePet.lua first!)
-- ============================================

if not getgenv().SniperConfig then
    warn("[Sniper] Please run LoaderSnipePet.lua first to configure settings!")
    warn("[Sniper] Get it from: LoaderSnipePet.lua")
end

-- ============================================
-- CONFIGURATION LOADER (ConfigLoaderSnipePet)
-- ============================================

-- Load settings from SniperConfig if available
if getgenv().SniperConfig then
    getgenv().AutoBuyPets = getgenv().SniperConfig.Enabled or false
    getgenv().AutoBuyPetsMaxPrice = getgenv().SniperConfig.MaxPrice or 0
    getgenv().AutoBuyPetsRarityFilter = getgenv().SniperConfig.RarityFilter or {}
    getgenv().PetFilter = getgenv().SniperConfig.SpecificPets or {}
    getgenv().SniperDelay = getgenv().SniperConfig.SniperDelay or 0.1
    getgenv().RetrySniperPet = getgenv().SniperConfig.RetryAttempts or 3
    getgenv().SniperRange = getgenv().SniperConfig.TeleportRange or 50
    getgenv().DiscordWebhook = getgenv().SniperConfig.DiscordWebhook or {}
else
    getgenv().AutoBuyPets = getgenv().AutoBuyPets or false
    getgenv().AutoBuyPetsMaxPrice = getgenv().AutoBuyPetsMaxPrice or 0
    getgenv().AutoBuyPetsRarityFilter = getgenv().AutoBuyPetsRarityFilter or {}
    getgenv().PetFilter = getgenv().PetFilter or {}
    getgenv().SniperDelay = getgenv().SniperDelay or 0.1
    getgenv().RetrySniperPet = getgenv().RetrySniperPet or 3
    getgenv().SniperRange = getgenv().SniperRange or 50
    getgenv().DiscordWebhook = getgenv().DiscordWebhook or {}
end

getgenv().AutoServerHop = getgenv().AutoServerHop or getgenv().SniperConfig and getgenv().SniperConfig.AutoServerHop or false
getgenv().ServerHopDelay = getgenv().ServerHopDelay or getgenv().SniperConfig and getgenv().SniperConfig.ServerHopDelay or 15

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
-- DISCORD WEBHOOK
-- ============================================

local function SendDiscordWebhook(petName, rarity, price, isHugeOrBig)
    local webhookConfig = getgenv().DiscordWebhook
    if not webhookConfig or not webhookConfig.Enabled or not webhookConfig.URL or webhookConfig.URL == "" then
        return
    end
    
    -- Check rarity filter
    local rarityFilter = webhookConfig.RarityFilter
    if not isHugeOrBig then
        if not rarityFilter[rarity] then
            return
        end
    else
        if not (rarityFilter["Huge"] or rarityFilter["Big"] or rarityFilter[rarity]) then
            return
        end
    end
    
    task.spawn(function()
        pcall(function()
            local HttpService = game:GetService("HttpService")
            
            -- Rarity colors (Discord embed color)
            local rarityColors = {
                Common = 9807270,
                Uncommon = 16744448,
                Rare = 2127726,
                Epic = 9933999,
                Legendary = 16750848,
                Mythic = 12519404,
                Super = 16724269,
            }
            local color = rarityColors[rarity] or 9807270
            
            -- Format price
            local priceText = ""
            if webhookConfig.ShowPrice and price > 0 then
                priceText = "\n**Price:** " .. FormatNumber(price) .. " Sheckles"
            end
            
            -- Timestamp
            local timestampText = ""
            if webhookConfig.ShowTimestamp then
                timestampText = "\n**Time:** " .. os.date("%Y-%m-%d %H:%M:%S UTC+7")
            end
            
            -- Ping
            local pingText = webhookConfig.PingOnSnipe and "@everyone" or ""
            
            -- Build embed
            local embed = {
                {
                    ["title"] = (isHugeOrBig and "HUGE/BIG" or rarity) .. " PET SNIPED!",
                    ["description"] = "**Pet:** " .. petName .. priceText .. timestampText,
                    ["color"] = color,
                    ["footer"] = {
                        ["text"] = "GrowGarden2 Pet Sniper",
                    },
                }
            }
            
            local payload = {
                ["content"] = pingText,
                ["embeds"] = embed,
            }
            
            local jsonPayload = HttpService:JSONEncode(payload)
            
            local requestPromise = syn and syn.request or http_request or request
            if requestPromise then
                requestPromise({
                    Url = webhookConfig.URL,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json",
                    },
                    Body = jsonPayload,
                })
            end
        end)
    end)
end

-- ============================================
-- STATE TRACKING
-- ============================================

local ActivePets = {}
local SnipedPets = {}
local LastSnipeTime = 0
local IsSniping = false
local SnipeStats = {
    TotalSniped = 0,
    TotalSpent = 0,
    TotalMissed = 0,
    TotalHops = 0,
}
local LastQualifyingPetTime = 0
local HasFoundQualifyingPetThisSession = false

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
    if PetData[petName] then
        return PetData[petName]
    end
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
-- SERVER HOP FUNCTION
-- ============================================

local function ServerHop()
    if not getgenv().AutoServerHop then
        return false
    end
    
    print("[Sniper] No qualifying pets found. Initiating server hop...")
    
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    local PlaceId = game.PlaceId
    
    local success, result = pcall(function()
        local request = syn and syn.request or http_request or request
        if not request then
            print("[Sniper] HTTP request not available")
            return false
        end
        
        -- Get server list via Roblox API
        local response = request({
            Url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
            Method = "GET"
        })
        
        if not response or response.StatusCode ~= 200 then
            print("[Sniper] Failed to get server list")
            return false
        end
        
        local data = HttpService:JSONDecode(response.Body)
        if not data or not data.data then
            print("[Sniper] Invalid server list response")
            return false
        end
        
        local servers = {}
        for _, server in ipairs(data.data) do
            -- Filter out current server and full servers
            if server.id ~= game.JobId and server.playing and server.playing < server.maxPlayers then
                table.insert(servers, server)
            end
        end
        
        if #servers == 0 then
            print("[Sniper] No available servers found")
            return false
        end
        
        -- Sort by player count (lower = better chance of unsold pets)
        table.sort(servers, function(a, b)
            return (a.playing or 0) < (b.playing or 0)
        end)
        
        -- Pick a random server from the first 10 (prefer low pop)
        local maxIndex = math.min(10, #servers)
        local chosenServer = servers[math.random(1, maxIndex)]
        
        print("[Sniper] Hopping to server with " .. chosenServer.playing .. "/" .. chosenServer.maxPlayers .. " players")
        
        -- Teleport with pcall protection
        pcall(function()
            TeleportService:TeleportToSpawnByName(PlaceId, chosenServer.id, Player)
        end)
        
        return true
    end)
    
    if success then
        return result
    else
        print("[Sniper] Server hop failed: " .. tostring(result))
        return false
    end
end

-- ============================================
-- CONFIGURATION CHECK FUNCTIONS
-- ============================================

local function ShouldBuyPet(petName, petInfo, price)
    if IsHugeOrBig(petName) then
        print("[Sniper] Detected HUGE/BIG pet: " .. petName .. " - PRIORITY BUY!")
        return true, true
    end
    
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
    
    if petInfo then
        local rarity = petInfo.Rarity
        local rarityEnabled = getgenv().AutoBuyPetsRarityFilter[rarity]
        if rarityEnabled == false then
            return false, false
        end
    end
    
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
        local spawnLocations = {
            workspace.Map and workspace.Map:FindFirstChild("WildPetSpawns"),
            workspace:FindFirstChild("WildPetSpawns"),
            workspace.Map and workspace.Map:FindFirstChild("WildPets"),
        }
        
        for _, spawnFolder in ipairs(spawnLocations) do
            if spawnFolder and (spawnFolder:IsA("Folder") or spawnFolder:IsA("Model")) then
                for _, obj in pairs(spawnFolder:GetChildren()) do
                    if obj:IsA("Model") and obj.Name:find("WildPet") then
                        local petName = obj:GetAttribute("PetName")
                        local rootPart = obj:FindFirstChild("RootPart")
                        
                        if rootPart and rootPart:IsDescendantOf(workspace) then
                            local prompt = rootPart:FindFirstChildWhichIsA("ProximityPrompt")
                            local price = prompt and GetPetPriceFromPrompt(prompt) or 0
                            
                            local petInfo = GetPetInfo(petName)
                            if not petInfo and price > 0 then
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
            if prompt and prompt:IsA("ProximityPrompt") then
                firesignal(prompt.PromptButtonFrame.Triggered)
            end
        end
    end)
end

local function TryPurchasePet(pet, retryCount)
    retryCount = retryCount or 0
    
    pcall(function()
        local targetPos = pet.Position + Vector3.new(0, 3, 0)
        TeleportTo(targetPos)
        task.wait(0.02)
        
        if pet.Prompt then
            FireProximityPrompt(pet.Prompt)
        end
    end)
    
    task.wait(getgenv().SniperDelay or 0.1)
    
    local stillExists = pet.Model and pet.Model:IsDescendantOf(workspace)
    
    if not stillExists then
        return true
    elseif retryCount < getgenv().RetrySniperPet then
        return TryPurchasePet(pet, retryCount + 1)
    end
    
    return false
end

-- ============================================
-- MAIN SNIPER LOOP (Mainscript_AutoSnipePet)
-- ============================================

local function StartSniperLoop()
    IsSniping = true
    print("[Sniper] Auto Sniper Pet started!")
    print("[Sniper] Config - MaxPrice: " .. getgenv().AutoBuyPetsMaxPrice .. ", Delay: " .. getgenv().SniperDelay)
    
    task.spawn(function()
        while IsSniping and getgenv().AutoBuyPets do
            pcall(function()
                if not getgenv().AutoBuyPets then
                    task.wait(0.5)
                    return
                end
                
                local pets = FindWildPets()
                local hasQualifyingPet = false
                
                if #pets == 0 then
                    print("[Sniper] No pets found on map")
                end
                
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
                
                table.sort(pets, function(a, b)
                    local aIsSpecial = IsHugeOrBig(a.PetName)
                    local bIsSpecial = IsHugeOrBig(b.PetName)
                    
                    if aIsSpecial and not bIsSpecial then return true end
                    if not aIsSpecial and bIsSpecial then return false end
                    
                    local rarityA = RARITY_PRIORITY[a.PetInfo and a.PetInfo.Rarity or "Common"] or 0
                    local rarityB = RARITY_PRIORITY[b.PetInfo and b.PetInfo.Rarity or "Common"] or 0
                    if rarityA ~= rarityB then
                        return rarityA > rarityB
                    end
                    
                    local distA = (hrp.Position - a.Position).Magnitude
                    local distB = (hrp.Position - b.Position).Magnitude
                    return distA < distB
                end)
                
                for _, pet in ipairs(pets) do
                    if not IsSniping or not getgenv().AutoBuyPets then
                        break
                    end
                    
                    if pet.Model and pet.Model:IsDescendantOf(workspace) then
                        local shouldBuy, isHugeOrBig = ShouldBuyPet(pet.PetName, pet.PetInfo, pet.Price)
                        
                        if shouldBuy then
                            hasQualifyingPet = true
                            LastQualifyingPetTime = tick()
                            HasFoundQualifyingPetThisSession = true
                            
                            local distance = (hrp.Position - pet.Position).Magnitude
                            local petRarity = pet.PetInfo and pet.PetInfo.Rarity or "Unknown"
                            local petPrice = pet.Price > 0 and pet.Price or (pet.PetInfo and pet.PetInfo.Price) or 0
                            
                            if isHugeOrBig then
                                print("[Sniper] SNIPING HUGE/BIG PET: " .. pet.PetName .. " (Rarity: " .. petRarity .. ", Price: " .. petPrice .. ")")
                            else
                                print("[Sniper] Sniping: " .. pet.PetName .. " [Rarity: " .. petRarity .. ", Price: " .. petPrice .. "]")
                            end
                            
                            if distance > (getgenv().SniperRange or 50) then
                                TeleportTo(pet.Position + Vector3.new(0, 3, 0))
                                task.wait(0.05)
                            end
                            
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
                                print("[Sniper] Successfully sniped: " .. pet.PetName)
                                
                                -- Send Discord webhook notification
                                SendDiscordWebhook(pet.PetName, petRarity, petPrice, isHugeOrBig)
                            else
                                SnipeStats.TotalMissed = SnipeStats.TotalMissed + 1
                                print("[Sniper] Failed to snipe: " .. pet.PetName)
                            end
                            
                            task.wait(getgenv().SniperDelay or 0.1)
                        end
                    end
                end
                
                -- Server Hop Logic
                if getgenv().AutoServerHop then
                    if not hasQualifyingPet then
                        local timeSinceQualifying = tick() - LastQualifyingPetTime
                        if timeSinceQualifying >= getgenv().ServerHopDelay then
                            if HasFoundQualifyingPetThisSession then
                                print("[Sniper] Qualifying pet(s) existed but were bought/missed. Waiting for new ones...")
                            else
                                print("[Sniper] No qualifying pets found after " .. getgenv().ServerHopDelay .. "s. Hopping servers...")
                                SnipeStats.TotalHops = SnipeStats.TotalHops + 1
                                ServerHop()
                                -- Reset tracking after hop
                                HasFoundQualifyingPetThisSession = false
                                LastQualifyingPetTime = tick()
                            end
                        end
                    else
                        LastQualifyingPetTime = tick()
                    end
                end
            end)
            
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
-- UI CREATION
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
    Title.Text = "Pet Sniper Status"
    Title.TextColor3 = Color3.fromRGB(255, 200, 75)
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.Parent = MainFrame
    
    local StatusText = Instance.new("TextLabel")
    StatusText.Name = "StatusText"
    StatusText.Size = UDim2.new(1, -20, 0, 20)
    StatusText.Position = UDim2.new(0, 10, 0, 35)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "Stopped"
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
    SnipedText.Text = "Sniped: 0"
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
    SpentText.Text = "Spent: 0"
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
    MissedText.Text = "Missed: 0"
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
    ShecklesText.Text = "Sheckles: Loading..."
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
    LastPetText.Text = "Last: None"
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
        statusText.Text = stats.IsRunning and "Running..." or "Stopped"
        statusText.TextColor3 = stats.IsRunning and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(150, 150, 170)
    end
    
    if snipedText then
        snipedText.Text = "Sniped: " .. stats.TotalSniped
    end
    
    if spentText then
        spentText.Text = "Spent: " .. FormatNumber(stats.TotalSpent)
    end
    
    if missedText then
        missedText.Text = "Missed: " .. stats.TotalMissed
    end
    
    if shecklesText then
        shecklesText.Text = "Sheckles: " .. FormatNumber(stats.CurrentSheckles)
    end
    
    if lastPetText and #stats.RecentPets > 0 then
        local last = stats.RecentPets[#stats.RecentPets]
        lastPetText.Text = "Last: " .. last.Rarity .. " " .. last.Name
    end
end

task.spawn(function()
    while true do
        pcall(UpdateSniperUI)
        task.wait(1)
    end
end)

-- ============================================
-- COMMANDS / API
-- ============================================

getgenv().StartPetSniper = function()
    if not getgenv().AutoBuyPets then
        getgenv().AutoBuyPets = true
        StartSniperLoop()
        print("[Sniper] Started!")
    end
end

getgenv().StopPetSniper = function()
    StopSniperLoop()
    print("[Sniper] Stopped!")
end

getgenv().TogglePetSniper = function()
    if getgenv().AutoBuyPets then
        getgenv().StopPetSniper()
    else
        getgenv().StartPetSniper()
    end
end

getgenv().GetSniperStats = GetSniperStats

-- ============================================
-- INITIALIZATION
-- ============================================

print("GrowGarden2 - Auto Sniper Pet Loaded!")
print("Commands: getgenv().StartPetSniper() / getgenv().StopPetSniper() / getgenv().TogglePetSniper()")

if getgenv().AutoBuyPets then
    StartSniperLoop()
end
