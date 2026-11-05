--========================================================
-- MYSTICS | LUMBER TYCOON 2 MODULE
-- V2.13 | Self-contained utility module + opt-in legacy research tests
-- No external script execution, anti-ban tampering or automatic dupe actions.
-- Historical waypoint coordinates are reference data, NOT verified.
--========================================================

if getgenv and type(getgenv().MysticsLT2Cleanup) == "function" then
    pcall(getgenv().MysticsLT2Cleanup)
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

local Parent = LocalPlayer:WaitForChild("PlayerGui")
pcall(function()
    if type(gethui) == "function" then Parent = gethui() or Parent end
end)
local previous = Parent:FindFirstChild("MysticsLT2_Module")
if previous then previous:Destroy() end

local State = {
    closed = false, selectedTab = "TRAVEL", selectedPlayer = nil,
    notifications = true, sounds = true, lowMotion = false,
    theme = "MYSTICS", returnCFrame = nil,
    customLocations = {}, woodHighlights = {},
    lastTeleport = 0, minimised = false,
}
local Connections, Tweens, Styled = {}, {}, {}
local Palette = {
    MYSTICS = {
        base = Color3.fromRGB(14, 17, 25), surface = Color3.fromRGB(24, 29, 41),
        card = Color3.fromRGB(33, 40, 55), action = Color3.fromRGB(103, 42, 69),
        accent = Color3.fromRGB(244, 91, 139), light = Color3.fromRGB(255, 174, 203),
        text = Color3.fromRGB(248, 249, 253), muted = Color3.fromRGB(164, 174, 194),
        border = Color3.fromRGB(66, 76, 96)
    },
    OBSIDIAN = {
        base = Color3.fromRGB(24, 29, 44), surface = Color3.fromRGB(43, 51, 73),
        card = Color3.fromRGB(61, 70, 95), action = Color3.fromRGB(71, 92, 142),
        accent = Color3.fromRGB(129, 173, 255), light = Color3.fromRGB(210, 225, 255),
        text = Color3.fromRGB(250, 251, 255), muted = Color3.fromRGB(208, 219, 238),
        border = Color3.fromRGB(111, 138, 184)
    },
    CHRISTMAS = {
        base = Color3.fromRGB(17, 42, 43), surface = Color3.fromRGB(30, 73, 68),
        card = Color3.fromRGB(43, 93, 88), action = Color3.fromRGB(35, 132, 101),
        accent = Color3.fromRGB(123, 224, 177), light = Color3.fromRGB(226, 255, 234),
        text = Color3.fromRGB(249, 255, 251), muted = Color3.fromRGB(205, 239, 220),
        border = Color3.fromRGB(101, 168, 145)
    },
    HALLOWEEN = {
        base = Color3.fromRGB(34, 20, 48), surface = Color3.fromRGB(68, 35, 82),
        card = Color3.fromRGB(92, 49, 111), action = Color3.fromRGB(155, 78, 55),
        accent = Color3.fromRGB(255, 169, 91), light = Color3.fromRGB(255, 228, 182),
        text = Color3.fromRGB(255, 250, 245), muted = Color3.fromRGB(242, 217, 226),
        border = Color3.fromRGB(171, 104, 147)
    }
}
local function theme() return Palette[State.theme] end
local function connect(signal, callback)
    local c = signal:Connect(callback)
    Connections[#Connections + 1] = c
    return c
end
local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = obj
    return c
end
local function stroke(obj, role, thickness)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 1
    s.Transparency = 0.2
    s.Parent = obj
    Styled[#Styled + 1] = {s, role or "stroke"}
    return s
end
local function style(obj, role)
    Styled[#Styled + 1] = {obj, role}
    return obj
end
local function applyTheme()
    local p = theme()
    for _, entry in ipairs(Styled) do
        local obj, role = entry[1], entry[2]
        if obj.Parent then
            if obj:IsA("UIStroke") then
                obj.Color = role == "accentStroke" and p.light or p.border
            elseif obj:IsA("TextLabel") or obj:IsA("TextBox") then
                obj.TextColor3 = role == "muted" and p.muted
                    or role == "accentText" and p.light or p.text
                if role == "input" then obj.BackgroundColor3 = p.card end
            elseif obj:IsA("Frame") or obj:IsA("TextButton") or obj:IsA("ScrollingFrame") then
                if role == "base" then obj.BackgroundColor3 = p.base
                elseif role == "surface" then obj.BackgroundColor3 = p.surface
                elseif role == "card" then obj.BackgroundColor3 = p.card
                elseif role == "accent" then obj.BackgroundColor3 = p.accent
                elseif role == "cta" then obj.BackgroundColor3 = p.action
                elseif role == "quiet" then obj.BackgroundColor3 = p.surface
                end
                if obj:IsA("TextButton") then obj.TextColor3 = p.text end
            end
        end
    end
end
local function tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end
local function animateForever(obj, seconds, props)
    local t = TweenService:Create(obj, TweenInfo.new(
        seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
    ), props)
    Tweens[#Tweens + 1] = t
    if not State.lowMotion then t:Play() end
end
local function playClick()
    if not State.sounds then return end
    pcall(function()
        local sound = Instance.new("Sound")
        sound.Name = "MysticsLT2UI"
        sound.SoundId = "rbxassetid://6895079853"
        sound.Volume = 0.14
        sound.Parent = SoundService
        sound:Play()
        Debris:AddItem(sound, 4)
    end)
end
local function makeFrame(parent, name, size, position, role, radius)
    local f = Instance.new("Frame")
    f.Name = name
    f.Size = size
    if position then f.Position = position end
    f.BackgroundColor3 = theme().surface
    f.BackgroundTransparency = 0
    f.BorderSizePixel = 0
    f.Parent = parent
    if role then style(f, role) end
    if radius then corner(f, radius) end
    return f
end
local function makeLabel(parent, value, size, position, fontSize, role, bold)
    local l = Instance.new("TextLabel")
    l.Name = "MysticsText"
    l.Size = size
    if position then l.Position = position end
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.Text = value
    l.TextColor3 = theme().text
    l.TextSize = fontSize or 12
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.TextWrapped = true
    l.Parent = parent
    style(l, role or "text")
    return l
end
local function makeInput(parent, placeholder, default)
    local field = Instance.new("TextBox")
    field.Size = UDim2.new(1, 0, 0, 42)
    field.BackgroundColor3 = theme().card
    field.BorderSizePixel = 0
    field.Text = default or ""
    field.PlaceholderText = placeholder
    field.PlaceholderColor3 = theme().muted
    field.TextColor3 = theme().text
    field.Font = Enum.Font.GothamMedium
    field.TextSize = 13
    field.TextXAlignment = Enum.TextXAlignment.Left
    field.ClearTextOnFocus = false
    field.Parent = parent
    style(field, "input")
    corner(field, 11)
    stroke(field)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 13)
    pad.PaddingRight = UDim.new(0, 12)
    pad.Parent = field
    return field
end
local function makeButton(parent, value, callback, role, height)
    local b = Instance.new("TextButton")
    b.Name = "MysticsAction"
    b.Size = UDim2.new(1, 0, 0, height or 46)
    b.BackgroundColor3 = theme().card
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Text = value
    b.Font = Enum.Font.GothamBold
    b.TextSize = role == "cta" and 14 or 12
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.TextColor3 = theme().text
    b.Parent = parent
    style(b, role or "card")
    corner(b, 12)
    local outline = stroke(b, role == "cta" and "accentStroke" or "stroke", role == "cta" and 1.5 or 1)
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 16)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = b
    local scale = Instance.new("UIScale")
    scale.Parent = b
    connect(b.MouseEnter, function()
        if State.closed then return end
        tween(scale, TweenInfo.new(0.16), {Scale = 1.014})
        tween(outline, TweenInfo.new(0.16), {Transparency = 0})
    end)
    connect(b.MouseLeave, function()
        if State.closed then return end
        tween(scale, TweenInfo.new(0.16), {Scale = 1})
        tween(outline, TweenInfo.new(0.16), {Transparency = 0.2})
    end)
    connect(b.Activated, function()
        if State.closed then return end
        playClick()
        if callback then
            local ok, err = pcall(callback)
            if not ok then warn("[Mystics LT2] " .. tostring(err)) end
        end
    end)
    return b
end

local Gui = Instance.new("ScreenGui")
Gui.Name = "MysticsLT2_Module"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 999990
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = Parent

local Main = makeFrame(Gui, "MysticsLT2Window",
    UDim2.fromOffset(620, 700), UDim2.new(0.5, -310, 0.5, -350), "base", 22)
Main.ClipsDescendants = true
stroke(Main, "accentStroke", 2)
local mainGradient = Instance.new("UIGradient")
mainGradient.Rotation = 115
mainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 35, 49)),
    ColorSequenceKeypoint.new(0.55, Color3.fromRGB(16, 20, 30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(34, 20, 34))
})
mainGradient.Parent = Main
local mainTopLine = makeFrame(Main, "TopAccent", UDim2.new(1, -34, 0, 3), UDim2.fromOffset(17, 3), "accent", 2)
mainTopLine.ZIndex = 5

local Ambient = makeFrame(Main, "RubyAtmosphere", UDim2.fromOffset(280, 280),
    UDim2.fromOffset(-80, -100), "accent", 110)
Ambient.BackgroundTransparency = 0.96
animateForever(Ambient, 12, {Position = UDim2.fromOffset(120, 0)})

local Header = makeFrame(Main, "MysticsHeader",
    UDim2.new(1, -24, 0, 104), UDim2.fromOffset(12, 12), "surface", 16)
Header.Active = true
stroke(Header)
local headerGradient = Instance.new("UIGradient")
headerGradient.Rotation = 0
headerGradient.Color = ColorSequence.new(theme().surface, theme().card)
headerGradient.Parent = Header
makeLabel(Header, "MYSTICS   /   LUMBER TYCOON 2",
    UDim2.new(1, -150, 0, 34), UDim2.fromOffset(21, 14), 20, "text", true)
makeLabel(Header, "V2.13  •  REFINED INTERFACE",
    UDim2.new(1, -150, 0, 22), UDim2.fromOffset(22, 52), 10, "accentText", true)
local HeaderRule = makeFrame(Header, "HeaderRule",
    UDim2.new(1, -40, 0, 2), UDim2.new(0, 20, 1, -13), "accent", 1)
HeaderRule.BackgroundTransparency = 0.27
local Emblem = makeFrame(Header, "MysticsMonogram",
    UDim2.fromOffset(43, 43), UDim2.new(1, -110, 0, 15), "cta", 20)
stroke(Emblem, "accentStroke", 1.4)
local monogram = makeLabel(Emblem, "M", UDim2.fromScale(1, 1),
    UDim2.fromOffset(0, 0), 23, "text", true)
monogram.TextXAlignment = Enum.TextXAlignment.Center
animateForever(Emblem, 4.5, {Position = UDim2.new(1, -104, 0, 18)})

local CloseButton = makeButton(Header, "×", nil, "quiet", 38)
CloseButton.Name = "CloseLT2"
CloseButton.Size = UDim2.fromOffset(37, 38)
CloseButton.Position = UDim2.new(1, -45, 0, 14)
CloseButton.TextXAlignment = Enum.TextXAlignment.Center
CloseButton.TextSize = 23
local MiniButton = makeButton(Header, "−", nil, "quiet", 34)
MiniButton.Name = "MinimiseLT2"
MiniButton.Size = UDim2.fromOffset(30, 32)
MiniButton.Position = UDim2.new(1, -136, 0, 17)
MiniButton.TextXAlignment = Enum.TextXAlignment.Center
MiniButton.TextSize = 19

local TabBar = makeFrame(Main, "TabBar",
    UDim2.new(1, -24, 0, 48), UDim2.fromOffset(12, 128), "surface", 12)
stroke(TabBar)
local tabPadding = Instance.new("UIPadding")
tabPadding.PaddingLeft = UDim.new(0, 6)
tabPadding.PaddingRight = UDim.new(0, 6)
tabPadding.Parent = TabBar
local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.Padding = UDim.new(0, 5)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = TabBar

local Surface = makeFrame(Main, "PageSurface",
    UDim2.new(1, -24, 1, -220), UDim2.fromOffset(12, 188), "surface", 17)
stroke(Surface)
local pages, tabs = {}, {}
local function createPage(name)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = name .. "Page"
    scroll.Size = UDim2.new(1, -20, 1, -20)
    scroll.Position = UDim2.fromOffset(10, 10)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = theme().accent
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new()
    scroll.Visible = false
    scroll.Parent = Surface
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 7)
    padding.PaddingBottom = UDim.new(0, 17)
    padding.PaddingLeft = UDim.new(0, 4)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = scroll
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 11)
    layout.Parent = scroll
    pages[name] = scroll
    return scroll
end
local function section(page, heading, hint)
    local holder = makeFrame(page, "SectionHeading",
        UDim2.new(1, 0, 0, hint and 63 or 45), nil, "card", 11)
    stroke(holder)
    makeLabel(holder, heading, UDim2.new(1, -26, 0, 22),
        UDim2.fromOffset(13, 7), 13, "text", true)
    if hint then
        makeLabel(holder, hint, UDim2.new(1, -26, 0, 27),
            UDim2.fromOffset(13, 28), 10, "muted", false)
    end
    return holder
end
local function info(page, text, height, role)
    local box = makeFrame(page, "InfoRow",
        UDim2.new(1, 0, 0, height or 52), nil, "card", 11)
    stroke(box)
    local l = makeLabel(box, text, UDim2.new(1, -26, 1, -8),
        UDim2.fromOffset(13, 4), 11, role or "muted", false)
    return l
end
local TAB_NAMES = {"TRAVEL", "WOOD", "PLOTS", "PLAYERS", "TOOLS", "BUILD", "UTILS", "DUPES", "STYLE"}
for index, name in ipairs(TAB_NAMES) do
    createPage(name)
    local tab = makeButton(TabBar, name, function()
        State.selectedTab = name
        for key, p in pairs(pages) do
            p.Visible = (key == name)
        end
        for key, item in pairs(tabs) do
            item.BackgroundColor3 = (key == name) and theme().action or theme().surface
            local tstroke = item:FindFirstChildOfClass("UIStroke")
            if tstroke then tstroke.Transparency = key == name and 0.02 or 0.55 end
        end
    end, "quiet", 32)
    tab.Name = name .. "Tab"
    tab.LayoutOrder = index
    tab.Size = UDim2.fromOffset(58, 36)
    tab.TextSize = 8
    tab.TextXAlignment = Enum.TextXAlignment.Center
    tabs[name] = tab
end
local function showTab(name)
    State.selectedTab = name
    for key, p in pairs(pages) do p.Visible = (key == name) end
    for key, b in pairs(tabs) do
        b.BackgroundColor3 = key == name and theme().action or theme().surface
        local st = b:FindFirstChildOfClass("UIStroke")
        if st then st.Transparency = key == name and 0.02 or 0.55 end
    end
end
local Footer = makeLabel(Main,
    "MYSTICS  •  LT2 CONTROL CENTRE   /   V2.13",
    UDim2.new(1, -34, 0, 20), UDim2.new(0, 17, 1, -28),
    9, "muted", true)

local Toast = makeFrame(Gui, "LT2Toast",
    UDim2.fromOffset(420, 60), UDim2.new(0.5, -210, 0, 24), "card", 12)
Toast.Visible = false
Toast.ZIndex = 80
stroke(Toast, "accentStroke", 1.3)
local ToastText = makeLabel(Toast, "", UDim2.new(1, -28, 1, -12),
    UDim2.fromOffset(14, 6), 12, "text", true)
ToastText.ZIndex = 81
local toastSeq = 0
local function notify(msg)
    if State.closed then return end
    Footer.Text = "MYSTICS  /  " .. string.sub(tostring(msg), 1, 70)
    if not State.notifications then return end
    toastSeq += 1
    local token = toastSeq
    ToastText.Text = tostring(msg)
    Toast.Visible = true
    Toast.Position = UDim2.new(0.5, -210, 0, 7)
    tween(Toast, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -210, 0, 24)})
    task.delay(3.2, function()
        if token == toastSeq and Toast.Parent then
            Toast.Visible = false
        end
    end)
end
local function clearHighlights()
    for _, hl in ipairs(State.woodHighlights) do
        if hl and hl.Parent then hl:Destroy() end
    end
    table.clear(State.woodHighlights)
end
local function cleanup()
    if State.closed then return end
    State.closed = true
    clearHighlights()
    if State.clearToolkitHighlights then pcall(State.clearToolkitHighlights) end
    if State.restoreMovement then pcall(State.restoreMovement) end
    if State.stopSell then pcall(State.stopSell) end
    if State.stopHarvest then pcall(State.stopHarvest) end
    if State.stopAutoCut then pcall(State.stopAutoCut) end
    if State.stopDupeTest then pcall(State.stopDupeTest) end
    if State.restoreLighting then pcall(State.restoreLighting) end
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    if State.ferryConnection then pcall(function() State.ferryConnection:Disconnect() end) end
    for _, t in ipairs(Tweens) do pcall(function() t:Cancel() end) end
    if Gui.Parent then Gui:Destroy() end
    if getgenv then
        pcall(function()
            if getgenv().MysticsLT2Cleanup == cleanup then
                getgenv().MysticsLT2Cleanup = nil
            end
        end)
    end
end
connect(CloseButton.Activated, cleanup)
connect(MiniButton.Activated, function()
    State.minimised = not State.minimised
    TabBar.Visible = not State.minimised
    Surface.Visible = not State.minimised
    Footer.Visible = not State.minimised
    MiniButton.Text = State.minimised and "+" or "−"
    tween(Main, TweenInfo.new(0.28, Enum.EasingStyle.Quint),
        {Size = State.minimised and UDim2.fromOffset(526, 115) or UDim2.fromOffset(526, 618)})
end)
if getgenv then pcall(function() getgenv().MysticsLT2Cleanup = cleanup end) end

-- Header-only dragging avoids the old deprecated GUI.Draggable behaviour.
local dragging, dragInput, startPos, startMouse = false, nil, nil, nil
connect(Header.InputBegan, function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
    dragging = true
    startMouse = input.Position
    startPos = Main.Position
    dragInput = input
end)
connect(UserInputService.InputChanged, function(input)
    if not dragging or not startMouse or not startPos then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input ~= dragInput then return end
    local d = input.Position - startMouse
    Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
        startPos.Y.Scale, startPos.Y.Offset + d.Y)
end)
connect(UserInputService.InputEnded, function(input)
    if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
local Scale = Instance.new("UIScale")
Scale.Parent = Main
local function resizeForScreen()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    Scale.Scale = math.clamp(math.min(
        cam.ViewportSize.X / 556, cam.ViewportSize.Y / 674, 1
    ), 0.58, 1)
end
resizeForScreen()
local camera = Workspace.CurrentCamera
if camera then connect(camera:GetPropertyChangedSignal("ViewportSize"), resizeForScreen) end

-- Historical navigation coordinates retained for convenience.
-- They are NOT validated for the current live map.
local HistoricalLocations = {
    {name="Wood R Us", pos=Vector3.new(265,3,57)},
    {name="Spawn", pos=Vector3.new(155,3,74)},
    {name="Land Store", pos=Vector3.new(258,3,-99)},
    {name="Link's Logic", pos=Vector3.new(4607,7.5,-798)},
    {name="Cave", pos=Vector3.new(3581,-179,430)},
    {name="Volcano", pos=Vector3.new(-1585,622,1140)},
    {name="Swamp", pos=Vector3.new(-1209,132,-801)},
    {name="Palm Island", pos=Vector3.new(2549,-5,-42)},
    {name="Fancy Furnishings", pos=Vector3.new(491,3,-1720)},
    {name="Boxed Cars", pos=Vector3.new(509,5.2,-1463)},
    {name="Fine Arts Shop", pos=Vector3.new(5207,-166,719)},
    {name="Bob's Shack", pos=Vector3.new(260,8,-2542)},
    {name="Strange Man", pos=Vector3.new(1061,16,1131)},
    {name="Dock", pos=Vector3.new(1114,3.2,-197)},
    {name="Bridge", pos=Vector3.new(113,15,-977)},
    {name="End Times", pos=Vector3.new(113,-204,-951)},
    {name="Shrine Of Sight", pos=Vector3.new(-1600,205,919)},
    {name="The Den", pos=Vector3.new(323,49,1930)},
    {name="Volcano Win", pos=Vector3.new(-1675,358,1476)},
    {name="Ski Lodge", pos=Vector3.new(1244,66,2306)},
    {name="Frost Tree", pos=Vector3.new(1448.3,413,3185.2)},
    {name="SnowGlow Tree", pos=Vector3.new(-1105.9,-6,-894)}
}
local function gameLooksLikeLT2()
    return Workspace:FindFirstChild("Properties") ~= nil
        or Workspace:FindFirstChild("PlayerModels") ~= nil
end
local function moveTo(pos, label, restore)
    if not gameLooksLikeLT2() then
        notify("LT2 world structures not found; teleport cancelled.")
        return
    end
    if os.clock() - State.lastTeleport < 0.65 then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then
        notify("Character isn't ready for teleport.")
        return
    end
    if typeof(pos) ~= "Vector3" then return end
    if not (pos.X == pos.X and pos.Y == pos.Y and pos.Z == pos.Z)
        or pos.Magnitude > 500000 then
        notify("Invalid destination coordinates.")
        return
    end
    if not restore then State.returnCFrame = root.CFrame end
    State.lastTeleport = os.clock()
    local ok, err = pcall(function()
        char:PivotTo(CFrame.new(pos + Vector3.new(0, 5, 0)))
    end)
    if ok then
        notify("Local teleport requested: " .. tostring(label) .. " (game may correct it).")
    else
        warn("[Mystics LT2] Teleport failed: " .. tostring(err))
        notify("Unable to move character.")
    end
end
local Travel = pages.TRAVEL
section(Travel, "WAYPOINT NAVIGATOR",
    "Historical coordinates. Check destinations before relying on them.")
local SearchTravel = makeInput(Travel, "Search places...", "")
local ReturnButton = makeButton(Travel, "RETURN TO PREVIOUS POSITION", function()
    if not State.returnCFrame then
        notify("No previous position saved yet.")
    else
        moveTo(State.returnCFrame.Position - Vector3.new(0,5,0), "previous position", true)
    end
end, "cta", 48)
local LocationGrid = makeFrame(Travel, "WaypointGrid",
    UDim2.new(1, 0, 0, 0), nil, nil, nil)
LocationGrid.BackgroundTransparency = 1
local grid = Instance.new("UIGridLayout")
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.CellSize = UDim2.new(0.5, -6, 0, 43)
grid.CellPadding = UDim2.fromOffset(10, 9)
grid.Parent = LocationGrid
local destinationButtons = {}
for idx, place in ipairs(HistoricalLocations) do
    local item = place
    local b = makeButton(LocationGrid, item.name, function()
        moveTo(item.pos, item.name, false)
    end, "card", 43)
    b.LayoutOrder = idx
    b.TextSize = 11
    destinationButtons[#destinationButtons + 1] = {button=b, name=string.lower(item.name)}
end
local function filterWaypoints()
    local query = string.lower(SearchTravel.Text)
    local shown = 0
    for _, item in ipairs(destinationButtons) do
        local visible = query == "" or string.find(item.name, query, 1, true) ~= nil
        item.button.Visible = visible
        if visible then shown += 1 end
    end
    LocationGrid.Size = UDim2.new(1, 0, 0, math.max(0,
        math.ceil(shown/2) * 52))
end
connect(SearchTravel:GetPropertyChangedSignal("Text"), filterWaypoints)
filterWaypoints()
section(Travel, "PERSONAL WAYPOINTS", "Saved positions are session-only.")
local WaypointName = makeInput(Travel, "Location name", "My spot")
local CustomGrid = makeFrame(Travel, "PersonalWaypoints",
    UDim2.new(1,0,0,0), nil, nil, nil)
CustomGrid.BackgroundTransparency = 1
local customLayout = Instance.new("UIListLayout")
customLayout.Padding = UDim.new(0, 8)
customLayout.Parent = CustomGrid
local function renderCustom()
    for _, child in ipairs(CustomGrid:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local count = 0
    for _, location in ipairs(State.customLocations) do
        local saved = location
        count += 1
        makeButton(CustomGrid, saved.name .. "  /  GO", function()
            moveTo(saved.pos, saved.name, false)
        end, "quiet", 42)
    end
    CustomGrid.Size = UDim2.new(1, 0, 0, count * 50)
end
makeButton(Travel, "SAVE CURRENT POSITION", function()
    local name = WaypointName.Text:match("^%s*(.-)%s*$")
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then notify("Character position is unavailable."); return end
    if name == "" or #name > 30 then notify("Enter a name up to 30 characters."); return end
    for _, place in ipairs(State.customLocations) do
        if string.lower(place.name) == string.lower(name) then
            place.pos = root.Position
            renderCustom()
            notify("Updated waypoint: " .. name)
            return
        end
    end
    if #State.customLocations >= 15 then notify("Limit: 15 saved positions per session."); return end
    table.insert(State.customLocations, {name = name, pos = root.Position})
    renderCustom()
    notify("Saved current position: " .. name)
end, "cta")

-- Local-only lumber inspector. LT2 usually stores loose wood as "Loose_..."
-- in Workspace.LogModels, and milled "Plank" models in PlayerModels.
-- Do not label unowned items as owned or modify any server object/remotes.
local function ownerIsLocal(value)
    if value == LocalPlayer or value == LocalPlayer.UserId or value == LocalPlayer.Name then
        return true
    end
    if type(value) == "number" then return value == LocalPlayer.UserId end
    if type(value) == "string" then
        local name = string.lower(value)
        return name == string.lower(LocalPlayer.Name)
            or name == tostring(LocalPlayer.UserId)
    end
    return false
end
local function readOwnerValue(obj)
    local owner = obj:FindFirstChild("Owner")
    if not owner then
        -- Occasionally an ownership value is stored within a nested model.
        owner = obj:FindFirstChild("Owner", true)
    end
    if owner and owner:IsA("ValueBase") then
        return owner.Value, true
    end
    for _, attr in ipairs({"OwnerUserId", "OwnerId", "OwnerName", "Owner"}) do
        local value = obj:GetAttribute(attr)
        if value ~= nil then return value, true end
    end
    return nil, false
end
local function belongsToLocal(obj)
    local value, exists = readOwnerValue(obj)
    return exists and ownerIsLocal(value)
end
local function findOwnedObjects()
    local found, seen = {}, {}
    local stats = {
        scanned = 0, woodModels = 0, withOwner = 0,
        ownedWood = 0, logs = 0, planks = 0,
        roots = {}, truncated = false
    }
    local rootNames = {"LogModels", "PlayerModels", "WoodModels", "PlankModels"}

    local function inspect(obj, rootName)
        if seen[obj] or not (obj:IsA("Model") or obj:IsA("BasePart")) then return end
        seen[obj] = true
        local lowerName = string.lower(obj.Name)
        local isLog = rootName == "LogModels" and (
            string.sub(obj.Name, 1, 6) == "Loose_" or
            obj:FindFirstChild("WoodSection") ~= nil or
            obj:FindFirstChild("TreeClass") ~= nil
        )
        local isPlank = lowerName == "plank" or
            (rootName == "PlankModels" and obj:IsA("Model"))
        local isWood = isLog or isPlank
            or string.find(lowerName, "wood", 1, true) ~= nil
            or string.find(lowerName, "log", 1, true) ~= nil
            or (rootName == "PlayerModels" and (
                obj:FindFirstChild("WoodSection") ~= nil or
                obj:FindFirstChild("TreeClass") ~= nil
            ))
        if not isWood then return end

        stats.woodModels += 1
        local value, hasOwner = readOwnerValue(obj)
        if hasOwner and value ~= nil then stats.withOwner += 1 end
        if not hasOwner or not ownerIsLocal(value) then return end

        -- A highlight cannot render if there is no geometry in the model.
        local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
        if not part then return end
        stats.ownedWood += 1
        local kind = isPlank and "PLANK" or (isLog and "LOG" or "WOOD")
        if kind == "PLANK" then stats.planks += 1
        elseif kind == "LOG" then stats.logs += 1 end
        local class = obj:FindFirstChild("TreeClass") or obj:FindFirstChild("ItemName")
        local species = class and class:IsA("ValueBase") and tostring(class.Value) or ""
        if species == "" or species == "nil" then species = obj.Name end
        table.insert(found, {
            model = obj, kind = kind,
            name = kind .. "  /  " .. string.sub(species, 1, 42)
        })
    end

    -- Bounded per root, with no workspace-wide descendant scan.
    for _, name in ipairs(rootNames) do
        local root = Workspace:FindFirstChild(name)
        if root then
            stats.roots[#stats.roots + 1] = name
            local children = root:GetChildren()
            for i, obj in ipairs(children) do
                if i > 2200 then stats.truncated = true; break end
                stats.scanned += 1
                if obj:IsA("Folder") then
                    for j, nested in ipairs(obj:GetChildren()) do
                        if j > 700 then stats.truncated = true; break end
                        stats.scanned += 1
                        inspect(nested, name)
                    end
                else
                    inspect(obj, name)
                end
            end
        end
    end
    return found, stats
end

local Wood = pages.WOOD
section(Wood, "LUMBER INSPECTOR",
    "Detects your Loose_ logs and Plank models by ownership.")
local WoodCount = info(Wood, "OWNED LOGS  /  --      PLANKS  /  --", 53, "text")
local WoodDescription = info(Wood,
    "Your owned wood types will appear here after a scan.", 82)
local WoodDiagnostics = info(Wood,
    "SCAN STATUS  /  NOT RUN", 79, "muted")
local HighlightButton
local WoodLastResults = {}
local WoodLastStats = {}

-- Keep local highlights outside item models to avoid nested render issues.
-- Limit them to a small number for low-end devices.
local function applyWoodHighlights()
    clearHighlights()
    local count = 0
    for _, entry in ipairs(WoodLastResults) do
        if count >= 30 then break end
        local obj = entry.model
        if obj and obj.Parent then
            local ok, hl = pcall(function()
                local marker = Instance.new("Highlight")
                marker.Name = "MysticsLT2OwnedWoodOutline"
                marker.Adornee = obj
                marker.Enabled = true
                marker.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                marker.FillColor = theme().accent
                marker.OutlineColor = theme().light
                marker.FillTransparency = 0.58
                marker.OutlineTransparency = 0
                marker.Parent = Workspace.CurrentCamera or Workspace
                return marker
            end)
            if ok and hl then
                table.insert(State.woodHighlights, hl)
                count += 1
            end
        end
    end
    return count
end
local function refreshWood()
    local found, stats = findOwnedObjects()
    WoodLastResults, WoodLastStats = found, stats
    WoodCount.Text = string.format(
        "OWNED LOGS  /  %d      PLANKS  /  %d      TOTAL  /  %d",
        stats.logs, stats.planks, #found
    )
    local names = {}
    for i = 1, math.min(6, #found) do names[i] = found[i].name end
    WoodDescription.Text = #names > 0 and table.concat(names, "\n")
        or "No owned wood found. Check the diagnostics below."
    local roots = #stats.roots > 0 and table.concat(stats.roots, ", ")
        or "NONE"
    WoodDiagnostics.Text = string.format(
        "FOLDERS: %s\nWOOD CANDIDATES: %d  •  WITH OWNER: %d\nSCANNED: %d%s",
        roots, stats.woodModels, stats.withOwner, stats.scanned,
        stats.truncated and "  (limited)" or ""
    )
    if State.woodHighlightEnabled then
        local count = applyWoodHighlights()
        if HighlightButton then
            HighlightButton.Text = "OWNED WOOD OUTLINES: ON  (" .. tostring(count) .. ")"
        end
    end
    return found, stats
end

makeButton(Wood, "REFRESH WOOD INVENTORY", function()
    local found, stats = refreshWood()
    if #found == 0 then
        notify("No owned wood detected. Check scan diagnostics and model ownership.")
    else
        notify("Found " .. #found .. " owned logs/planks.")
    end
end, "cta")
HighlightButton = makeButton(Wood, "OWNED WOOD OUTLINES: OFF", function()
    State.woodHighlightEnabled = not State.woodHighlightEnabled
    if State.woodHighlightEnabled then
        local found = refreshWood()
        local count = #State.woodHighlights
        HighlightButton.Text = "OWNED WOOD OUTLINES: ON  (" .. count .. ")"
        if count == 0 then
            notify("Nothing to outline yet. Inspect the diagnostic counts.")
        else
            notify("Highlighted " .. count .. " owned wood models.")
        end
    else
        clearHighlights()
        HighlightButton.Text = "OWNED WOOD OUTLINES: OFF"
        notify("Wood outlines disabled.")
    end
end, "card")
-- Recheck owned wood when fresh logs or planks appear. Debounce bursts from
-- tree chopping; the feature is completely idle when outlining is off.
local woodRefreshScheduled = false
local function scheduleWoodRefresh()
    if State.closed or not State.woodHighlightEnabled or woodRefreshScheduled then return end
    woodRefreshScheduled = true
    task.delay(0.45, function()
        woodRefreshScheduled = false
        if not State.closed and State.woodHighlightEnabled then
            refreshWood()
        end
    end)
end
for _, folderName in ipairs({"LogModels", "PlayerModels"}) do
    local folder = Workspace:FindFirstChild(folderName)
    if folder then
        connect(folder.ChildAdded, scheduleWoodRefresh)
        connect(folder.ChildRemoved, scheduleWoodRefresh)
    end
end
info(Wood, "Outlines are client-side only. If owned logs lose ownership or the game stops replicating a model, they cannot be counted reliably.", 82)
section(Wood, "WOOD DEBUGGER", "Arm the picker, then click a log or plank in the world.")
local AimedWoodInfo = info(Wood, "AIMED MODEL  /  NOT INSPECTED", 72)
local WoodPickActive = false
local woodMouse = LocalPlayer:GetMouse()
local function inspectWoodTarget(target)
    if not target then
        AimedWoodInfo.Text = "No visible part targeted. Aim at a log or plank and retry."
        return
    end
    local candidate = target
    local validRoot = {LogModels=true, PlayerModels=true, WoodModels=true, PlankModels=true}
    while candidate and candidate ~= Workspace do
        if candidate.Parent and validRoot[candidate.Parent.Name] then break end
        candidate = candidate.Parent
    end
    if not candidate or candidate == Workspace then
        AimedWoodInfo.Text = "Target not in recognised wood folders: " ..
            string.sub(target.Name, 1, 35)
        return
    end
    local value, hasOwner = readOwnerValue(candidate)
    local status = not hasOwner and "NO OWNER FIELD" or
        (ownerIsLocal(value) and "OWNED BY YOU" or "OTHER/UNASSIGNED")
    AimedWoodInfo.Text = "MODEL: " .. string.sub(candidate.Name, 1, 35) ..
        "\nFOLDER: " .. candidate.Parent.Name .. "   /   " .. status
    notify("Wood model: " .. status)
end
local WoodPickButton
WoodPickButton = makeButton(Wood, "PICK WOOD MODEL", function()
    WoodPickActive = not WoodPickActive
    WoodPickButton.Text = WoodPickActive and "CANCEL WOOD PICK" or "PICK WOOD MODEL"
    if WoodPickActive then
        AimedWoodInfo.Text = "Picker active. Click on a log or plank in the world."
    end
end, "quiet")
connect(woodMouse.Button1Down, function()
    if not WoodPickActive or State.closed then return end
    -- A click on the 3D world supplies the correct target; toggling the
    -- button itself does not re-use the button's screen position.
    WoodPickActive = false
    WoodPickButton.Text = "PICK WOOD MODEL"
    inspectWoodTarget(woodMouse.Target)
end)
-- Plot inspection is deliberately read-only except for optional local TP.
local Plots = pages.PLOTS
section(Plots, "PLOT INSPECTOR", "Ownership is checked before any plot destination is offered.")
local PlotSummary = info(Plots, "OWNED PLOT  /  NOT SCANNED", 59, "text")
local PlotExtra = info(Plots, "Plot data comes from Workspace.Properties when available.", 64)
local myPlot = nil
local function scanPlots()
    myPlot = nil
    local folder = Workspace:FindFirstChild("Properties")
    if not folder then
        PlotSummary.Text = "PLOT DATA  /  UNAVAILABLE"
        PlotExtra.Text = "Workspace.Properties was not found. The game may have changed."
        return
    end
    local total = 0
    for _, plot in ipairs(folder:GetChildren()) do
        total += 1
        if belongsToLocal(plot) then myPlot = plot; break end
    end
    if myPlot then
        local square = myPlot:FindFirstChild("OriginSquare")
        PlotSummary.Text = "YOUR PLOT  /  " .. myPlot.Name
        PlotExtra.Text = square and ("LOCATION  /  " ..
            tostring(math.floor(square.Position.X)) .. ", " ..
            tostring(math.floor(square.Position.Y)) .. ", " ..
            tostring(math.floor(square.Position.Z)))
            or "Plot found; OriginSquare is unavailable."
    else
        PlotSummary.Text = "YOUR PLOT  /  NOT DETECTED"
        PlotExtra.Text = "Checked " .. total .. " plots. No locally owned plot found."
    end
end
makeButton(Plots, "SCAN MY PLOT", scanPlots, "cta")
makeButton(Plots, "TRAVEL TO MY PLOT", function()
    scanPlots()
    local square = myPlot and myPlot:FindFirstChild("OriginSquare")
    if square and square:IsA("BasePart") then
        moveTo(square.Position + Vector3.new(0, 5, 0), "my plot", false)
    else
        notify("No owned plot destination available.")
    end
end, "card")
info(Plots, "This module will not wipe bases, copy other players' structures, or modify save slots.", 70)

-- Live roster, no fixed six-player limit or uncontrolled polling.
local PlayersPage = pages.PLAYERS
section(PlayersPage, "PLAYER NAVIGATION", "Select a player, then choose where to travel.")
local PlayerSearch = makeInput(PlayersPage, "Search players...", "")
local SelectedLabel = info(PlayersPage, "SELECTED PLAYER  /  NONE", 52, "text")
makeButton(PlayersPage, "TRAVEL TO SELECTED PLAYER", function()
    local target = State.selectedPlayer
    if not target or not target.Parent then notify("Choose a player first."); return end
    local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if root then moveTo(root.Position + Vector3.new(3,0,0), target.Name, false)
    else notify("Target character isn't loaded.") end
end, "cta")
makeButton(PlayersPage, "TRAVEL TO SELECTED PLOT", function()
    local target = State.selectedPlayer
    if not target or not target.Parent then notify("Choose a player first."); return end
    local folder = Workspace:FindFirstChild("Properties")
    if not folder then notify("Plot information isn't available."); return end
    for _, plot in ipairs(folder:GetChildren()) do
        local owner = plot:FindFirstChild("Owner")
        local square = plot:FindFirstChild("OriginSquare")
        if owner and (owner.Value == target or owner.Value == target.Name)
            and square and square:IsA("BasePart") then
            moveTo(square.Position + Vector3.new(0,5,0), target.Name .. "'s plot", false)
            return
        end
    end
    notify("That player's plot wasn't found.")
end, "quiet")
local PlayerRows = makeFrame(PlayersPage, "LivePlayerRoster",
    UDim2.new(1,0,0,0), nil, nil, nil)
PlayerRows.BackgroundTransparency = 1
local playerLayout = Instance.new("UIListLayout")
playerLayout.SortOrder = Enum.SortOrder.LayoutOrder
playerLayout.Padding = UDim.new(0, 8)
playerLayout.Parent = PlayerRows
-- Cache one button per player. Filtering only toggles visibility, avoiding
-- repeated connections and object churn on every search keystroke.
local rosterButtons = {}
local function renderPlayers()
    local filter = string.lower(PlayerSearch.Text)
    local players = Players:GetPlayers()
    local present = {}
    table.sort(players, function(a,b) return a.Name < b.Name end)
    local row = 0
    for _, player in ipairs(players) do
        present[player] = true
        local item = rosterButtons[player]
        if not item then
            local chosen = player
            local label = player.DisplayName == player.Name and player.Name
                or (player.DisplayName .. "  (@" .. player.Name .. ")")
            if player == LocalPlayer then label = label .. "  •  YOU" end
            item = makeButton(PlayerRows, label, function()
                State.selectedPlayer = chosen
                SelectedLabel.Text = "SELECTED PLAYER  /  " .. chosen.Name
            end, "card", 42)
            rosterButtons[player] = item
        end
        local visible = string.find(string.lower(player.Name .. " " .. player.DisplayName),
            filter, 1, true) ~= nil
        item.Visible = visible
        if visible then
            row += 1
            item.LayoutOrder = row
        end
    end
    for player, button in pairs(rosterButtons) do
        if not present[player] then
            if button.Parent then button:Destroy() end
            rosterButtons[player] = nil
        end
    end
    PlayerRows.Size = UDim2.new(1, 0, 0, row * 50)
end
connect(PlayerSearch:GetPropertyChangedSignal("Text"), renderPlayers)
connect(Players.PlayerAdded, function(p)
    renderPlayers()
    if State.notifications then notify(p.Name .. " joined.") end
end)
connect(Players.PlayerRemoving, function(p)
    if State.selectedPlayer == p then
        State.selectedPlayer = nil
        SelectedLabel.Text = "SELECTED PLAYER  /  NONE"
    end
    task.defer(renderPlayers)
    if State.notifications then notify(p.Name .. " left.") end
end)
renderPlayers()

local Utils = pages.UTILS
section(Utils, "WORLD STATUS", "Lightweight live information; no automation loops.")
local FerryText = info(Utils, "FERRY  /  NOT CONNECTED", 52, "text")
local WorldText = info(Utils, "WORLD  /  CHECKING", 58)
local FerryAlertsEnabled = false
local FerryAlertsButton
local lastFerrySeconds
local function refreshFerry()
    if State.ferryConnection then
        State.ferryConnection:Disconnect()
        State.ferryConnection = nil
    end
    lastFerrySeconds = nil
    local ferry = Workspace:FindFirstChild("Ferry")
    local value = ferry and (ferry:FindFirstChild("TimeToDeparture")
        or ferry:FindFirstChild("TimeToDeparture", true))
    if value and value:IsA("ValueBase") then
        local function update()
            if State.closed then return end
            local seconds = tonumber(value.Value)
            FerryText.Text = "FERRY DEPARTURE  /  " ..
                (seconds and (tostring(math.max(0, math.floor(seconds))) .. " SECONDS")
                    or tostring(value.Value))
            if FerryAlertsEnabled and seconds and seconds <= 0
                and lastFerrySeconds and lastFerrySeconds > 0 then
                notify("Ferry countdown reached zero.")
            end
            lastFerrySeconds = seconds
        end
        update()
        State.ferryConnection = value:GetPropertyChangedSignal("Value"):Connect(update)
    else
        FerryText.Text = "FERRY  /  TIMER UNAVAILABLE"
    end
end
FerryAlertsButton = makeButton(Utils, "FERRY DEPARTURE ALERT: OFF", function()
    FerryAlertsEnabled = not FerryAlertsEnabled
    FerryAlertsButton.Text = FerryAlertsEnabled
        and "FERRY DEPARTURE ALERT: ON" or "FERRY DEPARTURE ALERT: OFF"
    notify("Ferry alert " .. (FerryAlertsEnabled and "enabled." or "disabled."))
end, "card")
makeButton(Utils, "TRAVEL TO HISTORICAL FERRY DOCK", function()
    moveTo(Vector3.new(1114, 3.2, -197), "historical ferry dock", false)
end, "quiet")
connect(Workspace.ChildAdded, function(child)
    if child.Name == "Ferry" then task.defer(refreshFerry) end
end)
local function refreshWorld()
    WorldText.Text = gameLooksLikeLT2()
        and "WORLD DETECTED  /  LT2-TYPE STRUCTURES FOUND"
        or "WORLD WARNING  /  EXPECTED LT2 STRUCTURES MISSING"
    refreshFerry()
end
makeButton(Utils, "REFRESH WORLD STATUS", refreshWorld, "cta")
info(Utils, "Ferry and navigation tools use local replicated game information. Availability depends on the current server and game version.", 90)
section(Utils, "RELIABILITY", "No permanent refresh loops or hidden web dependencies.")
local UtilityState = info(Utils,
    "PLAYER LIST  /  EVENT DRIVEN\nWOOD / PLOT  /  MANUAL REFRESH\nLOADER  /  PINNED GITHUB RELEASE", 90)
UtilityState.TextYAlignment = Enum.TextYAlignment.Center

-- Local inventory, money and lighting tools do not depend on experimental tests.
section(Utils, "BACKPACK & SAVE READOUT",
    "Display local tool counts and currently replicated status.")
local InventoryInfo = info(Utils, "BACKPACK  /  NOT SCANNED", 84, "text")
local BalanceInfo = info(Utils, "MONEY  /  NOT SCANNED", 82, "text")
local function moneyObject()
    local folder = LocalPlayer:FindFirstChild("leaderstats")
    local money = folder and folder:FindFirstChild("Money")
    return money and money:IsA("ValueBase") and money or nil
end
local function getMoney()
    local obj = moneyObject()
    return obj and tonumber(obj.Value) or nil
end
local function updateInventory()
    local bag = LocalPlayer:FindFirstChildOfClass("Backpack")
    local character = LocalPlayer.Character
    local equipped, backpack = 0, 0
    local kinds = {}
    local function scan(root, isEquipped)
        if not root then return end
        for _, child in ipairs(root:GetChildren()) do
            if child:IsA("Tool") then
                if isEquipped then equipped += 1 else backpack += 1 end
                local item = child:FindFirstChild("ItemName")
                kinds[#kinds + 1] = item and item:IsA("ValueBase") and
                    tostring(item.Value) or child.Name
            end
        end
    end
    scan(bag, false)
    scan(character, true)
    InventoryInfo.Text = string.format(
        "TOOLS IN BACKPACK: %d  •  EQUIPPED: %d\n%s",
        backpack, equipped,
        #kinds > 0 and table.concat({unpack(kinds, 1, math.min(4, #kinds))}, "  /  ")
            or "No tools visible"
    )
    local slot = LocalPlayer:FindFirstChild("CurrentSaveSlot")
    local saving = LocalPlayer:FindFirstChild("CurrentlySavingOrLoading")
    local cash = getMoney()
    BalanceInfo.Text = string.format("MONEY: %s\nSAVE SLOT: %s  •  BUSY: %s",
        cash and tostring(cash) or "Unavailable",
        slot and tostring(slot.Value) or "Unavailable",
        saving and tostring(saving.Value) or "Unknown"
    )
end
makeButton(Utils, "REFRESH MY TOOLS & MONEY", updateInventory, "cta")
section(Utils, "PERSONAL VISIBILITY", "Local-only lighting changes; restore at any time.")
local defaultLighting = {
    FogStart=Lighting.FogStart,
    FogEnd=Lighting.FogEnd,
    Brightness=Lighting.Brightness,
    ClockTime=Lighting.ClockTime,
    GlobalShadows=Lighting.GlobalShadows
}
State.forceDay = false
State.noFog = false
local function applyLighting()
    if State.forceDay then
        Lighting.Brightness = 3.2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = defaultLighting.Brightness
        Lighting.ClockTime = defaultLighting.ClockTime
        Lighting.GlobalShadows = defaultLighting.GlobalShadows
    end
    if State.noFog then
        Lighting.FogStart = 100000
        Lighting.FogEnd = 100000
    else
        Lighting.FogStart = defaultLighting.FogStart
        Lighting.FogEnd = defaultLighting.FogEnd
    end
end
State.restoreLighting = function()
    State.forceDay = false
    State.noFog = false
    pcall(applyLighting)
end
local DayToggle
DayToggle = makeButton(Utils, "FULLBRIGHT DAY: OFF", function()
    State.forceDay = not State.forceDay
    applyLighting()
    DayToggle.Text = "FULLBRIGHT DAY: " .. (State.forceDay and "ON" or "OFF")
end, "card")
local FogToggle
FogToggle = makeButton(Utils, "REMOVE FOG: OFF", function()
    State.noFog = not State.noFog
    applyLighting()
    FogToggle.Text = "REMOVE FOG: " .. (State.noFog and "ON" or "OFF")
end, "card")
makeButton(Utils, "RESTORE ORIGINAL LIGHTING", function()
    State.restoreLighting()
    DayToggle.Text = "FULLBRIGHT DAY: OFF"
    FogToggle.Text = "REMOVE FOG: OFF"
    notify("Original local lighting restored.")
end, "quiet")
updateInventory()

-- LEGACY DUPE LAB / Experimental and reversible where possible.
-- Unverified in the current game. Run only with disposable saves/money.
local Dupes = pages.DUPES
section(Dupes, "LEGACY DUPE LAB", "Old methods; NOT verified in 2026.")
info(Dupes, "Item mode changes the local CurrentSaveSlot to -1. Money mode sends a limited self-donation. Both can be patched and can cause lost progress or money. Neither runs automatically.", 129)
local SaveReport = info(Dupes, "SAVE STATUS  /  NOT CHECKED", 75, "text")
local function dupeSaveValues()
    return LocalPlayer:FindFirstChild("CurrentSaveSlot"),
        LocalPlayer:FindFirstChild("CurrentlySavingOrLoading")
end
local function dupeSaving()
    local slot, busy = dupeSaveValues()
    return not slot or not slot:IsA("ValueBase") or
        (busy and busy:IsA("ValueBase") and busy.Value == true)
end
local function updateDupeReadout()
    local slot, busy = dupeSaveValues()
    SaveReport.Text = "SLOT: " .. (slot and tostring(slot.Value) or "MISSING") ..
        "\nSAVING/LOADING: " .. (busy and tostring(busy.Value) or "UNKNOWN") ..
        "\nNO SERVER-SIDE SAVE ASSURANCE"
end
makeButton(Dupes, "REFRESH SLOT / MONEY STATUS", function()
    updateDupeReadout()
    updateInventory()
end, "quiet")
section(Dupes, "ITEM DUPLICATION TEST", "A bounded 10-second legacy slot experiment.")
info(Dupes, "WARNING: Old slot suppression may prevent saving or do nothing. Do not run on a save you cannot afford to lose.", 82)
local ItemRiskInput = makeInput(Dupes, "Type RISK to unlock", "")
local ItemResult = info(Dupes, "ITEM TEST  /  IDLE", 58, "text")
local ItemButton
local ItemArmedExpiry = 0
local ItemActive = false
local OriginalSlot = nil
local SlotObject = nil
local ItemSerial = 0
local function stopItemTest()
    ItemActive = false
    ItemSerial += 1
    if SlotObject and SlotObject.Parent and OriginalSlot ~= nil
        and SlotObject.Value == -1 then
        pcall(function() SlotObject.Value = OriginalSlot end)
    end
    SlotObject, OriginalSlot = nil, nil
    ItemArmedExpiry = 0
    if ItemButton and ItemButton.Parent then
        ItemButton.Text = "BEGIN LEGACY ITEM DUPE TEST"
    end
    if ItemResult and ItemResult.Parent then
        ItemResult.Text = "ITEM TEST  /  STOPPED. Check save and inventory."
    end
end
State.stopDupeTest = stopItemTest
ItemButton = makeButton(Dupes, "BEGIN LEGACY ITEM DUPE TEST", function()
    if ItemActive then
        stopItemTest()
        notify("Item test stopped and local slot restored where possible.")
        return
    end
    if string.upper(ItemRiskInput.Text:match("^%s*(.-)%s*$")) ~= "RISK" then
        notify("Type RISK to acknowledge that progress can be lost.")
        return
    end
    if not gameLooksLikeLT2() then notify("LT2 structures not detected."); return end
    local slot = LocalPlayer:FindFirstChild("CurrentSaveSlot")
    if dupeSaving() or not slot or type(slot.Value) ~= "number" or slot.Value < 0 then
        notify("Load a save and wait until save/load is idle.")
        updateDupeReadout()
        return
    end
    if os.clock() > ItemArmedExpiry then
        ItemArmedExpiry = os.clock() + 12
        ItemButton.Text = "CONFIRM 10-SECOND ITEM TEST"
        ItemResult.Text = "ARMED  /  Click again within 12s; progress at risk."
        return
    end
    SlotObject, OriginalSlot = slot, slot.Value
    ItemArmedExpiry = 0
    ItemActive = true
    ItemSerial += 1
    local serial = ItemSerial
    ItemButton.Text = "STOP & RESTORE SLOT"
    ItemResult.Text = "RUNNING  /  Local save slot temporarily set to -1"
    task.spawn(function()
        for i = 1, 20 do
            if State.closed or not ItemActive or serial ~= ItemSerial then break end
            local _, saving = dupeSaveValues()
            if not slot.Parent or
                (slot.Value ~= -1 and slot.Value ~= OriginalSlot) or
                (saving and saving:IsA("ValueBase") and saving.Value == true) then
                break
            end
            local ok = pcall(function() slot.Value = -1 end)
            if not ok then break end
            task.wait(0.5)
        end
        if not State.closed and serial == ItemSerial then
            stopItemTest()
            updateDupeReadout()
            notify("Item experiment complete. No dupe confirmed; inspect saved items.")
        end
    end)
end, "cta", 52)
info(Dupes, "The old method is local-only and cannot guarantee server persistence. Auto-stops after 10 seconds and attempts to restore the original slot value.", 92)

-- The only verified historical money call is Donate:InvokeServer(
-- LocalPlayer, fullBalance, 1). To limit risk, this experiment sends a
-- SMALL user-entered amount (max 100 or 2% of visible balance), once.
section(Dupes, "MONEY DUPLICATION TEST", "One capped legacy self-donation; unverified.")
info(Dupes, "WARNING: This might permanently deduct the amount, fail, or do nothing. No guaranteed refund. Never use the full balance; try only with disposable game currency.", 105)
local MoneyAmount = makeInput(Dupes, "Amount: 1-100, maximum 2% of balance", "1")
local MoneyRiskInput = makeInput(Dupes, "Type SEND to unlock", "")
local MoneyResult = info(Dupes, "MONEY TEST  /  IDLE", 92, "text")
local MoneyButton
local MoneyArmedExpiry = 0
local MoneyArmedAmount = nil
local MoneyTestBusy = false
local LastMoneyTest = -1000
MoneyButton = makeButton(Dupes, "BEGIN LEGACY MONEY DUPE TEST", function()
    if MoneyTestBusy then notify("Previous test still waiting on server."); return end
    if os.clock() - LastMoneyTest < 90 then
        notify("Money test cooldown: wait 90 seconds."); return
    end
    if not gameLooksLikeLT2() then notify("Expected LT2 structures absent."); return end
    if string.upper(MoneyRiskInput.Text:match("^%s*(.-)%s*$")) ~= "SEND" then
        notify("Type SEND to accept possible loss of the amount."); return
    end
    local amount, balance = tonumber(MoneyAmount.Text), getMoney()
    if not amount or amount ~= math.floor(amount) or amount < 1 or amount > 100
        or not balance or amount > balance
        or amount > math.max(1, math.floor(balance * 0.02)) then
        MoneyResult.Text = "INVALID AMOUNT  /  Integer 1-100, not above 2% of your balance."
        return
    end
    local _, saving = dupeSaveValues()
    if saving and saving:IsA("ValueBase") and saving.Value == true then
        notify("Save/load currently in progress; cancelled."); return
    end
    local tx = game:GetService("ReplicatedStorage"):FindFirstChild("Transactions")
    local cts = tx and tx:FindFirstChild("ClientToServer")
    local donate = cts and cts:FindFirstChild("Donate")
    if not donate or not donate:IsA("RemoteFunction") then
        MoneyResult.Text = "UNAVAILABLE  /  Historical Donate remote not found."
        notify("Old self-donation call is no longer available."); return
    end
    if os.clock() > MoneyArmedExpiry or MoneyArmedAmount ~= amount then
        MoneyArmedExpiry = os.clock() + 10
        MoneyArmedAmount = amount
        MoneyButton.Text = "CONFIRM SELF-DONATION TEST"
        MoneyResult.Text = "ARMED  /  " .. tostring(amount) ..
            " money may be lost. Click again within 10 seconds."
        return
    end

    MoneyArmedExpiry = 0
    MoneyArmedAmount = nil
    LastMoneyTest = os.clock()
    MoneyTestBusy = true
    MoneyButton.Text = "WAITING FOR SERVER..."
    MoneyResult.Text = "RUNNING  /  One self-donation call for " .. tostring(amount)
    task.spawn(function()
        local ok, response = pcall(function()
            return donate:InvokeServer(LocalPlayer, amount, 1)
        end)
        if State.closed then return end
        MoneyTestBusy = false
        MoneyButton.Text = "BEGIN LEGACY MONEY DUPE TEST"
        local after = getMoney()
        MoneyResult.Text = "SERVER CALL  /  " .. (ok and "RETURNED" or "FAILED") ..
            "\nVISIBLE BALANCE CHANGE  /  " ..
            (after and tostring(after - balance) or "UNKNOWN") ..
            "\nDOES NOT CONFIRM PERSISTENT DUPLICATION"
        if not ok then warn("[Mystics LT2] Money experiment failed: " .. tostring(response)) end
        notify("Self-donation test ended. Verify balance after a fresh load.")
        updateInventory()
    end)
end, "cta", 52)
info(Dupes, "A server reply or temporary money change does not confirm any amount was duplicated. There is no automatic repeat or hidden retry.", 86)
updateDupeReadout()

local StylePage = pages.STYLE
section(StylePage, "SIGNATURE THEME", "Choose the look of the LT2 module.")
local themeButtons = {}
for _, key in ipairs({"MYSTICS", "OBSIDIAN", "CHRISTMAS", "HALLOWEEN"}) do
    local selectedTheme = key
    local button = makeButton(StylePage, key, function()
        State.theme = selectedTheme
        applyTheme()
        for name, item in pairs(themeButtons) do
            item.Text = (name == State.theme and "✓  " or "     ") .. name
        end
        for _, hl in ipairs(State.woodHighlights) do
            if hl.Parent then
                hl.FillColor = theme().accent
                hl.OutlineColor = theme().light
            end
        end
        for _, page in pairs(pages) do
            page.ScrollBarImageColor3 = theme().accent
        end
        showTab(State.selectedTab)
        notify("Theme: " .. selectedTheme)
    end, "card", 42)
    themeButtons[key] = button
end
local AlertsToggle
AlertsToggle = makeButton(StylePage, "JOIN / LEAVE NOTICES  /  ON", function()
    State.notifications = not State.notifications
    AlertsToggle.Text = State.notifications
        and "JOIN / LEAVE NOTICES  /  ON" or "JOIN / LEAVE NOTICES  /  OFF"
end, "card")
local AudioToggle
AudioToggle = makeButton(StylePage, "BUTTON SOUNDS  /  ON", function()
    State.sounds = not State.sounds
    AudioToggle.Text = State.sounds and "BUTTON SOUNDS  /  ON"
        or "BUTTON SOUNDS  /  OFF"
end, "card")
local MotionToggle
MotionToggle = makeButton(StylePage, "LOW MOTION  /  OFF", function()
    State.lowMotion = not State.lowMotion
    MotionToggle.Text = State.lowMotion and "LOW MOTION  /  ON"
        or "LOW MOTION  /  OFF"
    for _, t in ipairs(Tweens) do
        if State.lowMotion then t:Pause() else t:Play() end
    end
end, "card")
section(StylePage, "ABOUT THIS BUILD", "Mystics LT2 V2.12 • Discovery and cutting utilities.")
info(StylePage, "Mystics LT2 standalone toolkit. Experimental duplication tests remain opt-in and unverified; they can affect game saves or money. No hidden external script downloads.", 115)


--========================================================
-- EXPANDED TOOLKIT V1.3: read-only discovery + reversible local controls
-- All discovery is bounded to known LT2 folders and manually refreshed.
--========================================================
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local toolkit = pages.TOOLS
local buildPage = pages.BUILD
local toolkitHighlights = {}
local toolkitSettingsFile = "MysticsLT2_Settings.json"
local function clearToolkitHighlights()
    for _, h in ipairs(toolkitHighlights) do pcall(function() h:Destroy() end) end
    table.clear(toolkitHighlights)
end
local function shortName(obj)
    local item = obj:FindFirstChild("ItemName")
    return item and item:IsA("ValueBase") and tostring(item.Value) or obj.Name
end
local function ownedModel(obj)
    return belongsToLocal(obj)
end
local function objectPosition(obj)
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
        return part and part.Position or nil
    end
    return nil
end
local function safeDistance(pos)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    return root and math.floor((pos - root.Position).Magnitude) or nil
end
local function modelRoots()
    local roots = {}
    for _, name in ipairs({"PlayerModels","LogModels","PlankModels"}) do
        local root = Workspace:FindFirstChild(name)
        if root then roots[#roots+1] = root end
    end
    return roots
end
local function findModels(predicate, cap)
    local results, inspected = {}, 0
    for _, root in ipairs(modelRoots()) do
        for _, obj in ipairs(root:GetChildren()) do
            inspected += 1
            if inspected > 2500 then return results end
            if (obj:IsA("Model") or obj:IsA("BasePart")) and predicate(obj) then
                results[#results+1] = obj
                if #results >= (cap or 120) then return results end
            end
        end
    end
    return results
end
local function listText(items, cap)
    if #items == 0 then return "None detected in replicated game objects." end
    local out = {}
    for i=1, math.min(#items, cap or 7) do out[#out+1] = items[i] end
    return table.concat(out, "\n") .. (#items > (cap or 7) and "\n...and more" or "")
end
local function storeSettings()
    if type(writefile) ~= "function" then notify("File API unavailable: settings remain session-only."); return end
    local waypoints = {}
    for _, p in ipairs(State.customLocations) do
        waypoints[#waypoints+1] = {name=p.name, x=p.pos.X, y=p.pos.Y, z=p.pos.Z}
    end
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, {
        version=1, theme=State.theme, notifications=State.notifications,
        sounds=State.sounds, lowMotion=State.lowMotion, waypoints=waypoints
    })
    if ok and pcall(writefile, toolkitSettingsFile, encoded) then
        notify("Mystics preferences saved.")
    else notify("Could not save preferences.") end
end
local function loadSettings()
    if type(readfile) ~= "function" then notify("File API unavailable: settings remain session-only."); return end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(toolkitSettingsFile))
    end)
    if not ok or type(data) ~= "table" then notify("No valid saved preferences."); return end
    if type(data.theme) == "string" and Palette[data.theme] then State.theme=data.theme end
    for _, key in ipairs({"notifications","sounds","lowMotion"}) do
        if type(data[key]) == "boolean" then State[key]=data[key] end
    end
    State.customLocations = {}
    if type(data.waypoints) == "table" then
        for _, p in ipairs(data.waypoints) do
            if #State.customLocations >= 15 then break end
            if type(p) == "table" and type(p.name) == "string" and #p.name <= 30
                and type(p.x) == "number" and type(p.y) == "number"
                and type(p.z) == "number" then
                local pos = Vector3.new(p.x,p.y,p.z)
                if pos.Magnitude < 500000 and pos.Magnitude == pos.Magnitude then
                    State.customLocations[#State.customLocations+1] = {name=p.name,pos=pos}
                end
            end
        end
    end
    renderCustom()
    applyTheme()
    for key, b in pairs(themeButtons) do
        b.Text = (key == State.theme and "✓  " or "     ") .. key
    end
    AlertsToggle.Text = State.notifications and "JOIN / LEAVE NOTICES  /  ON" or "JOIN / LEAVE NOTICES  /  OFF"
    AudioToggle.Text = State.sounds and "BUTTON SOUNDS  /  ON" or "BUTTON SOUNDS  /  OFF"
    MotionToggle.Text = State.lowMotion and "LOW MOTION  /  ON" or "LOW MOTION  /  OFF"
    notify("Preferences loaded.")
end

local TreeFinderHeading = section(toolkit, "TREE FINDER", "1. Find trees, then highlight the nearest matches.")
TreeFinderHeading.LayoutOrder = -200
local TreeSearch = makeInput(toolkit, "Tree name filter (e.g. Oak, Birch)", "")
TreeSearch.LayoutOrder = -199
local TreeResult = info(toolkit, "TREE FINDER  /  READY", 116, "text")
TreeResult.Parent.LayoutOrder = -198
local treeCandidates = {}
-- Shared tree discovery used by finder and auto cutter.
-- LT2 normally creates multiple Workspace.TreeRegion models, while
-- some versions wrap them inside Workspace.TreeRegions.
local function localTreeRegions()
    local roots = {}
    local plural = Workspace:FindFirstChild("TreeRegions")
    if plural then
        for _, obj in ipairs(plural:GetChildren()) do
            if obj:IsA("Folder") or obj:IsA("Model") then
                roots[#roots+1] = obj
            end
        end
    end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name == "TreeRegion" then roots[#roots+1] = obj end
    end
    return roots
end
local function getCutSection(tree)
    -- ID 1 is the base cut section in the replicated tree model.
    -- Prefer it over WoodSection so cutting begins at ground level.
    local baseSection
    for _, part in ipairs(tree:GetDescendants()) do
        if part:IsA("BasePart") then
            local id = part:FindFirstChild("ID")
            if id and id:IsA("ValueBase") and tonumber(id.Value) == 1 then
                if not baseSection or part.Position.Y < baseSection.Position.Y then
                    baseSection = part
                end
            end
        end
    end
    if baseSection then return baseSection end
    local trunk = tree:FindFirstChild("WoodSection", true)
    if trunk and trunk:IsA("BasePart") then return trunk end
    return objectPosition(tree) and (tree.PrimaryPart or tree:FindFirstChildWhichIsA("BasePart", true)) or nil
end
-- Use the same region/section discovery as AUTO WOOD CUTTING.
local function showTreeScan()
    clearToolkitHighlights()
    treeCandidates = {}
    local regions = localTreeRegions()
    if #regions == 0 then
        TreeResult.Text = "NO TREE REGIONS FOUND\nWorld may still be loading; try scanning again."
        return
    end
    local query = string.lower(TreeSearch.Text:match("^%s*(.-)%s*$"))
    local inspected, qualified, matching, nearby = 0, 0, 0, 0
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then TreeResult.Text = "Character not ready. Spawn before scanning."; return end
    local center = root.Position
    for _, region in ipairs(regions) do
        for _, tree in ipairs(region:GetChildren()) do
            inspected += 1
            if inspected > 20000 then break end
            if tree:IsA("Model") and tree:FindFirstChild("CutEvent") then
                qualified += 1
                local class = tree:FindFirstChild("TreeClass")
                local species = class and class:IsA("ValueBase")
                    and tostring(class.Value) or tree.Name
                if query == "" or string.find(string.lower(species), query, 1, true) then
                    matching += 1
                    local part = getCutSection(tree)
                    if part then
                        local distance = (part.Position - center).Magnitude
                        -- Show the closest 100 results rather than the first 100
                        -- encountered in the workspace hierarchy.
                        if distance <= 10000 then
                            nearby += 1
                            local candidate = {obj=tree, name=species, pos=part.Position,
                                dist=math.floor(distance)}
                            if #treeCandidates < 500 then
                                treeCandidates[#treeCandidates+1] = candidate
                            else
                                local farthest = 1
                                for i=2,#treeCandidates do
                                    if treeCandidates[i].dist > treeCandidates[farthest].dist then
                                        farthest = i
                                    end
                                end
                                if candidate.dist < treeCandidates[farthest].dist then
                                    treeCandidates[farthest] = candidate
                                end
                            end
                        end
                    end
                end
            end
        end
        if inspected > 3200 then break end
    end
    table.sort(treeCandidates, function(a,b) return a.dist < b.dist end)
    local rows = {}
    for i=1, math.min(4,#treeCandidates) do
        local t = treeCandidates[i]
        rows[#rows+1] = t.name .. " / " .. t.dist .. " studs"
    end
    local summary = "NEARBY: "..nearby.." | TYPES MATCH: "..matching
        .."\nTREES: "..qualified.." | REGIONS: "..#regions
        ..(inspected > 20000 and " / SCAN CAPPED AT 20K" or "")
    if #treeCandidates == 0 then
        summary ..= "\nNo trees within 10000 studs; try a blank species filter."
    end
    TreeResult.Text = summary .. "\n" .. listText(rows, 4)
end
local ScanTreesButton = makeButton(toolkit, "SCAN TREES NEAR ME", showTreeScan, "cta")
ScanTreesButton.LayoutOrder = -197
local HighlightTreesButton = makeButton(toolkit, "HIGHLIGHT 12 NEAREST MATCHES", function()
    clearToolkitHighlights()
    for i=1, math.min(#treeCandidates,12) do
        local obj=treeCandidates[i].obj
        if obj and obj.Parent then
            local h=Instance.new("Highlight")
            h.Name="MysticsTreeFinder"
            h.Adornee=obj
            h.FillTransparency=0.85
            h.OutlineColor=theme().accent
            h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent=Workspace
            toolkitHighlights[#toolkitHighlights+1]=h
        end
    end
    notify("Highlighted "..#toolkitHighlights.." trees.")
end,"card")
HighlightTreesButton.LayoutOrder = -196
local ClearTreeButton = makeButton(toolkit, "CLEAR TREE HIGHLIGHTS", clearToolkitHighlights, "quiet")
ClearTreeButton.LayoutOrder = -195


--========================================================
-- AUTO WOOD CUTTING V1.6
-- Manual start/stop; near-field search only; capped server calls.
-- LT2's tree protocol is not guaranteed to remain compatible.
--========================================================
section(toolkit, "AUTO WOOD CUTTING",
    "Cuts nearby trees with an axe. Manual start/stop, max 3 trees per run.")
local CutSpecies = makeInput(toolkit, "Tree species filter (empty = any)", "")
local CutStatus = info(toolkit, "AUTO CUT / IDLE", 112, "text")
local cuttingActive = false
local cuttingToken = 0
local CutStopButton
local CutStartButton

local axeDamage = {
    BasicHatchet=0.2, Axe1=0.55, Axe2=0.93, Axe3=1.45,
    SilverAxe=1.6, ManyAxe=10.2, Rukiryaxe=1.68,
    FireAxe=0.6, EndTimesAxe=1.58, Beesaxe=1.4,
    AxeAmber=3.39, AxeChicken=0.9, AxeTwitter=1.65,
    CandyCornAxe=1.75, AxeAlphaTesters=1.5, AxeBetaTesters=1.45
}
local function equippedAxe()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") and obj:FindFirstChild("ToolName") then
            return obj
        end
    end
end
local function getAxeForCutting()
    local tool = equippedAxe()
    if tool then return tool end
    local char = LocalPlayer.Character
    local human = char and char:FindFirstChildOfClass("Humanoid")
    local bag = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not human or not bag then return nil end
    for _, candidate in ipairs(bag:GetChildren()) do
        if candidate:IsA("Tool") and candidate:FindFirstChild("ToolName")
            and axeDamage[tostring(candidate.ToolName.Value)] then
            pcall(function() human:EquipTool(candidate) end)
            return equippedAxe()
        end
    end
    return nil
end

-- Single-tree harvest return: uses an existing highlighted target.
-- The spawned log is only moved if ownership can be confirmed as local.
local HarvestHeading = section(toolkit, "HIGHLIGHTED TREE HARVEST",
    "2. Harvest highlighted tree and return to your starting position.")
HarvestHeading.LayoutOrder = -194
local HarvestStatus = info(toolkit, "HARVEST V2.6 / IDLE", 122, "text")
warn("[Mystics LT2 V2.6] Harvest diagnostic active; old DRAG REMOTES UNAVAILABLE text is absent.")
HarvestStatus.Parent.LayoutOrder = -193
local harvestRunning = false
local harvestToken = 0
local harvestOrigin, harvestCharacter = nil, nil
local function stopHarvest(message)
    harvestToken += 1
    harvestRunning = false
    if harvestOrigin and harvestCharacter and harvestCharacter.Parent then
        pcall(function() harvestCharacter:PivotTo(harvestOrigin) end)
    end
    harvestOrigin, harvestCharacter = nil, nil
    if not State.closed then HarvestStatus.Text = "HARVEST / " .. (message or "STOPPED") end
end
State.stopHarvest = function() stopHarvest("CLOSED") end
local HarvestStartButton = makeButton(toolkit, "HARVEST NEAREST HIGHLIGHTED TREE", function()
    if harvestRunning or cuttingActive then
        notify("Stop other cutting activity before harvesting.")
        return
    end
    local target, distance
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then
        notify("Spawn your character before harvesting."); return
    end
    for _, highlight in ipairs(toolkitHighlights) do
        local tree = highlight and highlight.Adornee
        if highlight and highlight.Parent and tree and tree.Parent
            and tree:IsA("Model") and tree:FindFirstChild("CutEvent") then
            local part = getCutSection(tree)
            if part then
                local d = (part.Position - root.Position).Magnitude
                if not distance or d < distance then
                    distance = d
                    target = {tree=tree,section=part}
                end
            end
        end
    end
    if not target then
        notify("Scan trees, then highlight trees before harvesting."); return
    end
    local tool = getAxeForCutting()
    local toolName = tool and tool:FindFirstChild("ToolName")
    if not toolName or not axeDamage[tostring(toolName.Value)] then
        notify("Equip a supported axe before harvesting."); return
    end
    local interaction = game:GetService("ReplicatedStorage"):FindFirstChild("Interaction")
    local cutRemote = interaction and interaction:FindFirstChild("RemoteProxy")
    if not cutRemote or not cutRemote:IsA("RemoteEvent") then
        notify("Cutting remote not available."); return
    end
    local startCFrame = root.CFrame
    harvestOrigin, harvestCharacter = startCFrame, character
    local tree = target.tree
    local treeType = tree:FindFirstChild("TreeClass")
    local species = treeType and treeType:IsA("ValueBase") and tostring(treeType.Value) or nil
    local logRoot = Workspace:FindFirstChild("LogModels")
    local playerModels = Workspace:FindFirstChild("PlayerModels")
    if not logRoot and not playerModels then
        harvestOrigin, harvestCharacter = nil, nil
        HarvestStatus.Text = "HARVEST / NO WOOD MODEL FOLDERS TO VERIFY"
        return
    end
    -- Resolve remotes after cutting, and tolerate LT2 versions without
    -- the optional ownership-request remote.
    local function findInteractionEvent(name)
        local instance = interaction and interaction:FindFirstChild(name, true)
        if instance and instance:IsA("RemoteEvent") then return instance end
        return nil
    end
    local function remoteDescription(name)
        local instance = interaction and interaction:FindFirstChild(name, true)
        return instance and (instance.Name .. ":" .. instance.ClassName) or (name .. ":MISSING")
    end
    local dragRemote = findInteractionEvent("ClientIsDragging")
    local ownershipRemote = findInteractionEvent("ClientRequestOwnership")
    local function requestWoodControl(part, model)
        if ownershipRemote then
            pcall(function() ownershipRemote:FireServer(part) end)
            pcall(function() ownershipRemote:FireServer(model) end)
        end
    end
    local logListeners = {}
    local targetTreePosition = target.section.Position
    local nearbyOwned = {}
    local knownBefore = {}
    local woodFolders = {}
    if logRoot then woodFolders[#woodFolders+1] = logRoot end
    if playerModels then woodFolders[#woodFolders+1] = playerModels end
    -- Snapshot the world before chopping; later classify new cut pieces
    -- independently of which wood folder the game places them inside.
    for _, folder in ipairs(woodFolders) do
        for _, item in ipairs(folder:GetChildren()) do
            knownBefore[item] = true
        end
    end
    harvestRunning = true
    harvestToken += 1
    local token = harvestToken
    task.spawn(function()
        local function active()
            return harvestRunning and harvestToken == token and not State.closed
        end
        local function isCutWood(candidate)
            if not candidate or not candidate.Parent or not candidate:IsA("Model") then return false end
            local rootName = candidate.Parent.Name
            if rootName ~= "LogModels" and rootName ~= "PlayerModels" then return false end
            local name = string.lower(candidate.Name)
            local typeValue = candidate:FindFirstChild("TreeClass")
            -- Exclude machinery and loose non-wood objects in PlayerModels.
            return rootName == "LogModels" or name:find("wood",1,true)
                or name:find("plank",1,true) or name:find("log",1,true)
                or name:find("loose_",1,true) or (typeValue ~= nil and typeValue:IsA("ValueBase"))
        end
        local function inspectOwnedWood(candidate)
            if not active() or not isCutWood(candidate) then return false end
            if not belongsToLocal(candidate) then return false end
            local pos = objectPosition(candidate)
            if not pos or (pos - targetTreePosition).Magnitude > 100 then return false end
            if species then
                local treeClass = candidate:FindFirstChild("TreeClass")
                if treeClass and treeClass:IsA("ValueBase")
                    and tostring(treeClass.Value) ~= species then return false end
            end
            nearbyOwned[candidate] = true
            return true
        end
        local function discoverOwnedWood()
            local found = 0
            for _, folder in ipairs(woodFolders) do
                local inspected = 0
                for _, item in ipairs(folder:GetChildren()) do
                    inspected += 1
                    if inspected > 1000 then break end
                    if inspectOwnedWood(item) then found += 1 end
                end
            end
            return found
        end
        local function newOwnedCutWood()
            local new = {}
            for item in pairs(nearbyOwned) do
                if not knownBefore[item] and item.Parent and belongsToLocal(item) then
                    new[#new+1] = item
                end
            end
            return new
        end
        -- Listen for new logs, then re-scan as ownership may replicate after spawn.
        for _, folder in ipairs(woodFolders) do
            logListeners[#logListeners+1] = folder.ChildAdded:Connect(function(candidate)
                task.delay(0.35, function()
                    if active() then inspectOwnedWood(candidate) end
                end)
            end)
        end
        local failure
        local ok = pcall(function()
            HarvestStatus.Text = "HARVEST / MOVING TO HIGHLIGHTED TREE"
            local section = target.section
            if not active() or not section.Parent or not tree.Parent then return end
            -- Stand beside, not inside, the trunk.
            local destination = section.Position + Vector3.new(4, 2, 4)
            character:PivotTo(CFrame.new(destination))
            task.wait(0.6)
            local movedRoot = character:FindFirstChild("HumanoidRootPart")
            if not active() or not movedRoot
                or (movedRoot.Position - section.Position).Magnitude > 10000 then
                failure = "TELEPORT DID NOT REACH TREE"
                return
            end
            local id = section:FindFirstChild("ID")
            local cutEvent = tree:FindFirstChild("CutEvent")
            if not id or not id:IsA("ValueBase") or not cutEvent then
                failure = "TREE CUT DATA MISSING"
                return
            end
            HarvestStatus.Text = "HARVEST / CUTTING; CHECKING MY WOOD"
            local MAX_CUT_ATTEMPTS, MAX_CUT_SECONDS = 600, 600
            local cutStarted, hitCount = os.clock(), 0
            local confirmed = false
            while active() and hitCount < MAX_CUT_ATTEMPTS
                and os.clock() - cutStarted < MAX_CUT_SECONDS do
                discoverOwnedWood()
                if #newOwnedCutWood() > 0 then confirmed = true; break end
                if not section.Parent or not tree.Parent or not tree:FindFirstChild("CutEvent") then
                    break
                end
                local charRoot = character:FindFirstChild("HumanoidRootPart")
                if not charRoot or (charRoot.Position - section.Position).Magnitude > 10000 then
                    failure = "LEFT CUTTING RANGE"; break
                end
                local held = equippedAxe()
                local value = held and held:FindFirstChild("ToolName")
                local damage = value and axeDamage[tostring(value.Value)]
                if not damage then failure = "AXE NO LONGER EQUIPPED"; break end
                local success = pcall(function()
                    cutRemote:FireServer(cutEvent, {
                        tool=held, faceVector=Vector3.new(0,0,-1),
                        height=0.3, sectionId=id.Value, hitPoints=damage,
                        cooldown=0.44, cuttingClass="Axe"
                    })
                end)
                if not success then failure = "CUT REQUEST FAILED"; break end
                hitCount += 1
                HarvestStatus.Text = "HARVEST / CUTTING " .. hitCount ..
                    "/120\nNEW OWNED LOGS: " .. #newOwnedCutWood()
                task.wait(0.56)
            end
            if active() and not confirmed then
                local verifyStart = os.clock()
                while active() and os.clock()-verifyStart < 7 do
                    discoverOwnedWood()
                    if #newOwnedCutWood() > 0 then confirmed = true; break end
                    task.wait(0.3)
                end
            end
            if not active() then return end
            if not confirmed then
                failure = failure or ("CUT NOT VERIFIED AFTER "..hitCount..
                    " HITS; NO NEW OWNED LOG")
                return
            end
            discoverOwnedWood()
            HarvestStatus.Text = "HARVEST / CUT VERIFIED: " .. #newOwnedCutWood()
                .. " NEW OWNED PIECES"
            -- Drag notifications are essential; ownership requests are not
            -- exposed in every LT2 session and should not abort transport.
            dragRemote = findInteractionEvent("ClientIsDragging")
            ownershipRemote = findInteractionEvent("ClientRequestOwnership")
            if not dragRemote then
                local detail = remoteDescription("ClientIsDragging") .. " / "
                    .. remoteDescription("ClientRequestOwnership")
                failure = "V2.6 REMOTE DIAGNOSTIC / " .. detail
                warn("[Mystics LT2 V2.6] " .. failure)
                return
            end
            if not ownershipRemote then
                HarvestStatus.Text = "HARVEST / DRAG FOUND; OWNERSHIP REMOTE OPTIONAL"
            end
            -- Transport fresh, verified owned wood only. Some LT2 versions
            -- expect ClientRequestOwnership to receive the WoodSection, not
            -- the model, and physics ownership is not the same as item Owner.
            local logs = newOwnedCutWood()
            table.sort(logs,function(a,b)
                return ((objectPosition(a) or targetTreePosition)-targetTreePosition).Magnitude
                    < ((objectPosition(b) or targetTreePosition)-targetTreePosition).Magnitude
            end)
            local delivered, failed, noControl = 0, 0, 0
            local count = math.min(#logs,8)
            if count == 0 then failure = "NO NEW OWNED LOGS ELIGIBLE FOR RETURN"; return end
            for n=1,count do
                if not active() then return end
                local log = logs[n]
                local wood = log and log:FindFirstChild("WoodSection",true)
                if not log or not log.Parent or not belongsToLocal(log)
                    or not wood or not wood:IsA("BasePart") then
                    failed += 1
                    HarvestStatus.Text = "HARVEST / SKIPPED WOOD "..n.." (MISSING OR UNOWNED)"
                else
                    local destination = startCFrame*CFrame.new(7+n*4,4,0)
                    local oldPrimary = log.PrimaryPart
                    local gotNetworkControl = false
                    local networkCheckAvailable = type(isnetworkowner) == "function"
                    -- Request the physical section as well as its assembly.
                    local requestStart = os.clock()
                    while active() and os.clock()-requestStart < 5 do
                        requestWoodControl(wood, log)
                        pcall(function() dragRemote:FireServer(log) end)
                        if networkCheckAvailable then
                            local ok, owns = pcall(isnetworkowner,wood)
                            if ok and owns then gotNetworkControl = true; break end
                        end
                        task.wait(0.15)
                    end
                    if networkCheckAvailable and not gotNetworkControl then
                        noControl += 1
                    end
                    HarvestStatus.Text = "HARVEST / WOOD "..n.."/"..count
                        ..(gotNetworkControl and " / PHYSICS OWNED" or " / OWNERSHIP UNCERTAIN")
                    local originalPos = wood.Position
                    -- Keep the player nearby to maintain physics simulation
                    -- while the log is moved. Try both the full assembly and
                    -- physical WoodSection, which LT2 uses as its trunk root.
                    local movedOnce = false
                    pcall(function() log.PrimaryPart=wood end)
                    if character.Parent and humanoid.Health > 0 then
                        pcall(function()
                            character:PivotTo(CFrame.new(originalPos+Vector3.new(5,3,5)))
                        end)
                    end
                    task.wait(0.2)
                    for frame=1,90 do
                        if not active() or not log.Parent or not wood.Parent
                            or not belongsToLocal(log) then break end
                        local succeeded = pcall(function()
                            requestWoodControl(wood, log)
                            dragRemote:FireServer(log)
                            log:PivotTo(destination)
                            wood.AssemblyLinearVelocity = Vector3.zero
                            wood.AssemblyAngularVelocity = Vector3.zero
                            dragRemote:FireServer(log)
                        end)
                        if succeeded then movedOnce = true end
                        if frame % 15 == 0 then
                            HarvestStatus.Text = "HARVEST / WOOD "..n.."/"..count
                                .." DRAG "..frame.."/90"
                        end
                        task.wait(0.05)
                    end
                    -- Let replication settle; local movement is only a
                    -- provisional check and can still be rejected by server.
                    task.wait(3)
                    local pos=wood.Parent and wood.Position
                    local distance=pos and (pos-destination.Position).Magnitude
                    if movedOnce and distance and distance<18 and belongsToLocal(log) then
                        delivered += 1
                        HarvestStatus.Text = "HARVEST / WOOD "..n.." NEAR HOME (LOCAL)"
                    else
                        failed += 1
                        HarvestStatus.Text = "HARVEST / WOOD "..n
                            .." SNAPPED BACK OR DRAG FAILED"
                    end
                    pcall(function()
                        if oldPrimary and oldPrimary.Parent==log then log.PrimaryPart=oldPrimary end
                    end)
                end
            end
            -- Preserve the actual outcome instead of masking it with a
            -- generic 'player returned' message when this task finishes.
            if delivered == count then
                HarvestStatus.Text = "HARVEST / "..delivered.."/"..count..
                    " LOGS NEAR START (CLIENT VERIFIED)"
            else
                failure = "WOOD RETURN "..delivered.."/"..count..
                    "; FAILED "..failed..
                    (noControl>0 and (" / PHYSICS CONTROL UNCONFIRMED "..noControl) or "")
            end
        end)
        for _, listener in ipairs(logListeners) do listener:Disconnect() end
        -- Return the player even if cutting or log movement fails.
        pcall(function()
            if character.Parent and humanoid.Health > 0 then
                character:PivotTo(startCFrame)
            end
        end)
        if token == harvestToken then
            harvestOrigin, harvestCharacter = nil, nil
            harvestRunning = false
            if not State.closed then
                HarvestStatus.Text = "HARVEST / " ..
                    (not ok and "SCRIPT ERROR; SEE CONSOLE" or
                    failure or "OWNED LOG RETURN ATTEMPT COMPLETE (LOCAL CHECK)")
            end
            if not ok then warn("[Mystics LT2] Harvest transport error") end
        end
    end)
end, "cta")
HarvestStartButton.LayoutOrder = -192
local HarvestStopButton = makeButton(toolkit, "STOP HARVEST / RETURN ME", function()
    if harvestRunning then stopHarvest("STOPPED / RETURNING")
    else notify("No highlighted-tree harvest is running.") end
end, "quiet")
HarvestStopButton.LayoutOrder = -191

-- Sell only loose logs that are currently owned by the local player.
-- The drop-off position is taken from existing community LT2 sell routines.
section(toolkit, "WOOD DROP-OFF", "Send your owned cut logs to the Wood R Us drop-off.")
local SellStatus = info(toolkit, "AUTO SELL / READY", 66, "text")
local sellRunning = false
local sellToken = 0
local function stopSell(message)
    sellToken += 1
    sellRunning = false
    if not State.closed then SellStatus.Text = "AUTO SELL / " .. (message or "STOPPED") end
end
State.stopSell = function() stopSell("CLOSED") end
local SellWoodButton = makeButton(toolkit, "SELL MY CUT WOOD", function()
    if sellRunning or harvestRunning or cuttingActive then
        notify("Finish the current harvest/cutting action first."); return
    end
    local logFolder = Workspace:FindFirstChild("LogModels")
    if not logFolder then SellStatus.Text = "AUTO SELL / LOGMODELS NOT FOUND"; return end
    local interaction = game:GetService("ReplicatedStorage"):FindFirstChild("Interaction")
    local drag = interaction and interaction:FindFirstChild("ClientIsDragging", true)
    if not drag or not drag:IsA("RemoteEvent") then
        SellStatus.Text = "AUTO SELL / CLIENTISDRAGGING REMOTE MISSING"; return
    end
    local owned = {}
    for _, log in ipairs(logFolder:GetChildren()) do
        if log:IsA("Model") and string.sub(log.Name,1,6) == "Loose_"
            and belongsToLocal(log) then
            local sectionPart = log:FindFirstChild("WoodSection")
                or log:FindFirstChild("WoodSection", true)
            if sectionPart and sectionPart:IsA("BasePart") then
                owned[#owned+1] = {model=log,part=sectionPart}
            end
        end
    end
    if #owned == 0 then
        SellStatus.Text = "AUTO SELL / NO OWNED CUT LOGS FOUND"; return
    end
    sellRunning = true
    sellToken += 1
    local token = sellToken
    task.spawn(function()
        local sold, uncertain, skipped = 0, 0, 0
        -- Historical LT2 community scripts target the Wood Drop-off here.
        local dropCFrame = CFrame.new(315, -0.296, 85.791)
            * CFrame.Angles(math.rad(90),0,0)
        for index, entry in ipairs(owned) do
            if not sellRunning or sellToken ~= token or State.closed then break end
            local log, part = entry.model, entry.part
            if not log.Parent or not part.Parent or not belongsToLocal(log) then
                skipped += 1
            else
                SellStatus.Text = "AUTO SELL / SENDING LOG "..index.."/"..#owned
                local moved = pcall(function()
                    for attempt=1,10 do
                        if not sellRunning or sellToken ~= token then break end
                        if not log.Parent or not part.Parent then break end
                        part.CFrame = dropCFrame
                        drag:FireServer(log)
                        task.wait(0.08)
                    end
                    for attempt=1,20 do
                        if not sellRunning or sellToken ~= token then break end
                        if not log.Parent then break end
                        drag:FireServer(log)
                        task.wait(0.06)
                    end
                end)
                if not moved then
                    skipped += 1
                else
                    -- Sale normally removes the log from LogModels.
                    local deadline = os.clock()+5
                    while sellRunning and sellToken==token and log.Parent
                        and os.clock()<deadline do task.wait(0.2) end
                    if not log.Parent then sold += 1
                    else uncertain += 1 end
                end
            end
        end
        if sellToken == token then
            sellRunning = false
            if not State.closed then
                SellStatus.Text = "AUTO SELL / REMOVED "..sold
                    .." | STILL PRESENT "..uncertain.." | SKIPPED "..skipped
            end
        end
    end)
end, "cta")
SellWoodButton.LayoutOrder = -190
local SellStopButton = makeButton(toolkit, "STOP AUTO SELL", function()
    if sellRunning then stopSell("STOPPED")
    else notify("Auto sell is not running.") end
end, "quiet")
SellStopButton.LayoutOrder = -189

local function nextCutTarget(species, ignored)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local best, closest, visited = nil, 18, 0
    for _, region in ipairs(localTreeRegions()) do
        for _, tree in ipairs(region:GetChildren()) do
            visited += 1
            if visited > 1200 then return best end
            if tree:IsA("Model") and not ignored[tree]
                and tree:FindFirstChild("CutEvent") then
                local class = tree:FindFirstChild("TreeClass")
                local name = class and tostring(class.Value) or tree.Name
                if species == "" or string.find(string.lower(name), species, 1, true) then
                    local part = getCutSection(tree)
                    if part then
                        local dist = (part.Position - root.Position).Magnitude
                        if dist < closest then
                            best = {tree=tree,section=part,species=name}
                            closest = dist
                        end
                    end
                end
            end
        end
    end
    return best
end
local function stopCutting(reason)
    cuttingActive = false
    cuttingToken += 1
    CutStatus.Text = "AUTO CUT / " .. (reason or "STOPPED")
    if CutStartButton then CutStartButton.Text = "START AUTO CUT / NEARBY TREES" end
end
State.stopAutoCut = function() stopCutting("CLOSED") end
CutStartButton = makeButton(toolkit, "START AUTO CUT / NEARBY TREES", function()
    if cuttingActive then notify("Auto cut is already running."); return end
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local interaction = ReplicatedStorage:FindFirstChild("Interaction")
    local proxy = interaction and interaction:FindFirstChild("RemoteProxy")
    if not proxy or not proxy:IsA("RemoteEvent") then
        notify("LT2 cutting remote not available."); return
    end
    local tool = getAxeForCutting()
    local toolName = tool and tool:FindFirstChild("ToolName")
    if not toolName or not axeDamage[tostring(toolName.Value)] then
        notify("Equip a supported axe before starting."); return
    end
    local species = string.lower(CutSpecies.Text:match("^%s*(.-)%s*$"))
    local candidate = nextCutTarget(species, {})
    if not candidate then
        notify("No matching tree within 18 studs."); return
    end
    cuttingToken += 1
    local token = cuttingToken
    cuttingActive = true
    CutStartButton.Text = "AUTO CUT / RUNNING"
    CutStatus.Text = "AUTO CUT / STARTING..."
    task.spawn(function()
        local completed, attempts, skipped = 0, 0, {}
        for index=1,100 do
            if not cuttingActive or token ~= cuttingToken or State.closed then break end
            local target = nextCutTarget(species, skipped)
            if not target then break end
            skipped[target.tree] = true
            local obj, part = target.tree, target.section
            local cutEvent = obj:FindFirstChild("CutEvent")
            local idValue = part:FindFirstChild("ID")
            if not cutEvent or not idValue then
                CutStatus.Text = "SKIPPED / MISSING CUT DATA"
            else
                local succeeded = false
                local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not root then break end
                local startPosition = root.Position
                local nearbyLogs = Workspace:FindFirstChild("LogModels")
                local countBefore = nearbyLogs and #nearbyLogs:GetChildren() or 0
                for attempt=1,2400 do
                    if not cuttingActive or token ~= cuttingToken or State.closed then break end
                    local currentRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local activeAxe = equippedAxe()
                    local nameValue = activeAxe and activeAxe:FindFirstChild("ToolName")
                    local damage = nameValue and axeDamage[tostring(nameValue.Value)]
                    if not currentRoot or not damage or not obj.Parent or not part.Parent
                        or (currentRoot.Position - part.Position).Magnitude > 10000
                        or (currentRoot.Position - startPosition).Magnitude > 30 then
                        CutStatus.Text = "AUTO CUT / STOPPED: RANGE OR AXE CHANGED"
                        cuttingActive = false
                        break
                    end
                    local args = {
                        tool=activeAxe,
                        faceVector=Vector3.new(0, 0, -1),
                        height=0.3,
                        sectionId=idValue.Value,
                        hitPoints=damage,
                        cooldown=0.22,
                        cuttingClass="Axe"
                    }
                    local ok = pcall(function() proxy:FireServer(cutEvent, args) end)
                    if not ok then
                        CutStatus.Text = "AUTO CUT / REMOTE CALL FAILED"
                        cuttingActive = false
                        break
                    end
                    attempts += 1
                    CutStatus.Text = "AUTO CUT / " .. target.species ..
                        "\nTREE " .. index .. "/100  •  HIT " .. attempt .. "/2400"
                    task.wait(0.56)
                    if not obj.Parent or not obj:FindFirstChild("CutEvent") then
                        succeeded = true
                        break
                    end
                    if nearbyLogs and #nearbyLogs:GetChildren() > countBefore then
                        succeeded = true
                        break
                    end
                end
                if succeeded then completed += 1 end
            end
            if cuttingActive and token == cuttingToken then task.wait(0.7) end
        end
        if token == cuttingToken then
            stopCutting("FINISHED / " .. completed .. " TREES DETECTED\n"
                .. attempts .. " CUT REQUESTS; SERVER RESULTS MAY VARY")
        end
    end)
end, "cta")
CutStopButton = makeButton(toolkit, "STOP AUTO CUT NOW", function()
    if cuttingActive then stopCutting("STOPPED BY USER")
    else notify("Auto cut is not active.") end
end, "quiet")

section(toolkit, "AXE & EQUIPMENT MANAGER", "Inventory names and best-axe suggestion from known legacy tiers.")
local AxeResult=info(toolkit,"AXES  /  NOT SCANNED",125,"text")
local axeRanks={Axe1=2,Axe2=3,Axe3=4,SilverAxe=5,Rukiryaxe=8,FireAxe=11,Beesaxe=13,ManyAxe=15,EndTimesAxe=16}
makeButton(toolkit,"SCAN MY AXES",function()
    local axes={}
    for _, root in ipairs({LocalPlayer:FindFirstChildOfClass("Backpack"),LocalPlayer.Character}) do
        if root then
            for _, obj in ipairs(root:GetChildren()) do
                if obj:IsA("Tool") then
                    local name=shortName(obj)
                    axes[#axes+1]={name=name,rank=axeRanks[name],equipped=root==LocalPlayer.Character}
                end
            end
        end
    end
    table.sort(axes,function(a,b) return (a.rank or -1)>(b.rank or -1) end)
    local rows={}
    for i=1,math.min(5,#axes) do
        local a=axes[i]
        rows[#rows+1]=a.name..(a.equipped and " [EQUIPPED]" or "")..
            (a.rank and " / historical tier "..a.rank or " / unranked")
    end
    AxeResult.Text="TOOLS: "..#axes.." / HISTORICAL TIERS NOT VERIFIED\n"..listText(rows,5)
end,"cta")

section(toolkit,"OWNED VEHICLES", "Locate vehicles in replicated player models.")
local VehicleResult=info(toolkit,"VEHICLES  /  NOT SCANNED",112,"text")
local nearestVehicle=nil
makeButton(toolkit,"FIND MY VEHICLES",function()
    nearestVehicle=nil
    local vehicles=findModels(function(obj)
        local name=string.lower(shortName(obj))
        return ownedModel(obj) and (name:find("truck",1,true) or name:find("trailer",1,true) or name:find("car",1,true))
    end,50)
    local rows={}
    local nearest=math.huge
    for _,obj in ipairs(vehicles) do
        local pos=objectPosition(obj)
        local dist=pos and safeDistance(pos)
        rows[#rows+1]=shortName(obj)..(dist and (" / "..dist.." studs") or "")
        if dist and dist<nearest then nearest=dist;nearestVehicle=pos end
    end
    VehicleResult.Text="OWNED VEHICLES: "..#vehicles.."\n"..listText(rows,5)
end,"cta")
makeButton(toolkit,"TRAVEL NEAR MY CLOSEST VEHICLE",function()
    if nearestVehicle then moveTo(nearestVehicle+Vector3.new(5,0,0),"owned vehicle",false)
    else notify("Scan vehicles first; no valid vehicle location.") end
end,"quiet")

section(toolkit,"PERFORMANCE", "Manual FPS sampling and replicated ping.")
local PerformanceResult=info(toolkit,"PERFORMANCE  /  NOT MEASURED",65,"text")
makeButton(toolkit,"MEASURE FPS & PING (2 SECONDS)",function()
    local count=0
    local started=os.clock()
    local conn
    conn=RunService.RenderStepped:Connect(function() count+=1 end)
    task.delay(2,function()
        conn:Disconnect()
        if State.closed then return end
        local fps=math.floor(count/math.max(0.1,os.clock()-started))
        local ping="Unavailable"
        pcall(function() ping=game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString() end)
        PerformanceResult.Text="FPS: "..fps.."\nPING: "..tostring(ping)
    end)
end,"card")

section(buildPage,"SAWMILL MANAGER","Owned machines only; manual discovery.")
local SawmillResult=info(buildPage,"SAWMILLS  /  NOT SCANNED",125,"text")
makeButton(buildPage,"SCAN MY SAWMILLS",function()
    local mills=findModels(function(obj)
        return ownedModel(obj) and string.find(string.lower(shortName(obj)),"sawmill",1,true)~=nil
    end,70)
    local rows={}
    for _,obj in ipairs(mills) do
        local pos=objectPosition(obj)
        local dist=pos and safeDistance(pos)
        rows[#rows+1]=shortName(obj)..(dist and (" / "..dist.." studs") or "")
    end
    SawmillResult.Text="OWNED SAWMILLS: "..#mills.."\n"..listText(rows,6)
end,"cta")

section(buildPage,"BUILD & BLUEPRINT ASSISTANT","Read-only summary of structures on your plot.")
local BuildResult=info(buildPage,"BUILDINGS  /  NOT SCANNED",115,"text")
makeButton(buildPage,"INSPECT OWNED STRUCTURES",function()
    local owned=findModels(function(obj) return ownedModel(obj) end,250)
    local counts={}
    for _,obj in ipairs(owned) do
        local name=shortName(obj)
        if string.find(string.lower(name),"blueprint",1,true)
            or string.find(string.lower(name),"wall",1,true)
            or string.find(string.lower(name),"floor",1,true) then
            counts[name]=(counts[name] or 0)+1
        end
    end
    local rows={}
    for name,count in pairs(counts) do rows[#rows+1]=name.." x"..count end
    table.sort(rows)
    BuildResult.Text="BLUEPRINT / STRUCTURE TYPES: "..#rows.."\n"..listText(rows,6)
end,"card")

section(buildPage,"WOOD VALUE ESTIMATOR","Local planning calculator, not a verified market price.")
local VolumeInput=makeInput(buildPage,"Wood volume in game units","100")
local PriceInput=makeInput(buildPage,"Estimated price per volume unit","1")
local ValueResult=info(buildPage,"ESTIMATE  /  ENTER VALUES",58,"text")
makeButton(buildPage,"CALCULATE ESTIMATED WOOD VALUE",function()
    local v,p=tonumber(VolumeInput.Text),tonumber(PriceInput.Text)
    if not v or not p or v<0 or p<0 or v>1e9 or p>1e9 then
        ValueResult.Text="Enter non-negative volume and price values.";return
    end
    ValueResult.Text=string.format("ESTIMATED VALUE: %.2f (%.2f x %.2f)",v*p,v,p)
end,"cta")

section(buildPage,"SHOP & PURCHASE PLANNER","Browse shop stock; no automatic purchases or remote calls.")
local ShopResult=info(buildPage,"SHOPS  /  NOT SCANNED",125,"text")
makeButton(buildPage,"INSPECT REPLICATED SHOP STOCK",function()
    local shops=Workspace:FindFirstChild("Stores")
    if not shops then ShopResult.Text="Workspace.Stores unavailable.";return end
    local rows={}
    for _,shop in ipairs(shops:GetChildren()) do
        local count=0
        for _,child in ipairs(shop:GetDescendants()) do
            if child:IsA("Model") and child:FindFirstChild("ItemName") then count+=1 end
            if count>=100 then break end
        end
        rows[#rows+1]=shop.Name.." / up to "..count.." visible items"
    end
    ShopResult.Text="SHOPS: "..#rows.."\n"..listText(rows,6)
end,"card")

section(buildPage,"LOCAL MOVEMENT CONTROLS","Reversible client-side values; server may override.")
local SpeedInput=makeInput(buildPage,"WalkSpeed (8-32)","16")
local JumpInput=makeInput(buildPage,"JumpPower (25-75)","50")
local originalMovement=nil
local function restoreMovement()
    local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum and originalMovement then
        pcall(function()
            hum.WalkSpeed=originalMovement.speed
            hum.JumpPower=originalMovement.jump
            hum.UseJumpPower=originalMovement.usesJump
        end)
    end
    originalMovement=nil
end
State.restoreMovement=restoreMovement
makeButton(buildPage,"APPLY LOCAL MOVEMENT VALUES",function()
    local speed,jump=tonumber(SpeedInput.Text),tonumber(JumpInput.Text)
    if not speed or not jump or speed<8 or speed>32 or jump<25 or jump>75 then
        notify("WalkSpeed 8-32, JumpPower 25-75.");return
    end
    local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not hum then notify("Humanoid unavailable.");return end
    if not originalMovement then
        originalMovement={speed=hum.WalkSpeed,jump=hum.JumpPower,usesJump=hum.UseJumpPower}
    end
    hum.UseJumpPower=true
    hum.WalkSpeed=speed
    hum.JumpPower=jump
    notify("Local movement values applied.")
end,"card")
makeButton(buildPage,"RESTORE ORIGINAL MOVEMENT",function()
    restoreMovement()
    notify("Original movement values restored where available.")
end,"quiet")


--========================================================
-- NAVIGATION & INVENTORY EXTRAS (manual, read-only scans)
--========================================================
section(Travel, "COORDINATE COMPASS", "Read your current coordinates or compare saved waypoints.")
local CompassReadout = info(Travel, "POSITION / NOT REFRESHED", 118, "text")
local currentCoordinates = nil
makeButton(Travel, "REFRESH CURRENT COORDINATES", function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then CompassReadout.Text = "Character position unavailable."; return end
    currentCoordinates = root.Position
    local nearestName, nearestDistance = nil, math.huge
    for _, place in ipairs(State.customLocations) do
        local d = (place.pos - currentCoordinates).Magnitude
        if d < nearestDistance then nearestName, nearestDistance = place.name, d end
    end
    local p = currentCoordinates
    CompassReadout.Text = string.format("X %.1f  /  Y %.1f  /  Z %.1f", p.X, p.Y, p.Z)
        .. (nearestName and ("\nNEAREST SAVED: " .. nearestName
            .. " / " .. math.floor(nearestDistance) .. " studs") or
            "\nNo personal waypoints saved.")
end, "cta")
makeButton(Travel, "COPY CURRENT COORDINATES", function()
    if not currentCoordinates then notify("Refresh current coordinates first."); return end
    if type(setclipboard) ~= "function" then notify("Clipboard API unavailable."); return end
    local p = currentCoordinates
    local value = string.format("%.2f, %.2f, %.2f", p.X, p.Y, p.Z)
    local ok = pcall(setclipboard, value)
    notify(ok and "Coordinates copied." or "Unable to copy coordinates.")
end, "quiet")
section(Travel, "WAYPOINT DISTANCE PLANNER",
    "Compare your current position with an existing named waypoint.")
local PlannerSearch = makeInput(Travel, "Waypoint name (exact or partial)", "")
local PlannerOutput = info(Travel, "DISTANCE / ENTER A SAVED WAYPOINT NAME", 80, "text")
makeButton(Travel, "CALCULATE WAYPOINT DISTANCE", function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then PlannerOutput.Text = "Character position unavailable."; return end
    local query = string.lower(PlannerSearch.Text:match("^%s*(.-)%s*$"))
    if query == "" then PlannerOutput.Text = "Enter a waypoint name."; return end
    local target
    for _, place in ipairs(State.customLocations) do
        if string.find(string.lower(place.name), query, 1, true) then target = place; break end
    end
    if not target then PlannerOutput.Text = "No saved waypoint matched."; return end
    local distance = math.floor((target.pos - root.Position).Magnitude)
    PlannerOutput.Text = target.name .. " / " .. distance
        .. " studs straight-line distance (not a travel ETA)."
end, "card")

section(toolkit, "WOOD TYPE CENSUS", "Summarize the visible types of wood in replicated world folders.")
local WoodCensus = info(toolkit, "WOOD CENSUS / NOT SCANNED", 138, "text")
makeButton(toolkit, "COUNT VISIBLE WOOD TYPES", function()
    local counts, total, scanned = {}, 0, 0
    for _, name in ipairs({"LogModels", "PlankModels", "WoodModels"}) do
        local folder = Workspace:FindFirstChild(name)
        if folder then
            for _, obj in ipairs(folder:GetChildren()) do
                scanned += 1
                if scanned > 1800 then break end
                if obj:IsA("Model") then
                    local typeName = shortName(obj)
                    local woodType = obj:FindFirstChild("TreeClass", true)
                    if woodType and woodType:IsA("ValueBase") then
                        typeName = tostring(woodType.Value)
                    end
                    counts[typeName] = (counts[typeName] or 0) + 1
                    total += 1
                end
            end
        end
        if scanned > 1800 then break end
    end
    local entries = {}
    for name, count in pairs(counts) do
        entries[#entries+1] = {name=name, count=count}
    end
    table.sort(entries, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.name < b.name
    end)
    local rows = {}
    for i=1,math.min(6,#entries) do
        rows[#rows+1] = entries[i].name .. " / " .. entries[i].count
    end
    WoodCensus.Text = "VISIBLE WOOD MODELS: " .. total
        .. (scanned > 1800 and " / SCAN CAPPED" or "")
        .. "\n" .. listText(rows, 6)
end, "cta")

section(buildPage, "LOADOUT NOTES", "Keep a short personal note for your next build or shopping trip.")
local NotesField = makeInput(buildPage, "Project notes (max 180 characters)", "")
makeButton(buildPage, "SAVE NOTE THIS SESSION", function()
    State.buildNote = string.sub(NotesField.Text, 1, 180)
    notify("Build note saved for this session.")
end, "card")
makeButton(buildPage, "RESTORE SAVED NOTE", function()
    NotesField.Text = State.buildNote or ""
    notify(State.buildNote and "Saved note restored." or "No build note saved.")
end, "quiet")

section(StylePage,"SAVE SETTINGS & WAYPOINTS","Optional executor file API; session-only fallback.")
makeButton(StylePage,"SAVE MY PREFERENCES",storeSettings,"cta")
makeButton(StylePage,"LOAD SAVED PREFERENCES",loadSettings,"card")
State.clearToolkitHighlights=clearToolkitHighlights

applyTheme()
for key, b in pairs(themeButtons) do
    b.Text = (key == State.theme and "✓  " or "     ") .. key
end
showTab("TRAVEL")
refreshWorld()
refreshWood()
scanPlots()
notify("Mystics LT2 v2.12 ready. Historical waypoints are unverified.")
