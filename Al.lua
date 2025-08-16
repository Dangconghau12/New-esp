--[[
Universal ESP + Team + Health + Tracers + Hitbox (5 teams)
By Conghau — 2025-08-16

Features:
- ESP with up to 5 team colors (auto-detect from Player.Team / TeamColor / Name)
- Name + Health (and distance) above head
- Tracer lines (Drawing API) from bottom-center of screen to player head
- Auto-updates: player join/leave, character spawn/death/respawn
- Hitbox toggle: enlarge HumanoidRootPart (HRP) on ON, restore on OFF
- Simple draggable menu with toggles (+ menu box toggle)

Notes:
- Tracers need an executor with Drawing API. If not available, tracers auto-disable.
- Hitbox is client-side only.
- LocalPlayer is ignored.
]]

---

-- CONFIG

local TEAM_COLORS = {
    Color3.fromRGB(255, 75, 75),   -- Team 1 (Red)
    Color3.fromRGB(75, 150, 255),  -- Team 2 (Blue)
    Color3.fromRGB(100, 255, 120), -- Team 3 (Green)
    Color3.fromRGB(255, 210, 70),  -- Team 4 (Yellow)
    Color3.fromRGB(200, 120, 255), -- Team 5 (Purple)
}
local HITBOX_SIZE = Vector3.new(6, 6, 6)  -- HRP size when hitbox is enabled
local SHOW_DISTANCE = true                -- show distance in the label

---

-- SERVICES / SHORTCUTS

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

---

-- GLOBAL STATE

local State = {
    espEnabled = false,
    tracerEnabled = false,
    hitboxEnabled = false,
    menuBoxEnabled = false, -- Thêm trạng thái menu box
}

local HasDrawing = pcall(function()
    return Drawing and typeof(Drawing.new) == "function"
end)

-- Player -> container with created objects & connections
local ESPMap = {}

-- Team mapping: any unique team key -> 1..5 index
local TeamIndexMap = {}

---

-- UTILS

local function safeDisconnect(conn)
    if conn then pcall(function() conn:Disconnect() end) end
end

local function formatNum(n)
    n = math.floor(n or 0)
    if n >= 1000 then
        return string.format("%.1fk", n/1000)
    end
    return tostring(n)
end

local function getTeamKey(p)
    if p.Team ~= nil then
        return "T:" .. (p.Team.Name or "Unknown")
    elseif p.TeamColor ~= nil then
        return "C:" .. tostring(p.TeamColor)
    else
        return "N:" .. p.Name
    end
end

local function getTeamColor(p)
    local key = getTeamKey(p)
    if not TeamIndexMap[key] then
        -- assign next slot 1..5 (cycling if >5 distinct keys)
        local count = 0
        for _ in pairs(TeamIndexMap) do count += 1 end
        local idx = (count % 5) + 1
        TeamIndexMap[key] = idx
    end
    return TEAM_COLORS[TeamIndexMap[key]] or TEAM_COLORS[1]
end

local function worldToScreen(v3)
    local v, onScreen = Camera:WorldToViewportPoint(v3)
    return Vector2.new(v.X, v.Y), onScreen, v.Z
end

---

-- UI (simple draggable menu + menu box)

local menuBoxFrame -- frame để hiện menu box

local function updateMenuBox()
    if State.menuBoxEnabled then
        if not menuBoxFrame then
            menuBoxFrame = Instance.new("Frame")
            menuBoxFrame.Size = UDim2.fromOffset(40, 40)
            menuBoxFrame.Position = UDim2.new(1, -50, 0, 10) -- góc phải trên
            menuBoxFrame.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
            menuBoxFrame.Parent = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("UniversalESP_Menu")
            Instance.new("UICorner", menuBoxFrame).CornerRadius = UDim.new(0, 12)
        end
        menuBoxFrame.Visible = true
    else
        if menuBoxFrame then
            menuBoxFrame.Visible = false
        end
    end
end

local function createUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "UniversalESP_Menu"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")  
    frame.Size = UDim2.fromOffset(220, 180)  
    frame.Position = UDim2.new(0, 20, 0.5, -90)  
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)  
    frame.BorderSizePixel = 0  
    frame.Active = true  
    frame.Draggable = true  
    frame.Parent = gui  
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)  

    local title = Instance.new("TextLabel")  
    title.Size = UDim2.new(1, -10, 0, 28)  
    title.Position = UDim2.fromOffset(10, 6)  
    title.BackgroundTransparency = 1  
    title.Text = "Universal ESP"  
    title.Font = Enum.Font.GothamBold  
    title.TextSize = 18  
    title.TextColor3 = Color3.new(1,1,1)  
    title.TextXAlignment = Enum.TextXAlignment.Left  
    title.Parent = frame  

    local function makeToggle(y, label, getFn, setFn)  
        local btn = Instance.new("TextButton")  
        btn.Size = UDim2.new(1, -20, 0, 30)  
        btn.Position = UDim2.fromOffset(10, y)  
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)  
        btn.BorderSizePixel = 0  
        btn.TextColor3 = Color3.new(1,1,1)  
        btn.Font = Enum.Font.Gotham  
        btn.TextSize = 16  
        btn.AutoButtonColor = true  
        btn.Parent = frame  
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)  

        local function refresh()  
            local on = getFn()  
            btn.Text = (on and "ON  | " or "OFF | ") .. label  
            btn.BackgroundColor3 = on and Color3.fromRGB(35, 120, 70) or Color3.fromRGB(90, 35, 35)  
        end  

        btn.MouseButton1Click:Connect(function()  
            setFn(not getFn())  
            refresh()  
        end)  
        refresh()  
        return btn  
    end  

    makeToggle(40, "ESP", function() return State.espEnabled end, function(v) State.espEnabled = v end)  
    makeToggle(75, "Tracer", function() return State.tracerEnabled end, function(v) State.tracerEnabled = v end)  
    makeToggle(110,"Hitbox", function() return State.hitboxEnabled end, function(v) State.hitboxEnabled = v end)
    makeToggle(145,"Menu Box", function() return State.menuBoxEnabled end, function(v) State.menuBoxEnabled = v end) -- Toggle cho menu box

    local note = Instance.new("TextLabel")  
    note.Size = UDim2.new(1, -10, 0, 18)  
    note.Position = UDim2.fromOffset(10, 170)  
    note.BackgroundTransparency = 1  
    note.Text = HasDrawing and "Drawing API: YES (tracers enabled)" or "Drawing API: NO (tracers disabled)"  
    note.Font = Enum.Font.Gotham  
    note.TextSize = 12  
    note.TextColor3 = Color3.fromRGB(200,200,200)  
    note.TextXAlignment = Enum.TextXAlignment.Left  
    note.Parent = frame

end

---

-- ESP BUILDERS
-- (giữ nguyên như code gốc)
-- ... [phần này giữ nguyên]

---

-- APPLY / REMOVE HELPERS
-- (giữ nguyên như code gốc)
-- ... [phần này giữ nguyên]

---

-- GLOBAL APPLY

local function applyEspVisibility()
    for _,container in pairs(ESPMap) do
        if container.gui then container.gui.Enabled = State.espEnabled end
        if container.highlight then container.highlight.Enabled = State.espEnabled end
        if container.box then container.box.Visible = State.espEnabled end
        if container.tracer then container.tracer.Visible = (State.espEnabled and State.tracerEnabled) end
    end
end

local function applyHitboxAll()
    for _,container in pairs(ESPMap) do
        if container.character then
            applyHitbox(container.character, State.hitboxEnabled, container.originals)
        end
    end
end

---

-- TRACER UPDATE LOOP
-- ... [phần này giữ nguyên]

---

-- PLAYERS HOOK
-- ... [phần này giữ nguyên]

---

-- MENU + FEEDBACK

createUI()

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Universal ESP",
        Text = string.format("Drawing: %s | Teams: %d", HasDrawing and "YES" or "NO", #TEAM_COLORS),
        Duration = 6
    })
end)

-- reactive apply when toggles change
task.spawn(function()
    local last = {esp=false, tracer=false, hit=false, box=false}
    while true do
        if State.espEnabled ~= last.esp or State.tracerEnabled ~= last.tracer then
            applyEspVisibility()
            last.esp = State.espEnabled
            last.tracer = State.tracerEnabled
        end
        if State.hitboxEnabled ~= last.hit then
            applyHitboxAll()
            last.hit = State.hitboxEnabled
        end
        if State.menuBoxEnabled ~= last.box then
            updateMenuBox()
            last.box = State.menuBoxEnabled
        end
        task.wait(0.25)
    end
end)

---
