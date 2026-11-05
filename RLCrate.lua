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
        Background = Color3.fromRGB(36, 42, 58),
        Panel = Color3.fromRGB(56, 65, 85),
        Panel2 = Color3.fromRGB(78, 89, 113),
        Text = Color3.fromRGB(248, 250, 255),
        Muted = Color3.fromRGB(215, 223, 235),
        Accent = Color3.fromRGB(126, 166, 255),
        Accent2 = Color3.fromRGB(176, 204, 255),
        Border = Color3.fromRGB(143, 166, 205),
        GradientA = Color3.fromRGB(102, 118, 146),
        GradientB = Color3.fromRGB(36, 42, 58)
    },

    {
        Name = "BLOOD RED",
        Icon = "◆",
        Tag = "THE RUBY COLLECTION",
        Decoration = {"◆", "♦", "✦"},
        Background = Color3.fromRGB(46, 10, 22),
        Panel = Color3.fromRGB(86, 20, 40),
        Panel2 = Color3.fromRGB(122, 30, 55),
        Text = Color3.fromRGB(255, 249, 251),
        Muted = Color3.fromRGB(244, 219, 228),
        Accent = Color3.fromRGB(214, 46, 79),
        Accent2 = Color3.fromRGB(255, 164, 184),
        Border = Color3.fromRGB(197, 84, 114),
        GradientA = Color3.fromRGB(150, 28, 58),
        GradientB = Color3.fromRGB(46, 10, 22)
    },

    {
        Name = "CHRISTMAS",
        Icon = "❄",
        Tag = "THE WINTER RESERVE COLLECTION",
        Decoration = {"❄", "✦", "✧"},
        Background = Color3.fromRGB(20, 52, 62),
        Panel = Color3.fromRGB(36, 92, 102),
        Panel2 = Color3.fromRGB(52, 118, 122),
        Text = Color3.fromRGB(248, 255, 252),
        Muted = Color3.fromRGB(224, 242, 239),
        Accent = Color3.fromRGB(129, 225, 199),
        Accent2 = Color3.fromRGB(242, 225, 168),
        Border = Color3.fromRGB(117, 186, 172),
        GradientA = Color3.fromRGB(70, 155, 140),
        GradientB = Color3.fromRGB(20, 52, 62)
    },

    {
        Name = "HALLOWEEN",
        Icon = "🎃",
        Tag = "THE MIDNIGHT MASQUERADE COLLECTION",
        Decoration = {"🎃", "*", "+"},
        Background = Color3.fromRGB(46, 26, 60),
        Panel = Color3.fromRGB(86, 50, 112),
        Panel2 = Color3.fromRGB(114, 67, 140),
        Text = Color3.fromRGB(255, 247, 240),
        Muted = Color3.fromRGB(238, 217, 240),
        Accent = Color3.fromRGB(255, 166, 84),
        Accent2 = Color3.fromRGB(255, 204, 132),
        Border = Color3.fromRGB(184, 126, 211),
        GradientA = Color3.fromRGB(154, 89, 194),
        GradientB = Color3.fromRGB(46, 26, 60)
    }
}

local Theme = Themes[ThemeIndex]
local VisualFX = {}

--========================================================
-- GUI HELPERS
--========================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "RL_Crate_Unboxing_V1_5_Luxury"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
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
Main.Size = UDim2.fromOffset(448, 700)
Main.Position = UDim2.new(0, 28, 0.06, 0)
Main.BackgroundColor3 = Theme.Background
Main.BorderSizePixel = 0
Main.Active = true
Main.ClipsDescendants = true
Main.Parent = Gui

Corner(Main, 24)
local MainStroke = Stroke(Main, Theme.Border, 1.6)
local MainGradient = Gradient(Main, Theme.Panel:Lerp(Color3.fromRGB(62, 72, 91), 0.58), Theme.Background:Lerp(Color3.fromRGB(52, 60, 80), 0.72))
-- High-visibility slate glass: real contrast, not additional dark overlays.
VisualFX.GlassTop = Color3.fromRGB(104, 118, 141)
VisualFX.GlassBottom = Color3.fromRGB(79, 91, 112)
VisualFX.CardTop = Color3.fromRGB(115, 128, 148)
VisualFX.CardBottom = Color3.fromRGB(94, 108, 131)
VisualFX.LabelBackground = Color3.fromRGB(104, 116, 137)
VisualFX.SecondaryBackground = Color3.fromRGB(105, 117, 139)

VisualFX.MainAura = Instance.new("Frame")
VisualFX.MainAura.Name = "MysticsMainAura"
VisualFX.MainAura.Position = UDim2.new(0, 0, 0, -22)
VisualFX.MainAura.Size = UDim2.new(1, 0, 0, 154)
VisualFX.MainAura.BackgroundColor3 = Theme.Accent2
VisualFX.MainAura.BackgroundTransparency = 0.94
VisualFX.MainAura.BorderSizePixel = 0
VisualFX.MainAura.ZIndex = 1
VisualFX.MainAura.Parent = Main
Corner(VisualFX.MainAura, 22)
VisualFX.MainAuraGradient = Instance.new("UIGradient")
VisualFX.MainAuraGradient.Rotation = 90
VisualFX.MainAuraGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.18),
    NumberSequenceKeypoint.new(0.48, 0.72),
    NumberSequenceKeypoint.new(1, 1)
})
VisualFX.MainAuraGradient.Parent = VisualFX.MainAura

-- Slow cinematic light behind the glass interface. No per-frame callbacks.
for i = 1, 2 do
    local orb = Instance.new("Frame")
    orb.Name = "MysticsAmbientOrb" .. i
    orb.AnchorPoint = Vector2.new(0.5, 0.5)
    orb.Size = UDim2.fromOffset(i == 1 and 242 or 202, i == 1 and 242 or 202)
    orb.Position = UDim2.fromScale(i == 1 and 0.18 or 0.84, i == 1 and 0.20 or 0.81)
    orb.BackgroundColor3 = Theme.Accent2
    orb.BackgroundTransparency = 0.94
    orb.BorderSizePixel = 0
    orb.ZIndex = 1
    orb.Parent = Main
    Corner(orb, 999)
    local orbGradient = Instance.new("UIGradient")
    orbGradient.Rotation = i == 1 and 38 or 148
    orbGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.45, 0.38),
        NumberSequenceKeypoint.new(1, 1)
    })
    orbGradient.Parent = orb
    TweenService:Create(orb,
        TweenInfo.new(9 + i * 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {
            Position = UDim2.fromScale(i == 1 and 0.38 or 0.68, i == 1 and 0.33 or 0.66),
            BackgroundTransparency = 0.975
        }
    ):Play()
end

-- Existing theme particles remain behind controls.
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

Corner(Header, 22)
local HeaderGradient = Gradient(
    Header,
    Theme.Panel2,
    Theme.Panel,
    0
)

VisualFX.HeaderSheen = Instance.new("Frame")
VisualFX.HeaderSheen.Name = "HeaderGlassSheen"
VisualFX.HeaderSheen.Position = UDim2.fromOffset(2, 2)
VisualFX.HeaderSheen.Size = UDim2.new(1, -4, 0, 62)
VisualFX.HeaderSheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
VisualFX.HeaderSheen.BackgroundTransparency = 0.965
VisualFX.HeaderSheen.BorderSizePixel = 0
VisualFX.HeaderSheen.ZIndex = 1
VisualFX.HeaderSheen.Parent = Header
Corner(VisualFX.HeaderSheen, 20)
VisualFX.HeaderSheenGradient = Instance.new("UIGradient")
VisualFX.HeaderSheenGradient.Rotation = 90
VisualFX.HeaderSheenGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.20),
    NumberSequenceKeypoint.new(1, 1)
})
VisualFX.HeaderSheenGradient.Parent = VisualFX.HeaderSheen

VisualFX.HeaderRule = Instance.new("Frame")
VisualFX.HeaderRule.Name = "HeaderAccentRule"
VisualFX.HeaderRule.Position = UDim2.new(0, 18, 1, -3)
VisualFX.HeaderRule.Size = UDim2.new(1, -36, 0, 1)
VisualFX.HeaderRule.BackgroundColor3 = Theme.Accent2
VisualFX.HeaderRule.BackgroundTransparency = 0.28
VisualFX.HeaderRule.BorderSizePixel = 0
VisualFX.HeaderRule.Parent = Header
VisualFX.HeaderRuleGradient = Instance.new("UIGradient")
VisualFX.HeaderRuleGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.18, 0.35),
    NumberSequenceKeypoint.new(0.82, 0.35),
    NumberSequenceKeypoint.new(1, 1)
})
VisualFX.HeaderRuleGradient.Parent = VisualFX.HeaderRule

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

-- Polished edge sweep on the existing border (no extra rendering loop).
VisualFX.BorderSweep = Instance.new("UIGradient")
VisualFX.BorderSweep.Color = ColorSequence.new(Theme.Accent2, Theme.Border)
VisualFX.BorderSweep.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.70),
    NumberSequenceKeypoint.new(0.42, 0.18),
    NumberSequenceKeypoint.new(0.53, 0),
    NumberSequenceKeypoint.new(0.64, 0.18),
    NumberSequenceKeypoint.new(1, 0.70)
})
VisualFX.BorderSweep.Offset = Vector2.new(-1, 0)
VisualFX.BorderSweep.Parent = MainStroke
VisualFX.BorderSweepTween = TweenService:Create(
    VisualFX.BorderSweep,
    TweenInfo.new(9.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Offset = Vector2.new(1, 0)}
)
VisualFX.BorderSweepTween:Play()

VisualFX.AuraPulse = TweenService:Create(
    VisualFX.MainAura,
    TweenInfo.new(5.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {BackgroundTransparency = 0.975}
)
VisualFX.AuraPulse:Play()

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
Subtitle.Text = Theme.Tag
Subtitle.TextColor3 = Theme.Muted
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 11
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

local Creator = Instance.new("TextLabel")
Creator.Size = UDim2.new(1, -155, 0, 17)
Creator.Position = UDim2.fromOffset(21, 64)
Creator.BackgroundTransparency = 1
Creator.Text = "MYSTICS  •  PREMIUM CRATE SUITE"
Creator.TextColor3 = Theme.Accent2
Creator.Font = Enum.Font.GothamSemibold
Creator.TextSize = 10
Creator.TextXAlignment = Enum.TextXAlignment.Left
Creator.Parent = Header

-- Signature Mystics monogram: round glass badge with glint and slow float.
VisualFX.Emblem = Instance.new("Frame")
VisualFX.Emblem.Name = "MysticsEmblem"
VisualFX.Emblem.Size = UDim2.fromOffset(44, 44)
VisualFX.Emblem.Position = UDim2.new(1, -143, 0, 17)
VisualFX.Emblem.BackgroundColor3 = Color3.fromRGB(54, 57, 74)
VisualFX.Emblem.BackgroundTransparency = 0.12
VisualFX.Emblem.BorderSizePixel = 0
VisualFX.Emblem.ZIndex = 2
VisualFX.Emblem.Parent = Header
Corner(VisualFX.Emblem, 999)
VisualFX.EmblemStroke = Stroke(VisualFX.Emblem, Theme.Accent2, 1.6)
VisualFX.EmblemStroke.Transparency = 0.15
VisualFX.EmblemGradient = Gradient(VisualFX.Emblem, Theme.Accent, Theme.Panel2, 45)
VisualFX.EmblemGradient.Offset = Vector2.new(-1, 0)
VisualFX.Emblem.Active = true
VisualFX.Emblem.ClipsDescendants = true
VisualFX.EmblemScale = Instance.new("UIScale")
VisualFX.EmblemScale.Scale = 1
VisualFX.EmblemScale.Parent = VisualFX.Emblem

VisualFX.LogoShine = Instance.new("Frame")
VisualFX.LogoShine.Name = "LogoInteractionShine"
VisualFX.LogoShine.Size = UDim2.fromScale(1, 1)
VisualFX.LogoShine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
VisualFX.LogoShine.BackgroundTransparency = 0.91
VisualFX.LogoShine.BorderSizePixel = 0
VisualFX.LogoShine.ZIndex = 2
VisualFX.LogoShine.Parent = VisualFX.Emblem
VisualFX.LogoShineGradient = Instance.new("UIGradient")
VisualFX.LogoShineGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.5, 0.15),
    NumberSequenceKeypoint.new(1, 1)
})
VisualFX.LogoShineGradient.Offset = Vector2.new(-1, 0)
VisualFX.LogoShineGradient.Parent = VisualFX.LogoShine

local Decoration = Instance.new("TextLabel")
Decoration.Name = "MysticsMonogram"
Decoration.Size = UDim2.fromScale(1, 1)
Decoration.Position = UDim2.fromScale(0, 0)
Decoration.BackgroundTransparency = 1
Decoration.Text = "M"
Decoration.TextColor3 = Theme.Text
Decoration.Font = Enum.Font.GothamBlack
Decoration.TextSize = 23
Decoration.ZIndex = 3
Decoration.Parent = VisualFX.Emblem

TweenService:Create(VisualFX.Emblem,
    TweenInfo.new(4.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Position = UDim2.new(1, -143, 0, 13)}
):Play()
TweenService:Create(VisualFX.EmblemStroke,
    TweenInfo.new(3.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Transparency = 0.48}
):Play()
TweenService:Create(VisualFX.EmblemGradient,
    TweenInfo.new(6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1),
    {Offset = Vector2.new(1, 0)}
):Play()

VisualFX.Emblem.MouseEnter:Connect(function()
    TweenService:Create(VisualFX.EmblemScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1.10}):Play()
    TweenService:Create(VisualFX.EmblemStroke, TweenInfo.new(0.2), {Thickness = 2.2, Transparency = 0}):Play()
end)
VisualFX.Emblem.MouseLeave:Connect(function()
    TweenService:Create(VisualFX.EmblemScale, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
    TweenService:Create(VisualFX.EmblemStroke, TweenInfo.new(0.22), {Thickness = 1.6, Transparency = 0.15}):Play()
end)
VisualFX.Emblem.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    VisualFX.LogoShineGradient.Offset = Vector2.new(-1, 0)
    TweenService:Create(VisualFX.LogoShineGradient,
        TweenInfo.new(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Offset = Vector2.new(1, 0)}
    ):Play()
end)

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
TabBar.ZIndex = 3
TabBar.Parent = Main

VisualFX.TabShell = Instance.new("Frame")
VisualFX.TabShell.Name = "TabNavigationShell"
VisualFX.TabShell.Position = TabBar.Position
VisualFX.TabShell.Size = TabBar.Size
VisualFX.TabShell.BackgroundColor3 = Color3.fromRGB(88, 100, 121)
VisualFX.TabShell.BackgroundTransparency = 0
VisualFX.TabShell.BorderSizePixel = 0
VisualFX.TabShell.ZIndex = 2
VisualFX.TabShell.Parent = Main
Corner(VisualFX.TabShell, 12)
VisualFX.TabShellStroke = Stroke(VisualFX.TabShell, Theme.Border, 1)
VisualFX.TabShellStroke.Transparency = 0.33
VisualFX.TabShellGradient = Gradient(VisualFX.TabShell, VisualFX.GlassTop, VisualFX.GlassBottom, 90)
VisualFX.TabShellGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.04),
    NumberSequenceKeypoint.new(1, 0.20)
})

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 5)
TabLayout.Parent = TabBar

local PageContainer = Instance.new("Frame")
PageContainer.Name = "TabPages"
PageContainer.Position = UDim2.fromOffset(12, 145)
PageContainer.Size = UDim2.new(1, -24, 1, -157)
PageContainer.BackgroundTransparency = 1
PageContainer.ClipsDescendants = true
PageContainer.ZIndex = 8
PageContainer.Parent = Main

VisualFX.ContentShell = Instance.new("Frame")
VisualFX.ContentShell.Name = "ContentGlassShell"
VisualFX.ContentShell.Position = UDim2.fromOffset(12, 145)
VisualFX.ContentShell.Size = UDim2.new(1, -24, 1, -157)
VisualFX.ContentShell.BackgroundColor3 = Color3.fromRGB(82, 94, 115)
VisualFX.ContentShell.BackgroundTransparency = 0
VisualFX.ContentShell.BorderSizePixel = 0
VisualFX.ContentShell.ZIndex = 1
VisualFX.ContentShell.Parent = Main
Corner(VisualFX.ContentShell, 16)
VisualFX.ContentShellStroke = Stroke(VisualFX.ContentShell, Theme.Border, 1)
VisualFX.ContentShellStroke.Transparency = 0.38
VisualFX.ContentShellGradient = Gradient(VisualFX.ContentShell, VisualFX.GlassTop, VisualFX.GlassBottom, 90)
VisualFX.ContentShellGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.06),
    NumberSequenceKeypoint.new(0.58, 0.10),
    NumberSequenceKeypoint.new(1, 0.06)
})

VisualFX.ContentSheen = Instance.new("Frame")
VisualFX.ContentSheen.Name = "GlassTopHighlight"
VisualFX.ContentSheen.Position = UDim2.fromOffset(16, 13)
VisualFX.ContentSheen.Size = UDim2.new(1, -32, 0, 1)
VisualFX.ContentSheen.BackgroundColor3 = Color3.fromRGB(244, 248, 255)
VisualFX.ContentSheen.BackgroundTransparency = 0.83
VisualFX.ContentSheen.BorderSizePixel = 0
VisualFX.ContentSheen.ZIndex = 1
VisualFX.ContentSheen.Parent = VisualFX.ContentShell
VisualFX.ContentSheenGradient = Instance.new("UIGradient")
VisualFX.ContentSheenGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.22, 0.54),
    NumberSequenceKeypoint.new(0.78, 0.54),
    NumberSequenceKeypoint.new(1, 1)
})
VisualFX.ContentSheenGradient.Parent = VisualFX.ContentSheen

-- Subtle signature in spare space, behind the scrolling pages.
VisualFX.Watermark = Instance.new("TextLabel")
VisualFX.Watermark.Name = "MysticsContentWatermark"
VisualFX.Watermark.AnchorPoint = Vector2.new(0.5, 0.5)
VisualFX.Watermark.Position = UDim2.fromScale(0.5, 0.82)
VisualFX.Watermark.Size = UDim2.new(1, -24, 0, 98)
VisualFX.Watermark.BackgroundTransparency = 1
VisualFX.Watermark.Text = "M"
VisualFX.Watermark.Font = Enum.Font.GothamBlack
VisualFX.Watermark.TextSize = 86
VisualFX.Watermark.TextColor3 = Theme.Accent2
VisualFX.Watermark.TextTransparency = 0.94
VisualFX.Watermark.ZIndex = 2
VisualFX.Watermark.Parent = VisualFX.ContentShell

VisualFX.WatermarkCaption = Instance.new("TextLabel")
VisualFX.WatermarkCaption.Name = "MysticsSignatureCaption"
VisualFX.WatermarkCaption.AnchorPoint = Vector2.new(0.5, 1)
VisualFX.WatermarkCaption.Position = UDim2.new(0.5, 0, 1, -18)
VisualFX.WatermarkCaption.Size = UDim2.new(1, -30, 0, 16)
VisualFX.WatermarkCaption.BackgroundTransparency = 1
VisualFX.WatermarkCaption.Text = "M Y S T I C S    /    PREMIUM SUITE"
VisualFX.WatermarkCaption.Font = Enum.Font.GothamBold
VisualFX.WatermarkCaption.TextSize = 9
VisualFX.WatermarkCaption.TextColor3 = Theme.Accent2
VisualFX.WatermarkCaption.TextTransparency = 0.70
VisualFX.WatermarkCaption.ZIndex = 2
VisualFX.WatermarkCaption.Parent = VisualFX.ContentShell

VisualFX.ContentSweep = Instance.new("Frame")
VisualFX.ContentSweep.Name = "ContentAccentSweep"
VisualFX.ContentSweep.Position = UDim2.fromOffset(18, 8)
VisualFX.ContentSweep.Size = UDim2.new(1, -36, 0, 2)
VisualFX.ContentSweep.BackgroundColor3 = Theme.Accent2
VisualFX.ContentSweep.BackgroundTransparency = 0.12
VisualFX.ContentSweep.BorderSizePixel = 0
VisualFX.ContentSweep.ZIndex = 1
VisualFX.ContentSweep.Parent = VisualFX.ContentShell
Corner(VisualFX.ContentSweep, 2)
VisualFX.ContentSweepGradient = Instance.new("UIGradient")
VisualFX.ContentSweepGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.2, 0.38),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(0.8, 0.38),
    NumberSequenceKeypoint.new(1, 1)
})
VisualFX.ContentSweepGradient.Offset = Vector2.new(-1, 0)
VisualFX.ContentSweepGradient.Parent = VisualFX.ContentSweep
TweenService:Create(
    VisualFX.ContentSweepGradient,
    TweenInfo.new(6.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1),
    {Offset = Vector2.new(1, 0)}
):Play()

local Pages = {}
local TabButtons = {}
local CurrentPageName = "OVERVIEW"
local Content

local function CreatePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.ZIndex = 9
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Theme.Accent
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new()
    page.Visible = false
    page.Parent = PageContainer

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 15)
    padding.PaddingTop = UDim.new(0, 18)
    padding.PaddingBottom = UDim.new(0, 20)
    padding.Parent = page

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 13)
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
        button.BackgroundColor3 = selected and Theme.Panel2 or Theme.Panel
        button.TextColor3 = selected and Theme.Text or Theme.Muted
        local stroke = button:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Transparency = selected and 0.02 or 0.36
            stroke.Color = Theme.Border
        end
    end
    if VisualFX.SlideToTab then
        VisualFX.SlideToTab(name)
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
    tab.TextSize = 10
    tab.TextColor3 = Theme.Muted
    tab.ZIndex = 4
    tab.Parent = TabBar
    Corner(tab, 11)
    local tabScale = Instance.new("UIScale")
    tabScale.Scale = 1
    tabScale.Parent = tab
    tab.MouseEnter:Connect(function()
        TweenService:Create(tabScale, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1.035}):Play()
    end)
    tab.MouseLeave:Connect(function()
        TweenService:Create(tabScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
    end)
    local tabStroke = Stroke(tab, Theme.Border, 1)
    tabStroke.Transparency = 0.28
    TabButtons[definition.Name] = tab
    tab.Activated:Connect(function()
        PlayUISound(UI_CLICK_SOUND_ID, 0.20, 1)
        SelectPage(definition.Name)
    end)
end

-- A single sliding indicator stays in the DECORATIVE SHELL.
-- Never parent it inside TabBar, which has a UIListLayout.
VisualFX.TabSlider = Instance.new("Frame")
VisualFX.TabSlider.Name = "SharedSlidingTabIndicator"
VisualFX.TabSlider.Size = UDim2.fromOffset(45, 3)
VisualFX.TabSlider.Position = UDim2.fromOffset(36, 133)
VisualFX.TabSlider.BackgroundColor3 = Theme.Accent2
VisualFX.TabSlider.BorderSizePixel = 0
VisualFX.TabSlider.ZIndex = 5
VisualFX.TabSlider.Parent = Main
Corner(VisualFX.TabSlider, 3)
VisualFX.TabSliderStroke = Stroke(VisualFX.TabSlider, Theme.Accent2, 1)
VisualFX.TabSliderStroke.Transparency = 0.32

VisualFX.SlideToTab = function(name)
    local button = TabButtons[name]
    if not button or not button.Parent or not VisualFX.TabSlider.Parent then return end
    local offset = button.AbsolutePosition.X - Main.AbsolutePosition.X
        + (button.AbsoluteSize.X - 45) / 2
    if offset < 0 then return end
    TweenService:Create(
        VisualFX.TabSlider,
        TweenInfo.new(0.27, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Position = UDim2.fromOffset(math.floor(offset + 0.5), 133)}
    ):Play()
end
task.defer(function()
    if not Destroyed and VisualFX.TabSlider.Parent then
        VisualFX.SlideToTab(CurrentPageName)
    end
end)
-- Let the entrance UIScale complete before the final indicator alignment.
task.delay(0.85, function()
    if not Destroyed and VisualFX.TabSlider.Parent then
        VisualFX.SlideToTab(CurrentPageName)
    end
end)

SelectPage("OVERVIEW")

local function Label(text, height, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, height or 27)
    l.BackgroundColor3 = VisualFX.LabelBackground
    l.BackgroundTransparency = 0
    l.ZIndex = 10
    l:SetAttribute("MysticsGlassLabel", true)
    l.BorderSizePixel = 0
    l.Text = text
    l.TextColor3 = color or Theme.Text
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 13
    l.TextTransparency = 0
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.TextTruncate = Enum.TextTruncate.AtEnd
    l:SetAttribute("MysticsTextRole",
        color == Theme.Muted and "muted"
        or color == Theme.Accent2 and "accent"
        or color == Theme.Text and "main"
        or "custom")
    l.Parent = Content
    Corner(l, 10)
    local labelStroke = Stroke(l, Theme.Border, 1)
    labelStroke.Transparency = 0.35
    -- Hairline reflection creates subtle elevation without dark overlays.
    local reflection = Instance.new("Frame")
    reflection.Name = "GlassCardReflection"
    reflection.Position = UDim2.fromOffset(11, 2)
    reflection.Size = UDim2.new(1, -22, 0, 1)
    reflection.BackgroundColor3 = Color3.fromRGB(251, 253, 255)
    reflection.BackgroundTransparency = 0.73
    reflection.BorderSizePixel = 0
    reflection.ZIndex = 11
    reflection.Parent = l
    local reflectionFade = Instance.new("UIGradient")
    reflectionFade.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.78),
        NumberSequenceKeypoint.new(0.45, 0.05),
        NumberSequenceKeypoint.new(1, 1)
    })
    reflectionFade.Parent = reflection

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 11)
    padding.PaddingRight = UDim.new(0, 9)
    padding.Parent = l
    return l
end

local function Section(text)
    local holder = Instance.new("Frame")
    holder.Name = "SectionHeading"
    holder.Size = UDim2.new(1, 0, 0, 42)
    holder.BackgroundColor3 = Color3.fromRGB(73, 83, 103)
    holder.BackgroundTransparency = 0.02
    holder.BorderSizePixel = 0
    holder.ZIndex = 10
    holder.Parent = Content
    Corner(holder, 12)
    local headerOutline = Stroke(holder, Theme.Border, 1)
    headerOutline.Transparency = 0.62
    local softRule = Instance.new("Frame")
    softRule.Name = "SectionUpperReflection"
    softRule.Position = UDim2.fromOffset(13, 2)
    softRule.Size = UDim2.new(1, -26, 0, 1)
    softRule.BackgroundColor3 = Color3.fromRGB(250, 253, 255)
    softRule.BackgroundTransparency = 0.78
    softRule.BorderSizePixel = 0
    softRule.ZIndex = 11
    softRule.Parent = holder

    local accent = Instance.new("Frame")
    accent.Name = "AccentBar"
    accent.Size = UDim2.new(0, 4, 0, 17)
    accent.Position = UDim2.fromOffset(1, 6)
    accent.BackgroundColor3 = Theme.Accent2
    accent.BorderSizePixel = 0
    accent.ZIndex = 11
    accent.Parent = holder
    Corner(accent, 2)

    local l = Instance.new("TextLabel")
    l.Name = "SectionTitle"
    l.BackgroundTransparency = 1
    l.Position = UDim2.fromOffset(14, 0)
    l.Size = UDim2.new(1, -17, 0, 19)
    l.Text = string.upper(text)
    l.TextColor3 = Theme.Accent2
    l.Font = Enum.Font.GothamBold
    l.TextSize = 12
    l.TextTransparency = 0
    l.ZIndex = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = holder
    l:SetAttribute("MysticsTextRole", "accent")

    local caption = Instance.new("TextLabel")
    caption.Name = "SectionCaption"
    caption.BackgroundTransparency = 1
    caption.Position = UDim2.fromOffset(14, 17)
    caption.Size = UDim2.new(1, -17, 0, 10)
    caption.Font = Enum.Font.GothamMedium
    caption.Text = "MYSTICS  /  PREMIUM CONTROLS"
    caption.TextColor3 = Theme.Muted
    caption.TextSize = 10
    caption.ZIndex = 11
    caption.TextXAlignment = Enum.TextXAlignment.Left
    caption.Parent = holder
    caption:SetAttribute("MysticsTextRole", "muted")

    local line = Instance.new("Frame")
    line.Name = "SectionRule"
    line.AnchorPoint = Vector2.new(0, 0.5)
    line.Position = UDim2.new(0, 14, 1, -1)
    line.Size = UDim2.new(1, -17, 0, 1)
    line.BackgroundColor3 = Theme.Border
    line.BackgroundTransparency = 0.72
    line.BorderSizePixel = 0
    line.Parent = holder
    return holder
end

-- Semantic button roles separate important actions from toggles and utilities.
-- No child icon/rail overlays the actual button label.
VisualFX.StyleActionButton = function(button)
    local variant = button:GetAttribute("MysticsActionVariant") or "secondary"
    local stroke = button:FindFirstChildOfClass("UIStroke")
    local fill
    local border
    local alpha = 0.23
    if variant == "primary" then
        fill = Theme.Panel2:Lerp(Theme.Accent, Theme.Name == "BLOOD RED" and 0.60 or 0.30)
        border = Theme.Accent2
        alpha = 0.04
    elseif variant == "danger" then
        fill = Color3.fromRGB(135, 33, 47)
        border = Color3.fromRGB(255, 153, 161)
        alpha = 0.10
    elseif variant == "toggle" then
        fill = VisualFX.LabelBackground:Lerp(Theme.Accent, 0.17)
        border = Theme.Accent2
        alpha = 0.22
    elseif variant == "quiet" then
        fill = Theme.Background:Lerp(VisualFX.SecondaryBackground, 0.67)
        border = Theme.Border
        alpha = 0.52
    else
        fill = VisualFX.SecondaryBackground:Lerp(Color3.fromRGB(241, 236, 242), 0.10)
        border = Theme.Border
    end
    button.BackgroundColor3 = fill
    button.BackgroundTransparency = 0
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextTransparency = 0
    if stroke then
        stroke.Color = border
        stroke.Transparency = alpha
        stroke.Thickness = variant == "primary" and 1.7 or 1.25
    end
end

local function MakeButton(text, callback, color, variant)
    local kind = variant or "secondary"
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, (kind == "primary" and 58 or (kind == "danger" and 54 or 49)))
    b.BackgroundColor3 = VisualFX.SecondaryBackground
    b.BackgroundTransparency = 0
    b.BorderSizePixel = 0
    b.ZIndex = 10
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextTransparency = 0
    b.Font = Enum.Font.GothamBold
    b.TextSize = kind == "primary" and 15 or 13
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.AutoButtonColor = false
    b.Parent = Content
    b:SetAttribute("MysticsButtonTone", kind == "primary" and "primary" or "secondary")
    b:SetAttribute("MysticsActionVariant", kind)
    b:SetAttribute("MysticsGlassButton", true)

    Corner(b, 12)
    local buttonStroke = Stroke(b, Theme.Border, 1)
    VisualFX.StyleActionButton(b)
    -- No decorative rail over button labels: a child positioned inside a
    -- padded TextButton can render through the first letters.
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 15)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = b

    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = b
    local buttonReflection = Instance.new("Frame")
    buttonReflection.Name = "ActionTopReflection"
    buttonReflection.Position = UDim2.fromOffset(13, 2)
    buttonReflection.Size = UDim2.new(1, -26, 0, 1)
    buttonReflection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    buttonReflection.BackgroundTransparency = 0.80
    buttonReflection.BorderSizePixel = 0
    buttonReflection.ZIndex = 11
    buttonReflection.Parent = b

    b.MouseEnter:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 1.009}):Play()
        TweenService:Create(buttonStroke, TweenInfo.new(0.18), {Transparency = 0.02, Thickness = 1.45}):Play()
        TweenService:Create(buttonReflection, TweenInfo.new(0.18), {BackgroundTransparency = 0.32}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 1}):Play()
        local baseAlpha = kind == "primary" and 0.04 or (kind == "danger" and 0.10 or (kind == "quiet" and 0.52 or 0.23))
        TweenService:Create(buttonStroke, TweenInfo.new(0.18), {Transparency = baseAlpha, Thickness = kind == "primary" and 1.7 or 1.25}):Play()
        TweenService:Create(buttonReflection, TweenInfo.new(0.18), {BackgroundTransparency = 0.80}):Play()
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
    box.BackgroundColor3 = VisualFX.LabelBackground
    box.BackgroundTransparency = 0
    box.BorderSizePixel = 0
    box.ZIndex = 10
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.PlaceholderColor3 = Color3.fromRGB(233, 238, 246)
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

-- A compact, non-blocking in-menu toast stack. No platform notification
-- calls, no RenderStepped work, and at most three visible messages.
VisualFX.ToastHost = Instance.new("Frame")
VisualFX.ToastHost.Name = "MysticsToastHost"
VisualFX.ToastHost.AnchorPoint = Vector2.new(1, 0)
VisualFX.ToastHost.Position = UDim2.new(1, -18, 0, 18)
VisualFX.ToastHost.Size = UDim2.fromOffset(328, 440)
VisualFX.ToastHost.BackgroundTransparency = 1
VisualFX.ToastHost.BorderSizePixel = 0
VisualFX.ToastHost.ZIndex = 70
VisualFX.ToastHost.Parent = Gui
VisualFX.ToastLayout = Instance.new("UIListLayout")
VisualFX.ToastLayout.SortOrder = Enum.SortOrder.LayoutOrder
VisualFX.ToastLayout.Padding = UDim.new(0, 8)
VisualFX.ToastLayout.Parent = VisualFX.ToastHost
VisualFX.ToastItems = {}
VisualFX.ToastSequence = 0

local function Notify(message)
    if Destroyed or not VisualFX.ToastHost.Parent then return end
    message = tostring(message or "")
    if message == "" then return end

    while #VisualFX.ToastItems >= 3 do
        local oldest = table.remove(VisualFX.ToastItems, 1)
        if oldest then oldest:Destroy() end
    end

    VisualFX.ToastSequence = VisualFX.ToastSequence - 1
    local low = string.lower(message)
    local warning = low:find("error", 1, true) or low:find("failed", 1, true)
        or low:find("not found", 1, true) or low:find("stop", 1, true)
    local success = low:find("saved", 1, true) or low:find("loaded", 1, true)
        or low:find("enabled", 1, true) or low:find("reset", 1, true)
    local accent = warning and Color3.fromRGB(255, 148, 155)
        or (success and Color3.fromRGB(171, 242, 193) or Theme.Accent2)
    local titleText = warning and "SYSTEM NOTICE" or (success and "ACTION CONFIRMED" or "MYSTICS")
    local tall = message:find("\n") and 126 or (string.len(message) > 90 and 90 or 72)

    local wrapper = Instance.new("Frame")
    wrapper.Name = "ToastSlot"
    wrapper.Size = UDim2.new(1, 0, 0, tall)
    wrapper.BackgroundTransparency = 1
    wrapper.LayoutOrder = VisualFX.ToastSequence
    wrapper.ZIndex = 70
    wrapper.Parent = VisualFX.ToastHost
    table.insert(VisualFX.ToastItems, wrapper)

    local toast = Instance.new("Frame")
    toast.Name = "PremiumToast"
    toast.Size = UDim2.fromScale(1, 1)
    toast.Position = UDim2.fromOffset(45, 0)
    toast.BackgroundColor3 = Color3.fromRGB(43, 47, 61)
    toast.BackgroundTransparency = 0.08
    toast.BorderSizePixel = 0
    toast.ZIndex = 71
    toast.Parent = wrapper
    Corner(toast, 12)
    local stroke = Stroke(toast, accent, 1.25)
    stroke.Transparency = 0.2

    local headline = Instance.new("TextLabel")
    headline.Name = "ToastHeadline"
    headline.BackgroundTransparency = 1
    headline.Position = UDim2.fromOffset(14, 9)
    headline.Size = UDim2.new(1, -28, 0, 14)
    headline.Font = Enum.Font.GothamBold
    headline.TextSize = 10
    headline.Text = titleText
    headline.TextColor3 = accent
    headline.TextXAlignment = Enum.TextXAlignment.Left
    headline.ZIndex = 72
    headline.Parent = toast

    local content = Instance.new("TextLabel")
    content.Name = "ToastContent"
    content.BackgroundTransparency = 1
    content.Position = UDim2.fromOffset(14, 25)
    content.Size = UDim2.new(1, -28, 1, -34)
    content.Font = Enum.Font.GothamMedium
    content.TextSize = 11
    content.Text = string.sub(message, 1, 290)
    content.TextWrapped = true
    content.TextColor3 = Color3.fromRGB(250, 250, 255)
    content.TextXAlignment = Enum.TextXAlignment.Left
    content.TextYAlignment = Enum.TextYAlignment.Top
    content.ZIndex = 72
    content.Parent = toast

    local lifespan = 4.2
    local progress = Instance.new("Frame")
    progress.Name = "ToastProgress"
    progress.Position = UDim2.new(0, 13, 1, -5)
    progress.Size = UDim2.new(1, -26, 0, 2)
    progress.BackgroundColor3 = accent
    progress.BorderSizePixel = 0
    progress.ZIndex = 72
    progress.Parent = toast
    Corner(progress, 2)
    TweenService:Create(toast,
        TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Position = UDim2.fromOffset(0, 0)}
    ):Play()
    TweenService:Create(progress,
        TweenInfo.new(lifespan, Enum.EasingStyle.Linear),
        {Size = UDim2.new(0, 0, 0, 2)}
    ):Play()

    task.delay(lifespan, function()
        if Destroyed or not wrapper.Parent then return end
        TweenService:Create(toast,
            TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.fromOffset(45, 0), BackgroundTransparency = 1}
        ):Play()
        task.delay(0.24, function()
            for i, item in ipairs(VisualFX.ToastItems) do
                if item == wrapper then
                    table.remove(VisualFX.ToastItems, i)
                    break
                end
            end
            if wrapper.Parent then wrapper:Destroy() end
        end)
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
local AntiAfkStatus = Label("PREVENT IDLE DISCONNECTS", 22, Theme.Muted)
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
        AntiAfkButton.Text = AntiAfkEnabled and "IDLE GUARD: ON" or "IDLE GUARD: OFF"
    end
    AntiAfkStatus.Text = "PREVENT IDLE DISCONNECTS"
    AntiAfkStatus.TextColor3 = Theme.Muted
end

AntiAfkButton = MakeButton("IDLE GUARD: OFF", function()
    SetAntiAfkEnabled(not AntiAfkEnabled)
    Notify(AntiAfkEnabled and "Anti-AFK enabled." or "Anti-AFK disabled.")
end, nil, "toggle")

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
StatsDashboard.BackgroundColor3 = Color3.fromRGB(85, 97, 119)
StatsDashboard.BackgroundTransparency = 0
StatsDashboard.BorderSizePixel = 0
StatsDashboard.Parent = Content
Corner(StatsDashboard, 11)
local dashboardStroke = Stroke(StatsDashboard, Theme.Border, 1)
dashboardStroke.Transparency = 0.20

local dashboardGrid = Instance.new("UIGridLayout")
dashboardGrid.CellSize = UDim2.new(0.5, -6, 0, 43)
dashboardGrid.CellPadding = UDim2.fromOffset(8, 6)
dashboardGrid.SortOrder = Enum.SortOrder.LayoutOrder
dashboardGrid.Parent = StatsDashboard

local function DashboardCard(order, caption, initial, accentColor)
    local card = Instance.new("Frame")
    card.Name = caption:gsub("%W", "") .. "Card"
    card.LayoutOrder = order
    card.BackgroundColor3 = Color3.fromRGB(97, 110, 131)
    card.BackgroundTransparency = 0
    card.BorderSizePixel = 0
    card.Parent = StatsDashboard
    Corner(card, 10)
    local cardStroke = Stroke(card, Theme.Border, 1)
    cardStroke.Transparency = 0.20
    local cardScale = Instance.new("UIScale")
    cardScale.Scale = 1
    cardScale.Parent = card
    card.Active = true
    card.MouseEnter:Connect(function()
        TweenService:Create(cardScale,
            TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Scale = 1.018}
        ):Play()
        TweenService:Create(cardStroke, TweenInfo.new(0.16), {Transparency = 0.02}):Play()
    end)
    card.MouseLeave:Connect(function()
        TweenService:Create(cardScale,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Scale = 1}
        ):Play()
        TweenService:Create(cardStroke, TweenInfo.new(0.18), {Transparency = 0.20}):Play()
    end)
    local cardGradient = Gradient(card, VisualFX.CardTop, VisualFX.CardBottom, 90)
    cardGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.04),
        NumberSequenceKeypoint.new(1, 0.18)
    })
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
    title.TextSize = 10
    title.TextColor3 = Color3.fromRGB(245, 247, 255)
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
    local valueScale = Instance.new("UIScale")
    valueScale.Name = "StatChangeScale"
    valueScale.Scale = 1
    valueScale.Parent = value
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
    popup.BackgroundTransparency = 0.015
    popup.BorderSizePixel = 0
    popup.ClipsDescendants = true
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

    local popupSheen = Instance.new("Frame")
    popupSheen.Name = "PopupGlassSheen"
    popupSheen.Position = UDim2.fromOffset(1, 1)
    popupSheen.Size = UDim2.new(1, -2, 0, 56)
    popupSheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    popupSheen.BackgroundTransparency = 0.94
    popupSheen.BorderSizePixel = 0
    popupSheen.ZIndex = 100
    popupSheen.Parent = popup
    local popupSheenGradient = Instance.new("UIGradient")
    popupSheenGradient.Rotation = 90
    popupSheenGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.12),
        NumberSequenceKeypoint.new(1, 1)
    })
    popupSheenGradient.Parent = popupSheen
    local popupSheenCorner = Instance.new("UICorner")
    popupSheenCorner.CornerRadius = UDim.new(0, 16)
    popupSheenCorner.Parent = popupSheen

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
-- Animate meaningful changes only; each active count-up is short-lived.
-- Kept separate from reward calculations so rarity/value logic is untouched.
VisualFX.StatAnimations = {}
VisualFX.AnimateStat = function(label, targetText)
    if Destroyed or not label or not label.Parent then return end
    if label.Text == targetText then return end
    local previous = VisualFX.StatAnimations[label]
    if previous and previous.target == targetText then return end
    if previous then
        if previous.tween then previous.tween:Cancel() end
        if previous.conn then previous.conn:Disconnect() end
        if previous.value then previous.value:Destroy() end
        VisualFX.StatAnimations[label] = nil
    end

    local scale = label:FindFirstChild("StatChangeScale")
    if scale then
        TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {Scale = 1.07}):Play()
        task.delay(0.18, function()
            if scale.Parent then
                TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Scale = 1}):Play()
            end
        end)
    end

    local number = tonumber(targetText:match("^[%d%.]+"))
    if not number then
        label.Text = targetText
        return
    end
    local origin = tonumber(label.Text:match("^[%d%.]+")) or number
    local fraction = targetText:match("%.(%d+)")
    local digits = fraction and #fraction or 0
    local suffix = targetText:match("%%$") and "%" or ""
    local value = Instance.new("NumberValue")
    value.Value = origin
    local record = {value = value, target = targetText}
    VisualFX.StatAnimations[label] = record
    record.conn = value:GetPropertyChangedSignal("Value"):Connect(function()
        if not label.Parent or VisualFX.StatAnimations[label] ~= record then return end
        label.Text = string.format("%." .. tostring(digits) .. "f", value.Value) .. suffix
    end)
    record.tween = TweenService:Create(
        value, TweenInfo.new(0.48, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Value = number}
    )
    record.tween.Completed:Connect(function()
        if record.conn then record.conn:Disconnect() end
        if VisualFX.StatAnimations[label] == record then
            label.Text = targetText
            VisualFX.StatAnimations[label] = nil
        end
        value:Destroy()
    end)
    record.tween:Play()
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
    VisualFX.AnimateStat(DashItems, tostring(total))
    VisualFX.AnimateStat(DashCycles, tostring(CompletedCycles))
    VisualFX.AnimateStat(DashImportRate, string.format("%.1f%%", importPlusRate))
    VisualFX.AnimateStat(DashEstValue, string.format("%.2f", estimate))
    VisualFX.AnimateStat(DashBestRarity, BestRarityName)
    VisualFX.AnimateStat(DashCratesPerMin, string.format("%.1f", CompletedCycles / (elapsed / 60)))

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
Section("TIMING & LIMITS")

local ModeButton

ModeButton = MakeButton("UNBOX MODE: SMART", function()
    if Mode == "SMART" then
        Mode = "TIMED"
    elseif Mode == "TIMED" then
        Mode = "HYBRID"
    else
        Mode = "SMART"
    end

    ModeButton.Text = "UNBOX MODE: " .. Mode
end, nil, "toggle")

Label("CLICK DELAY (0.5–30 SECONDS)", 20, Theme.Muted)
local DelayInput = MakeInput("Seconds", "2")

Label("MAX CASES (0 = UNLIMITED)", 20, Theme.Muted)
local MaxInput = MakeInput("Case limit", "0")

Label("EXTRA RANDOM DELAY (SECONDS)", 20, Theme.Muted)
local RandomInput = MakeInput("Extra seconds", "0")

local RandomButton

RandomButton = MakeButton("RANDOMIZE TIMING: OFF", function()
    RandomEnabled = not RandomEnabled

    RandomButton.Text = RandomEnabled
        and "RANDOMIZE TIMING: ON"
        or "RANDOMIZE TIMING: OFF"
end, nil, "toggle")

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

Section("SESSION ACTIONS")

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
    PauseButton.Text = "PAUSE RUN"

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
        PauseButton.Text = "PAUSE RUN"
    end

    Notify("Mystics automation stopped.")
end

MakeButton("START UNBOXING", Start, nil, "primary")

PauseButton = MakeButton("PAUSE RUN", function()
    if not Running then return end

    Paused = not Paused

    if not Paused then
        GameCheckPaused = false
    end

    PauseButton.Text = Paused
        and "RESUME RUN"
        or "PAUSE RUN"

    Status.Text = Paused
        and "●  PAUSED"
        or "●  RUNNING"
end)

MakeButton("STOP SESSION", Stop, Theme.Panel2, "danger")

--========================================================
-- APPEARANCE & PROFILES TAB
--========================================================

SelectPage("APPEARANCE")
-- One theme gallery below replaces the old duplicate theme controls.
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
            local duration = isPumpkin and math.random(7, 11) or (isObsidian and math.random(5, 9) or math.random(6, 11))
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
            task.wait(isPumpkin and 0.85 or (isObsidian and 0.75 or 0.62))
        end
    end)
end

local function ApplyTheme()
    Theme = Themes[ThemeIndex]
    StartThemeAtmosphere()
    Subtitle.Text = Theme.Tag

    -- Blood Red uses luminous crimson glass, not the neutral slate shared
    -- by the other themes. Keep white lettering for contrast.
    if Theme.Name == "BLOOD RED" then
        VisualFX.GlassTop = Color3.fromRGB(132, 43, 68)
        VisualFX.GlassBottom = Color3.fromRGB(88, 20, 40)
        VisualFX.CardTop = Color3.fromRGB(146, 55, 80)
        VisualFX.CardBottom = Color3.fromRGB(104, 28, 50)
        VisualFX.LabelBackground = Color3.fromRGB(122, 39, 62)
        VisualFX.SecondaryBackground = Color3.fromRGB(128, 33, 56)
        VisualFX.SectionBackground = Color3.fromRGB(102, 26, 48)
        VisualFX.DashboardBackground = Color3.fromRGB(92, 23, 43)
        VisualFX.StatCardBackground = Color3.fromRGB(114, 31, 54)
    else
        VisualFX.GlassTop = Color3.fromRGB(104, 118, 141)
        VisualFX.GlassBottom = Color3.fromRGB(79, 91, 112)
        VisualFX.CardTop = Color3.fromRGB(115, 128, 148)
        VisualFX.CardBottom = Color3.fromRGB(94, 108, 131)
        VisualFX.LabelBackground = Color3.fromRGB(104, 116, 137)
        VisualFX.SecondaryBackground = Color3.fromRGB(105, 117, 139)
        VisualFX.SectionBackground = Color3.fromRGB(73, 83, 103)
        VisualFX.DashboardBackground = Color3.fromRGB(85, 97, 119)
        VisualFX.StatCardBackground = Color3.fromRGB(97, 110, 131)
    end

    Main.BackgroundColor3 = Theme.Background
    Header.BackgroundColor3 = Theme.Panel
    VisualFX.MainAura.BackgroundColor3 = Theme.Accent2
    VisualFX.HeaderRule.BackgroundColor3 = Theme.Accent2
    VisualFX.TabShell.BackgroundColor3 = Theme.Name == "BLOOD RED"
        and Color3.fromRGB(96, 24, 48) or Color3.fromRGB(88, 100, 121)
    VisualFX.ContentShell.BackgroundColor3 = Theme.Name == "BLOOD RED"
        and Color3.fromRGB(82, 18, 39) or Color3.fromRGB(82, 94, 115)
    VisualFX.ContentSweep.BackgroundColor3 = Theme.Accent2
    VisualFX.EmblemStroke.Color = Theme.Accent2
    VisualFX.EmblemGradient.Color = ColorSequence.new(Theme.Accent, Theme.Panel2)

    Title.TextColor3 = Theme.Text
    Subtitle.TextColor3 = Theme.Muted
    Creator.TextColor3 = Theme.Accent2
    Decoration.Text = "M"
    Decoration.TextColor3 = Theme.Accent2

    MainStroke.Color = Theme.Border
    MainGradient.Color = Theme.Name == "BLOOD RED"
        and ColorSequence.new(
            Color3.fromRGB(102, 22, 46),
            Color3.fromRGB(42, 9, 22)
        )
        or ColorSequence.new(
            Theme.Panel:Lerp(Color3.fromRGB(62, 72, 91), 0.58),
            Theme.Background:Lerp(Color3.fromRGB(52, 60, 80), 0.72)
        )

    HeaderGradient.Color = ColorSequence.new(
        Theme.Panel2,
        Theme.Panel
    )

    if SoundButton then
        SoundButton.Text = UISoundsEnabled and "SOUND EFFECTS: ON" or "SOUND EFFECTS: OFF"
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
            obj.BackgroundColor3 = VisualFX.LabelBackground
            obj.TextColor3 = Color3.fromRGB(255, 255, 255)
            obj.TextTransparency = 0
            obj.PlaceholderColor3 = Color3.fromRGB(233, 238, 246)

        elseif obj:IsA("TextButton") then
            if obj == MinButton then
                obj.BackgroundColor3 = Theme.Panel2
            elseif obj:GetAttribute("MysticsGlassButton") then
                -- Action palette is restored after generic UIStroke updates.
                VisualFX.StyleActionButton(obj)
            end
        elseif obj:IsA("Frame") and obj.Name == "SectionHeading" then
            obj.BackgroundColor3 = VisualFX.SectionBackground
        elseif obj:IsA("Frame") and obj.Name == "LiveStatisticsDashboard" then
            obj.BackgroundColor3 = VisualFX.DashboardBackground
        elseif obj:IsA("Frame") and obj.Parent == StatsDashboard then
            obj.BackgroundColor3 = VisualFX.StatCardBackground
            local glassGradient = obj:FindFirstChildOfClass("UIGradient")
            if glassGradient then
                glassGradient.Color = ColorSequence.new(VisualFX.CardTop, VisualFX.CardBottom)
            end
        elseif obj:IsA("Frame") and obj.Name == "AccentBar" then
            obj.BackgroundColor3 = Theme.Accent2
        elseif obj:IsA("Frame") and obj.Name == "SectionRule" then
            obj.BackgroundColor3 = Theme.Border
        elseif obj:IsA("TextLabel") and obj.Name == "SectionTitle" then
            obj.TextColor3 = Theme.Accent2
        end

        if obj:IsA("TextLabel") and obj:GetAttribute("MysticsTextRole") then
            if obj:GetAttribute("MysticsGlassLabel") then
                obj.BackgroundColor3 = VisualFX.LabelBackground
                obj.TextTransparency = 0
            elseif obj.BackgroundTransparency < 1 then
                obj.BackgroundColor3 = Theme.Panel
            end
        end
        if obj:IsA("UIStroke") and obj ~= MainStroke then
            obj.Color = Theme.Border
        end

        -- Do not recolour every gradient: doing so tinted panel surfaces
        -- and even text-bearing buttons. Named accents update below instead.
    end

    for _, page in pairs(Pages) do
        page.ScrollBarImageColor3 = Theme.Accent
    end
    for _, obj in ipairs(Gui:GetDescendants()) do
        if obj:IsA("TextButton") and obj:GetAttribute("MysticsGlassButton") then
            VisualFX.StyleActionButton(obj)
        end
    end
    -- ApplyTheme's shared stroke pass runs above; restore the emblem accent last.
    VisualFX.EmblemStroke.Color = Theme.Accent2
    VisualFX.BorderSweep.Color = ColorSequence.new(Theme.Accent2, Theme.Border)
    VisualFX.Watermark.TextColor3 = Theme.Accent2
    VisualFX.WatermarkCaption.TextColor3 = Theme.Accent2
    VisualFX.TabSlider.BackgroundColor3 = Theme.Accent2
    VisualFX.TabSliderStroke.Color = Theme.Accent2
    VisualFX.MainAuraGradient.Color = ColorSequence.new(Theme.Accent2, Theme.Background)
    VisualFX.HeaderRuleGradient.Color = ColorSequence.new(Theme.Accent2, Theme.Border)
    VisualFX.TabShellGradient.Color = ColorSequence.new(VisualFX.GlassTop, VisualFX.GlassBottom)
    VisualFX.ContentShellGradient.Color = ColorSequence.new(VisualFX.GlassTop, VisualFX.GlassBottom)

    -- Keep previews individually coloured while highlighting only the active
    -- selection. Refresh after the shared theme-styling pass above.
    for i, info in ipairs(VisualFX.ThemeCards or {}) do
        local selected = (i == ThemeIndex)
        info.Stroke.Color = selected and Theme.Accent2 or info.Preset.Border
        info.Stroke.Transparency = selected and 0.02 or 0.46
        info.Stroke.Thickness = selected and 2 or 1
        info.Button.BackgroundColor3 = info.Preset.Panel2
        info.Chip.Text = selected and "SELECTED" or "APPLY"
        info.Chip.TextColor3 = selected and Theme.Accent2 or info.Preset.Muted
        info.Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    SelectPage(CurrentPageName)
end

-- Theme selection lives in the gallery; no duplicate cycle button.
Section("CHOOSE YOUR SIGNATURE THEME")
VisualFX.ThemeCards = {}
VisualFX.ThemeGallery = Instance.new("Frame")
VisualFX.ThemeGallery.Name = "PremiumThemeGallery"
VisualFX.ThemeGallery.Size = UDim2.new(1, 0, 0, 180)
VisualFX.ThemeGallery.BackgroundTransparency = 1
VisualFX.ThemeGallery.BorderSizePixel = 0
VisualFX.ThemeGallery.ZIndex = 10
VisualFX.ThemeGallery.Parent = Content
VisualFX.ThemeGalleryLayout = Instance.new("UIGridLayout")
VisualFX.ThemeGalleryLayout.CellSize = UDim2.new(0.5, -6, 0, 86)
VisualFX.ThemeGalleryLayout.CellPadding = UDim2.fromOffset(10, 8)
VisualFX.ThemeGalleryLayout.SortOrder = Enum.SortOrder.LayoutOrder
VisualFX.ThemeGalleryLayout.Parent = VisualFX.ThemeGallery

for index, preset in ipairs(Themes) do
    local choice = index
    local card = Instance.new("TextButton")
    card.Name = "ThemePreview" .. tostring(index)
    card.LayoutOrder = index
    card.Size = UDim2.new(0.5, -6, 0, 86)
    card.BackgroundColor3 = preset.Panel2
    card.BackgroundTransparency = 0.09
    card.BorderSizePixel = 0
    card.Text = ""
    card.ZIndex = 10
    card.AutoButtonColor = false
    card.Parent = VisualFX.ThemeGallery
    Corner(card, 13)
    local outline = Stroke(card, preset.Border, 1)
    outline.Transparency = 0.46
    local zoom = Instance.new("UIScale")
    zoom.Parent = card

    local swatch = Instance.new("Frame")
    swatch.Name = "ThemeSwatch"
    swatch.Position = UDim2.fromOffset(10, 10)
    swatch.Size = UDim2.fromOffset(41, 51)
    swatch.BackgroundColor3 = preset.Panel
    swatch.BorderSizePixel = 0
    swatch.ZIndex = 11
    swatch.Parent = card
    Corner(swatch, 9)
    Gradient(swatch, preset.Panel2, preset.Background, 55)
    local swatchStroke = Stroke(swatch, preset.Accent2, 1)
    swatchStroke.Transparency = 0.24

    local swatchDot = Instance.new("Frame")
    swatchDot.Size = UDim2.fromOffset(17, 17)
    swatchDot.AnchorPoint = Vector2.new(0.5, 0.5)
    swatchDot.Position = UDim2.fromScale(0.5, 0.5)
    swatchDot.BackgroundColor3 = preset.Accent
    swatchDot.BorderSizePixel = 0
    swatchDot.ZIndex = 12
    swatchDot.Parent = swatch
    Corner(swatchDot, 99)

    local name = Instance.new("TextLabel")
    name.Name = "ThemeName"
    name.BackgroundTransparency = 1
    name.Position = UDim2.fromOffset(60, 10)
    name.Size = UDim2.new(1, -68, 0, 29)
    name.Font = Enum.Font.GothamBold
    name.Text = preset.Name
    name.TextSize = 11
    name.TextWrapped = true
    name.TextColor3 = Color3.fromRGB(255, 255, 255)
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.ZIndex = 11
    name.Parent = card

    local chip = Instance.new("TextLabel")
    chip.Name = "SelectionStatus"
    chip.BackgroundTransparency = 1
    chip.Position = UDim2.fromOffset(60, 47)
    chip.Size = UDim2.new(1, -68, 0, 16)
    chip.Font = Enum.Font.GothamBold
    chip.Text = "APPLY"
    chip.TextSize = 9
    chip.TextColor3 = preset.Muted
    chip.TextXAlignment = Enum.TextXAlignment.Left
    chip.ZIndex = 11
    chip.Parent = card
    VisualFX.ThemeCards[index] = {
        Button = card, Stroke = outline, Label = name,
        Chip = chip, Preset = preset
    }
    card.MouseEnter:Connect(function()
        TweenService:Create(zoom, TweenInfo.new(0.16, Enum.EasingStyle.Quad), {Scale = 1.025}):Play()
    end)
    card.MouseLeave:Connect(function()
        TweenService:Create(zoom, TweenInfo.new(0.16, Enum.EasingStyle.Quad), {Scale = 1}):Play()
    end)
    card.Activated:Connect(function()
        ThemeIndex = choice
        ApplyTheme()
        Notify("Theme selected: " .. Themes[choice].Name)
    end)
end

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
end, nil, "primary")

MakeButton("APPLY PROFILE", function()
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

    ModeButton.Text = "UNBOX MODE: " .. Mode
    ApplyTheme()

    Notify("Profile loaded.")
end)

-- Session history and reset belong to performance, not theme selection.
SelectPage("PERFORMANCE")
Section("SESSION TOOLS")
MakeButton("SESSION HISTORY", function()
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
end, nil, "quiet")

MakeButton("CLEAR SESSION STATS", function()
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
end, Theme.Panel2, "quiet")

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
        local target = UDim2.fromOffset(448, 94)
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
        Main.Size = UDim2.fromOffset(448, 94)
        MenuSizeTween = TweenService:Create(
            Main,
            TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = UDim2.fromOffset(448, 700)}
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
    pcall(function() if VisualFX.BorderSweepTween then VisualFX.BorderSweepTween:Cancel() end end)
    -- Stat count-up values are not parented to the GUI, so dispose of them
    -- explicitly when exiting or relaunching.
    for label, record in pairs(VisualFX.StatAnimations or {}) do
        if record.tween then pcall(function() record.tween:Cancel() end) end
        if record.conn then record.conn:Disconnect() end
        if record.value then record.value:Destroy() end
        VisualFX.StatAnimations[label] = nil
    end
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

-- Audio preference stays on STYLE, never in the HOME session readout.
SelectPage("APPEARANCE")
Section("PREFERENCES")
SoundButton = MakeButton("SOUND EFFECTS: ON", function()
    UISoundsEnabled = not UISoundsEnabled
    SoundButton.Text = UISoundsEnabled and "SOUND EFFECTS: ON" or "SOUND EFFECTS: OFF"
    if UISoundsEnabled then
        PlayUISound(UI_CONFIRM_SOUND_ID, 0.22, 1.04)
    end
end, Theme.Panel2, "toggle")

SelectPage("OVERVIEW")
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

