--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CosmeticCatalog = require(ReplicatedStorage.Shared.GolfPro.Config.CosmeticCatalog)
local UIController = require(script.Parent.UIController)

local LockerController = {}

local started = false
local labels: { [string]: TextLabel? } = {}
local buttons: { TextButton } = {}
local latestSnapshot: any = nil
local listFrame: Frame? = nil

local function remotesFolder(): Folder?
	return ReplicatedStorage:FindFirstChild("NexusRemotes") :: Folder?
end

local function remoteEvent(name: string): RemoteEvent?
	local folder = remotesFolder()
	local remote = folder and folder:FindFirstChild(name)
	return if remote and remote:IsA("RemoteEvent") then remote else nil
end

local function remoteFunction(name: string): RemoteFunction?
	local folder = remotesFolder()
	local remote = folder and folder:FindFirstChild(name)
	return if remote and remote:IsA("RemoteFunction") then remote else nil
end

local function bindRemote(name: string, callback: (...any) -> ())
	task.spawn(function()
		local folder = ReplicatedStorage:WaitForChild("NexusRemotes", 10)
		if folder == nil then
			return
		end
		local remote = folder:WaitForChild(name, 10)
		if remote and remote:IsA("RemoteEvent") then
			remote.OnClientEvent:Connect(callback)
		end
	end)
end

local function setText(key: string, text: string)
	local label = labels[key]
	if label ~= nil then
		label.Text = text
	end
end

local function makeLabel(parent: Instance, key: string, y: number, text: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = key
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextColor3 = Color3.fromRGB(240, 244, 241)
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Size = UDim2.fromOffset(292, 20)
	label.Position = UDim2.fromOffset(10, y)
	label.Text = text
	label.Parent = parent
	labels[key] = label
	return label
end

local function makeRow(parent: Instance, item: any, rowIndex: number, state: any)
	local y = (rowIndex - 1) * 24
	local row = Instance.new("Frame")
	row.Name = item.id
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromOffset(292, 22)
	row.Position = UDim2.fromOffset(0, y)
	row.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextColor3 = Color3.fromRGB(234, 238, 232)
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Size = UDim2.fromOffset(204, 22)
	label.Position = UDim2.fromOffset(0, 0)
	label.Text = item.displayName
	label.Parent = row

	local button = Instance.new("TextButton")
	button.Name = "Equip"
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 10
	button.Size = UDim2.fromOffset(78, 20)
	button.Position = UDim2.fromOffset(214, 1)
	button.Parent = row
	table.insert(buttons, button)

	if state ~= nil and state.equipped == true then
		button.Text = "Equipped"
		button.Active = false
		button.AutoButtonColor = false
		button.BackgroundColor3 = Color3.fromRGB(65, 105, 83)
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
	elseif state ~= nil and state.owned == true then
		button.Text = "Equip"
		button.Active = true
		button.AutoButtonColor = true
		button.BackgroundColor3 = Color3.fromRGB(80, 93, 57)
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.Activated:Connect(function()
			local remote = remoteEvent("RequestEquipCosmetic")
			if remote ~= nil then
				remote:FireServer({ cosmeticId = item.id })
			end
		end)
	else
		button.Text = "Locked"
		button.Active = false
		button.AutoButtonColor = false
		button.BackgroundColor3 = Color3.fromRGB(54, 56, 52)
		button.TextColor3 = Color3.fromRGB(172, 177, 169)
	end
end

local function clearRows()
	for _, button in buttons do
		button:Destroy()
	end
	buttons = {}
	local frame = listFrame
	if frame ~= nil then
		for _, child in frame:GetChildren() do
			child:Destroy()
		end
	end
end

local function update(snapshot: any)
	latestSnapshot = snapshot
	if type(snapshot) ~= "table" then
		return
	end

	local equipped = snapshot.equipped or {}
	setText(
		"equipped",
		("Ball: %s  Trail: %s"):format(
			tostring(equipped.ball_skin or "classic_white_ball"),
			tostring(equipped.trail or "classic_arc_trail")
		)
	)
	setText(
		"profile",
		("Title: %s  Banner: %s"):format(
			tostring(equipped.title or "starter_title"),
			tostring(equipped.profile_banner or "clubhouse_banner")
		)
	)

	clearRows()
	local frame = listFrame
	if frame == nil then
		return
	end
	local rowIndex = 1
	for _, item: any in CosmeticCatalog.all() do
		makeRow(frame, item, rowIndex, snapshot.items and snapshot.items[item.id])
		rowIndex += 1
	end
end

local function requestSnapshot()
	task.spawn(function()
		local folder = ReplicatedStorage:WaitForChild("NexusRemotes", 10)
		if folder == nil then
			return
		end
		local remote = remoteFunction("RequestCosmeticInventory")
		if remote == nil then
			return
		end
		local ok, snapshot = pcall(function()
			return remote:InvokeServer()
		end)
		if ok then
			update(snapshot)
		end
	end)
end

function LockerController.start()
	if started then
		return
	end
	started = true

	Players.LocalPlayer:WaitForChild("PlayerGui")
	UIController.start()
	local panel = UIController.createToolPanel("LockerPanel", "Locker", UDim2.fromOffset(312, 330))
	panel:SetAttribute("LegacyGuiName", "GolfProLockerGui")
	panel.BackgroundColor3 = Color3.fromRGB(25, 31, 30)
	panel.BackgroundTransparency = 0.08

	makeLabel(panel, "title", 8, "Locker")
	makeLabel(panel, "equipped", 30, "Ball: classic_white_ball  Trail: classic_arc_trail")
	makeLabel(panel, "profile", 52, "Title: starter_title  Banner: clubhouse_banner")

	local frame = Instance.new("Frame")
	frame.Name = "CosmeticList"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(292, 248)
	frame.Position = UDim2.fromOffset(10, 76)
	frame.Parent = panel
	listFrame = frame

	bindRemote("CosmeticInventoryUpdated", update)
	requestSnapshot()
end

function LockerController.getDebugState()
	return latestSnapshot
end

return LockerController
