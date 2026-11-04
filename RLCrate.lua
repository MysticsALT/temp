--========================================================
-- MYSTICS | RL CRATE UNBOXING MODULE
-- Loaded on demand by Mystics_Launcher.lua.
-- Pinned launcher builds should fetch this file by commit SHA.
--========================================================

-- CLEANUP
if getgenv and getgenv().MysticsCleanup then
    pcall(getgenv().MysticsCleanup)
end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local Player = Players.LocalPlayer

local Running = false
local Paused = false
local Destroyed = false
local Minimized = false
local WaitingForNext = false
local SawButtonDisappear = false
local GameCheckPaused = false
local WaitingForFreeOpen = false
local FreeOpenClicked = false

local AntiAfkEnabled = false
local AntiAfkConnection = nil
local FpsConnection = nil
local FrameCount = 0
local CurrentFPS = 0
local ScriptLoadedAt = os.clock()

local Mode = "SMART"
local Delay = 2
local MaxCases = 0
local RandomExtra = 0
local RandomEnabled = false

local ClickAttempts = 0
local CompletedCycles = 0
local TotalItemsDetected = 0
local LastBatchEstimate = 0
local LastBatchMinimum = 0
local LastBatchMaximum = 0
local SessionStart = 0
local LastClick = 0
local CurrentButton = nil

local Profiles = {}
local History = {}
local DATA_FILE = "MysticsHub_Data.json"

-- Optional executor-backed persistence. The script still works normally
-- when file APIs are unavailable; data then lasts for this session only.
local function SaveLocalData()
    if typeof(writefile) ~= "function" then return false end
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode({
            Profiles = Profiles,
            History = History
        })
    end)
    if not ok then return false end
    return pcall(function()
        writefile(DATA_FILE, encoded)
    end)
end

local function LoadLocalData()
    if typeof(readfile) ~= "function" or typeof(isfile) ~= "function" then
        return
    end
    local exists = false
    pcall(function() exists = isfile(DATA_FILE) end)
    if not exists then return end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(DATA_FILE))
    end)
    if ok and type(decoded) == "table" then
        if type(decoded.Profiles) == "table" then Profiles = decoded.Profiles end
        if type(decoded.History) == "table" then History = decoded.History end
    end
end

LoadLocalData()

local ThemeIndex = 1

--========================================================
-- THEMES
--========================================================

local Themes = {
    {
        Name = "OBSIDIAN",
        Icon = "*",
        Tag = "THE OBSIDIAN SIGNATURE COLLECTION",
        Decoration = {"*", "+", "."},
        Background = Color3.fromRGB(5, 7, 12),
        Panel = Color3.fromRGB(14, 18, 29),
        Panel2 = Color3.fromRGB(25, 31, 45),
        Text = Color3.fromRGB(245, 242, 234),
        Muted = Color3.fromRGB(154, 164, 181),
        Accent = Color3.fromRGB(72, 88, 112),
        Accent2 = Color3.fromRGB(219, 231, 245),
        Border = Color3.fromRGB(94, 116, 145),
        GradientA = Color3.fromRGB(34, 45, 64),
        GradientB = Color3.fromRGB(5, 7, 12)
    },

    {
        Name = "BLOOD RED",
        Icon = "◆",
        Tag = "THE RUBY COLLECTION",
        Decoration = {"◆", "♦", "✦"},
        Background = Color3.fromRGB(8, 2, 5),
        Panel = Color3.fromRGB(25, 4, 10),
        Panel2 = Color3.fromRGB(42, 6, 15),
        Text = Color3.fromRGB(255, 245, 247),
        Muted = Color3.fromRGB(205, 165, 175),
        Accent = Color3.fromRGB(82, 7, 23),
        Accent2 = Color3.fromRGB(175, 35, 58),
        Border = Color3.fromRGB(125, 31, 52),
        GradientA = Color3.fromRGB(98, 9, 28),
        GradientB = Color3.fromRGB(12, 2, 6)
    },

    {
        Name = "CHRISTMAS",
        Icon = "❄",
        Tag = "THE WINTER RESERVE COLLECTION",
        Decoration = {"❄", "✦", "✧"},
        Background = Color3.fromRGB(3, 16, 23),
        Panel = Color3.fromRGB(8, 38, 45),
        Panel2 = Color3.fromRGB(12, 61, 64),
        Text = Color3.fromRGB(250, 248, 238),
        Muted = Color3.fromRGB(174, 211, 215),
        Accent = Color3.fromRGB(128, 20, 31),
        Accent2 = Color3.fromRGB(239, 207, 132),
        Border = Color3.fromRGB(192, 166, 100),
        GradientA = Color3.fromRGB(16, 91, 82),
        GradientB = Color3.fromRGB(4, 17, 26)
    },

    {
        Name = "HALLOWEEN",
        Icon = "🎃",
        Tag = "THE MIDNIGHT MASQUERADE COLLECTION",
        Decoration = {"🎃", "*", "+"},
        Background = Color3.fromRGB(12, 5, 20),
        Panel = Color3.fromRGB(31, 12, 48),
        Panel2 = Color3.fromRGB(53, 20, 69),
        Text = Color3.fromRGB(250, 235, 218),
        Muted = Color3.fromRGB(187, 157, 194),
        Accent = Color3.fromRGB(151, 55, 14),
        Accent2 = Color3.fromRGB(247, 161, 63),
        Border = Color3.fromRGB(116, 67, 145),
        GradientA = Color3.fromRGB(83, 29, 108),
        GradientB = Color3.fromRGB(17, 6, 28)
    }
}

local Theme = Themes[ThemeIndex]

--========================================================
-- GUI HELPERS
--========================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "RL_Crate_Unboxing_V1_5_Luxury"
Gui.ResetOnSpawn = false
Gui.DisplayOrder = 999999

local Parent = Player:WaitForChild("PlayerGui")

pcall(function()
    if gethui then
        Parent = gethui()
    end
end)

Gui.Parent = Parent

--========================================================
-- GUI SOUND EFFECTS
-- Replace these asset IDs with sounds you own / have permission to use.
--========================================================
local SoundService = game:GetService("SoundService")
local UI_CLICK_SOUND_ID = "rbxassetid://6895079853"
local UI_OPEN_SOUND_ID = "rbxassetid://6026984224"
local UI_CLOSE_SOUND_ID = "rbxassetid://6026984224"
local UI_CONFIRM_SOUND_ID = UI_CLICK_SOUND_ID
local UI_WARNING_SOUND_ID = UI_CLOSE_SOUND_ID
local UISoundsEnabled = true

local function PlayUISound(soundId, volume, playbackSpeed)
    if not UISoundsEnabled or not soundId or soundId == "" then return end
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = volume or 0.35
        sound.PlaybackSpeed = playbackSpeed or 1
        sound.Parent = SoundService
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
        sound:Play()
        task.delay(5, function()
            if sound and sound.Parent then sound:Destroy() end
        end)
    end)
end

local function Corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = object
    return c
end

local function Stroke(object, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = 0.08
    s.Parent = object
    return s
end

local function Gradient(object, first, second, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, first),
        ColorSequenceKeypoint.new(1, second)
    })
    g.Rotation = rotation or 90
    g.Parent = object
    return g
end

--========================================================
-- MAIN WINDOW
--========================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(410, 700)
Main.Position = UDim2.new(0, 28, 0.06, 0)
Main.BackgroundColor3 = Theme.Background
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = Gui

Corner(Main, 22)
local MainStroke = Stroke(Main, Theme.Border, 1.6)
local MainGradient = Gradient(Main, Theme.GradientA, Theme.GradientB)

-- Atmospheric particles sit behind the interface controls.
local Atmosphere = Instance.new("Frame")
Atmosphere.Name = "ThemeAtmosphere"
Atmosphere.Size = UDim2.fromScale(1, 1)
Atmosphere.BackgroundTransparency = 1
Atmosphere.BorderSizePixel = 0
Atmosphere.ClipsDescendants = true
Atmosphere.ZIndex = 1
Atmosphere.Parent = Main

local AtmosphereGeneration = 0

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 94)
Header.BackgroundColor3 = Theme.Panel
Header.BorderSizePixel = 0
Header.Parent = Main

Corner(Header, 15)
local HeaderGradient = Gradient(
    Header,
    Theme.GradientA,
    Theme.GradientB,
    0
)

--========================================================
-- LUXURY AMBIENT ANIMATION
-- Slow gradient movement and a restrained metallic edge pulse.
--========================================================

local AmbientGradientTween = TweenService:Create(
    MainGradient,
    TweenInfo.new(18, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Rotation = 270}
)
AmbientGradientTween:Play()

local HeaderGradientTween = TweenService:Create(
    HeaderGradient,
    TweenInfo.new(12, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Rotation = 180}
)
HeaderGradientTween:Play()

local BorderPulseTween = TweenService:Create(
    MainStroke,
    TweenInfo.new(3.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Transparency = 0.38}
)
BorderPulseTween:Play()

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -155, 0, 30)
Title.Position = UDim2.fromOffset(19, 12)
Title.BackgroundTransparency = 1
Title.Text = "RL CRATE UNBOXING V1.8"
Title.TextColor3 = Theme.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -155, 0, 18)
Subtitle.Position = UDim2.fromOffset(21, 43)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Why pay when you're the goat"
Subtitle.TextColor3 = Theme.Muted
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 11
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

local Creator = Instance.new("TextLabel")
Creator.Size = UDim2.new(1, -155, 0, 17)
Creator.Position = UDim2.fromOffset(21, 64)
Creator.BackgroundTransparency = 1
Creator.Text = "Made by Mystics"
Creator.TextColor3 = Theme.Accent2
Creator.Font = Enum.Font.GothamSemibold
Creator.TextSize = 10
Creator.TextXAlignment = Enum.TextXAlignment.Left
Creator.Parent = Header

local Decoration = Instance.new("TextLabel")
Decoration.Size = UDim2.fromOffset(55, 45)
Decoration.Position = UDim2.new(1, -150, 0, 18)
Decoration.BackgroundTransparency = 1
Decoration.Text = Theme.Icon
Decoration.TextColor3 = Theme.Accent2
Decoration.Font = Enum.Font.GothamBold
Decoration.TextSize = 29
Decoration.Parent = Header

local MinButton = Instance.new("TextButton")
MinButton.Size = UDim2.fromOffset(28, 28)
MinButton.Position = UDim2.new(1, -72, 0, 21)
MinButton.Text = "—"
MinButton.TextSize = 16
MinButton.Font = Enum.Font.GothamBold
MinButton.TextColor3 = Theme.Text
MinButton.BackgroundColor3 = Theme.Panel2
MinButton.Parent = Header
Corner(MinButton, 7)

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.fromOffset(28, 28)
CloseButton.Position = UDim2.new(1, -38, 0, 21)
CloseButton.Text = "×"
CloseButton.TextSize = 20
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextColor3 = Theme.Text
CloseButton.BackgroundColor3 = Theme.Accent
CloseButton.Parent = Header
Corner(CloseButton, 7)

CloseButton.Activated:Connect(function()
    PlayUISound(UI_CLOSE_SOUND_ID, 0.38, 0.92)
end)

--========================================================
-- MULTI-PAGE TAB NAVIGATION
-- Each tab owns its own scrolling page, preserving scroll position.
--========================================================

local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Position = UDim2.fromOffset(14, 101)
TabBar.Size = UDim2.new(1, -28, 0, 37)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Main

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 5)
TabLayout.Parent = TabBar

local PageContainer = Instance.new("Frame")
PageContainer.Name = "TabPages"
PageContainer.Position = UDim2.fromOffset(0, 145)
PageContainer.Size = UDim2.new(1, 0, 1, -150)
PageContainer.BackgroundTransparency = 1
PageContainer.ClipsDescendants = true
PageContainer.Parent = Main

local Pages = {}
local TabButtons = {}
local CurrentPageName = "OVERVIEW"
local Content

local function CreatePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Theme.Accent
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new()
    page.Visible = false
    page.Parent = PageContainer

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 13)
    padding.PaddingRight = UDim.new(0, 13)
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 12)
    padding.Parent = page

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    Pages[name] = page
    return page
end

local function SelectPage(name)
    if not Pages[name] then return end
    CurrentPageName = name
    Content = Pages[name]
    for pageName, page in pairs(Pages) do
        page.Visible = pageName == name
    end
    for tabName, button in pairs(TabButtons) do
        local selected = tabName == name
        button.BackgroundColor3 = selected and Theme.Accent or Theme.Panel2
        button.TextColor3 = selected and Theme.Text or Theme.Muted
        local stroke = button:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Transparency = selected and 0.05 or 0.55
            stroke.Color = Theme.Border
        end
    end
end

local tabDefinitions = {
    {Name = "OVERVIEW", Text = "HOME"},
    {Name = "REWARDS", Text = "REWARDS"},
    {Name = "AUTOMATION", Text = "AUTO"},
    {Name = "PERFORMANCE", Text = "PERF"},
    {Name = "APPEARANCE", Text = "STYLE"}
}

for index, definition in ipairs(tabDefinitions) do
    CreatePage(definition.Name)
    local tab = Instance.new("TextButton")
    tab.Name = definition.Name .. "Tab"
    tab.LayoutOrder = index
    tab.Size = UDim2.new(0, 72, 1, 0)
    tab.BackgroundColor3 = Theme.Panel2
    tab.BorderSizePixel = 0
    tab.AutoButtonColor = false
    tab.Font = Enum.Font.GothamBold
    tab.Text = definition.Text
    tab.TextSize = 9
    tab.TextColor3 = Theme.Muted
    tab.Parent = TabBar
    Corner(tab, 9)
    local tabStroke = Stroke(tab, Theme.Border, 1)
    tabStroke.Transparency = 0.42
    TabButtons[definition.Name] = tab
    tab.Activated:Connect(function()
        PlayUISound(UI_CLICK_SOUND_ID, 0.20, 1)
        SelectPage(definition.Name)
    end)
end

SelectPage("OVERVIEW")

local function Label(text, height, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, height or 27)
    l.BackgroundColor3 = Theme.Panel
    l.BackgroundTransparency = 0.16
    l.BorderSizePixel = 0
    l.Text = text
    l.TextColor3 = color or Theme.Text
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.TextTruncate = Enum.TextTruncate.AtEnd
    l:SetAttribute("MysticsTextRole",
        color == Theme.Muted and "muted"
        or color == Theme.Accent2 and "accent"
        or color == Theme.Text and "main"
        or "custom")
    l.Parent = Content
    Corner(l, 8)
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 11)
    padding.PaddingRight = UDim.new(0, 9)
    padding.Parent = l
    return l
end

local function Section(text)
    local holder = Instance.new("Frame")
    holder.Name = "SectionHeading"
    holder.Size = UDim2.new(1, 0, 0, 30)
    holder.BackgroundTransparency = 1
    holder.Parent = Content

    local accent = Instance.new("Frame")
    accent.Name = "AccentBar"
    accent.Size = UDim2.new(0, 3, 0, 15)
    accent.Position = UDim2.fromOffset(1, 7)
    accent.BackgroundColor3 = Theme.Accent2
    accent.BorderSizePixel = 0
    accent.Parent = holder
    Corner(accent, 2)

    local l = Instance.new("TextLabel")
    l.Name = "SectionTitle"
    l.BackgroundTransparency = 1
    l.Position = UDim2.fromOffset(12, 0)
    l.Size = UDim2.new(1, -15, 1, 0)
    l.Text = string.upper(text)
    l.TextColor3 = Theme.Accent2
    l.Font = Enum.Font.GothamBold
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = holder
    l:SetAttribute("MysticsTextRole", "accent")

    local line = Instance.new("Frame")
    line.Name = "SectionRule"
    line.AnchorPoint = Vector2.new(0, 0.5)
    line.Position = UDim2.new(0, 12, 1, -1)
    line.Size = UDim2.new(1, -15, 0, 1)
    line.BackgroundColor3 = Theme.Border
    line.BackgroundTransparency = 0.72
    line.BorderSizePixel = 0
    line.Parent = holder
    return holder
end

local function MakeButton(text, callback, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 42)
    b.BackgroundColor3 = color or Theme.Accent
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Theme.Text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.AutoButtonColor = false
    b.Parent = Content
    b:SetAttribute("MysticsButtonTone", color and "secondary" or "primary")

    Corner(b, 11)
    local buttonStroke = Stroke(b, Theme.Border, 1)
    buttonStroke.Transparency = 0.34
    local buttonGradient = Gradient(b,
        color and Theme.Panel2 or Theme.Accent,
        color and Theme.Panel or Theme.GradientB, 90)
    buttonGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.08),
        NumberSequenceKeypoint.new(1, 0.22)
    })

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = b

    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = b

    b.MouseEnter:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1.012}):Play()
        TweenService:Create(buttonStroke, TweenInfo.new(0.14), {Transparency = 0.04}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
        TweenService:Create(buttonStroke, TweenInfo.new(0.16), {Transparency = 0.34}):Play()
    end)
    b.MouseButton1Down:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.985}):Play()
    end)
    b.MouseButton1Up:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.012}):Play()
    end)
    b.Activated:Connect(function()
        PlayUISound(UI_CLICK_SOUND_ID, 0.24, 1 + math.random(-4, 4) / 100)
        if callback then callback() end
    end)
    return b
end

local function MakeInput(placeholder, default)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, 38)
    box.BackgroundColor3 = Theme.Panel2
    box.BackgroundTransparency = 0.08
    box.BorderSizePixel = 0
    box.TextColor3 = Theme.Text
    box.PlaceholderColor3 = Theme.Muted
    box.PlaceholderText = placeholder
    box.Text = tostring(default)
    box.ClearTextOnFocus = false
    box.Font = Enum.Font.GothamMedium
    box.TextSize = 12
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Parent = Content

    Corner(box, 9)
    local inputStroke = Stroke(box, Theme.Border, 1)
    inputStroke.Transparency = 0.42
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 11)
    padding.PaddingRight = UDim.new(0, 9)
    padding.Parent = box
    box.Focused:Connect(function()
        TweenService:Create(inputStroke, TweenInfo.new(0.16), {Transparency = 0.04, Thickness = 1.35}):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(inputStroke, TweenInfo.new(0.16), {Transparency = 0.42, Thickness = 1}):Play()
    end)
    return box
end

local function Notify(message)
    pcall(function()
        game:GetService("StarterGui"):SetCore(
            "SendNotification",
            {
                Title = "MYSTICS",
                Text = message,
                Duration = 3
            }
        )
    end)
end

--========================================================
-- STATISTICS
--========================================================

Section("LIVE SESSION")

local Status = Label("●  STOPPED", 24, Theme.Accent2)
local ClickLabel = Label("CLICK ATTEMPTS       0")
local CycleLabel = Label("COMPLETED CYCLES      0")
local TimerLabel = Label("SESSION TIME          00:00:00")
local RateLabel = Label("CLICKS / MINUTE       0")
local ItemsLabel = Label("ITEMS DETECTED         0")


-- Move performance controls to their own tab.
SelectPage("PERFORMANCE")

--========================================================
-- INTEGRATED ANTI-AFK + PERFORMANCE MONITOR
-- Uses the existing Mystics window; no second ScreenGui or
-- permanent while-true loop is created.
--========================================================

Section("ANTI-AFK & PERFORMANCE")

local AntiAfkButton
local AntiAfkStatus = Label("ANTI-AFK              OFF", 22, Theme.Muted)
local FPSMonitorLabel = Label("LIVE FPS               --", 22, Theme.Accent2)
local PingMonitorLabel = Label("LIVE PING              --", 22, Theme.Accent2)
local UptimeMonitorLabel = Label("SCRIPT UPTIME          00:00:00", 22, Theme.Muted)

local function SetAntiAfkEnabled(enabled)
    AntiAfkEnabled = enabled

    if AntiAfkConnection then
        AntiAfkConnection:Disconnect()
        AntiAfkConnection = nil
    end

    if AntiAfkEnabled then
        -- Roblox fires Idled when the local player becomes inactive.
        -- VirtualUser support can vary by execution environment.
        AntiAfkConnection = Player.Idled:Connect(function()
            if not AntiAfkEnabled or Destroyed then return end
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
            end)
        end)
    end

    if AntiAfkButton then
        AntiAfkButton.Text = AntiAfkEnabled and "ANTI-AFK  /  ON" or "ANTI-AFK  /  OFF"
    end
    AntiAfkStatus.Text = AntiAfkEnabled and "ANTI-AFK              ON" or "ANTI-AFK              OFF"
    AntiAfkStatus.TextColor3 = AntiAfkEnabled and Color3.fromRGB(125, 235, 155) or Theme.Muted
end

AntiAfkButton = MakeButton("ANTI-AFK  /  OFF", function()
    SetAntiAfkEnabled(not AntiAfkEnabled)
    Notify(AntiAfkEnabled and "Anti-AFK enabled." or "Anti-AFK disabled.")
end)

local FpsWindowStart = os.clock()
FpsConnection = RunService.RenderStepped:Connect(function()
    FrameCount = FrameCount + 1
    local now = os.clock()
    local elapsed = now - FpsWindowStart
    if elapsed >= 1 then
        CurrentFPS = math.floor(FrameCount / elapsed + 0.5)
        FrameCount = 0
        FpsWindowStart = now
        FPSMonitorLabel.Text = "LIVE FPS               " .. CurrentFPS
    end
end)

local function ReadPing()
    local pingValue
    pcall(function()
        local performanceStats = Stats:FindFirstChild("PerformanceStats")
        local pingObject = performanceStats and performanceStats:FindFirstChild("Ping")
        if pingObject then
            pingValue = tonumber(pingObject:GetValue())
        end
    end)

    if not pingValue then
        pcall(function()
            local network = Stats:FindFirstChild("Network")
            local serverStats = network and network:FindFirstChild("ServerStatsItem")
            local dataPing = serverStats and serverStats:FindFirstChild("Data Ping")
            if dataPing then
                pingValue = tonumber((dataPing:GetValueString() or ""):match("[%d%.]+"))
            end
        end)
    end

    return pingValue
end

task.spawn(function()
    while not Destroyed and Gui.Parent do
        local ping = ReadPing()
        PingMonitorLabel.Text = ping
            and string.format("LIVE PING              %d ms", math.floor(ping + 0.5))
            or "LIVE PING              --"

        local uptime = math.floor(os.clock() - ScriptLoadedAt)
        UptimeMonitorLabel.Text = string.format(
            "SCRIPT UPTIME          %02d:%02d:%02d",
            math.floor(uptime / 3600),
            math.floor((uptime % 3600) / 60),
            uptime % 60
        )
        task.wait(1)
    end
end)

local function FormatTime(t)
    t = math.floor(t)

    return string.format(
        "%02d:%02d:%02d",
        math.floor(t / 3600),
        math.floor((t % 3600) / 60),
        t % 60
    )
end

local RefreshAnalytics

local function UpdateStats()
    ClickLabel.Text = "CLICK ATTEMPTS       " .. ClickAttempts
    CycleLabel.Text = "COMPLETED CYCLES      " .. CompletedCycles

    local elapsed = math.max(1, os.clock() - SessionStart)

    TimerLabel.Text = "SESSION TIME          " ..
        FormatTime(elapsed)

    RateLabel.Text = "CLICKS / MINUTE       " ..
        math.floor(ClickAttempts / (elapsed / 60))
    ItemsLabel.Text = "ITEMS DETECTED         " .. TotalItemsDetected
    RefreshAnalytics()
end

-- Move reward tracking and analytics to their own tab.
SelectPage("REWARDS")

--========================================================
-- AUTOMATIC SESSION VALUE TRACKER
-- Detects reward rarity from UI colours before OPEN AGAIN is pressed.
-- Values are estimates in the game's value units, not Robux.
--========================================================

Section("LIVE SESSION VALUE")
Label("BOTTOM REWARD TEXT COLOUR DETECTION  /  AUTOMATIC", 22, Theme.Muted)

local RarityCounts = {
    Import = 0,
    Uncommon = 0,
    Rare = 0,
    VeryRare = 0,
    BlackMarket = 0
}

local ValueLowLabel = Label("MINIMUM VALUE       0.00", 22, Color3.fromRGB(125, 235, 155))
local ValueMidLabel = Label("ESTIMATED VALUE     0.00", 22, Theme.Accent2)
local ValueHighLabel = Label("MAXIMUM VALUE       0.00", 22, Color3.fromRGB(255, 145, 145))
local ValueBreakdownLabel = Label("IMP 0  |  U 0  |  R 0  |  VR 0  |  BM 0", 25, Theme.Muted)
local DetectionLabel = Label("WAITING FOR FIRST REWARD", 22, Theme.Muted)
local BatchValueLabel = Label("LAST 3-ITEM BATCH       —", 22, Theme.Accent2)

Section("SESSION ANALYTICS")

-- Compact live statistics dashboard. These values are sourced from the
-- existing reward counters; this is presentation-only and does not alter detection.
local StatsDashboard = Instance.new("Frame")
StatsDashboard.Name = "LiveStatisticsDashboard"
StatsDashboard.Size = UDim2.new(1, 0, 0, 148)
StatsDashboard.BackgroundColor3 = Theme.Panel2
StatsDashboard.BackgroundTransparency = 0.04
StatsDashboard.BorderSizePixel = 0
StatsDashboard.Parent = Content
Corner(StatsDashboard, 11)
local dashboardStroke = Stroke(StatsDashboard, Theme.Border, 1)
dashboardStroke.Transparency = 0.35

local dashboardGrid = Instance.new("UIGridLayout")
dashboardGrid.CellSize = UDim2.new(0.5, -6, 0, 43)
dashboardGrid.CellPadding = UDim2.fromOffset(8, 6)
dashboardGrid.SortOrder = Enum.SortOrder.LayoutOrder
dashboardGrid.Parent = StatsDashboard

local function DashboardCard(order, caption, initial, accentColor)
    local card = Instance.new("Frame")
    card.Name = caption:gsub("%W", "") .. "Card"
    card.LayoutOrder = order
    card.BackgroundColor3 = Theme.Panel
    card.BackgroundTransparency = 0.08
    card.BorderSizePixel = 0
    card.Parent = StatsDashboard
    Corner(card, 8)
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 1, -12)
    accent.Position = UDim2.fromOffset(6, 6)
    accent.BackgroundColor3 = accentColor or Theme.Accent2
    accent.BorderSizePixel = 0
    accent.Parent = card
    Corner(accent, 2)
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(15, 4)
    title.Size = UDim2.new(1, -20, 0, 13)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 8
    title.TextColor3 = Theme.Muted
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = caption
    title.Parent = card
    local value = Instance.new("TextLabel")
    value.Name = "Value"
    value.BackgroundTransparency = 1
    value.Position = UDim2.fromOffset(15, 17)
    value.Size = UDim2.new(1, -20, 0, 22)
    value.Font = Enum.Font.GothamBold
    value.TextSize = 15
    value.TextColor3 = accentColor or Theme.Text
    value.TextXAlignment = Enum.TextXAlignment.Left
    value.Text = initial
    value.Parent = card
    return value
end

local DashItems = DashboardCard(1, "ITEMS DETECTED", "0", Theme.Accent2)
local DashCycles = DashboardCard(2, "COMPLETED CYCLES", "0", Theme.Text)
local DashImportRate = DashboardCard(3, "IMPORT+ RATE", "0.0%", Color3.fromRGB(255, 125, 160))
local DashEstValue = DashboardCard(4, "ESTIMATED VALUE", "0.00", Color3.fromRGB(130, 225, 165))
local DashBestRarity = DashboardCard(5, "BEST RARITY", "NONE", Theme.Accent2)
local DashCratesPerMin = DashboardCard(6, "CYCLES / MIN", "0.0", Theme.Text)

local BestRarityLabel = Label("BEST RARITY             NONE", 22, Theme.Accent2)
local AverageItemsLabel = Label("ITEMS PER CYCLE         0.00", 22, Theme.Muted)
local AverageValueLabel = Label("EST. VALUE / CYCLE      0.00", 22, Theme.Muted)
local RarityRateLabel = Label("IMPORT+ REWARD RATE     0.0%", 22, Theme.Muted)
local GoalInput = MakeInput("Session goal (completed cycles)", "0")
local GoalProgressLabel = Label("SESSION GOAL            NOT SET", 22, Theme.Accent2)

Section("RECENT REWARDS")
local RewardFeedLabels = {}
for i = 1, 6 do
    RewardFeedLabels[i] = Label(string.format("%02d  WAITING FOR REWARD", i), 21, Theme.Muted)
end
local RewardFeed = {}
local BestRarityRank = 0
local BestRarityName = "NONE"

local function AddRewardFeed(rarityName, detail)
    local entry = string.upper(rarityName or "UNKNOWN")
    if detail and detail ~= "" then
        entry = entry .. "  /  " .. tostring(detail)
    end
    table.insert(RewardFeed, 1, entry)
    while #RewardFeed > 6 do
        table.remove(RewardFeed)
    end
    for i = 1, 6 do
        local value = RewardFeed[i]
        RewardFeedLabels[i].Text = string.format(
            "%02d  %s", i, value or "WAITING FOR REWARD"
        )
        RewardFeedLabels[i].TextColor3 = value and Theme.Accent2 or Theme.Muted
    end
end

--========================================================
-- IMPORT+ REWARD POPUP
-- Shows one premium notification per recorded crate batch.
--========================================================
local ImportPlusPopup = nil
local ImportPlusPopupToken = 0

local function ShowImportPlusPopup(rewardNames)
    if not rewardNames or #rewardNames == 0 or Destroyed then return end

    ImportPlusPopupToken = ImportPlusPopupToken + 1
    local thisToken = ImportPlusPopupToken

    if ImportPlusPopup and ImportPlusPopup.Parent then
        ImportPlusPopup:Destroy()
    end

    local hasBlackMarket = false
    for _, name in ipairs(rewardNames) do
        if string.find(string.upper(tostring(name)), "BLACK MARKET", 1, true) then
            hasBlackMarket = true
            break
        end
    end

    local titleText = hasBlackMarket and "✦  LEGENDARY DROP  ✦" or "✧  IMPORT+ DISCOVERED  ✧"
    local subtitleText = hasBlackMarket and "BLACK MARKET REWARD" or "IMPORT REWARD"
    local highlight = hasBlackMarket
        and Color3.fromRGB(255, 190, 92)
        or Color3.fromRGB(255, 105, 145)
    local popupHeight = hasBlackMarket and 174 or 150

    -- A restrained screen tint gives the reward reveal more impact without
    -- blocking input or changing any game controls.
    local overlay = Instance.new("Frame")
    overlay.Name = "MysticsImportPlusOverlay"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 90
    overlay.Parent = Gui
    ImportPlusPopup = overlay

    local popup = Instance.new("Frame")
    popup.Name = "MysticsImportPlusPopup"
    popup.AnchorPoint = Vector2.new(0.5, 0.5)
    popup.Position = UDim2.fromScale(0.5, 0.035)
    popup.Size = UDim2.new(0.88, 0, 0, popupHeight)
    popup.BackgroundColor3 = Theme.Panel
    popup.BackgroundTransparency = 0.04
    popup.BorderSizePixel = 0
    popup.ZIndex = 100
    popup.Parent = overlay

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 17)
    corner.Parent = popup

    local stroke = Instance.new("UIStroke")
    stroke.Color = highlight
    stroke.Thickness = hasBlackMarket and 2.5 or 1.8
    stroke.Transparency = 0.02
    stroke.Parent = popup

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(Theme.GradientA, Theme.GradientB)
    gradient.Rotation = 35
    gradient.Parent = popup

    local scale = Instance.new("UIScale")
    scale.Scale = 0.72
    scale.Parent = popup

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(1, -28, 0, 3)
    accent.Position = UDim2.fromOffset(14, 10)
    accent.BackgroundColor3 = highlight
    accent.BorderSizePixel = 0
    accent.ZIndex = 101
    accent.Parent = popup
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(1, 0)
    accentCorner.Parent = accent

    local emblem = Instance.new("TextLabel")
    emblem.BackgroundTransparency = 1
    emblem.Position = UDim2.new(0.5, -23, 0, 19)
    emblem.Size = UDim2.fromOffset(46, 38)
    emblem.Font = Enum.Font.GothamBlack
    emblem.Text = hasBlackMarket and "✦" or "◆"
    emblem.TextColor3 = highlight
    emblem.TextSize = hasBlackMarket and 34 or 29
    emblem.ZIndex = 101
    emblem.Parent = popup

    local heading = Instance.new("TextLabel")
    heading.BackgroundTransparency = 1
    heading.Position = UDim2.fromOffset(18, 59)
    heading.Size = UDim2.new(1, -36, 0, 27)
    heading.Font = Enum.Font.GothamBlack
    heading.Text = titleText
    heading.TextColor3 = highlight
    heading.TextSize = hasBlackMarket and 19 or 16
    heading.TextXAlignment = Enum.TextXAlignment.Center
    heading.ZIndex = 101
    heading.Parent = popup

    local subtitle = Instance.new("TextLabel")
    subtitle.BackgroundTransparency = 1
    subtitle.Position = UDim2.fromOffset(18, 88)
    subtitle.Size = UDim2.new(1, -36, 0, 19)
    subtitle.Font = Enum.Font.GothamBold
    subtitle.Text = subtitleText
    subtitle.TextColor3 = Theme.Muted
    subtitle.TextSize = 10
    subtitle.TextXAlignment = Enum.TextXAlignment.Center
    subtitle.ZIndex = 101
    subtitle.Parent = popup

    local detail = Instance.new("TextLabel")
    detail.BackgroundTransparency = 1
    detail.Position = UDim2.fromOffset(20, 111)
    detail.Size = UDim2.new(1, -40, 0, hasBlackMarket and 37 or 27)
    detail.Font = Enum.Font.GothamMedium
    detail.Text = table.concat(rewardNames, "  •  ")
    detail.TextColor3 = Theme.Text
    detail.TextSize = 12
    detail.TextWrapped = true
    detail.TextXAlignment = Enum.TextXAlignment.Center
    detail.TextYAlignment = Enum.TextYAlignment.Center
    detail.ZIndex = 101
    detail.Parent = popup

    -- Decorative starburst particles are contained within the popup overlay.
    local particleSymbols = {"✦", "✧", "·", "◇"}
    for i = 1, (hasBlackMarket and 16 or 9) do
        local particle = Instance.new("TextLabel")
        particle.BackgroundTransparency = 1
        particle.Size = UDim2.fromOffset(18, 18)
        particle.AnchorPoint = Vector2.new(0.5, 0.5)
        particle.Position = UDim2.fromScale(0.5, 0.5)
        particle.Font = Enum.Font.GothamBold
        particle.Text = particleSymbols[math.random(1, #particleSymbols)]
        particle.TextColor3 = highlight
        particle.TextTransparency = 0.12
        particle.TextSize = math.random(10, hasBlackMarket and 19 or 15)
        particle.ZIndex = 99
        particle.Parent = overlay

        local angle = (math.pi * 2) * (i / (hasBlackMarket and 16 or 9))
        local distance = hasBlackMarket and math.random(155, 225) or math.random(125, 175)
        local target = UDim2.new(0.5, math.cos(angle) * distance, 0.5, math.sin(angle) * distance)
        local particleTween = TweenService:Create(particle,
            TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = target, TextTransparency = 1, Rotation = math.random(-100, 100)})
        particleTween:Play()
        particleTween.Completed:Connect(function()
            if particle.Parent then particle:Destroy() end
        end)
    end

    TweenService:Create(overlay, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
    TweenService:Create(scale,
        TweenInfo.new(hasBlackMarket and 0.55 or 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = 1}):Play()
    TweenService:Create(popup, TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Position = UDim2.fromScale(0.5, 0.12)}):Play()

    -- Use the script's existing UI sound setting; no external assets required.
    if hasBlackMarket then
        PlayUISound(UI_CONFIRM_SOUND_ID, 0.55, 0.78)
    else
        PlayUISound(UI_CONFIRM_SOUND_ID, 0.38, 1.08)
    end

    task.delay(hasBlackMarket and 4.8 or 3.6, function()
        if thisToken ~= ImportPlusPopupToken or not overlay.Parent then return end
        local fadeInfo = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(overlay, fadeInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(scale, fadeInfo, {Scale = 0.88}):Play()
        for _, object in ipairs(overlay:GetDescendants()) do
            if object:IsA("TextLabel") then
                TweenService:Create(object, fadeInfo, {TextTransparency = 1}):Play()
            elseif object:IsA("UIStroke") then
                TweenService:Create(object, fadeInfo, {Transparency = 1}):Play()
            elseif object:IsA("Frame") and object ~= overlay then
                TweenService:Create(object, fadeInfo, {BackgroundTransparency = 1}):Play()
            end
        end
        task.wait(0.36)
        if thisToken == ImportPlusPopupToken and overlay.Parent then
            overlay:Destroy()
            ImportPlusPopup = nil
        end
    end)
end
RefreshAnalytics = function()
    local total = TotalItemsDetected
    local importPlus = RarityCounts.Import + RarityCounts.BlackMarket
    local importPlusRate = total > 0 and (importPlus / total) * 100 or 0
    local averageItems = CompletedCycles > 0 and total / CompletedCycles or 0
    local estimate = (RarityCounts.Uncommon * 0.125)
        + (RarityCounts.Rare * 0.25)
        + (RarityCounts.VeryRare * 0.50)
        + (RarityCounts.BlackMarket * 10)
    local averageValue = CompletedCycles > 0 and estimate / CompletedCycles or 0

    BestRarityLabel.Text = "BEST RARITY             " .. BestRarityName
    AverageItemsLabel.Text = string.format("ITEMS PER CYCLE         %.2f", averageItems)
    AverageValueLabel.Text = string.format("EST. VALUE / CYCLE      %.2f", averageValue)
    RarityRateLabel.Text = string.format("IMPORT+ REWARD RATE     %.1f%%", importPlusRate)

    local elapsed = math.max(1, os.clock() - SessionStart)
    DashItems.Text = tostring(total)
    DashCycles.Text = tostring(CompletedCycles)
    DashImportRate.Text = string.format("%.1f%%", importPlusRate)
    DashEstValue.Text = string.format("%.2f", estimate)
    DashBestRarity.Text = BestRarityName
    DashCratesPerMin.Text = string.format("%.1f", CompletedCycles / (elapsed / 60))

    local goal = math.max(0, math.floor(tonumber(GoalInput.Text) or 0))
    if goal > 0 then
        local percent = math.clamp((CompletedCycles / goal) * 100, 0, 100)
        GoalProgressLabel.Text = string.format(
            "SESSION GOAL            %d / %d  (%.0f%%)",
            math.min(CompletedCycles, goal), goal, percent
        )
    else
        GoalProgressLabel.Text = "SESSION GOAL            NOT SET"
    end
end

-- Import is counted separately. Its value weight is left at zero because
-- the original script did not define an Import value estimate.
local function UpdateSessionValue()
    local imp = RarityCounts.Import
    local u = RarityCounts.Uncommon
    local r = RarityCounts.Rare
    local vr = RarityCounts.VeryRare
    local blackMarket = RarityCounts.BlackMarket

    local minimum = (u * 0.10) + (r * 0.20) + (vr * 0.50) + (blackMarket * 1)
    local estimate = (u * 0.125) + (r * 0.25) + (vr * 0.50) + (blackMarket * 10)
    local maximum = (u * 0.15) + (r * 0.30) + (vr * 0.50) + (blackMarket * 20)

    ValueLowLabel.Text = string.format("MINIMUM VALUE       %.2f", minimum)
    ValueMidLabel.Text = string.format("ESTIMATED VALUE     %.2f", estimate)
    ValueHighLabel.Text = string.format("MAXIMUM VALUE       %.2f", maximum)
    ValueBreakdownLabel.Text = string.format(
        "IMP %d  |  U %d  |  R %d  |  VR %d  |  BM %d",
        imp, u, r, vr, blackMarket
    )
end

-- Capture ONLY the coloured text labels at the very bottom of the
-- three reward columns. Card borders, UIStrokes, images and other text
-- elsewhere on the screen are deliberately ignored.
local PendingRewardRarities = {}
local RewardAlreadyRecorded = false

local function NormalizeRarityText(text)
    text = string.upper(tostring(text or ""))
    text = text:gsub("[%p%c]", " ")
    text = text:gsub("%s+", " ")
    return text:match("^%s*(.-)%s*$") or ""
end

local function RarityFromText(text)
    local normalized = NormalizeRarityText(text)
    -- Text matching is more reliable than colour alone and handles themes,
    -- anti-aliasing and slightly different Import label colours.
    if normalized == "BLACK MARKET" or normalized == "BLACKMARKET" then
        return "BlackMarket", "BLACK MARKET"
    elseif normalized == "VERY RARE" or normalized == "VERYRARE" then
        return "VeryRare", "VERY RARE"
    elseif normalized == "RARE" then
        return "Rare", "RARE"
    elseif normalized == "UNCOMMON" then
        return "Uncommon", "UNCOMMON"
    end
    return nil
end

local function ReelFromX(x, viewportWidth)
    return math.clamp(math.floor((x / math.max(1, viewportWidth)) * 3) + 1, 1, 3)
end

local function RarityFromCaptionColor(color)
    if typeof(color) ~= "Color3" then return nil end

    local hue, saturation, value = Color3.toHSV(color)
    if saturation < 0.45 or value < 0.35 then return nil end

    -- The supplied reward screenshot shows the selected Import reward's
    -- small caption (e.g. "LIME") in red beneath the three reward columns.
    -- Only use colour in this narrow result-caption strip, never globally.
    if hue >= 0.94 or hue <= 0.045 then
        return "Import", "IMPORT"
    end
    return nil
end

local function CaptureRewardRarities()
    if RewardAlreadyRecorded or WaitingForFreeOpen or GameCheckPaused then
        return
    end

    PendingRewardRarities = {}
    if WaitingForNext and not SawButtonDisappear then
        return
    end

    local root = Player:FindFirstChild("PlayerGui")
    if not root then return end

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1777, 882)

    -- Confirm this is the results page, but do not use its red text as a
    -- rarity signal. In the supplied screenshots rarity is encoded by the
    -- coloured outline of the selected item card.
    local resultScreenVisible = false
    for _, obj in ipairs(root:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible
            and obj.AbsoluteSize.X > 0 and obj.AbsoluteSize.Y > 0 then
            local text = NormalizeRarityText(obj.Text)
            if text == "NEW ITEMS" or text == "OPEN AGAIN" then
                resultScreenVisible = true
                break
            end
        end
    end
    if not resultScreenVisible then return end

    local byReel = {{}, {}, {}}

    -- The selected reward is the large card intersected by the horizontal
    -- selection line near the middle of each reel. Read that card's UIStroke
    -- colour, not arbitrary red caption text elsewhere on the screen.
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("UIStroke") and obj.Enabled and obj.Thickness >= 1 then
            local card = obj.Parent
            if card and card:IsA("GuiObject") and card.Visible then
                local pos = card.AbsolutePosition
                local size = card.AbsoluteSize
                local widthRatio = size.X / math.max(1, viewport.X)
                local heightRatio = size.Y / math.max(1, viewport.Y)
                local centerX = pos.X + size.X / 2
                local centerY = pos.Y + size.Y / 2
                local yRatio = centerY / math.max(1, viewport.Y)

                -- Ignore outer reel frames, tiny labels, and full-screen
                -- decorative outlines. The actual item tiles in the user's
                -- screenshots are medium/large portrait-ish cards.
                local looksLikeItemCard =
                    widthRatio >= 0.10 and widthRatio <= 0.25
                    and heightRatio >= 0.16 and heightRatio <= 0.40
                    and yRatio >= 0.32 and yRatio <= 0.70

                if looksLikeItemCard then
                    local hue, saturation, value = Color3.toHSV(obj.Color)
                    local rarity = nil
                    local displayName = nil

                    if saturation >= 0.50 and value >= 0.32 then
                        -- Leave ambiguous cyan/blue-green hues unclassified
                        -- rather than incorrectly promoting an Uncommon to Rare.
                        if hue >= 0.94 or hue <= 0.045 then
                            rarity, displayName = "Import", "IMPORT"
                        elseif hue >= 0.20 and hue <= 0.49 then
                            rarity, displayName = "Uncommon", "UNCOMMON"
                        elseif hue >= 0.56 and hue < 0.69 then
                            rarity, displayName = "Rare", "RARE"
                        elseif hue >= 0.72 and hue < 0.88 then
                            rarity, displayName = "VeryRare", "VERY RARE"
                        end
                    end

                    -- Black Market is only accepted from an explicit
                    -- rarity label; never infer it from a dark/black border.
                    if rarity then
                        local reel = math.clamp(
                            math.floor((centerX / math.max(1, viewport.X)) * 3) + 1,
                            1, 3
                        )
                        table.insert(byReel[reel], {
                            Rarity = rarity,
                            DisplayName = displayName,
                            SourceText = "CARD OUTLINE",
                            YDistance = math.abs(yRatio - 0.50),
                            Area = size.X * size.Y
                        })
                    end
                end
            end
        end
    end

    -- Explicit rarity labels, when the game exposes them, take precedence
    -- for Black Market. Only accept labels within the bottom caption strip.
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible and obj.Text then
            local rarity, displayName = RarityFromText(obj.Text)
            if rarity == "BlackMarket" then
                local centerX = obj.AbsolutePosition.X + obj.AbsoluteSize.X / 2
                local centerY = obj.AbsolutePosition.Y + obj.AbsoluteSize.Y / 2
                if centerY >= viewport.Y * 0.72 and centerY <= viewport.Y + 150 then
                    local reel = math.clamp(
                        math.floor((centerX / math.max(1, viewport.X)) * 3) + 1,
                        1, 3
                    )
                    byReel[reel] = {{
                        Rarity = "BlackMarket",
                        DisplayName = displayName,
                        SourceText = tostring(obj.Text),
                        YDistance = 0,
                        Area = math.huge
                    }}
                end
            end
        end
    end

    for reel = 1, 3 do
        -- Pick the card closest to the horizontal selection line; if tied,
        -- prefer the larger card. This avoids classifying the scrolling
        -- cards above/below the actual reward.
        table.sort(byReel[reel], function(x, y)
            if math.abs(x.YDistance - y.YDistance) > 0.001 then
                return x.YDistance < y.YDistance
            end
            return x.Area > y.Area
        end)
        if byReel[reel][1] then
            PendingRewardRarities[reel] = byReel[reel][1]
        end
    end
end

local function DetectRewardRarities()
    local rewards = {}
    for reel = 1, 3 do
        local reward = PendingRewardRarities[reel]
        if not reward then return nil end
        rewards[reel] = reward
    end
    return rewards
end

local function RecordReward(forcePartial)
    if RewardAlreadyRecorded then return false end

    -- Take one final sample before using the cached sightings.
    CaptureRewardRarities()

    local rewards = {}
    local found = 0
    for reel = 1, 3 do
        local reward = PendingRewardRarities[reel]
        if reward then
            rewards[#rewards + 1] = reward
            found = found + 1
        elseif not forcePartial then
            DetectionLabel.Text = string.format(
                "CAPTURING RARITIES  /  %d OF 3 REELS", found
            )
            return false
        end
    end

    -- In forcePartial mode, missing labels are recorded as unknown rather
    -- than guessed. Crucially, this still returns control to the click engine.
    local batchMinimum = 0
    local batchEstimate = 0
    local batchMaximum = 0

    local valueTable = {
        Import = {0, 0, 0},
        Uncommon = {0.10, 0.125, 0.15},
        Rare = {0.20, 0.25, 0.30},
        VeryRare = {0.50, 0.50, 0.50},
        BlackMarket = {1.00, 10.00, 20.00}
    }

    local names = {}
    local importPlusRewards = {}
    -- Rocket League quality order. The Import+ tracker only includes
    -- Import and Black Market because Exotic is not currently detected.
    local rarityRanks = {
        Uncommon = 1,
        Rare = 2,
        VeryRare = 3,
        Import = 4,
        BlackMarket = 5
    }
    local rarityDisplay = {
        Import = "IMPORT",
        Uncommon = "UNCOMMON",
        Rare = "RARE",
        VeryRare = "VERY RARE",
        BlackMarket = "BLACK MARKET"
    }
    for _, reward in ipairs(rewards) do
        local values = valueTable[reward.Rarity]
        if values then
            RarityCounts[reward.Rarity] = RarityCounts[reward.Rarity] + 1
            batchMinimum = batchMinimum + values[1]
            batchEstimate = batchEstimate + values[2]
            batchMaximum = batchMaximum + values[3]
            TotalItemsDetected = TotalItemsDetected + 1
            names[#names + 1] = rarityDisplay[reward.Rarity] or reward.DisplayName
            local rank = rarityRanks[reward.Rarity] or 0
            -- Keep the dedicated rarity feed focused on Import and above.
            if rank >= 4 then
                local rewardName = rarityDisplay[reward.Rarity] or reward.Rarity
                AddRewardFeed(rewardName, reward.SourceText)
                table.insert(importPlusRewards, rewardName)
            end
            if rank >= 4 and rank > BestRarityRank then
                BestRarityRank = rank
                BestRarityName = rarityDisplay[reward.Rarity] or reward.Rarity
            end
        end
    end

    if #importPlusRewards > 0 then
        ShowImportPlusPopup(importPlusRewards)
    end

    LastBatchMinimum = batchMinimum
    LastBatchEstimate = batchEstimate
    LastBatchMaximum = batchMaximum
    RewardAlreadyRecorded = true

    if found == 3 then
        DetectionLabel.Text = string.format(
            "3 ITEMS ADDED  /  %s + %s + %s",
            names[1], names[2], names[3]
        )
    elseif found > 0 then
        DetectionLabel.Text = string.format(
            "%d OF 3 ITEMS COUNTED  /  OPENING ANYWAY", found
        )
    else
        DetectionLabel.Text = "RARITY NOT CAPTURED  /  OPENING ANYWAY"
    end

    BatchValueLabel.Text = string.format(
        "LAST BATCH (%d/3)  %.2f / %.2f / %.2f",
        found, batchMinimum, batchEstimate, batchMaximum
    )

    UpdateSessionValue()
    UpdateStats()
    RefreshAnalytics()
    return true
end

local function ResetSessionValue()
    RarityCounts.Import = 0
    RarityCounts.Uncommon = 0
    RarityCounts.Rare = 0
    RarityCounts.VeryRare = 0
    RarityCounts.BlackMarket = 0
    TotalItemsDetected = 0
    LastBatchMinimum = 0
    LastBatchEstimate = 0
    LastBatchMaximum = 0
    RewardAlreadyRecorded = false
    PendingRewardRarities = {}
    RewardFeed = {}
    BestRarityRank = 0
    BestRarityName = "NONE"
    for i = 1, 6 do
        RewardFeedLabels[i].Text = string.format("%02d  WAITING FOR REWARD", i)
        RewardFeedLabels[i].TextColor3 = Theme.Muted
    end
    DetectionLabel.Text = "WAITING FOR FIRST REWARD"
    BatchValueLabel.Text = "LAST 3-ITEM BATCH       —"
    UpdateSessionValue()
    RefreshAnalytics()
end

UpdateSessionValue()

--========================================================
-- AUTOMATION TAB
--========================================================

SelectPage("AUTOMATION")
Section("AUTOMATION SETTINGS")

local ModeButton

ModeButton = MakeButton("MODE  /  SMART", function()
    if Mode == "SMART" then
        Mode = "TIMED"
    elseif Mode == "TIMED" then
        Mode = "HYBRID"
    else
        Mode = "SMART"
    end

    ModeButton.Text = "MODE  /  " .. Mode
end)

Label("CLICK DELAY (0.5–30 SECONDS)", 20, Theme.Muted)
local DelayInput = MakeInput("Seconds", "2")

Label("MAX CASES (0 = UNLIMITED)", 20, Theme.Muted)
local MaxInput = MakeInput("Case limit", "0")

Label("RANDOM EXTRA DELAY", 20, Theme.Muted)
local RandomInput = MakeInput("Extra seconds", "0")

local RandomButton

RandomButton = MakeButton("RANDOM DELAY  /  OFF", function()
    RandomEnabled = not RandomEnabled

    RandomButton.Text = RandomEnabled
        and "RANDOM DELAY  /  ON"
        or "RANDOM DELAY  /  OFF"
end)

--========================================================
-- BUTTON DETECTION
--========================================================

local function FindOpenAgain()
    local root = Player:FindFirstChild("PlayerGui")
    if not root then return nil end

    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("TextButton")
            and obj.Visible
            and obj.Active
            and obj.AbsoluteSize.X > 0
            and obj.AbsoluteSize.Y > 0
            and string.find(
                string.upper(obj.Text),
                "OPEN AGAIN",
                1,
                true
            ) then

            return obj
        end
    end

    return nil
end

-- Finds the free-crate button shown after the activity-check dialog.
local function FindOpenFree()
    local root = Player:FindFirstChild("PlayerGui")
    if not root then return nil end

    local function IsFreeOpenLabel(value)
        local text = string.upper((value or ""):gsub("%s+", " "))
        text = text:gsub("^%s+", ""):gsub("%s+$", "")
        return string.find(text, "OPEN 3 FREE", 1, true) ~= nil
            or string.find(text, "OPEN FREE", 1, true) ~= nil
    end

    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("GuiButton")
            and obj.Visible
            and obj.Active
            and obj.AbsoluteSize.X > 0
            and obj.AbsoluteSize.Y > 0 then

            -- Support both TextButtons and ImageButtons whose caption is a
            -- separate TextLabel. The current game caption is "OPEN 3 FREE".
            if obj:IsA("TextButton") and IsFreeOpenLabel(obj.Text) then
                return obj
            end

            for _, child in ipairs(obj:GetDescendants()) do
                if child:IsA("TextLabel") and child.Visible
                    and IsFreeOpenLabel(child.Text) then
                    return obj
                end
            end
        end
    end

    return nil
end

--========================================================
-- MOUSE CLICK
--========================================================

local function ClickButton(button)
    if not button or not button.Parent then
        return false
    end

    if not button:IsA("GuiButton") or not button.Visible
        or not button.Active or button.AbsoluteSize.X <= 0
        or button.AbsoluteSize.Y <= 0 then
        return false
    end

    -- First try Roblox's GUI activation API. This targets the button itself
    -- and does not depend on the player's current cursor position.
    local activated = pcall(function()
        button:Activate()
    end)

    if activated then
        return true
    end

    -- Fallback for executor environments that expose firesignal.
    if typeof(firesignal) == "function" then
        local fired = pcall(function()
            firesignal(button.Activated)
        end)

        if fired then
            return true
        end
    end

    -- Last fallback: coordinate-based input at the button's center.
    local p = button.AbsolutePosition
    local s = button.AbsoluteSize
    local x = p.X + s.X / 2
    local y = p.Y + s.Y / 2

    if typeof(mouse1click) == "function" then
        local sent = pcall(function()
            mouse1click(x, y)
        end)
        if sent then
            return true
        end
    end

    local vim
    local gotVim = pcall(function()
        vim = game:GetService("VirtualInputManager")
    end)

    if gotVim and vim then
        return pcall(function()
            vim:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait(0.05)
            vim:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end)
    end

    return false
end

local PauseButton

--========================================================
-- GAME ACTIVITY CHECK MONITOR
-- The player completes the game's activity check manually.
-- Automation pauses while the prompt is visible and safely
-- resets the interrupted crate-opening state after it clears.
--========================================================

local function FindStillThereButton()
    local root = Player:FindFirstChild("PlayerGui")
    if not root then return nil end

    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("TextButton")
            and obj.Visible
            and obj.Active
            and obj.AbsoluteSize.X > 0
            and obj.AbsoluteSize.Y > 0 then

            local text = string.upper((obj.Text or ""):gsub("%s+", " "))
            text = text:gsub("^%s+", ""):gsub("%s+$", "")
            if text == "I AM HERE" then
                return obj
            end
        end
    end
    return nil
end

local function IsStillTherePromptVisible()
    local root = Player:FindFirstChild("PlayerGui")
    if not root then return false end

    for _, obj in ipairs(root:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton"))
            and obj.Visible
            and obj.AbsoluteSize.X > 0
            and obj.AbsoluteSize.Y > 0 then

            local text = string.upper((obj.Text or ""):gsub("%s+", " "))
            if string.find(text, "STILL THERE", 1, true) then
                return true
            end
        end
    end
    return false
end

--========================================================
-- AUTOMATION ENGINE
--========================================================

local function SaveSessionHistory()
    local snapshot = {
        Clicks = ClickAttempts,
        Cycles = CompletedCycles,
        Items = TotalItemsDetected,
        Estimate = (RarityCounts.Uncommon * 0.125)
            + (RarityCounts.Rare * 0.25)
            + (RarityCounts.VeryRare * 0.50)
            + (RarityCounts.BlackMarket * 10),
        BestRarity = BestRarityName,
        Duration = math.max(0, os.clock() - SessionStart)
    }
    table.insert(History, snapshot)
    while #History > 20 do
        table.remove(History, 1)
    end
    SaveLocalData()
end

local function CompleteCycle()
    CompletedCycles = CompletedCycles + 1

    CurrentButton = nil
    WaitingForNext = false
    SawButtonDisappear = false

    UpdateStats()

    if MaxCases > 0 and CompletedCycles >= MaxCases then
        SaveSessionHistory()
        Running = false
        Status.Text = "●  CASE LIMIT REACHED"
        Notify("Case limit reached.")
    end
end

local LastGameCheckAttempt = 0
local FreeOpenStartedAt = 0
local FreeOpenLastAttemptAt = 0
local FreeOpenAttempts = 0
local FREE_OPEN_RECOVERY_TIMEOUT = 30
local FREE_OPEN_RETRY_INTERVAL = 2.0

local function EngineStep()
    -- Stage 1: detect the activity prompt and activate its confirmation button.
    if IsStillTherePromptVisible() then
        if not WaitingForFreeOpen then
            WaitingForFreeOpen = true
            FreeOpenClicked = false
            FreeOpenStartedAt = os.clock()
            FreeOpenLastAttemptAt = 0
            FreeOpenAttempts = 0

            -- Discard the pre-prompt reward button/state. It may no longer
            -- be valid after the game replaces the reward screen.
            CurrentButton = nil
            WaitingForNext = false
            SawButtonDisappear = false
            RewardAlreadyRecorded = false
            PendingRewardRarities = {}
        end

        GameCheckPaused = true
        Status.Text = "●  GAME CHECK — CONFIRMING"

        local confirmButton = FindStillThereButton()
        if confirmButton and os.clock() - LastGameCheckAttempt >= 1 then
            LastGameCheckAttempt = os.clock()
            if ClickButton(confirmButton) then
                Notify("Activity check confirmation activated.")
            end
        end
        return
    end

    -- The activity dialog has closed. Continue with the required free-open step.
    if GameCheckPaused then
        GameCheckPaused = false
        Status.Text = Paused and "●  PAUSED" or "●  RUNNING"
        if PauseButton then
            PauseButton.Text = Paused and "RESUME AUTOMATION" or "PAUSE AUTOMATION"
        end
        Notify("Activity check cleared — continuing recovery.")
    end

    if WaitingForFreeOpen then
        -- The reward screen is the strongest signal that recovery completed.
        -- Check it before the free button because some interfaces leave both
        -- controls in the hierarchy during their transition animation.
        local openAgain = FindOpenAgain()
        if openAgain then
            WaitingForFreeOpen = false
            FreeOpenClicked = false
            FreeOpenAttempts = 0
            FreeOpenLastAttemptAt = 0
            CurrentButton = nil
            WaitingForNext = false
            SawButtonDisappear = false
            RewardAlreadyRecorded = false
            Status.Text = Paused and "●  PAUSED" or "●  RUNNING"
            Notify("Recovery complete — OPEN AGAIN detected.")
            -- Fall through to the normal OPEN AGAIN handling below.
        else
            local freeButton = FindOpenFree()
            local now = os.clock()

            if freeButton and FreeOpenAttempts < 3
                and (FreeOpenLastAttemptAt == 0 or now - FreeOpenLastAttemptAt >= FREE_OPEN_RETRY_INTERVAL) then
                FreeOpenLastAttemptAt = now
                FreeOpenAttempts = FreeOpenAttempts + 1
                if ClickButton(freeButton) then
                    FreeOpenClicked = true
                    Status.Text = "●  OPENING FREE CRATE  " .. FreeOpenAttempts .. "/3"
                    Notify("OPEN FREE / 0 KEYS activated (attempt " .. FreeOpenAttempts .. ").")
                end
            end

            -- Wait for the game to transition. A bounded recovery window
            -- prevents a stale or hidden free button from freezing the engine.
            if now - FreeOpenStartedAt >= FREE_OPEN_RECOVERY_TIMEOUT then
                WaitingForFreeOpen = false
                FreeOpenClicked = false
                FreeOpenAttempts = 0
                FreeOpenLastAttemptAt = 0
                CurrentButton = nil
                WaitingForNext = false
                SawButtonDisappear = false
                RewardAlreadyRecorded = false
                Notify("Recovery wait ended — returning to normal button detection.")
            else
                return
            end
        end
    end

    -- Sample the reward UI every engine pass; rarity labels may vanish quickly.
    CaptureRewardRarities()

    local button = FindOpenAgain()

    if WaitingForNext then
        local originalAvailable =
            CurrentButton
            and CurrentButton.Parent
            and CurrentButton.Visible
            and CurrentButton.Active

        if not originalAvailable then
            -- The reward panel has transitioned; allow the next reward to be recorded.
            RewardAlreadyRecorded = false
            -- First observe the old button disappear/disable.
            SawButtonDisappear = true
            return
        end

        if SawButtonDisappear and button then
            -- The OPEN AGAIN control has returned: count one completed cycle.
            CompleteCycle()
        end

        return
    end

    if not button then return end

    if os.clock() - LastClick < Delay then
        return
    end

    -- The reward panel is still on screen here. Read its visible rarity text
    -- before pressing OPEN AGAIN and advancing to the next crate.
    -- Try to record all three rarities. If one or more labels were missed,
    -- count only the labels actually captured and continue regardless.
    -- Rarity detection must NEVER hold the crate-opening loop hostage.
    RecordReward(true)

    -- Clear the cache for the next opening. The recorded counts have already
    -- been committed above; missing labels remain unknown, not misclassified.
    PendingRewardRarities = {}

    -- ClickAttempts counts dispatches, not successful game-side opens.
    local attempted = ClickButton(button)
    if attempted then
        ClickAttempts = ClickAttempts + 1
        LastClick = os.clock()
        CurrentButton = button
        WaitingForNext = true
        SawButtonDisappear = false
        UpdateStats()
    end
end

--========================================================
-- MAIN CONTROLS
--========================================================

Section("CONTROL PANEL")

local function Start()
    if Running then return end

    Delay = math.clamp(
        tonumber(DelayInput.Text) or 2,
        0.5,
        30
    )

    MaxCases = math.max(
        0,
        math.floor(tonumber(MaxInput.Text) or 0)
    )

    RandomExtra = math.clamp(
        tonumber(RandomInput.Text) or 0,
        0,
        10
    )
    local requestedGoal = math.max(0, math.floor(tonumber(GoalInput.Text) or 0))
    GoalInput.Text = tostring(requestedGoal)

    ClickAttempts = 0
    CompletedCycles = 0
    ResetSessionValue()
    SessionStart = os.clock()
    LastClick = 0
    CurrentButton = nil
    WaitingForNext = false
    SawButtonDisappear = false
    GameCheckPaused = false
    WaitingForFreeOpen = false
    FreeOpenClicked = false
    LastGameCheckAttempt = 0
    FreeOpenStartedAt = 0
    FreeOpenLastAttemptAt = 0
    FreeOpenAttempts = 0
    TotalItemsDetected = 0
    Running = true
    Paused = false

    Status.Text = "●  RUNNING"
    PauseButton.Text = "PAUSE AUTOMATION"

    Notify("RL Crate Unboxing V1.6 started.")

    task.spawn(function()
        while Running and not Destroyed do
            if not Paused then
                EngineStep()
                UpdateStats()

                local waitTime = 0.25

                if Mode == "TIMED" then
                    waitTime = Delay
                elseif Mode == "HYBRID" then
                    waitTime = math.min(Delay, 0.5)
                end

                if RandomEnabled then
                    waitTime = waitTime +
                        math.random() * RandomExtra
                end

                task.wait(waitTime)
            else
                task.wait(0.2)
            end
        end
    end)
end

local function Stop()
    if Running then
        SaveSessionHistory()
    end

    Running = false
    Paused = false
    WaitingForNext = false
    SawButtonDisappear = false
    GameCheckPaused = false
    WaitingForFreeOpen = false
    FreeOpenClicked = false
    FreeOpenAttempts = 0
    FreeOpenStartedAt = 0
    CurrentButton = nil

    Status.Text = "●  STOPPED"
    UpdateStats()

    if PauseButton then
        PauseButton.Text = "PAUSE AUTOMATION"
    end

    Notify("Mystics automation stopped.")
end

MakeButton("START AUTOMATION", Start)

PauseButton = MakeButton("PAUSE AUTOMATION", function()
    if not Running then return end

    Paused = not Paused

    if not Paused then
        GameCheckPaused = false
    end

    PauseButton.Text = Paused
        and "RESUME AUTOMATION"
        or "PAUSE AUTOMATION"

    Status.Text = Paused
        and "●  PAUSED"
        or "●  RUNNING"
end)

MakeButton("EMERGENCY STOP", Stop, Theme.Panel2)

--========================================================
-- APPEARANCE & PROFILES TAB
--========================================================

SelectPage("APPEARANCE")
Section("MYSTICS THEME COLLECTION")

local ThemeButton
local SoundButton

--========================================================
-- THEME ATMOSPHERE
-- Christmas: drifting/falling snow.
-- Halloween: bats gliding across the panel.
-- Blood Red: rising crimson embers and glowing droplets.
--========================================================

local function StartThemeAtmosphere()
    AtmosphereGeneration = AtmosphereGeneration + 1
    local thisGeneration = AtmosphereGeneration

    for _, child in ipairs(Atmosphere:GetChildren()) do
        child:Destroy()
    end

    local particleSets = {
        OBSIDIAN = {"*", ".", "+", "o"},
        CHRISTMAS = {"❄", "❅", "✦"},
        HALLOWEEN = {"🎃", "*", "+"},
        ["BLOOD RED"] = {"◆", "●", "✦"}
    }

    local symbols = particleSets[Theme.Name]
    if not symbols then return end

    task.spawn(function()
        while not Destroyed and AtmosphereGeneration == thisGeneration do
            local symbol = symbols[math.random(1, #symbols)]
            local particle = Instance.new("TextLabel")
            local isPumpkin = Theme.Name == "HALLOWEEN"
            local isBlood = Theme.Name == "BLOOD RED"
            local isObsidian = Theme.Name == "OBSIDIAN"
            local isChristmas = Theme.Name == "CHRISTMAS"

            particle.Name = "LuxuryAtmosphereParticle"
            particle.BackgroundTransparency = 1
            particle.BorderSizePixel = 0
            particle.AnchorPoint = Vector2.new(0.5, 0.5)
            particle.Size = UDim2.fromOffset(
                isPumpkin and math.random(20, 30) or math.random(10, isObsidian and 18 or 23),
                isPumpkin and math.random(20, 30) or math.random(10, isObsidian and 18 or 23)
            )
            particle.Font = Enum.Font.GothamBold
            particle.Text = symbol
            particle.TextSize = isPumpkin and math.random(17, 25) or math.random(11, isObsidian and 18 or 21)
            particle.TextTransparency = isObsidian and 0.48 or (isBlood and 0.22 or 0.3)
            particle.ZIndex = 1

            if isChristmas then
                particle.TextColor3 = Color3.fromRGB(220, 245, 255)
            elseif isPumpkin then
                particle.TextColor3 = Color3.fromRGB(207, 174, 232)
            elseif isBlood then
                particle.TextColor3 = Color3.fromRGB(225, math.random(25, 65), math.random(45, 80))
            elseif isObsidian then
                particle.TextColor3 = Color3.fromRGB(170, 196, 225)
            else
                particle.TextColor3 = Theme.Accent2
            end

            local startX, startY, endX, endY
            if isPumpkin then
                local fromLeft = math.random(1, 2) == 1
                startX = fromLeft and -0.08 or 1.08
                endX = fromLeft and 1.08 or -0.08
                startY = math.random(12, 88) / 100
                endY = math.clamp(startY + math.random(-18, 18) / 100, 0.08, 0.92)
            elseif isBlood then
                startX, startY = math.random(5, 95) / 100, 1.08
                endX = math.clamp(startX + math.random(-12, 12) / 100, 0.03, 0.97)
                endY = -0.08
            elseif isObsidian then
                startX, startY = math.random(5, 95) / 100, math.random(8, 92) / 100
                endX = math.clamp(startX + math.random(-9, 9) / 100, 0.03, 0.97)
                endY = math.clamp(startY + math.random(-12, 12) / 100, 0.05, 0.95)
            else
                startX, startY = math.random(3, 97) / 100, -0.08
                endX = math.clamp(startX + math.random(-12, 12) / 100, 0.02, 0.98)
                endY = 1.08
            end

            particle.Position = UDim2.fromScale(startX, startY)
            particle.Parent = Atmosphere
            local duration = isBat and math.random(7, 11) or (isObsidian and math.random(5, 9) or math.random(6, 11))
            local tween = TweenService:Create(
                particle,
                TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {
                    Position = UDim2.fromScale(endX, endY),
                    Rotation = math.random(-120, 120),
                    TextTransparency = 1
                }
            )
            tween:Play()
            tween.Completed:Connect(function()
                if particle.Parent then particle:Destroy() end
            end)
            task.wait(isBat and 0.7 or (isObsidian and 0.45 or 0.25))
        end
    end)
end

local function ApplyTheme()
    Theme = Themes[ThemeIndex]
    StartThemeAtmosphere()

    Main.BackgroundColor3 = Theme.Background
    Header.BackgroundColor3 = Theme.Panel

    Title.TextColor3 = Theme.Text
    Subtitle.TextColor3 = Theme.Muted
    Creator.TextColor3 = Theme.Accent2
    Decoration.Text = Theme.Icon
    Decoration.TextColor3 = Theme.Accent2

    MainStroke.Color = Theme.Border
    MainGradient.Color = ColorSequence.new(
        Theme.GradientA,
        Theme.GradientB
    )

    HeaderGradient.Color = ColorSequence.new(
        Theme.GradientA,
        Theme.GradientB
    )

    ThemeButton.Text = "THEME  /  " .. Theme.Name
    if SoundButton then
        SoundButton.Text = UISoundsEnabled and "UI SOUNDS  /  ON" or "UI SOUNDS  /  OFF"
    end

    for _, obj in ipairs(Gui:GetDescendants()) do
        if obj:IsA("TextLabel") then
            local role = obj:GetAttribute("MysticsTextRole")
            if obj == Subtitle then
                obj.TextColor3 = Theme.Muted
            elseif obj == Creator or obj == Decoration or obj == Status then
                obj.TextColor3 = Theme.Accent2
            elseif role == "muted" then
                obj.TextColor3 = Theme.Muted
            elseif role == "accent" then
                obj.TextColor3 = Theme.Accent2
            elseif role == "main" then
                obj.TextColor3 = Theme.Text
            elseif role ~= "custom" and obj ~= Subtitle then
                obj.TextColor3 = Theme.Text
            end

        elseif obj:IsA("TextBox") then
            obj.BackgroundColor3 = Theme.Panel2
            obj.TextColor3 = Theme.Text
            obj.PlaceholderColor3 = Theme.Muted

        elseif obj:IsA("TextButton") then
            if obj == MinButton then
                obj.BackgroundColor3 = Theme.Panel2
            elseif obj:GetAttribute("MysticsButtonTone") == "secondary" then
                obj.BackgroundColor3 = Theme.Panel2
                obj.TextColor3 = Theme.Text
            elseif obj:GetAttribute("MysticsButtonTone") == "primary" then
                obj.BackgroundColor3 = Theme.Accent
                obj.TextColor3 = Theme.Text
            end
        elseif obj:IsA("Frame") and (obj.Name == "AccentBar") then
            obj.BackgroundColor3 = Theme.Accent2
        elseif obj:IsA("Frame") and obj.Name == "SectionRule" then
            obj.BackgroundColor3 = Theme.Border
        elseif obj:IsA("TextLabel") and obj.Name == "SectionTitle" then
            obj.TextColor3 = Theme.Accent2
        end

        if obj:IsA("TextLabel") and obj:GetAttribute("MysticsTextRole") then
            if obj.BackgroundTransparency < 1 then obj.BackgroundColor3 = Theme.Panel end
        end

        if obj:IsA("UIStroke") and obj ~= MainStroke then
            obj.Color = Theme.Border
        end

        if obj:IsA("UIGradient") and obj ~= MainGradient
            and obj ~= HeaderGradient then
            obj.Color = ColorSequence.new(
                Theme.Accent2,
                Theme.Accent
            )
        end
    end

    for _, page in pairs(Pages) do
        page.ScrollBarImageColor3 = Theme.Accent
    end
    SelectPage(CurrentPageName)
end

ThemeButton = MakeButton(
    "THEME  /  OBSIDIAN",
    function()
        ThemeIndex = ThemeIndex + 1

        if ThemeIndex > #Themes then
            ThemeIndex = 1
        end

        ApplyTheme()
        Notify("Theme: " .. Theme.Name)
    end
)

--========================================================
-- PROFILES
--========================================================

Section("SAVED PROFILES")

local ProfileInput = MakeInput("Profile name", "My Profile")

MakeButton("SAVE PROFILE", function()
    local name = ProfileInput.Text

    if name == "" then return end

    Profiles[name] = {
        Delay = DelayInput.Text,
        Max = MaxInput.Text,
        Random = RandomInput.Text,
        Goal = GoalInput.Text,
        Mode = Mode,
        Theme = ThemeIndex
    }

    SaveLocalData()
    Notify("Profile saved: " .. name)
end)

MakeButton("LOAD PROFILE", function()
    local p = Profiles[ProfileInput.Text]

    if not p then
        Notify("Profile not found.")
        return
    end

    DelayInput.Text = p.Delay
    MaxInput.Text = p.Max
    RandomInput.Text = p.Random
    GoalInput.Text = p.Goal or "0"

    Mode = p.Mode
    ThemeIndex = p.Theme

    ModeButton.Text = "MODE  /  " .. Mode
    ApplyTheme()

    Notify("Profile loaded.")
end)

MakeButton("VIEW SESSION HISTORY", function()
    if #History == 0 then
        Notify("No saved session history yet.")
        return
    end

    local lines = {}
    for i = math.max(1, #History - 4), #History do
        local item = History[i]
        lines[#lines + 1] = string.format(
            "#%d  %d cycles  |  %d items  |  %.2f value  |  %s",
            i, item.Cycles or 0, item.Items or 0,
            item.Estimate or 0, FormatTime(item.Duration or 0)
        )
    end
    Notify(table.concat(lines, "\n"))
end)

MakeButton("RESET SESSION STATISTICS", function()
    if Running then
        Notify("Stop automation before resetting session statistics.")
        return
    end
    ClickAttempts = 0
    CompletedCycles = 0
    SessionStart = 0
    ResetSessionValue()
    UpdateStats()
    Notify("Current session statistics reset.")
end, Theme.Panel2)

-- Open on the overview tab when the script finishes building.
SelectPage("OVERVIEW")

--========================================================
-- MINIMIZE
--========================================================

local MenuSizeTween
local function SetMinimized(value)
    if Minimized == value then return end
    Minimized = value
    MinButton.Text = value and "+" or "—"

    if MenuSizeTween then
        pcall(function() MenuSizeTween:Cancel() end)
    end

    if value then
        PlayUISound(UI_CLOSE_SOUND_ID, 0.32, 0.9)
        local target = UDim2.fromOffset(410, 94)
        MenuSizeTween = TweenService:Create(
            Main,
            TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut),
            {Size = target}
        )
        MenuSizeTween:Play()
        task.delay(0.22, function()
            if Minimized and not Destroyed then PageContainer.Visible = false TabBar.Visible = false end
        end)
    else
        PlayUISound(UI_OPEN_SOUND_ID, 0.38, 1.08)
        PageContainer.Visible = true
        TabBar.Visible = true
        Main.Size = UDim2.fromOffset(410, 94)
        MenuSizeTween = TweenService:Create(
            Main,
            TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = UDim2.fromOffset(410, 700)}
        )
        MenuSizeTween:Play()
    end
end

MinButton.MouseButton1Click:Connect(function()
    SetMinimized(not Minimized)
end)

--========================================================
-- DRAGGING
--========================================================

local dragging = false
local dragStart
local startPosition

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)

local DragChanged = UIS.InputChanged:Connect(function(input)
    if not dragging then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

local DragEnded = UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = false
    end
end)

--========================================================
-- HOTKEYS
--========================================================

local KeyConnection = UIS.InputBegan:Connect(function(input, processed)
    if processed or Destroyed then return end

    if input.KeyCode == Enum.KeyCode.F6 then
        if Running then
            Stop()
        else
            Start()
        end

    elseif input.KeyCode == Enum.KeyCode.F7 then
        Stop()

    elseif input.KeyCode == Enum.KeyCode.F8 then
        if Running then
            Paused = not Paused

            if not Paused then
                GameCheckPaused = false
            end

            PauseButton.Text = Paused
                and "RESUME AUTOMATION"
                or "PAUSE AUTOMATION"

            Status.Text = Paused
                and "●  PAUSED"
                or "●  RUNNING"
        end
    end
end)

--========================================================
-- LIVE STATISTICS
--========================================================

task.spawn(function()
    while not Destroyed do
        if Running then
            UpdateStats()
        end

        task.wait(1)
    end
end)

--========================================================
-- CLEANUP
--========================================================

local function Cleanup()
    if Destroyed then return end

    Stop()
    SetAntiAfkEnabled(false)
    Destroyed = true
    AtmosphereGeneration = AtmosphereGeneration + 1

    if FpsConnection then
        FpsConnection:Disconnect()
        FpsConnection = nil
    end

    pcall(function() EntranceTween:Cancel() end)
    pcall(function() PositionTween:Cancel() end)
    pcall(function() HeaderFadeTween:Cancel() end)
    pcall(function() AmbientGradientTween:Cancel() end)
    pcall(function() HeaderGradientTween:Cancel() end)
    pcall(function() BorderPulseTween:Cancel() end)
    pcall(function() if MenuSizeTween then MenuSizeTween:Cancel() end end)

    if KeyConnection then
        KeyConnection:Disconnect()
    end

    if DragChanged then
        DragChanged:Disconnect()
    end

    if DragEnded then
        DragEnded:Disconnect()
    end

    Gui:Destroy()
end

CloseButton.MouseButton1Click:Connect(Cleanup)

if getgenv then
    getgenv().MysticsCleanup = Cleanup
end

-- Premium UI sound toggle. Kept separate from automation controls.
SoundButton = MakeButton("UI SOUNDS  /  ON", function()
    UISoundsEnabled = not UISoundsEnabled
    SoundButton.Text = UISoundsEnabled and "UI SOUNDS  /  ON" or "UI SOUNDS  /  OFF"
    if UISoundsEnabled then
        PlayUISound(UI_CONFIRM_SOUND_ID, 0.22, 1.04)
    end
end, Theme.Panel2)

ApplyTheme()

--========================================================
-- MENU ENTRANCE ANIMATION
-- Soft fade, slight rise and a spring-like scale-in.
--========================================================

local EntranceScale = Instance.new("UIScale")
EntranceScale.Scale = 0.86
EntranceScale.Parent = Main

local TargetPosition = Main.Position
Main.Position = UDim2.new(
    TargetPosition.X.Scale,
    TargetPosition.X.Offset,
    TargetPosition.Y.Scale,
    TargetPosition.Y.Offset + 28
)
Main.BackgroundTransparency = 1
Header.BackgroundTransparency = 1

local EntranceTween = TweenService:Create(
    EntranceScale,
    TweenInfo.new(0.62, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    {Scale = 1}
)
local PositionTween = TweenService:Create(
    Main,
    TweenInfo.new(0.62, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    {
        Position = TargetPosition,
        BackgroundTransparency = 0
    }
)
local HeaderFadeTween = TweenService:Create(
    Header,
    TweenInfo.new(0.48, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    {BackgroundTransparency = 0}
)

PlayUISound(UI_OPEN_SOUND_ID, 0.38, 1.08)
EntranceTween:Play()
PositionTween:Play()
HeaderFadeTween:Play()

print("======================================")
print("RL CRATE UNBOXING V1.8")
print("WHY PAY WHEN YOU’RE THE GOAT")
print("Version 1.8")
print("F6 Start / Stop")
print("F7 Emergency Stop")
print("F8 Pause / Resume")
print("======================================")

Notify("Mystics Crate Unboxing loaded — Anti-AFK monitor integrated.")

