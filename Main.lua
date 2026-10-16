--[[
    ╔══════════════════════════════════════════════╗
    ║   Grow a Garden - Auto Buy Seeds (Filtered)  ║
    ║   Executor: Delta / Fluxus / Solara / Codex  ║
    ║   Game: Grow a Garden (Roblox)               ║
    ╚══════════════════════════════════════════════╝
    
    Fitur:
    - Otomatis membeli benih berdasarkan Nama & Rarity (Kelangkaan)
    - Tab GUI: [Utama] [Rarity] [Pilih Benih]
    - Status & notifikasi real-time
    - Loop mode & Auto-retry jika gagal
    - Auto-detect Rarity dari game data
]]

-- ═══════════════════════════════════════════════
-- Services
-- ═══════════════════════════════════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

-- ═══════════════════════════════════════════════
-- Konfigurasi & Filter
-- ═══════════════════════════════════════════════
local CONFIG = {
    DELAY_BETWEEN_PURCHASES = 0.3,   -- Delay antar pembelian (detik)
    AUTO_RETRY = true,               -- Otomatis coba lagi jika gagal
    MAX_RETRIES = 3,                 -- Maksimal percobaan ulang
    BUY_QUANTITY = 1,                -- Jumlah per pembelian
    LOOP_MODE = false,               -- Mode loop (beli terus-menerus)
    LOOP_INTERVAL = 5,               -- Interval loop (detik)

    -- Filter (Jika tabel kosong = tidak membatasi / beli semua)
    SELECTED_NAMES = {},             -- Contoh: { ["Carrot Seed"] = true }
    SELECTED_RARITIES = {},          -- Contoh: { ["Rare"] = true }
}

-- ═══════════════════════════════════════════════
-- Database Rarity & Warna
-- ═══════════════════════════════════════════════
local RARITY_COLORS = {
    Common    = Color3.fromRGB(180, 180, 180),
    Uncommon  = Color3.fromRGB(80, 200, 120),
    Rare      = Color3.fromRGB(60, 140, 255),
    Epic      = Color3.fromRGB(180, 70, 255),
    Legendary = Color3.fromRGB(255, 185, 30),
    Mythic    = Color3.fromRGB(255, 60, 100),
}

local SEED_RARITY = {
    -- Common
    ["Carrot Seed"]       = "Common",
    ["Tomato Seed"]       = "Common",
    ["Potato Seed"]       = "Common",
    ["Wheat Seed"]        = "Common",
    ["Corn Seed"]         = "Common",
    ["Onion Seed"]        = "Common",
    ["Lettuce Seed"]      = "Common",

    -- Uncommon
    ["Strawberry Seed"]   = "Uncommon",
    ["Blueberry Seed"]    = "Uncommon",
    ["Pepper Seed"]       = "Uncommon",
    ["Tulip Seed"]        = "Uncommon",
    ["Daisy Seed"]        = "Uncommon",
    ["Rice Seed"]         = "Uncommon",

    -- Rare
    ["Watermelon Seed"]   = "Rare",
    ["Pumpkin Seed"]      = "Rare",
    ["Rose Seed"]         = "Rare",
    ["Cactus Seed"]       = "Rare",
    ["Mushroom Seed"]     = "Rare",
    ["Bamboo Seed"]       = "Rare",

    -- Epic
    ["Apple Seed"]        = "Epic",
    ["Orange Seed"]       = "Epic",
    ["Grape Seed"]        = "Epic",
    ["Lemon Seed"]        = "Epic",
    ["Cherry Seed"]       = "Epic",
    ["Sunflower Seed"]    = "Epic",

    -- Legendary
    ["Mango Seed"]        = "Legendary",
    ["Coconut Seed"]      = "Legendary",
    ["Dragonfruit Seed"]  = "Legendary",
    ["Starfruit Seed"]    = "Legendary",
    ["Golden Apple Seed"] = "Legendary",

    -- Mythic
    ["Moonflower Seed"]   = "Mythic",
    ["Rainbow Seed"]      = "Mythic",
    ["Crystal Seed"]      = "Mythic",
    ["Cosmic Seed"]       = "Mythic",
}

-- ═══════════════════════════════════════════════
-- Utility Functions
-- ═══════════════════════════════════════════════
local function notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title or "Auto Buy Seeds",
            Text = text or "",
            Duration = duration or 3
        })
    end)
end

local function log(msg)
    print("[AutoBuySeeds] " .. tostring(msg))
end

-- ═══════════════════════════════════════════════
-- Filter Matching Logic
-- ═══════════════════════════════════════════════
local function matchesFilters(seedName)
    local hasNameFilter = next(CONFIG.SELECTED_NAMES) ~= nil
    local hasRarityFilter = next(CONFIG.SELECTED_RARITIES) ~= nil
    local rarity = SEED_RARITY[seedName]

    local nameMatches = not hasNameFilter or CONFIG.SELECTED_NAMES[seedName] == true
    local rarityMatches = not hasRarityFilter or (rarity and CONFIG.SELECTED_RARITIES[rarity] == true)

    return nameMatches and rarityMatches
end

-- ═══════════════════════════════════════════════
-- Pencarian Remote Events / Functions
-- ═══════════════════════════════════════════════
local function findBuyRemote()
    local remotes = {}
    local searchPaths = {
        ReplicatedStorage,
        ReplicatedStorage:FindFirstChild("Remotes"),
        ReplicatedStorage:FindFirstChild("Events"),
        ReplicatedStorage:FindFirstChild("RemoteEvents"),
        ReplicatedStorage:FindFirstChild("Network"),
        ReplicatedStorage:FindFirstChild("Shared"),
    }
    
    local keywords = {"buy", "purchase", "shop", "seed", "store", "item", "transaction"}
    
    for _, path in pairs(searchPaths) do
        if path then
            for _, child in pairs(path:GetDescendants()) do
                if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                    local nameLower = child.Name:lower()
                    for _, keyword in pairs(keywords) do
                        if nameLower:find(keyword) then
                            table.insert(remotes, child)
                            log("Ditemukan remote: " .. child:GetFullName())
                            break
                        end
                    end
                end
            end
        end
    end
    
    return remotes
end

-- ═══════════════════════════════════════════════
-- Pencarian Benih & Deteksi Rarity Otomatis
-- ═══════════════════════════════════════════════
local function findAllSeeds()
    local seeds = {}
    local foundSet = {}

    local function addSeed(name, detectedRarity)
        if not foundSet[name] then
            foundSet[name] = true
            table.insert(seeds, name)
            if detectedRarity and not SEED_RARITY[name] then
                SEED_RARITY[name] = detectedRarity
            end
        end
    end

    local searchLocations = {
        ReplicatedStorage:FindFirstChild("Seeds"),
        ReplicatedStorage:FindFirstChild("Items"),
        ReplicatedStorage:FindFirstChild("ShopItems"),
        ReplicatedStorage:FindFirstChild("SeedData"),
        ReplicatedStorage:FindFirstChild("GameData"),
        ReplicatedStorage:FindFirstChild("Data"),
        ReplicatedStorage:FindFirstChild("Configs"),
        ReplicatedStorage:FindFirstChild("Assets"),
    }
    
    for _, location in pairs(searchLocations) do
        if location then
            for _, item in pairs(location:GetDescendants()) do
                local nameLower = item.Name:lower()
                if nameLower:find("seed") or nameLower:find("benih") then
                    -- Cek attribute atau child Rarity
                    local detectedRarity = item:GetAttribute("Rarity")
                    if not detectedRarity and item:FindFirstChild("Rarity") then
                        detectedRarity = item.Rarity.Value
                    end
                    addSeed(item.Name, detectedRarity)
                end
            end
        end
    end
    
    -- Cek ModuleScript
    for _, module in pairs(ReplicatedStorage:GetDescendants()) do
        if module:IsA("ModuleScript") then
            local nameLower = module.Name:lower()
            if nameLower:find("seed") or nameLower:find("shop") or nameLower:find("item") then
                local success, data = pcall(function()
                    return require(module)
                end)
                if success and type(data) == "table" then
                    for key, value in pairs(data) do
                        if type(key) == "string" and (key:lower():find("seed") or key:lower():find("benih")) then
                            local r = type(value) == "table" and (value.Rarity or value.rarity) or nil
                            addSeed(key, r)
                        end
                    end
                end
            end
        end
    end

    -- Fallback ke default list jika belum ada dari game
    if #seeds == 0 then
        for seedName, _ in pairs(SEED_RARITY) do
            addSeed(seedName, nil)
        end
    end

    table.sort(seeds)
    return seeds
end

-- ═══════════════════════════════════════════════
-- Fungsi Utama: Beli Benih (dengan Filter)
-- ═══════════════════════════════════════════════
local function buyFilteredSeeds()
    log("Memulai Auto Buy Seeds (Filtered)...")
    
    local allSeeds = findAllSeeds()
    local remotes = findBuyRemote()
    
    if #remotes == 0 then
        log("Tidak menemukan remote spesifik, mencoba semua remote...")
        for _, child in pairs(ReplicatedStorage:GetDescendants()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                table.insert(remotes, child)
            end
        end
    end

    -- Saring benih berdasarkan filter
    local filteredSeeds = {}
    for _, seedName in ipairs(allSeeds) do
        if matchesFilters(seedName) then
            table.insert(filteredSeeds, seedName)
        end
    end

    if #filteredSeeds == 0 then
        local msg = "Tidak ada benih yang sesuai filter!"
        log(msg)
        notify("Auto Buy Seeds", msg, 3)
        return 0, 0, 0
    end

    notify("Auto Buy Seeds", string.format("Membeli %d jenis benih sesuai filter...", #filteredSeeds), 3)

    local totalBought = 0
    local totalFailed = 0

    for _, seedName in ipairs(filteredSeeds) do
        local bought = false
        local retries = 0
        local rarity = SEED_RARITY[seedName] or "Unknown"

        while not bought and retries < CONFIG.MAX_RETRIES do
            for _, remote in pairs(remotes) do
                local success = pcall(function()
                    if remote:IsA("RemoteEvent") then
                        remote:FireServer("Buy", seedName, CONFIG.BUY_QUANTITY)
                        remote:FireServer("BuySeed", seedName, CONFIG.BUY_QUANTITY)
                        remote:FireServer("Purchase", seedName, CONFIG.BUY_QUANTITY)
                        remote:FireServer("PurchaseItem", {
                            Item = seedName,
                            Quantity = CONFIG.BUY_QUANTITY,
                            Type = "Seed"
                        })
                        remote:FireServer(seedName, CONFIG.BUY_QUANTITY)
                        remote:FireServer({
                            Action = "Buy",
                            ItemName = seedName,
                            Amount = CONFIG.BUY_QUANTITY
                        })
                    elseif remote:IsA("RemoteFunction") then
                        remote:InvokeServer("Buy", seedName, CONFIG.BUY_QUANTITY)
                        remote:InvokeServer("BuySeed", seedName, CONFIG.BUY_QUANTITY)
                        remote:InvokeServer("Purchase", seedName, CONFIG.BUY_QUANTITY)
                    end
                end)

                if success then
                    bought = true
                    totalBought = totalBought + 1
                    log(string.format("✅ Berhasil beli: %s [%s]", seedName, rarity))
                    break
                end
            end

            if not bought then
                retries = retries + 1
                if CONFIG.AUTO_RETRY and retries < CONFIG.MAX_RETRIES then
                    task.wait(0.4)
                end
            end
        end

        if not bought then
            totalFailed = totalFailed + 1
            log(string.format("❌ Gagal beli: %s [%s]", seedName, rarity))
        end

        task.wait(CONFIG.DELAY_BETWEEN_PURCHASES)
    end

    local summary = string.format("Selesai! Berhasil: %d | Gagal: %d | Total: %d", totalBought, totalFailed, #filteredSeeds)
    log(summary)
    notify("Auto Buy Seeds", summary, 4)
    return totalBought, totalFailed, #filteredSeeds
end

-- ═══════════════════════════════════════════════
-- GUI dengan Dukungan Tab Filter
-- ═══════════════════════════════════════════════
local function createGUI()
    if CoreGui:FindFirstChild("AutoBuySeedsGUI") then
        CoreGui:FindFirstChild("AutoBuySeedsGUI"):Destroy()
    end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoBuySeedsGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 320, 0, 380)
    MainFrame.Position = UDim2.new(0.02, 0, 0.25, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = MainFrame
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(80, 200, 120)
    MainStroke.Thickness = 2
    MainStroke.Parent = MainFrame
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 36)
    TitleBar.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 10)
    TitleCorner.Parent = TitleBar
    
    local TitleFix = Instance.new("Frame")
    TitleFix.Size = UDim2.new(1, 0, 0.5, 0)
    TitleFix.Position = UDim2.new(0, 0, 0.5, 0)
    TitleFix.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
    TitleFix.BorderSizePixel = 0
    TitleFix.Parent = TitleBar
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -40, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "🌱 Auto Buy Seeds (Filter)"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 14
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar
    
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 26, 0, 26)
    CloseBtn.Position = UDim2.new(1, -30, 0, 5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 13
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = TitleBar
    
    local CloseBtnCorner = Instance.new("UICorner")
    CloseBtnCorner.CornerRadius = UDim.new(0, 6)
    CloseBtnCorner.Parent = CloseBtn

    -- Tab Navigation
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(1, -16, 0, 30)
    TabBar.Position = UDim2.new(0, 8, 0, 42)
    TabBar.BackgroundTransparency = 1
    TabBar.Parent = MainFrame

    local function createTabBtn(name, text, posX, widthRatio)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(widthRatio, -4, 1, 0)
        btn.Position = UDim2.new(posX, 0, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.Parent = TabBar
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = btn
        return btn
    end

    local TabMainBtn = createTabBtn("TabMain", "🛒 Beli", 0, 0.33)
    local TabRarityBtn = createTabBtn("TabRarity", "⭐ Rarity", 0.33, 0.33)
    local TabSeedBtn = createTabBtn("TabSeed", "🌱 Benih", 0.66, 0.34)

    -- Container Tabs
    local ContainerMain = Instance.new("Frame")
    ContainerMain.Size = UDim2.new(1, -16, 1, -82)
    ContainerMain.Position = UDim2.new(0, 8, 0, 76)
    ContainerMain.BackgroundTransparency = 1
    ContainerMain.Parent = MainFrame

    local ContainerRarity = Instance.new("Frame")
    ContainerRarity.Size = UDim2.new(1, -16, 1, -82)
    ContainerRarity.Position = UDim2.new(0, 8, 0, 76)
    ContainerRarity.BackgroundTransparency = 1
    ContainerRarity.Visible = false
    ContainerRarity.Parent = MainFrame

    local ContainerSeed = Instance.new("Frame")
    ContainerSeed.Size = UDim2.new(1, -16, 1, -82)
    ContainerSeed.Position = UDim2.new(0, 8, 0, 76)
    ContainerSeed.BackgroundTransparency = 1
    ContainerSeed.Visible = false
    ContainerSeed.Parent = MainFrame

    -- Helper Switch Tab
    local function switchTab(tabName)
        ContainerMain.Visible = (tabName == "Main")
        ContainerRarity.Visible = (tabName == "Rarity")
        ContainerSeed.Visible = (tabName == "Seed")

        TabMainBtn.BackgroundColor3 = (tabName == "Main") and Color3.fromRGB(50, 180, 90) or Color3.fromRGB(45, 45, 60)
        TabMainBtn.TextColor3 = (tabName == "Main") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)

        TabRarityBtn.BackgroundColor3 = (tabName == "Rarity") and Color3.fromRGB(50, 180, 90) or Color3.fromRGB(45, 45, 60)
        TabRarityBtn.TextColor3 = (tabName == "Rarity") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)

        TabSeedBtn.BackgroundColor3 = (tabName == "Seed") and Color3.fromRGB(50, 180, 90) or Color3.fromRGB(45, 45, 60)
        TabSeedBtn.TextColor3 = (tabName == "Seed") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
    end

    TabMainBtn.MouseButton1Click:Connect(function() switchTab("Main") end)
    TabRarityBtn.MouseButton1Click:Connect(function() switchTab("Rarity") end)
    TabSeedBtn.MouseButton1Click:Connect(function() switchTab("Seed") end)
    switchTab("Main")

    -- ───────────────────────────────────────────
    -- [TAB 1: UTAMA]
    -- ───────────────────────────────────────────
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, 0, 0, 24)
    StatusLabel.Position = UDim2.new(0, 0, 0, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Status: Siap"
    StatusLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
    StatusLabel.TextSize = 13
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = ContainerMain

    local FilterSummaryLabel = Instance.new("TextLabel")
    FilterSummaryLabel.Size = UDim2.new(1, 0, 0, 36)
    FilterSummaryLabel.Position = UDim2.new(0, 0, 0, 24)
    FilterSummaryLabel.BackgroundTransparency = 1
    FilterSummaryLabel.Text = "Filter Rarity: Semua\nFilter Benih: Semua"
    FilterSummaryLabel.TextColor3 = Color3.fromRGB(255, 215, 100)
    FilterSummaryLabel.TextSize = 11
    FilterSummaryLabel.Font = Enum.Font.Gotham
    FilterSummaryLabel.TextXAlignment = Enum.TextXAlignment.Left
    FilterSummaryLabel.TextWrapped = true
    FilterSummaryLabel.Parent = ContainerMain

    local function updateFilterSummary()
        local rCount = 0
        local rList = {}
        for r, _ in pairs(CONFIG.SELECTED_RARITIES) do
            rCount = rCount + 1
            table.insert(rList, r)
        end

        local nCount = 0
        for _, _ in pairs(CONFIG.SELECTED_NAMES) do
            nCount = nCount + 1
        end

        local rText = (rCount == 0) and "Semua" or table.concat(rList, ", ")
        local nText = (nCount == 0) and "Semua" or (nCount .. " jenis dipilih")
        FilterSummaryLabel.Text = string.format("Filter Rarity: %s\nFilter Benih: %s", rText, nText)
    end

    local BuyAllBtn = Instance.new("TextButton")
    BuyAllBtn.Size = UDim2.new(1, 0, 0, 42)
    BuyAllBtn.Position = UDim2.new(0, 0, 0, 68)
    BuyAllBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 90)
    BuyAllBtn.Text = "🛒 Beli Benih (Sesuai Filter)"
    BuyAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    BuyAllBtn.TextSize = 14
    BuyAllBtn.Font = Enum.Font.GothamBold
    BuyAllBtn.BorderSizePixel = 0
    BuyAllBtn.Parent = ContainerMain
    local BuyAllCorner = Instance.new("UICorner")
    BuyAllCorner.CornerRadius = UDim.new(0, 8)
    BuyAllCorner.Parent = BuyAllBtn

    local LoopBtn = Instance.new("TextButton")
    LoopBtn.Size = UDim2.new(1, 0, 0, 36)
    LoopBtn.Position = UDim2.new(0, 0, 0, 118)
    LoopBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    LoopBtn.Text = "🔄 Loop Mode: OFF"
    LoopBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    LoopBtn.TextSize = 13
    LoopBtn.Font = Enum.Font.GothamBold
    LoopBtn.BorderSizePixel = 0
    LoopBtn.Parent = ContainerMain
    local LoopCorner = Instance.new("UICorner")
    LoopCorner.CornerRadius = UDim.new(0, 8)
    LoopCorner.Parent = LoopBtn

    local InfoLabel = Instance.new("TextLabel")
    InfoLabel.Size = UDim2.new(1, 0, 0, 30)
    InfoLabel.Position = UDim2.new(0, 0, 1, -30)
    InfoLabel.BackgroundTransparency = 1
    InfoLabel.Text = "Delay: " .. CONFIG.DELAY_BETWEEN_PURCHASES .. "s | Retry: " .. CONFIG.MAX_RETRIES .. "x"
    InfoLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
    InfoLabel.TextSize = 11
    InfoLabel.Font = Enum.Font.Gotham
    InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    InfoLabel.Parent = ContainerMain

    -- ───────────────────────────────────────────
    -- [TAB 2: FILTER RARITY]
    -- ───────────────────────────────────────────
    local RaritySubTitle = Instance.new("TextLabel")
    RaritySubTitle.Size = UDim2.new(1, 0, 0, 22)
    RaritySubTitle.BackgroundTransparency = 1
    RaritySubTitle.Text = "Pilih Rarity yang ingin dibeli:"
    RaritySubTitle.TextColor3 = Color3.fromRGB(200, 200, 220)
    RaritySubTitle.TextSize = 12
    RaritySubTitle.Font = Enum.Font.GothamBold
    RaritySubTitle.TextXAlignment = Enum.TextXAlignment.Left
    RaritySubTitle.Parent = ContainerRarity

    local RarityResetBtn = Instance.new("TextButton")
    RarityResetBtn.Size = UDim2.new(1, 0, 0, 28)
    RarityResetBtn.Position = UDim2.new(0, 0, 0, 24)
    RarityResetBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    RarityResetBtn.Text = "🔄 Reset Rarity (Beli Semua)"
    RarityResetBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    RarityResetBtn.TextSize = 12
    RarityResetBtn.Font = Enum.Font.Gotham
    RarityResetBtn.BorderSizePixel = 0
    RarityResetBtn.Parent = ContainerRarity
    local rrc = Instance.new("UICorner")
    rrc.CornerRadius = UDim.new(0, 6)
    rrc.Parent = RarityResetBtn

    local RarityListFrame = Instance.new("Frame")
    RarityListFrame.Size = UDim2.new(1, 0, 1, -60)
    RarityListFrame.Position = UDim2.new(0, 0, 0, 58)
    RarityListFrame.BackgroundTransparency = 1
    RarityListFrame.Parent = ContainerRarity

    local rarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}
    local rarityButtons = {}

    local function refreshRarityButtons()
        for rName, btn in pairs(rarityButtons) do
            local isSelected = CONFIG.SELECTED_RARITIES[rName] == true
            local col = RARITY_COLORS[rName] or Color3.fromRGB(180, 180, 180)
            if isSelected then
                btn.BackgroundColor3 = col
                btn.TextColor3 = Color3.fromRGB(20, 20, 20)
                btn.Text = "✓ " .. rName .. " (Dipilih)"
            else
                btn.BackgroundColor3 = Color3.fromRGB(38, 38, 50)
                btn.TextColor3 = col
                btn.Text = "○ " .. rName
            end
        end
        updateFilterSummary()
    end

    RarityResetBtn.MouseButton1Click:Connect(function()
        CONFIG.SELECTED_RARITIES = {}
        refreshRarityButtons()
        notify("Filter Rarity", "Rarity di-reset: Beli semua rarity", 2)
    end)

    for i, rName in ipairs(rarities) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.Position = UDim2.new(0, 0, 0, (i - 1) * 36)
        btn.BackgroundColor3 = Color3.fromRGB(38, 38, 50)
        btn.Text = "○ " .. rName
        btn.TextColor3 = RARITY_COLORS[rName]
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.Parent = RarityListFrame
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = btn

        btn.MouseButton1Click:Connect(function()
            if CONFIG.SELECTED_RARITIES[rName] then
                CONFIG.SELECTED_RARITIES[rName] = nil
            else
                CONFIG.SELECTED_RARITIES[rName] = true
            end
            refreshRarityButtons()
        end)

        rarityButtons[rName] = btn
    end

    -- ───────────────────────────────────────────
    -- [TAB 3: FILTER NAMA BENIH]
    -- ───────────────────────────────────────────
    local SeedHeader = Instance.new("Frame")
    SeedHeader.Size = UDim2.new(1, 0, 0, 28)
    SeedHeader.BackgroundTransparency = 1
    SeedHeader.Parent = ContainerSeed

    local ResetSeedBtn = Instance.new("TextButton")
    ResetSeedBtn.Size = UDim2.new(1, 0, 1, 0)
    ResetSeedBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    ResetSeedBtn.Text = "🔄 Reset Benih (Beli Semua)"
    ResetSeedBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    ResetSeedBtn.TextSize = 12
    ResetSeedBtn.Font = Enum.Font.Gotham
    ResetSeedBtn.BorderSizePixel = 0
    ResetSeedBtn.Parent = SeedHeader
    local rsc = Instance.new("UICorner")
    rsc.CornerRadius = UDim.new(0, 6)
    rsc.Parent = ResetSeedBtn

    local SeedScroll = Instance.new("ScrollingFrame")
    SeedScroll.Size = UDim2.new(1, 0, 1, -34)
    SeedScroll.Position = UDim2.new(0, 0, 0, 34)
    SeedScroll.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    SeedScroll.BorderSizePixel = 0
    SeedScroll.ScrollBarThickness = 5
    SeedScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    SeedScroll.Parent = ContainerSeed
    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(0, 6)
    sc.Parent = SeedScroll

    local seedRowButtons = {}

    local function refreshSeedButtons()
        for sName, btn in pairs(seedRowButtons) do
            local isSelected = CONFIG.SELECTED_NAMES[sName] == true
            local r = SEED_RARITY[sName] or "Common"
            local col = RARITY_COLORS[r] or Color3.fromRGB(180, 180, 180)
            if isSelected then
                btn.BackgroundColor3 = Color3.fromRGB(40, 100, 60)
                btn.Text = "✓ " .. sName .. " [" .. r .. "]"
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                btn.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
                btn.Text = "○ " .. sName .. " [" .. r .. "]"
                btn.TextColor3 = col
            end
        end
        updateFilterSummary()
    end

    ResetSeedBtn.MouseButton1Click:Connect(function()
        CONFIG.SELECTED_NAMES = {}
        refreshSeedButtons()
        notify("Filter Benih", "Pilihan benih di-reset: Beli semua", 2)
    end)

    local function populateSeedList()
        local seeds = findAllSeeds()
        local yOffset = 4
        local rowHeight = 30
        local gap = 4

        for _, seedName in ipairs(seeds) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, rowHeight)
            btn.Position = UDim2.new(0, 5, 0, yOffset)
            btn.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
            btn.BorderSizePixel = 0
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.TextSize = 11
            btn.Font = Enum.Font.Gotham
            btn.Parent = SeedScroll

            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 5)
            c.Parent = btn

            local pad = Instance.new("UIPadding")
            pad.PaddingLeft = UDim.new(0, 8)
            pad.Parent = btn

            btn.MouseButton1Click:Connect(function()
                if CONFIG.SELECTED_NAMES[seedName] then
                    CONFIG.SELECTED_NAMES[seedName] = nil
                else
                    CONFIG.SELECTED_NAMES[seedName] = true
                end
                refreshSeedButtons()
            end)

            seedRowButtons[seedName] = btn
            yOffset = yOffset + rowHeight + gap
        end

        SeedScroll.CanvasSize = UDim2.new(0, 0, 0, yOffset + 10)
        refreshSeedButtons()
    end

    populateSeedList()
    refreshRarityButtons()

    -- ───────────────────────────────────────────
    -- Logika Tombol & Loop
    -- ───────────────────────────────────────────
    local isRunning = false
    local loopRunning = false

    CloseBtn.MouseButton1Click:Connect(function()
        loopRunning = false
        ScreenGui:Destroy()
    end)

    BuyAllBtn.MouseButton1Click:Connect(function()
        if isRunning then return end
        isRunning = true
        BuyAllBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        BuyAllBtn.Text = "⏳ Memproses Pembelian..."
        StatusLabel.Text = "Status: Sedang membeli..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)

        task.spawn(function()
            local b, f, t = buyFilteredSeeds()
            isRunning = false
            BuyAllBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 90)
            BuyAllBtn.Text = "🛒 Beli Benih (Sesuai Filter)"
            StatusLabel.Text = string.format("Status: Selesai (%d/%d sukses) ✅", b, t)
            StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        end)
    end)

    LoopBtn.MouseButton1Click:Connect(function()
        CONFIG.LOOP_MODE = not CONFIG.LOOP_MODE
        loopRunning = CONFIG.LOOP_MODE

        if CONFIG.LOOP_MODE then
            LoopBtn.Text = "🔄 Loop Mode: ON"
            LoopBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 90)
            StatusLabel.Text = "Status: Loop aktif (Filter)"
            StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)

            task.spawn(function()
                while loopRunning do
                    if not isRunning then
                        isRunning = true
                        BuyAllBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                        BuyAllBtn.Text = "⏳ Membeli..."

                        buyFilteredSeeds()

                        isRunning = false
                        BuyAllBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 90)
                        BuyAllBtn.Text = "🛒 Beli Benih (Sesuai Filter)"

                        if loopRunning then
                            StatusLabel.Text = "Status: Menunggu " .. CONFIG.LOOP_INTERVAL .. "s..."
                            task.wait(CONFIG.LOOP_INTERVAL)
                        end
                    end
                    task.wait(0.1)
                end
            end)
        else
            LoopBtn.Text = "🔄 Loop Mode: OFF"
            LoopBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            StatusLabel.Text = "Status: Loop dimatikan"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        end
    end)

    -- Parent GUI ke CoreGui (dengan fallback PlayerGui)
    local success = pcall(function()
        ScreenGui.Parent = CoreGui
    end)
    if not success then
        ScreenGui.Parent = player:WaitForChild("PlayerGui")
    end

    return ScreenGui
end

-- ═══════════════════════════════════════════════
-- Inisialisasi
-- ═══════════════════════════════════════════════
log("Script dimuat dengan fitur Filter Rarity & Nama!")
notify("🌱 Auto Buy Seeds", "Script dimuat!\nGunakan tab [Rarity] / [Benih] untuk memfilter.", 5)
createGUI()
