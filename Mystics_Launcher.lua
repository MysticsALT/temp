--========================================================
-- MYSTICS HUB | V3.0 PREMIUM LAUNCHER
-- Startup creates only this hub. Experience code is not loaded here.
-- RL Crate Unboxing is fetched from a pinned GitHub commit only on click.
--========================================================

if getgenv and getgenv().MysticsCleanup then
    pcall(getgenv().MysticsCleanup)
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local HubParent = PlayerGui
pcall(function()
    if gethui then
        HubParent = gethui()
    end
end)

-- Clear previous versions from both supported GUI roots when relaunching.
-- This avoids showing the old launcher if an earlier session used another root.
for _, parent in ipairs({PlayerGui, HubParent}) do
    local previousHub = parent:FindFirstChild("MysticsHub_Main")
    if previousHub then previousHub:Destroy() end
end

local HubGui = Instance.new("ScreenGui")
HubGui.Name = "MysticsHub_Main"
HubGui.ResetOnSpawn = false
HubGui.IgnoreGuiInset = true
HubGui.DisplayOrder = 1000000
HubGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
HubGui.Parent = HubParent

-- Launcher audio (uses the same UI sound set as the crate GUI).
local HUB_CLICK_SOUND_ID = "rbxassetid://6895079853"
local HUB_OPEN_SOUND_ID = "rbxassetid://6026984224"
local HUB_CLOSE_SOUND_ID = "rbxassetid://6026984224"
local HubSoundsEnabled = true
local HubClosing = false
local HubLaunching = false
local HubUnlocked = false
local HubVisual = {}

local function PlayHubSound(soundId, volume, speed)
    if not HubSoundsEnabled then return end
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = volume or 0.3
        sound.PlaybackSpeed = speed or 1
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

local function AddCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = object
    return corner
end

local function AddStroke(object, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.Parent = object
    return stroke
end

local function AddGradient(object, colorA, colorB, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, colorA),
        ColorSequenceKeypoint.new(1, colorB)
    })
    gradient.Rotation = rotation or 0
    gradient.Parent = object
    return gradient
end

local Background = Instance.new("Frame")
Background.Name = "Background"
Background.AnchorPoint = Vector2.new(0.5, 0.5)
Background.Position = UDim2.fromScale(0.5, 0.5)
Background.Size = UDim2.new(0, 448, 0, 550)
Background.BackgroundColor3 = Color3.fromRGB(24, 8, 15)
Background.BorderSizePixel = 0
Background.ClipsDescendants = true
Background.Parent = HubGui
AddCorner(Background, 24)
HubVisual.Stroke = AddStroke(Background, Color3.fromRGB(155, 48, 72), 1.6, 0.04)
HubVisual.Gradient = AddGradient(Background, Color3.fromRGB(67, 17, 33), Color3.fromRGB(28, 9, 19), 90)

HubVisual.Ambient = Instance.new("Frame")
HubVisual.Ambient.Name = "HubAmbient"
HubVisual.Ambient.Size = UDim2.fromScale(1, 1)
HubVisual.Ambient.BackgroundTransparency = 1
HubVisual.Ambient.BorderSizePixel = 0
HubVisual.Ambient.ClipsDescendants = true
HubVisual.Ambient.ZIndex = 1
HubVisual.Ambient.Parent = Background

HubVisual.TopAura = Instance.new("Frame")
HubVisual.TopAura.Name = "RubyTopAura"
HubVisual.TopAura.Position = UDim2.new(0, -18, 0, -28)
HubVisual.TopAura.Size = UDim2.new(1, 36, 0, 150)
HubVisual.TopAura.BackgroundColor3 = Color3.fromRGB(225, 55, 94)
HubVisual.TopAura.BackgroundTransparency = 0.79
HubVisual.TopAura.BorderSizePixel = 0
HubVisual.TopAura.ZIndex = 1
HubVisual.TopAura.Parent = HubVisual.Ambient
AddCorner(HubVisual.TopAura, 36)
HubVisual.TopAuraGradient = Instance.new("UIGradient")
HubVisual.TopAuraGradient.Rotation = 90
HubVisual.TopAuraGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.12),
    NumberSequenceKeypoint.new(0.58, 0.72),
    NumberSequenceKeypoint.new(1, 1)
})
HubVisual.TopAuraGradient.Parent = HubVisual.TopAura

for i = 1, 8 do
    local particle = Instance.new("Frame")
    particle.Name = "RubyParticle" .. i
    particle.Size = UDim2.fromOffset(i % 3 == 0 and 4 or 3, i % 3 == 0 and 4 or 3)
    particle.Position = UDim2.new(0.08 + ((i * 13) % 82) / 100, 0, 0.10 + ((i * 17) % 78) / 100, 0)
    particle.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(255, 180, 195) or Color3.fromRGB(190, 55, 83)
    particle.BackgroundTransparency = 0.58
    particle.BorderSizePixel = 0
    particle.ZIndex = 1
    particle.Parent = HubVisual.Ambient
    AddCorner(particle, 99)
    TweenService:Create(
        particle,
        TweenInfo.new(3.2 + i * 0.28, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {
            Position = particle.Position + UDim2.new(0, 0, i % 2 == 0 and -0.018 or 0.016, 0),
            BackgroundTransparency = 0.9
        }
    ):Play()
end

HubVisual.BorderPulse = TweenService:Create(
    HubVisual.Stroke,
    TweenInfo.new(3.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Transparency = 0.32, Thickness = 2}
)
HubVisual.BorderPulse:Play()

local Scale = Instance.new("UIScale")
Scale.Scale = 0.90
Scale.Parent = Background

local HubTargetPosition = Background.Position
Background.Position = UDim2.new(
    HubTargetPosition.X.Scale, HubTargetPosition.X.Offset,
    HubTargetPosition.Y.Scale, HubTargetPosition.Y.Offset + 22
)
Background.BackgroundTransparency = 1

local HubOpenTween = TweenService:Create(
    Scale,
    TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    {Scale = 1}
)
local HubPositionTween = TweenService:Create(
    Background,
    TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    {Position = HubTargetPosition, BackgroundTransparency = 0}
)

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 150)
Header.BackgroundColor3 = Color3.fromRGB(91, 22, 43)
Header.BorderSizePixel = 0
Header.Parent = Background
AddCorner(Header, 18)
AddGradient(Header, Color3.fromRGB(151, 31, 63), Color3.fromRGB(65, 16, 34), 0)
Header.BackgroundTransparency = 1
local HubHeaderTween = TweenService:Create(
    Header,
    TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    {BackgroundTransparency = 0}
)

local HeaderCover = Instance.new("Frame")
HeaderCover.Position = UDim2.new(0, 0, 1, -18)
HeaderCover.Size = UDim2.new(1, 0, 0, 18)
HeaderCover.BackgroundColor3 = Color3.fromRGB(65, 16, 34)
HeaderCover.BorderSizePixel = 0
HeaderCover.Parent = Header

local HubTitle = Instance.new("TextLabel")
HubTitle.BackgroundTransparency = 1
HubTitle.Position = UDim2.new(0, 26, 0, 29)
HubTitle.Size = UDim2.new(1, -48, 0, 48)
HubTitle.Font = Enum.Font.GothamBlack
HubTitle.Text = "MYSTICS HUB"
HubTitle.TextColor3 = Color3.fromRGB(255, 245, 247)
HubTitle.TextSize = 32
HubTitle.TextXAlignment = Enum.TextXAlignment.Left
HubTitle.Parent = Header

-- Animated ruby title: a slow glow pulse with a moving red highlight.
local HubTitleStroke = Instance.new("UIStroke")
HubTitleStroke.Color = Color3.fromRGB(190, 35, 62)
HubTitleStroke.Thickness = 0.8
HubTitleStroke.Transparency = 0.38
HubTitleStroke.Parent = HubTitle

local HubTitleGradient = Instance.new("UIGradient")
HubTitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 245, 247)),
    ColorSequenceKeypoint.new(0.48, Color3.fromRGB(255, 115, 137)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 245, 247))
})
HubTitleGradient.Parent = HubTitle

local HubTitleScale = Instance.new("UIScale")
HubTitleScale.Scale = 1
HubTitleScale.Parent = HubTitle

local TitlePulseTween = TweenService:Create(
    HubTitleScale,
    TweenInfo.new(1.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Scale = 1.045}
)
local TitleGlowTween = TweenService:Create(
    HubTitleStroke,
    TweenInfo.new(1.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Transparency = 0.08, Thickness = 1.5}
)
local TitleGradientTween = TweenService:Create(
    HubTitleGradient,
    TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
    {Rotation = 360}
)
TitlePulseTween:Play()
TitleGlowTween:Play()
TitleGradientTween:Play()

local Welcome = Instance.new("TextLabel")
Welcome.BackgroundTransparency = 1
Welcome.Position = UDim2.new(0, 28, 0, 84)
Welcome.Size = UDim2.new(1, -52, 0, 28)
Welcome.Font = Enum.Font.GothamMedium
Welcome.Text = "A PREMIUM SPACE FOR YOUR CRATE SESSIONS"
Welcome.TextColor3 = Color3.fromRGB(205, 165, 175)
Welcome.TextSize = 11
Welcome.TextXAlignment = Enum.TextXAlignment.Left
Welcome.Parent = Header

HubVisual.Kicker = Instance.new("TextLabel")
HubVisual.Kicker.Name = "LauncherKicker"
HubVisual.Kicker.BackgroundTransparency = 1
HubVisual.Kicker.Position = UDim2.new(0, 28, 0, 15)
HubVisual.Kicker.Size = UDim2.new(1, -56, 0, 12)
HubVisual.Kicker.Font = Enum.Font.GothamBold
HubVisual.Kicker.Text = "MYSTICS V3.2   /   PIN-GATED LAUNCHER"
HubVisual.Kicker.TextColor3 = Color3.fromRGB(218, 104, 129)
HubVisual.Kicker.TextSize = 8
HubVisual.Kicker.TextXAlignment = Enum.TextXAlignment.Left
HubVisual.Kicker.Parent = Header

HubVisual.StatusChip = Instance.new("Frame")
HubVisual.StatusChip.Name = "UndetectedStatus"
HubVisual.StatusChip.Position = UDim2.new(0, 28, 0, 116)
HubVisual.StatusChip.Size = UDim2.fromOffset(113, 20)
HubVisual.StatusChip.BackgroundColor3 = Color3.fromRGB(76, 23, 42)
HubVisual.StatusChip.BackgroundTransparency = 0.12
HubVisual.StatusChip.BorderSizePixel = 0
HubVisual.StatusChip.Parent = Header
AddCorner(HubVisual.StatusChip, 99)
AddStroke(HubVisual.StatusChip, Color3.fromRGB(151, 53, 77), 1, 0.5)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.fromOffset(5, 5)
statusDot.Position = UDim2.new(0, 10, 0.5, -2)
statusDot.BackgroundColor3 = Color3.fromRGB(255, 125, 153)
statusDot.BorderSizePixel = 0
statusDot.Parent = HubVisual.StatusChip
AddCorner(statusDot, 99)

local statusText = Instance.new("TextLabel")
statusText.BackgroundTransparency = 1
statusText.Position = UDim2.fromOffset(22, 0)
statusText.Size = UDim2.new(1, -26, 1, 0)
statusText.Font = Enum.Font.GothamBold
statusText.Text = "UNDETECTED"
statusText.TextColor3 = Color3.fromRGB(245, 194, 209)
statusText.TextSize = 9
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = HubVisual.StatusChip

HubVisual.HeaderRule = Instance.new("Frame")
HubVisual.HeaderRule.Position = UDim2.new(0, 22, 1, -2)
HubVisual.HeaderRule.Size = UDim2.new(1, -44, 0, 1)
HubVisual.HeaderRule.BackgroundColor3 = Color3.fromRGB(228, 91, 125)
HubVisual.HeaderRule.BackgroundTransparency = 0.42
HubVisual.HeaderRule.BorderSizePixel = 0
HubVisual.HeaderRule.Parent = Header
local headerRuleGradient = Instance.new("UIGradient")
headerRuleGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.18, 0.3),
    NumberSequenceKeypoint.new(0.82, 0.3),
    NumberSequenceKeypoint.new(1, 1)
})
headerRuleGradient.Parent = HubVisual.HeaderRule

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "Close"
CloseButton.AnchorPoint = Vector2.new(1, 0)
CloseButton.Position = UDim2.new(1, -15, 0, 14)
CloseButton.Size = UDim2.new(0, 28, 0, 28)
CloseButton.BackgroundColor3 = Color3.fromRGB(82, 7, 23)
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 20
CloseButton.Font = Enum.Font.GothamBold
CloseButton.AutoButtonColor = true
CloseButton.Parent = Header
AddCorner(CloseButton, 8)

local List = Instance.new("Frame")
List.Name = "HubButtons"
List.BackgroundTransparency = 1
List.Position = UDim2.new(0, 25, 0, 169)
List.Size = UDim2.new(1, -50, 0, 340)
List.Parent = Background

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 11)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = List

local function CloseHub()
    if HubClosing or not HubGui.Parent then return end
    HubClosing = true
    PlayHubSound(HUB_CLOSE_SOUND_ID, 0.28, 0.92)

    local closeScale = TweenService:Create(
        Scale,
        TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Scale = 0.94}
    )
    local closePosition = TweenService:Create(
        Background,
        TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Position = UDim2.new(
                Background.Position.X.Scale, Background.Position.X.Offset,
                Background.Position.Y.Scale, Background.Position.Y.Offset + 12
            ),
            BackgroundTransparency = 1
        }
    )
    closeScale:Play()
    closePosition:Play()
    closePosition.Completed:Once(function()
        if HubGui then HubGui:Destroy() end
    end)
end

local function CreateHubButton(label, order, isPrimary, callback)
    local button = Instance.new("TextButton")
    button.Name = label:gsub("%W", "") .. "Button"
    button.LayoutOrder = order
    button.Size = UDim2.new(1, 0, 0, 47)
    button.BackgroundColor3 = isPrimary
        and Color3.fromRGB(153, 31, 64)
        or Color3.fromRGB(62, 20, 36)
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Font = Enum.Font.GothamSemibold
    local buttonIcons = {"📦", "🌲", "💎", "🏆", "📊", "⚙️"}
    button.Text = ""
    button.Parent = List
    button.AutoButtonColor = false
    AddCorner(button, 14)

    -- TextButton.Text ignores UIPadding in some clients, so use a dedicated
    -- label with fixed space for the emoji on the left and status pill on the right.
    local buttonTitle = Instance.new("TextLabel")
    buttonTitle.Name = "ButtonTitle"
    buttonTitle.BackgroundTransparency = 1
    buttonTitle.Position = UDim2.fromOffset(72, 0)
    buttonTitle.Size = UDim2.new(1, -174, 1, 0)
    buttonTitle.Font = Enum.Font.GothamSemibold
    buttonTitle.Text = label
    buttonTitle.TextColor3 = isPrimary
        and Color3.fromRGB(255, 250, 251)
        or Color3.fromRGB(239, 207, 216)
    buttonTitle.TextSize = 13
    buttonTitle.TextXAlignment = Enum.TextXAlignment.Left
    buttonTitle.TextTruncate = Enum.TextTruncate.AtEnd
    buttonTitle.ZIndex = 2
    buttonTitle.Parent = button

    local iconBadge = Instance.new("Frame")
    iconBadge.Name = "EmojiIconBadge"
    iconBadge.Position = UDim2.new(0, 14, 0.5, -16)
    iconBadge.Size = UDim2.fromOffset(32, 32)
    iconBadge.BackgroundColor3 = isPrimary and Color3.fromRGB(210, 70, 108) or Color3.fromRGB(119, 43, 72)
    iconBadge.BackgroundTransparency = 0.12
    iconBadge.BorderSizePixel = 0
    iconBadge.ZIndex = 3
    iconBadge.Parent = button
    AddCorner(iconBadge, 10)
    AddStroke(iconBadge, Color3.fromRGB(255, 174, 194), 1, 0.62)

    local emoji = Instance.new("TextLabel")
    emoji.Name = "MenuEmoji"
    emoji.BackgroundTransparency = 1
    emoji.Size = UDim2.fromScale(1, 1)
    emoji.Font = Enum.Font.Gotham
    emoji.Text = buttonIcons[order] or "✨"
    emoji.TextSize = 19
    emoji.ZIndex = 4
    emoji.Parent = iconBadge

    local accentRail = Instance.new("Frame")
    accentRail.Name = "AccentRail"
    accentRail.Position = UDim2.new(0, 8, 0, 7)
    accentRail.Size = UDim2.new(0, 3, 1, -14)
    accentRail.BackgroundColor3 = isPrimary and Color3.fromRGB(255, 130, 160) or Color3.fromRGB(142, 53, 77)
    accentRail.BorderSizePixel = 0
    accentRail.Parent = button
    AddCorner(accentRail, 99)

    local statePill = Instance.new("Frame")
    statePill.Name = "StatePill"
    statePill.AnchorPoint = Vector2.new(1, 0.5)
    statePill.Position = UDim2.new(1, -12, 0.5, 0)
    statePill.Size = UDim2.fromOffset(58, 21)
    statePill.BackgroundColor3 = isPrimary and Color3.fromRGB(181, 47, 82) or Color3.fromRGB(91, 31, 52)
    statePill.BackgroundTransparency = 0.12
    statePill.BorderSizePixel = 0
    statePill.Parent = button
    AddCorner(statePill, 99)
    AddStroke(statePill, isPrimary and Color3.fromRGB(255, 136, 164) or Color3.fromRGB(132, 61, 81), 1, 0.42)

    local statePillText = Instance.new("TextLabel")
    statePillText.Name = "StatePillLabel"
    statePillText.BackgroundTransparency = 1
    statePillText.Size = UDim2.fromScale(1, 1)
    statePillText.Font = Enum.Font.GothamBold
    statePillText.Text = callback and "OPEN" or "SOON"
    statePillText.TextColor3 = isPrimary and Color3.fromRGB(255, 236, 241) or Color3.fromRGB(180, 145, 155)
    statePillText.TextSize = 8
    statePillText.Parent = statePill

    local buttonGradient = AddGradient(button,
        isPrimary and Color3.fromRGB(166, 37, 73) or Color3.fromRGB(88, 29, 49),
        isPrimary and Color3.fromRGB(91, 21, 45) or Color3.fromRGB(47, 15, 29), 90)
    buttonGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.04),
        NumberSequenceKeypoint.new(1, 0.16)
    })

    local buttonStroke = AddStroke(button,
        isPrimary and Color3.fromRGB(175, 35, 58) or Color3.fromRGB(125, 31, 52),
        isPrimary and 1.3 or 1,
        isPrimary and 0.1 or 0.45
    )
    local buttonScale = Instance.new("UIScale")
    buttonScale.Scale = 1
    buttonScale.Parent = button

    if callback then
        button.Activated:Connect(function()
            if not HubUnlocked or HubLaunching or HubClosing then return end
            PlayHubSound(HUB_CLICK_SOUND_ID, 0.28, 1 + math.random(-3, 3) / 100)
            callback()
        end)
    end

    button.MouseButton1Down:Connect(function()
        if button.Parent then
            TweenService:Create(buttonScale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.975}):Play()
        end
    end)
    button.MouseButton1Up:Connect(function()
        if button.Parent then
            TweenService:Create(buttonScale, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.018}):Play()
        end
    end)

    button.MouseEnter:Connect(function()
        if button.Parent then
            TweenService:Create(button, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = isPrimary
                    and Color3.fromRGB(190, 48, 88)
                    or Color3.fromRGB(105, 34, 59)
            }):Play()
            TweenService:Create(buttonScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Scale = 1.018
            }):Play()
            TweenService:Create(buttonStroke, TweenInfo.new(0.16), {Transparency = 0}):Play()
        end
    end)
    button.MouseLeave:Connect(function()
        if button.Parent then
            TweenService:Create(button, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = isPrimary
                    and Color3.fromRGB(153, 31, 64)
                    or Color3.fromRGB(62, 20, 36)
            }):Play()
            TweenService:Create(buttonScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Scale = 1
            }):Play()
            TweenService:Create(buttonStroke, TweenInfo.new(0.16), {
                Transparency = isPrimary and 0.1 or 0.45
            }):Play()
        end
    end)

    return button
end

-- Forward declaration: the crate module is fetched only after the user clicks.
local LaunchRLCrateUnboxing
local RLCrateButton
local RLCrateLoading = false

local function SetRLCrateButtonState(text, enabled)
    if RLCrateButton and RLCrateButton.Parent then
        local buttonTitle = RLCrateButton:FindFirstChild("ButtonTitle")
        if buttonTitle then buttonTitle.Text = text end
        RLCrateButton.Active = enabled
        RLCrateButton.AutoButtonColor = enabled
        local pill = RLCrateButton:FindFirstChild("StatePill")
        local pillLabel = pill and pill:FindFirstChild("StatePillLabel")
        if pillLabel then
            pillLabel.Text = string.find(string.upper(text), "RETRY", 1, true) and "RETRY"
                or (enabled and "OPEN" or "LOADING")
        end
    end
end

local function LaunchSelectedExperience()
    if not HubUnlocked or HubLaunching or HubClosing or RLCrateLoading then return end
    HubLaunching = true
    RLCrateLoading = true
    SetRLCrateButtonState("Downloading RL Crate...", false)
    task.spawn(function()
        local ok, err = pcall(LaunchRLCrateUnboxing)
        if not ok then
            warn("[Mystics Hub] RL Crate load failed: " .. tostring(err))
            RLCrateLoading = false
            HubLaunching = false
            SetRLCrateButtonState("Retry RL Crate Unboxing", true)
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "MYSTICS HUB",
                    Text = "RL Crate could not load. Check connection and retry.",
                    Duration = 5
                })
            end)
            return
        end
        RLCrateLoading = false
        CloseHub()
    end)
end

LaunchRLCrateUnboxing = function()
    -- Immutable commit pin: main-branch changes cannot silently alter this module.
    local moduleCommit = "95026c4c612a0d844ac963927bc2ec35f453decd"
    local moduleUrl = "https://raw.githubusercontent.com/MysticsALT/temp/" .. moduleCommit .. "/RLCrate.lua"

    if type(loadstring) ~= "function" then
        error("This environment does not provide loadstring.")
    end

    local downloadOk, sourceCode = pcall(function()
        return game:HttpGet(moduleUrl)
    end)
    if not downloadOk then
        error("GitHub download failed: " .. tostring(sourceCode))
    end

    if type(sourceCode) ~= "string"
        or #sourceCode < 1000
        or not string.find(sourceCode, "MYSTICS | RL CRATE UNBOXING MODULE", 1, true) then
        error("GitHub returned an empty, incomplete, or unexpected RL Crate module.")
    end

    local chunk, compileError = loadstring(sourceCode, "Mystics_RLCrate")
    if type(chunk) ~= "function" then
        error("RL Crate compile error: " .. tostring(compileError))
    end

    return chunk()
end

-- Button 2 has its own independent, lazy-loaded module.
-- It is downloaded ONLY when the user explicitly chooses Lumber Tycoon 2.
local LT2Button
local LT2Loading = false
local function SetLT2ButtonState(textValue, enabled)
    if not LT2Button or not LT2Button.Parent then return end
    local title = LT2Button:FindFirstChild("ButtonTitle")
    if title then title.Text = textValue end
    LT2Button.Active = enabled
    local pill = LT2Button:FindFirstChild("StatePill")
    local label = pill and pill:FindFirstChild("StatePillLabel")
    if label then
        label.Text = not enabled and "LOADING" or
            (string.find(textValue, "Retry", 1, true) and "RETRY" or "OPEN")
    end
end

local function LaunchLT2()
    if not HubUnlocked or HubLaunching or HubClosing or LT2Loading or RLCrateLoading then return end
    HubLaunching = true
    LT2Loading = true
    SetLT2ButtonState("Downloading Lumber Tycoon 2...", false)
    task.spawn(function()
        local ok, errorMessage = pcall(function()
            -- Commit-pinned loading avoids silently changing module contents.
            local lt2ModuleCommit = "ad24ed4b9309938ccba3927b33b191a428d54cf4"
            local lt2Url = "https://raw.githubusercontent.com/MysticsALT/temp/"
                .. lt2ModuleCommit .. "/LT2.lua"
            if type(loadstring) ~= "function" then
                error("This environment does not provide loadstring.")
            end
            local downloaded, source = pcall(function()
                -- Use the exact raw URL: some executors mishandle query strings on raw GitHub.
                return game:HttpGet(lt2Url)
            end)
            if not downloaded then
                error("LT2 GitHub download failed: " .. tostring(source))
            end
            if type(source) ~= "string" then
                error("LT2 download returned " .. typeof(source) .. " instead of text.")
            end
            local sourceLength = #source
            local hasMarker = string.find(source, "MYSTICS | LUMBER TYCOON 2 MODULE", 1, true) ~= nil
            local hasVersion = string.find(source, "V2.24 | Self-contained", 1, true) ~= nil
            if sourceLength < 8000 then
                error("LT2 download too short: " .. sourceLength .. " characters. Check executor HTTP response.")
            end
            if not hasMarker then
                error("LT2 download missing module marker; received " .. sourceLength .. " characters. Response may be an HTML error page or truncated.")
            end
            if not hasVersion then
                error("LT2 download has the module marker but not version V2.24; received " .. sourceLength .. " characters.")
            end
            local chunk, compileError = loadstring(source, "Mystics_LT2")
            if type(chunk) ~= "function" then
                error("LT2 compile error: " .. tostring(compileError))
            end
            return chunk()
        end)

        LT2Loading = false
        if not ok then
            warn("[Mystics Hub] LT2 load failed: " .. tostring(errorMessage))
            HubLaunching = false
            SetLT2ButtonState("Retry Lumber Tycoon 2", true)
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "MYSTICS HUB",
                    Text = "LT2 could not load. Check the console and try again.",
                    Duration = 5
                })
            end)
            return
        end
        CloseHub()
    end)
end

RLCrateButton = CreateHubButton("RL Crate Unboxing", 1, true, LaunchSelectedExperience)
LT2Button = CreateHubButton("Lumber Tycoon 2", 2, true, LaunchLT2)
CreateHubButton("Premium Items", 3, false, nil)
CreateHubButton("Achievements", 4, false, nil)
CreateHubButton("Statistics", 5, false, nil)
CreateHubButton("Settings", 6, false, nil)

local Footer = Instance.new("TextLabel")
Footer.BackgroundTransparency = 1
Footer.AnchorPoint = Vector2.new(0.5, 1)
Footer.Position = UDim2.new(0.5, 0, 1, -14)
Footer.Size = UDim2.new(1, -30, 0, 18)
Footer.Font = Enum.Font.Gotham
Footer.Text = "M Y S T I C S     /     ON-DEMAND EXPERIENCE LOADER"
Footer.TextColor3 = Color3.fromRGB(215, 157, 173)
Footer.TextSize = 8
Footer.Parent = Background

CloseButton.Activated:Connect(CloseHub)

-- Present ONLY the PIN screen until unlocked, so the menu cannot be
-- interacted with or accidentally be mistaken for an ungated version.
Header.Visible = false
List.Visible = false
Footer.Visible = false
HubVisual.Ambient.Visible = false

-- This is a client-side UI lock, not a secure server-side authentication system.
local AccessOverlay = Instance.new("Frame")
AccessOverlay.Name = "AccessGate"
AccessOverlay.Size = UDim2.fromScale(1, 1)
AccessOverlay.BackgroundColor3 = Color3.fromRGB(28, 7, 17)
AccessOverlay.BackgroundTransparency = 0.02
AccessOverlay.BorderSizePixel = 0
AccessOverlay.Active = true
AccessOverlay.ZIndex = 40
AccessOverlay.Parent = Background
AddCorner(AccessOverlay, 24)
local AccessGradient = AddGradient(AccessOverlay, Color3.fromRGB(96, 21, 51), Color3.fromRGB(23, 6, 15), 90)
TweenService:Create(AccessGradient,
    TweenInfo.new(17, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Rotation = 135}
):Play()

-- Low-overhead drifting ruby lights behind the PIN panel.
local AccessGlow = Instance.new("Frame")
AccessGlow.Name = "AccessSoftGlow"
AccessGlow.AnchorPoint = Vector2.new(0.5, 0.5)
AccessGlow.Position = UDim2.fromScale(0.5, 0.5)
AccessGlow.Size = UDim2.new(1, -12, 0, 380)
AccessGlow.BackgroundColor3 = Color3.fromRGB(222, 48, 99)
AccessGlow.BackgroundTransparency = 0.86
AccessGlow.BorderSizePixel = 0
AccessGlow.ZIndex = 40
AccessGlow.Parent = AccessOverlay
AddCorner(AccessGlow, 40)
TweenService:Create(AccessGlow,
    TweenInfo.new(4.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {BackgroundTransparency = 0.94}
):Play()

for i = 1, 17 do
    local spark = Instance.new("Frame")
    spark.Name = "AccessSpark" .. i
    spark.Size = UDim2.fromOffset(i % 3 == 0 and 4 or 2, i % 3 == 0 and 4 or 2)
    spark.Position = UDim2.fromScale(0.06 + ((i * 23) % 87) / 100, 0.08 + ((i * 17) % 83) / 100)
    spark.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(255, 178, 202) or Color3.fromRGB(229, 84, 128)
    spark.BackgroundTransparency = 0.36 + (i % 3) * 0.08
    spark.BorderSizePixel = 0
    spark.ZIndex = 40
    spark.Parent = AccessOverlay
    AddCorner(spark, 99)
    TweenService:Create(spark,
        TweenInfo.new(3.5 + i * 0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Position = spark.Position + UDim2.new(0, 0, -(0.045 + (i % 3) * 0.012), 0), BackgroundTransparency = 0.85}
    ):Play()
end

-- Animated ambient lights live BEHIND the access card (ZIndex 40).
-- A small fixed number of tweens, no RenderStepped handlers.
for i = 1, 2 do
    local orb = Instance.new("Frame")
    orb.Name = "AccessFloatingOrb" .. i
    orb.AnchorPoint = Vector2.new(0.5, 0.5)
    orb.Size = UDim2.fromOffset(i == 1 and 156 or 128, i == 1 and 156 or 128)
    orb.Position = UDim2.fromScale(i == 1 and 0.15 or 0.85, i == 1 and 0.20 or 0.80)
    orb.BackgroundColor3 = i == 1 and Color3.fromRGB(253, 86, 142)
        or Color3.fromRGB(255, 140, 182)
    orb.BackgroundTransparency = 0.88
    orb.BorderSizePixel = 0
    orb.ZIndex = 40
    orb.Parent = AccessOverlay
    AddCorner(orb, 999)
    local orbGradient = Instance.new("UIGradient")
    orbGradient.Rotation = i == 1 and 30 or 150
    orbGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.72),
        NumberSequenceKeypoint.new(0.42, 0.12),
        NumberSequenceKeypoint.new(1, 1)
    })
    orbGradient.Parent = orb
    TweenService:Create(
        orb,
        TweenInfo.new(8 + i * 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {
            Position = UDim2.fromScale(i == 1 and 0.34 or 0.65, i == 1 and 0.32 or 0.66),
            BackgroundTransparency = 0.95
        }
    ):Play()
end

-- Two slow ruby streaks make the background feel alive without obscuring the PIN.
for i = 1, 2 do
    local streak = Instance.new("Frame")
    streak.Name = "AccessMovingStreak" .. i
    streak.Position = UDim2.fromScale(0.07, i == 1 and 0.14 or 0.83)
    streak.Size = UDim2.new(0.86, 0, 0, 2)
    streak.BackgroundColor3 = Color3.fromRGB(245, 105, 155)
    streak.BackgroundTransparency = 0.50
    streak.BorderSizePixel = 0
    streak.ZIndex = 40
    streak.Parent = AccessOverlay
    local streakGradient = Instance.new("UIGradient")
    streakGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.36, 0.92),
        NumberSequenceKeypoint.new(0.5, 0.1),
        NumberSequenceKeypoint.new(0.64, 0.92),
        NumberSequenceKeypoint.new(1, 1)
    })
    streakGradient.Offset = Vector2.new(-1, 0)
    streakGradient.Parent = streak
    TweenService:Create(
        streakGradient,
        TweenInfo.new(5.0 + i * 1.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Offset = Vector2.new(1, 0)}
    ):Play()
end

local AccessPanel = Instance.new("Frame")
AccessPanel.Name = "AccessPanel"
AccessPanel.AnchorPoint = Vector2.new(0.5, 0.5)
AccessPanel.Position = UDim2.fromScale(0.5, 0.5)
AccessPanel.Size = UDim2.new(1, -50, 0, 320)
AccessPanel.BackgroundColor3 = Color3.fromRGB(73, 18, 39)
AccessPanel.BorderSizePixel = 0
AccessPanel.ZIndex = 41
AccessPanel.Parent = AccessOverlay
AddCorner(AccessPanel, 18)
local AccessStroke = AddStroke(AccessPanel, Color3.fromRGB(231, 86, 127), 1.5, 0.14)
AddGradient(AccessPanel, Color3.fromRGB(126, 31, 64), Color3.fromRGB(54, 15, 34), 90)
AccessPanel.ClipsDescendants = true

local AccessScale = Instance.new("UIScale")
AccessScale.Scale = 0.94
AccessScale.Parent = AccessPanel
TweenService:Create(AccessScale,
    TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    {Scale = 1}
):Play()
TweenService:Create(AccessStroke,
    TweenInfo.new(3.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Transparency = 0.52}
):Play()

-- A soft moving highlight across the panel's upper edge.
local AccessLine = Instance.new("Frame")
AccessLine.Name = "AccessLightSweep"
AccessLine.Position = UDim2.fromOffset(20, 8)
AccessLine.Size = UDim2.new(1, -40, 0, 2)
AccessLine.BackgroundColor3 = Color3.fromRGB(255, 146, 186)
AccessLine.BackgroundTransparency = 0.12
AccessLine.BorderSizePixel = 0
AccessLine.ZIndex = 41
AccessLine.Parent = AccessPanel
AddCorner(AccessLine, 2)
local AccessLineGradient = Instance.new("UIGradient")
AccessLineGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.5, 0.08),
    NumberSequenceKeypoint.new(1, 1)
})
AccessLineGradient.Offset = Vector2.new(-1, 0)
AccessLineGradient.Parent = AccessLine
TweenService:Create(AccessLineGradient,
    TweenInfo.new(5.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1),
    {Offset = Vector2.new(1, 0)}
):Play()

-- Monogram uses a text glyph instead of an external image asset.
local AccessEmblem = Instance.new("Frame")
AccessEmblem.Name = "AccessEmblem"
AccessEmblem.Position = UDim2.new(1, -59, 0, 22)
AccessEmblem.Size = UDim2.fromOffset(34, 34)
AccessEmblem.BackgroundColor3 = Color3.fromRGB(136, 34, 69)
AccessEmblem.BackgroundTransparency = 0.25
AccessEmblem.BorderSizePixel = 0
AccessEmblem.ZIndex = 42
AccessEmblem.Parent = AccessPanel
AddCorner(AccessEmblem, 99)
AddStroke(AccessEmblem, Color3.fromRGB(245, 133, 172), 1, 0.37)
local AccessLetter = Instance.new("TextLabel")
AccessLetter.BackgroundTransparency = 1
AccessLetter.Size = UDim2.fromScale(1, 1)
AccessLetter.Font = Enum.Font.GothamBlack
AccessLetter.Text = "M"
AccessLetter.TextSize = 17
AccessLetter.TextColor3 = Color3.fromRGB(255, 215, 229)
AccessLetter.ZIndex = 43
AccessLetter.Parent = AccessEmblem

local AccessKicker = Instance.new("TextLabel")
AccessKicker.BackgroundTransparency = 1
AccessKicker.Position = UDim2.fromOffset(24, 24)
AccessKicker.Size = UDim2.new(1, -48, 0, 18)
AccessKicker.Font = Enum.Font.GothamBold
AccessKicker.Text = "Mystics HUB V 2.1"
AccessKicker.TextSize = 10
AccessKicker.TextColor3 = Color3.fromRGB(255, 156, 182)
AccessKicker.TextXAlignment = Enum.TextXAlignment.Left
AccessKicker.ZIndex = 42
AccessKicker.Parent = AccessPanel

local AccessTitle = Instance.new("TextLabel")
AccessTitle.BackgroundTransparency = 1
AccessTitle.Position = UDim2.fromOffset(24, 54)
AccessTitle.Size = UDim2.new(1, -48, 0, 36)
AccessTitle.Font = Enum.Font.GothamBlack
AccessTitle.Text = "Mystics HUB V 2.1"
AccessTitle.TextSize = 23
AccessTitle.TextColor3 = Color3.fromRGB(255, 243, 248)
AccessTitle.TextXAlignment = Enum.TextXAlignment.Left
AccessTitle.ZIndex = 42
AccessTitle.Parent = AccessPanel

local AccessHint = Instance.new("TextLabel")
AccessHint.BackgroundTransparency = 1
AccessHint.Position = UDim2.fromOffset(24, 94)
AccessHint.Size = UDim2.new(1, -48, 0, 24)
AccessHint.Font = Enum.Font.Gotham
AccessHint.Text = "Do you know ball?"
AccessHint.TextSize = 12
AccessHint.TextColor3 = Color3.fromRGB(222, 176, 191)
AccessHint.TextXAlignment = Enum.TextXAlignment.Left
AccessHint.ZIndex = 42
AccessHint.Parent = AccessPanel

local AccessInput = Instance.new("TextBox")
AccessInput.Name = "AccessCodeInput"
AccessInput.Position = UDim2.new(0, 24, 0, 135)
AccessInput.Size = UDim2.new(1, -48, 0, 52)
AccessInput.BackgroundColor3 = Color3.fromRGB(30, 9, 21)
AccessInput.BorderSizePixel = 0
AccessInput.ClearTextOnFocus = false
AccessInput.MultiLine = false
AccessInput.Text = ""
AccessInput.PlaceholderText = "TYPE CODE"
AccessInput.PlaceholderColor3 = Color3.fromRGB(185, 127, 150)
AccessInput.TextColor3 = Color3.fromRGB(255, 223, 235)
AccessInput.TextTransparency = 0
AccessInput.TextSize = 18
AccessInput.Font = Enum.Font.GothamBold
AccessInput.TextXAlignment = Enum.TextXAlignment.Center
AccessInput.ZIndex = 43
AccessInput.Parent = AccessPanel
AddCorner(AccessInput, 12)
AddStroke(AccessInput, Color3.fromRGB(190, 78, 110), 1, 0.25)

local AccessMask = Instance.new("TextLabel")
AccessMask.Name = "CodeMask"
AccessMask.BackgroundTransparency = 1
AccessMask.Position = AccessInput.Position
AccessMask.Size = AccessInput.Size
AccessMask.Font = Enum.Font.GothamBold
AccessMask.Text = "○   ○   ○   ○"
AccessMask.TextSize = 21
AccessMask.TextColor3 = Color3.fromRGB(255, 207, 221)
AccessMask.ZIndex = 44
AccessMask.Active = false
AccessMask.Visible = false
AccessMask.Parent = AccessPanel

local AccessError = Instance.new("TextLabel")
AccessError.BackgroundTransparency = 1
AccessError.Position = UDim2.new(0, 24, 0, 194)
AccessError.Size = UDim2.new(1, -48, 0, 18)
AccessError.Font = Enum.Font.GothamMedium
AccessError.Text = ""
AccessError.TextColor3 = Color3.fromRGB(255, 127, 147)
AccessError.TextSize = 11
AccessError.ZIndex = 42
AccessError.Parent = AccessPanel

-- High-contrast button: pale rose with dark burgundy letters.
-- Avoid UIGradient directly on the TextButton; it darkens its text too.
local UnlockHalo = Instance.new("Frame")
UnlockHalo.Name = "UnlockButtonHalo"
UnlockHalo.Position = UDim2.new(0, 20, 0, 220)
UnlockHalo.Size = UDim2.new(1, -40, 0, 52)
UnlockHalo.BackgroundColor3 = Color3.fromRGB(252, 89, 143)
UnlockHalo.BackgroundTransparency = 0.70
UnlockHalo.BorderSizePixel = 0
UnlockHalo.ZIndex = 42
UnlockHalo.Parent = AccessPanel
AddCorner(UnlockHalo, 14)
TweenService:Create(
    UnlockHalo,
    TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {BackgroundTransparency = 0.90}
):Play()

local UnlockButton = Instance.new("TextButton")
UnlockButton.Name = "UnlockButton"
UnlockButton.Position = UDim2.new(0, 24, 0, 224)
UnlockButton.Size = UDim2.new(1, -48, 0, 44)
UnlockButton.BackgroundColor3 = Color3.fromRGB(255, 184, 208)
UnlockButton.BorderSizePixel = 0
UnlockButton.Font = Enum.Font.GothamBlack
UnlockButton.Text = "UNLOCK HERE"
UnlockButton.TextColor3 = Color3.fromRGB(46, 10, 26)
UnlockButton.TextSize = 16
UnlockButton.AutoButtonColor = false
UnlockButton.ZIndex = 43
UnlockButton.Parent = AccessPanel
AddCorner(UnlockButton, 11)
local UnlockStroke = AddStroke(UnlockButton, Color3.fromRGB(255, 229, 238), 2, 0.04)
local UnlockScale = Instance.new("UIScale")
UnlockScale.Scale = 1
UnlockScale.Parent = UnlockButton
TweenService:Create(
    UnlockStroke,
    TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Transparency = 0.40}
):Play()

UnlockButton.MouseEnter:Connect(function()
    TweenService:Create(UnlockButton,
        TweenInfo.new(0.17, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundColor3 = Color3.fromRGB(255, 214, 229)}
    ):Play()
    TweenService:Create(UnlockScale,
        TweenInfo.new(0.17, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Scale = 1.02}
    ):Play()
end)
UnlockButton.MouseLeave:Connect(function()
    TweenService:Create(UnlockButton,
        TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundColor3 = Color3.fromRGB(255, 184, 208)}
    ):Play()
    TweenService:Create(UnlockScale,
        TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Scale = 1}
    ):Play()
end)
UnlockButton.MouseButton1Down:Connect(function()
    TweenService:Create(UnlockScale,
        TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Scale = 0.985}
    ):Play()
end)
UnlockButton.MouseButton1Up:Connect(function()
    TweenService:Create(UnlockScale,
        TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = 1.02}
    ):Play()
end)

local AccessExit = Instance.new("TextButton")
AccessExit.Name = "ExitLockedHub"
AccessExit.Position = UDim2.new(0, 24, 1, -38)
AccessExit.Size = UDim2.new(1, -48, 0, 26)
AccessExit.BackgroundTransparency = 1
AccessExit.Font = Enum.Font.GothamMedium
AccessExit.Text = "EXIT"
AccessExit.TextColor3 = Color3.fromRGB(208, 151, 172)
AccessExit.TextSize = 10
AccessExit.ZIndex = 42
AccessExit.Parent = AccessPanel
AccessExit.Activated:Connect(CloseHub)

AccessInput:GetPropertyChangedSignal("Text"):Connect(function()
    if HubUnlocked then return end
    local digits = AccessInput.Text:gsub("%D", ""):sub(1, 4)
    if AccessInput.Text ~= digits then
        AccessInput.Text = digits
    end
    local dots = {}
    for i = 1, 4 do
        dots[i] = i <= #digits and "●" or "○"
    end
    AccessMask.Text = table.concat(dots, "   ")
    AccessError.Text = ""
end)

local function AttemptUnlock()
    if HubUnlocked or HubClosing then return end
    if AccessInput.Text == "4587" then
        HubUnlocked = true
        PlayHubSound(HUB_CLICK_SOUND_ID, 0.25, 1.05)
        Header.Visible = true
        List.Visible = true
        Footer.Visible = true
        HubVisual.Ambient.Visible = true
        AccessOverlay:Destroy()
    else
        AccessInput.Text = ""
        AccessError.Text = "Incorrect code. Please try again."
        TweenService:Create(
            AccessStroke,
            TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 1, true),
            {Color = Color3.fromRGB(255, 80, 102), Thickness = 2.5}
        ):Play()
        AccessInput:CaptureFocus()
    end
end

UnlockButton.Activated:Connect(AttemptUnlock)
AccessInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then AttemptUnlock() end
end)
-- The gate remains visible until the correct PIN is entered; no auto-unlock.

PlayHubSound(HUB_OPEN_SOUND_ID, 0.32, 1.04)
HubOpenTween:Play()
HubPositionTween:Play()
HubHeaderTween:Play()

-- Drag the launcher by its header.
local UserInputService = game:GetService("UserInputService")
local dragging = false
local dragStart
local startPosition

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = Background.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Background.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

--========================================================
