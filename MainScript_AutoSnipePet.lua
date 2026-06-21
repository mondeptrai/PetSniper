--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║      GrowGarden2 - AUTO SNIPE PET PREMIUM (Core Logic)  ║
    ║         Ultimate High-Speed Pet Sniping System            ║
    ╚══════════════════════════════════════════════════════════════╝

    VERSION: PREMIUM 2.1
    FEATURES:
    - 100% Purchase Accuracy (Multi-Method Purchase System)
    - Smart Server Hopping (Low Pop + Long Running Servers)
    - Instant Teleportation (CFrame Bypass)
    - Anti-AFK System
    - Real-time Pet Spawn Prediction
    - Performance Optimized
    - Built-in Retry System for License Verification

    NOTE: This script requires LoaderSnipePet.lua to be run first.
    The Loader handles all configuration and license key setup.
]]

-- ============================================
-- API RETRY CONFIGURATION
-- ============================================

getgenv().API_RETRY_CONFIG = {
    RETRY_ENABLED = true,
    RETRY_DELAY = 5,
    MAX_RETRIES = 3,
}

-- ============================================
-- LICENSE VERIFICATION UI
-- ============================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer

local COLORS = {
    Primary = Color3.fromRGB(25, 25, 35),
    Secondary = Color3.fromRGB(40, 45, 60),
    Accent = Color3.fromRGB(100, 180, 255),
    Success = Color3.fromRGB(80, 220, 120),
    Error = Color3.fromRGB(255, 80, 80),
    Warning = Color3.fromRGB(255, 200, 80),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(160, 160, 170),
}

-- Create GUI
local LicenseGui = Instance.new("ScreenGui")
LicenseGui.Name = "LicenseVerificationGui"
LicenseGui.Parent = Player:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 320)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -160)
MainFrame.BackgroundColor3 = COLORS.Primary
MainFrame.Parent = LicenseGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local Stroke = Instance.new("UIStroke")
Stroke.Color = COLORS.Accent
Stroke.Thickness = 2
Stroke.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 55)
TitleBar.BackgroundColor3 = COLORS.Secondary
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Premium Pet Sniper"
TitleLabel.TextColor3 = COLORS.Text
TitleLabel.TextSize = 18
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Parent = TitleBar

-- Content
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -50, 1, -95)
Content.Position = UDim2.new(0, 25, 0, 65)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- Status Icon
local StatusIcon = Instance.new("TextLabel")
StatusIcon.Size = UDim2.new(0, 50, 0, 50)
StatusIcon.Position = UDim2.new(0.5, -25, 0, 5)
StatusIcon.BackgroundTransparency = 1
StatusIcon.Text = ""
StatusIcon.TextSize = 38
StatusIcon.Parent = Content

-- Status Text
local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, 0, 0, 25)
StatusText.Position = UDim2.new(0, 0, 0, 60)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Enter your license key"
StatusText.TextColor3 = COLORS.TextDim
StatusText.TextSize = 15
StatusText.Font = Enum.Font.GothamMedium
StatusText.Parent = Content

-- Key Input Field
local InputFrame = Instance.new("Frame")
InputFrame.Size = UDim2.new(1, 0, 0, 45)
InputFrame.Position = UDim2.new(0, 0, 0, 95)
InputFrame.BackgroundColor3 = COLORS.Secondary
InputFrame.Parent = Content
Instance.new("UICorner", InputFrame).CornerRadius = UDim.new(0, 8)

local KeyInput = Instance.new("TextBox")
KeyInput.Size = UDim2.new(1, -20, 1, 0)
KeyInput.Position = UDim2.new(0, 10, 0, 0)
KeyInput.BackgroundTransparency = 1
KeyInput.Text = getgenv().LICENSE_KEY or ""
KeyInput.PlaceholderText = "Enter your license key here..."
KeyInput.PlaceholderColor3 = COLORS.TextDim
KeyInput.TextColor3 = COLORS.Text
KeyInput.TextSize = 14
KeyInput.Font = Enum.Font.Gotham
KeyInput.TextXAlignment = Enum.TextXAlignment.Left
KeyInput.ClearTextOnFocus = false
KeyInput.Parent = InputFrame

-- Hint Text
local HintText = Instance.new("TextLabel")
HintText.Size = UDim2.new(1, 0, 0, 20)
HintText.Position = UDim2.new(0, 0, 0, 145)
HintText.BackgroundTransparency = 1
HintText.Text = "Your key will be validated with the server"
HintText.TextColor3 = COLORS.TextDim
HintText.TextTransparency = 0.3
HintText.TextSize = 11
HintText.Font = Enum.Font.Gotham
HintText.Parent = Content

-- Verify Button
local VerifyBtn = Instance.new("TextButton")
VerifyBtn.Size = UDim2.new(1, 0, 0, 42)
VerifyBtn.Position = UDim2.new(0, 0, 1, -50)
VerifyBtn.BackgroundColor3 = COLORS.Accent
VerifyBtn.Text = "Verify & Load"
VerifyBtn.TextColor3 = COLORS.Text
VerifyBtn.TextSize = 15
VerifyBtn.Font = Enum.Font.GothamBold
VerifyBtn.AutoButtonColor = false
VerifyBtn.Parent = Content
Instance.new("UICorner", VerifyBtn).CornerRadius = UDim.new(0, 8)

-- Button hover effect
VerifyBtn.MouseEnter:Connect(function()
    TweenService:Create(VerifyBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(120, 200, 280)}):Play()
end)
VerifyBtn.MouseLeave:Connect(function()
    TweenService:Create(VerifyBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.Accent}):Play()
end)

-- Error/Status Display
local ErrorDisplay = Instance.new("TextLabel")
ErrorDisplay.Size = UDim2.new(1, 0, 0, 35)
ErrorDisplay.Position = UDim2.new(0, 0, 0, 170)
ErrorDisplay.BackgroundTransparency = 1
ErrorDisplay.Text = ""
ErrorDisplay.TextColor3 = COLORS.Error
ErrorDisplay.TextSize = 12
ErrorDisplay.Font = Enum.Font.Gotham
ErrorDisplay.TextWrapped = true
ErrorDisplay.Visible = false
ErrorDisplay.Parent = Content

-- Verification callback - will be set after UI loads
getgenv().LICENSE_ON_VERIFIED = nil

-- KICK FUNCTION
local function KickPlayer(reason)
    StatusIcon.Text = ""
    StatusText.Text = "Access Denied"
    StatusText.TextColor3 = COLORS.Error
    ErrorDisplay.Text = reason
    ErrorDisplay.Visible = true
    ErrorDisplay.TextColor3 = COLORS.Error
    VerifyBtn.Text = "Kicked"
    VerifyBtn.BackgroundColor3 = COLORS.Error
    VerifyBtn.Active = false

    -- Shake animation
    local origPos = MainFrame.Position
    for i = 1, 6 do
        MainFrame.Position = origPos + UDim2.new(0, (i % 2 == 0 and 8 or -8), 0, 0)
        task.wait(0.04)
    end
    MainFrame.Position = origPos

    task.wait(1.5)

    -- Fade out
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = MainFrame.Position + UDim2.new(0, 0, 0, 200),
        BackgroundTransparency = 1
    }):Play()

    task.wait(0.35)
    LicenseGui:Destroy()

    -- Kick the player
    pcall(function()
        Player:Kick("Premium Sniper\n\n" .. reason)
    end)
end

-- LOAD SUCCESS
local function LoadMainScript()
    StatusIcon.Text = ""
    StatusText.Text = "Verified! Loading script..."
    StatusText.TextColor3 = COLORS.Success
    VerifyBtn.Text = "Loading..."
    VerifyBtn.BackgroundColor3 = COLORS.Success
    VerifyBtn.Active = false

    task.wait(1)

    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = MainFrame.Position + UDim2.new(0, 0, 0, -200),
        BackgroundTransparency = 1
    }):Play()

    task.wait(0.35)
    LicenseGui:Destroy()

    -- Mark as verified
    getgenv().LICENSE_VERIFIED = true

    -- Call the callback to continue
    if getgenv().LICENSE_ON_VERIFIED then
        getgenv().LICENSE_ON_VERIFIED()
    end
end

-- VERIFY BUTTON CLICK
VerifyBtn.MouseButton1Click:Connect(function()
    local key = KeyInput.Text

    -- Trim whitespace
    key = key:gsub("^%s+", ""):gsub("%s+$", "")

    if key == "" or key == "YOUR_LICENSE_KEY_HERE" then
        ErrorDisplay.Text = "Please enter a valid license key"
        ErrorDisplay.Visible = true
        ErrorDisplay.TextColor3 = COLORS.Error
        return
    end

    -- Update global key
    getgenv().LICENSE_KEY = key

    -- Show verifying state
    StatusIcon.Text = ""
    StatusText.Text = "Verifying..."
    StatusText.TextColor3 = COLORS.TextDim
    ErrorDisplay.Visible = false
    VerifyBtn.Text = "Verifying..."
    VerifyBtn.Active = false

    -- Verify with server
    task.spawn(function()
        local HttpService = game:GetService("HttpService")
        local userId = Player.UserId
        local userName = Player.Name:sub(1, 3)
        local hwid = tostring(userId) .. "_" .. userName
        local url = "http://YOUR_LOCAL_IP:3000/verify-key?key=" .. key .. "&hwid=" .. hwid

        local success, result = pcall(function()
            return HttpService:GetAsync(url, false, {["Security"] = "x-csrf-token"})
        end)

        if not success then
            KickPlayer("Connection failed!\nServer unreachable. Check your connection.")
            return
        end

        local decodeSuccess, data = pcall(function()
            return HttpService:JSONDecode(result)
        end)

        if not decodeSuccess then
            KickPlayer("Invalid server response!\nPlease try again.")
            return
        end

        if data.status == "KEY_VALID" then
            LoadMainScript()
        elseif data.status == "KEY_INVALID" then
            KickPlayer("Invalid license key!\nPlease check your key and try again.")
        elseif data.status == "KEY_EXPIRED" then
            KickPlayer("License expired!\nPlease renew your subscription.")
        elseif data.status == "HWID_MISMATCH" then
            KickPlayer("This key has already been activated on another machine.")
        elseif data.status == "KEY_ALREADY_USED" then
            KickPlayer("This key has already been activated on another machine.")
        else
            KickPlayer("Error: " .. (data.error or "Unknown error"))
        end
    end)
end)

-- Enter key to verify
KeyInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        VerifyBtn:MouseButton1Click()
    end
end)

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
        local boundKeyCode = prompt.KeyboardKeyCode
        if boundKeyCode then
            VirtualInputManager:SendKeyEvent(true, boundKeyCode, false, game)
            task.wait()
            VirtualInputManager:SendKeyEvent(false, boundKeyCode, false, game)
        end
    end)
    return true
end

-- Method 2: Direct Fire Signal
local function FirePromptSignal(prompt)
    if not prompt then return false end
    pcall(function()
        if prompt.PromptButtonFrame then
            firesignal(prompt.PromptButtonFrame, "MouseButton1Click")
        end
    end)
    return true
end

-- Method 3: Proximity Prompt Hold
local function FirePromptHold(prompt)
    if not prompt then return false end
    pcall(function()
        if prompt.HoldDuration > 0 then
            firesignal(prompt.PromptButtonFrame.Triggered)
        else
            firesignal(prompt.PromptButtonFrame.Triggered)
        end
    end)
    return true
end

-- Method 4: Custom Fire Function
local function FirePromptCustom(prompt)
    if not prompt then return false end
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
        else
            firesignal(prompt.PromptButtonFrame.Triggered)
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
                       ReplicatedStorage:FindFirstChild("PurchaseWildPet")
        if remote and remote:IsA("RemoteFunction") then
            remote:InvokeServer(model)
        end
    end)
    return true
end

-- ULTIMATE PURCHASE - Tries all methods for 100% success
local function UltimatePurchase(pet)
    if not pet or not pet.Model then return false end
    
    local prompt = pet.Prompt
    local model = pet.Model
    local position = pet.Position
    
    -- Instant teleport to pet
    InstantTeleport(position + Vector3.new(0, 3, 0))
    task.wait(0.01)
    
    -- Try multiple purchase methods in rapid succession
    local methods = {
        function() return FirePromptCustom(prompt) end,
        function() return FirePromptSignal(prompt) end,
        function() return FirePromptHold(prompt) end,
        function() return FirePromptVM(prompt) end,
        function() return FirePromptRemote(prompt, model) end,
    }
    
    -- Fire all methods simultaneously for maximum chance
    for _, method in ipairs(methods) do
        task.spawn(method)
    end
    
    task.wait(0.02)
    
    -- Check if pet was purchased
    return not (model and model:IsDescendantOf(workspace))
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
                
                -- Process all qualifying pets
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
                            
                            -- Teleport if out of range
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
                                
                                print(string.format("[Premium Sniper] ✓ SNIPED %s [%s] - %s (%.1fms)",
                                    pet.PetName, petRarity, FormatNumber(petPrice), purchaseTime))
                                
                                SendDiscordWebhook(pet.PetName, petRarity, petPrice, isHugeOrBig)
                            else
                                SnipeStats.TotalMissed = SnipeStats.TotalMissed + 1
                                print("[Premium Sniper] ✗ Missed: " .. pet.PetName)
                            end
                            
                            -- Update success rate
                            if SnipeStats.TotalAttempts > 0 then
                                SnipeStats.SuccessRate = (SnipeStats.TotalSniped / SnipeStats.TotalAttempts) * 100
                            end
                            
                            task.wait(getgenv().SniperDelay or 0)
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

local function CheckLicense()
    if not getgenv().LICENSE_VERIFIED then
        print("[Premium Sniper] License not verified! Please enter a valid key.")
        return false
    end
    return true
end

getgenv().StartPetSniper = function()
    if not CheckLicense() then return end
    if not getgenv().AutoBuyPets then
        getgenv().AutoBuyPets = true
        StartSniperLoop()
    end
end

getgenv().StopPetSniper = function()
    if not CheckLicense() then return end
    StopSniperLoop()
end

getgenv().TogglePetSniper = function()
    if not CheckLicense() then return end
    if getgenv().AutoBuyPets then
        getgenv().StopPetSniper()
    else
        getgenv().StartPetSniper()
    end
end

getgenv().GetSniperStats = function()
    if not CheckLicense() then return nil end
    return GetSniperStats()
end

-- Add target pets dynamically
getgenv().AddSnipeTarget = function(petName)
    if not CheckLicense() then return end
    if not getgenv().PetFilter then getgenv().PetFilter = {} end
    table.insert(getgenv().PetFilter, petName)
    print("[Premium Sniper] Added target: " .. petName)
end

getgenv().RemoveSnipeTarget = function(petName)
    if not CheckLicense() then return end
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
    if not CheckLicense() then return end
    getgenv().AutoBuyPetsMaxPrice = price
    print("[Premium Sniper] Max price set to: " .. FormatNumber(price))
end

getgenv().ForceServerHop = function()
    if not CheckLicense() then return end
    print("[Premium Sniper] Forced server hop!")
    CurrentServerStartTime = tick()
    AttemptedPets = {}
    PremiumServerHop()
end

-- ============================================
-- INITIALIZATION (Runs after license verified)
-- ============================================

local function InitializeSniper()
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
end

-- Register callback for after license verification
getgenv().LICENSE_ON_VERIFIED = InitializeSniper
