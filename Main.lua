--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                     JAYA SC - HUB v1.0                       ║
    ║               Game: Grow a Garden (Roblox)                   ║
    ║            Compatible: Delta, Fluxus, Codex, Solara          ║
    ║          100% Custom Framework (No External Credits)         ║
    ╚══════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════
-- TAHAP 1: VALIDASI GAME (GAME LOCK / WHITELIST)
-- ═══════════════════════════════════════════════════════════════
local VALID_PLACE_IDS = {
    [126884695634066] = true, -- Grow a Garden (Main Place)
}
local VALID_GAME_IDS = {
    [7436755782] = true,      -- Grow a Garden (Universe ID)
}

local function ValidateGame()
    if VALID_PLACE_IDS[game.PlaceId] or VALID_GAME_IDS[game.GameId] then
        return true
    end

    local mps = game:GetService("MarketplaceService")
    local success, productInfo = pcall(function()
        return mps:GetProductInfo(game.PlaceId)
    end)
    if success and productInfo and productInfo.Name then
        if productInfo.Name:lower():find("grow a garden") then
            return true
        end
    end

    return false
end

if not ValidateGame() then
    local StarterGui = game:GetService("StarterGui")
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "⛔ JAYA SC: Akses Ditolak",
            Text = "Script ini khusus untuk game Roblox 'Grow a Garden'!",
            Duration = 6
        })
    end)
    warn("[JAYA SC] Akses ditolak! PlaceId (" .. tostring(game.PlaceId) .. ") tidak cocok dengan Grow a Garden.")
    return
end

-- ═══════════════════════════════════════════════════════════════
-- TAHAP 2: LIFECYCLE CONTROLLER & CLEAN SHUTDOWN (MAID ENGINE)
-- ═══════════════════════════════════════════════════════════════
local JayaState = {
    IsRunning = true,
    Connections = {},
    UIInstances = {},
}

function JayaState:TrackConnection(conn)
    table.insert(self.Connections, conn)
    return conn
end

function JayaState:TrackUI(gui)
    table.insert(self.UIInstances, gui)
    return gui
end

function JayaState:Shutdown()
    if not self.IsRunning then return end
    self.IsRunning = false -- Berhenti seketika semua loop aktif

    for _, conn in ipairs(self.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    self.Connections = {}

    for _, ui in ipairs(self.UIInstances) do
        pcall(function() ui:Destroy() end)
    end
    self.UIInstances = {}

    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "JAYA SC",
            Text = "Script telah dimatikan dan berhenti total.",
            Duration = 4
        })
    end)
    print("[JAYA SC] Script successfully stopped. No background processes running.")
end

-- ═══════════════════════════════════════════════════════════════
-- SERVICES & UTILITIES
-- ═══════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local function GetSafeGuiParent()
    if RunService:IsStudio() then
        return Player:WaitForChild("PlayerGui")
    end
    local success, result = pcall(function()
        if typeof(gethui) == "function" then
            local h = gethui()
            if h then return h end
        end
        return CoreGui
    end)
    return (success and result) or Player:WaitForChild("PlayerGui")
end

-- ═══════════════════════════════════════════════════════════════
-- LOGO ASSET LOADER (JSC LOGO)
-- ═══════════════════════════════════════════════════════════════
local LOGO_URL = "https://raw.githubusercontent.com/jaya40388-art/GrowAGarden-AutoBuy/refs/heads/main/logo.png"
local CACHED_LOGO_ASSET = nil

local function GetLogoAsset()
    if CACHED_LOGO_ASSET then return CACHED_LOGO_ASSET end
    pcall(function()
        local getAsset = getcustomasset or getsynasset
        if typeof(getAsset) == "function" and typeof(writefile) == "function" then
            local fileName = "jaya_sc_logo.png"
            local shouldDownload = true
            if typeof(isfile) == "function" and isfile(fileName) then
                shouldDownload = false
            end
            if shouldDownload then
                local content = game:HttpGet(LOGO_URL)
                if content and #content > 0 then
                    writefile(fileName, content)
                end
            end
            CACHED_LOGO_ASSET = getAsset(fileName)
        end
    end)
    return CACHED_LOGO_ASSET
end

-- ═══════════════════════════════════════════════════════════════
-- DATA & KATALOG 3 TOKO (FIXED DELAY = 0.4s)
-- ═══════════════════════════════════════════════════════════════
local FIXED_PURCHASE_DELAY = 0.4 -- Delay tetap 0.4s (tersembunyi dari user)

local CONFIG = {
    -- 1. Shop Seed
    SEED_LOOP = false,
    SEED_LOOP_INTERVAL = 3,
    SELECTED_SEED_NAMES = {},    -- [name] = true

    -- 2. Shop Egg
    EGG_LOOP = false,
    EGG_LOOP_INTERVAL = 3,
    SELECTED_EGGS = {},          -- [eggName] = true

    -- 3. Shop Gears
    GEAR_LOOP = false,
    GEAR_LOOP_INTERVAL = 3,
    SELECTED_GEARS = {},         -- [gearName] = true
}

-- 32 Jenis Benih Resmi Sesuai Tabel Game Grow a Garden
local DEFAULT_SEEDS = {
    "Carrot Seed",
    "Strawberry Seed",
    "Blueberry Seed",
    "Buttercup Seed",
    "Tomato Seed",
    "Corn Seed",
    "Daffodil Seed",
    "Watermelon Seed",
    "Pumpkin Seed",
    "Apple Seed",
    "Bamboo Seed",
    "Coconut Seed",
    "Cactus Seed",
    "Dragon Fruit Seed",
    "Mango Seed",
    "Grape Seed",
    "Mushroom Seed",
    "Pepper Seed",
    "Cacao Seed",
    "Sunflower Seed",
    "Beanstalk Seed",
    "Ember Lily Seed",
    "Sugar Apple Seed",
    "Burning Bud Seed",
    "Giant Pinecone Seed",
    "Elder Strawberry Seed",
    "Romanesco Seed",
    "Crimson Thorn Seed",
    "Zebrazinkle Seed",
    "Octobloom Seed",
    "Alien Apple Seed",
    "Aurum Spire Seed",
}

local SEED_TIER = {
    ["Carrot Seed"]           = "Common",
    ["Strawberry Seed"]       = "Common",
    ["Blueberry Seed"]        = "Uncommon",
    ["Buttercup Seed"]        = "Uncommon",
    ["Tomato Seed"]           = "Rare",
    ["Corn Seed"]             = "Rare",
    ["Daffodil Seed"]         = "Rare",
    ["Watermelon Seed"]       = "Legendary",
    ["Pumpkin Seed"]          = "Legendary",
    ["Apple Seed"]            = "Legendary",
    ["Bamboo Seed"]           = "Legendary",
    ["Coconut Seed"]          = "Mythical",
    ["Cactus Seed"]           = "Mythical",
    ["Dragon Fruit Seed"]     = "Mythical",
    ["Mango Seed"]            = "Mythical",
    ["Grape Seed"]            = "Divine",
    ["Mushroom Seed"]         = "Divine",
    ["Pepper Seed"]           = "Divine",
    ["Cacao Seed"]            = "Divine",
    ["Sunflower Seed"]        = "Divine",
    ["Beanstalk Seed"]        = "Prismatic",
    ["Ember Lily Seed"]       = "Prismatic",
    ["Sugar Apple Seed"]      = "Prismatic",
    ["Burning Bud Seed"]      = "Prismatic",
    ["Giant Pinecone Seed"]   = "Prismatic",
    ["Elder Strawberry Seed"] = "Prismatic",
    ["Romanesco Seed"]        = "Prismatic",
    ["Crimson Thorn Seed"]    = "Transcendent",
    ["Zebrazinkle Seed"]      = "Transcendent",
    ["Octobloom Seed"]        = "Transcendent",
    ["Alien Apple Seed"]      = "Transcendent",
    ["Aurum Spire Seed"]      = "Transcendent",
}

-- Fungsi Penghitung Waktu Refresh Toko (Tiap 5 Menit pada Menit XX:X0 & XX:X5)
local function GetRestockTimeInfo()
    local t = os.time()
    local rem = 300 - (t % 300)
    if rem == 300 then
        return "RESTOCK!", 0
    end
    local m = math.floor(rem / 60)
    local s = rem % 60
    return string.format("%02d:%02d", m, s), rem
end

local DEFAULT_EGGS = {
    "Common Egg", "Uncommon Egg", "Rare Egg", "Forest Egg",
    "Bug Egg", "Bee Egg", "Jungle Egg", "Oasis Egg", "Golden Egg", "Mythic Egg"
}

local DEFAULT_GEARS = {
    "Watering Can", "Basic Shovel", "Golden Shovel", "Sprinkler",
    "Advanced Sprinkler", "Fertilizer", "Harvesting Basket", "Iron Rake", "Scythe", "Master Trowel"
}

-- Scanner Universal Remotes
local function FindRemotes()
    local remotes = {}
    local searchPaths = {
        ReplicatedStorage,
        ReplicatedStorage:FindFirstChild("Remotes"),
        ReplicatedStorage:FindFirstChild("Events"),
        ReplicatedStorage:FindFirstChild("RemoteEvents"),
        ReplicatedStorage:FindFirstChild("Network"),
    }
    local keywords = {"buy", "purchase", "shop", "seed", "egg", "gear", "tool", "store", "item"}

    for _, path in ipairs(searchPaths) do
        if path then
            for _, item in ipairs(path:GetDescendants()) do
                if item:IsA("RemoteEvent") or item:IsA("RemoteFunction") then
                    local name = item.Name:lower()
                    for _, kw in ipairs(keywords) do
                        if name:find(kw) then
                            table.insert(remotes, item)
                            break
                        end
                    end
                end
            end
        end
    end
    return remotes
end

local function FindAvailableSeeds()
    local seeds, set = {}, {}
    -- Urutan utama sesuai tabel resmi (Tier Common s/d Transcendent)
    for _, s in ipairs(DEFAULT_SEEDS) do
        if not set[s] then
            set[s] = true
            table.insert(seeds, s)
        end
    end
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj.Name:lower():find("seed") or obj.Name:lower():find("benih") then
            if not set[obj.Name] then
                set[obj.Name] = true
                table.insert(seeds, obj.Name)
            end
        end
    end
    return seeds
end

local function FindAvailableEggs()
    local eggs, set = {}, {}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj.Name:lower():find("egg") or obj.Name:lower():find("telur") then
            if not set[obj.Name] then
                set[obj.Name] = true
                table.insert(eggs, obj.Name)
            end
        end
    end
    if #eggs == 0 then
        for _, e in ipairs(DEFAULT_EGGS) do table.insert(eggs, e) end
    end
    table.sort(eggs)
    return eggs
end

local function FindAvailableGears()
    local gears, set = {}, {}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        local n = obj.Name:lower()
        if n:find("gear") or n:find("tool") or n:find("shovel") or n:find("sprinkler") or n:find("can") then
            if not set[obj.Name] then
                set[obj.Name] = true
                table.insert(gears, obj.Name)
            end
        end
    end
    if #gears == 0 then
        for _, g in ipairs(DEFAULT_GEARS) do table.insert(gears, g) end
    end
    table.sort(gears)
    return gears
end

-- Filter benih kini langsung menggunakan nama benih terpilih (Filter Rarity dihapus)

-- ═══════════════════════════════════════════════════════════════
-- JAYA SC UI ENGINE (PROPRIETARY FRAMEWORK)
-- ═══════════════════════════════════════════════════════════════
local JayaLib = {
    AccentColor = Color3.fromRGB(16, 185, 129),    -- Emerald Green #10b981
    BgDark      = Color3.fromRGB(18, 18, 24),     -- Deep Obsidian
    BgCard      = Color3.fromRGB(26, 26, 36),     -- Element Container
    BgHover     = Color3.fromRGB(34, 34, 48),     -- Element Hover
    TextMain    = Color3.fromRGB(245, 245, 250),  -- Crisp White
    TextMuted   = Color3.fromRGB(150, 150, 165),  -- Muted Subtitle
    BorderCol   = Color3.fromRGB(45, 45, 60),     -- Subtle Divider
}

function JayaLib:EnableAntiAFK()
    local conn = Player.Idled:Connect(function()
        if not JayaState.IsRunning then return end
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
    JayaState:TrackConnection(conn)
end
JayaLib:EnableAntiAFK()

local function CreateInstance(className, properties, parent)
    local inst = Instance.new(className)
    for k, v in pairs(properties or {}) do
        inst[k] = v
    end
    if parent then inst.Parent = parent end
    return inst
end

local function MakeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil

    local c1 = handle.InputBegan:Connect(function(input)
        if not JayaState.IsRunning then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position

            local cEnd
            cEnd = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if cEnd then cEnd:Disconnect() end
                end
            end)
            JayaState:TrackConnection(cEnd)
        end
    end)
    JayaState:TrackConnection(c1)

    local c2 = handle.InputChanged:Connect(function(input)
        if not JayaState.IsRunning then return end
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    JayaState:TrackConnection(c2)
end

local function SpawnRipple(button, x, y)
    task.spawn(function()
        button.ClipsDescendants = true
        local ripple = CreateInstance("Frame", {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.85,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, x - button.AbsolutePosition.X, 0, y - button.AbsolutePosition.Y),
            Size = UDim2.new(0, 0, 0, 0),
            ZIndex = button.ZIndex + 5,
            Parent = button
        })
        CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, ripple)

        local targetSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
        local tw = TweenService:Create(ripple, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, targetSize, 0, targetSize),
            BackgroundTransparency = 1
        })
        tw:Play()
        tw.Completed:Connect(function() ripple:Destroy() end)
    end)
end

function JayaLib:Notify(title, message, duration)
    if not JayaState.IsRunning then return end

    task.spawn(function()
        local parent = GetSafeGuiParent()
        local notifGui = parent:FindFirstChild("Jaya_Notifications")
        if not notifGui then
            notifGui = CreateInstance("ScreenGui", {
                Name = "Jaya_Notifications",
                ResetOnSpawn = false,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            }, parent)
            JayaState:TrackUI(notifGui)
        end

        local container = notifGui:FindFirstChild("NotifContainer") or CreateInstance("Frame", {
            Name = "NotifContainer",
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -20, 1, -20),
            AnchorPoint = Vector2.new(1, 1),
            Size = UDim2.new(0, 300, 1, -40),
            Parent = notifGui
        })

        local toast = CreateInstance("Frame", {
            BackgroundColor3 = JayaLib.BgCard,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 70),
            Position = UDim2.new(1, 320, 1, -75),
            Parent = container
        })
        CreateInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, toast)
        CreateInstance("UIStroke", { Color = JayaLib.AccentColor, Thickness = 1.4 }, toast)

        local logoAsset = GetLogoAsset()
        local textOffset = 12

        if logoAsset then
            local iconImg = CreateInstance("ImageLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 9),
                Size = UDim2.new(0, 18, 0, 18),
                Image = logoAsset,
                Parent = toast
            })
            CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, iconImg)
            textOffset = 34
        end

        CreateInstance("TextLabel", {
            Font = Enum.Font.GothamBold,
            Text = (logoAsset and "" or "🌿 ") .. (title or "JAYA SC"),
            TextColor3 = JayaLib.TextMain,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, textOffset, 0, 8),
            Size = UDim2.new(1, -textOffset - 10, 0, 18),
            Parent = toast
        })

        CreateInstance("TextLabel", {
            Font = Enum.Font.Gotham,
            Text = message or "",
            TextColor3 = JayaLib.TextMuted,
            TextSize = 11.5,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 28),
            Size = UDim2.new(1, -24, 0, 36),
            Parent = toast
        })

        TweenService:Create(toast, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 1, -75)
        }):Play()

        task.wait(duration or 3.5)

        if toast and toast.Parent then
            local outTw = TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 320, 1, -75)
            })
            outTw:Play()
            outTw.Completed:Connect(function() toast:Destroy() end)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- WINDOW CREATION & HEADER CONTROLS [-] & [X]
-- ═══════════════════════════════════════════════════════════════
function JayaLib:CreateWindow(config)
    local titleText = config.Title or "JAYA SC"
    local subText = config.Subtitle or "Grow a Garden"
    local windowSize = config.Size or UDim2.fromOffset(540, 310)
    local tabWidth = config.TabWidth or 140

    local rootParent = GetSafeGuiParent()
    if rootParent:FindFirstChild("Jaya_MainGui") then
        rootParent:FindFirstChild("Jaya_MainGui"):Destroy()
    end

    local ScreenGui = CreateInstance("ScreenGui", {
        Name = "Jaya_MainGui",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, rootParent)
    JayaState:TrackUI(ScreenGui)

    local logoAsset = GetLogoAsset()

    -- Floating Icon (Muncul saat tombol [-] ditekan)
    local FloatIcon = CreateInstance("ImageButton", {
        Name = "Jaya_FloatIcon",
        BackgroundColor3 = JayaLib.BgDark,
        BorderSizePixel = 0,
        Position = UDim2.new(0.04, 0, 0.12, 0),
        Size = UDim2.new(0, 52, 0, 52),
        Image = logoAsset or "",
        ScaleType = Enum.ScaleType.Fit,
        AutoButtonColor = false,
        Visible = false,
        Parent = ScreenGui
    })
    CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, FloatIcon)
    CreateInstance("UIStroke", { Color = JayaLib.AccentColor, Thickness = 2.2 }, FloatIcon)
    MakeDraggable(FloatIcon, FloatIcon)

    if not logoAsset then
        CreateInstance("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Text = "JSC",
            TextColor3 = JayaLib.AccentColor,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            Parent = FloatIcon
        })
    end

    -- Main Window Container
    local MainFrame = CreateInstance("Frame", {
        Name = "MainWindow",
        BackgroundColor3 = JayaLib.BgDark,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = windowSize,
        ClipsDescendants = false,
        Parent = ScreenGui
    })
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 10) }, MainFrame)
    CreateInstance("UIStroke", { Color = JayaLib.BorderCol, Thickness = 1.5 }, MainFrame)

    -- Topbar Header
    local Topbar = CreateInstance("Frame", {
        Name = "Topbar",
        BackgroundColor3 = Color3.fromRGB(22, 22, 30),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 44),
        Parent = MainFrame
    })
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 10) }, Topbar)
    CreateInstance("Frame", {
        BackgroundColor3 = Color3.fromRGB(22, 22, 30),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0.5, 0),
        Parent = Topbar
    })

    if logoAsset then
        local topLogo = CreateInstance("ImageLabel", {
            Name = "JSC_Logo",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0.5, -14),
            Size = UDim2.new(0, 28, 0, 28),
            Image = logoAsset,
            ScaleType = Enum.ScaleType.Fit,
            Parent = Topbar
        })
        CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, topLogo)
    else
        local badge = CreateInstance("TextLabel", {
            Font = Enum.Font.GothamBold,
            Text = "JSC",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 10,
            BackgroundColor3 = JayaLib.AccentColor,
            Position = UDim2.new(0, 10, 0.5, -10),
            Size = UDim2.new(0, 28, 0, 20),
            Parent = Topbar
        })
        CreateInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, badge)
    end

    local TitleLabel = CreateInstance("TextLabel", {
        Font = Enum.Font.GothamBold,
        Text = titleText,
        TextColor3 = JayaLib.TextMain,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 46, 0, 0),
        Size = UDim2.new(0, 80, 1, 0),
        Parent = Topbar
    })

    CreateInstance("TextLabel", {
        Font = Enum.Font.Gotham,
        Text = "• " .. subText,
        TextColor3 = JayaLib.AccentColor,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 46 + TitleLabel.TextBounds.X + 8, 0, 0),
        Size = UDim2.new(0, 180, 1, 0),
        Parent = Topbar
    })

    -- Tombol [X] (Shutdown Total) dan Tombol [-] (Minimize)
    local CloseBtn = CreateInstance("TextButton", {
        Font = Enum.Font.GothamBold,
        Text = "✕",
        TextColor3 = JayaLib.TextMuted,
        TextSize = 13,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0, 28, 0, 28),
        Parent = Topbar
    })
    local MinBtn = CreateInstance("TextButton", {
        Font = Enum.Font.GothamBold,
        Text = "—",
        TextColor3 = JayaLib.TextMuted,
        TextSize = 13,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -38, 0.5, 0),
        Size = UDim2.new(0, 28, 0, 28),
        Parent = Topbar
    })

    MakeDraggable(Topbar, MainFrame)

    -- POIN 1: Hilangkan notifikasi jika script di-minimize
    MinBtn.Activated:Connect(function()
        if not JayaState.IsRunning then return end
        MainFrame.Visible = false
        FloatIcon.Visible = true
        -- Notifikasi ditiadakan sesuai instruksi
    end)

    FloatIcon.Activated:Connect(function()
        if not JayaState.IsRunning then return end
        MainFrame.Visible = true
        FloatIcon.Visible = false
    end)

    CloseBtn.Activated:Connect(function()
        JayaState:Shutdown()
    end)

    CreateInstance("Frame", {
        BackgroundColor3 = JayaLib.BorderCol,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = MainFrame
    })

    -- Sidebar Navigasi 3 Toko
    local Sidebar = CreateInstance("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 52),
        Size = UDim2.new(0, tabWidth, 1, -60),
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = MainFrame
    })
    CreateInstance("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Sidebar
    })

    local ContentHolder = CreateInstance("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, tabWidth + 18, 0, 52),
        Size = UDim2.new(1, -(tabWidth + 28), 1, -60),
        ClipsDescendants = true,
        Parent = MainFrame
    })
    local PageLayout = CreateInstance("UIPageLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        TweenTime = 0.25,
        EasingStyle = Enum.EasingStyle.Quad,
        EasingDirection = Enum.EasingDirection.Out,
        Parent = ContentHolder
    })

    local Window = {}
    local tabCount = 0
    local tabButtons = {}

    function Window:CreateTab(tabConfig)
        local tName = tabConfig.Name or "Tab"
        local tIcon = tabConfig.Icon or "🌱"
        local currentIdx = tabCount

        local PageScroll = CreateInstance("ScrollingFrame", {
            Name = "Page_" .. tName,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Color3.fromRGB(80, 80, 95),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            LayoutOrder = currentIdx,
            Parent = ContentHolder
        })
        local PageList = CreateInstance("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = PageScroll
        })

        local function updateScroll()
            task.wait(0.02)
            PageScroll.CanvasSize = UDim2.new(0, 0, 0, PageList.AbsoluteContentSize.Y + 14)
        end
        PageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateScroll)

        local TabBtn = CreateInstance("TextButton", {
            BackgroundColor3 = (currentIdx == 0) and JayaLib.AccentColor or JayaLib.BgCard,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 36),
            Text = "",
            LayoutOrder = currentIdx,
            Parent = Sidebar
        })
        CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, TabBtn)

        local TabBtnLabel = CreateInstance("TextLabel", {
            Font = Enum.Font.GothamBold,
            Text = tIcon .. "  " .. tName,
            TextColor3 = (currentIdx == 0) and Color3.fromRGB(255, 255, 255) or JayaLib.TextMuted,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -10, 1, 0),
            Parent = TabBtn
        })
        tabButtons[currentIdx] = { Btn = TabBtn, Label = TabBtnLabel }

        TabBtn.Activated:Connect(function()
            if not JayaState.IsRunning then return end
            SpawnRipple(TabBtn, Player:GetMouse().X, Player:GetMouse().Y)
            PageLayout:JumpToIndex(currentIdx)

            for idx, data in pairs(tabButtons) do
                if idx == currentIdx then
                    TweenService:Create(data.Btn, TweenInfo.new(0.2), { BackgroundColor3 = JayaLib.AccentColor }):Play()
                    data.Label.TextColor3 = Color3.fromRGB(255, 255, 255)
                else
                    TweenService:Create(data.Btn, TweenInfo.new(0.2), { BackgroundColor3 = JayaLib.BgCard }):Play()
                    data.Label.TextColor3 = JayaLib.TextMuted
                end
            end
        end)

        tabCount = tabCount + 1

        local Tab = {}
        Tab.PageScroll = PageScroll
        Tab.PageList = PageList
        Tab.UpdateScroll = updateScroll

        function Tab:AddCategoryBar(cfg)
            local catTitle = cfg.Title or "PILIH KATEGORI TOKO"
            local options = cfg.Options or {}
            local onSelect = cfg.Callback or function() end

            local CatFrame = CreateInstance("Frame", {
                BackgroundColor3 = JayaLib.BgCard,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 72),
                Parent = PageScroll
            })
            CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, CatFrame)
            CreateInstance("UIStroke", { Color = JayaLib.BorderCol, Thickness = 1 }, CatFrame)

            local CatTitleLbl = CreateInstance("TextLabel", {
                Font = Enum.Font.GothamBold,
                Text = catTitle,
                TextColor3 = JayaLib.TextMuted,
                TextSize = 10.5,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 6),
                Size = UDim2.new(1, -20, 0, 14),
                Parent = CatFrame
            })

            local BtnRow = CreateInstance("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 8, 0, 24),
                Size = UDim2.new(1, -16, 0, 40),
                Parent = CatFrame
            })
            local RowLayout = CreateInstance("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = BtnRow
            })

            local buttons = {}
            local activeCat = nil

            local function refreshButtons()
                for catId, data in pairs(buttons) do
                    local isSel = (activeCat == catId)
                    local statusDot = data.IsActive and " •" or ""
                    data.Btn.Text = (data.Icon .. " " .. data.Name .. statusDot)
                    if isSel then
                        data.Btn.BackgroundColor3 = JayaLib.AccentColor
                        data.Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        data.Stroke.Color = Color3.fromRGB(52, 211, 153)
                    else
                        data.Btn.BackgroundColor3 = JayaLib.BgHover
                        data.Btn.TextColor3 = data.IsActive and JayaLib.AccentColor or JayaLib.TextMuted
                        data.Stroke.Color = JayaLib.BorderCol
                    end
                end
            end

            local count = #options
            local btnScale = (count > 0) and (1 / count) or 1
            local padOffset = (count > 1) and math.floor(6 * (count - 1) / count) or 0

            for idx, opt in ipairs(options) do
                local btn = CreateInstance("TextButton", {
                    BackgroundColor3 = JayaLib.BgHover,
                    BorderSizePixel = 0,
                    Size = UDim2.new(btnScale, -padOffset, 1, 0),
                    Text = (opt.Icon and (opt.Icon .. " ") or "") .. opt.Name,
                    TextColor3 = JayaLib.TextMuted,
                    TextSize = 11,
                    Font = Enum.Font.GothamBold,
                    LayoutOrder = idx,
                    Parent = BtnRow
                })
                CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
                local stroke = CreateInstance("UIStroke", { Color = JayaLib.BorderCol, Thickness = 1 }, btn)

                buttons[opt.Id] = {
                    Btn = btn,
                    Stroke = stroke,
                    Name = opt.Name,
                    Icon = opt.Icon or "",
                    IsActive = false
                }

                btn.Activated:Connect(function()
                    if not JayaState.IsRunning then return end
                    SpawnRipple(btn, Player:GetMouse().X, Player:GetMouse().Y)
                    if activeCat == opt.Id then
                        activeCat = nil
                    else
                        activeCat = opt.Id
                    end
                    refreshButtons()
                    onSelect(activeCat)
                end)
            end

            refreshButtons()

            local barController = {}
            function barController:Select(id)
                activeCat = id
                refreshButtons()
                onSelect(activeCat)
            end
            function barController:SetStatus(id, isActive)
                if buttons[id] then
                    buttons[id].IsActive = isActive
                    refreshButtons()
                end
            end
            function barController:GetActive()
                return activeCat
            end

            return barController
        end

        function Tab:AddSection(secTitle, isOpen)
            local isExpanded = (isOpen == nil and true or isOpen)

            local SecFrame = CreateInstance("Frame", {
                BackgroundColor3 = JayaLib.BgCard,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 36),
                ClipsDescendants = true,
                Parent = PageScroll
            })
            CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, SecFrame)
            CreateInstance("UIStroke", { Color = JayaLib.BorderCol, Thickness = 1 }, SecFrame)

            local SecHeader = CreateInstance("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 36),
                Text = "",
                Parent = SecFrame
            })

            CreateInstance("TextLabel", {
                Font = Enum.Font.GothamBold,
                Text = secTitle or "Section",
                TextColor3 = JayaLib.TextMain,
                TextSize = 12.5,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -40, 1, 0),
                Parent = SecHeader
            })

            local Arrow = CreateInstance("TextLabel", {
                Font = Enum.Font.GothamBold,
                Text = isExpanded and "▼" or "▶",
                TextColor3 = JayaLib.AccentColor,
                TextSize = 11,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -26, 0, 0),
                Size = UDim2.new(0, 20, 1, 0),
                Parent = SecHeader
            })

            local SecContent = CreateInstance("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 38),
                Size = UDim2.new(1, -20, 0, 0),
                Parent = SecFrame
            })
            local SecLayout = CreateInstance("UIListLayout", {
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = SecContent
            })

            local function refreshSectionHeight()
                if isExpanded then
                    local targetH = SecLayout.AbsoluteContentSize.Y + 46
                    TweenService:Create(SecFrame, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, targetH) }):Play()
                    TweenService:Create(SecContent, TweenInfo.new(0.2), { Size = UDim2.new(1, -20, 0, SecLayout.AbsoluteContentSize.Y) }):Play()
                    Arrow.Text = "▼"
                else
                    TweenService:Create(SecFrame, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, 36) }):Play()
                    Arrow.Text = "▶"
                end
                updateScroll()
            end

            SecLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshSectionHeight)
            SecHeader.Activated:Connect(function()
                if not JayaState.IsRunning then return end
                isExpanded = not isExpanded
                refreshSectionHeight()
            end)

            local Items = {}
            Items.Frame = SecFrame

            function Items:SetVisible(val)
                SecFrame.Visible = val
                updateScroll()
            end

            -- TOGGLE SAKLAR (AUTO BUY)
            function Items:AddToggle(cfg)
                local tTitle = cfg.Title or "Toggle"
                local tDesc = cfg.Content or cfg.Desc or ""
                local state = cfg.Default or false
                local tCallback = cfg.Callback or function() end

                local tog = CreateInstance("TextButton", {
                    BackgroundColor3 = JayaLib.BgHover,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 42),
                    Text = "",
                    Parent = SecContent
                })
                CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, tog)

                local titleLbl = CreateInstance("TextLabel", {
                    Font = Enum.Font.GothamBold,
                    Text = tTitle,
                    TextColor3 = state and JayaLib.TextMain or JayaLib.TextMuted,
                    TextSize = 12.5,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 4),
                    Size = UDim2.new(1, -70, 0, 18),
                    Parent = tog
                })

                CreateInstance("TextLabel", {
                    Font = Enum.Font.Gotham,
                    Text = tDesc,
                    TextColor3 = Color3.fromRGB(130, 130, 145),
                    TextSize = 10.5,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 22),
                    Size = UDim2.new(1, -70, 0, 14),
                    Parent = tog
                })

                local Pill = CreateInstance("Frame", {
                    BackgroundColor3 = state and JayaLib.AccentColor or Color3.fromRGB(50, 50, 65),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -12, 0.5, 0),
                    Size = UDim2.new(0, 36, 0, 20),
                    BorderSizePixel = 0,
                    Parent = tog
                })
                CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, Pill)

                local Knob = CreateInstance("Frame", {
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
                    Size = UDim2.new(0, 14, 0, 14),
                    BorderSizePixel = 0,
                    Parent = Pill
                })
                CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, Knob)

                local handler = { Value = state }
                function handler:Set(val)
                    state = val
                    handler.Value = state
                    local targetPos = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
                    local targetCol = state and JayaLib.AccentColor or Color3.fromRGB(50, 50, 65)

                    TweenService:Create(Knob, TweenInfo.new(0.2), { Position = targetPos }):Play()
                    TweenService:Create(Pill, TweenInfo.new(0.2), { BackgroundColor3 = targetCol }):Play()
                    titleLbl.TextColor3 = state and JayaLib.TextMain or JayaLib.TextMuted
                    tCallback(state)
                end

                tog.Activated:Connect(function()
                    if not JayaState.IsRunning then return end
                    SpawnRipple(tog, Player:GetMouse().X, Player:GetMouse().Y)
                    handler:Set(not state)
                end)
                return handler
            end

            -- DROPDOWN (MULTI & SINGLE)
            function Items:AddDropdown(cfg)
                local dTitle = cfg.Title or "Dropdown"
                local options = cfg.Options or {}
                local isMulti = cfg.Multi or false
                local selected = cfg.Default or (isMulti and {} or options[1])
                local dCallback = cfg.Callback or function() end

                local dropFrame = CreateInstance("Frame", {
                    BackgroundColor3 = JayaLib.BgHover,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 40),
                    ClipsDescendants = true,
                    Parent = SecContent
                })
                CreateInstance("UICorner", { CornerRadius = UDim.new(0, 5) }, dropFrame)

                local dropHeader = CreateInstance("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 40),
                    Text = "",
                    Parent = dropFrame
                })

                CreateInstance("TextLabel", {
                    Font = Enum.Font.GothamBold,
                    Text = dTitle,
                    TextColor3 = JayaLib.TextMain,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0, 140, 1, 0),
                    Parent = dropHeader
                })

                local selectionSummary = CreateInstance("TextLabel", {
                    Font = Enum.Font.Gotham,
                    Text = isMulti and (type(selected) == "table" and (#selected .. " terpilih") or "Pilih...") or tostring(selected),
                    TextColor3 = JayaLib.AccentColor,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -60, 0, 0),
                    Size = UDim2.new(0, 35, 1, 0),
                    Parent = dropHeader
                })

                local dropArrow = CreateInstance("TextLabel", {
                    Font = Enum.Font.GothamBold,
                    Text = "▼",
                    TextColor3 = JayaLib.TextMuted,
                    TextSize = 10,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -24, 0, 0),
                    Size = UDim2.new(0, 20, 1, 0),
                    Parent = dropHeader
                })

                local optionHolder = CreateInstance("ScrollingFrame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 8, 0, 42),
                    Size = UDim2.new(1, -16, 0, 110),
                    ScrollBarThickness = 3,
                    CanvasSize = UDim2.new(0, 0, 0, #options * 28),
                    Parent = dropFrame
                })
                CreateInstance("UIListLayout", {
                    Padding = UDim.new(0, 3),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = optionHolder
                })

                local dropOpen = false
                local optButtons = {}

                local function getIsSelected(val)
                    if isMulti then
                        if type(selected) ~= "table" then selected = {} end
                        return selected[val] == true or table.find(selected, val) ~= nil
                    else
                        return selected == val
                    end
                end

                local function updateSummaryText()
                    if isMulti then
                        local count = 0
                        for _, v in pairs(selected) do count = count + 1 end
                        selectionSummary.Text = (count == 0) and "Semua" or (count .. " dipilih")
                    else
                        selectionSummary.Text = tostring(selected)
                    end
                end

                local function refreshOptions()
                    for optName, btn in pairs(optButtons) do
                        local active = getIsSelected(optName)
                        btn.BackgroundColor3 = active and JayaLib.AccentColor or Color3.fromRGB(28, 28, 38)
                        btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or JayaLib.TextMuted
                        btn.Text = (active and "✓ " or "○ ") .. optName
                    end
                    updateSummaryText()
                end

                for _, optName in ipairs(options) do
                    local optBtn = CreateInstance("TextButton", {
                        BackgroundColor3 = Color3.fromRGB(28, 28, 38),
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, -6, 0, 26),
                        Text = "○ " .. optName,
                        TextColor3 = JayaLib.TextMuted,
                        TextSize = 11,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = optionHolder
                    })
                    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, optBtn)
                    CreateInstance("UIPadding", { PaddingLeft = UDim.new(0, 8) }, optBtn)

                    optBtn.Activated:Connect(function()
                        if not JayaState.IsRunning then return end
                        if isMulti then
                            if type(selected) ~= "table" then selected = {} end
                            if selected[optName] then
                                selected[optName] = nil
                            else
                                selected[optName] = true
                            end
                            dCallback(selected)
                        else
                            selected = optName
                            dropOpen = false
                            dropFrame.Size = UDim2.new(1, 0, 0, 40)
                            dropArrow.Text = "▼"
                            refreshSectionHeight()
                            dCallback(selected)
                        end
                        refreshOptions()
                    end)
                    optButtons[optName] = optBtn
                end

                refreshOptions()

                dropHeader.Activated:Connect(function()
                    if not JayaState.IsRunning then return end
                    dropOpen = not dropOpen
                    if dropOpen then
                        dropFrame.Size = UDim2.new(1, 0, 0, 160)
                        dropArrow.Text = "▲"
                    else
                        dropFrame.Size = UDim2.new(1, 0, 0, 40)
                        dropArrow.Text = "▼"
                    end
                    refreshSectionHeight()
                end)
            end

            return Items
        end

        return Tab
    end

    return Window
end

-- ═══════════════════════════════════════════════════════════════
-- TAHAP 3 (PENYESUAIAN): 3 TOKO DENGAN TOGGLE AUTO BUY TERPADU
-- ═══════════════════════════════════════════════════════════════

local Window = JayaLib:CreateWindow({
    Title = "JAYA SC",
    Subtitle = "Grow a Garden",
    Size = UDim2.fromOffset(540, 310),
    TabWidth = 140
})

-- ───────────────────────────────────────────────────────────────
-- MENU UTAMA: 🛒 SHOP (SATU MENU DENGAN 3 PILIHAN KATEGORI)
-- ───────────────────────────────────────────────────────────────
local TabShop = Window:CreateTab({ Name = "Shop", Icon = "🛒" })

local CategoryBar
local SecSeed, SecEgg, SecGear, GuideCard

-- Bar 3 Pilihan Kategori di Layar Kanan (Shop Seed, Shop Egg, Shop Gears)
CategoryBar = TabShop:AddCategoryBar({
    Title = "PILIHAN TOKO (KLIK UNTUK MEMBUKA MENU)",
    Options = {
        { Id = "Seed", Name = "Shop Seed", Icon = "🌱" },
        { Id = "Egg",  Name = "Shop Egg",  Icon = "🥚" },
        { Id = "Gear", Name = "Shop Gears", Icon = "⚙️" },
    },
    Callback = function(selectedId)
        if GuideCard then
            GuideCard.Visible = (selectedId == nil)
        end
        if SecSeed then
            SecSeed:SetVisible(selectedId == "Seed")
        end
        if SecEgg then
            SecEgg:SetVisible(selectedId == "Egg")
        end
        if SecGear then
            SecGear:SetVisible(selectedId == "Gear")
        end
    end
})

-- Banner Countdown Live Refresh Toko (Setiap 5 menit pada XX:X0 dan XX:X5)
local RestockBanner = CreateInstance("Frame", {
    BackgroundColor3 = JayaLib.BgCard,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 36),
    LayoutOrder = 1,
    Parent = TabShop.PageScroll
})
CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, RestockBanner)
CreateInstance("UIStroke", { Color = JayaLib.BorderCol, Thickness = 1 }, RestockBanner)

CreateInstance("TextLabel", {
    Font = Enum.Font.GothamBold,
    Text = "⏱️",
    TextSize = 13,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 0, 0),
    Size = UDim2.new(0, 20, 1, 0),
    Parent = RestockBanner
})

CreateInstance("TextLabel", {
    Font = Enum.Font.GothamBold,
    Text = "Refresh Toko (Tiap XX:X0 & XX:X5):",
    TextColor3 = JayaLib.TextMuted,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 34, 0, 0),
    Size = UDim2.new(1, -135, 1, 0),
    Parent = RestockBanner
})

local RestockCountdown = CreateInstance("TextLabel", {
    Font = Enum.Font.GothamBold,
    Text = "05:00",
    TextColor3 = JayaLib.AccentColor,
    TextSize = 12.5,
    TextXAlignment = Enum.TextXAlignment.Right,
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -95, 0, 0),
    Size = UDim2.new(0, 85, 1, 0),
    Parent = RestockBanner
})

task.spawn(function()
    while JayaState.IsRunning do
        local strTime, rem = GetRestockTimeInfo()
        if rem <= 10 and rem > 0 then
            RestockCountdown.TextColor3 = Color3.fromRGB(250, 204, 21)
            RestockCountdown.Text = "⚡ " .. strTime
        elseif rem == 0 then
            RestockCountdown.TextColor3 = Color3.fromRGB(52, 211, 153)
            RestockCountdown.Text = "RESTOCK!"
        else
            RestockCountdown.TextColor3 = JayaLib.AccentColor
            RestockCountdown.Text = strTime
        end
        task.wait(1)
    end
end)

-- Kartu Panduan yang Muncul Ketika Belum Memilih Kategori
GuideCard = CreateInstance("Frame", {
    BackgroundColor3 = JayaLib.BgCard,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 135),
    LayoutOrder = 3,
    Parent = TabShop.PageScroll
})
CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, GuideCard)
CreateInstance("UIStroke", { Color = JayaLib.BorderCol, Thickness = 1 }, GuideCard)

CreateInstance("TextLabel", {
    Font = Enum.Font.GothamBold,
    Text = "🛒 Kategori Toko Tersedia",
    TextColor3 = JayaLib.TextMain,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 10),
    Size = UDim2.new(1, -24, 0, 20),
    Parent = GuideCard
})

CreateInstance("TextLabel", {
    Font = Enum.Font.Gotham,
    Text = "Silakan klik salah satu pilihan toko di atas untuk membuka menu pembelian otomatis & filternya:\n\n• 🌱 Shop Seed : Pilihan 32 Nama Benih & Auto Buy\n• 🥚 Shop Egg : Pilihan Jenis Telur & Auto Buy\n• ⚙️ Shop Gears : Pilihan Alat Berkebun & Auto Buy\n\n⏰ Catatan: Toko di-refresh otomatis setiap 5 menit (menit XX:X0 & XX:X5). Auto Buy akan memborong item pilihan Anda saat restock tiba!",
    TextColor3 = JayaLib.TextMuted,
    TextSize = 10.5,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 32),
    Size = UDim2.new(1, -24, 0, 95),
    Parent = GuideCard
})

-- ───────────────────────────────────────────────────────────────
-- PILIHAN 1: 🌱 SHOP SEED
-- ───────────────────────────────────────────────────────────────
SecSeed = TabShop:AddSection("🌱 Menu Shop Seed (Benih)", true)

local isBuyingSeeds = false
local function BuySeeds()
    if not JayaState.IsRunning or isBuyingSeeds then return end
    isBuyingSeeds = true

    local remotes = FindRemotes()
    local available = FindAvailableSeeds()
    local targets = {}

    local hasSeedFilter = next(CONFIG.SELECTED_SEED_NAMES) ~= nil
    for _, s in ipairs(available) do
        if not hasSeedFilter or (CONFIG.SELECTED_SEED_NAMES[s] == true) then
            table.insert(targets, s)
        end
    end

    for _, seedName in ipairs(targets) do
        if not JayaState.IsRunning or not CONFIG.SEED_LOOP then break end

        local cleanName = seedName:gsub(" Seed$", "")

        for _, rem in ipairs(remotes) do
            pcall(function()
                if rem:IsA("RemoteEvent") then
                    rem:FireServer("Buy", seedName, 1)
                    rem:FireServer("BuySeed", seedName, 1)
                    rem:FireServer(seedName, 1)
                    if cleanName ~= seedName then
                        rem:FireServer("Buy", cleanName, 1)
                        rem:FireServer("BuySeed", cleanName, 1)
                        rem:FireServer(cleanName, 1)
                    end
                elseif rem:IsA("RemoteFunction") then
                    rem:InvokeServer("Buy", seedName, 1)
                    if cleanName ~= seedName then
                        rem:InvokeServer("Buy", cleanName, 1)
                    end
                end
            end)
        end
        task.wait(FIXED_PURCHASE_DELAY)
    end

    isBuyingSeeds = false
end

-- Tombol Auto Buy Seed (Desain Saklar / Toggle)
SecSeed:AddToggle({
    Title = "Auto Buy Seed",
    Desc = "Membeli benih terpilih secara otomatis",
    Default = false,
    Callback = function(val)
        CONFIG.SEED_LOOP = val
        if CategoryBar then CategoryBar:SetStatus("Seed", val) end
        if val then
            JayaLib:Notify("Shop Seed", "Auto Buy Seed: AKTIF", 2.5)
            task.spawn(function()
                while JayaState.IsRunning and CONFIG.SEED_LOOP do
                    BuySeeds()
                    task.wait(CONFIG.SEED_LOOP_INTERVAL)
                end
            end)
        else
            JayaLib:Notify("Shop Seed", "Auto Buy Seed: DIMATIKAN", 2.5)
        end
    end
})

local seedList = FindAvailableSeeds()
SecSeed:AddDropdown({
    Title = "Pilih Nama Benih (32 Benih)",
    Multi = true,
    Options = seedList,
    Default = {},
    Callback = function(selectedTable)
        CONFIG.SELECTED_SEED_NAMES = {}
        for n, isSel in pairs(selectedTable) do
            if isSel then CONFIG.SELECTED_SEED_NAMES[n] = true end
        end
    end
})

-- ───────────────────────────────────────────────────────────────
-- PILIHAN 2: 🥚 SHOP EGG
-- ───────────────────────────────────────────────────────────────
SecEgg = TabShop:AddSection("🥚 Menu Shop Egg (Telur)", true)

local isBuyingEggs = false
local function BuyEggs()
    if not JayaState.IsRunning or isBuyingEggs then return end
    isBuyingEggs = true

    local remotes = FindRemotes()
    local available = FindAvailableEggs()
    local targets = {}

    local hasEggFilter = next(CONFIG.SELECTED_EGGS) ~= nil
    for _, e in ipairs(available) do
        if not hasEggFilter or (CONFIG.SELECTED_EGGS[e] == true) then
            table.insert(targets, e)
        end
    end

    for _, eggName in ipairs(targets) do
        if not JayaState.IsRunning or not CONFIG.EGG_LOOP then break end

        for _, rem in ipairs(remotes) do
            pcall(function()
                if rem:IsA("RemoteEvent") then
                    rem:FireServer("BuyEgg", eggName, 1)
                    rem:FireServer("PurchaseEgg", eggName, 1)
                    rem:FireServer("OpenEgg", eggName, 1)
                    rem:FireServer(eggName, 1)
                elseif rem:IsA("RemoteFunction") then
                    rem:InvokeServer("BuyEgg", eggName, 1)
                end
            end)
        end
        task.wait(FIXED_PURCHASE_DELAY)
    end

    isBuyingEggs = false
end

-- Tombol Auto Buy Egg (Desain Saklar / Toggle)
SecEgg:AddToggle({
    Title = "Auto Buy Egg",
    Desc = "Membeli telur terpilih secara otomatis",
    Default = false,
    Callback = function(val)
        CONFIG.EGG_LOOP = val
        if CategoryBar then CategoryBar:SetStatus("Egg", val) end
        if val then
            JayaLib:Notify("Shop Egg", "Auto Buy Egg: AKTIF", 2.5)
            task.spawn(function()
                while JayaState.IsRunning and CONFIG.EGG_LOOP do
                    BuyEggs()
                    task.wait(CONFIG.EGG_LOOP_INTERVAL)
                end
            end)
        else
            JayaLib:Notify("Shop Egg", "Auto Buy Egg: DIMATIKAN", 2.5)
        end
    end
})

local eggList = FindAvailableEggs()
SecEgg:AddDropdown({
    Title = "Pilih Jenis Telur",
    Multi = true,
    Options = eggList,
    Default = {},
    Callback = function(selectedTable)
        CONFIG.SELECTED_EGGS = {}
        for eggName, isSel in pairs(selectedTable) do
            if isSel then CONFIG.SELECTED_EGGS[eggName] = true end
        end
    end
})

-- ───────────────────────────────────────────────────────────────
-- PILIHAN 3: ⚙️ SHOP GEARS
-- ───────────────────────────────────────────────────────────────
SecGear = TabShop:AddSection("⚙️ Menu Shop Gears (Alat Berkebun)", true)

local isBuyingGears = false
local function BuyGears()
    if not JayaState.IsRunning or isBuyingGears then return end
    isBuyingGears = true

    local remotes = FindRemotes()
    local available = FindAvailableGears()
    local targets = {}

    local hasGearFilter = next(CONFIG.SELECTED_GEARS) ~= nil
    for _, g in ipairs(available) do
        if not hasGearFilter or (CONFIG.SELECTED_GEARS[g] == true) then
            table.insert(targets, g)
        end
    end

    for _, gearName in ipairs(targets) do
        if not JayaState.IsRunning or not CONFIG.GEAR_LOOP then break end

        for _, rem in ipairs(remotes) do
            pcall(function()
                if rem:IsA("RemoteEvent") then
                    rem:FireServer("BuyGear", gearName, 1)
                    rem:FireServer("PurchaseGear", gearName, 1)
                    rem:FireServer("BuyTool", gearName, 1)
                    rem:FireServer(gearName, 1)
                elseif rem:IsA("RemoteFunction") then
                    rem:InvokeServer("BuyGear", gearName, 1)
                end
            end)
        end
        task.wait(FIXED_PURCHASE_DELAY)
    end

    isBuyingGears = false
end

-- Tombol Auto Buy Gears (Desain Saklar / Toggle)
SecGear:AddToggle({
    Title = "Auto Buy Gears",
    Desc = "Membeli alat berkebun terpilih secara otomatis",
    Default = false,
    Callback = function(val)
        CONFIG.GEAR_LOOP = val
        if CategoryBar then CategoryBar:SetStatus("Gear", val) end
        if val then
            JayaLib:Notify("Shop Gears", "Auto Buy Gears: AKTIF", 2.5)
            task.spawn(function()
                while JayaState.IsRunning and CONFIG.GEAR_LOOP do
                    BuyGears()
                    task.wait(CONFIG.GEAR_LOOP_INTERVAL)
                end
            end)
        else
            JayaLib:Notify("Shop Gears", "Auto Buy Gears: DIMATIKAN", 2.5)
        end
    end
})

local gearList = FindAvailableGears()
SecGear:AddDropdown({
    Title = "Pilih Jenis Alat / Gear",
    Multi = true,
    Options = gearList,
    Default = {},
    Callback = function(selectedTable)
        CONFIG.SELECTED_GEARS = {}
        for gearName, isSel in pairs(selectedTable) do
            if isSel then CONFIG.SELECTED_GEARS[gearName] = true end
        end
    end
})


-- ═══════════════════════════════════════════════════════════════
-- SINKRONISASI RESTOCK OTOMATIS (SETIAP MENIT XX:X0 & XX:X5)
-- ═══════════════════════════════════════════════════════════════
task.spawn(function()
    local lastRestockMin = -1
    while JayaState.IsRunning do
        local now = os.date("*t")
        local m = now.min
        local s = now.sec
        -- Saat menit berakhiran 0 atau 5 (XX:X0 atau XX:X5) pada detik 0-2
        if (m % 5 == 0) and s <= 2 and lastRestockMin ~= m then
            lastRestockMin = m
            print("[JAYA SC] Restock 5-menit tiba (Menit " .. tostring(m) .. ")! Memulai siklus auto buy instan...")
            if CONFIG.SEED_LOOP then
                task.spawn(BuySeeds)
            end
            if CONFIG.EGG_LOOP then
                task.spawn(BuyEggs)
            end
            if CONFIG.GEAR_LOOP then
                task.spawn(BuyGears)
            end
        end
        task.wait(1)
    end
end)

-- Sembunyikan ketiga menu hingga user memilih salah satu tombol kategori
SecSeed:SetVisible(false)
SecEgg:SetVisible(false)
SecGear:SetVisible(false)

-- ═══════════════════════════════════════════════════════════════
-- NOTIFIKASI SAMBUTAN
-- ═══════════════════════════════════════════════════════════════
JayaLib:Notify("JAYA SC", "Selamat datang! Menu Shop terpadu siap digunakan.", 4)
