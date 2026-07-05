--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MysteryRangeController = {}

local started = false
local labels: { [string]: TextLabel? } = {}
local latestSnapshot: any = nil

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

local function update(snapshot: any)
	latestSnapshot = snapshot
	if type(snapshot) ~= "table" then
		return
	end
	setText("tokens", "Tokens: " .. tostring(snapshot.rangeTokens or 0))
	setText(
		"meter",
		("Meter: %d / %d"):format(snapshot.discoveryMeter or 0, snapshot.meterCapacity or 100)
	)
	local zones = snapshot.unlockedZones or {}
	setText(
		"zones",
		("Zones: S%s C%s D%s"):format(
			if zones.starter then "+" else "-",
			if zones.canyon then "+" else "-",
			if zones.deep_green then "+" else "-"
		)
	)
end

local function fire(name: string, payload: any)
	local remote = remoteEvent(name)
	if remote ~= nil then
		remote:FireServer(payload)
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
	label.Size = UDim2.fromOffset(286, 20)
	label.Position = UDim2.fromOffset(10, y)
	label.Text = text
	label.Parent = parent
	labels[key] = label
	return label
end

local function makeButton(parent: Instance, text: string, x: number, y: number, callback: () -> ())
	local button = Instance.new("TextButton")
	button.Name = text:gsub("%s+", "")
	button.BackgroundColor3 = Color3.fromRGB(70, 76, 42)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 11
	button.Size = UDim2.fromOffset(88, 24)
	button.Position = UDim2.fromOffset(x, y)
	button.Text = text
	button.Parent = parent
	button.Activated:Connect(callback)
	return button
end

local function requestSnapshot()
	task.spawn(function()
		local folder = ReplicatedStorage:WaitForChild("NexusRemotes", 10)
		if folder == nil then
			return
		end
		local remote = remoteFunction("RequestMysteryRangeSnapshot")
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

function MysteryRangeController.start()
	if started then
		return
	end
	started = true

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "GolfProMysteryRangeGui"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "MysteryRangePanel"
	panel.BackgroundColor3 = Color3.fromRGB(28, 30, 24)
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel = 0
	panel.Size = UDim2.fromOffset(306, 178)
	panel.Position = UDim2.fromOffset(828, 82)
	panel.Parent = gui

	makeLabel(panel, "title", 8, "Mystery Range")
	makeLabel(panel, "tokens", 29, "Tokens: 0")
	makeLabel(panel, "meter", 50, "Meter: 0 / 100")
	makeLabel(panel, "zones", 71, "Zones: S+ C- D-")
	makeLabel(panel, "message", 92, "")

	makeButton(panel, "Deposit", 10, 119, function()
		fire("RequestMysteryRangeDeposit", {})
	end)
	makeButton(panel, "Canyon", 104, 119, function()
		fire("RequestMysteryRangeUpgrade", { upgradeId = "unlock_canyon" })
	end)
	makeButton(panel, "Deep", 198, 119, function()
		fire("RequestMysteryRangeUpgrade", { upgradeId = "unlock_deep_green" })
	end)
	makeButton(panel, "Meter+", 10, 147, function()
		fire("RequestMysteryRangeUpgrade", { upgradeId = "meter_capacity_2" })
	end)

	bindRemote("MysteryRangeUpdated", update)
	bindRemote("MysteryRangeRewardRevealed", function(payload: any)
		setText("message", "Reward: " .. tostring(payload.shardId or payload.tokens or "tokens"))
		if payload.snapshot ~= nil then
			update(payload.snapshot)
		end
	end)
	requestSnapshot()
end

function MysteryRangeController.getDebugState()
	return latestSnapshot
end

return MysteryRangeController
