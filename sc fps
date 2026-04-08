-- FPS Optimizer UI Script
-- Made with toggle controls and per-feature settings

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = (gethui and gethui()) or game:GetService("CoreGui")

-- =====================
-- STATE
-- =====================
local settings = {
    removePostEffects   = true,
    disableShadows      = true,
    flatMaterials       = true,
    hideDecals          = true,
    flatTerrain         = true,
    qualityLevel        = 1,
    physicsSleep        = true,
}

local originalData = {
    effects = {},
    parts   = {},
    decals  = {},
    terrain = {},
}

-- =====================
-- FUNCTIONS
-- =====================
local function applyPostEffects(enabled)
    if enabled then
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") then
                v:Destroy()
            end
        end
        Lighting.GlobalShadows = false
        Lighting.FogEnd        = 9e9
        Lighting.Brightness    = 2
    else
        Lighting.GlobalShadows = true
        Lighting.FogEnd        = 10000
        Lighting.Brightness    = 1
    end
end

local function applyMaterials(enabled)
    for _, instance in ipairs(workspace:GetDescendants()) do
        if instance:IsA("BasePart") then
            if player.Character and instance:IsDescendantOf(player.Character) then continue end
            if enabled then
                originalData.parts[instance] = {
                    Material    = instance.Material,
                    Reflectance = instance.Reflectance,
                }
                instance.Material    = Enum.Material.SmoothPlastic
                instance.Reflectance = 0
            else
                if originalData.parts[instance] then
                    instance.Material    = originalData.parts[instance].Material
                    instance.Reflectance = originalData.parts[instance].Reflectance
                end
            end
        end
    end
end

local function applyDecals(enabled)
    for _, instance in ipairs(workspace:GetDescendants()) do
        if instance:IsA("Texture") or instance:IsA("Decal") then
            if player.Character and instance:IsDescendantOf(player.Character) then continue end
            if enabled then
                originalData.decals[instance] = instance.Transparency
                instance.Transparency = 1
            else
                if originalData.decals[instance] then
                    instance.Transparency = originalData.decals[instance]
                end
            end
        end
    end
end

local function applyTerrain(enabled)
    local terrain = workspace:FindFirstChild("Terrain")
    if not terrain then return end
    if enabled then
        originalData.terrain = {
            WaterWaveSize       = terrain.WaterWaveSize,
            WaterWaveSpeed      = terrain.WaterWaveSpeed,
            WaterReflectance    = terrain.WaterReflectance,
            WaterTransparency   = terrain.WaterTransparency,
        }
        terrain.WaterWaveSize     = 0
        terrain.WaterWaveSpeed    = 0
        terrain.WaterReflectance  = 0
        terrain.WaterTransparency = 1
    else
        if originalData.terrain.WaterWaveSize then
            terrain.WaterWaveSize     = originalData.terrain.WaterWaveSize
            terrain.WaterWaveSpeed    = originalData.terrain.WaterWaveSpeed
            terrain.WaterReflectance  = originalData.terrain.WaterReflectance
            terrain.WaterTransparency = originalData.terrain.WaterTransparency
        end
    end
end

local function applyQuality(level)
    pcall(function()
        UserSettings().GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        settings().Rendering.QualityLevel = level
    end)
end

local function applyPhysics(enabled)
    pcall(function()
        settings().Physics.AllowSleep = enabled
    end)
end

local function applyAll()
    applyPostEffects(settings.removePostEffects)
    applyMaterials(settings.flatMaterials)
    applyDecals(settings.hideDecals)
    applyTerrain(settings.flatTerrain)
    applyQuality(settings.qualityLevel)
    applyPhysics(settings.physicsSleep)
end

local function revertAll()
    applyPostEffects(false)
    applyMaterials(false)
    applyDecals(false)
    applyTerrain(false)
    pcall(function() settings().Rendering.QualityLevel = 21 end)
    pcall(function() settings().Physics.AllowSleep = false end)
end

local masterEnabled = false

-- Don't apply on start, wait for user

-- DescendantAdded listener
workspace.DescendantAdded:Connect(function(instance)
    if not settings.flatMaterials and not settings.hideDecals then return end
    if player.Character and instance:IsDescendantOf(player.Character) then return end
    if settings.flatMaterials and instance:IsA("BasePart") then
        instance.Material    = Enum.Material.SmoothPlastic
        instance.Reflectance = 0
    end
    if settings.hideDecals and (instance:IsA("Texture") or instance:IsA("Decal")) then
        instance.Transparency = 1
    end
end)

-- =====================
-- UI
-- =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "FPSByElixir"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder   = 999

local guiParented = false
if not guiParented then pcall(function() screenGui.Parent = game:GetService("CoreGui") guiParented = true end) end
if not guiParented then pcall(function() screenGui.Parent = gethui() guiParented = true end) end
if not guiParented then screenGui.Parent = player.PlayerGui end

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size              = UDim2.new(0, 280, 0, 380)
mainFrame.Position          = UDim2.new(0, 16, 0.5, -190)
mainFrame.BackgroundColor3  = Color3.fromRGB(18, 12, 30)
mainFrame.BorderSizePixel   = 0
mainFrame.Active            = true
mainFrame.Draggable         = true
mainFrame.Parent            = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent       = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color     = Color3.fromRGB(120, 60, 200)
mainStroke.Thickness = 1
mainStroke.Parent    = mainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundColor3 = Color3.fromRGB(80, 30, 160)
titleBar.BorderSizePixel  = 0
titleBar.Parent           = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent       = titleBar

-- fix bottom corners of titlebar
local titleFix = Instance.new("Frame")
titleFix.Size             = UDim2.new(1, 0, 0, 10)
titleFix.Position         = UDim2.new(0, 0, 1, -10)
titleFix.BackgroundColor3 = Color3.fromRGB(80, 30, 160)
titleFix.BorderSizePixel  = 0
titleFix.Parent           = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size              = UDim2.new(1, -90, 1, 0)
titleLabel.Position          = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text              = "ELIXIR STORE"
titleLabel.TextColor3        = Color3.fromRGB(255, 220, 255)
titleLabel.TextSize          = 14
titleLabel.Font              = Enum.Font.GothamBold
titleLabel.TextXAlignment    = Enum.TextXAlignment.Left
titleLabel.Parent            = titleBar

-- Master ON/OFF button
local masterBtn = Instance.new("TextButton")
masterBtn.Size               = UDim2.new(0, 42, 0, 24)
masterBtn.Position           = UDim2.new(1, -82, 0.5, -12)
masterBtn.BackgroundColor3   = Color3.fromRGB(55, 25, 80)
masterBtn.Text               = "OFF"
masterBtn.TextColor3         = Color3.fromRGB(200, 140, 255)
masterBtn.TextSize           = 11
masterBtn.Font               = Enum.Font.GothamBold
masterBtn.BorderSizePixel    = 0
masterBtn.Parent             = titleBar

local masterCorner = Instance.new("UICorner")
masterCorner.CornerRadius = UDim.new(0, 6)
masterCorner.Parent       = masterBtn

-- Minimize button
local minBtn = Instance.new("TextButton")
minBtn.Size                  = UDim2.new(0, 28, 0, 28)
minBtn.Position              = UDim2.new(1, -34, 0.5, -14)
minBtn.BackgroundColor3      = Color3.fromRGB(100, 40, 170)
minBtn.Text                  = "–"
minBtn.TextColor3            = Color3.fromRGB(240, 200, 255)
minBtn.TextSize              = 16
minBtn.Font                  = Enum.Font.GothamBold
minBtn.BorderSizePixel       = 0
minBtn.Parent                = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent       = minBtn

-- Content
local content = Instance.new("ScrollingFrame")
content.Size                = UDim2.new(1, 0, 1, -44)
content.Position            = UDim2.new(0, 0, 0, 44)
content.BackgroundTransparency = 1
content.BorderSizePixel     = 0
content.ScrollBarThickness  = 3
content.ScrollBarImageColor3 = Color3.fromRGB(150, 60, 220)
content.CanvasSize          = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.Parent              = mainFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding       = UDim.new(0, 0)
contentLayout.SortOrder     = Enum.SortOrder.LayoutOrder
contentLayout.Parent        = content

local contentPad = Instance.new("UIPadding")
contentPad.PaddingLeft   = UDim.new(0, 14)
contentPad.PaddingRight  = UDim.new(0, 14)
contentPad.PaddingTop    = UDim.new(0, 10)
contentPad.PaddingBottom = UDim.new(0, 10)
contentPad.Parent        = content

-- =====================
-- Toggle Helper
-- =====================
local function makeToggle(labelText, description, defaultOn, layoutOrder, callback)
    local row = Instance.new("Frame")
    row.Size              = UDim2.new(1, 0, 0, 56)
    row.BackgroundColor3  = Color3.fromRGB(30, 15, 50)
    row.BorderSizePixel   = 0
    row.LayoutOrder       = layoutOrder
    row.Parent            = content

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 8)
    rowCorner.Parent       = row

    local rowMargin = Instance.new("UIPadding")
    rowMargin.PaddingTop    = UDim.new(0, 2)
    rowMargin.PaddingBottom = UDim.new(0, 2)
    rowMargin.Parent        = row

    local lbl = Instance.new("TextLabel")
    lbl.Size                 = UDim2.new(1, -64, 0, 20)
    lbl.Position             = UDim2.new(0, 12, 0, 10)
    lbl.BackgroundTransparency = 1
    lbl.Text                 = labelText
    lbl.TextColor3           = Color3.fromRGB(220, 180, 255)
    lbl.TextSize             = 13
    lbl.Font                 = Enum.Font.GothamBold
    lbl.TextXAlignment       = Enum.TextXAlignment.Left
    lbl.Parent               = row

    local desc = Instance.new("TextLabel")
    desc.Size                = UDim2.new(1, -64, 0, 16)
    desc.Position            = UDim2.new(0, 12, 0, 30)
    desc.BackgroundTransparency = 1
    desc.Text                = description
    desc.TextColor3          = Color3.fromRGB(140, 100, 180)
    desc.TextSize            = 11
    desc.Font                = Enum.Font.Gotham
    desc.TextXAlignment      = Enum.TextXAlignment.Left
    desc.Parent              = row

    -- Toggle pill
    local toggleBg = Instance.new("Frame")
    toggleBg.Size            = UDim2.new(0, 40, 0, 22)
    toggleBg.Position        = UDim2.new(1, -52, 0.5, -11)
    toggleBg.BackgroundColor3 = defaultOn and Color3.fromRGB(130, 60, 220) or Color3.fromRGB(55, 25, 80)
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent          = row

    local pillCorner = Instance.new("UICorner")
    pillCorner.CornerRadius = UDim.new(1, 0)
    pillCorner.Parent       = toggleBg

    local knob = Instance.new("Frame")
    knob.Size            = UDim2.new(0, 16, 0, 16)
    knob.Position        = defaultOn and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent          = toggleBg

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent       = knob

    -- Spacer between rows
    local spacer = Instance.new("Frame")
    spacer.Size             = UDim2.new(1, 0, 0, 6)
    spacer.BackgroundTransparency = 1
    spacer.LayoutOrder      = layoutOrder
    spacer.Parent           = content

    local isOn = defaultOn
    local btn = Instance.new("TextButton")
    btn.Size                 = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text                 = ""
    btn.Parent               = row

    btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
        TweenService:Create(toggleBg, tweenInfo, {
            BackgroundColor3 = isOn and Color3.fromRGB(130, 60, 220) or Color3.fromRGB(55, 25, 80)
        }):Play()
        TweenService:Create(knob, tweenInfo, {
            Position = isOn and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        }):Play()
        callback(isOn)
    end)

    return row
end

-- =====================
-- Section Label Helper
-- =====================
local function makeSection(text, layoutOrder)
    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, 0, 0, 28)
    lbl.BackgroundTransparency = 1
    lbl.Text             = text
    lbl.TextColor3       = Color3.fromRGB(160, 80, 220)
    lbl.TextSize         = 11
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.LayoutOrder      = layoutOrder
    lbl.Parent           = content
end

-- =====================
-- Slider Helper
-- =====================
local function makeSlider(labelText, min, max, default, layoutOrder, callback)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 64)
    row.BackgroundColor3 = Color3.fromRGB(30, 15, 50)
    row.BorderSizePixel  = 0
    row.LayoutOrder      = layoutOrder
    row.Parent           = content

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 8)
    rowCorner.Parent       = row

    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, -50, 0, 18)
    lbl.Position         = UDim2.new(0, 12, 0, 10)
    lbl.BackgroundTransparency = 1
    lbl.Text             = labelText
    lbl.TextColor3       = Color3.fromRGB(220, 180, 255)
    lbl.TextSize         = 13
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Parent           = row

    local valLabel = Instance.new("TextLabel")
    valLabel.Size        = UDim2.new(0, 38, 0, 18)
    valLabel.Position    = UDim2.new(1, -50, 0, 10)
    valLabel.BackgroundTransparency = 1
    valLabel.Text        = tostring(default)
    valLabel.TextColor3  = Color3.fromRGB(180, 100, 255)
    valLabel.TextSize    = 13
    valLabel.Font        = Enum.Font.GothamBold
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Parent      = row

    -- Slider track
    local track = Instance.new("Frame")
    track.Size           = UDim2.new(1, -24, 0, 4)
    track.Position       = UDim2.new(0, 12, 0, 40)
    track.BackgroundColor3 = Color3.fromRGB(55, 25, 80)
    track.BorderSizePixel = 0
    track.Parent         = row

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent       = track

    local fill = Instance.new("Frame")
    local pct = (default - min) / (max - min)
    fill.Size            = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(130, 60, 220)
    fill.BorderSizePixel = 0
    fill.Parent          = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent       = fill

    local thumb = Instance.new("Frame")
    thumb.Size           = UDim2.new(0, 14, 0, 14)
    thumb.Position       = UDim2.new(pct, -7, 0.5, -7)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    thumb.ZIndex         = 2
    thumb.Parent         = track

    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(1, 0)
    thumbCorner.Parent       = thumb

    local spacer = Instance.new("Frame")
    spacer.Size             = UDim2.new(1, 0, 0, 6)
    spacer.BackgroundTransparency = 1
    spacer.LayoutOrder      = layoutOrder
    spacer.Parent           = content

    local dragging = false
    local trackBtn = Instance.new("TextButton")
    trackBtn.Size            = UDim2.new(1, 0, 0, 24)
    trackBtn.Position        = UDim2.new(0, 0, 0, 32)
    trackBtn.BackgroundTransparency = 1
    trackBtn.Text            = ""
    trackBtn.ZIndex          = 3
    trackBtn.Parent          = row

    local function updateSlider(input)
        local trackAbs = track.AbsolutePosition
        local trackSize = track.AbsoluteSize
        local relX = math.clamp((input.Position.X - trackAbs.X) / trackSize.X, 0, 1)
        local value = math.round(min + relX * (max - min))
        valLabel.Text = tostring(value)
        fill.Size     = UDim2.new(relX, 0, 1, 0)
        thumb.Position = UDim2.new(relX, -7, 0.5, -7)
        callback(value)
    end

    trackBtn.MouseButton1Down:Connect(function()
        dragging = true
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    trackBtn.MouseButton1Up:Connect(function(x, y)
        local input = {Position = Vector3.new(x, y, 0)}
        updateSlider({Position = Vector3.new(x, y, 0)})
    end)
end

-- =====================
-- Build UI Items
-- =====================
makeSection("LIGHTING", 0)
makeToggle("Remove Post Effects", "Bloom, blur, color correction", settings.removePostEffects, 1, function(v)
    settings.removePostEffects = v
    if masterEnabled then applyPostEffects(v) end
end)
makeToggle("Disable Shadows", "Global shadow rendering", settings.disableShadows, 2, function(v)
    settings.disableShadows = v
    if masterEnabled then Lighting.GlobalShadows = not v end
end)

makeSection("WORLD", 10)
makeToggle("Flat Materials", "SmoothPlastic on all parts", settings.flatMaterials, 11, function(v)
    settings.flatMaterials = v
    if masterEnabled then applyMaterials(v) end
end)
makeToggle("Hide Decals & Textures", "Makes all textures invisible", settings.hideDecals, 12, function(v)
    settings.hideDecals = v
    if masterEnabled then applyDecals(v) end
end)
makeToggle("Flat Terrain Water", "Remove water waves & reflections", settings.flatTerrain, 13, function(v)
    settings.flatTerrain = v
    if masterEnabled then applyTerrain(v) end
end)

makeSection("PERFORMANCE", 20)
makeSlider("Render Quality", 1, 21, settings.qualityLevel, 21, function(v)
    settings.qualityLevel = v
    if masterEnabled then pcall(function() settings().Rendering.QualityLevel = v end) end
end)
makeToggle("Physics Sleep", "Idle parts skip physics calc", settings.physicsSleep, 22, function(v)
    settings.physicsSleep = v
    if masterEnabled then pcall(function() settings().Physics.AllowSleep = v end) end
end)

-- =====================
-- Minimize Logic
-- =====================
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
    if minimized then
        TweenService:Create(mainFrame, tweenInfo, {Size = UDim2.new(0, 280, 0, 44)}):Play()
        minBtn.Text = "+"
    else
        TweenService:Create(mainFrame, tweenInfo, {Size = UDim2.new(0, 280, 0, 380)}):Play()
        minBtn.Text = "–"
    end
end)

-- =====================
-- Master ON/OFF Logic
-- =====================
masterBtn.MouseButton1Click:Connect(function()
    masterEnabled = not masterEnabled
    local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
    if masterEnabled then
        masterBtn.Text = "ON"
        TweenService:Create(masterBtn, tweenInfo, {
            BackgroundColor3 = Color3.fromRGB(130, 60, 220),
            TextColor3       = Color3.fromRGB(255, 230, 255),
        }):Play()
        applyAll()
    else
        masterBtn.Text = "OFF"
        TweenService:Create(masterBtn, tweenInfo, {
            BackgroundColor3 = Color3.fromRGB(55, 25, 80),
            TextColor3       = Color3.fromRGB(200, 140, 255),
        }):Play()
        revertAll()
    end
end)
