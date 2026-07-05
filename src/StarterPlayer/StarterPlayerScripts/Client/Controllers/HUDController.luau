--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClubRegistry = require(ReplicatedStorage.Shared.GolfPro.Clubs.ClubRegistry)
local Constants = require(ReplicatedStorage.Shared.GolfPro.Constants)
local EquipmentController = require(script.Parent.EquipmentController)
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

local function wholeYards(value: any): string
	if type(value) ~= "number" then
		return "--"
	end

	return tostring(math.floor(value + 0.5)) .. " yd"
end

local function formatToPar(value: any): string
	local score = tonumber(value)
	if score == nil then
		return "--"
	end
	if score == 0 then
		return "E"
	end
	if score > 0 then
		return "+" .. tostring(score)
	end
	return tostring(score)
end

local function recordText(recordPayload: any): string
	local record = recordPayload
	if type(recordPayload) == "table" then
		record = recordPayload.current or recordPayload.record or recordPayload
	end
	if type(record) ~= "table" then
		return Constants.UNCLAIMED_RECORD_DISPLAY
	end
	if record.label ~= nil then
		return tostring(record.label)
	end
	if record.unclaimed == true then
		return Constants.UNCLAIMED_RECORD_DISPLAY
	end
	return "Course Record: "
		.. tostring(record.score or 0)
		.. " / "
		.. tostring(record.holderName or "Unclaimed")
end

local function makeLabel(parent: Instance, key: string, order: number, text: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = key
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextColor3 = Color3.fromRGB(246, 248, 245)
	label.TextSize = 15
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Size = UDim2.fromOffset(300, 20)
	label.Position = UDim2.fromOffset(12, 12 + order * 21)
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
	button.Size = UDim2.fromOffset(86, 28)
	button.Position = UDim2.fromOffset(x, y)
	button.Text = text
	button.Parent = parent
	button.Activated:Connect(callback)

	return button
end

local function makeClubButton(parent: Instance, text: string, callback: () -> ())
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = Color3.fromRGB(26, 74, 72)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 12
	button.Size = UDim2.fromOffset(88, 28)
	button.Text = text
	button.Parent = parent
	button.Activated:Connect(callback)

	return button
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

local function updateShotStats(payload: any)
	if type(payload) ~= "table" or type(payload.result) ~= "table" then
		return
	end

	local result = payload.result
	labels.lastShot.Text = "Last Shot: " .. tostring(payload.shotId or "shot")
	labels.carry.Text = "Carry: " .. wholeYards(result.carryYards)
	labels.roll.Text = "Roll: " .. wholeYards(result.rollYards)
	labels.total.Text = "Total: " .. wholeYards(result.totalYards)
	labels.offline.Text = "Offline: " .. wholeYards(result.lateralOffsetYards)
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
	panel.Size = UDim2.fromOffset(324, 428)
	panel.Position = UDim2.fromOffset(18, 82)
	panel.Parent = gui

	makeLabel(panel, "club", 0, "Club: Driver")
	makeLabel(panel, "distance", 1, "Hole: --")
	makeLabel(panel, "lie", 2, "Lie: tee")
	makeLabel(panel, "wind", 3, "Wind: daily")
	makeLabel(panel, "state", 4, "State: idle")
	makeLabel(panel, "score", 5, "Score: E")
	makeLabel(panel, "lastShot", 6, "Last Shot: --")
	makeLabel(panel, "carry", 7, "Carry: --")
	makeLabel(panel, "roll", 8, "Roll: --")
	makeLabel(panel, "total", 9, "Total: --")
	makeLabel(panel, "offline", 10, "Offline: --")
	makeLabel(panel, "final", 11, "Final: --")
	makeLabel(panel, "leaderboard", 12, "Leaderboard: --")
	makeLabel(panel, "record", 13, Constants.UNCLAIMED_RECORD_DISPLAY)

	makeButton(panel, "Practice", 12, 316, function()
		fireRoundStart(Constants.Mode.PRACTICE, Constants.DEFAULT_PRACTICE_COURSE_ID)
	end)
	makeButton(panel, "3 Holes", 106, 316, function()
		fireRoundStart(Constants.Mode.SOLO_STROKE_3_DEBUG, Constants.DEFAULT_COURSE_ID)
	end)

	local clubScroll = Instance.new("ScrollingFrame")
	clubScroll.Name = "ClubScroll"
	clubScroll.BackgroundColor3 = Color3.fromRGB(10, 24, 22)
	clubScroll.BackgroundTransparency = 0.1
	clubScroll.BorderSizePixel = 0
	clubScroll.CanvasSize = UDim2.fromOffset(0, 154)
	clubScroll.ScrollBarThickness = 6
	clubScroll.Size = UDim2.fromOffset(300, 68)
	clubScroll.Position = UDim2.fromOffset(12, 344)
	clubScroll.Parent = panel

	local grid = Instance.new("UIGridLayout")
	grid.CellPadding = UDim2.fromOffset(6, 6)
	grid.CellSize = UDim2.fromOffset(88, 28)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = clubScroll

	for index, club in ClubRegistry.all() do
		local button = makeClubButton(clubScroll, club.displayName, function()
			SwingController.setClub(club.id)
			EquipmentController.setClub(club.id)
			labels.club.Text = "Club: " .. club.displayName
		end)
		button.LayoutOrder = index
	end

	EquipmentController.setClub("driver")
	bindRemote("RoundStateUpdated", updateRound)
	bindRemote("BallPath", updateShotStats)
	bindRemote("BallAtRest", function(payload: any)
		labels.lie.Text = "Lie: " .. tostring(payload.surface)
	end)
	bindRemote("ScorecardUpdated", function(payload: any)
		labels.score.Text = "Score: " .. tostring(payload.total)
	end)
	bindRemote("RoundCompleted", function(payload: any)
		local result = payload.result or {}
		labels.final.Text = "Final: "
			.. tostring(result.totalScore or "--")
			.. " ("
			.. formatToPar(result.toPar)
			.. ")"
		labels.leaderboard.Text = if payload.leaderboardAccepted == true
			then "Leaderboard: Accepted"
			else "Leaderboard: Rejected " .. tostring(payload.leaderboardRejectedReason or "")
		labels.record.Text = recordText(payload.courseRecordDisplay or payload.courseRecord)
	end)
	bindRemote("CourseRecordUpdated", function(payload: any)
		labels.record.Text = recordText(payload)
	end)
	bindRemote("ShotRejected", function(payload: any)
		labels.state.Text = "Rejected: " .. tostring(payload.reasonCode)
	end)
end

return HUDController
