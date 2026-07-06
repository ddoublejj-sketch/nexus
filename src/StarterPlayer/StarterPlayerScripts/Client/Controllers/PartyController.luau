--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.GolfPro.Constants)
local SwingController = require(script.Parent.SwingController)

local PartyController = {}

local started = false
local latestParty: any = nil
local latestMatch: any = nil
local latestScrambleVote: any = nil
local gui: ScreenGui? = nil
local labels: { [string]: any } = {}
local joinBox: TextBox? = nil

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

local function fire(name: string, ...)
	local remote = remoteEvent(name)
	if remote ~= nil then
		remote:FireServer(...)
	end
end

local function defaultPayload(mode: string): any
	return {
		mode = mode,
		courseId = Constants.DEFAULT_COURSE_ID,
		teeSet = Constants.DEFAULT_TEE_SET,
		pinSet = Constants.DEFAULT_PIN_SET,
		ranked = false,
	}
end

local function localMember(): any?
	if latestParty == nil or type(latestParty.members) ~= "table" then
		return nil
	end

	local userId = Players.LocalPlayer.UserId
	for _, member in latestParty.members do
		if member.userId == userId then
			return member
		end
	end

	return nil
end

local function memberLine(member: any): string
	local ready = if member.ready then "ready" else "wait"
	local team = if member.teamId ~= nil then " " .. tostring(member.teamId) else ""
	return ("%s:%s%s"):format(tostring(member.displayName or member.userId), ready, team)
end

local function updateLabels()
	if labels.code == nil then
		return
	end

	if latestParty == nil then
		labels.code.Text = "Party: none"
		labels.mode.Text = "Mode: --"
		labels.members.Text = "Members: --"
	else
		labels.code.Text = "Party: "
			.. tostring(latestParty.code)
			.. " "
			.. tostring(latestParty.status)
		labels.mode.Text = "Mode: " .. tostring(latestParty.desiredMode)
		local parts = {}
		for index, member in latestParty.members do
			parts[index] = memberLine(member)
		end
		labels.members.Text = "Members: " .. table.concat(parts, " | ")
	end

	if latestMatch == nil then
		labels.match.Text = "Match: --"
	else
		labels.match.Text = "Match: "
			.. tostring(latestMatch.mode)
			.. " "
			.. tostring(latestMatch.transport)
	end

	if latestScrambleVote ~= nil then
		labels.scramble.Text = "Scramble: "
			.. tostring(latestScrambleVote.teamId)
			.. " cycle "
			.. tostring(latestScrambleVote.shotCycle)
	else
		labels.scramble.Text = "Scramble: --"
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
	label.Size = UDim2.fromOffset(430, 20)
	label.Position = UDim2.fromOffset(10, y)
	label.Text = text
	label.Parent = parent
	labels[key] = label
	return label
end

local function makeButton(parent: Instance, text: string, x: number, y: number, callback: () -> ())
	local button = Instance.new("TextButton")
	button.Name = text:gsub("%s+", "")
	button.BackgroundColor3 = Color3.fromRGB(42, 79, 96)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 12
	button.Size = UDim2.fromOffset(92, 26)
	button.Position = UDim2.fromOffset(x, y)
	button.Text = text
	button.Parent = parent
	button.Activated:Connect(callback)
	return button
end

local function ensureGui()
	if gui ~= nil then
		return
	end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild("GolfProPartyGui")
	if existing and existing:IsA("ScreenGui") then
		gui = existing
		return
	end

	local screen = Instance.new("ScreenGui")
	screen.Name = "GolfProPartyGui"
	screen.ResetOnSpawn = false
	screen.Parent = playerGui
	gui = screen

	local panel = Instance.new("Frame")
	panel.Name = "PartyPanel"
	panel.BackgroundColor3 = Color3.fromRGB(17, 29, 36)
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel = 0
	panel.Size = UDim2.fromOffset(450, 210)
	panel.Position = UDim2.fromOffset(360, 82)
	panel.Parent = screen

	makeLabel(panel, "code", 8, "Party: none")
	makeLabel(panel, "mode", 29, "Mode: --")
	makeLabel(panel, "members", 50, "Members: --")
	makeLabel(panel, "match", 71, "Match: --")
	makeLabel(panel, "scramble", 92, "Scramble: --")
	makeLabel(panel, "message", 113, "")

	local box = Instance.new("TextBox")
	box.Name = "JoinCode"
	box.BackgroundColor3 = Color3.fromRGB(9, 18, 22)
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.GothamMedium
	box.PlaceholderText = "CODE"
	box.Text = ""
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.TextSize = 12
	box.Size = UDim2.fromOffset(92, 26)
	box.Position = UDim2.fromOffset(106, 139)
	box.Parent = panel
	joinBox = box

	makeButton(panel, "Create", 10, 139, function()
		PartyController.createParty()
	end)
	makeButton(panel, "Join", 204, 139, function()
		PartyController.joinByCode(if joinBox ~= nil then joinBox.Text else "")
	end)
	makeButton(panel, "Leave", 302, 139, function()
		PartyController.leaveParty()
	end)
	makeButton(panel, "Ready", 10, 173, function()
		local member = localMember()
		PartyController.setReady(not (member and member.ready == true))
	end)
	makeButton(panel, "Private 18", 106, 173, function()
		PartyController.startPrivateRound(Constants.Mode.PRIVATE_STROKE)
	end)
	makeButton(panel, "2v2 Scramble", 204, 173, function()
		PartyController.startPrivateRound(Constants.Mode.SCRAMBLE_2V2)
	end)
	makeButton(panel, "Red", 302, 173, function()
		PartyController.setTeam(Constants.TeamId.RED)
	end)
	makeButton(panel, "Blue", 362, 173, function()
		PartyController.setTeam(Constants.TeamId.BLUE)
	end).Size =
		UDim2.fromOffset(78, 26)
end

function PartyController.start()
	if started then
		return
	end

	started = true
	ensureGui()
	bindRemote("PartyUpdated", function(payload: any)
		latestParty = payload
		updateLabels()
	end)
	bindRemote("MatchFound", function(payload: any)
		latestMatch = payload
		if payload.mode == Constants.Mode.SCRAMBLE_2V2 then
			SwingController.setRoundSnapshot({
				roundId = payload.roundId,
				mode = Constants.Mode.SCRAMBLE_2V2,
				holeIndex = 1,
				holeCount = 18,
				state = Constants.RoundState.PRE_SHOT,
				ball = {
					surface = Constants.Surface.TEE,
					moving = false,
				},
			})
		end
		updateLabels()
	end)
	bindRemote("ScrambleVoteUpdated", function(payload: any)
		latestScrambleVote = payload
		updateLabels()
	end)
	bindRemote("SystemMessage", function(message: string, _detail: any)
		if labels.message ~= nil then
			labels.message.Text = tostring(message)
		end
	end)
end

function PartyController.createParty()
	fire("RequestCreateParty")
end

function PartyController.joinByCode(code: string)
	fire("RequestJoinPartyCode", { code = code })
end

function PartyController.leaveParty()
	fire("RequestLeaveParty", {})
end

function PartyController.setReady(ready: boolean)
	fire("RequestPartyReady", { ready = ready })
end

function PartyController.configure(payload: any)
	fire("RequestPartyConfigure", payload)
end

function PartyController.setTeam(teamId: string)
	fire("RequestPartyTeam", { teamId = teamId })
end

function PartyController.startPrivateRound(mode: string?)
	local selectedMode = mode
		or (latestParty and latestParty.desiredMode)
		or Constants.Mode.PRIVATE_STROKE
	local payload = defaultPayload(selectedMode)
	if latestParty ~= nil then
		PartyController.configure(payload)
	end
	fire("RequestStartPrivateRound", payload)
end

function PartyController.getDebugState()
	return {
		party = latestParty,
		match = latestMatch,
		scrambleVote = latestScrambleVote,
	}
end

return PartyController
