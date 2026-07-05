--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClubRegistry = require(ReplicatedStorage.Shared.GolfPro.Clubs.ClubRegistry)
local Constants = require(ReplicatedStorage.Shared.GolfPro.Constants)
local SwingController = require(script.Parent.SwingController)

local HUDController = {}

local started = false
local labels: { [string]: TextLabel } = {}

local function remoteEvent(name: string): RemoteEvent?
	local folder = ReplicatedStorage:FindFirstChild("NexusRemotes")
	if folder == nil then
		return nil
	end

	local remote = folder:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end

	return nil
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

local function makeLabel(parent: Instance, key: string, order: number, text: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = key
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextColor3 = Color3.fromRGB(246, 248, 245)
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Size = UDim2.fromOffset(260, 22)
	label.Position = UDim2.fromOffset(12, 12 + order * 24)
	label.Text = text
	label.Parent = parent
	labels[key] = label

	return label
end

local function fireRoundStart(mode: string, courseId: string)
	local remote = remoteEvent("RequestStartPrivateRound")
	if remote == nil then
		return
	end

	remote:FireServer({
		mode = mode,
		courseId = courseId,
		teeSet = Constants.DEFAULT_TEE_SET,
		pinSet = Constants.DEFAULT_PIN_SET,
		ranked = false,
	})
end

local function makeButton(parent: Instance, text: string, x: number, y: number, callback: () -> ())
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = Color3.fromRGB(22, 86, 62)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 13
	button.Size = UDim2.fromOffset(82, 28)
	button.Position = UDim2.fromOffset(x, y)
	button.Text = text
	button.Parent = parent
	button.Activated:Connect(callback)
end

local function updateRound(snapshot: any)
	SwingController.setRoundSnapshot(snapshot)
	labels.lie.Text = "Lie: " .. tostring(snapshot.ball.surface)
	labels.distance.Text = "Hole: "
		.. tostring(snapshot.holeIndex)
		.. " / "
		.. tostring(snapshot.holeCount)
	labels.state.Text = "State: " .. tostring(snapshot.state)
end

function HUDController.start()
	if started then
		return
	end

	started = true
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "GolfProHUD"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.BackgroundColor3 = Color3.fromRGB(15, 31, 28)
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel = 0
	panel.Size = UDim2.fromOffset(300, 224)
	panel.Position = UDim2.fromOffset(18, 82)
	panel.Parent = gui

	makeLabel(panel, "club", 0, "Club: Driver")
	makeLabel(panel, "distance", 1, "Hole: --")
	makeLabel(panel, "lie", 2, "Lie: tee")
	makeLabel(panel, "wind", 3, "Wind: daily")
	makeLabel(panel, "state", 4, "State: idle")
	makeLabel(panel, "score", 5, "Score: E")

	makeButton(panel, "Practice", 12, 160, function()
		fireRoundStart(Constants.Mode.PRACTICE, Constants.DEFAULT_PRACTICE_COURSE_ID)
	end)
	makeButton(panel, "3 Holes", 104, 160, function()
		fireRoundStart(Constants.Mode.SOLO_STROKE_3_DEBUG, Constants.DEFAULT_COURSE_ID)
	end)

	local x = 12
	for _, club in ClubRegistry.all() do
		makeButton(panel, club.displayName, x, 192, function()
			SwingController.setClub(club.id)
			labels.club.Text = "Club: " .. club.displayName
		end)
		x += 92
		if x > 196 then
			break
		end
	end

	bindRemote("RoundStateUpdated", updateRound)
	bindRemote("BallAtRest", function(payload: any)
		labels.lie.Text = "Lie: " .. tostring(payload.surface)
	end)
	bindRemote("ScorecardUpdated", function(payload: any)
		labels.score.Text = "Score: " .. tostring(payload.total)
	end)
	bindRemote("ShotRejected", function(payload: any)
		labels.state.Text = "Rejected: " .. tostring(payload.reasonCode)
	end)
end

return HUDController
