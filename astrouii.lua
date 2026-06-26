-- // =========================================
-- // King Rua Hub UI Library – vFinal
-- // =========================================
local Library = {}

-- Serviços
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")

-- Helpers
function Library:TweenInstance(Instance, Time, Property, NewValue)
	local Tween = TweenService:Create(Instance, TweenInfo.new(Time, Enum.EasingStyle.Quad), { [Property] = NewValue })
	Tween:Play()
	return Tween
end

function Library:UpdateScrolling(Scroll, List)
	Scroll.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 15)
	List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		Scroll.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 15)
	end)
end

function Library:MouseEvent(Button, EnterCallback, LeaveCallback)
	Button.MouseEnter:Connect(EnterCallback)
	Button.MouseLeave:Connect(LeaveCallback)
end

function Library:MakeConfig(Defaults, Given)
	Given = Given or {}
	for Key, Default in pairs(Defaults) do
		if Given[Key] == nil then
			Given[Key] = Default
		end
	end
	return Given
end

function Library:MakeDraggable(TopBar, Object)
	local Dragging, DragStart, StartPos
	TopBar.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			DragStart = Input.Position
			StartPos = Object.Position
			Input.Changed:Connect(function(Prop)
				if Prop == "UserInputState" and Input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(Input)
		if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
			local Delta = Input.Position - DragStart
			Object.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
		end
	end)
end

-- Flags & Persistência
Library.Flags = {}
local FlagsFolder = nil
pcall(function()
	if writefile and readfile then
		FlagsFolder = "KingRua_Hub"
		if not isfolder(FlagsFolder) then makefolder(FlagsFolder) end
	end
end)

function Library:SaveSettings()
	if not FlagsFolder then return end
	local Data = {}
	for Name, Flag in pairs(Library.Flags) do
		Data[Name] = Flag.Value
	end
	pcall(writefile, FlagsFolder .. "/flags.json", game:GetService("HttpService"):JSONEncode(Data))
end

function Library:LoadSettings()
	if not FlagsFolder then return end
	local Success, Content = pcall(readfile, FlagsFolder .. "/flags.json")
	if Success and Content then
		local Data = game:GetService("HttpService"):JSONDecode(Content)
		for Name, Value in pairs(Data) do
			if Library.Flags[Name] and Library.Flags[Name].Set then
				Library.Flags[Name]:Set(Value, true)
			end
		end
	end
end

-- Notificações
function Library:Notification(Title, Text, Duration)
	Duration = Duration or 5
	local NotifyGui = Instance.new("ScreenGui")
	NotifyGui.Name = "NotificationGui"
	NotifyGui.Parent = CoreGui
	NotifyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(0, 260, 0, 80)
	Frame.Position = UDim2.new(1, -270, 1, -90)
	Frame.AnchorPoint = Vector2.new(0, 1)
	Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	Frame.BorderSizePixel = 0
	Frame.Parent = NotifyGui
	Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
	Instance.new("UIStroke", Frame).Color = Color3.fromRGB(100, 100, 100)

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Size = UDim2.new(1, -10, 0, 20)
	TitleLabel.Position = UDim2.new(0, 10, 0, 10)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Font = Enum.Font.GothamBold
	TitleLabel.Text = Title
	TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	TitleLabel.TextSize = 14
	TitleLabel.Parent = Frame

	local TextLabel = Instance.new("TextLabel")
	TextLabel.Size = UDim2.new(1, -10, 0, 30)
	TextLabel.Position = UDim2.new(0, 10, 0, 35)
	TextLabel.BackgroundTransparency = 1
	TextLabel.Font = Enum.Font.Gotham
	TextLabel.Text = Text
	TextLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	TextLabel.TextSize = 12
	TextLabel.TextWrapped = true
	TextLabel.Parent = Frame

	Library:TweenInstance(Frame, 0.4, "Position", UDim2.new(1, -270, 1, -10))
	task.delay(Duration, function()
		Library:TweenInstance(Frame, 0.4, "Position", UDim2.new(1, -270, 1, -90))
		task.delay(0.4, NotifyGui.Destroy, NotifyGui)
	end)
end

-- =====================================================================
-- Construtor da Janela
-- =====================================================================
function Library:NewWindow(ConfigWindow)
	local OldGui = CoreGui:FindFirstChild("KingRuaUI_Premium")
	if OldGui then OldGui:Destroy() end

	ConfigWindow = self:MakeConfig({
		Title = "King Rua Hub",
		Description = "By _ng.shinichi",
		ThemeColor = Color3.fromRGB(255, 255, 255),   -- cor dos contornos
		ToggleKey = Enum.KeyCode.RightShift,
	}, ConfigWindow or {})

	local ThemeColor = ConfigWindow.ThemeColor
	local WindowOpen = true
	local KeybindConnection

	local KingRuaUI_Premium = Instance.new("ScreenGui")
	KingRuaUI_Premium.Name = "KingRuaUI_Premium"
	KingRuaUI_Premium.Parent = CoreGui
	KingRuaUI_Premium.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Main (centralizado)
	local Main = Instance.new("Frame")
	Main.BackgroundColor3 = Color3.fromRGB(9,9,9)
	Main.BackgroundTransparency = 0.07
	Main.BorderSizePixel = 0
	Main.Size = UDim2.new(0, 555, 0, 350)
	Main.AnchorPoint = Vector2.new(0.5, 0.5)
	Main.Position = UDim2.new(0.5, 0, 0.5, 0)
	Main.Parent = KingRuaUI_Premium
	Instance.new("UICorner", Main)

	local UIStroke = Instance.new("UIStroke")
	UIStroke.Color = ThemeColor
	UIStroke.Thickness = 1.5
	UIStroke.Transparency = 0.5
	UIStroke.Parent = Main

	-- Top
	local Top = Instance.new("Frame")
	Top.BackgroundTransparency = 1
	Top.Size = UDim2.new(1,0,0,50)
	Top.Name = "Top"
	Top.Parent = Main

	local Left = Instance.new("Folder")
	Left.Name = "Left"
	Left.Parent = Top

	local NameHub = Instance.new("TextLabel")
	NameHub.BackgroundTransparency = 1
	NameHub.Position = UDim2.new(0,60,0,10)
	NameHub.Size = UDim2.new(0,470,0,20)
	NameHub.Font = Enum.Font.GothamBold
	NameHub.Text = ConfigWindow.Title
	NameHub.TextColor3 = Color3.fromRGB(255,255,255)
	NameHub.TextSize = 14
	NameHub.TextXAlignment = Enum.TextXAlignment.Left
	NameHub.Parent = Left

	local LogoHub = Instance.new("ImageLabel")
	LogoHub.BackgroundTransparency = 1
	LogoHub.Position = UDim2.new(0,10,0,5)
	LogoHub.Size = UDim2.new(0,40,0,35)
	LogoHub.Image = "rbxassetid://124762714875426"
	LogoHub.Parent = Left

	local Desc = Instance.new("TextLabel")
	Desc.BackgroundTransparency = 1
	Desc.Position = UDim2.new(0,60,0,27)
	Desc.Size = UDim2.new(0,470,1,-30)
	Desc.Font = Enum.Font.GothamBold
	Desc.Text = ConfigWindow.Description
	Desc.TextColor3 = Color3.fromRGB(100,100,100)
	Desc.TextSize = 12
	Desc.TextXAlignment = Enum.TextXAlignment.Left
	Desc.TextYAlignment = Enum.TextYAlignment.Top
	Desc.Parent = Left

	local Right = Instance.new("Folder")
	Right.Name = "Right"
	Right.Parent = Top

	local Frame = Instance.new("Frame")
	Frame.BackgroundTransparency = 1
	Frame.Position = UDim2.new(1, -110, 0, 0)
	Frame.Size = UDim2.new(0, 110, 1, 0)
	Frame.Parent = Right

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Padding = UDim.new(0,6)
	UIListLayout.Parent = Frame

	local UIPadding = Instance.new("UIPadding")
	UIPadding.PaddingTop = UDim.new(0,10)
	UIPadding.Parent = Frame

	-- Minimize
	local Minize = Instance.new("TextButton")
	Minize.BackgroundTransparency = 1
	Minize.Size = UDim2.new(0,30,0,30)
	Minize.Text = ""
	Minize.Parent = Frame
	local IconMin = Instance.new("ImageLabel")
	IconMin.AnchorPoint = Vector2.new(0.5,0.5)
	IconMin.BackgroundTransparency = 1
	IconMin.Position = UDim2.new(0.5,0,0.5,0)
	IconMin.Size = UDim2.new(0,20,0,20)
	IconMin.Image = "rbxassetid://136452605242985"
	IconMin.ImageRectOffset = Vector2.new(288,672)
	IconMin.ImageRectSize = Vector2.new(96,96)
	IconMin.Parent = Minize
	Minize.Activated:Connect(function()
		WindowOpen = false
		Main.Visible = false
	end)

	-- Maximize/Restore (apenas estica, sem mover)
	local Large = Instance.new("TextButton")
	Large.BackgroundTransparency = 1
	Large.Size = UDim2.new(0,30,0,30)
	Large.Text = ""
	Large.Parent = Frame
	local IconMax = Instance.new("ImageLabel")
	IconMax.AnchorPoint = Vector2.new(0.5,0.5)
	IconMax.BackgroundTransparency = 1
	IconMax.Position = UDim2.new(0.5,0,0.5,0)
	IconMax.Size = UDim2.new(0,18,0,18)
	IconMax.Image = "rbxassetid://136452605242985"
	IconMax.ImageRectOffset = Vector2.new(580,194)
	IconMax.ImageRectSize = Vector2.new(96,96)
	IconMax.Parent = Large

	local IsMaximized = false
	local OldSize = Main.Size
	Large.Activated:Connect(function()
		if IsMaximized then
			Library:TweenInstance(Main, 0.3, "Size", OldSize)
			IconMax.ImageRectOffset = Vector2.new(580,194)
			IsMaximized = false
		else
			OldSize = Main.Size
			Library:TweenInstance(Main, 0.3, "Size", UDim2.new(1,0,1,0))
			IconMax.ImageRectOffset = Vector2.new(580,98)
			IsMaximized = true
		end
	end)

	-- Close
	local Close = Instance.new("TextButton")
	Close.BackgroundTransparency = 1
	Close.Size = UDim2.new(0,30,0,30)
	Close.Text = ""
	Close.Parent = Frame
	local IconClose = Instance.new("ImageLabel")
	IconClose.AnchorPoint = Vector2.new(0.5,0.5)
	IconClose.BackgroundTransparency = 1
	IconClose.Position = UDim2.new(0.5,0,0.5,0)
	IconClose.Size = UDim2.new(0,20,0,20)
	IconClose.Image = "rbxassetid://105957381820378"
	IconClose.ImageRectOffset = Vector2.new(480,0)
	IconClose.ImageRectSize = Vector2.new(96,96)
	IconClose.Parent = Close
	Close.Activated:Connect(function()
		KingRuaUI_Premium:Destroy()
		if KeybindConnection then KeybindConnection:Disconnect() end
	end)

	-- TabFrame (barra lateral das abas)
	local TabFrame = Instance.new("Frame")
	TabFrame.BackgroundTransparency = 1
	TabFrame.Position = UDim2.new(0,0,0,50)
	TabFrame.Size = UDim2.new(0,144,1,-50)
	TabFrame.Parent = Main

	local SearchFrame = Instance.new("Frame")
	SearchFrame.BackgroundColor3 = Color3.new(1,1,1)
	SearchFrame.BackgroundTransparency = 0.95
	SearchFrame.BorderSizePixel = 0
	SearchFrame.Position = UDim2.new(0,7,0,10)
	SearchFrame.Size = UDim2.new(1,-14,0,30)
	SearchFrame.Parent = TabFrame
	Instance.new("UICorner", SearchFrame).CornerRadius = UDim.new(0,3)

	local IconSearch = Instance.new("ImageLabel")
	IconSearch.AnchorPoint = Vector2.new(0,0.5)
	IconSearch.BackgroundTransparency = 1
	IconSearch.Position = UDim2.new(0,10,0.5,0)
	IconSearch.Size = UDim2.new(0,15,0,15)
	IconSearch.Image = "rbxassetid://71309835376233"
	IconSearch.Parent = SearchFrame

	local SearchBox = Instance.new("TextBox")
	SearchBox.BackgroundTransparency = 1
	SearchBox.ClipsDescendants = true
	SearchBox.Position = UDim2.new(0,35,0,0)
	SearchBox.Size = UDim2.new(1,-35,1,0)
	SearchBox.Font = Enum.Font.GothamBold
	SearchBox.PlaceholderText = "Search..."
	SearchBox.Text = ""
	SearchBox.TextColor3 = Color3.fromRGB(255,255,255)
	SearchBox.TextSize = 13
	SearchBox.TextXAlignment = Enum.TextXAlignment.Left
	SearchBox.Parent = SearchFrame

	-- Lista de abas (ScrollingFrame na lateral)
	local ScrollingTab = Instance.new("ScrollingFrame")
	ScrollingTab.BackgroundTransparency = 1
	ScrollingTab.Position = UDim2.new(0,0,0,50)
	ScrollingTab.Selectable = false
	ScrollingTab.Size = UDim2.new(1,0,1,-50)
	ScrollingTab.ScrollBarThickness = 0
	ScrollingTab.Parent = TabFrame

	local UIListLayout_2 = Instance.new("UIListLayout")
	UIListLayout_2.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout_2.Parent = ScrollingTab

	local UIPadding_2 = Instance.new("UIPadding")
	UIPadding_2.PaddingBottom = UDim.new(0,3)
	UIPadding_2.PaddingLeft = UDim.new(0,7)
	UIPadding_2.PaddingRight = UDim.new(0,7)
	UIPadding_2.PaddingTop = UDim.new(0,3)
	UIPadding_2.Parent = ScrollingTab

	Library:UpdateScrolling(ScrollingTab, UIListLayout_2)

	-- Layout da área de conteúdo
	local LayoutFrame = Instance.new("Frame")
	LayoutFrame.BackgroundTransparency = 1
	LayoutFrame.Position = UDim2.new(0,144,0,50)
	LayoutFrame.Size = UDim2.new(1,-144,1,-50)
	LayoutFrame.ClipsDescendants = true
	LayoutFrame.Parent = Main

	local LayoutName = Instance.new("Frame")
	LayoutName.BackgroundTransparency = 1
	LayoutName.Size = UDim2.new(1,0,0,40)
	LayoutName.Parent = LayoutFrame

	local TextLabel = Instance.new("TextLabel")  -- nome da aba atual
	TextLabel.BackgroundTransparency = 1
	TextLabel.Position = UDim2.new(0,10,0,0)
	TextLabel.Size = UDim2.new(1,-10,1,0)
	TextLabel.Font = Enum.Font.GothamBold
	TextLabel.Text = ""
	TextLabel.TextColor3 = Color3.fromRGB(255,255,255)
	TextLabel.TextSize = 13
	TextLabel.TextXAlignment = Enum.TextXAlignment.Left
	TextLabel.Parent = LayoutName

	-- Contêiner dos conteúdos das abas
	local TabContentContainer = Instance.new("Frame")
	TabContentContainer.BackgroundTransparency = 1
	TabContentContainer.Size = UDim2.new(1,0,1,-40)
	TabContentContainer.Position = UDim2.new(0,0,0,40)
	TabContentContainer.Parent = LayoutFrame

	-- Tabela para guardar ScrollingFrames das abas
	local TabContents = {}
	local ActiveTabContent = nil

	-- DropdownZone (para dropdowns e color picker modal)
	local DropdownZone = Instance.new("Frame")
	DropdownZone.Name = "DropdownZone"
	DropdownZone.BackgroundColor3 = Color3.new(0,0,0)
	DropdownZone.BackgroundTransparency = 1
	DropdownZone.BorderSizePixel = 0
	DropdownZone.Size = UDim2.new(1,0,1,0)
	DropdownZone.Visible = false
	DropdownZone.Parent = Main

	Library:MakeDraggable(Top, Main)

	-- ========================
	-- Funções de aba e elementos
	-- ========================
	local Window = {}

	local function SwitchTab(TabButton)
		for _, tabBtn in ipairs(ScrollingTab:GetChildren()) do
			if tabBtn:IsA("Frame") then
				tabBtn.BackgroundColor3 = Color3.new(1,1,1)
				tabBtn.BackgroundTransparency = 1
				local nl = tabBtn:FindFirstChild("NameTab")
				if nl then nl.TextTransparency = 0.5 end
			end
		end
		TabButton.BackgroundColor3 = Color3.fromRGB(30,30,30)
		TabButton.BackgroundTransparency = 0.3
		local nl = TabButton:FindFirstChild("NameTab")
		if nl then nl.TextTransparency = 0 end
		local content = TabContents[TabButton]
		if content then
			if ActiveTabContent then ActiveTabContent.Visible = false end
			content.Visible = true
			ActiveTabContent = content
			TextLabel.Text = nl and nl.Text or ""
		end
	end

	function Window:CreateTab(TabConfig)
		local TabName, TabIcon
		if type(TabConfig) == "string" then
			TabName = TabConfig
			TabIcon = nil
		else
			TabConfig = self:MakeConfig({Name = "Tab", Icon = ""}, TabConfig)
			TabName = TabConfig.Name
			TabIcon = TabConfig.Icon
		end

		local TabButton = Instance.new("Frame")
		TabButton.BackgroundTransparency = 1
		TabButton.Size = UDim2.new(1,0,0,30)
		TabButton.Parent = ScrollingTab
		Instance.new("UICorner", TabButton).CornerRadius = UDim.new(0,6)

		local IconLabel = nil
		if TabIcon and TabIcon ~= "" then
			IconLabel = Instance.new("ImageLabel")
			IconLabel.BackgroundTransparency = 1
			IconLabel.Size = UDim2.new(0,20,0,20)
			IconLabel.Position = UDim2.new(0,5,0,5)
			IconLabel.Image = TabIcon
			IconLabel.Parent = TabButton
		end

		local NameTab = Instance.new("TextLabel")
		NameTab.Name = "NameTab"
		NameTab.BackgroundTransparency = 1
		NameTab.Position = IconLabel and UDim2.new(0,30,0,0) or UDim2.new(0,10,0,0)
		NameTab.Size = UDim2.new(1, IconLabel and -40 or -20, 1, 0)
		NameTab.Font = Enum.Font.GothamBold
		NameTab.Text = TabName
		NameTab.TextColor3 = Color3.fromRGB(255,255,255)
		NameTab.TextSize = 12
		NameTab.TextTransparency = 0.5
		NameTab.TextXAlignment = Enum.TextXAlignment.Left
		NameTab.Parent = TabButton

		local ClickTab = Instance.new("TextButton")
		ClickTab.BackgroundTransparency = 1
		ClickTab.Size = UDim2.new(1,0,1,0)
		ClickTab.Text = ""
		ClickTab.Parent = TabButton

		local ContentScroll = Instance.new("ScrollingFrame")
		ContentScroll.BackgroundTransparency = 1
		ContentScroll.Selectable = false
		ContentScroll.Size = UDim2.new(1,0,1,0)
		ContentScroll.CanvasSize = UDim2.new(0,0,0,0)
		ContentScroll.ScrollBarThickness = 0
		ContentScroll.Visible = false
		ContentScroll.Parent = TabContentContainer

		local UIListLayout_3 = Instance.new("UIListLayout")
		UIListLayout_3.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout_3.Padding = UDim.new(0,8)
		UIListLayout_3.Parent = ContentScroll

		local UIPadding_3 = Instance.new("UIPadding")
		UIPadding_3.PaddingLeft = UDim.new(0,10)
		UIPadding_3.PaddingRight = UDim.new(0,10)
		UIPadding_3.PaddingTop = UDim.new(0,5)
		UIPadding_3.PaddingBottom = UDim.new(0,15)
		UIPadding_3.Parent = ContentScroll

		Library:UpdateScrolling(ContentScroll, UIListLayout_3)
		TabContents[TabButton] = ContentScroll

		if #TabContents == 1 then
			SwitchTab(TabButton)
		end

		ClickTab.Activated:Connect(function()
			SwitchTab(TabButton)
		end)

		-- Objeto de métodos da aba
		local TabMethods = {}

		function TabMethods:AddSeparator(Text)
			local Sep = Instance.new("TextLabel")
			Sep.BackgroundTransparency = 1
			Sep.Size = UDim2.new(1,0,0,28)
			Sep.Font = Enum.Font.GothamBlack
			Sep.Text = Text
			Sep.TextColor3 = Color3.fromRGB(255,255,255)   -- branco puro
			Sep.TextSize = 16
			Sep.TextXAlignment = Enum.TextXAlignment.Left
			Sep.Parent = ContentScroll
		end

		local function AddStrokeTo(parent)
			local s = Instance.new("UIStroke")
			s.Color = ThemeColor
			s.Thickness = 1.5
			s.Transparency = 0.8
			s.Parent = parent
			return s
		end

		-- ===== Elementos =====
		function TabMethods:AddToggle(Config)
			Config = Library:MakeConfig({
				Title = "Toggle", Description = "", Default = false,
				Flag = nil, Callback = function() end
			}, Config or {})
			local Toggle = Instance.new("Frame")
			Toggle.BackgroundColor3 = Color3.new(1,1,1)
			Toggle.BackgroundTransparency = 0.95
			Toggle.BorderSizePixel = 0
			Toggle.Size = UDim2.new(1,0,0,45)
			Toggle.Parent = ContentScroll
			Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0,4)
			AddStrokeTo(Toggle)

			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Position = UDim2.new(0,10,0,5)
			TitleLabel.Size = UDim2.new(1,-60,0,16)
			TitleLabel.Font = Enum.Font.GothamBold
			TitleLabel.Text = Config.Title
			TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
			TitleLabel.TextSize = 13
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.Parent = Toggle

			local Content = Instance.new("TextLabel")
			Content.BackgroundTransparency = 1
			Content.Position = UDim2.new(0,10,0,24)
			Content.Size = UDim2.new(1,-60,0,14)
			Content.Font = Enum.Font.Gotham
			Content.Text = Config.Description
			Content.TextColor3 = Color3.fromRGB(150,150,150)
			Content.TextSize = 12
			Content.TextXAlignment = Enum.TextXAlignment.Left
			Content.Parent = Toggle

			local ToggleCheck = Instance.new("Frame")
			ToggleCheck.AnchorPoint = Vector2.new(0,0.5)
			ToggleCheck.BackgroundColor3 = Color3.fromRGB(60,60,60)
			ToggleCheck.BorderSizePixel = 0
			ToggleCheck.Position = UDim2.new(1,-50,0.5,0)
			ToggleCheck.Size = UDim2.new(0,40,0,22)
			ToggleCheck.Parent = Toggle
			Instance.new("UICorner", ToggleCheck).CornerRadius = UDim.new(1,0)

			local Check = Instance.new("Frame")
			Check.AnchorPoint = Vector2.new(0,0.5)
			Check.BackgroundColor3 = Color3.fromRGB(200,200,200)
			Check.BorderSizePixel = 0
			Check.Position = UDim2.new(0,3,0.5,0)
			Check.Size = UDim2.new(0,16,0,16)
			Check.Parent = ToggleCheck
			Instance.new("UICorner", Check).CornerRadius = UDim.new(1,0)

			local ToggleClick = Instance.new("TextButton")
			ToggleClick.BackgroundTransparency = 1
			ToggleClick.Size = UDim2.new(1,0,1,0)
			ToggleClick.Text = ""
			ToggleClick.Parent = Toggle

			local ToggleFunc = { Value = Config.Default }
			function ToggleFunc:Set(Boolean, NoCallback)
				self.Value = Boolean
				if Boolean then
					Library:TweenInstance(ToggleCheck, 0.3, "BackgroundColor3", ThemeColor)
					Library:TweenInstance(Check, 0.3, "Position", UDim2.new(0,22,0.5,0))
					Library:TweenInstance(Check, 0.3, "BackgroundColor3", Color3.fromRGB(255,255,255))
				else
					Library:TweenInstance(ToggleCheck, 0.3, "BackgroundColor3", Color3.fromRGB(60,60,60))
					Library:TweenInstance(Check, 0.3, "Position", UDim2.new(0,3,0.5,0))
					Library:TweenInstance(Check, 0.3, "BackgroundColor3", Color3.fromRGB(200,200,200))
				end
				if not NoCallback then pcall(Config.Callback, Boolean) end
				if Config.Flag then Library.Flags[Config.Flag] = self; Library:SaveSettings() end
			end
			function ToggleFunc:Get() return self.Value end
			ToggleClick.Activated:Connect(function() ToggleFunc:Set(not ToggleFunc.Value) end)
			ToggleFunc:Set(ToggleFunc.Value, true)
			return ToggleFunc
		end

		function TabMethods:AddButton(Config)
			Config = Library:MakeConfig({
				Title = "Button", Description = "", Callback = function() end
			}, Config or {})
			local Button = Instance.new("Frame")
			Button.BackgroundColor3 = Color3.new(1,1,1)
			Button.BackgroundTransparency = 0.95
			Button.BorderSizePixel = 0
			Button.Size = UDim2.new(1,0,0,45)
			Button.Parent = ContentScroll
			Instance.new("UICorner", Button).CornerRadius = UDim.new(0,4)
			AddStrokeTo(Button)

			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Position = UDim2.new(0,10,0,5)
			TitleLabel.Size = UDim2.new(1,-60,0,16)
			TitleLabel.Font = Enum.Font.GothamBold
			TitleLabel.Text = Config.Title
			TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
			TitleLabel.TextSize = 13
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.Parent = Button

			local Content = Instance.new("TextLabel")
			Content.BackgroundTransparency = 1
			Content.Position = UDim2.new(0,10,0,24)
			Content.Size = UDim2.new(1,-60,0,14)
			Content.Font = Enum.Font.Gotham
			Content.Text = Config.Description
			Content.TextColor3 = Color3.fromRGB(150,150,150)
			Content.TextSize = 12
			Content.Parent = Button

			local IconImg = Instance.new("ImageLabel")
			IconImg.AnchorPoint = Vector2.new(0,0.5)
			IconImg.BackgroundTransparency = 1
			IconImg.Position = UDim2.new(1,-35,0.5,0)
			IconImg.Size = UDim2.new(0,24,0,24)
			IconImg.Image = "rbxassetid://85905776508942"
			IconImg.Parent = Button

			local BtnClick = Instance.new("TextButton")
			BtnClick.BackgroundTransparency = 1
			BtnClick.Size = UDim2.new(1,0,1,0)
			BtnClick.Text = ""
			BtnClick.Parent = Button
			BtnClick.Activated:Connect(function() pcall(Config.Callback) end)
		end

		function TabMethods:AddSlider(Config)
			Config = Library:MakeConfig({
				Title = "Slider", Description = "", Min = 1, Max = 100,
				Increment = 1, Default = 50, Flag = nil, Callback = function() end
			}, Config or {})
			local Slider = Instance.new("Frame")
			Slider.BackgroundColor3 = Color3.new(1,1,1)
			Slider.BackgroundTransparency = 0.95
			Slider.BorderSizePixel = 0
			Slider.Size = UDim2.new(1,0,0,55)
			Slider.Parent = ContentScroll
			Instance.new("UICorner", Slider).CornerRadius = UDim.new(0,4)
			AddStrokeTo(Slider)

			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Position = UDim2.new(0,10,0,5)
			TitleLabel.Size = UDim2.new(1,-180,0,16)
			TitleLabel.Font = Enum.Font.GothamBold
			TitleLabel.Text = Config.Title
			TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
			TitleLabel.TextSize = 13
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.Parent = Slider

			local Content = Instance.new("TextLabel")
			Content.BackgroundTransparency = 1
			Content.Position = UDim2.new(0,10,0,24)
			Content.Size = UDim2.new(1,-180,0,14)
			Content.Font = Enum.Font.Gotham
			Content.Text = Config.Description
			Content.TextColor3 = Color3.fromRGB(150,150,150)
			Content.TextSize = 12
			Content.Parent = Slider

			local SliderValueBox = Instance.new("TextBox")
			SliderValueBox.AnchorPoint = Vector2.new(0,0.5)
			SliderValueBox.BackgroundColor3 = ThemeColor
			SliderValueBox.BorderSizePixel = 0
			SliderValueBox.Position = UDim2.new(1,-185,0.5,0)
			SliderValueBox.Size = UDim2.new(0,35,0,20)
			SliderValueBox.Font = Enum.Font.GothamBold
			SliderValueBox.Text = tostring(Config.Default)
			SliderValueBox.TextColor3 = Color3.fromRGB(255,255,255)
			SliderValueBox.TextSize = 11
			SliderValueBox.Parent = Slider
			Instance.new("UICorner", SliderValueBox).CornerRadius = UDim.new(0,2)

			local SliderFrame = Instance.new("Frame")
			SliderFrame.AnchorPoint = Vector2.new(0,0.5)
			SliderFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
			SliderFrame.BorderSizePixel = 0
			SliderFrame.Position = UDim2.new(1,-140,0.5,0)
			SliderFrame.Size = UDim2.new(0,130,0,8)
			SliderFrame.Parent = Slider
			Instance.new("UICorner", SliderFrame).CornerRadius = UDim.new(1,0)

			local SliderDraggable = Instance.new("Frame")
			SliderDraggable.BackgroundColor3 = ThemeColor
			SliderDraggable.BorderSizePixel = 0
			SliderDraggable.Size = UDim2.new(0,20,1,0)
			SliderDraggable.Parent = SliderFrame
			Instance.new("UICorner", SliderDraggable).CornerRadius = UDim.new(1,0)

			local Circle = Instance.new("Frame")
			Circle.AnchorPoint = Vector2.new(0.5,0.5)
			Circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
			Circle.BorderSizePixel = 0
			Circle.Position = UDim2.new(1,0,0.5,0)
			Circle.Size = UDim2.new(0,12,0,12)
			Circle.Parent = SliderDraggable
			Instance.new("UICorner", Circle).CornerRadius = UDim.new(1,0)

			local SliderFunc = { Value = Config.Default }
			local Dragging = false
			local function Round(Number, Factor)
				local Result = math.floor(Number / Factor + 0.5) * Factor
				if Result < 0 then Result = Result + Factor end
				return Result
			end
			function SliderFunc:Set(Value, NoCallback)
				Value = math.clamp(Round(Value, Config.Increment), Config.Min, Config.Max)
				self.Value = Value
				SliderValueBox.Text = tostring(Value)
				local Scale = (Value - Config.Min) / (Config.Max - Config.Min)
				Library:TweenInstance(SliderDraggable, 0.3, "Size", UDim2.new(Scale, 0, 1, 0))
				if not NoCallback then pcall(Config.Callback, Value) end
				if Config.Flag then Library.Flags[Config.Flag] = { Value = Value, Set = function(v) SliderFunc:Set(v) end, Get = function() return self.Value end }; Library:SaveSettings() end
			end
			function SliderFunc:Get() return self.Value end
			SliderFrame.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = true end
			end)
			SliderFrame.InputEnded:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = false end
			end)
			UserInputService.InputChanged:Connect(function(Input)
				if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
					local Scale = math.clamp((Input.Position.X - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
					SliderFunc:Set(Config.Min + (Config.Max - Config.Min) * Scale)
				end
			end)
			SliderValueBox.FocusLost:Connect(function()
				local Num = tonumber(SliderValueBox.Text) or Config.Min
				SliderFunc:Set(Num)
			end)
			SliderFunc:Set(Config.Default, true)
			return SliderFunc
		end

		function TabMethods:AddDropdown(Config)
			Config = Library:MakeConfig({
				Title = "Dropdown", Description = "", Values = {}, Multi = false,
				Default = nil, Flag = nil, Callback = function() end
			}, Config or {})
			local Dropdown = Instance.new("Frame")
			Dropdown.BackgroundColor3 = Color3.new(1,1,1)
			Dropdown.BackgroundTransparency = 0.95
			Dropdown.BorderSizePixel = 0
			Dropdown.Size = UDim2.new(1,0,0,45)
			Dropdown.Parent = ContentScroll
			Instance.new("UICorner", Dropdown).CornerRadius = UDim.new(0,4)
			AddStrokeTo(Dropdown)

			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Position = UDim2.new(0,10,0,5)
			TitleLabel.Size = UDim2.new(1,-60,0,16)
			TitleLabel.Font = Enum.Font.GothamBold
			TitleLabel.Text = Config.Title
			TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
			TitleLabel.TextSize = 13
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.Parent = Dropdown

			local Content = Instance.new("TextLabel")
			Content.BackgroundTransparency = 1
			Content.Position = UDim2.new(0,10,0,24)
			Content.Size = UDim2.new(1,-60,0,14)
			Content.Font = Enum.Font.Gotham
			Content.Text = Config.Description
			Content.TextColor3 = Color3.fromRGB(150,150,150)
			Content.TextSize = 12
			Content.Parent = Dropdown

			local Selects = Instance.new("Frame")
			Selects.AnchorPoint = Vector2.new(0,0.5)
			Selects.BackgroundColor3 = Color3.fromRGB(20,20,20)
			Selects.BorderSizePixel = 0
			Selects.Position = UDim2.new(1,-90,0.5,0)
			Selects.Size = UDim2.new(0,80,0,25)
			Selects.Parent = Dropdown
			Instance.new("UICorner", Selects).CornerRadius = UDim.new(0,5)

			local SelectText = Instance.new("TextLabel")
			SelectText.BackgroundTransparency = 1
			SelectText.Position = UDim2.new(0,3,0,0)
			SelectText.Size = UDim2.new(1,-25,1,0)
			SelectText.Font = Enum.Font.GothamBold
			SelectText.Text = ""
			SelectText.TextColor3 = Color3.fromRGB(255,255,255)
			SelectText.TextScaled = true
			SelectText.TextSize = 1
			SelectText.Parent = Selects

			local DropClick = Instance.new("TextButton")
			DropClick.BackgroundTransparency = 1
			DropClick.Size = UDim2.new(1,0,1,0)
			DropClick.Text = ""
			DropClick.Parent = Selects

			local Arrow = Instance.new("ImageLabel")
			Arrow.AnchorPoint = Vector2.new(0,0.5)
			Arrow.BackgroundTransparency = 1
			Arrow.Position = UDim2.new(1,-20,0.5,0)
			Arrow.Size = UDim2.new(0,15,0,15)
			Arrow.Image = "rbxassetid://80845745785361"
			Arrow.Parent = Selects

			local DropdownList = Instance.new("Frame")
			DropdownList.BackgroundColor3 = Color3.fromRGB(18,18,18)
			DropdownList.BorderSizePixel = 0
			DropdownList.Size = UDim2.new(0,400,0,250)
			DropdownList.Position = UDim2.new(0.5,0,0.5,0)
			DropdownList.AnchorPoint = Vector2.new(0.5,0.5)
			DropdownList.Visible = false
			DropdownList.Parent = DropdownZone
			Instance.new("UICorner", DropdownList).CornerRadius = UDim.new(0,5)
			Instance.new("UIStroke", DropdownList).Color = ThemeColor

			local Topbar = Instance.new("Frame")
			Topbar.BackgroundTransparency = 1
			Topbar.Size = UDim2.new(1,0,0,50)
			Topbar.Parent = DropdownList
			local Title_10 = Instance.new("TextLabel")
			Title_10.BackgroundTransparency = 1
			Title_10.Position = UDim2.new(0,15,0,0)
			Title_10.Size = UDim2.new(1,-200,1,-5)
			Title_10.Font = Enum.Font.GothamBold
			Title_10.Text = Config.Title
			Title_10.TextColor3 = Color3.fromRGB(255,255,255)
			Title_10.TextSize = 14
			Title_10.TextXAlignment = Enum.TextXAlignment.Left
			Title_10.Parent = Topbar

			local SearchFrame2 = Instance.new("Frame")
			SearchFrame2.BackgroundColor3 = Color3.fromRGB(15,15,15)
			SearchFrame2.BorderSizePixel = 0
			SearchFrame2.Position = UDim2.new(1,-150,0,8)
			SearchFrame2.Size = UDim2.new(0,100,0,30)
			SearchFrame2.Parent = Topbar
			Instance.new("UICorner", SearchFrame2).CornerRadius = UDim.new(0,5)
			Instance.new("UIStroke", SearchFrame2).Color = ThemeColor
			local IconSearch2 = Instance.new("ImageLabel")
			IconSearch2.AnchorPoint = Vector2.new(0,0.5)
			IconSearch2.BackgroundTransparency = 1
			IconSearch2.Position = UDim2.new(0,10,0.5,0)
			IconSearch2.Size = UDim2.new(0,15,0,15)
			IconSearch2.Image = "rbxassetid://71309835376233"
			IconSearch2.Parent = SearchFrame2
			local SearchInput = Instance.new("TextBox")
			SearchInput.BackgroundTransparency = 1
			SearchInput.Position = UDim2.new(0,35,0,0)
			SearchInput.Size = UDim2.new(1,-35,1,0)
			SearchInput.Font = Enum.Font.GothamBold
			SearchInput.PlaceholderText = "Search..."
			SearchInput.Text = ""
			SearchInput.TextColor3 = Color3.fromRGB(255,255,255)
			SearchInput.TextSize = 12
			SearchInput.TextXAlignment = Enum.TextXAlignment.Left
			SearchInput.Parent = SearchFrame2

			local CloseDropdown = Instance.new("TextButton")
			CloseDropdown.BackgroundTransparency = 1
			CloseDropdown.Position = UDim2.new(1,-40,0,8)
			CloseDropdown.Size = UDim2.new(0,30,0,30)
			CloseDropdown.Text = ""
			CloseDropdown.Parent = Topbar
			local CloseIcon = Instance.new("ImageLabel")
			CloseIcon.AnchorPoint = Vector2.new(0.5,0.5)
			CloseIcon.BackgroundTransparency = 1
			CloseIcon.Position = UDim2.new(0.5,0,0.5,0)
			CloseIcon.Size = UDim2.new(0,20,0,20)
			CloseIcon.Image = "rbxassetid://105957381820378"
			CloseIcon.ImageRectOffset = Vector2.new(480,0)
			CloseIcon.ImageRectSize = Vector2.new(96,96)
			CloseIcon.Parent = CloseDropdown

			local RealList = Instance.new("ScrollingFrame")
			RealList.BackgroundColor3 = Color3.fromRGB(12,12,12)
			RealList.BorderSizePixel = 0
			RealList.Position = UDim2.new(0,10,0,50)
			RealList.Selectable = false
			RealList.ScrollBarThickness = 0
			RealList.Size = UDim2.new(1,-20,1,-60)
			RealList.Parent = DropdownList
			Instance.new("UICorner", RealList).CornerRadius = UDim.new(0,5)

			local UIListLayout_5 = Instance.new("UIListLayout")
			UIListLayout_5.SortOrder = Enum.SortOrder.LayoutOrder
			UIListLayout_5.Padding = UDim.new(0,5)
			UIListLayout_5.Parent = RealList

			local UIPadding_5 = Instance.new("UIPadding")
			UIPadding_5.PaddingBottom = UDim.new(0,7)
			UIPadding_5.PaddingLeft = UDim.new(0,7)
			UIPadding_5.PaddingRight = UDim.new(0,7)
			UIPadding_5.PaddingTop = UDim.new(0,7)
			UIPadding_5.Parent = RealList

			Library:UpdateScrolling(RealList, UIListLayout_5)

			SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
				local Query = SearchInput.Text:lower()
				for _, Option in ipairs(RealList:GetChildren()) do
					if Option:IsA("Frame") then
						local OptText = Option:FindFirstChild("Title")
						if OptText then
							Option.Visible = OptText.Text:lower():find(Query) ~= nil or Query == ""
						end
					end
				end
			end)

			local SelectedValues
			if Config.Multi then
				SelectedValues = Config.Default or {}
			else
				SelectedValues = Config.Default and {Config.Default} or {}
			end
			local DropFunc = { Value = Config.Multi and SelectedValues or (SelectedValues[1] or "") }

			function DropFunc:Refresh(List)
				for _, v in ipairs(RealList:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
				for _, ItemName in ipairs(List) do
					local Option = Instance.new("Frame")
					Option.BackgroundColor3 = Color3.new(1,1,1)
					Option.BackgroundTransparency = 0.98
					Option.BorderSizePixel = 0
					Option.Size = UDim2.new(1,0,0,35)
					Option.Parent = RealList
					Instance.new("UICorner", Option).CornerRadius = UDim.new(0,4)
					local OptText = Instance.new("TextLabel")
					OptText.Name = "Title"
					OptText.BackgroundTransparency = 1
					OptText.Size = UDim2.new(1,0,1,0)
					OptText.Font = Enum.Font.GothamBold
					OptText.Text = ItemName
					OptText.TextColor3 = Color3.fromRGB(255,255,255)
					OptText.TextSize = 13
					OptText.TextTransparency = 0.5
					OptText.Parent = Option
					local OptClick = Instance.new("TextButton")
					OptClick.BackgroundTransparency = 1
					OptClick.Size = UDim2.new(1,0,1,0)
					OptClick.Text = ""
					OptClick.Parent = Option
					Library:MouseEvent(OptClick,
						function() Option.BackgroundTransparency = 0.95 end,
						function() Option.BackgroundTransparency = 0.98 end)
					OptClick.Activated:Connect(function()
						if Config.Multi then
							local Idx = table.find(SelectedValues, ItemName)
							if Idx then table.remove(SelectedValues, Idx) else table.insert(SelectedValues, ItemName) end
						else
							SelectedValues = {ItemName}
						end
						DropFunc:Set(SelectedValues)
					end)
				end
				DropFunc:Set(SelectedValues, true)
			end

			function DropFunc:Set(Values, NoCallback)
				Values = Values or {}
				if not Config.Multi then Values = (type(Values) == "table") and Values or {Values} end
				SelectedValues = Values
				self.Value = Config.Multi and SelectedValues or table.concat(SelectedValues, ", ")
				local Text = Config.Multi and table.concat(SelectedValues, ", ") or (SelectedValues[1] or "")
				SelectText.Text = Text == "" and "..." or Text
				for _, Option in ipairs(RealList:GetChildren()) do
					if Option:IsA("Frame") then
						local OptText = Option:FindFirstChild("Title")
						if OptText then
							if table.find(SelectedValues, OptText.Text) then
								Library:TweenInstance(Option, 0.3, "BackgroundTransparency", 0)
								Library:TweenInstance(OptText, 0.3, "TextTransparency", 0)
							else
								Library:TweenInstance(Option, 0.3, "BackgroundTransparency", 0.98)
								Library:TweenInstance(OptText, 0.3, "TextTransparency", 0.5)
							end
						end
					end
				end
				if not NoCallback then pcall(Config.Callback, self.Value) end
				if Config.Flag then Library.Flags[Config.Flag] = { Value = self.Value, Set = function(v) DropFunc:Set(v) end, Get = function() return self.Value end }; Library:SaveSettings() end
			end
			function DropFunc:Get() return self.Value end

			DropClick.Activated:Connect(function()
				for _, child in ipairs(DropdownZone:GetChildren()) do
					if child:IsA("Frame") and child ~= DropdownList then child.Visible = false end
				end
				if DropdownList.Visible then
					DropdownList.Visible = false
					Library:TweenInstance(DropdownZone, 0.3, "BackgroundTransparency", 1)
					task.wait(0.3)
					DropdownZone.Visible = false
				else
					DropdownZone.Visible = true
					DropdownList.Visible = true
					Library:TweenInstance(DropdownZone, 0.3, "BackgroundTransparency", 0.3)
				end
			end)
			CloseDropdown.Activated:Connect(function()
				DropdownList.Visible = false
				Library:TweenInstance(DropdownZone, 0.3, "BackgroundTransparency", 1)
				task.wait(0.3)
				DropdownZone.Visible = false
			end)

			DropFunc:Refresh(Config.Values)
			return DropFunc
		end

		function TabMethods:AddInput(Config)
			Config = Library:MakeConfig({
				Title = "Input", Description = "", PlaceHolder = "",
				Default = "", Flag = nil, Callback = function() end
			}, Config or {})
			local Input = Instance.new("Frame")
			Input.BackgroundColor3 = Color3.new(1,1,1)
			Input.BackgroundTransparency = 0.95
			Input.BorderSizePixel = 0
			Input.Size = UDim2.new(1,0,0,45)
			Input.Parent = ContentScroll
			Instance.new("UICorner", Input).CornerRadius = UDim.new(0,4)
			AddStrokeTo(Input)

			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Position = UDim2.new(0,10,0,5)
			TitleLabel.Size = UDim2.new(1,-60,0,16)
			TitleLabel.Font = Enum.Font.GothamBold
			TitleLabel.Text = Config.Title
			TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
			TitleLabel.TextSize = 13
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.Parent = Input

			local Content = Instance.new("TextLabel")
			Content.BackgroundTransparency = 1
			Content.Position = UDim2.new(0,10,0,24)
			Content.Size = UDim2.new(1,-160,0,14)
			Content.Font = Enum.Font.Gotham
			Content.Text = Config.Description
			Content.TextColor3 = Color3.fromRGB(150,150,150)
			Content.TextSize = 12
			Content.Parent = Input

			local TextboxFrame = Instance.new("Frame")
			TextboxFrame.AnchorPoint = Vector2.new(0,0.5)
			TextboxFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
			TextboxFrame.BorderSizePixel = 0
			TextboxFrame.Position = UDim2.new(1,-140,0.5,0)
			TextboxFrame.Size = UDim2.new(0,130,0,28)
			TextboxFrame.Parent = Input
			Instance.new("UICorner", TextboxFrame).CornerRadius = UDim.new(0,3)

			local WritingIcon = Instance.new("ImageLabel")
			WritingIcon.AnchorPoint = Vector2.new(0,0.5)
			WritingIcon.BackgroundTransparency = 1
			WritingIcon.Position = UDim2.new(0,10,0.5,0)
			WritingIcon.Size = UDim2.new(0,15,0,15)
			WritingIcon.Image = "rbxassetid://126409600467363"
			WritingIcon.Parent = TextboxFrame

			local RealTextBox = Instance.new("TextBox")
			RealTextBox.BackgroundTransparency = 1
			RealTextBox.Position = UDim2.new(0,35,0,0)
			RealTextBox.Size = UDim2.new(1,-35,1,0)
			RealTextBox.Font = Enum.Font.GothamBold
			RealTextBox.PlaceholderText = Config.PlaceHolder
			RealTextBox.Text = Config.Default
			RealTextBox.TextColor3 = Color3.fromRGB(255,255,255)
			RealTextBox.TextSize = 12
			RealTextBox.TextXAlignment = Enum.TextXAlignment.Left
			RealTextBox.Parent = TextboxFrame

			local InputFunc = { Value = Config.Default }
			RealTextBox.FocusLost:Connect(function()
				InputFunc.Value = RealTextBox.Text
				if Config.Flag then
					Library.Flags[Config.Flag] = { Value = RealTextBox.Text, Set = function(v) InputFunc:Set(v) end, Get = function() return RealTextBox.Text end }
					Library:SaveSettings()
				end
				pcall(Config.Callback, RealTextBox.Text)
			end)
			function InputFunc:Set(Value) RealTextBox.Text = Value; self.Value = Value end
			function InputFunc:Get() return RealTextBox.Text end
			return InputFunc
		end

		function TabMethods:AddKeybind(Config)
			Config = Library:MakeConfig({
				Title = "Keybind", Description = "", Default = Enum.KeyCode.LeftControl,
				Flag = nil, Callback = function() end
			}, Config or {})
			local Keybind = Instance.new("Frame")
			Keybind.BackgroundColor3 = Color3.new(1,1,1)
			Keybind.BackgroundTransparency = 0.95
			Keybind.BorderSizePixel = 0
			Keybind.Size = UDim2.new(1,0,0,45)
			Keybind.Parent = ContentScroll
			Instance.new("UICorner", Keybind).CornerRadius = UDim.new(0,4)
			AddStrokeTo(Keybind)

			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Position = UDim2.new(0,10,0,5)
			TitleLabel.Size = UDim2.new(1,-60,0,16)
			TitleLabel.Font = Enum.Font.GothamBold
			TitleLabel.Text = Config.Title
			TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
			TitleLabel.TextSize = 13
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.Parent = Keybind

			local KeyDisplay = Instance.new("TextButton")
			KeyDisplay.AnchorPoint = Vector2.new(0,0.5)
			KeyDisplay.BackgroundColor3 = Color3.fromRGB(25,25,25)
			KeyDisplay.BorderSizePixel = 0
			KeyDisplay.Position = UDim2.new(1,-100,0.5,0)
			KeyDisplay.Size = UDim2.new(0,90,0,25)
			KeyDisplay.Font = Enum.Font.GothamBold
			KeyDisplay.Text = Config.Default.Name
			KeyDisplay.TextColor3 = Color3.fromRGB(255,255,255)
			KeyDisplay.TextSize = 12
			KeyDisplay.Parent = Keybind
			Instance.new("UICorner", KeyDisplay).CornerRadius = UDim.new(0,3)

			local CurrentKey = Config.Default
			local Listening = false
			local KeybindFunc = {}
			local function StartListening()
				Listening = true
				KeyDisplay.Text = "..."
			end
			local function StopListening()
				Listening = false
				KeyDisplay.Text = CurrentKey.Name
			end
			KeyDisplay.Activated:Connect(StartListening)
			local InputConn
			InputConn = UserInputService.InputBegan:Connect(function(Input, GameProcessed)
				if Listening and not GameProcessed then
					if Input.UserInputType == Enum.UserInputType.Keyboard then
						CurrentKey = Input.KeyCode
						StopListening()
						pcall(Config.Callback, CurrentKey)
						if Config.Flag then Library.Flags[Config.Flag] = { Value = CurrentKey, Set = function(v) CurrentKey = v; KeyDisplay.Text = v.Name end, Get = function() return CurrentKey end }; Library:SaveSettings() end
					end
				end
			end)
			function KeybindFunc:Set(Key) CurrentKey = Key; KeyDisplay.Text = Key.Name end
			function KeybindFunc:Get() return CurrentKey end
			return KeybindFunc
		end

		function TabMethods:AddParagraph(Config)
			Config = Library:MakeConfig({
				Title = "Paragraph", Content = ""
			}, Config or {})
			local Paragraph = Instance.new("Frame")
			Paragraph.BackgroundColor3 = Color3.new(1,1,1)
			Paragraph.BackgroundTransparency = 0.95
			Paragraph.BorderSizePixel = 0
			Paragraph.Size = UDim2.new(1,0,0,45)
			Paragraph.Parent = ContentScroll
			Instance.new("UICorner", Paragraph).CornerRadius = UDim.new(0,4)
			AddStrokeTo(Paragraph)

			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Position = UDim2.new(0,10,0,5)
			TitleLabel.Size = UDim2.new(1,-60,0,16)
			TitleLabel.Font = Enum.Font.GothamBold
			TitleLabel.Text = Config.Title
			TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
			TitleLabel.TextSize = 13
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.Parent = Paragraph

			local Content = Instance.new("TextLabel")
			Content.BackgroundTransparency = 1
			Content.Position = UDim2.new(0,10,0,24)
			Content.Size = UDim2.new(1,-10,0,14)
			Content.Font = Enum.Font.Gotham
			Content.Text = Config.Content
			Content.TextColor3 = Color3.fromRGB(150,150,150)
			Content.TextSize = 12
			Content.TextXAlignment = Enum.TextXAlignment.Left
			Content.Parent = Paragraph

			return {
				SetTitle = function(t) TitleLabel.Text = t end,
				SetContent = function(c) Content.Text = c end
			}
		end

		-- ColorPicker compacto com modal
		function TabMethods:AddColorPicker(Config)
			Config = Library:MakeConfig({
				Title = "Color Picker", Description = "", Default = Color3.fromRGB(255,255,255),
				Flag = nil, Callback = function() end
			}, Config or {})
			local ColorFrame = Instance.new("Frame")
			ColorFrame.BackgroundColor3 = Color3.new(1,1,1)
			ColorFrame.BackgroundTransparency = 0.95
			ColorFrame.BorderSizePixel = 0
			ColorFrame.Size = UDim2.new(1,0,0,45)
			ColorFrame.Parent = ContentScroll
			Instance.new("UICorner", ColorFrame).CornerRadius = UDim.new(0,4)
			AddStrokeTo(ColorFrame)

			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Position = UDim2.new(0,10,0,5)
			TitleLabel.Size = UDim2.new(1,-60,0,16)
			TitleLabel.Font = Enum.Font.GothamBold
			TitleLabel.Text = Config.Title
			TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
			TitleLabel.TextSize = 13
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.Parent = ColorFrame

			local Preview = Instance.new("Frame")
			Preview.AnchorPoint = Vector2.new(0,0.5)
			Preview.BorderSizePixel = 0
			Preview.BackgroundColor3 = Config.Default
			Preview.Position = UDim2.new(1,-50,0.5,0)
			Preview.Size = UDim2.new(0,30,0,30)
			Preview.Parent = ColorFrame
			Instance.new("UICorner", Preview).CornerRadius = UDim.new(0,4)
			local PreviewStroke = Instance.new("UIStroke")
			PreviewStroke.Color = ThemeColor
			PreviewStroke.Thickness = 1.5
			PreviewStroke.Transparency = 0.5
			PreviewStroke.Parent = Preview

			local OpenColorBtn = Instance.new("TextButton")
			OpenColorBtn.BackgroundTransparency = 1
			OpenColorBtn.Size = UDim2.new(1,0,1,0)
			OpenColorBtn.Text = ""
			OpenColorBtn.Parent = ColorFrame

			-- Modal de color picker
			local ColorModal = Instance.new("Frame")
			ColorModal.BackgroundColor3 = Color3.fromRGB(15,15,15)
			ColorModal.BorderSizePixel = 0
			ColorModal.Size = UDim2.new(0,250,0,180)
			ColorModal.Position = UDim2.new(0.5,0,0.5,0)
			ColorModal.AnchorPoint = Vector2.new(0.5,0.5)
			ColorModal.Visible = false
			ColorModal.Parent = DropdownZone
			Instance.new("UICorner", ColorModal).CornerRadius = UDim.new(0,6)
			Instance.new("UIStroke", ColorModal).Color = ThemeColor

			local ModalTitle = Instance.new("TextLabel")
			ModalTitle.BackgroundTransparency = 1
			ModalTitle.Size = UDim2.new(1,-20,0,30)
			ModalTitle.Position = UDim2.new(0,10,0,5)
			ModalTitle.Font = Enum.Font.GothamBold
			ModalTitle.Text = Config.Title or "Color Picker"
			ModalTitle.TextColor3 = Color3.fromRGB(255,255,255)
			ModalTitle.TextSize = 14
			ModalTitle.TextXAlignment = Enum.TextXAlignment.Left
			ModalTitle.Parent = ColorModal

			local CloseModal = Instance.new("TextButton")
			CloseModal.BackgroundTransparency = 1
			CloseModal.Position = UDim2.new(1,-30,0,5)
			CloseModal.Size = UDim2.new(0,25,0,25)
			CloseModal.Text = "✕"
			CloseModal.TextColor3 = Color3.fromRGB(255,255,255)
			CloseModal.TextSize = 16
			CloseModal.Parent = ColorModal

			-- Sliders RGB no modal
			local currentColor = {R = Config.Default.R*255, G = Config.Default.G*255, B = Config.Default.B*255}
			local function updatePreview()
				Preview.BackgroundColor3 = Color3.fromRGB(currentColor.R, currentColor.G, currentColor.B)
			end

			local function makeSlider(letter, y)
				local label = Instance.new("TextLabel")
				label.BackgroundTransparency = 1
				label.Position = UDim2.new(0,15,0,y)
				label.Size = UDim2.new(0,20,0,20)
				label.Font = Enum.Font.GothamBold
				label.Text = letter
				label.TextColor3 = Color3.fromRGB(255,255,255)
				label.TextSize = 12
				label.Parent = ColorModal

				local bar = Instance.new("Frame")
				bar.BackgroundColor3 = Color3.fromRGB(40,40,40)
				bar.BorderSizePixel = 0
				bar.Position = UDim2.new(0,40,0,y+2)
				bar.Size = UDim2.new(1,-100,0,6)
				bar.Parent = ColorModal
				Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)

				local fill = Instance.new("Frame")
				fill.BackgroundColor3 = ThemeColor
				fill.BorderSizePixel = 0
				fill.Size = UDim2.new(0.5,0,1,0)
				fill.Parent = bar
				Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

				local valBox = Instance.new("TextBox")
				valBox.AnchorPoint = Vector2.new(0,0.5)
				valBox.BackgroundColor3 = Color3.fromRGB(25,25,25)
				valBox.BorderSizePixel = 0
				valBox.Position = UDim2.new(1,-45,0.5,y)
				valBox.Size = UDim2.new(0,35,0,20)
				valBox.Font = Enum.Font.GothamBold
				valBox.Text = "0"
				valBox.TextColor3 = Color3.fromRGB(255,255,255)
				valBox.TextSize = 11
				valBox.Parent = ColorModal
				Instance.new("UICorner", valBox).CornerRadius = UDim.new(0,3)

				local dragging = false
				bar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = true
						local scale = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
						local val = math.floor(scale*255)
						currentColor[letter] = val
						fill.Size = UDim2.new(scale,0,1,0)
						valBox.Text = tostring(val)
						updatePreview()
						pcall(Config.Callback, Color3.fromRGB(currentColor.R, currentColor.G, currentColor.B))
					end
				end)
				bar.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
				end)
				UserInputService.InputChanged:Connect(function(input)
					if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
						local scale = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
						local val = math.floor(scale*255)
						currentColor[letter] = val
						fill.Size = UDim2.new(scale,0,1,0)
						valBox.Text = tostring(val)
						updatePreview()
						pcall(Config.Callback, Color3.fromRGB(currentColor.R, currentColor.G, currentColor.B))
					end
				end)
				valBox.FocusLost:Connect(function()
					local num = tonumber(valBox.Text) or 0
					num = math.clamp(math.floor(num), 0, 255)
					currentColor[letter] = num
					fill.Size = UDim2.new(num/255,0,1,0)
					valBox.Text = tostring(num)
					updatePreview()
					pcall(Config.Callback, Color3.fromRGB(currentColor.R, currentColor.G, currentColor.B))
				end)
				return fill, valBox
			end

			local RFill, RBox = makeSlider("R", 35)
			local GFill, GBox = makeSlider("G", 65)
			local BFill, BBox = makeSlider("B", 95)

			OpenColorBtn.Activated:Connect(function()
				for _, child in ipairs(DropdownZone:GetChildren()) do
					if child:IsA("Frame") and child ~= ColorModal then child.Visible = false end
				end
				if ColorModal.Visible then
					ColorModal.Visible = false
					Library:TweenInstance(DropdownZone, 0.3, "BackgroundTransparency", 1)
					task.wait(0.3)
					DropdownZone.Visible = false
				else
					DropdownZone.Visible = true
					ColorModal.Visible = true
					Library:TweenInstance(DropdownZone, 0.3, "BackgroundTransparency", 0.3)
				end
			end)
			CloseModal.Activated:Connect(function()
				ColorModal.Visible = false
				Library:TweenInstance(DropdownZone, 0.3, "BackgroundTransparency", 1)
				task.wait(0.3)
				DropdownZone.Visible = false
			end)

			-- Inicializa
			RFill.Size = UDim2.new(currentColor.R/255,0,1,0)
			GFill.Size = UDim2.new(currentColor.G/255,0,1,0)
			BFill.Size = UDim2.new(currentColor.B/255,0,1,0)
			RBox.Text = tostring(currentColor.R)
			GBox.Text = tostring(currentColor.G)
			BBox.Text = tostring(currentColor.B)

			local ColorPickerObj = {}
			function ColorPickerObj:Set(color)
				currentColor.R = color.R*255
				currentColor.G = color.G*255
				currentColor.B = color.B*255
				updatePreview()
				RFill.Size = UDim2.new(currentColor.R/255,0,1,0)
				GFill.Size = UDim2.new(currentColor.G/255,0,1,0)
				BFill.Size = UDim2.new(currentColor.B/255,0,1,0)
				RBox.Text = tostring(currentColor.R)
				GBox.Text = tostring(currentColor.G)
				BBox.Text = tostring(currentColor.B)
				if Config.Flag then
					Library.Flags[Config.Flag] = { Value = Preview.BackgroundColor3, Set = function(v) self:Set(v) end, Get = function() return Preview.BackgroundColor3 end }
					Library:SaveSettings()
				end
			end
			function ColorPickerObj:Get()
				return Preview.BackgroundColor3
			end

			if Config.Flag then
				Library.Flags[Config.Flag] = { Value = Config.Default, Set = function(v) ColorPickerObj:Set(v) end, Get = function() return Preview.BackgroundColor3 end }
			end
			return ColorPickerObj
		end

		return TabMethods
	end

	-- Botão flutuante
	local FloatingButton = Instance.new("ImageButton")
	FloatingButton.BackgroundColor3 = Color3.fromRGB(255,255,255)
	FloatingButton.BorderSizePixel = 0
	FloatingButton.Size = UDim2.new(0,50,0,50)
	FloatingButton.Position = UDim2.new(0, 20, 1, -70)
	FloatingButton.Image = "rbxassetid://124762714875426"
	FloatingButton.Visible = true
	FloatingButton.Parent = KingRuaUI_Premium
	Instance.new("UICorner", FloatingButton).CornerRadius = UDim.new(1,0)
	Instance.new("UIStroke", FloatingButton).Color = ThemeColor
	Library:MakeDraggable(FloatingButton, FloatingButton)
	FloatingButton.MouseButton1Click:Connect(function()
		WindowOpen = not WindowOpen
		Main.Visible = WindowOpen
	end)

	KeybindConnection = UserInputService.InputBegan:Connect(function(Input, GameProcessed)
		if GameProcessed then return end
		if Input.KeyCode == ConfigWindow.ToggleKey then
			WindowOpen = not WindowOpen
			Main.Visible = WindowOpen
		end
	end)

	function Library:Destroy()
		if KingRuaUI_Premium then KingRuaUI_Premium:Destroy() end
		if KeybindConnection then KeybindConnection:Disconnect() end
	end

	Library:LoadSettings()
	return Window
end

return Library
