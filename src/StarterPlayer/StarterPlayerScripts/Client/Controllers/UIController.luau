--!strict

local Players = game:GetService("Players")

local UIController = {}

local started = false
local screenGui: ScreenGui? = nil
local menuLayer: Frame? = nil
local playLayer: Frame? = nil
local leftDock: Frame? = nil
local rightDock: Frame? = nil
local overlayDock: Frame? = nil
local menuActionsFrame: Frame? = nil
local toolPanels: { [string]: Frame? } = {}
local toolButtons: { [string]: TextButton? } = {}
local menuButtons: { TextButton } = {}
local toolButtonCount = 0

local COLORS = {
	backdrop = Color3.fromRGB(7, 14, 13),
	panel = Color3.fromRGB(14, 24, 23),
	panelAlt = Color3.fromRGB(18, 31, 35),
	stroke = Color3.fromRGB(98, 121, 101),
	text = Color3.fromRGB(244, 248, 240),
	muted = Color3.fromRGB(174, 187, 172),
	gold = Color3.fromRGB(232, 188, 91),
	green = Color3.fromRGB(31, 93, 67),
	blue = Color3.fromRGB(40, 75, 98),
}

local function addCorner(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function addStroke(parent: Instance, color: Color3, transparency: number)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Transparency = transparency
	stroke.Thickness = 1
	stroke.Parent = parent
end

local function makeText(
	parent: Instance,
	name: string,
	text: string,
	y: number,
	size: number
): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = COLORS.text
	label.TextSize = size
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Size = UDim2.new(1, -32, 0, 34)
	label.Position = UDim2.fromOffset(16, y)
	label.Parent = parent
	return label
end

local function makeNavButton(name: string, text: string, callback: () -> ()): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.BackgroundColor3 = COLORS.panelAlt
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = COLORS.text
	button.TextSize = 12
	button.Size = UDim2.fromOffset(92, 32)
	button.AutoButtonColor = true
	addCorner(button, 6)
	addStroke(button, COLORS.stroke, 0.62)
	button.Activated:Connect(callback)
	return button
end

local function hideToolPanels()
	for _, panel in toolPanels do
		if panel ~= nil then
			panel.Visible = false
		end
	end
	if rightDock ~= nil then
		rightDock.Visible = false
	end
	for _, button in toolButtons do
		if button ~= nil then
			button.BackgroundColor3 = COLORS.panelAlt
		end
	end
end

local function ensureGui()
	if screenGui ~= nil then
		return
	end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local screen = Instance.new("ScreenGui")
	screen.Name = "GolfProUI"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = playerGui
	screenGui = screen

	local menu = Instance.new("Frame")
	menu.Name = "MenuLayer"
	menu.BackgroundColor3 = COLORS.backdrop
	menu.BorderSizePixel = 0
	menu.Size = UDim2.fromScale(1, 1)
	menu.Visible = true
	menu.Parent = screen
	menuLayer = menu

	local hero = Instance.new("Frame")
	hero.Name = "MainMenu"
	hero.AnchorPoint = Vector2.new(0.5, 0.5)
	hero.BackgroundColor3 = COLORS.panel
	hero.BackgroundTransparency = 0.04
	hero.BorderSizePixel = 0
	hero.Position = UDim2.fromScale(0.5, 0.5)
	hero.Size = UDim2.fromOffset(560, 520)
	hero.Parent = menu
	addCorner(hero, 8)
	addStroke(hero, COLORS.stroke, 0.35)

	makeText(hero, "Eyebrow", "PINEBROOK NATIONAL", 28, 13).TextColor3 = COLORS.gold
	makeText(hero, "Title", "Golf Pro", 62, 40)
	makeText(
		hero,
		"Subtitle",
		"Choose where you want to play. The course UI stays hidden until you enter a mode.",
		116,
		16
	).TextColor3 =
		COLORS.muted

	local actions = Instance.new("Frame")
	actions.Name = "MenuActions"
	actions.BackgroundTransparency = 1
	actions.Position = UDim2.fromOffset(28, 184)
	actions.Size = UDim2.new(1, -56, 0, 300)
	actions.Parent = hero
	menuActionsFrame = actions

	local actionsLayout = Instance.new("UIListLayout")
	actionsLayout.Padding = UDim.new(0, 12)
	actionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	actionsLayout.Parent = actions

	local play = Instance.new("Frame")
	play.Name = "PlayLayer"
	play.BackgroundTransparency = 1
	play.Size = UDim2.fromScale(1, 1)
	play.Visible = false
	play.Parent = screen
	playLayer = play

	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.BackgroundColor3 = Color3.fromRGB(8, 15, 16)
	topBar.BackgroundTransparency = 0.08
	topBar.BorderSizePixel = 0
	topBar.Size = UDim2.new(1, 0, 0, 64)
	topBar.Parent = play

	local title = makeText(topBar, "Title", "Golf Pro", 15, 18)
	title.Size = UDim2.fromOffset(180, 28)

	local nav = Instance.new("Frame")
	nav.Name = "ToolNav"
	nav.AnchorPoint = Vector2.new(1, 0)
	nav.BackgroundTransparency = 1
	nav.Position = UDim2.new(1, -16, 0, 16)
	nav.Size = UDim2.fromOffset(640, 34)
	nav.Parent = topBar

	local navLayout = Instance.new("UIListLayout")
	navLayout.FillDirection = Enum.FillDirection.Horizontal
	navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	navLayout.Padding = UDim.new(0, 8)
	navLayout.SortOrder = Enum.SortOrder.LayoutOrder
	navLayout.Parent = nav

	local menuButton = makeNavButton("BackToMenu", "Menu", function()
		UIController.showMenu()
	end)
	menuButton.LayoutOrder = 999
	menuButton.Parent = nav

	local left = Instance.new("Frame")
	left.Name = "LeftDock"
	left.BackgroundTransparency = 1
	left.Position = UDim2.fromOffset(18, 82)
	left.Size = UDim2.new(0, 344, 1, -100)
	left.Parent = play
	leftDock = left

	local right = Instance.new("Frame")
	right.Name = "RightDock"
	right.AnchorPoint = Vector2.new(1, 0)
	right.BackgroundTransparency = 1
	right.Position = UDim2.new(1, -18, 0, 82)
	right.Size = UDim2.new(0, 456, 1, -100)
	right.Visible = false
	right.Parent = play
	rightDock = right

	local overlay = Instance.new("Frame")
	overlay.Name = "OverlayDock"
	overlay.BackgroundTransparency = 1
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.Parent = play
	overlayDock = overlay
end

function UIController.start()
	if started then
		return
	end
	started = true
	ensureGui()
end

function UIController.showMenu()
	ensureGui()
	if menuLayer ~= nil then
		menuLayer.Visible = true
	end
	if playLayer ~= nil then
		playLayer.Visible = false
	end
	hideToolPanels()
end

function UIController.enterPlay()
	ensureGui()
	if menuLayer ~= nil then
		menuLayer.Visible = false
	end
	if playLayer ~= nil then
		playLayer.Visible = true
	end
	hideToolPanels()
end

function UIController.setMainMenuActions(actions: { any })
	ensureGui()
	local parent = menuActionsFrame
	if parent == nil then
		return
	end
	for _, button in menuButtons do
		button:Destroy()
	end
	menuButtons = {}

	for index, action in actions do
		local button = Instance.new("TextButton")
		button.Name = tostring(action.id or action.title or "MenuAction")
		button.BackgroundColor3 = if index == 1 then COLORS.green else COLORS.panelAlt
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamBold
		button.Text = ""
		button.Size = UDim2.new(1, 0, 0, 62)
		button.LayoutOrder = index
		button.Parent = parent
		addCorner(button, 8)
		addStroke(button, if index == 1 then COLORS.gold else COLORS.stroke, 0.48)

		local title = makeText(button, "Title", tostring(action.title or "Play"), 9, 17)
		title.Size = UDim2.new(1, -34, 0, 22)
		local subtitle = makeText(button, "Subtitle", tostring(action.subtitle or ""), 33, 12)
		subtitle.Font = Enum.Font.GothamMedium
		subtitle.TextColor3 = COLORS.muted
		subtitle.Size = UDim2.new(1, -34, 0, 20)

		button.Activated:Connect(function()
			UIController.enterPlay()
			if action.panelName ~= nil then
				UIController.showToolPanel(tostring(action.panelName))
			end
			if type(action.callback) == "function" then
				action.callback()
			end
		end)
		table.insert(menuButtons, button)
	end
end

function UIController.createHudPanel(name: string, size: UDim2): Frame
	ensureGui()
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.BackgroundColor3 = COLORS.panel
	panel.BackgroundTransparency = 0.04
	panel.BorderSizePixel = 0
	panel.Size = size
	panel.Position = UDim2.fromOffset(0, 0)
	panel.Parent = leftDock
	addCorner(panel, 8)
	addStroke(panel, COLORS.stroke, 0.4)
	return panel
end

function UIController.createToolPanel(name: string, title: string, size: UDim2): Frame
	ensureGui()
	local existing = toolPanels[name]
	if existing ~= nil then
		return existing
	end

	local panel = Instance.new("Frame")
	panel.Name = name
	panel.BackgroundColor3 = COLORS.panel
	panel.BackgroundTransparency = 0.04
	panel.BorderSizePixel = 0
	panel.Size = size
	panel.Position = UDim2.fromOffset(0, 0)
	panel.Visible = false
	panel.Parent = rightDock
	panel:SetAttribute("ToolTitle", title)
	addCorner(panel, 8)
	addStroke(panel, COLORS.stroke, 0.4)
	toolPanels[name] = panel

	local nav = screenGui and screenGui:FindFirstChild("PlayLayer", true)
	local navFrame = nav and nav:FindFirstChild("ToolNav", true)
	if navFrame and navFrame:IsA("Frame") then
		local button = makeNavButton(title .. "Tab", title, function()
			UIController.showToolPanel(name)
		end)
		toolButtonCount += 1
		button.LayoutOrder = toolButtonCount
		button.Parent = navFrame
		toolButtons[name] = button
	end

	return panel
end

function UIController.createOverlayPanel(name: string, size: UDim2): Frame
	ensureGui()
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.BackgroundColor3 = COLORS.panelAlt
	panel.BackgroundTransparency = 0.04
	panel.BorderSizePixel = 0
	panel.Position = UDim2.new(0.5, 0, 1, -36)
	panel.Size = size
	panel.Visible = false
	panel.Parent = overlayDock
	addCorner(panel, 8)
	addStroke(panel, COLORS.gold, 0.48)
	return panel
end

function UIController.showToolPanel(name: string)
	UIController.enterPlay()
	local panel = toolPanels[name]
	if panel == nil then
		return
	end

	for panelName, otherPanel in toolPanels do
		if otherPanel ~= nil then
			otherPanel.Visible = panelName == name
		end
	end
	if rightDock ~= nil then
		rightDock.Visible = true
	end
	for panelName, button in toolButtons do
		if button ~= nil then
			button.BackgroundColor3 = if panelName == name then COLORS.blue else COLORS.panelAlt
		end
	end
end

return UIController
