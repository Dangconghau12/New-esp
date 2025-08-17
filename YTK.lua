-- ZilpX ESP MENU - Không box, line/tracer đã fix, giao diện đỏ đen, menu kéo, tính năng đầy đủ
local logoUrl = "https://i.imgur.com/nvFqJiJ.png"

local State = {
    espEnabled = false,
    tracerEnabled = false,
    hitboxEnabled = false,
    hitboxHeadEnabled = false,
    aimEnabled = false,
    lockAimEnabled = false,
    fov = 120,
    hitboxSize = 6,
    hitboxHeadSize = 10,
    aimSmooth = 0.22,
}
local TEAM_COLORS = {
    Color3.fromRGB(255, 75, 75), Color3.fromRGB(75, 150, 255), Color3.fromRGB(100, 255, 120), Color3.fromRGB(255, 210, 70),
    Color3.fromRGB(200, 120, 255), Color3.fromRGB(255, 140, 0), Color3.fromRGB(0, 220, 255), Color3.fromRGB(255, 255, 255),
}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local HasDrawing = pcall(function() return Drawing and typeof(Drawing.new) == "function" end)
local ESPMap, TeamIndexMap = {}, {}

local function getTeamKey(p) if p.Team then return "T:"..(p.Team.Name or "") elseif p.TeamColor then return "C:"..tostring(p.TeamColor) else return "N:"..p.Name end end
local function getTeamColor(p) local key=getTeamKey(p) if not TeamIndexMap[key] then local c=0 for _ in pairs(TeamIndexMap) do c=c+1 end TeamIndexMap[key]=(c%8)+1 end return TEAM_COLORS[TeamIndexMap[key]] end
local function worldToScreen(v3) local v,on=Camera:WorldToViewportPoint(v3) return Vector2.new(v.X,v.Y),on,v.Z end
local function formatNum(n) n=math.floor(n or 0) if n>=1000 then return string.format("%.1fk",n/1000) end return tostring(n) end

-- MENU UI (giữ nguyên như bản trước)
local function createUI()
    local plr = LocalPlayer
    local gui = Instance.new("ScreenGui")
    gui.Name = "ZilpXMenu"
    gui.Parent = plr:WaitForChild("PlayerGui")
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local OpenBtn = Instance.new("ImageButton")
    OpenBtn.Size = UDim2.new(0,52,0,52)
    OpenBtn.Position = UDim2.new(0, 18, 0, 80)
    OpenBtn.BackgroundColor3 = Color3.fromRGB(32,0,0)
    OpenBtn.Image = logoUrl
    OpenBtn.ImageColor3 = Color3.new(1,1,1)
    OpenBtn.Visible = true
    OpenBtn.Parent = gui
    OpenBtn.AutoButtonColor = true
    local OpenBtnCorner = Instance.new("UICorner",OpenBtn)
    OpenBtnCorner.CornerRadius = UDim.new(1,0)
    local OpenBtnStroke = Instance.new("UIStroke",OpenBtn)
    OpenBtnStroke.Color = Color3.fromRGB(255,32,32)
    OpenBtnStroke.Thickness = 2

    local dragging, dragStart, startPos
    local function beginDrag(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = OpenBtn.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging=false end end)
        end
    end
    local function updateDrag(input)
        if dragging and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            local nx = math.clamp(startPos.X.Offset+delta.X,0,Camera.ViewportSize.X-OpenBtn.Size.X.Offset)
            local ny = math.clamp(startPos.Y.Offset+delta.Y,0,Camera.ViewportSize.Y-OpenBtn.Size.Y.Offset)
            OpenBtn.Position = UDim2.new(0,nx,0,ny)
        end
    end
    OpenBtn.InputBegan:Connect(beginDrag)
    OpenBtn.InputChanged:Connect(updateDrag)
    UserInputService.InputChanged:Connect(updateDrag)

    local menuW, menuH = 258, 370
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, menuW, 0, menuH)
    MainFrame.Position = UDim2.new(0, OpenBtn.Position.X.Offset+OpenBtn.Size.X.Offset+12, 0, OpenBtn.Position.Y.Offset)
    MainFrame.BackgroundColor3 = Color3.fromRGB(36,0,0)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = gui
    MainFrame.Visible = false
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0,14)
    UICorner.Parent = MainFrame
    local MainStroke = Instance.new("UIStroke",MainFrame)
    MainStroke.Color = Color3.fromRGB(200,0,0)
    MainStroke.Thickness = 2

    OpenBtn.MouseButton1Click:Connect(function()
        local px = OpenBtn.Position.X.Offset
        local py = OpenBtn.Position.Y.Offset
        MainFrame.Position = UDim2.new(0, px+OpenBtn.Size.X.Offset+10, 0, py)
        MainFrame.Visible = true
        OpenBtn.Visible = false
    end)

    local Title = Instance.new("TextLabel")
    Title.Text = "ZilpX Menu"
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundColor3 = Color3.fromRGB(80,0,0)
    Title.TextColor3 = Color3.fromRGB(255,70,70)
    Title.Font = Enum.Font.GothamBlack
    Title.TextSize = 17
    Title.TextStrokeTransparency = 0.7
    Title.TextStrokeColor3 = Color3.fromRGB(40,0,0)
    Title.Parent = MainFrame
    Title.BorderSizePixel = 0
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0,8)
    TitleCorner.Parent = Title

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0,22,0,22)
    CloseBtn.Position = UDim2.new(1,-27,0,4)
    CloseBtn.AnchorPoint = Vector2.new(0,0)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(180,0,0)
    CloseBtn.Text = "✕"
    CloseBtn.TextSize = 14
    CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
    CloseBtn.Font = Enum.Font.GothamBlack
    CloseBtn.Parent = MainFrame
    CloseBtn.ZIndex = 3
    local CloseBtnCorner = Instance.new("UICorner",CloseBtn)
    CloseBtnCorner.CornerRadius = UDim.new(1,0)
    local CloseStroke = Instance.new("UIStroke",CloseBtn)
    CloseStroke.Color = Color3.fromRGB(250,64,64)
    CloseStroke.Thickness = 1
    CloseBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        OpenBtn.Visible = true
        if fovCircle then fovCircle.Visible = false end
        for _,ct in pairs(ESPMap) do
            if ct.tracer then ct.tracer.Visible = false end
        end
    end)

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Position = UDim2.new(0,0,0,30)
    Scroll.Size = UDim2.new(1,0,1,-30-16)
    Scroll.CanvasSize = UDim2.new(0,0,0,400)
    Scroll.ScrollBarThickness = 6
    Scroll.ScrollBarImageColor3 = Color3.fromRGB(200,0,0)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.Parent = MainFrame

    local function createToggle(name, posY, getFn, setFn)
        local btn = Instance.new("TextButton")
        btn.Text = (getFn() and "✔️ " or "✖️ ")..name
        btn.Size = UDim2.new(0.93, 0, 0, 24)
        btn.Position = UDim2.new(0.035, 0, 0, posY)
        btn.BackgroundColor3 = getFn() and Color3.fromRGB(195,0,32) or Color3.fromRGB(49,0,0)
        btn.TextColor3 = Color3.new(1,0.6,0.6)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.Parent = Scroll
        btn.ZIndex = 2
        btn.AutoButtonColor = true
        btn.BorderSizePixel = 0
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 7)
        corner.Parent = btn
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255,40,40)
        stroke.Thickness = 1
        stroke.Parent = btn
        btn.MouseButton1Click:Connect(function()
            setFn(not getFn())
            btn.BackgroundColor3 = getFn() and Color3.fromRGB(195,0,32) or Color3.fromRGB(49,0,0)
            btn.Text = (getFn() and "✔️ " or "✖️ ")..name
        end)
    end

    local function createNumBox(label, posY, getFn, setFn, min, max)
        local lbl = Instance.new("TextLabel")
        lbl.Text = label
        lbl.Size = UDim2.new(0.52, 0, 0, 20)
        lbl.Position = UDim2.new(0.035, 0, 0, posY)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.fromRGB(255,100,100)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = Scroll
        lbl.ZIndex = 2

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0.35, 0, 0, 20)
        box.Position = UDim2.new(0.60, 0, 0, posY)
        box.Text = tostring(getFn())
        box.BackgroundColor3 = Color3.fromRGB(90,0,0)
        box.TextColor3 = Color3.fromRGB(255,180,180)
        box.Font = Enum.Font.GothamBold
        box.TextSize = 11
        box.Parent = Scroll
        box.ZIndex = 2
        box.BorderSizePixel = 0
        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(0, 6)
        UICorner.Parent = box
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255,38,38)
        stroke.Thickness = 1
        stroke.Parent = box
        box.FocusLost:Connect(function()
            local x = tonumber(box.Text)
            if x and x >= min and x <= max then setFn(x) end
            box.Text = tostring(getFn())
        end)
    end

    local y = 4
    createToggle("ESP", y, function() return State.espEnabled end, function(v) State.espEnabled = v end)
    y = y + 28
    createToggle("Tracer", y, function() return State.tracerEnabled end, function(v) State.tracerEnabled = v end)
    y = y + 28
    createToggle("Hitbox Thân", y, function() return State.hitboxEnabled end, function(v) State.hitboxEnabled = v end)
    y = y + 28
    createToggle("Hitbox Đầu", y, function() return State.hitboxHeadEnabled end, function(v) State.hitboxHeadEnabled = v end)
    y = y + 28
    createToggle("Aim", y, function() return State.aimEnabled end, function(v) State.aimEnabled = v end)
    y = y + 28
    createToggle("Lock Aim", y, function() return State.lockAimEnabled end, function(v) State.lockAimEnabled = v end)

    y = y + 32
    createNumBox("Aim FOV", y, function() return State.fov end, function(v) State.fov = v end, 10, 180)
    y = y + 22
    createNumBox("Hitbox Thân", y, function() return State.hitboxSize end, function(v) State.hitboxSize = v end, 5, 20)
    y = y + 22
    createNumBox("Hitbox Đầu", y, function() return State.hitboxHeadSize end, function(v) State.hitboxHeadSize = v end, 5, 20)
    y = y + 22
    createNumBox("Aim Smooth", y, function() return State.aimSmooth end, function(v) State.aimSmooth = v end, 0.01, 1)

    Scroll.CanvasSize = UDim2.new(0,0,0,y+32)

    local note = Instance.new("TextLabel")
    note.Text = "ZilpX Menu | Drawing API: "..(HasDrawing and "YES" or "NO")
    note.Size = UDim2.new(1, -12, 0, 14)
    note.Position = UDim2.new(0, 6, 1, -16)
    note.BackgroundTransparency = 1
    note.Font = Enum.Font.Gotham
    note.TextSize = 10
    note.TextColor3 = Color3.fromRGB(250,64,64)
    note.TextStrokeTransparency = 0.68
    note.TextXAlignment = Enum.TextXAlignment.Right
    note.Parent = MainFrame
    note.ZIndex = 2
end

-- LOGIC (KHÔNG TẠO BOX)
local function safeDisconnect(conn) if conn then pcall(function() conn:Disconnect() end) end end
local function makeBillboard(character, player)
    local head = character:FindFirstChild("Head") if not head then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_Nameplate" bb.AlwaysOnTop = true bb.Size = UDim2.new(0, 200, 0, 40)
    bb.StudsOffset = Vector3.new(0, 3, 0) bb.Adornee = head bb.Parent = character
    local tl = Instance.new("TextLabel") tl.Name = "Label" tl.BackgroundTransparency = 1
    tl.Size = UDim2.new(1, 0, 1, 0) tl.Font = Enum.Font.GothamBold tl.TextSize = 14
    tl.TextColor3 = getTeamColor(player) tl.TextStrokeTransparency = 0.5 tl.TextYAlignment = Enum.TextYAlignment.Center tl.Parent = bb
    return bb, tl
end
local function makeHighlight(character, player)
    local h = Instance.new("Highlight") h.Name = "ESP_Highlight"
    h.FillTransparency = 1 h.OutlineTransparency = 0 h.OutlineColor = getTeamColor(player)
    h.Adornee = character h.Parent = character return h
end
local function makeTracer(character, player)
    if not HasDrawing then return nil end
    local line = Drawing.new("Line") line.Thickness = 2 line.Transparency = 1
    line.Visible = false line.Color = getTeamColor(player) return line
end
local function updateNameplateText(tl, player, humanoid, character)
    if not tl or not tl.Parent then return end
    local hp = (humanoid and humanoid.Health) or 0
    local maxHp = (humanoid and humanoid.MaxHealth) or 100
    local percent = (maxHp > 0) and math.clamp(hp / maxHp * 100, 0, 999) or 0
    local dist = ""
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local d = (hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        dist = string.format(" | %dm", math.floor(d + 0.5))
    end
    tl.Text = string.format("%s | HP: %s/%s (%.0f%%%s)", player.Name, formatNum(hp), formatNum(maxHp), percent, dist)
end
local function isEnemy(p) return p ~= LocalPlayer and ((LocalPlayer.Team and p.Team ~= LocalPlayer.Team) or not LocalPlayer.Team) end
local function applyHitbox(character, enable, store, player)
    if not isEnemy(player) then return end
    local hrp = character:FindFirstChild("HumanoidRootPart") if not hrp then return end
    if enable then
        if store then store.hrpSize = hrp.Size store.hrpCollide = hrp.CanCollide store.hrpMassless = hrp.Massless end
        pcall(function() hrp.Size = Vector3.new(State.hitboxSize,State.hitboxSize,State.hitboxSize) hrp.Massless = true hrp.CanCollide = false end)
    else
        if store and store.hrpSize then
            pcall(function() hrp.Size = store.hrpSize hrp.CanCollide = store.hrpCollide hrp.Massless = store.hrpMassless end)
        end
    end
end
local function applyHitboxHead(character, enable, store, player)
    if not isEnemy(player) then return end
    local head = character:FindFirstChild("Head") if not head then return end
    if enable then
        if store then store.headSize = head.Size store.headMassless = head.Massless store.headCollide = head.CanCollide end
        pcall(function() head.Size = Vector3.new(State.hitboxHeadSize,State.hitboxHeadSize,State.hitboxHeadSize) head.Massless = true head.CanCollide = false end)
    else
        if store and store.headSize then
            pcall(function() head.Size = store.headSize head.Massless = store.headMassless head.CanCollide = store.headCollide end)
        end
    end
end

local function createESPForPlayer(p)
    local container = { conns = {}, originals = {} }
    ESPMap[p] = container
    local function onCharacter(char)
        container.character = char
        local humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 10)
        local bb, label = makeBillboard(char, p)
        container.gui = bb
        container.label = label
        container.highlight = makeHighlight(char, p)
        container.tracer = makeTracer(char, p)
        if humanoid then
            table.insert(container.conns, humanoid.HealthChanged:Connect(function()
                updateNameplateText(label, p, humanoid, char)
            end))
            updateNameplateText(label, p, humanoid, char)
            table.insert(container.conns, humanoid.Died:Connect(function()
                removeESPForPlayer(p)
            end))
        end
        local visible = State.espEnabled
        if container.gui then container.gui.Enabled = visible end
        if container.highlight then container.highlight.Enabled = visible end
        if container.tracer then container.tracer.Visible = (visible and State.tracerEnabled) end
        applyHitbox(char, State.hitboxEnabled, container.originals, p)
        applyHitboxHead(char, State.hitboxHeadEnabled, container.originals, p)
    end
    if p.Character then onCharacter(p.Character) end
    table.insert(container.conns, p.CharacterAdded:Connect(function(c) onCharacter(c) end))
end

local function removeESPForPlayer(p)
    local container = ESPMap[p]
    if not container then return end
    if container.character then
        applyHitbox(container.character, false, container.originals, p)
        applyHitboxHead(container.character, false, container.originals, p)
    end
    for _,c in ipairs(container.conns) do safeDisconnect(c) end
    if container.gui then pcall(function() container.gui:Destroy() end) end
    if container.highlight then pcall(function() container.highlight:Destroy() end) end
    if container.tracer then pcall(function() container.tracer.Visible=false; container.tracer:Remove() end) end
    ESPMap[p] = nil
end

local function applyEspVisibility()
    for p,container in pairs(ESPMap) do
        local show = State.espEnabled
        if container.gui then container.gui.Enabled = show end
        if container.highlight then container.highlight.Enabled = show end
        if container.tracer then container.tracer.Visible = (show and State.tracerEnabled) end
    end
end

local function applyHitboxAll()
    for p,container in pairs(ESPMap) do
        if container.character then
            applyHitbox(container.character, State.hitboxEnabled, container.originals, p)
        end
    end
end

local function applyHitboxHeadAll()
    for p,container in pairs(ESPMap) do
        if container.character then
            applyHitboxHead(container.character, State.hitboxHeadEnabled, container.originals, p)
        end
    end
end

-- AIMBOT/LOCK AIM/FOV giữ nguyên như cũ
local function getClosestTargetToCrosshair(lockMode)
    local closest, closestDist = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()
    for p, container in pairs(ESPMap) do
        if isEnemy(p) then
            local char = container.character
            if char and char.Parent and char:FindFirstChild("Head") and char ~= LocalPlayer.Character then
                local head = char.Head
                local pos2D, onScreen = worldToScreen(head.Position)
                local dist
                if lockMode then
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
                        dist = (LocalPlayer.Character.Head.Position - head.Position).Magnitude
                    else
                        dist = math.huge
                    end
                else
                    dist = (pos2D - mousePos).Magnitude
                end
                if onScreen and dist < closestDist and dist <= State.fov then
                    closest = head
                    closestDist = dist
                end
            end
        end
    end
    return closest
end

local aimingConn, lockAimingConn
task.spawn(function()
    local lastAim, lastLockAim = false, false
    while true do
        if State.aimEnabled ~= lastAim then
            if State.aimEnabled then
                if not aimingConn then
                    aimingConn = RunService.RenderStepped:Connect(function(dt)
                        local target = getClosestTargetToCrosshair(false)
                        if target then
                            local camPos = Camera.CFrame.Position
                            local targetLook = (target.Position - camPos).Unit
                            local currentLook = Camera.CFrame.LookVector
                            local mouseDelta = UserInputService:GetMouseDelta()
                            if Vector2.new(mouseDelta.X, mouseDelta.Y).Magnitude > 0.5 then return end
                            local smooth = State.aimSmooth or 0.2
                            local blended = currentLook:Lerp(targetLook, math.clamp(smooth, 0, 1))
                            Camera.CFrame = CFrame.new(camPos, camPos + blended)
                        end
                    end)
                end
            else
                if aimingConn then aimingConn:Disconnect(); aimingConn = nil end
            end
            lastAim = State.aimEnabled
        end
        if State.lockAimEnabled ~= lastLockAim then
            if State.lockAimEnabled then
                if not lockAimingConn then
                    lockAimingConn = RunService.RenderStepped:Connect(function()
                        local target = getClosestTargetToCrosshair(true)
                        if target then
                            local camPos = Camera.CFrame.Position
                            Camera.CFrame = CFrame.new(camPos, target.Position)
                        end
                    end)
                end
            else
                if lockAimingConn then lockAimingConn:Disconnect(); lockAimingConn = nil end
            end
            lastLockAim = State.lockAimEnabled
        end
        task.wait(0.15)
    end
end)

-- TRACER UPDATE (Đã fix: line không lỗi, không lag, chỉ hiện khi đúng điều kiện)
RunService.RenderStepped:Connect(function()
    if not State.espEnabled or not State.tracerEnabled or not HasDrawing or not next(ESPMap) then
        for _,ct in pairs(ESPMap) do
            if ct.tracer then ct.tracer.Visible = false end
        end
        return
    end
    local screenBottom = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y - 2)
    for _,ct in pairs(ESPMap) do
        local char = ct.character
        local tracer = ct.tracer
        if tracer and char and char.Parent then
            local head = char:FindFirstChild("Head")
            if head then
                local pos2D, onScreen = worldToScreen(head.Position)
                if onScreen then
                    tracer.From = screenBottom
                    tracer.To = pos2D
                    tracer.Visible = true
                else
                    tracer.Visible = false
                end
            else
                tracer.Visible = false
            end
        elseif tracer then
            tracer.Visible = false
        end
    end
end)

-- FOV Circle update
local fovCircle
local function updateFOVCircle()
    if not HasDrawing then return end
    if State.aimEnabled or State.lockAimEnabled then
        if not fovCircle then
            fovCircle = Drawing.new("Circle")
            fovCircle.Thickness = 2
            fovCircle.Transparency = 1
            fovCircle.Color = Color3.new(1,0,0)
            fovCircle.Filled = false
            fovCircle.ZIndex = 99
        end
        local center = Camera.ViewportSize/2
        fovCircle.Position = Vector2.new(center.X, center.Y)
        fovCircle.Visible = true
        fovCircle.Radius = State.fov
    else
        if fovCircle then fovCircle.Visible = false end
    end
end
task.spawn(function()
    local lastAim, lastLockAim, lastFov = false, false, State.fov
    while true do
        if (State.aimEnabled ~= lastAim) or (State.lockAimEnabled ~= lastLockAim) or (State.fov ~= lastFov) then
            updateFOVCircle()
            lastAim = State.aimEnabled
            lastLockAim = State.lockAimEnabled
            lastFov = State.fov
        end
        task.wait(0.1)
    end
end)

local function refreshPlayers()
    for p,_ in pairs(ESPMap) do
        if not Players:FindFirstChild(p.Name) then removeESPForPlayer(p) end
    end
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not ESPMap[p] then createESPForPlayer(p) end
    end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then createESPForPlayer(p) end
end)
Players.PlayerRemoving:Connect(function(p)
    removeESPForPlayer(p)
end)
RunService.Heartbeat:Connect(refreshPlayers)

-- APPLY MENU
createUI()

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "ZilpX Menu",
        Text = string.format("Drawing: %s | Teams: %d", HasDrawing and "YES" or "NO", #TEAM_COLORS),
        Duration = 6
    })
end)

task.spawn(function()
    local last = {esp=false, tracer=false, hit=false, head=false, fov=State.fov, hsize=State.hitboxSize, hhead=State.hitboxHeadSize, smooth=State.aimSmooth}
    while true do
        if State.espEnabled ~= last.esp or State.tracerEnabled ~= last.tracer then
            applyEspVisibility()
            last.esp = State.espEnabled
            last.tracer = State.tracerEnabled
        end
        if State.hitboxEnabled ~= last.hit or State.hitboxSize ~= last.hsize then
            applyHitboxAll()
            last.hit = State.hitboxEnabled
            last.hsize = State.hitboxSize
        end
        if State.hitboxHeadEnabled ~= last.head or State.hitboxHeadSize ~= last.hhead then
            applyHitboxHeadAll()
            last.head = State.hitboxHeadEnabled
            last.hhead = State.hitboxHeadSize
        end
        last.fov = State.fov
        last.smooth = State.aimSmooth
        task.wait(0.25)
    end
end)
