--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TournamentController = {}

local started = false
local labels: { [string]: TextLabel? } = {}
local latestEvents: any = nil
local latestLeaderboard: any = nil

local function remotesFolder(): Folder?
	return ReplicatedStorage:FindFirstChild("NexusRemotes") :: Folder?
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
	label.Size = UDim2.fromOffset(296, 20)
	label.Position = UDim2.fromOffset(10, y)
	label.Text = text
	label.Parent = parent
	labels[key] = label
	return label
end

local function updateLeaderboard(leaderboard: any)
	latestLeaderboard = leaderboard
	if type(leaderboard) ~= "table" or type(leaderboard.rows) ~= "table" then
		setText("leaderboard", "Leaderboard: no scores yet")
		return
	end
	if #leaderboard.rows == 0 then
		setText("leaderboard", "Leaderboard: no scores yet")
		return
	end
	local parts = {}
	for _, row in leaderboard.rows do
		table.insert(parts, ("#%d %s %s"):format(row.rank, row.playerName, row.score))
		if #parts >= 3 then
			break
		end
	end
	setText("leaderboard", "Leaderboard: " .. table.concat(parts, " | "))
end

local function requestLeaderboard(eventId: string)
	task.spawn(function()
		local remote = remoteFunction("RequestTournamentLeaderboard")
		if remote == nil then
			return
		end
		local ok, leaderboard = pcall(function()
			return remote:InvokeServer({ eventId = eventId })
		end)
		if ok then
			updateLeaderboard(leaderboard)
		end
	end)
end

local function updateEvents(events: any)
	if type(events) == "table" and events.events ~= nil then
		events = events.events
	end
	latestEvents = events
	if type(events) ~= "table" or events[1] == nil then
		setText("event", "Event: none")
		setText("attempts", "Attempts: 0 / 0")
		setText("reward", "Reward: cosmetic")
		return
	end
	local event = events[1]
	setText("event", ("Event: %s - %s"):format(event.displayName, event.courseName))
	setText(
		"attempts",
		("Attempts: %d / %d"):format(event.attemptsUsed or 0, event.maxAttempts or 0)
	)
	setText("reward", "Reward: " .. tostring(event.rewardDescription or "cosmetic"))
	requestLeaderboard(event.id)
end

local function requestEvents()
	task.spawn(function()
		local folder = ReplicatedStorage:WaitForChild("NexusRemotes", 10)
		if folder == nil then
			return
		end
		local remote = remoteFunction("RequestTournamentEvents")
		if remote == nil then
			return
		end
		local ok, events = pcall(function()
			return remote:InvokeServer()
		end)
		if ok then
			updateEvents(events)
		end
	end)
end

function TournamentController.start()
	if started then
		return
	end
	started = true

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "GolfProTournamentGui"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "TournamentPanel"
	panel.BackgroundColor3 = Color3.fromRGB(31, 29, 37)
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel = 0
	panel.Size = UDim2.fromOffset(316, 134)
	panel.Position = UDim2.fromOffset(340, 300)
	panel.Parent = gui

	makeLabel(panel, "title", 8, "Tournament")
	makeLabel(panel, "event", 30, "Event: Weekend Open")
	makeLabel(panel, "attempts", 52, "Attempts: 0 / 3")
	makeLabel(panel, "reward", 74, "Reward: Pin Seeker title")
	makeLabel(panel, "leaderboard", 96, "Leaderboard: no scores yet")

	bindRemote("TournamentUpdated", function(payload: any)
		updateEvents(payload)
	end)
	requestEvents()
end

function TournamentController.getDebugState()
	return {
		events = latestEvents,
		leaderboard = latestLeaderboard,
	}
end

return TournamentController
