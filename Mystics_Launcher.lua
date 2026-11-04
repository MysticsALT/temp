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

local ExistingHub = HubParent:FindFirstChild("MysticsHub_Main")
if ExistingHub then
    ExistingHub:Destroy()
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
Background.BackgroundColor3 = Color3.fromRGB(8, 2, 5)
Background.BorderSizePixel = 0
Background.ClipsDescendants = true
Background.Parent = HubGui
AddCorner(Background, 24)
HubVisual.Stroke = AddStroke(Background, Color3.fromRGB(155, 48, 72), 1.6, 0.04)
HubVisual.Gradient = AddGradient(Background, Color3.fromRGB(25, 4, 10), Color3.fromRGB(12, 2, 6), 90)

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
HubVisual.TopAura.BackgroundColor3 = Color3.fromRGB(155, 25, 57)
HubVisual.TopAura.BackgroundTransparency = 0.88
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
Header.BackgroundColor3 = Color3.fromRGB(42, 6, 15)
Header.BorderSizePixel = 0
Header.Parent = Background
AddCorner(Header, 18)
AddGradient(Header, Color3.fromRGB(98, 9, 28), Color3.fromRGB(25, 4, 10), 0)
Header.BackgroundTransparency = 1
local HubHeaderTween = TweenService:Create(
    Header,
    TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    {BackgroundTransparency = 0}
)

local HeaderCover = Instance.new("Frame")
HeaderCover.Position = UDim2.new(0, 0, 1, -18)
HeaderCover.Size = UDim2.new(1, 0, 0, 18)
HeaderCover.BackgroundColor3 = Color3.fromRGB(25, 4, 10)
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
HubVisual.Kicker.Text = "PREMIUM EXPERIENCE HUB   /   V3.0"
HubVisual.Kicker.TextColor3 = Color3.fromRGB(218, 104, 129)
HubVisual.Kicker.TextSize = 8
HubVisual.Kicker.TextXAlignment = Enum.TextXAlignment.Left
HubVisual.Kicker.Parent = Header

HubVisual.ChipRow = Instance.new("Frame")
HubVisual.ChipRow.Name = "LauncherStatusChips"
HubVisual.ChipRow.BackgroundTransparency = 1
HubVisual.ChipRow.Position = UDim2.new(0, 28, 0, 116)
HubVisual.ChipRow.Size = UDim2.new(1, -56, 0, 20)
HubVisual.ChipRow.Parent = Header

for i, chipInfo in ipairs({
    {"ON-DEMAND MODULE", 112},
    {"GITHUB CONNECTED", 116}
}) do
    local chip = Instance.new("Frame")
    chip.Name = "LauncherChip" .. i
    chip.Position = UDim2.fromOffset((i - 1) * 122, 0)
    chip.Size = UDim2.fromOffset(chipInfo[2], 20)
    chip.BackgroundColor3 = Color3.fromRGB(20, 5, 11)
    chip.BackgroundTransparency = 0.12
    chip.BorderSizePixel = 0
    chip.Parent = HubVisual.ChipRow
    AddCorner(chip, 99)
    AddStroke(chip, Color3.fromRGB(151, 53, 77), 1, 0.5)

    local chipDot = Instance.new("Frame")
    chipDot.Size = UDim2.fromOffset(5, 5)
    chipDot.Position = UDim2.new(0, 9, 0.5, -2)
    chipDot.BackgroundColor3 = Color3.fromRGB(255, 125, 153)
    chipDot.BorderSizePixel = 0
    chipDot.Parent = chip
    AddCorner(chipDot, 99)

    local chipText = Instance.new("TextLabel")
    chipText.BackgroundTransparency = 1
    chipText.Position = UDim2.fromOffset(19, 0)
    chipText.Size = UDim2.new(1, -24, 1, 0)
    chipText.Font = Enum.Font.GothamBold
    chipText.Text = chipInfo[1]
    chipText.TextColor3 = Color3.fromRGB(225, 190, 199)
    chipText.TextSize = 8
    chipText.TextXAlignment = Enum.TextXAlignment.Left
    chipText.Parent = chip
end

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
        and Color3.fromRGB(82, 7, 23)
        or Color3.fromRGB(25, 4, 10)
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Font = Enum.Font.GothamSemibold
    button.Text = label
    button.TextColor3 = isPrimary
        and Color3.fromRGB(255, 245, 247)
        or Color3.fromRGB(205, 165, 175)
    button.TextSize = 13
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.Parent = List
    button.AutoButtonColor = false
    AddCorner(button, 14)
    local buttonPadding = Instance.new("UIPadding")
    buttonPadding.PaddingLeft = UDim.new(0, 22)
    buttonPadding.PaddingRight = UDim.new(0, 104)
    buttonPadding.Parent = button

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
    statePill.BackgroundColor3 = isPrimary and Color3.fromRGB(112, 18, 42) or Color3.fromRGB(31, 8, 16)
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
        isPrimary and Color3.fromRGB(75, 8, 25) or Color3.fromRGB(26, 5, 11),
        isPrimary and Color3.fromRGB(34, 4, 13) or Color3.fromRGB(13, 2, 6), 90)
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
            if HubLaunching or HubClosing then return end
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
                    and Color3.fromRGB(125, 15, 38)
                    or Color3.fromRGB(42, 6, 15)
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
                    and Color3.fromRGB(82, 7, 23)
                    or Color3.fromRGB(25, 4, 10)
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
        RLCrateButton.Text = text
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
    if HubLaunching or HubClosing or RLCrateLoading then return end
    HubLaunching = true
    RLCrateLoading = true
    SetRLCrateButtonState("✦   DOWNLOADING RL CRATE...", false)
    task.spawn(function()
        local ok, err = pcall(LaunchRLCrateUnboxing)
        if not ok then
            warn("[Mystics Hub] RL Crate load failed: " .. tostring(err))
            RLCrateLoading = false
            HubLaunching = false
            SetRLCrateButtonState("✦   RETRY RL CRATE UNBOXING", true)
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
    local moduleCommit = "89e66a7be0c1dc3382db74cb2d53b5529493ec63"
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

RLCrateButton = CreateHubButton("✦   RL Crate Unboxing", 1, true, LaunchSelectedExperience)
CreateHubButton("◈   Hub Slot 02  —  Coming Soon", 2, false, nil)
CreateHubButton("◇   Hub Slot 03  —  Coming Soon", 3, false, nil)
CreateHubButton("✧   Hub Slot 04  —  Coming Soon", 4, false, nil)
CreateHubButton("◆   Hub Slot 05  —  Coming Soon", 5, false, nil)
CreateHubButton("✦   Hub Slot 06  —  Coming Soon", 6, false, nil)

local Footer = Instance.new("TextLabel")
Footer.BackgroundTransparency = 1
Footer.AnchorPoint = Vector2.new(0.5, 1)
Footer.Position = UDim2.new(0.5, 0, 1, -14)
Footer.Size = UDim2.new(1, -30, 0, 18)
Footer.Font = Enum.Font.Gotham
Footer.Text = "M Y S T I C S     /     ON-DEMAND EXPERIENCE LOADER"
Footer.TextColor3 = Color3.fromRGB(166, 99, 114)
Footer.TextSize = 8
Footer.Parent = Background

CloseButton.Activated:Connect(CloseHub)

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
