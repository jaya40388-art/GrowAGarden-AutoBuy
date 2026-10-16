--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                     JAYA SC - HUB v1.0                       ║
    ║               Game: Grow a Garden (Roblox)                   ║
    ║            Compatible: Delta, Fluxus, Codex, Solara          ║
    ║          100% Custom Framework (No External Credits)         ║
    ╚══════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════
-- 1. SERVICES & COMPATIBILITY LAYER
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
-- 2. LOGO ASSET LOADER (JSC LOGO)
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
-- 3. GAME CONFIGURATION & LOGIC (GROW A GARDEN)
-- ═══════════════════════════════════════════════════════════════
local CONFIG = {
    DELAY_BETWEEN_PURCHASES = 0.3,
    AUTO_RETRY = true,
    MAX_RETRIES = 3,
    BUY_QUANTITY = 1,
    LOOP_MODE = false,
    LOOP_INTERVAL = 5,
    SELECTED_NAMES = {},    -- [seedName] = true
    SELECTED_RARITIES = {}, -- [rarity] = true
}

local RARITY_COLORS = {
    Common    = Color3.fromRGB(180, 180, 180),
    Uncommon  = Color3.fromRGB(52, 211, 153),
    Rare      = Color3.fromRGB(59, 130, 246),
    Epic      = Color3.fromRGB(168, 85, 247),
    Legendary = Color3.fromRGB(245, 158, 11),
    Mythic    = Color3.fromRGB(244, 63, 94),
}

local SEED_RARITY = {
    ["Carrot Seed"]       = "Common",
    ["Tomato Seed"]       = "Common",
    ["Potato Seed"]       = "Common",
    ["Wheat Seed"]        = "Common",
    ["Corn Seed"]         = "Common",
    ["Onion Seed"]        = "Common",
    ["Lettuce Seed"]      = "Common",

    ["Strawberry Seed"]   = "Uncommon",
    ["Blueberry Seed"]    = "Uncommon",
    ["Pepper Seed"]       = "Uncommon",
    ["Tulip Seed"]        = "Uncommon",
    ["Daisy Seed"]        = "Uncommon",
    ["Rice Seed"]         = "Uncommon",

    ["Watermelon Seed"]   = "Rare",
    ["Pumpkin Seed"]      = "Rare",
    ["Rose Seed"]         = "Rare",
    ["Cactus Seed"]       = "Rare",
    ["Mushroom Seed"]     = "Rare",
    ["Bamboo Seed"]       = "Rare",

    ["Apple Seed"]        = "Epic",
    ["Orange Seed"]       = "Epic",
    ["Grape Seed"]        = "Epic",
    ["Lemon Seed"]        = "Epic",
    ["Cherry Seed"]       = "Epic",
    ["Sunflower Seed"]    = "Epic",

    ["Mango Seed"]        = "Legendary",
    ["Coconut Seed"]      = "Legendary",
    ["Dragonfruit Seed"]  = "Legendary",
    ["Starfruit Seed"]    = "Legendary",
    ["Golden Apple Seed"] = "Legendary",

    ["Moonflower Seed"]   = "Mythic",
    ["Rainbow Seed"]      = "Mythic",
    ["Crystal Seed"]      = "Mythic",
    ["Cosmic Seed"]       = "Mythic",
}

local function FindBuyRemotes()
    local remotes = {}
    local searchPaths = {
        ReplicatedStorage,
        ReplicatedStorage:FindFirstChild("Remotes"),
        ReplicatedStorage:FindFirstChild("Events"),
        ReplicatedStorage:FindFirstChild("RemoteEvents"),
        ReplicatedStorage:FindFirstChild("Network"),
    }
    local keywords = {"buy", "purchase", "shop", "seed", "store", "item"}
    
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

local function FindAllAvailableSeeds()
    local seeds = {}
    local set = {}
    local function add(s, r)
        if not set[s] then
            set[s] = true
            table.insert(seeds, s)
            if r and not SEED_RARITY[s] then
                SEED_RARITY[s] = r
            end
        end
    end

    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj.Name:lower():find("seed") or obj.Name:lower():find("benih") then
            local r = obj:GetAttribute("Rarity") or (obj:FindFirstChild("Rarity") and obj.Rarity.Value)
            add(obj.Name, r)
        end
    end

    if #seeds == 0 then
        for s, _ in pairs(SEED_RARITY) do
            add(s, nil)
        end
    end
    table.sort(seeds)
    return seeds
end

local function MatchesFilter(seedName)
    local hasNameFilter = next(CONFIG.SELECTED_NAMES) ~= nil
    local hasRarityFilter = next(CONFIG.SELECTED_RARITIES) ~= nil
    local rarity = SEED_RARITY[seedName]

    local nameOk = not hasNameFilter or (CONFIG.SELECTED_NAMES[seedName] == true)
    local rarityOk = not hasRarityFilter or (rarity and CONFIG.SELECTED_RARITIES[rarity] == true)

    return nameOk and rarityOk
end

-- ═══════════════════════════════════════════════════════════════
-- 4. JAYA SC UI ENGINE (PROPRIETARY FRAMEWORK)
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
    Player.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
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

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
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
    task.spawn(function()
        local parent = GetSafeGuiParent()
        local notifGui = parent:FindFirstChild("Jaya_Notifications") or CreateInstance("ScreenGui", {
            Name = "Jaya_Notifications",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        }, parent)

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

        -- Toast Header with Logo or Icon
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

        local titleLbl = CreateInstance("TextLabel", {
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

        local msgLbl = CreateInstance("TextLabel", {
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

        local outTw = TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 320, 1, -75)
        })
        outTw:Play()
        outTw.Completed:Connect(function() toast:Destroy() end)
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- 5. JAYA SC WINDOW CREATION
-- ═══════════════════════════════════════════════════════════════
function JayaLib:CreateWindow(config)
    local titleText = config.Title or "JAYA SC"
    local subText = config.Subtitle or "Grow a Garden"
    local windowSize = config.Size or UDim2.fromOffset(540, 330)
    local tabWidth = config.TabWidth or 130

    local rootParent = GetSafeGuiParent()
    if rootParent:FindFirstChild("Jaya_MainGui") then
        rootParent:FindFirstChild("Jaya_MainGui"):Destroy()
    end

    local ScreenGui = CreateInstance("ScreenGui", {
        Name = "Jaya_MainGui",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, rootParent)

    local logoAsset = GetLogoAsset()

    -- ═══════════════════════════════════════════════════════════
    -- Floating Icon for Mobile / Minimize Restore (Using JSC Logo)
    -- ═══════════════════════════════════════════════════════════
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
        local floatFallback = CreateInstance("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Text = "JSC",
            TextColor3 = JayaLib.AccentColor,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            Parent = FloatIcon
        })
    end

    -- ═══════════════════════════════════════════════════════════
    -- Main Window Container
    -- ═══════════════════════════════════════════════════════════
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

    -- ═══════════════════════════════════════════════════════════
    -- Top Header Bar (With Logo next to Title)
    -- ═══════════════════════════════════════════════════════════
    local Topbar = CreateInstance("Frame", {
        Name = "Topbar",
        BackgroundColor3 = Color3.fromRGB(22, 22, 30),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 44),
        Parent = MainFrame
    })
    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 10) }, Topbar)
    local TopbarFill = CreateInstance("Frame", {
        BackgroundColor3 = Color3.fromRGB(22, 22, 30),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0.5, 0),
        Parent = Topbar
    })

    -- JSC Logo in Topbar
    local topLogo = CreateInstance("ImageLabel", {
        Name = "JSC_Logo",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0.5, -14),
        Size = UDim2.new(0, 28, 0, 28),
        Image = logoAsset or "",
        Parent = Topbar
    })
    CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, topLogo)

    -- If no asset, fallback to stylized text badge
    if not logoAsset then
        topLogo.Visible = false
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

    local SubLabel = CreateInstance("TextLabel", {
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

    -- Minimize & Close Buttons
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

    MinBtn.Activated:Connect(function()
        MainFrame.Visible = false
        FloatIcon.Visible = true
        JayaLib:Notify("JAYA SC", "UI di-minimize. Klik ikon JSC untuk membuka kembali.", 3)
    end)
    FloatIcon.Activated:Connect(function()
        MainFrame.Visible = true
        FloatIcon.Visible = false
    end)
    CloseBtn.Activated:Connect(function()
        ScreenGui:Destroy()
    end)

    -- Divider Line
    CreateInstance("Frame", {
        BackgroundColor3 = JayaLib.BorderCol,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = MainFrame
    })

    -- Sidebar for Tabs
    local Sidebar = CreateInstance("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 52),
        Size = UDim2.new(0, tabWidth, 1, -60),
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = MainFrame
    })
    local SidebarLayout = CreateInstance("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Sidebar
    })

    -- Content Area with Page Navigation
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

    -- Tab & Component Builder
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
            PageScroll.CanvasSize = UDim2.new(0, 0, 0, PageList.AbsoluteContentSize.Y + 12)
        end
        PageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateScroll)

        local TabBtn = CreateInstance("TextButton", {
            BackgroundColor3 = (currentIdx == 0) and JayaLib.AccentColor or JayaLib.BgCard,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 34),
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

            local HeaderTitle = CreateInstance("TextLabel", {
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
                isExpanded = not isExpanded
                refreshSectionHeight()
            end)

            local Items = {}

            -- BUTTON
            function Items:AddButton(cfg)
                local bTitle = cfg.Title or "Button"
                local bDesc = cfg.Content or cfg.Desc or ""
                local bCallback = cfg.Callback or function() end

                local btn = CreateInstance("TextButton", {
                    BackgroundColor3 = JayaLib.BgHover,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 36),
                    Text = "",
                    Parent = SecContent
                })
                CreateInstance("UICorner", { CornerRadius = UDim.new(0, 5) }, btn)

                CreateInstance("TextLabel", {
                    Font = Enum.Font.GothamBold,
                    Text = bTitle,
                    TextColor3 = JayaLib.TextMain,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -40, 1, 0),
                    Parent = btn
                })

                CreateInstance("TextLabel", {
                    Font = Enum.Font.GothamBold,
                    Text = "➔",
                    TextColor3 = JayaLib.AccentColor,
                    TextSize = 13,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -28, 0, 0),
                    Size = UDim2.new(0, 20, 1, 0),
                    Parent = btn
                })

                btn.Activated:Connect(function()
                    SpawnRipple(btn, Player:GetMouse().X, Player:GetMouse().Y)
                    bCallback()
                end)
                return btn
            end

            -- TOGGLE
            function Items:AddToggle(cfg)
                local tTitle = cfg.Title or "Toggle"
                local tDesc = cfg.Content or cfg.Desc or ""
                local state = cfg.Default or false
                local tCallback = cfg.Callback or function() end

                local tog = CreateInstance("TextButton", {
                    BackgroundColor3 = JayaLib.BgHover,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 38),
                    Text = "",
                    Parent = SecContent
                })
                CreateInstance("UICorner", { CornerRadius = UDim.new(0, 5) }, tog)

                local titleLbl = CreateInstance("TextLabel", {
                    Font = Enum.Font.GothamBold,
                    Text = tTitle,
                    TextColor3 = state and JayaLib.TextMain or JayaLib.TextMuted,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 4),
                    Size = UDim2.new(1, -60, 0, 16),
                    Parent = tog
                })

                local descLbl = CreateInstance("TextLabel", {
                    Font = Enum.Font.Gotham,
                    Text = tDesc,
                    TextColor3 = Color3.fromRGB(120, 120, 135),
                    TextSize = 10.5,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 20),
                    Size = UDim2.new(1, -60, 0, 14),
                    Parent = tog
                })

                local Pill = CreateInstance("Frame", {
                    BackgroundColor3 = state and JayaLib.AccentColor or Color3.fromRGB(50, 50, 65),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0, 34, 0, 18),
                    BorderSizePixel = 0,
                    Parent = tog
                })
                CreateInstance("UICorner", { CornerRadius = UDim.new(0, 9) }, Pill)

                local Knob = CreateInstance("Frame", {
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
                    Size = UDim2.new(0, 14, 0, 14),
                    BorderSizePixel = 0,
                    Parent = Pill
                })
                CreateInstance("UICorner", { CornerRadius = UDim.new(0, 7) }, Knob)

                local handler = { Value = state }
                function handler:Set(val)
                    state = val
                    handler.Value = state
                    local targetPos = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
                    local targetCol = state and JayaLib.AccentColor or Color3.fromRGB(50, 50, 65)

                    TweenService:Create(Knob, TweenInfo.new(0.2), { Position = targetPos }):Play()
                    TweenService:Create(Pill, TweenInfo.new(0.2), { BackgroundColor3 = targetCol }):Play()
                    titleLbl.TextColor3 = state and JayaLib.TextMain or JayaLib.TextMuted
                    tCallback(state)
                end

                tog.Activated:Connect(function()
                    SpawnRipple(tog, Player:GetMouse().X, Player:GetMouse().Y)
                    handler:Set(not state)
                end)
                return handler
            end

            -- SLIDER
            function Items:AddSlider(cfg)
                local sTitle = cfg.Title or "Slider"
                local minVal = cfg.Min or 0
                local maxVal = cfg.Max or 100
                local currentVal = cfg.Default or minVal
                local sCallback = cfg.Callback or function() end

                local sliderFrame = CreateInstance("Frame", {
                    BackgroundColor3 = JayaLib.BgHover,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 46),
                    Parent = SecContent
                })
                CreateInstance("UICorner", { CornerRadius = UDim.new(0, 5) }, sliderFrame)

                local titleLbl = CreateInstance("TextLabel", {
                    Font = Enum.Font.GothamBold,
                    Text = sTitle,
                    TextColor3 = JayaLib.TextMain,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 6),
                    Size = UDim2.new(1, -80, 0, 16),
                    Parent = sliderFrame
                })

                local valLbl = CreateInstance("TextLabel", {
                    Font = Enum.Font.GothamBold,
                    Text = tostring(currentVal),
                    TextColor3 = JayaLib.AccentColor,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -70, 0, 6),
                    Size = UDim2.new(0, 60, 0, 16),
                    Parent = sliderFrame
                })

                local barBg = CreateInstance("TextButton", {
                    BackgroundColor3 = Color3.fromRGB(45, 45, 60),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 10, 0, 28),
                    Size = UDim2.new(1, -20, 0, 8),
                    Text = "",
                    Parent = sliderFrame
                })
                CreateInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, barBg)

                local fillPct = math.clamp((currentVal - minVal) / (maxVal - minVal), 0, 1)
                local fillBar = CreateInstance("Frame", {
                    BackgroundColor3 = JayaLib.AccentColor,
                    BorderSizePixel = 0,
                    Size = UDim2.new(fillPct, 0, 1, 0),
                    Parent = barBg
                })
                CreateInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, fillBar)

                local sliding = false
                local function updateSlider(input)
                    local relX = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
                    local calculated = math.floor((minVal + ((maxVal - minVal) * relX)) * 10) / 10
                    currentVal = calculated
                    valLbl.Text = tostring(currentVal)
                    fillBar.Size = UDim2.new(relX, 0, 1, 0)
                    sCallback(currentVal)
                end

                barBg.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                        updateSlider(input)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateSlider(input)
                    end
                end)
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

                local titleLbl = CreateInstance("TextLabel", {
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
                local optLayout = CreateInstance("UIListLayout", {
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
                    local pad = CreateInstance("UIPadding", { PaddingLeft = UDim.new(0, 8) }, optBtn)

                    optBtn.Activated:Connect(function()
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

            -- PARAGRAPH
            function Items:AddParagraph(cfg)
                local pTitle = cfg.Title or "Info"
                local pDesc = cfg.Content or cfg.Desc or ""

                local pFrame = CreateInstance("Frame", {
                    BackgroundColor3 = JayaLib.BgHover,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 48),
                    Parent = SecContent
                })
                CreateInstance("UICorner", { CornerRadius = UDim.new(0, 5) }, pFrame)

                local pTitleLbl = CreateInstance("TextLabel", {
                    Font = Enum.Font.GothamBold,
                    Text = pTitle,
                    TextColor3 = JayaLib.AccentColor,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 6),
                    Size = UDim2.new(1, -20, 0, 16),
                    Parent = pFrame
                })

                local pDescLbl = CreateInstance("TextLabel", {
                    Font = Enum.Font.Gotham,
                    Text = pDesc,
                    TextColor3 = JayaLib.TextMuted,
                    TextSize = 11,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 24),
                    Size = UDim2.new(1, -20, 0, 20),
                    Parent = pFrame
                })

                local function setFunc(newTitle, newDesc)
                    pTitleLbl.Text = newTitle or pTitleLbl.Text
                    pDescLbl.Text = newDesc or pDescLbl.Text
                end
                return { Set = setFunc }
            end

            return Items
        end

        return Tab
    end

    return Window
end

-- ═══════════════════════════════════════════════════════════════
-- 6. IMPLEMENTASI FITUR GAME: GROW A GARDEN DENGAN JAYA SC
-- ═══════════════════════════════════════════════════════════════

local Window = JayaLib:CreateWindow({
    Title = "JAYA SC",
    Subtitle = "Grow a Garden",
    Size = UDim2.fromOffset(540, 330),
    TabWidth = 135
})

-- ---------------------------------------------------------------
-- TAB 1: 🛒 AUTO BUY SEEDS
-- ---------------------------------------------------------------
local TabBuy = Window:CreateTab({ Name = "Auto Buy", Icon = "🛒" })
local SecBuy = TabBuy:AddSection("Kontrol Pembelian Otomatis", true)

local StatusParagraph = SecBuy:AddParagraph({
    Title = "Status Pembelian",
    Content = "Sistem siap. Atur filter kelangkaan atau nama benih di tab sebelah."
})

local isPurchasing = false
local function ExecutePurchase()
    if isPurchasing then return end
    isPurchasing = true

    local remotes = FindBuyRemotes()
    local allSeeds = FindAllAvailableSeeds()
    local targets = {}

    for _, s in ipairs(allSeeds) do
        if MatchesFilter(s) then
            table.insert(targets, s)
        end
    end

    if #targets == 0 then
        StatusParagraph.Set("Status: Kosong", "Tidak ada benih yang sesuai filter!")
        JayaLib:Notify("Auto Buy", "Tidak ada benih yang lolos filter!", 3)
        isPurchasing = false
        return
    end

    StatusParagraph.Set("Status: Membeli...", string.format("Sedang memproses %d jenis benih...", #targets))
    local bought, failed = 0, 0

    for _, seedName in ipairs(targets) do
        local success = false
        for _, rem in ipairs(remotes) do
            local ok = pcall(function()
                if rem:IsA("RemoteEvent") then
                    rem:FireServer("Buy", seedName, CONFIG.BUY_QUANTITY)
                    rem:FireServer("BuySeed", seedName, CONFIG.BUY_QUANTITY)
                    rem:FireServer(seedName, CONFIG.BUY_QUANTITY)
                elseif rem:IsA("RemoteFunction") then
                    rem:InvokeServer("Buy", seedName, CONFIG.BUY_QUANTITY)
                end
            end)
            if ok then success = true break end
        end

        if success then bought = bought + 1 else failed = failed + 1 end
        task.wait(CONFIG.DELAY_BETWEEN_PURCHASES)
    end

    local resultMsg = string.format("Selesai! Sukses: %d | Gagal: %d", bought, failed)
    StatusParagraph.Set("Status: Selesai ✅", resultMsg)
    JayaLib:Notify("Auto Buy", resultMsg, 4)
    isPurchasing = false
end

-- Toggle Loop
local loopRunning = false
SecBuy:AddToggle({
    Title = "Auto Buy Seeds (Loop)",
    Desc = "Membeli benih berulang-ulang secara otomatis",
    Default = false,
    Callback = function(val)
        CONFIG.LOOP_MODE = val
        loopRunning = val
        if loopRunning then
            JayaLib:Notify("Auto Buy Loop", "Loop Mode: AKTIF", 2.5)
            task.spawn(function()
                while loopRunning do
                    ExecutePurchase()
                    task.wait(CONFIG.LOOP_INTERVAL)
                end
            end)
        else
            JayaLib:Notify("Auto Buy Loop", "Loop Mode: DIMATIKAN", 2.5)
        end
    end
})

-- Button Beli 1x
SecBuy:AddButton({
    Title = "Beli Semua Benih (1x Jalan)",
    Desc = "Membeli semua benih yang lolos filter sekarang",
    Callback = function()
        task.spawn(ExecutePurchase)
    end
})

-- Slider Delay
SecBuy:AddSlider({
    Title = "Delay Antar Pembelian (detik)",
    Min = 0.1,
    Max = 2.0,
    Default = CONFIG.DELAY_BETWEEN_PURCHASES,
    Callback = function(val)
        CONFIG.DELAY_BETWEEN_PURCHASES = val
    end
})

-- ---------------------------------------------------------------
-- TAB 2: ⭐ FILTER RARITY
-- ---------------------------------------------------------------
local TabRarity = Window:CreateTab({ Name = "Rarity", Icon = "⭐" })
local SecRarity = TabRarity:AddSection("Filter Kelangkaan Benih", true)

SecRarity:AddParagraph({
    Title = "Petunjuk Filter",
    Content = "Pilih satu atau beberapa kelangkaan. Jika tidak ada yang dipilih = membeli semua rarity."
})

local rarityOptions = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}
SecRarity:AddDropdown({
    Title = "Pilih Rarity",
    Multi = true,
    Options = rarityOptions,
    Default = {},
    Callback = function(selectedTable)
        CONFIG.SELECTED_RARITIES = {}
        for rName, isSel in pairs(selectedTable) do
            if isSel then CONFIG.SELECTED_RARITIES[rName] = true end
        end
    end
})

SecRarity:AddButton({
    Title = "Reset Filter Rarity (Beli Semua)",
    Callback = function()
        CONFIG.SELECTED_RARITIES = {}
        JayaLib:Notify("Filter Rarity", "Filter di-reset: Beli semua kelangkaan.", 3)
    end
})

-- ---------------------------------------------------------------
-- TAB 3: 🌾 FILTER BENIH
-- ---------------------------------------------------------------
local TabSeeds = Window:CreateTab({ Name = "Pilih Benih", Icon = "🌾" })
local SecSeeds = TabSeeds:AddSection("Filter Benih Spesifik", true)

local allSeedList = FindAllAvailableSeeds()
SecSeeds:AddDropdown({
    Title = "Pilih Nama Benih",
    Multi = true,
    Options = allSeedList,
    Default = {},
    Callback = function(selectedTable)
        CONFIG.SELECTED_NAMES = {}
        for sName, isSel in pairs(selectedTable) do
            if isSel then CONFIG.SELECTED_NAMES[sName] = true end
        end
    end
})

SecSeeds:AddButton({
    Title = "Reset Pilihan Benih (Beli Semua)",
    Callback = function()
        CONFIG.SELECTED_NAMES = {}
        JayaLib:Notify("Filter Benih", "Pilihan benih di-reset: Beli semua benih.", 3)
    end
})

-- ---------------------------------------------------------------
-- TAB 4: ⚙️ PENGATURAN
-- ---------------------------------------------------------------
local TabSettings = Window:CreateTab({ Name = "Pengaturan", Icon = "⚙️" })
local SecSettings = TabSettings:AddSection("Sistem & Info", true)

SecSettings:AddParagraph({
    Title = "JAYA SC v1.0",
    Content = "Framework UI kustom eksklusif untuk game Roblox Grow a Garden. Dibuat mandiri & bebas kredit pihak ketiga."
})

SecSettings:AddButton({
    Title = "Uji Coba Notifikasi",
    Callback = function()
        JayaLib:Notify("JAYA SC", "Sistem notifikasi berjalan lancar dan responsif!", 3.5)
    end
})

-- Notifikasi Sambutan
JayaLib:Notify("JAYA SC", "Selamat datang! Script Grow a Garden berhasil dimuat.", 4.5)
