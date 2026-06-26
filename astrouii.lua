-- // =========================================
-- // King Rua Hub UI Library - Versão Corrigid
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

function Library:UpdateContent(Content, Title, Object)
	if Content.Text ~= "" then
		Title.Position = UDim2.new(0, 10, 0, 7)
		Title.Size = UDim2.new(1, -60, 0, 16)
		local MaxY = math.max(Content.TextBounds.Y + 15, 45)
		Object.Size = UDim2.new(1, 0, 0, MaxY)
	end
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

-- Construtor da Janela
function Library:NewWindow(ConfigWindow)
	local OldGui = CoreGui:FindFirstChild("KingRuaUI_Premium")
	if OldGui then OldGui:Destroy() end

	ConfigWindow = self:MakeConfig({
		Title = "King Rua Hub",
		Description = "By _ng.shinichi",
		ThemeColor = Color3.fromRGB(255, 255, 255),   -- contornos brancos
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
			-- Restaurar: volta ao tamanho original, posição mantida
			Library:TweenInstance(Main, 0.3, "Size", OldSize)
			IconMax.ImageRectOffset = Vector2.new(580,194)
			IsMaximized = false
		else
			OldSize = Main.Size
			-- Maximizar: estica para tela cheia, mas mantém a posição
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

	-- TabFrame
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

	local TextLabel = Instance.new("TextLabel")
	TextLabel.BackgroundTransparency = 1
	TextLabel.Position = UDim2.new(0,10,0,0)
	TextLabel.Size = UDim2.new(1,-10,1,0)
	TextLabel.Font = Enum.Font.GothamBold
	TextLabel.Text = ""
	TextLabel.TextColor3 = Color3.fromRGB(255,255,255)
	TextLabel.TextSize = 13
	TextLabel.TextXAlignment = Enum.TextXAlignment.Left
	TextLabel.Parent = LayoutName

	local RealLayout = Instance.new("Frame")
	RealLayout.BackgroundTransparency = 1
	RealLayout.Position = UDim2.new(0,0,0,40)
	RealLayout.Size = UDim2.new(1,0,1,-40)
	RealLayout.Parent = LayoutFrame

	local LayoutList = Instance.new("Folder")
	LayoutList.Name = "Layout List"
	LayoutList.Parent = RealLayout

	local UIPageLayout = Instance.new("UIPageLayout")
	UIPageLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIPageLayout.EasingStyle = Enum.EasingStyle.Quad
	UIPageLayout.TweenTime = 0.3
	UIPageLayout.Parent = LayoutList

	local DropdownZone = Instance.new("Frame")
	DropdownZone.Name = "DropdownZone"
	DropdownZone.BackgroundColor3 = Color3.new(0,0,0)
	DropdownZone.BackgroundTransparency = 1
	DropdownZone.BorderSizePixel = 0
	DropdownZone.Size = UDim2.new(1,0,1,0)
	DropdownZone.Visible = false
	DropdownZone.Parent = Main

	Library:MakeDraggable(Top, Main)

	-- Componentes
	local AllLayouts = 0
	local Tab = {}

	function Tab:T(TabName)
		local TabButton = Instance.new("Frame")
		TabButton.BackgroundTransparency = 1
		TabButton.Size = UDim2.new(1,0,0,25)
		TabButton.Parent = ScrollingTab

		local Choose = Instance.new("Frame")
		Choose.BackgroundColor3 = ThemeColor
		Choose.BorderSizePixel = 0
		Choose.Position = UDim2.new(0,0,0,5)
		Choose.Size = UDim2.new(0,4,0,15)
		Choose.Visible = false
		Choose.Parent = TabButton
		Instance.new("UICorner", Choose).CornerRadius = UDim.new(1,0)

		local NameTab = Instance.new("TextLabel")
		NameTab.BackgroundTransparency = 1
		NameTab.Position = UDim2.new(0,15,0,0)
		NameTab.Size = UDim2.new(1,-15,1,0)
		NameTab.Font = Enum.Font.GothamBold
		NameTab.Text = TabName
		NameTab.TextColor3 = Color3.fromRGB(255,255,255)
		NameTab.TextSize = 12
		NameTab.TextTransparency = 0.3
		NameTab.TextXAlignment = Enum.TextXAlignment.Left
		NameTab.Parent = TabButton

		local ClickTab = Instance.new("TextButton")
		ClickTab.BackgroundTransparency = 1
		ClickTab.Size = UDim2.new(1,0,1,0)
		ClickTab.Text = ""
		ClickTab.Parent = TabButton

		local Layout = Instance.new("ScrollingFrame")
		Layout.BackgroundTransparency = 1
		Layout.Selectable = false
		Layout.Size = UDim2.new(1,0,1,0)
		Layout.CanvasSize = UDim2.new(0,0,1,0)
		Layout.ScrollBarThickness = 0
		Layout.LayoutOrder = AllLayouts
		Layout.Parent = LayoutList

		local UIPadding_3 = Instance.new("UIPadding")
		UIPadding_3.PaddingBottom = UDim.new(0,7)
		UIPadding_3.PaddingLeft = UDim.new(0,10)
		UIPadding_3.PaddingRight = UDim.new(0,7)
		UIPadding_3.Parent = Layout

		local UIListLayout_3 = Instance.new("UIListLayout")
		UIListLayout_3.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout_3.Padding = UDim.new(0,10)
		UIListLayout_3.Parent = Layout

		Library:UpdateScrolling(Layout, UIListLayout_3)

		if AllLayouts == 0 then
			NameTab.TextTransparency = 0
			Choose.Visible = true
			UIPageLayout:JumpToIndex(0)
			TextLabel.Text = TabName
		end
		AllLayouts = AllLayouts + 1

		ClickTab.Activated:Connect(function()
			TextLabel.Text = TabName
			for _, v in ipairs(ScrollingTab:GetChildren()) do
				if v:IsA("Frame") and v:FindFirstChild("NameTab") then
					Library:TweenInstance(v.NameTab, 0.3, "TextTransparency", 0.3)
					v.Choose.Visible = false
				end
			end
			Library:TweenInstance(NameTab, 0.2, "TextTransparency", 0)
			Choose.Visible = true
			local TargetX = Layout.AbsolutePosition.X - RealLayout.AbsolutePosition.X
			Library:TweenInstance(RealLayout, 0.3, "CanvasPosition", Vector2.new(TargetX, 0))
			UIPageLayout:JumpToIndex(Layout.LayoutOrder)
		end)

		local TabFunc = {}

		function TabFunc:AddSection(SectionName)
			local Section = Instance.new("Frame")
			Section.BackgroundColor3 = Color3.new(1,1,1)
			Section.BackgroundTransparency = 0.98
			Section.BorderSizePixel = 0
			Section.Size = UDim2.new(1,0,0,55)
			Section.Parent = Layout

			Instance.new("UICorner", Section).CornerRadius = UDim.new(0,4)

			local SecStroke = Instance.new("UIStroke")
			SecStroke.Color = Color3.fromRGB(100,100,100)
			SecStroke.Thickness = 2
			SecStroke.Transparency = 0.92
			SecStroke.Parent = Section

			local NameSection = Instance.new("Frame")
			NameSection.BackgroundTransparency = 1
			NameSection.Size = UDim2.new(1,0,0,30)
			NameSection.Parent = Section

			local Title = Instance.new("TextLabel")
			Title.BackgroundTransparency = 1
			Title.Size = UDim2.new(1,0,1,0)
			Title.Font = Enum.Font.GothamBold
			Title.Text = SectionName
			Title.TextColor3 = Color3.fromRGB(255,255,255)
			Title.TextSize = 14
			Title.Parent = NameSection

			local SectionList = Instance.new("Frame")
			SectionList.BackgroundTransparency = 1
			SectionList.Position = UDim2.new(0,0,0,35)
			SectionList.Size = UDim2.new(1,0,1,-35)
			SectionList.Parent = Section

			local UIPadding_4 = Instance.new("UIPadding")
			UIPadding_4.PaddingBottom = UDim.new(0,7)
			UIPadding_4.PaddingLeft = UDim.new(0,7)
			UIPadding_4.PaddingRight = UDim.new(0,7)
			UIPadding_4.PaddingTop = UDim.new(0,7)
			UIPadding_4.Parent = SectionList

			local UIListLayout_4 = Instance.new("UIListLayout")
			UIListLayout_4.SortOrder = Enum.SortOrder.LayoutOrder
			UIListLayout_4.Padding = UDim.new(0,6)
			UIListLayout_4.Parent = SectionList

			UIListLayout_4:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				Section.Size = UDim2.new(1,0,0, UIListLayout_4.AbsoluteContentSize.Y + 55)
			end)

			SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
				local Query = SearchBox.Text:lower()
				for _, Element in ipairs(SectionList:GetChildren()) do
					if Element:IsA("Frame") then
						local Found = false
						for _, Child in ipairs(Element:GetChildren()) do
							if Child:IsA("TextLabel") and Child.Text:lower():find(Query) then
								Found = true
								break
							end
						end
						Element.Visible = Found or Query == ""
					end
				end
			end)

			local SectionFunc = {}

			-- // Toggle
			function SectionFunc:AddToggle(Config)
				Config = Library:MakeConfig({
					Title = "Toggle", Description = "", Default = false,
					Flag = nil, Callback = function() end
				}, Config or {})
				local Toggle = Instance.new("Frame")
				Toggle.BackgroundColor3 = Color3.new(1,1,1)
				Toggle.BackgroundTransparency = 0.95
				Toggle.BorderSizePixel = 0
				Toggle.Size = UDim2.new(1,0,0,35)
				Toggle.Parent = SectionList
				Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0,3)
				local TitleLabel = Instance.new("TextLabel")
				TitleLabel.BackgroundTransparency = 1
				TitleLabel.Position = UDim2.new(0,10,0,0)
				TitleLabel.Size = UDim2.new(1,-60,1,0)
				TitleLabel.Font = Enum.Font.GothamBold
				TitleLabel.Text = Config.Title
				TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
				TitleLabel.TextSize = 13
				TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
				TitleLabel.Parent = Toggle
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
				local Content = Instance.new("TextLabel")
				Content.BackgroundTransparency = 1
				Content.Position = UDim2.new(0,10,0,22)
				Content.Size = UDim2.new(1,-60,1,0)
				Content.Font = Enum.Font.GothamBold
				Content.Text = Config.Description
				Content.TextColor3 = Color3.fromRGB(100,100,100)
				Content.TextSize = 12
				Content.TextXAlignment = Enum.TextXAlignment.Left
				Content.TextYAlignment = Enum.TextYAlignment.Top
				Content.Parent = Toggle
				Library:UpdateContent(Content, TitleLabel, Toggle)
				Library:MouseEvent(ToggleClick,
					function() Toggle.BackgroundTransparency = 0.93 end,
					function() Toggle.BackgroundTransparency = 0.95 end)
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

			-- // Button
			function SectionFunc:AddButton(Config)
				Config = Library:MakeConfig({
					Title = "Button", Description = "", Callback = function() end
				}, Config or {})
				local Button = Instance.new("Frame")
				Button.BackgroundColor3 = Color3.new(1,1,1)
				Button.BackgroundTransparency = 0.95
				Button.BorderSizePixel = 0
				Button.Size = UDim2.new(1,0,0,35)
				Button.Parent = SectionList
				Instance.new("UICorner", Button).CornerRadius = UDim.new(0,3)
				local TitleLabel = Instance.new("TextLabel")
				TitleLabel.BackgroundTransparency = 1
				TitleLabel.Position = UDim2.new(0,10,0,0)
				TitleLabel.Size = UDim2.new(1,-60,1,0)
				TitleLabel.Font = Enum.Font.GothamBold
				TitleLabel.Text = Config.Title
				TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
				TitleLabel.TextSize = 13
				TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
				TitleLabel.Parent = Button
				local ButtonClick = Instance.new("TextButton")
				ButtonClick.BackgroundTransparency = 1
				ButtonClick.Size = UDim2.new(1,0,1,0)
				ButtonClick.Text = ""
				ButtonClick.Parent = Button
				local Content = Instance.new("TextLabel")
				Content.BackgroundTransparency = 1
				Content.Position = UDim2.new(0,10,0,22)
				Content.Size = UDim2.new(1,-60,1,0)
				Content.Font = Enum.Font.GothamBold
				Content.Text = Config.Description
				Content.TextColor3 = Color3.fromRGB(100,100,100)
				Content.TextSize = 12
				Content.TextXAlignment = Enum.TextXAlignment.Left
				Content.TextYAlignment = Enum.TextYAlignment.Top
				Content.Parent = Button
				local IconImg = Instance.new("ImageLabel")
				IconImg.AnchorPoint = Vector2.new(0,0.5)
				IconImg.BackgroundTransparency = 1
				IconImg.Position = UDim2.new(1,-35,0.5,0)
				IconImg.Size = UDim2.new(0,24,0,24)
				IconImg.Image = "rbxassetid://85905776508942"
				IconImg.Parent = Button
				Library:UpdateContent(Content, TitleLabel, Button)
				Library:MouseEvent(ButtonClick,
					function() Button.BackgroundTransparency = 0.92 end,
					function() Button.BackgroundTransparency = 0.95 end)
				ButtonClick.Activated:Connect(function() pcall(Config.Callback) end)
			end

			-- // Input
			function SectionFunc:AddInput(Config)
				Config = Library:MakeConfig({
					Title = "Input", Description = "", PlaceHolder = "",
					Default = "", Flag = nil, Callback = function() end
				}, Config or {})
				local Input = Instance.new("Frame")
				Input.BackgroundColor3 = Color3.new(1,1,1)
				Input.BackgroundTransparency = 0.95
				Input.BorderSizePixel = 0
				Input.Size = UDim2.new(1,0,0,35)
				Input.Parent = SectionList
				Instance.new("UICorner", Input).CornerRadius = UDim.new(0,3)
				local TitleLabel = Instance.new("TextLabel")
				TitleLabel.BackgroundTransparency = 1
				TitleLabel.Position = UDim2.new(0,10,0,0)
				TitleLabel.Size = UDim2.new(1,-60,1,0)
				TitleLabel.Font = Enum.Font.GothamBold
				TitleLabel.Text = Config.Title
				TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
				TitleLabel.TextSize = 13
				TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
				TitleLabel.Parent = Input
				local Content = Instance.new("TextLabel")
				Content.BackgroundTransparency = 1
				Content.Position = UDim2.new(0,10,0,22)
				Content.Size = UDim2.new(1,-160,1,0)
				Content.Font = Enum.Font.GothamBold
				Content.Text = Config.Description
				Content.TextColor3 = Color3.fromRGB(100,100,100)
				Content.TextSize = 12
				Content.TextXAlignment = Enum.TextXAlignment.Left
				Content.TextYAlignment = Enum.TextYAlignment.Top
				Content.Parent = Input
				Library:UpdateContent(Content, TitleLabel, Input)
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

			-- // Dropdown (multi corrigido)
			function SectionFunc:AddDropdown(Config)
				Config = Library:MakeConfig({
					Title = "Dropdown", Description = "", Values = {}, Multi = false,
					Default = nil, Flag = nil, Callback = function() end
				}, Config or {})
				local Dropdown = Instance.new("Frame")
				Dropdown.BackgroundColor3 = Color3.new(1,1,1)
				Dropdown.BackgroundTransparency = 0.95
				Dropdown.BorderSizePixel = 0
				Dropdown.Size = UDim2.new(1,0,0,35)
				Dropdown.Parent = SectionList
				Instance.new("UICorner", Dropdown).CornerRadius = UDim.new(0,3)
				local TitleLabel = Instance.new("TextLabel")
				TitleLabel.BackgroundTransparency = 1
				TitleLabel.Position = UDim2.new(0,10,0,0)
				TitleLabel.Size = UDim2.new(1,-60,1,0)
				TitleLabel.Font = Enum.Font.GothamBold
				TitleLabel.Text = Config.Title
				TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
				TitleLabel.TextSize = 13
				TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
				TitleLabel.Parent = Dropdown
				local Content = Instance.new("TextLabel")
				Content.BackgroundTransparency = 1
				Content.Position = UDim2.new(0,10,0,22)
				Content.Size = UDim2.new(1,-60,1,0)
				Content.Font = Enum.Font.GothamBold
				Content.Text = Config.Description
				Content.TextColor3 = Color3.fromRGB(100,100,100)
				Content.TextSize = 12
				Content.TextXAlignment = Enum.TextXAlignment.Left
				Content.TextYAlignment = Enum.TextYAlignment.Top
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
				Library:UpdateContent(Content, TitleLabel, Dropdown)
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

			-- // Slider (agora presente)
			function SectionFunc:AddSlider(Config)
				Config = Library:MakeConfig({
					Title = "Slider", Description = "", Min = 1, Max = 100,
					Increment = 1, Default = 50, Flag = nil, Callback = function() end
				}, Config or {})
				local Slider = Instance.new("Frame")
				Slider.BackgroundColor3 = Color3.new(1,1,1)
				Slider.BackgroundTransparency = 0.95
				Slider.BorderSizePixel = 0
				Slider.Size = UDim2.new(1,0,0,35)
				Slider.Parent = SectionList
				Instance.new("UICorner", Slider).CornerRadius = UDim.new(0,3)
				local TitleLabel = Instance.new("TextLabel")
				TitleLabel.BackgroundTransparency = 1
				TitleLabel.Position = UDim2.new(0,10,0,0)
				TitleLabel.Size = UDim2.new(1,-60,1,0)
				TitleLabel.Font = Enum.Font.GothamBold
				TitleLabel.Text = Config.Title
				TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
				TitleLabel.TextSize = 13
				TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
				TitleLabel.Parent = Slider
				local Content = Instance.new("TextLabel")
				Content.BackgroundTransparency = 1
				Content.Position = UDim2.new(0,10,0,22)
				Content.Size = UDim2.new(1,-160,1,0)
				Content.Font = Enum.Font.GothamBold
				Content.Text = Config.Description
				Content.TextColor3 = Color3.fromRGB(100,100,100)
				Content.TextSize = 12
				Content.TextXAlignment = Enum.TextXAlignment.Left
				Content.TextYAlignment = Enum.TextYAlignment.Top
				Content.Parent = Slider
				Library:UpdateContent(Content, TitleLabel, Slider)
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

			-- // ColorPicker
			function SectionFunc:AddColorPicker(Config)
				Config = Library:MakeConfig({
					Title = "Color Picker", Description = "", Default = Color3.fromRGB(255,255,255),
					Flag = nil, Callback = function() end
				}, Config or {})
				local ColorFrame = Instance.new("Frame")
				ColorFrame.BackgroundColor3 = Color3.new(1,1,1)
				ColorFrame.BackgroundTransparency = 0.95
				ColorFrame.BorderSizePixel = 0
				ColorFrame.Size = UDim2.new(1,0,0,70)
				ColorFrame.Parent = SectionList
				Instance.new("UICorner", ColorFrame).CornerRadius = UDim.new(0,3)
				local TitleLabel = Instance.new("TextLabel")
				TitleLabel.BackgroundTransparency = 1
				TitleLabel.Position = UDim2.new(0,10,0,5)
				TitleLabel.Size = UDim2.new(1,-10,0,16)
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
				local function CreateColorSlider(Text, YPos)
					local Label = Instance.new("TextLabel")
					Label.BackgroundTransparency = 1
					Label.Position = UDim2.new(0,10,0,YPos)
					Label.Size = UDim2.new(0,20,0,20)
					Label.Font = Enum.Font.GothamBold
					Label.Text = Text
					Label.TextColor3 = Color3.fromRGB(255,255,255)
					Label.TextSize = 11
					Label.Parent = ColorFrame
					local SliderFrame2 = Instance.new("Frame")
					SliderFrame2.BackgroundColor3 = Color3.fromRGB(20,20,20)
					SliderFrame2.BorderSizePixel = 0
					SliderFrame2.Position = UDim2.new(0,35,0,YPos+2)
					SliderFrame2.Size = UDim2.new(1,-100,0,6)
					SliderFrame2.Parent = ColorFrame
					Instance.new("UICorner", SliderFrame2).CornerRadius = UDim.new(1,0)
					local Fill2 = Instance.new("Frame")
					Fill2.BackgroundColor3 = ThemeColor
					Fill2.BorderSizePixel = 0
					Fill2.Size = UDim2.new(1,0,1,0)
					Fill2.Parent = SliderFrame2
					Instance.new("UICorner", Fill2).CornerRadius = UDim.new(1,0)
					return Fill2, SliderFrame2
				end
				local RFill, RSlider = CreateColorSlider("R", 25)
				local GFill, GSlider = CreateColorSlider("G", 42)
				local BFill, BSlider = CreateColorSlider("B", 59)
				local CurrentColor = Config.Default
				local Dragging2 = false
				local function UpdateColorFromSlider(SliderFrame, Component)
					local Scale = math.clamp((UserInputService:GetMouseLocation().X - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
					local Value = math.floor(Scale * 255)
					local r = Component == "R" and Value or CurrentColor.R
					local g = Component == "G" and Value or CurrentColor.G
					local b = Component == "B" and Value or CurrentColor.B
					CurrentColor = Color3.fromRGB(r,g,b)
					Preview.BackgroundColor3 = CurrentColor
					pcall(Config.Callback, CurrentColor)
					if Config.Flag then Library.Flags[Config.Flag] = { Value = CurrentColor, Set = function(v) CurrentColor = v; Preview.BackgroundColor3 = v end, Get = function() return CurrentColor end }; Library:SaveSettings() end
					RFill.Size = UDim2.new(r/255,0,1,0)
					GFill.Size = UDim2.new(g/255,0,1,0)
					BFill.Size = UDim2.new(b/255,0,1,0)
				end
				UserInputService.InputChanged:Connect(function(Input)
					if Dragging2 and Input.UserInputType == Enum.UserInputType.MouseMovement then
						UpdateColorFromSlider(RSlider, "R")
						UpdateColorFromSlider(GSlider, "G")
						UpdateColorFromSlider(BSlider, "B")
					end
				end)
				RSlider.InputBegan:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging2 = true end end)
				RSlider.InputEnded:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging2 = false end end)
				GSlider.InputBegan:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging2 = true end end)
				GSlider.InputEnded:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging2 = false end end)
				BSlider.InputBegan:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging2 = true end end)
				BSlider.InputEnded:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging2 = false end end)
				RFill.Size = UDim2.new(Config.Default.R/255,0,1,0)
				GFill.Size = UDim2.new(Config.Default.G/255,0,1,0)
				BFill.Size = UDim2.new(Config.Default.B/255,0,1,0)
				return { Set = function(color) CurrentColor = color; Preview.BackgroundColor3 = color end, Get = function() return CurrentColor end }
			end

			-- // Keybind
			function SectionFunc:AddKeybind(Config)
				Config = Library:MakeConfig({
					Title = "Keybind", Description = "", Default = Enum.KeyCode.LeftControl,
					Flag = nil, Callback = function() end
				}, Config or {})
				local Keybind = Instance.new("Frame")
				Keybind.BackgroundColor3 = Color3.new(1,1,1)
				Keybind.BackgroundTransparency = 0.95
				Keybind.BorderSizePixel = 0
				Keybind.Size = UDim2.new(1,0,0,35)
				Keybind.Parent = SectionList
				Instance.new("UICorner", Keybind).CornerRadius = UDim.new(0,3)
				local TitleLabel = Instance.new("TextLabel")
				TitleLabel.BackgroundTransparency = 1
				TitleLabel.Position = UDim2.new(0,10,0,0)
				TitleLabel.Size = UDim2.new(1,-60,1,0)
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

			-- // Paragraph
			function SectionFunc:AddParagraph(Config)
				Config = Library:MakeConfig({
					Title = "Paragraph", Content = ""
				}, Config or {})
				local Paragraph = Instance.new("Frame")
				Paragraph.BackgroundColor3 = Color3.new(1,1,1)
				Paragraph.BackgroundTransparency = 0.95
				Paragraph.BorderSizePixel = 0
				Paragraph.Size = UDim2.new(1,0,0,45)
				Paragraph.Parent = SectionList
				Instance.new("UICorner", Paragraph).CornerRadius = UDim.new(0,3)
				local TitleLabel = Instance.new("TextLabel")
				TitleLabel.BackgroundTransparency = 1
				TitleLabel.Position = UDim2.new(0,10,0,7)
				TitleLabel.Size = UDim2.new(1,-60,0,16)
				TitleLabel.Font = Enum.Font.GothamBold
				TitleLabel.Text = Config.Title
				TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
				TitleLabel.TextSize = 13
				TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
				TitleLabel.Parent = Paragraph
				local Content = Instance.new("TextLabel")
				Content.BackgroundTransparency = 1
				Content.Position = UDim2.new(0,10,0,22)
				Content.Size = UDim2.new(1,-10,1,0)
				Content.Font = Enum.Font.GothamBold
				Content.Text = Config.Content
				Content.TextColor3 = Color3.fromRGB(100,100,100)
				Content.TextSize = 12
				Content.TextXAlignment = Enum.TextXAlignment.Left
				Content.TextYAlignment = Enum.TextYAlignment.Top
				Content.Parent = Paragraph
				Library:UpdateContent(Content, TitleLabel, Paragraph)
				return {
					SetTitle = function(t) TitleLabel.Text = t end,
					SetContent = function(c) Content.Text = c; Library:UpdateContent(Content, TitleLabel, Paragraph) end
				}
			end

			return SectionFunc
		end
		return TabFunc
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
	return Tab
end

return Library
