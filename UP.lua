-- CONG HAU ESP VIP CAO CẤP FULL CODE (Key: MenuVip1)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local keyRequired = "MenuVip1"
local keyUnlocked = false
local menuActivated = false
local menuCircleBtn, menuFrame
local posList = {"left","right","top","bottom"}
local posIndex = 1
local menuPositions = {
    left = UDim2.new(0, 20, 0.5, -24),
    right = UDim2.new(1, -70, 0.5, -24),
    top = UDim2.new(0.5, -24, 0, 18),
    bottom = UDim2.new(0.5, -24, 1, -68),
}

local State = {
    esp = false,
    tracer = false,
    hitbox = false,
    hitboxHead = false,
    aim = false,
    fov = 110,
    hitboxSize = 6,
    hitboxHeadSize = 8,
    highlight = false,
    lockhp = false,
    heal = false,
    showTeam = false,
    showWeapon = false,
    menu = false,
    menupos = "left",
}

local ESPMap = {}

--------------------------
-- Auto ESP Update & Tracer
--------------------------
local function getTeamColor(p)
    if p.Team and p.TeamColor then
        return p.TeamColor.Color
    else
        return Color3.fromRGB(255,255,0)
    end
end

local function formatNum(n)
    return math.floor(n or 0)
end

local function updateESP()
    for _,obj in pairs(ESPMap) do
        if obj.bb then pcall(function() obj.bb:Destroy() end) end
        if obj.tracer then pcall(function() obj.tracer:Remove() end) end
        if obj.highlight then pcall(function() obj.highlight:Destroy() end) end
    end
    ESPMap = {}

    if not State.esp or not keyUnlocked or not menuActivated then return end

    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local char = p.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.new(0, 140, 0, 32)
            bb.AlwaysOnTop = true
            bb.Adornee = char.Head
            bb.Parent = char
            local tl = Instance.new("TextLabel")
            tl.Size = UDim2.new(1,0,1,0)
            tl.BackgroundTransparency = 1
            tl.Font = Enum.Font.GothamBold
            tl.TextSize = 14
            tl.TextColor3 = getTeamColor(p)
            tl.TextStrokeTransparency = 0.5
            local hp = (char:FindFirstChildOfClass("Humanoid") and char:FindFirstChildOfClass("Humanoid").Health) or 0
            local maxHp = (char:FindFirstChildOfClass("Humanoid") and char:FindFirstChildOfClass("Humanoid").MaxHealth) or 100
            local dist = hrp and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and
                math.floor((hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude + 0.5) or 0
            tl.Text = p.Name.." | HP: "..formatNum(hp).."/"..formatNum(maxHp).." | "..dist.."m"
            if State.showTeam and p.Team then tl.Text = tl.Text.." | "..p.Team.Name end
            if State.showWeapon and p.Backpack then
                for _,tool in ipairs(p.Backpack:GetChildren()) do
                    if tool:IsA("Tool") then tl.Text = tl.Text.." | "..tool.Name end
                end
            end
            tl.Parent = bb

            -- Highlight
            local highlight = nil
            if State.highlight then
                highlight = Instance.new("Highlight")
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0
                highlight.OutlineColor = getTeamColor(p)
                highlight.Adornee = char
                highlight.Parent = char
            end

            -- Tracer
            local tracer = nil
            local hasDrawing = pcall(function() return Drawing and typeof(Drawing.new)=="function" end)
            if State.tracer and hasDrawing then
                tracer = Drawing.new("Line")
                tracer.Thickness = 1.8
                tracer.Transparency = 0.9
                tracer.Color = getTeamColor(p)
                tracer.Visible = true
            end

            ESPMap[p] = {bb=bb, tl=tl, tracer=tracer, highlight=highlight, char=char}
        end
    end
end

task.spawn(function()
    while true do
        updateESP()
        wait(1.5)
    end
end)

RunService.RenderStepped:Connect(function()
    for p,ct in pairs(ESPMap) do
        local char = ct.char
        if ct.bb then
            ct.bb.Enabled = State.esp and keyUnlocked and menuActivated
        end
        if ct.highlight then
            ct.highlight.Enabled = State.highlight and keyUnlocked and menuActivated
        end
        if ct.tracer and char and char:FindFirstChild("Head") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
            local Camera = workspace.CurrentCamera
            local screenBottom = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y - 2)
            local head = char.Head
            local pos2D, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                ct.tracer.From = screenBottom
                ct.tracer.To = Vector2.new(pos2D.X, pos2D.Y)
                ct.tracer.Visible = State.tracer and keyUnlocked and menuActivated
            else
                ct.tracer.Visible = false
            end
        elseif ct.tracer then
            ct.tracer.Visible = false
        end
    end
end)

--------------------------
-- Hitbox Thân/Đầu
--------------------------
local function applyHitboxAll()
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local head = p.Character:FindFirstChild("Head")
            if hrp then
                hrp.Size = State.hitbox and Vector3.new(State.hitboxSize,State.hitboxSize,State.hitboxSize) or Vector3.new(2,2,1)
                hrp.CanCollide = not State.hitbox
                hrp.Massless = State.hitbox
            end
            if head then
                head.Size = State.hitboxHead and Vector3.new(State.hitboxHeadSize,State.hitboxHeadSize,State.hitboxHeadSize) or Vector3.new(1,1,1)
                head.CanCollide = not State.hitboxHead
                head.Massless = State.hitboxHead
            end
        end
    end
end

task.spawn(function()
    local lastHit, lastHead = false, false
    while true do
        if State.hitbox ~= lastHit or State.hitboxHead ~= lastHead then
            applyHitboxAll()
            lastHit = State.hitbox
            lastHead = State.hitboxHead
        end
        wait(1)
    end
end)

--------------------------
-- LOCK HP & HEAL
--------------------------
task.spawn(function()
    while true do
        if (State.lockhp or State.heal) and keyUnlocked and menuActivated then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    if State.lockhp and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
                    if State.heal and hum.Health < hum.MaxHealth then hum.Health = math.min(hum.Health + math.max(3, hum.MaxHealth*0.02), hum.MaxHealth) end
                end
            end
        end
        wait(0.25)
    end
end)

--------------------------
-- Aimbot & FOV Circle
--------------------------
local fovCircle
local function updateFOVCircle()
    if not State.aim or not keyUnlocked or not menuActivated then
        if fovCircle then fovCircle.Visible = false end
        return
    end
    if not fovCircle then
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 2
        fovCircle.Transparency = 1
        fovCircle.Color = Color3.new(1,1,1)
        fovCircle.Filled = false
        fovCircle.ZIndex = 99
    end
    local center = workspace.CurrentCamera.ViewportSize/2
    fovCircle.Position = Vector2.new(center.X, center.Y)
    fovCircle.Visible = true
    fovCircle.Radius = State.fov
end

task.spawn(function()
    local lastAim, lastFov = false, State.fov
    while true do
        if (State.aim ~= lastAim) or (State.fov ~= lastFov) then
            updateFOVCircle()
            lastAim = State.aim
            lastFov = State.fov
        end
        wait(0.2)
    end
end)

local function getClosestEnemy()
    local closest, closestDist = nil, math.huge
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local head = p.Character.Head
            local dist = (head.Position-myPos).Magnitude
            local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(head.Position)
            local fovDist = (Vector2.new(screenPos.X, screenPos.Y) - workspace.CurrentCamera.ViewportSize/2).Magnitude
            if dist < closestDist and fovDist <= State.fov then
                closest = head
                closestDist = dist
            end
        end
    end
    return closest
end

local aimingConn
task.spawn(function()
    while true do
        if State.aim and keyUnlocked and menuActivated then
            if not aimingConn then
                aimingConn = RunService.RenderStepped:Connect(function()
                    local target = getClosestEnemy()
                    if target then
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
                    end
                end)
            end
        else
            if aimingConn then
                aimingConn:Disconnect()
                aimingConn = nil
            end
        end
        wait(0.2)
    end
end)

--------------------------
-- UI CAO CẤP
--------------------------
local function createUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "CONGHAU_ESP_VIP"
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    menuCircleBtn = Instance.new("TextButton")
    menuCircleBtn.Size = UDim2.fromOffset(48, 48)
    menuCircleBtn.Position = menuPositions[State.menupos]
    menuCircleBtn.BackgroundColor3 = Color3.fromRGB(90, 200, 255)
    menuCircleBtn.Text = "≡"
    menuCircleBtn.TextSize = 31
    menuCircleBtn.TextColor3 = Color3.new(1,1,1)
    menuCircleBtn.Font = Enum.Font.GothamBlack
    menuCircleBtn.Parent = gui
    menuCircleBtn.ZIndex = 10
    Instance.new("UICorner", menuCircleBtn).CornerRadius = UDim.new(1, 0)

    menuFrame = Instance.new("Frame")
    menuFrame.Size = UDim2.fromOffset(230, 420)
    menuFrame.Position = UDim2.new(0.5, -115, 0.5, -210)
    menuFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    menuFrame.BorderSizePixel = 0
    menuFrame.Visible = false
    menuFrame.Active = true
    menuFrame.Draggable = true
    menuFrame.Parent = gui
    Instance.new("UICorner", menuFrame).CornerRadius = UDim.new(0, 12)

    menuCircleBtn.MouseButton1Click:Connect(function()
        State.menu = not State.menu
        menuFrame.Visible = State.menu
        menuCircleBtn.BackgroundColor3 = State.menu and Color3.fromRGB(35,120,70) or Color3.fromRGB(90,200,255)
    end)

    local keyBox = Instance.new("TextBox")
    keyBox.Size = UDim2.new(0, 120, 0, 22)
    keyBox.Position = UDim2.new(0.5, -60, 0.5, -32)
    keyBox.PlaceholderText = "Nhập key VIP..."
    keyBox.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    keyBox.TextColor3 = Color3.new(1,1,1)
    keyBox.Font = Enum.Font.GothamBold
    keyBox.TextSize = 14
    keyBox.Name = "KeyBox"
    keyBox.Parent = menuFrame
    Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0, 10)

    local keyLabel = Instance.new("TextLabel")
    keyLabel.Size = UDim2.new(1, 0, 0, 18)
    keyLabel.Position = UDim2.new(0, 0, 0.5, -54)
    keyLabel.Text = "Nhập key VIP để mở menu"
    keyLabel.BackgroundTransparency = 1
    keyLabel.TextColor3 = Color3.new(1,1,1)
    keyLabel.Font = Enum.Font.Gotham
    keyLabel.TextSize = 13
    keyLabel.Parent = menuFrame

    local moveKeyBtn = Instance.new("TextButton")
    moveKeyBtn.Size = UDim2.new(0, 110, 0, 22)
    moveKeyBtn.Position = UDim2.new(0.5, -55, 0.5, -5)
    moveKeyBtn.BackgroundColor3 = Color3.fromRGB(45,45,60)
    moveKeyBtn.TextColor3 = Color3.new(1,1,1)
    moveKeyBtn.Font = Enum.Font.Gotham
    moveKeyBtn.TextSize = 12
    moveKeyBtn.Text = "Đổi vị trí menu: Trái"
    moveKeyBtn.Parent = menuFrame
    Instance.new("UICorner", moveKeyBtn).CornerRadius = UDim.new(0,8)
    moveKeyBtn.Visible = true

    moveKeyBtn.MouseButton1Click:Connect(function()
        posIndex = posIndex % #posList + 1
        State.menupos = posList[posIndex]
        moveKeyBtn.Text = "Đổi vị trí menu: " .. ({
            left="Trái",right="Phải",top="Trên",bottom="Dưới"
        })[State.menupos]
        menuCircleBtn.Position = menuPositions[State.menupos]
    end)

    local enterBtn = Instance.new("TextButton")
    enterBtn.Size = UDim2.new(0, 110, 0, 24)
    enterBtn.Position = UDim2.new(0.5, -55, 0.5, 24)
    enterBtn.BackgroundColor3 = Color3.fromRGB(35, 120, 70)
    enterBtn.TextColor3 = Color3.new(1,1,1)
    enterBtn.Font = Enum.Font.GothamBold
    enterBtn.TextSize = 13
    enterBtn.Text = "Vào menu"
    enterBtn.Visible = false
    enterBtn.Parent = menuFrame
    Instance.new("UICorner", enterBtn).CornerRadius = UDim.new(0, 8)

    local featureObjs = {}
    local function setFeaturesVisible(visible) for _,obj in ipairs(featureObjs) do obj.Visible = visible end end
    local function makeFeature(obj) table.insert(featureObjs, obj) obj.Visible = false end

    keyBox.FocusLost:Connect(function()
        if keyBox.Text == keyRequired then
            keyUnlocked = true
            keyBox.BackgroundColor3 = Color3.fromRGB(35, 120, 70)
            keyLabel.Text = "Đúng key! Bấm Vào menu."
            enterBtn.Visible = true
            StarterGui:SetCore("SendNotification", {Title="CONG HAU ESP VIP",Text="Đã nhập đúng key!",Duration=3})
        else
            keyUnlocked = false
            keyBox.BackgroundColor3 = Color3.fromRGB(90,35,35)
            keyLabel.Text = "Sai key! Nhập lại."
            enterBtn.Visible = false
            menuActivated = false
            setFeaturesVisible(false)
            StarterGui:SetCore("SendNotification", {Title="CONG HAU ESP VIP",Text="Sai key, hãy nhập lại!",Duration=3})
        end
    end)

    enterBtn.MouseButton1Click:Connect(function()
        menuActivated = true
        setFeaturesVisible(true)
        enterBtn.Visible = false
        keyBox.Visible = false
        keyLabel.Visible = false
        moveKeyBtn.Visible = false
    end)

    local title = Instance.new("TextLabel", menuFrame)
    title.Size = UDim2.new(1, -20, 0, 26)
    title.Position = UDim2.new(0, 10, 0, 18)
    title.BackgroundTransparency = 1
    title.Text = "CONG HAU ESP VIP CAO CẤP"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 17
    title.TextColor3 = Color3.new(1,1,0)
    makeFeature(title)

    local function makeToggle(y, label, getFn, setFn)
        local btn = Instance.new("TextButton", menuFrame)
        btn.Size = UDim2.new(1, -20, 0, 28)
        btn.Position = UDim2.new(0, 10, 0, y)
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.Parent = menuFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        makeFeature(btn)
        local function refresh()
            local on = getFn()
            btn.Text = (on and "✔ " or "✗ ") .. label
            btn.BackgroundColor3 = on and Color3.fromRGB(35, 120, 70) or Color3.fromRGB(90, 35, 35)
        end
        btn.MouseButton1Click:Connect(function() setFn(not getFn()) refresh() end)
        refresh()
        return btn
    end

    local function makeNumberBox(y, label, getFn, setFn, min, max)
        local lbl = Instance.new("TextLabel", menuFrame)
        lbl.Size = UDim2.new(0, 120, 0, 28)
        lbl.Position = UDim2.new(0, 10, 0, y)
        lbl.Text = label
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.TextColor3 = Color3.new(1,1,1)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        makeFeature(lbl)
        local box = Instance.new("TextBox", menuFrame)
        box.Size = UDim2.new(0, 60, 0, 28)
        box.Position = UDim2.new(0, 130, 0, y)
        box.Text = tostring(getFn())
        box.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        box.TextColor3 = Color3.new(1,1,1)
        box.Font = Enum.Font.Gotham
        box.TextSize = 14
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
        makeFeature(box)
        box.FocusLost:Connect(function()
            local n = tonumber(box.Text)
            if n and n >= min and n <= max then setFn(n) end
            box.Text = tostring(getFn())
        end)
    end

    makeToggle(50, "Auto ESP", function() return State.esp end, function(v) State.esp = v end)
    makeToggle(84, "Tracer", function() return State.tracer end, function(v) State.tracer = v end)
    makeToggle(118, "Highlight", function() return State.highlight end, function(v) State.highlight = v end)
    makeToggle(152, "Hitbox Thân", function() return State.hitbox end, function(v) State.hitbox = v end)
    makeToggle(186, "Hitbox Đầu", function() return State.hitboxHead end, function(v) State.hitboxHead = v end)
    makeToggle(220, "Aimbot (Khóa tâm)", function() return State.aim end, function(v) State.aim = v end)
    makeToggle(254, "Khóa máu (Lock HP)", function() return State.lockhp end, function(v) State.lockhp = v end)
    makeToggle(288, "Tăng hồi máu", function() return State.heal end, function(v) State.heal = v end)
    makeToggle(322, "Hiện Team", function() return State.showTeam end, function(v) State.showTeam = v end)
    makeToggle(356, "Hiện Vũ Khí", function() return State.showWeapon end, function(v) State.showWeapon = v end)

    makeNumberBox(390, "FOV", function() return State.fov end, function(v) State.fov = v end, 30, 300)
    makeNumberBox(390+34, "Hitbox Thân", function() return State.hitboxSize end, function(v) State.hitboxSize = v end, 2, 20)
    makeNumberBox(390+68, "Hitbox Đầu", function() return State.hitboxHeadSize end, function(v) State.hitboxHeadSize = v end, 2, 20)
end

createUI()

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "CONG HAU ESP VIP CAO CẤP",
        Text = "Nhập key MenuVip1 để mở menu!",
        Duration = 8
    })
end)
