-- Mystics Wire Art Placement Lab (isolated experiment)
-- This file is intentionally NOT loaded by Mystics_Launcher.lua.
-- Execute manually only while in Lumber Tycoon 2. It sends at most one placement request.
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end
local function findOwnedPlot()
    local properties = Workspace:FindFirstChild('Properties')
    if not properties then return nil end
    for _, plot in ipairs(properties:GetChildren()) do
        local owner = plot:FindFirstChild('Owner')
        if owner and owner.Value == LocalPlayer and plot:FindFirstChild('OriginSquare') then
            return plot
        end
    end
    return nil
end
local function findWireTemplate()
    local purchasables = ReplicatedStorage:FindFirstChild('Purchasables')
    return purchasables and purchasables:FindFirstChild('Wire', true)
end
local function findOwnedPurchasedWire()
    local models = Workspace:FindFirstChild('PlayerModels')
    if not models then return nil end
    for _, item in ipairs(models:GetChildren()) do
        local owner = item:FindFirstChild('Owner')
        local purchased = item:FindFirstChild('PurchasedBoxItemName')
        if owner and owner.Value == LocalPlayer and purchased and tostring(purchased.Value) == 'Wire' then
            return item
        end
    end
    return nil
end
local gui = Instance.new('ScreenGui')
gui.Name = 'MysticsWireArtLab'
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild('PlayerGui')
local frame = Instance.new('Frame')
frame.Name = 'Panel'
frame.Size = UDim2.fromOffset(330, 170)
frame.Position = UDim2.new(0.5, -165, 0.5, -85)
frame.BackgroundColor3 = Color3.fromRGB(25, 12, 17)
frame.BorderSizePixel = 0
frame.Parent = gui
local title = Instance.new('TextLabel')
title.Size = UDim2.new(1, -20, 0, 34)
title.Position = UDim2.fromOffset(10, 8)
title.BackgroundTransparency = 1
title.Text = 'MYSTICS / WIRE PLACEMENT LAB'
title.TextColor3 = Color3.fromRGB(255, 85, 110)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = frame
local status = Instance.new('TextLabel')
status.Size = UDim2.new(1, -20, 0, 52)
status.Position = UDim2.fromOffset(10, 44)
status.BackgroundTransparency = 1
status.TextWrapped = true
status.Text = 'Checks setup, then sends at most one short test wire.'
status.TextColor3 = Color3.fromRGB(235, 220, 225)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.Parent = frame
local test = Instance.new('TextButton')
test.Size = UDim2.new(1, -20, 0, 34)
test.Position = UDim2.fromOffset(10, 102)
test.BackgroundColor3 = Color3.fromRGB(135, 25, 48)
test.Text = 'PLACE ONE TEST WIRE'
test.TextColor3 = Color3.new(1, 1, 1)
test.Font = Enum.Font.GothamBold
test.TextSize = 12
test.Parent = frame
local close = Instance.new('TextButton')
close.Size = UDim2.fromOffset(24, 24)
close.Position = UDim2.new(1, -30, 0, 8)
close.BackgroundTransparency = 1
close.Text = 'X'
close.TextColor3 = Color3.new(1, 1, 1)
close.Parent = frame
close.MouseButton1Click:Connect(function() gui:Destroy() end)
local busy = false
test.MouseButton1Click:Connect(function()
    if busy then return end
    busy = true
    test.Active = false
    status.Text = 'Checking plot, remote, template and purchased Wire...'
    local ok, result = pcall(function()
        local plot = findOwnedPlot()
        if not plot then error('No owned plot with OriginSquare found.') end
        local template = findWireTemplate()
        if not template then error('No Wire template found under ReplicatedStorage.Purchasables.') end
        local remoteFolder = ReplicatedStorage:FindFirstChild('PlaceStructure')
        local remote = remoteFolder and remoteFolder:FindFirstChild('ClientPlacedWire')
        if not remote or not remote:IsA('RemoteEvent') then error('ClientPlacedWire RemoteEvent missing.') end
        local purchasedWire = findOwnedPurchasedWire()
        if not purchasedWire then error('No owned purchased Wire model found in Workspace.PlayerModels.') end
        local origin = plot.OriginSquare.Position
        local points = {origin + Vector3.new(0, 5, 0), origin + Vector3.new(0, 10, 0)}
        -- Public LT2 reference pattern: template, points, player, purchased Wire, true.
        remote:FireServer(template, points, LocalPlayer, purchasedWire, true)
        return 'One request sent. Check your plot above the OriginSquare for a short vertical wire.'
    end)
    status.Text = ok and result or ('Test stopped: ' .. tostring(result))
    busy = false
    test.Active = true
end)