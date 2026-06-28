--[[
    AURORA UI LIBRARY
    ------------------------------------------------------------------
    Biblioteca de interface para Roblox (Luau) inspirada esteticamente
    na Obsidian UI, com design e código 100% originais.

    - Arquivo único, sem dependências externas
    - Otimizada (reaproveita tweens, limpa conexões via Janitor)
    - API simples: Library:CreateWindow / Window:CreateTab / Tab:CreateSection
    - Compatível com executores modernos (gethui / protect_gui quando disponíveis)

    Autor: Aurora UI
    Versão: 1.0.0
------------------------------------------------------------------]]

-- // SERVIÇOS -------------------------------------------------------
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local HttpService    = game:GetService("HttpService")
local Players         = game:GetService("Players")
local Lighting        = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- // ROOT GUI ---------------------------------------------------------
local function GetGuiParent()
    local ok, hui = pcall(function() return gethui() end)
    if ok and hui then return hui end
    local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- // JANITOR (limpeza interna de conexões/objetos) --------------------
local Janitor = {}
Janitor.__index = Janitor

function Janitor.new()
    return setmetatable({ _items = {} }, Janitor)
end

function Janitor:Add(obj, cleanupMethod)
    if obj == nil then return obj end
    table.insert(self._items, { obj, cleanupMethod })
    return obj
end

function Janitor:Clean()
    for i = #self._items, 1, -1 do
        local entry = self._items[i]
        local obj, method = entry[1], entry[2]
        pcall(function()
            if typeof(obj) == "RBXScriptConnection" then
                obj:Disconnect()
            elseif typeof(obj) == "function" then
                obj()
            elseif typeof(obj) == "Instance" then
                obj:Destroy()
            elseif method and obj[method] then
                obj[method](obj)
            end
        end)
        self._items[i] = nil
    end
end

-- // UTILITÁRIOS -------------------------------------------------------
local Utility = {}

function Utility.Create(class, props, children)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            inst[k] = v
        end
    end
    if children then
        for _, c in ipairs(children) do
            c.Parent = inst
        end
    end
    return inst
end

function Utility.Corner(parent, radius)
    return Utility.Create("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent })
end

function Utility.Stroke(parent, color, thickness, transparency)
    return Utility.Create("UIStroke", {
        Color = color or Color3.fromRGB(255, 255, 255),
        Thickness = thickness or 1,
        Transparency = transparency or 0.85,
        Parent = parent,
    })
end

function Utility.Padding(parent, all)
    return Utility.Create("UIPadding", {
        PaddingTop = UDim.new(0, all or 6),
        PaddingBottom = UDim.new(0, all or 6),
        PaddingLeft = UDim.new(0, all or 6),
        PaddingRight = UDim.new(0, all or 6),
        Parent = parent,
    })
end

function Utility.Tween(obj, props, time, style, dir)
    local tween = TweenService:Create(
        obj,
        TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
        props
    )
    tween:Play()
    return tween
end

function Utility.Round(value, increment)
    increment = increment or 1
    return math.floor(value / increment + 0.5) * increment
end

function Utility.Clamp(value, min, max)
    return math.clamp(value, min, max)
end

-- arrasto genérico (usado pela janela, botão flutuante, color picker, etc.)
function Utility.MakeDraggable(handle, target, janitor, bounds)
    local dragging = false
    local dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
        target.Position = newPos
    end

    janitor:Add(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    conn:Disconnect()
                end
            end)
        end
    end))

    janitor:Add(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end))
end

-- // TEMA --------------------------------------------------------------
local Themes = {
    Dark = {
        Background = Color3.fromRGB(18, 18, 20),
        Topbar = Color3.fromRGB(24, 24, 27),
        Section = Color3.fromRGB(26, 26, 29),
        Element = Color3.fromRGB(32, 32, 36),
        ElementHover = Color3.fromRGB(40, 40, 45),
        Accent = Color3.fromRGB(120, 90, 255),
        Text = Color3.fromRGB(235, 235, 240),
        SubText = Color3.fromRGB(150, 150, 160),
        Stroke = Color3.fromRGB(255, 255, 255),
    },
    Purple = {
        Background = Color3.fromRGB(20, 17, 26),
        Topbar = Color3.fromRGB(27, 22, 35),
        Section = Color3.fromRGB(29, 24, 38),
        Element = Color3.fromRGB(36, 30, 47),
        ElementHover = Color3.fromRGB(45, 38, 58),
        Accent = Color3.fromRGB(168, 100, 253),
        Text = Color3.fromRGB(235, 235, 240),
        SubText = Color3.fromRGB(160, 150, 175),
        Stroke = Color3.fromRGB(255, 255, 255),
    },
    Red = {
        Background = Color3.fromRGB(22, 16, 17),
        Topbar = Color3.fromRGB(29, 21, 22),
        Section = Color3.fromRGB(31, 23, 24),
        Element = Color3.fromRGB(38, 28, 29),
        ElementHover = Color3.fromRGB(47, 34, 35),
        Accent = Color3.fromRGB(235, 70, 80),
        Text = Color3.fromRGB(235, 235, 240),
        SubText = Color3.fromRGB(170, 150, 152),
        Stroke = Color3.fromRGB(255, 255, 255),
    },
    Blue = {
        Background = Color3.fromRGB(15, 18, 22),
        Topbar = Color3.fromRGB(20, 24, 30),
        Section = Color3.fromRGB(22, 27, 33),
        Element = Color3.fromRGB(28, 34, 42),
        ElementHover = Color3.fromRGB(35, 42, 52),
        Accent = Color3.fromRGB(70, 140, 255),
        Text = Color3.fromRGB(235, 235, 240),
        SubText = Color3.fromRGB(150, 160, 175),
        Stroke = Color3.fromRGB(255, 255, 255),
    },
}

-- // BIBLIOTECA PRINCIPAL ----------------------------------------------
local Library = {}
Library.__index = Library

Library.Flags = {}
Library.Options = {}        -- Flag -> elemento (para Config + Theme)
Library.Windows = {}
Library.Theme = table.clone(Themes.Dark)
Library.ThemeObjects = {}   -- lista de {Instance, Property, ThemeKey}
Library.SoundsEnabled = true
Library.ConfigFolder = "AuroraUIConfigs"
Library.Janitor = Janitor.new()

local Sounds = {
    Click = "rbxassetid://6895079853",
    Hover = "rbxassetid://6895079788",
    Notification = "rbxassetid://6895079853",
}

function Library:PlaySound(name)
    if not Library.SoundsEnabled then return end
    pcall(function()
        local id = Sounds[name]
        if not id then return end
        local s = Instance.new("Sound")
        s.SoundId = id
        s.Volume = 0.4
        s.Parent = GetGuiParent()
        s:Play()
        s.Ended:Connect(function() s:Destroy() end)
        task.delay(2, function() if s then s:Destroy() end end)
    end)
end

-- registra um instance para receber atualização automática de tema
function Library:Recolor(instance, property, themeKey)
    table.insert(Library.ThemeObjects, { instance, property, themeKey })
    instance[property] = Library.Theme[themeKey]
end

function Library:SetTheme(theme)
    if type(theme) == "string" then
        theme = Themes[theme]
        if not theme then
            warn("[AuroraUI] Tema '" .. tostring(theme) .. "' não existe.")
            return
        end
    end
    for key, value in pairs(theme) do
        Library.Theme[key] = value
    end
    for _, entry in ipairs(Library.ThemeObjects) do
        local inst, prop, key = entry[1], entry[2], entry[3]
        if inst and inst.Parent and Library.Theme[key] then
            pcall(function()
                Utility.Tween(inst, { [prop] = Library.Theme[key] }, 0.2)
            end)
        end
    end
end

-- // TOOLTIP -----------------------------------------------------------
local TooltipGui
local TooltipLabel

local function EnsureTooltip()
    if TooltipGui then return end
    local parent = GetGuiParent()
    TooltipGui = Utility.Create("ScreenGui", { Name = "AuroraTooltip", Parent = parent, ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
    TooltipLabel = Utility.Create("TextLabel", {
        BackgroundColor3 = Library.Theme.Element,
        Size = UDim2.new(0, 0, 0, 22),
        AutomaticSize = Enum.AutomaticSize.X,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = Library.Theme.Text,
        Text = "",
        Visible = false,
        ZIndex = 999,
        Parent = TooltipGui,
    })
    Utility.Padding(TooltipLabel, 6)
    Utility.Corner(TooltipLabel, 6)
    Utility.Stroke(TooltipLabel, Library.Theme.Stroke, 1, 0.85)
end

function Library:AddTooltip(instance, text)
    EnsureTooltip()
    instance.MouseEnter:Connect(function()
        TooltipLabel.Text = text
        TooltipLabel.Visible = true
    end)
    instance.MouseMoving:Connect(function(x, y)
        TooltipLabel.Position = UDim2.new(0, x + 16, 0, y + 16)
    end)
    instance.MouseLeave:Connect(function()
        TooltipLabel.Visible = false
    end)
end

-- // NOTIFICAÇÕES ------------------------------------------------------
local NotifyGui, NotifyHolder

local function EnsureNotifyGui()
    if NotifyGui then return end
    local parent = GetGuiParent()
    NotifyGui = Utility.Create("ScreenGui", { Name = "AuroraNotifications", Parent = parent, ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
    NotifyHolder = Utility.Create("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.new(0, 280, 1, -32),
        Parent = NotifyGui,
    })
    Utility.Create("UIListLayout", {
        Parent = NotifyHolder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
end

function Library:Notify(opts)
    opts = opts or {}
    EnsureNotifyGui()
    local duration = opts.Duration or 4
    local color = opts.Color or Library.Theme.Accent

    local frame = Utility.Create("Frame", {
        BackgroundColor3 = Library.Theme.Section,
        Size = UDim2.new(1, 0, 0, 60),
        Position = UDim2.new(1, 40, 0, 0),
        Parent = NotifyHolder,
    })
    Utility.Corner(frame, 10)
    Utility.Stroke(frame, Library.Theme.Stroke, 1, 0.88)

    Utility.Create("Frame", {
        BackgroundColor3 = color,
        Size = UDim2.new(0, 4, 1, -12),
        Position = UDim2.new(0, 0, 0, 6),
        Parent = frame,
    }, { Utility.Corner(nil, 4) and nil }) -- placeholder, corner added below
    local bar = frame:FindFirstChildOfClass("Frame")
    if bar then Utility.Corner(bar, 4) end

    local title = Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 6),
        Size = UDim2.new(1, -28, 0, 18),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Library.Theme.Text,
        Text = opts.Title or "Notificação",
        Parent = frame,
    })

    local body = Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 24),
        Size = UDim2.new(1, -28, 0, 30),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextColor3 = Library.Theme.SubText,
        Text = opts.Text or "",
        Parent = frame,
    })

    Library:PlaySound("Notification")
    Utility.Tween(frame, { Position = UDim2.new(0, 0, 0, 0) }, 0.35, Enum.EasingStyle.Back)

    task.delay(duration, function()
        if not frame or not frame.Parent then return end
        Utility.Tween(frame, { Position = UDim2.new(1, 40, 0, 0) }, 0.3)
        task.delay(0.3, function()
            if frame then frame:Destroy() end
        end)
    end)
end

-- // PROMPT (DIALOG) ---------------------------------------------------
function Library:Prompt(opts)
    opts = opts or {}
    local parent = GetGuiParent()
    local gui = Utility.Create("ScreenGui", { Name = "AuroraPrompt", Parent = parent, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })

    local overlay = Utility.Create("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = gui,
    })
    Utility.Tween(overlay, { BackgroundTransparency = 0.45 }, 0.2)

    local box = Utility.Create("Frame", {
        BackgroundColor3 = Library.Theme.Section,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 320, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = overlay,
    })
    Utility.Corner(box, 12)
    Utility.Stroke(box, Library.Theme.Stroke, 1, 0.85)
    Utility.Padding(box, 18)

    local layout = Utility.Create("UIListLayout", {
        Parent = box,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Library.Theme.Text,
        Text = opts.Title or "Aviso",
        LayoutOrder = 1,
        Parent = box,
    })

    Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Library.Theme.SubText,
        Text = opts.Text or "",
        LayoutOrder = 2,
        Parent = box,
    })

    local btnHolder = Utility.Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        LayoutOrder = 3,
        Parent = box,
    })
    Utility.Create("UIListLayout", {
        Parent = btnHolder,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local function closePrompt()
        Utility.Tween(overlay, { BackgroundTransparency = 1 }, 0.2)
        task.delay(0.2, function() gui:Destroy() end)
    end

    for label, callback in pairs(opts.Buttons or {}) do
        local isPrimary = (label == "Yes" or label == "Confirmar" or label == "Sim")
        local b = Utility.Create("TextButton", {
            BackgroundColor3 = isPrimary and Library.Theme.Accent or Library.Theme.Element,
            Size = UDim2.new(0, 90, 1, 0),
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = Library.Theme.Text,
            Text = label,
            AutoButtonColor = false,
            Parent = btnHolder,
        })
        Utility.Corner(b, 8)
        b.MouseButton1Click:Connect(function()
            Library:PlaySound("Click")
            pcall(callback)
            closePrompt()
        end)
    end

    return gui
end

-- // CONFIG SYSTEM ------------------------------------------------------
local function EnsureConfigFolder()
    pcall(function()
        if not isfolder(Library.ConfigFolder) then
            makefolder(Library.ConfigFolder)
        end
    end)
end

function Library:SaveConfig(name)
    EnsureConfigFolder()
    local data = {}
    for flag, element in pairs(Library.Options) do
        if element.Save ~= false then
            data[flag] = Library.Flags[flag]
        end
    end
    local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if not ok then
        warn("[AuroraUI] Falha ao serializar config: " .. tostring(encoded))
        return false
    end
    local success, err = pcall(function()
        writefile(Library.ConfigFolder .. "/" .. name .. ".json", encoded)
    end)
    if not success then
        warn("[AuroraUI] Falha ao salvar config: " .. tostring(err))
        return false
    end
    return true
end

function Library:LoadConfig(name)
    local path = Library.ConfigFolder .. "/" .. name .. ".json"
    local ok, content = pcall(function() return readfile(path) end)
    if not ok then
        warn("[AuroraUI] Config '" .. name .. "' não encontrada.")
        return false
    end
    local ok2, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok2 then
        warn("[AuroraUI] Config corrompida.")
        return false
    end
    for flag, value in pairs(data) do
        local element = Library.Options[flag]
        if element and element.Set then
            pcall(function() element:Set(value) end)
        end
    end
    return true
end

function Library:ListConfigs()
    EnsureConfigFolder()
    local ok, files = pcall(function() return listfiles(Library.ConfigFolder) end)
    if not ok then return {} end
    local names = {}
    for _, f in ipairs(files) do
        local n = f:match("([^/\\]+)%.json$")
        if n then table.insert(names, n) end
    end
    return names
end

function Library:SetAutoSave(enabled, name, interval)
    if Library._autoSaveJanitor then
        Library._autoSaveJanitor:Clean()
        Library._autoSaveJanitor = nil
    end
    if not enabled then return end
    Library._autoSaveJanitor = Janitor.new()
    Library._autoSaveJanitor:Add(task.spawn(function()
        while true do
            task.wait(interval or 30)
            Library:SaveConfig(name or "AutoSave")
        end
    end), nil)
end

-- // CONSTRUTOR DE ELEMENTO BASE ----------------------------------------
-- todo elemento herda Set / Get / Destroy / Hide / Show / Lock / Unlock
local function NewElementBase(instance, janitor)
    local base = {
        Instance = instance,
        Locked = false,
        _janitor = janitor,
    }

    function base:Hide()
        instance.Visible = false
    end

    function base:Show()
        instance.Visible = true
    end

    function base:Lock()
        base.Locked = true
    end

    function base:Unlock()
        base.Locked = false
    end

    function base:Destroy()
        if base._janitor then base._janitor:Clean() end
        if instance then instance:Destroy() end
    end

    return base
end

-- // JANELA (WINDOW) ----------------------------------------------------
function Library:CreateWindow(opts)
    opts = opts or {}
    local title = opts.Title or "Aurora UI"
    local subtitle = opts.Subtitle or ""
    local size = opts.Size or UDim2.new(0, 550, 0, 400)
    local minSize = opts.MinSize or Vector2.new(420, 280)
    local keybind = opts.Keybind or Enum.KeyCode.RightControl

    local winJanitor = Janitor.new()
    local parent = GetGuiParent()

    local screenGui = Utility.Create("ScreenGui", {
        Name = "AuroraUI_" .. HttpService:GenerateGUID(false):sub(1, 8),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = parent,
    })
    pcall(function() screenGui.DisplayOrder = 100 end)

    -- janela principal
    local Main = Utility.Create("Frame", {
        Name = "Main",
        BackgroundColor3 = Library.Theme.Background,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = size,
        ClipsDescendants = true,
        Parent = screenGui,
    })
    Utility.Corner(Main, 12)
    Utility.Stroke(Main, Library.Theme.Stroke, 1, 0.88)
    Library:Recolor(Main, "BackgroundColor3", "Background")

    -- sombra suave
    local Shadow = Utility.Create("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 4),
        Size = UDim2.new(1, 60, 1, 60),
        ZIndex = -1,
        Parent = Main,
    })

    -- topbar
    local Topbar = Utility.Create("Frame", {
        Name = "Topbar",
        BackgroundColor3 = Library.Theme.Topbar,
        Size = UDim2.new(1, 0, 0, 44),
        Parent = Main,
    })
    Utility.Corner(Topbar, 12)
    Library:Recolor(Topbar, "BackgroundColor3", "Topbar")

    -- máscara para topbar não arredondar a parte inferior
    Utility.Create("Frame", {
        BackgroundColor3 = Library.Theme.Topbar,
        Position = UDim2.new(0, 0, 1, -12),
        Size = UDim2.new(1, 0, 0, 12),
        BorderSizePixel = 0,
        Parent = Topbar,
    })

    local icon = opts.Icon
    local iconLabel
    local textOffset = 14
    if icon then
        iconLabel = Utility.Create("ImageLabel", {
            BackgroundTransparency = 1,
            Image = icon,
            Position = UDim2.new(0, 12, 0.5, -10),
            Size = UDim2.new(0, 20, 0, 20),
            Parent = Topbar,
        })
        textOffset = 42
    end

    Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, textOffset, 0, 5),
        Size = UDim2.new(1, -120, 0, 18),
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Library.Theme.Text,
        Text = title,
        Parent = Topbar,
    })

    Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, textOffset, 0, 22),
        Size = UDim2.new(1, -120, 0, 16),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Library.Theme.SubText,
        Text = subtitle,
        Parent = Topbar,
    })

    -- botões de controle (fechar / minimizar)
    local function ControlButton(xOffset, iconId)
        local b = Utility.Create("ImageButton", {
            BackgroundTransparency = 1,
            Image = iconId,
            ImageColor3 = Library.Theme.SubText,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, xOffset, 0.5, 0),
            Size = UDim2.new(0, 16, 0, 16),
            Parent = Topbar,
        })
        return b
    end

    local closeBtn = ControlButton(-14, "rbxassetid://6031094678")
    local minimizeBtn = ControlButton(-44, "rbxassetid://6031090990")

    -- corpo
    local Body = Utility.Create("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(1, 0, 1, -44),
        Parent = Main,
    })

    local TabBar = Utility.Create("Frame", {
        Name = "TabBar",
        BackgroundColor3 = Library.Theme.Topbar,
        Size = UDim2.new(0, 130, 1, 0),
        Parent = Body,
    })
    Library:Recolor(TabBar, "BackgroundColor3", "Topbar")

    local TabScroll = Utility.Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -8),
        Position = UDim2.new(0, 0, 0, 8),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Library.Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = TabBar,
    })
    Utility.Create("UIListLayout", {
        Parent = TabScroll,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    Utility.Padding(TabScroll, 8)

    local PageHolder = Utility.Create("Frame", {
        Name = "PageHolder",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 130, 0, 0),
        Size = UDim2.new(1, -130, 1, 0),
        Parent = Body,
    })

    -- alça de redimensionamento
    local ResizeHandle = Utility.Create("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 0, 1, 0),
        Size = UDim2.new(0, 18, 0, 18),
        Parent = Main,
    })
    Utility.Create("ImageLabel", {
        BackgroundTransparency = 1,
        Image = "rbxassetid://6031091004",
        ImageColor3 = Library.Theme.SubText,
        ImageTransparency = 0.4,
        Rotation = 90,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = ResizeHandle,
    })

    -- arrastar janela
    Utility.MakeDraggable(Topbar, Main, winJanitor)

    -- redimensionar janela
    do
        local resizing = false
        local startMouse, startSize
        winJanitor:Add(ResizeHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = true
                startMouse = UserInputService:GetMouseLocation()
                startSize = Main.Size
            end
        end))
        winJanitor:Add(UserInputService.InputChanged:Connect(function(input)
            if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
                local mouse = UserInputService:GetMouseLocation()
                local delta = mouse - startMouse
                local newW = math.max(minSize.X, startSize.X.Offset + delta.X)
                local newH = math.max(minSize.Y, startSize.Y.Offset + delta.Y)
                Main.Size = UDim2.new(0, newW, 0, newH)
            end
        end))
        winJanitor:Add(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = false
            end
        end))
    end

    -- botão flutuante externo
    local FloatGui = Utility.Create("ScreenGui", {
        Name = "AuroraFloat",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        Parent = parent,
    })
    local FloatButton = Utility.Create("ImageButton", {
        BackgroundColor3 = Library.Theme.Accent,
        Position = UDim2.new(0, 30, 0, 120),
        Size = UDim2.new(0, 46, 0, 46),
        Image = opts.FloatIcon or "rbxassetid://6034509993",
        ImageColor3 = Color3.new(1, 1, 1),
        AutoButtonColor = false,
        Visible = false,
        Parent = FloatGui,
    })
    Utility.Corner(FloatButton, 23)
    Library:Recolor(FloatButton, "BackgroundColor3", "Accent")
    Utility.MakeDraggable(FloatButton, FloatButton, winJanitor)

    local Window = setmetatable({
        ScreenGui = screenGui,
        Main = Main,
        Tabs = {},
        TabScroll = TabScroll,
        PageHolder = PageHolder,
        _janitor = winJanitor,
        _firstTab = nil,
        _minimized = false,
        _visible = true,
        FloatButton = FloatButton,
    }, Library)

    -- minimizar / maximizar
    local fullSize = size
    minimizeBtn.MouseButton1Click:Connect(function()
        Library:PlaySound("Click")
        Window._minimized = not Window._minimized
        if Window._minimized then
            Body.Visible = false
            Utility.Tween(Main, { Size = UDim2.new(0, fullSize.X.Offset, 0, 44) }, 0.25)
        else
            Utility.Tween(Main, { Size = fullSize }, 0.25)
            task.delay(0.1, function() Body.Visible = true end)
        end
    end)

    -- fechar (esconde, sem destruir, para reabrir pelo botão flutuante)
    local function setVisible(state)
        Window._visible = state
        Main.Visible = state
        FloatButton.Visible = not state
    end

    closeBtn.MouseButton1Click:Connect(function()
        Library:PlaySound("Click")
        setVisible(false)
    end)

    FloatButton.MouseButton1Click:Connect(function()
        Utility.Tween(FloatButton, { Size = UDim2.new(0, 38, 0, 38) }, 0.08)
        task.delay(0.08, function()
            Utility.Tween(FloatButton, { Size = UDim2.new(0, 46, 0, 46) }, 0.12)
        end)
        Library:PlaySound("Click")
        setVisible(true)
    end)

    winJanitor:Add(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == keybind then
            setVisible(not Window._visible)
        end
    end))

    table.insert(Library.Windows, Window)
    return Window
end

-- // TABS ---------------------------------------------------------------
function Library:CreateTab(name, icon)
    local self = self
    local isDefault = (#self.Tabs == 0)

    local TabButton = Utility.Create("TextButton", {
        BackgroundColor3 = Library.Theme.Element,
        BackgroundTransparency = isDefault and 0 or 1,
        Size = UDim2.new(1, 0, 0, 32),
        Font = Enum.Font.Gotham,
        Text = "",
        AutoButtonColor = false,
        Parent = self.TabScroll,
    })
    Utility.Corner(TabButton, 8)

    local layoutOffset = 12
    if icon then
        Utility.Create("ImageLabel", {
            BackgroundTransparency = 1,
            Image = icon,
            ImageColor3 = isDefault and Library.Theme.Text or Library.Theme.SubText,
            Position = UDim2.new(0, 10, 0.5, -8),
            Size = UDim2.new(0, 16, 0, 16),
            Parent = TabButton,
        })
        layoutOffset = 32
    end

    local label = Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, layoutOffset, 0, 0),
        Size = UDim2.new(1, -layoutOffset - 6, 1, 0),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = isDefault and Library.Theme.Text or Library.Theme.SubText,
        Text = name,
        Parent = TabButton,
    })

    local Page = Utility.Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Library.Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = isDefault,
        Parent = self.PageHolder,
    })
    Utility.Padding(Page, 12)

    local Columns = Utility.Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = Page,
    })
    Utility.Create("UIListLayout", {
        Parent = Columns,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
    })

    local LeftCol = Utility.Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -5, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = Columns,
    })
    Utility.Create("UIListLayout", { Parent = LeftCol, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })

    local RightCol = Utility.Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -5, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = Columns,
    })
    Utility.Create("UIListLayout", { Parent = RightCol, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })

    local Tab = {
        Name = name,
        Button = TabButton,
        Page = Page,
        LeftCol = LeftCol,
        RightCol = RightCol,
        _window = self,
        _autoToggle = true,
    }

    function Tab:_select()
        for _, t in ipairs(self._window.Tabs) do
            t.Page.Visible = false
            Utility.Tween(t.Button, { BackgroundTransparency = 1 }, 0.15)
            local lbl = t.Button:FindFirstChildOfClass("TextLabel")
            local img = t.Button:FindFirstChildOfClass("ImageLabel")
            if lbl then lbl.TextColor3 = Library.Theme.SubText end
            if img then img.ImageColor3 = Library.Theme.SubText end
        end
        self.Page.Visible = true
        Utility.Tween(self.Button, { BackgroundTransparency = 0 }, 0.15)
        local lbl = self.Button:FindFirstChildOfClass("TextLabel")
        local img = self.Button:FindFirstChildOfClass("ImageLabel")
        if lbl then lbl.TextColor3 = Library.Theme.Text end
        if img then img.ImageColor3 = Library.Theme.Text end

        -- garante visibilidade do botão na scroll
        self._window.TabScroll.CanvasPosition = Vector2.new(0, self.Button.AbsolutePosition.Y - self._window.TabScroll.AbsolutePosition.Y)
    end

    TabButton.MouseButton1Click:Connect(function()
        Library:PlaySound("Click")
        Tab:_select()
    end)

    -- Sub-Tabs (cria uma barra horizontal de sub-abas dentro da Page)
    function Tab:CreateSubTab(subName)
        if not self._subBar then
            self._subBar = Utility.Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 28),
                LayoutOrder = -1,
                Parent = self.Page,
            })
            Utility.Create("UIListLayout", {
                Parent = self._subBar,
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })
            self._subTabs = {}
        end

        local subIsDefault = (#self._subTabs == 0)
        local SubBtn = Utility.Create("TextButton", {
            BackgroundColor3 = Library.Theme.Element,
            BackgroundTransparency = subIsDefault and 0 or 0.5,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = subIsDefault and Library.Theme.Text or Library.Theme.SubText,
            Text = "  " .. subName .. "  ",
            AutoButtonColor = false,
            Parent = self._subBar,
        })
        Utility.Corner(SubBtn, 6)

        local SubColumns = Utility.Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Visible = subIsDefault,
            Parent = self.Page,
        })
        Utility.Create("UIListLayout", {
            Parent = SubColumns,
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
        })
        local SLeft = Utility.Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.5, -5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = SubColumns })
        Utility.Create("UIListLayout", { Parent = SLeft, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
        local SRight = Utility.Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.5, -5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = SubColumns })
        Utility.Create("UIListLayout", { Parent = SRight, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })

        local SubTab = { Button = SubBtn, LeftCol = SLeft, RightCol = SRight, Holder = SubColumns }
        table.insert(self._subTabs, SubTab)

        SubBtn.MouseButton1Click:Connect(function()
            Library:PlaySound("Click")
            for _, st in ipairs(self._subTabs) do
                st.Holder.Visible = false
                Utility.Tween(st.Button, { BackgroundTransparency = 0.5 }, 0.15)
                st.Button.TextColor3 = Library.Theme.SubText
            end
            SubColumns.Visible = true
            Utility.Tween(SubBtn, { BackgroundTransparency = 0 }, 0.15)
            SubBtn.TextColor3 = Library.Theme.Text
        end)

        -- delega CreateSection para as colunas da sub-aba
        SubTab.CreateSection = function(_, secName, side)
            return Tab.CreateSection(self, secName, side, SubTab)
        end

        return SubTab
    end

    -- // SECTIONS -------------------------------------------------------
    function Tab:CreateSection(secName, side, targetSubTab)
        local leftCol = targetSubTab and targetSubTab.LeftCol or self.LeftCol
        local rightCol = targetSubTab and targetSubTab.RightCol or self.RightCol

        local col
        if side == "Right" then
            col = rightCol
        elseif side == "Left" then
            col = leftCol
        else
            -- automático: escolhe a coluna com menor altura atual
            col = (leftCol.AbsoluteSize.Y <= rightCol.AbsoluteSize.Y) and leftCol or rightCol
        end

        local secJanitor = Janitor.new()

        local SectionFrame = Utility.Create("Frame", {
            BackgroundColor3 = Library.Theme.Section,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = col,
        })
        Utility.Corner(SectionFrame, 10)
        Utility.Stroke(SectionFrame, Library.Theme.Stroke, 1, 0.9)
        Library:Recolor(SectionFrame, "BackgroundColor3", "Section")

        local Header = Utility.Create("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 30),
            Text = "",
            AutoButtonColor = false,
            Parent = SectionFrame,
        })

        Utility.Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(1, -34, 1, 0),
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Library.Theme.Text,
            Text = secName,
            Parent = Header,
        })

        local Arrow = Utility.Create("ImageLabel", {
            BackgroundTransparency = 1,
            Image = "rbxassetid://6031091004",
            ImageColor3 = Library.Theme.SubText,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Rotation = 180,
            Size = UDim2.new(0, 14, 0, 14),
            Parent = Header,
        })

        local Content = Utility.Create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 30),
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = SectionFrame,
        })
        Utility.Padding(Content, 10)
        Utility.Create("UIListLayout", {
            Parent = Content,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        local collapsed = false
        Header.MouseButton1Click:Connect(function()
            Library:PlaySound("Click")
            collapsed = not collapsed
            Content.Visible = not collapsed
            Utility.Tween(Arrow, { Rotation = collapsed and 90 or 180 }, 0.2)
        end)

        local Section = {
            Instance = SectionFrame,
            Content = Content,
            _janitor = secJanitor,
        }

        function Section:Collapse() collapsed = true; Content.Visible = false; Arrow.Rotation = 90 end
        function Section:Expand() collapsed = false; Content.Visible = true; Arrow.Rotation = 180 end
        function Section:Destroy() secJanitor:Clean(); SectionFrame:Destroy() end

        -- // helper interno: cria container base p/ cada elemento
        local function ElementContainer(height)
            local holder = Utility.Create("Frame", {
                BackgroundColor3 = Library.Theme.Element,
                Size = UDim2.new(1, 0, 0, height or 34),
                Parent = Content,
            })
            Utility.Corner(holder, 8)
            Library:Recolor(holder, "BackgroundColor3", "Element")
            return holder
        end

        -- ============ BUTTON ============
        function Section:CreateButton(o)
            o = o or {}
            local holder = ElementContainer(34)
            local btn = Utility.Create("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = Library.Theme.Text,
                Text = o.Name or "Button",
                AutoButtonColor = false,
                Parent = holder,
            })
            local elJanitor = Janitor.new()
            local base = NewElementBase(holder, elJanitor)

            btn.MouseEnter:Connect(function()
                if base.Locked then return end
                Utility.Tween(holder, { BackgroundColor3 = Library.Theme.ElementHover }, 0.15)
            end)
            btn.MouseLeave:Connect(function()
                Utility.Tween(holder, { BackgroundColor3 = Library.Theme.Element }, 0.15)
            end)
            btn.MouseButton1Click:Connect(function()
                if base.Locked then return end
                Library:PlaySound("Click")
                Utility.Tween(holder, { BackgroundColor3 = Library.Theme.Accent }, 0.08)
                task.delay(0.08, function()
                    Utility.Tween(holder, { BackgroundColor3 = Library.Theme.Element }, 0.18)
                end)
                if o.Callback then pcall(o.Callback) end
            end)

            if o.Tooltip then Library:AddTooltip(btn, o.Tooltip) end
            return base
        end

        -- ============ TOGGLE ============
        function Section:CreateToggle(o)
            o = o or {}
            local holder = ElementContainer(34)
            Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Library.Theme.Text,
                Text = o.Name or "Toggle",
                Parent = holder,
            })

            local Switch = Utility.Create("Frame", {
                BackgroundColor3 = Library.Theme.Background,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.new(0, 36, 0, 18),
                Parent = holder,
            })
            Utility.Corner(Switch, 9)
            local Knob = Utility.Create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                Position = UDim2.new(0, 2, 0.5, -7),
                Size = UDim2.new(0, 14, 0, 14),
                Parent = Switch,
            })
            Utility.Corner(Knob, 7)

            local elJanitor = Janitor.new()
            local base = NewElementBase(holder, elJanitor)
            base.Value = o.Default or false

            local function render(instant)
                local t = base.Value and 0.25 or 0.05
                Utility.Tween(Switch, { BackgroundColor3 = base.Value and Library.Theme.Accent or Library.Theme.Background }, instant and 0 or 0.18)
                Utility.Tween(Knob, { Position = base.Value and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7) }, instant and 0 or 0.18)
            end

            function base:Set(value)
                base.Value = value and true or false
                render()
                if o.Flag then Library.Flags[o.Flag] = base.Value end
                if o.Callback then pcall(o.Callback, base.Value) end
            end

            function base:Get()
                return base.Value
            end

            local clickArea = Utility.Create("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", Parent = holder })
            clickArea.MouseButton1Click:Connect(function()
                if base.Locked then return end
                Library:PlaySound("Click")
                base:Set(not base.Value)
            end)

            render(true)
            if o.Flag then
                Library.Flags[o.Flag] = base.Value
                Library.Options[o.Flag] = base
            end
            if o.Tooltip then Library:AddTooltip(holder, o.Tooltip) end
            return base
        end

        -- ============ SLIDER ============
        function Section:CreateSlider(o)
            o = o or {}
            local min, max = o.Min or 0, o.Max or 100
            local increment = o.Increment or 1
            local suffix = o.Suffix or ""

            local holder = ElementContainer(44)
            Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 4),
                Size = UDim2.new(1, -24, 0, 16),
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Library.Theme.Text,
                Text = o.Name or "Slider",
                Parent = holder,
            })

            local ValueBox = Utility.Create("TextBox", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -12, 0, 4),
                Size = UDim2.new(0, 60, 0, 16),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextColor3 = Library.Theme.SubText,
                ClearTextOnFocus = false,
                Text = tostring(o.Default or min) .. suffix,
                Parent = holder,
            })

            local Track = Utility.Create("Frame", {
                BackgroundColor3 = Library.Theme.Background,
                Position = UDim2.new(0, 12, 0, 28),
                Size = UDim2.new(1, -24, 0, 6),
                Parent = holder,
            })
            Utility.Corner(Track, 3)
            local Fill = Utility.Create("Frame", {
                BackgroundColor3 = Library.Theme.Accent,
                Size = UDim2.new(0, 0, 1, 0),
                Parent = Track,
            })
            Utility.Corner(Fill, 3)
            Library:Recolor(Fill, "BackgroundColor3", "Accent")

            local elJanitor = Janitor.new()
            local base = NewElementBase(holder, elJanitor)
            base.Value = Utility.Clamp(o.Default or min, min, max)

            local function render()
                local pct = (base.Value - min) / (max - min)
                Fill.Size = UDim2.new(pct, 0, 1, 0)
                ValueBox.Text = tostring(base.Value) .. suffix
            end

            function base:Set(value)
                value = Utility.Clamp(Utility.Round(value, increment), min, max)
                base.Value = value
                render()
                if o.Flag then Library.Flags[o.Flag] = value end
                if o.Callback then pcall(o.Callback, value) end
            end

            function base:Get() return base.Value end

            local dragging = false
            local function updateFromX(x)
                local rel = Utility.Clamp((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                base:Set(min + (max - min) * rel)
            end

            elJanitor:Add(Track.InputBegan:Connect(function(input)
                if base.Locked then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateFromX(input.Position.X)
                end
            end))
            elJanitor:Add(UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateFromX(input.Position.X)
                end
            end))
            elJanitor:Add(UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end))

            ValueBox.FocusLost:Connect(function()
                local n = tonumber(ValueBox.Text:gsub(suffix, ""))
                if n then base:Set(n) else render() end
            end)

            render()
            if o.Flag then
                Library.Flags[o.Flag] = base.Value
                Library.Options[o.Flag] = base
            end
            if o.Tooltip then Library:AddTooltip(holder, o.Tooltip) end
            return base
        end

        -- ============ DROPDOWN ============
        function Section:CreateDropdown(o)
            o = o or {}
            local options = o.Options or {}
            local holder = ElementContainer(34)
            holder.ClipsDescendants = false

            Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -100, 1, 0),
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Library.Theme.Text,
                Text = o.Name or "Dropdown",
                Parent = holder,
            })

            local Selected = Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -28, 0, 0),
                Size = UDim2.new(0, 80, 1, 0),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextColor3 = Library.Theme.SubText,
                Text = tostring(o.Default or "..."),
                Parent = holder,
            })

            local Arrow = Utility.Create("ImageLabel", {
                BackgroundTransparency = 1,
                Image = "rbxassetid://6031091004",
                ImageColor3 = Library.Theme.SubText,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -8, 0.5, 0),
                Size = UDim2.new(0, 12, 0, 12),
                Parent = holder,
            })

            local Clicker = Utility.Create("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", Parent = holder })

            local List = Utility.Create("Frame", {
                BackgroundColor3 = Library.Theme.Element,
                Position = UDim2.new(0, 0, 1, 4),
                Size = UDim2.new(1, 0, 0, 0),
                Visible = false,
                ZIndex = 5,
                Parent = holder,
            })
            Utility.Corner(List, 8)
            Utility.Stroke(List, Library.Theme.Stroke, 1, 0.85)

            local Search = Utility.Create("TextBox", {
                BackgroundColor3 = Library.Theme.Background,
                Size = UDim2.new(1, -10, 0, 24),
                Position = UDim2.new(0, 5, 0, 5),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Library.Theme.Text,
                PlaceholderText = "Buscar...",
                ClearTextOnFocus = false,
                ZIndex = 6,
                Parent = List,
            })
            Utility.Corner(Search, 6)
            Utility.Padding(Search, 6)

            local ListScroll = Utility.Create("ScrollingFrame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 5, 0, 34),
                Size = UDim2.new(1, -10, 0, 120),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 3,
                ZIndex = 6,
                Parent = List,
            })
            Utility.Create("UIListLayout", { Parent = ListScroll, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })

            local elJanitor = Janitor.new()
            local base = NewElementBase(holder, elJanitor)
            base.Value = o.Default

            local open = false
            local function setOpen(state)
                open = state
                List.Visible = state
                List.Size = state and UDim2.new(1, 0, 0, 160) or UDim2.new(1, 0, 0, 0)
                Utility.Tween(Arrow, { Rotation = state and 180 or 0 }, 0.15)
            end

            function base:Set(value)
                base.Value = value
                Selected.Text = tostring(value)
                if o.Flag then Library.Flags[o.Flag] = value end
                if o.Callback then pcall(o.Callback, value) end
            end
            function base:Get() return base.Value end

            function base:Refresh(newOptions)
                options = newOptions
                for _, c in ipairs(ListScroll:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                base:_populate()
            end

            function base:_populate(filter)
                for _, c in ipairs(ListScroll:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                for _, opt in ipairs(options) do
                    if not filter or tostring(opt):lower():find(filter:lower(), 1, true) then
                        local optBtn = Utility.Create("TextButton", {
                            BackgroundColor3 = Library.Theme.Background,
                            Size = UDim2.new(1, 0, 0, 26),
                            Font = Enum.Font.Gotham,
                            TextSize = 12,
                            TextColor3 = Library.Theme.Text,
                            Text = tostring(opt),
                            AutoButtonColor = false,
                            ZIndex = 6,
                            Parent = ListScroll,
                        })
                        Utility.Corner(optBtn, 6)
                        optBtn.MouseButton1Click:Connect(function()
                            Library:PlaySound("Click")
                            base:Set(opt)
                            setOpen(false)
                        end)
                    end
                end
            end

            Clicker.MouseButton1Click:Connect(function()
                if base.Locked then return end
                Library:PlaySound("Click")
                setOpen(not open)
                if open then base:_populate() end
            end)
            Search:GetPropertyChangedSignal("Text"):Connect(function()
                base:_populate(Search.Text)
            end)

            if o.Default then Selected.Text = tostring(o.Default) end
            if o.Flag then
                Library.Flags[o.Flag] = base.Value
                Library.Options[o.Flag] = base
            end
            if o.Tooltip then Library:AddTooltip(holder, o.Tooltip) end
            return base
        end

        -- ============ MULTI DROPDOWN ============
        function Section:CreateMultiDropdown(o)
            o = o or {}
            local options = o.Options or {}
            local holder = ElementContainer(34)
            holder.ClipsDescendants = false

            Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -100, 1, 0),
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Library.Theme.Text,
                Text = o.Name or "Multi Dropdown",
                Parent = holder,
            })

            local Selected = Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -28, 0, 0),
                Size = UDim2.new(0, 90, 1, 0),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextColor3 = Library.Theme.SubText,
                Text = "0 selecionado(s)",
                Parent = holder,
            })

            local Arrow = Utility.Create("ImageLabel", {
                BackgroundTransparency = 1,
                Image = "rbxassetid://6031091004",
                ImageColor3 = Library.Theme.SubText,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -8, 0.5, 0),
                Size = UDim2.new(0, 12, 0, 12),
                Parent = holder,
            })

            local Clicker = Utility.Create("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", Parent = holder })

            local List = Utility.Create("Frame", {
                BackgroundColor3 = Library.Theme.Element,
                Position = UDim2.new(0, 0, 1, 4),
                Size = UDim2.new(1, 0, 0, 0),
                Visible = false,
                ZIndex = 5,
                Parent = holder,
            })
            Utility.Corner(List, 8)
            Utility.Stroke(List, Library.Theme.Stroke, 1, 0.85)

            local ListScroll = Utility.Create("ScrollingFrame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 5, 0, 5),
                Size = UDim2.new(1, -10, 0, 150),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 3,
                ZIndex = 6,
                Parent = List,
            })
            Utility.Create("UIListLayout", { Parent = ListScroll, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })

            local elJanitor = Janitor.new()
            local base = NewElementBase(holder, elJanitor)
            base.Value = {}
            for _, v in ipairs(o.Default or {}) do base.Value[v] = true end

            local open = false
            local function setOpen(state)
                open = state
                List.Visible = state
                List.Size = state and UDim2.new(1, 0, 0, 160) or UDim2.new(1, 0, 0, 0)
                Utility.Tween(Arrow, { Rotation = state and 180 or 0 }, 0.15)
            end

            local function getSelectedArray()
                local arr = {}
                for k, v in pairs(base.Value) do
                    if v then table.insert(arr, k) end
                end
                return arr
            end

            local function refreshLabel()
                local arr = getSelectedArray()
                Selected.Text = #arr .. " selecionado(s)"
            end

            function base:Set(tbl)
                base.Value = {}
                for _, v in ipairs(tbl) do base.Value[v] = true end
                refreshLabel()
                if o.Flag then Library.Flags[o.Flag] = getSelectedArray() end
                if o.Callback then pcall(o.Callback, getSelectedArray()) end
            end
            function base:Get() return getSelectedArray() end

            function base:_populate()
                for _, c in ipairs(ListScroll:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                for _, opt in ipairs(options) do
                    local active = base.Value[opt] == true
                    local optBtn = Utility.Create("TextButton", {
                        BackgroundColor3 = active and Library.Theme.Accent or Library.Theme.Background,
                        Size = UDim2.new(1, 0, 0, 26),
                        Font = Enum.Font.Gotham,
                        TextSize = 12,
                        TextColor3 = Library.Theme.Text,
                        Text = tostring(opt),
                        AutoButtonColor = false,
                        ZIndex = 6,
                        Parent = ListScroll,
                    })
                    Utility.Corner(optBtn, 6)
                    optBtn.MouseButton1Click:Connect(function()
                        Library:PlaySound("Click")
                        base.Value[opt] = not base.Value[opt] or nil
                        if base.Value[opt] == nil then base.Value[opt] = false end
                        optBtn.BackgroundColor3 = base.Value[opt] and Library.Theme.Accent or Library.Theme.Background
                        refreshLabel()
                        if o.Flag then Library.Flags[o.Flag] = getSelectedArray() end
                        if o.Callback then pcall(o.Callback, getSelectedArray()) end
                    end)
                end
            end

            Clicker.MouseButton1Click:Connect(function()
                if base.Locked then return end
                Library:PlaySound("Click")
                setOpen(not open)
                if open then base:_populate() end
            end)

            refreshLabel()
            if o.Flag then
                Library.Flags[o.Flag] = getSelectedArray()
                Library.Options[o.Flag] = base
            end
            if o.Tooltip then Library:AddTooltip(holder, o.Tooltip) end
            return base
        end

        -- ============ COLOR PICKER ============
        function Section:CreateColorPicker(o)
            o = o or {}
            local holder = ElementContainer(34)
            holder.ClipsDescendants = false

            Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Library.Theme.Text,
                Text = o.Name or "Color Picker",
                Parent = holder,
            })

            local Swatch = Utility.Create("TextButton", {
                BackgroundColor3 = o.Default or Color3.fromRGB(255, 255, 255),
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.new(0, 28, 0, 18),
                Text = "",
                AutoButtonColor = false,
                Parent = holder,
            })
            Utility.Corner(Swatch, 5)
            Utility.Stroke(Swatch, Library.Theme.Stroke, 1, 0.8)

            local Popup = Utility.Create("Frame", {
                BackgroundColor3 = Library.Theme.Element,
                Position = UDim2.new(0, 0, 1, 4),
                Size = UDim2.new(0, 220, 0, 0),
                Visible = false,
                ZIndex = 8,
                Parent = holder,
            })
            Utility.Corner(Popup, 10)
            Utility.Stroke(Popup, Library.Theme.Stroke, 1, 0.8)
            Utility.Padding(Popup, 10)

            local SVBox = Utility.Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(255, 0, 0),
                Size = UDim2.new(1, 0, 0, 110),
                ZIndex = 8,
                Parent = Popup,
            })
            Utility.Corner(SVBox, 6)
            local SatGrad = Utility.Create("Frame", { BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(1,0,1,0), ZIndex = 8, Parent = SVBox })
            Utility.Create("UIGradient", { Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(1,1,1)), Transparency = NumberSequence.new(0, 1), Parent = SatGrad })
            local ValGrad = Utility.Create("Frame", { BackgroundColor3 = Color3.new(0,0,0), Size = UDim2.new(1,0,1,0), ZIndex = 8, Parent = SVBox })
            Utility.Create("UIGradient", { Color = ColorSequence.new(Color3.new(0,0,0), Color3.new(0,0,0)), Transparency = NumberSequence.new(1, 0), Rotation = 90, Parent = ValGrad })
            Utility.Corner(SatGrad, 6); Utility.Corner(ValGrad, 6)

            local SVCursor = Utility.Create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(0, 8, 0, 8),
                ZIndex = 9,
                Parent = SVBox,
            })
            Utility.Corner(SVCursor, 4)
            Utility.Stroke(SVCursor, Color3.new(0,0,0), 1, 0)

            local HueBar = Utility.Create("Frame", {
                BackgroundColor3 = Color3.new(1,1,1),
                Size = UDim2.new(1, 0, 0, 14),
                Position = UDim2.new(0, 0, 0, 120),
                ZIndex = 8,
                Parent = Popup,
            })
            Utility.Corner(HueBar, 6)
            local hueSeq = {}
            for i = 0, 10 do
                table.insert(hueSeq, ColorSequenceKeypoint.new(i / 10, Color3.fromHSV(i / 10, 1, 1)))
            end
            Utility.Create("UIGradient", { Color = ColorSequence.new(hueSeq), Parent = HueBar })
            local HueCursor = Utility.Create("Frame", {
                BackgroundColor3 = Color3.new(1,1,1),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(0, 4, 1, 4),
                Position = UDim2.new(0, 0, 0.5, 0),
                ZIndex = 9,
                Parent = HueBar,
            })

            local HexBox = Utility.Create("TextBox", {
                BackgroundColor3 = Library.Theme.Background,
                Size = UDim2.new(1, 0, 0, 24),
                Position = UDim2.new(0, 0, 0, 142),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Library.Theme.Text,
                ClearTextOnFocus = false,
                Text = "#FFFFFF",
                ZIndex = 8,
                Parent = Popup,
            })
            Utility.Corner(HexBox, 6)

            local ActionsRow = Utility.Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 24),
                Position = UDim2.new(0, 0, 0, 172),
                ZIndex = 8,
                Parent = Popup,
            })
            Utility.Create("UIListLayout", { Parent = ActionsRow, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder })

            local function smallBtn(text)
                local b = Utility.Create("TextButton", {
                    BackgroundColor3 = Library.Theme.Background,
                    Size = UDim2.new(0, 50, 1, 0),
                    Font = Enum.Font.Gotham, TextSize = 11,
                    TextColor3 = Library.Theme.Text, Text = text,
                    AutoButtonColor = false, ZIndex = 8,
                    Parent = ActionsRow,
                })
                Utility.Corner(b, 6)
                return b
            end
            local CopyBtn = smallBtn("Copiar")
            local PasteBtn = smallBtn("Colar")
            local RainbowBtn = smallBtn("Rainbow")

            Popup.Size = UDim2.new(0, 220, 0, 206)

            local elJanitor = Janitor.new()
            local base = NewElementBase(holder, elJanitor)
            local h, s, v = Color3.toHSV(o.Default or Color3.fromRGB(255,255,255))
            base.Value = o.Default or Color3.fromRGB(255, 255, 255)
            local rainbowOn = false

            local function applyColor(noCallback)
                local color = Color3.fromHSV(h, s, v)
                base.Value = color
                Swatch.BackgroundColor3 = color
                SVBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                HexBox.Text = string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
                if not noCallback then
                    if o.Flag then Library.Flags[o.Flag] = color end
                    if o.Callback then pcall(o.Callback, color) end
                end
            end

            function base:Set(color)
                h, s, v = Color3.toHSV(color)
                applyColor()
            end
            function base:Get() return base.Value end

            Swatch.MouseButton1Click:Connect(function()
                if base.Locked then return end
                Popup.Visible = not Popup.Visible
            end)

            local draggingSV, draggingHue = false, false
            local function updateSV(pos)
                local rel = Vector2.new(
                    Utility.Clamp((pos.X - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X, 0, 1),
                    Utility.Clamp((pos.Y - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y, 0, 1)
                )
                s = rel.X
                v = 1 - rel.Y
                SVCursor.Position = UDim2.new(rel.X, 0, rel.Y, 0)
                applyColor()
            end
            local function updateHue(pos)
                local rel = Utility.Clamp((pos.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
                h = rel
                HueCursor.Position = UDim2.new(rel, 0, 0.5, 0)
                applyColor()
            end

            elJanitor:Add(SVBox.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSV = true; updateSV(i.Position) end end))
            elJanitor:Add(HueBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingHue = true; updateHue(i.Position) end end))
            elJanitor:Add(UserInputService.InputChanged:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseMovement then
                    if draggingSV then updateSV(i.Position) end
                    if draggingHue then updateHue(i.Position) end
                end
            end))
            elJanitor:Add(UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSV = false; draggingHue = false end
            end))

            HexBox.FocusLost:Connect(function()
                local hex = HexBox.Text:gsub("#", "")
                if #hex == 6 then
                    local r = tonumber(hex:sub(1,2), 16)
                    local g = tonumber(hex:sub(3,4), 16)
                    local bl = tonumber(hex:sub(5,6), 16)
                    if r and g and bl then
                        base:Set(Color3.fromRGB(r, g, bl))
                    end
                end
            end)

            CopyBtn.MouseButton1Click:Connect(function()
                pcall(function() setclipboard(HexBox.Text) end)
                Library:PlaySound("Click")
            end)
            PasteBtn.MouseButton1Click:Connect(function()
                local ok, clip = pcall(function() return getclipboard() end)
                if ok and clip then
                    HexBox.Text = clip
                    HexBox.FocusLost:Wait()
                end
                Library:PlaySound("Click")
            end)
            RainbowBtn.MouseButton1Click:Connect(function()
                rainbowOn = not rainbowOn
                RainbowBtn.BackgroundColor3 = rainbowOn and Library.Theme.Accent or Library.Theme.Background
                if rainbowOn then
                    elJanitor:Add(task.spawn(function()
                        while rainbowOn do
                            h = (h + 0.01) % 1
                            applyColor()
                            task.wait(0.03)
                        end
                    end), nil)
                end
            end)

            applyColor(true)
            if o.Flag then
                Library.Flags[o.Flag] = base.Value
                Library.Options[o.Flag] = base
            end
            if o.Tooltip then Library:AddTooltip(holder, o.Tooltip) end
            return base
        end

        -- ============ KEYBIND ============
        function Section:CreateKeybind(o)
            o = o or {}
            local holder = ElementContainer(34)
            Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -110, 1, 0),
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Library.Theme.Text,
                Text = o.Name or "Keybind",
                Parent = holder,
            })

            local KeyBtn = Utility.Create("TextButton", {
                BackgroundColor3 = Library.Theme.Background,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.new(0, 80, 0, 22),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Library.Theme.Text,
                Text = o.Default and o.Default.Name or "Nenhuma",
                AutoButtonColor = false,
                Parent = holder,
            })
            Utility.Corner(KeyBtn, 6)

            local elJanitor = Janitor.new()
            local base = NewElementBase(holder, elJanitor)
            base.Key = o.Default
            base.Mode = o.Mode or "Toggle" -- "Toggle" | "Hold" | "Always"
            base.Value = false

            local listening = false
            KeyBtn.MouseButton1Click:Connect(function()
                if base.Locked then return end
                listening = true
                KeyBtn.Text = "..."
            end)

            elJanitor:Add(UserInputService.InputBegan:Connect(function(input, gpe)
                if listening then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        base.Key = input.KeyCode
                        KeyBtn.Text = input.KeyCode.Name
                        listening = false
                    end
                    return
                end
                if gpe or not base.Key then return end
                if input.KeyCode == base.Key then
                    if base.Mode == "Toggle" then
                        base.Value = not base.Value
                        if o.Callback then pcall(o.Callback, base.Value) end
                    elseif base.Mode == "Hold" then
                        base.Value = true
                        if o.Callback then pcall(o.Callback, true) end
                    end
                    if o.Flag then Library.Flags[o.Flag] = base.Value end
                end
            end))
            elJanitor:Add(UserInputService.InputEnded:Connect(function(input)
                if base.Mode == "Hold" and base.Key and input.KeyCode == base.Key then
                    base.Value = false
                    if o.Callback then pcall(o.Callback, false) end
                    if o.Flag then Library.Flags[o.Flag] = false end
                end
            end))

            function base:Set(key) base.Key = key; KeyBtn.Text = key and key.Name or "Nenhuma" end
            function base:Get() return base.Key end

            if o.Flag then Library.Options[o.Flag] = base end
            if o.Tooltip then Library:AddTooltip(holder, o.Tooltip) end
            return base
        end

        -- ============ TEXTBOX ============
        function Section:CreateTextbox(o)
            o = o or {}
            local holder = ElementContainer(34)
            Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(0, 90, 1, 0),
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Library.Theme.Text,
                Text = o.Name or "Input",
                Parent = holder,
            })

            local Box = Utility.Create("TextBox", {
                BackgroundColor3 = Library.Theme.Background,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.new(0, 140, 0, 22),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Library.Theme.Text,
                PlaceholderText = o.Placeholder or "",
                ClearTextOnFocus = false,
                Text = o.Default or "",
                Parent = holder,
            })
            Utility.Corner(Box, 6)
            Utility.Padding(Box, 6)

            local elJanitor = Janitor.new()
            local base = NewElementBase(holder, elJanitor)
            base.Value = o.Default or ""

            Box:GetPropertyChangedSignal("Text"):Connect(function()
                local text = Box.Text
                if o.NumbersOnly then
                    text = text:gsub("%D", "")
                    Box.Text = text
                end
                if o.MaxLength and #text > o.MaxLength then
                    text = text:sub(1, o.MaxLength)
                    Box.Text = text
                end
                base.Value = text
                if o.Flag then Library.Flags[o.Flag] = text end
            end)
            Box.FocusLost:Connect(function(enterPressed)
                if o.Callback then pcall(o.Callback, base.Value, enterPressed) end
            end)

            function base:Set(text) Box.Text = text end
            function base:Get() return base.Value end

            if o.Flag then
                Library.Flags[o.Flag] = base.Value
                Library.Options[o.Flag] = base
            end
            if o.Tooltip then Library:AddTooltip(holder, o.Tooltip) end
            return base
        end

        -- ============ LABEL / TITLE / SUBTITLE / PARAGRAPH / DIVIDER ============
        function Section:CreateLabel(o)
            o = o or {}
            local holder = ElementContainer(24)
            holder.BackgroundTransparency = 1
            local lbl = Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Library.Theme.Text,
                Text = o.Text or "",
                Parent = holder,
            })
            local elJanitor = Janitor.new()
            local base = NewElementBase(holder, elJanitor)
            function base:Set(text) lbl.Text = text end
            function base:Get() return lbl.Text end
            return base
        end

        function Section:CreateTitle(o)
            o = o or {}
            local holder = ElementContainer(28)
            holder.BackgroundTransparency = 1
            local lbl = Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = Enum.Font.GothamBold,
                TextSize = 18,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Library.Theme.Text,
                Text = o.Text or "Título",
                Parent = holder,
            })
            return NewElementBase(holder, Janitor.new())
        end

        function Section:CreateSubtitle(o)
            o = o or {}
            local holder = ElementContainer(20)
            holder.BackgroundTransparency = 1
            Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Library.Theme.SubText,
                Text = o.Text or "Subtítulo",
                Parent = holder,
            })
            return NewElementBase(holder, Janitor.new())
        end

        function Section:CreateParagraph(o)
            o = o or {}
            local holder = ElementContainer(0)
            holder.AutomaticSize = Enum.AutomaticSize.Y
            holder.Size = UDim2.new(1, 0, 0, 0)
            Utility.Padding(holder, 10)
            if o.Title then
                Utility.Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    Font = Enum.Font.GothamBold,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextColor3 = Library.Theme.Text,
                    Text = o.Title,
                    Parent = holder,
                })
            end
            Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, o.Title and 18 or 0),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Library.Theme.SubText,
                Text = o.Text or "",
                Parent = holder,
            })
            return NewElementBase(holder, Janitor.new())
        end

        function Section:CreateDivider()
            local holder = Utility.Create("Frame", {
                BackgroundColor3 = Library.Theme.Stroke,
                BackgroundTransparency = 0.9,
                Size = UDim2.new(1, 0, 0, 1),
                Parent = Content,
            })
            return NewElementBase(holder, Janitor.new())
        end

        return Section
    end

    table.insert(self.Tabs, Tab)
    if isDefault then self._firstTab = Tab end
    return Tab
end

-- // EXTRAS -------------------------------------------------------------

-- Watermark / contador de FPS
function Library:CreateWatermark(opts)
    opts = opts or {}
    local parent = GetGuiParent()
    local gui = Utility.Create("ScreenGui", { Name = "AuroraWatermark", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = parent })
    local frame = Utility.Create("Frame", {
        BackgroundColor3 = Library.Theme.Section,
        Position = UDim2.new(0, 10, 0, 10),
        Size = UDim2.new(0, 180, 0, 24),
        Parent = gui,
    })
    Utility.Corner(frame, 6)
    Utility.Stroke(frame, Library.Theme.Stroke, 1, 0.88)
    local label = Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Library.Theme.Text,
        Text = opts.Text or "Aurora UI",
        Parent = frame,
    })

    local janitor = Janitor.new()
    Utility.MakeDraggable(frame, frame, janitor)

    if opts.ShowFPS then
        local frames, last = 0, os.clock()
        janitor:Add(RunService.RenderStepped:Connect(function()
            frames += 1
            local now = os.clock()
            if now - last >= 1 then
                label.Text = string.format("%s | %d FPS", opts.Text or "Aurora UI", frames)
                frames = 0
                last = now
            end
        end))
    end

    return NewElementBase(frame, janitor)
end

-- Tela de carregamento
function Library:CreateLoadingScreen(opts)
    opts = opts or {}
    local parent = GetGuiParent()
    local gui = Utility.Create("ScreenGui", { Name = "AuroraLoading", IgnoreGuiInset = true, Parent = parent })
    local bg = Utility.Create("Frame", { BackgroundColor3 = Library.Theme.Background, Size = UDim2.new(1,0,1,0), Parent = gui })

    Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.45, 0),
        Size = UDim2.new(0, 400, 0, 40),
        Font = Enum.Font.GothamBold,
        TextSize = 24,
        TextColor3 = Library.Theme.Text,
        Text = opts.Title or "Aurora UI",
        Parent = bg,
    })
    Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.52, 0),
        Size = UDim2.new(0, 400, 0, 20),
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = Library.Theme.SubText,
        Text = opts.Subtitle or "Carregando...",
        Parent = bg,
    })

    local barBg = Utility.Create("Frame", {
        BackgroundColor3 = Library.Theme.Element,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.58, 0),
        Size = UDim2.new(0, 240, 0, 6),
        Parent = bg,
    })
    Utility.Corner(barBg, 3)
    local bar = Utility.Create("Frame", { BackgroundColor3 = Library.Theme.Accent, Size = UDim2.new(0, 0, 1, 0), Parent = barBg })
    Utility.Corner(bar, 3)
    Utility.Tween(bar, { Size = UDim2.new(1, 0, 1, 0) }, 1.4)

    local handle = { Gui = gui }
    function handle:Finish()
        Utility.Tween(bg, { BackgroundTransparency = 1 }, 0.4)
        task.delay(0.4, function() gui:Destroy() end)
    end
    return handle
end

-- Blur de fundo
function Library:SetBlur(enabled, size)
    if enabled then
        if not Library._blur then
            Library._blur = Utility.Create("BlurEffect", { Size = 0, Parent = Lighting })
        end
        Utility.Tween(Library._blur, { Size = size or 18 }, 0.3)
    elseif Library._blur then
        Utility.Tween(Library._blur, { Size = 0 }, 0.3)
        task.delay(0.3, function()
            if Library._blur then Library._blur:Destroy(); Library._blur = nil end
        end)
    end
end

-- Sistema de comandos simples
Library.Commands = {}
function Library:RegisterCommand(name, callback)
    Library.Commands[name:lower()] = callback
end

function Library:ExecuteCommand(input)
    local parts = string.split(input, " ")
    local name = table.remove(parts, 1)
    local cb = name and Library.Commands[name:lower()]
    if cb then
        pcall(cb, parts)
        return true
    end
    return false
end

-- Janela de debug
function Library:CreateDebugWindow()
    local parent = GetGuiParent()
    local gui = Utility.Create("ScreenGui", { Name = "AuroraDebug", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = parent })
    local frame = Utility.Create("Frame", {
        BackgroundColor3 = Library.Theme.Section,
        Position = UDim2.new(0, 10, 1, -120),
        Size = UDim2.new(0, 220, 0, 100),
        Parent = gui,
    })
    Utility.Corner(frame, 8)
    Utility.Stroke(frame, Library.Theme.Stroke, 1, 0.85)
    local label = Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 1, -16),
        Position = UDim2.new(0, 8, 0, 8),
        Font = Enum.Font.Code,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextColor3 = Library.Theme.Text,
        Text = "",
        Parent = frame,
    })
    local janitor = Janitor.new()
    Utility.MakeDraggable(frame, frame, janitor)
    janitor:Add(RunService.Heartbeat:Connect(function()
        local mem = math.floor(collectgarbage("count"))
        local elementCount = 0
        for _ in pairs(Library.Options) do elementCount += 1 end
        label.Text = string.format(
            "Memória: %d KB\nElementos: %d\nJanelas: %d",
            mem, elementCount, #Library.Windows
        )
    end))
    return NewElementBase(frame, janitor)
end

return Library
