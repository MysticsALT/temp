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
frame.Size = UDim2.fromOffset(380, 260)
frame.Position = UDim2.new(0.5, -190, 0.5, -130)
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
status.Size = UDim2.new(1, -20, 0, 92)
status.Position = UDim2.fromOffset(10, 42)
status.BackgroundTransparency = 1
status.TextWrapped = true
status.Text = 'Run the storage scan first. Do not test placement until a Wire template is located.'
status.TextColor3 = Color3.fromRGB(235, 220, 225)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.Parent = frame
local test = Instance.new('TextButton')
test.Size = UDim2.new(1, -20, 0, 34)
test.Position = UDim2.fromOffset(10, 198)
test.BackgroundColor3 = Color3.fromRGB(135, 25, 48)
test.Text = 'PLACE ONE TEST WIRE'
test.TextColor3 = Color3.new(1, 1, 1)
test.Font = Enum.Font.GothamBold
test.TextSize = 12
test.Parent = frame
local scan = Instance.new('TextButton')
scan.Size = UDim2.new(1, -20, 0, 34)
scan.Position = UDim2.fromOffset(10, 144)
scan.BackgroundColor3 = Color3.fromRGB(65, 35, 48)
scan.Text = 'SCAN REPLICATED STORAGE'
scan.TextColor3 = Color3.new(1, 1, 1)
scan.Font = Enum.Font.GothamBold
scan.TextSize = 12
scan.Parent = frame
scan.MouseButton1Click:Connect(function()
    local lines = {"REPLICATEDSTORAGE SCAN"}
    local direct = {}
    for _, child in ipairs(ReplicatedStorage:GetChildren()) do
        direct[#direct+1] = child.Name .. " [" .. child.ClassName .. "]"
    end
    lines[#lines+1] = "Top-level: " .. (#direct > 0 and table.concat(direct, ", ") or "(none)")
    local hits, count = {}, 0
    for _, item in ipairs(ReplicatedStorage:GetDescendants()) do
        local n = string.lower(item.Name)
        if n == "purchasables" or n == "wireobjects" or n == "wire" or n == "otherinfo" then
            count += 1
            if #hits < 35 then hits[#hits+1] = item:GetFullName() .. " [" .. item.ClassName .. "]" end
        end
    end
    lines[#lines+1] = "Matching descendants (" .. count .. "):"
    for _, hit in ipairs(hits) do lines[#lines+1] = hit end
    if count == 0 then lines[#lines+1] = "No matching names replicated to this client." end
    status.Text = table.concat(lines, "\n")
end)
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
        if not template then error('No replicated Wire template found. Run SCAN REPLICATED STORAGE and share its output.') end
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