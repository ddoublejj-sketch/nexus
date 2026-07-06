--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIController = require(script.Parent.UIController)

local ScrambleController = {}

local started = false
local latestVote: any = nil
local panel: Frame? = nil
local titleLabel: TextLabel? = nil
local selectedLabel: TextLabel? = nil
local buttonsFrame: Frame? = nil

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

local function ensureGui()
	if panel ~= nil then
		return
	end

	Players.LocalPlayer:WaitForChild("PlayerGui")
	UIController.start()
	local frame = UIController.createOverlayPanel("ScramblePanel", UDim2.fromOffset(450, 150))
	frame:SetAttribute("LegacyGuiName", "GolfProScrambleGui")
	frame.BackgroundColor3 = Color3.fromRGB(28, 38, 45)
	frame.BackgroundTransparency = 0.08
	frame.Visible = false
	panel = frame

	local title = Instance.new("TextLabel")
	title.Name = "VoteTitle"
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.fromRGB(246, 248, 245)
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Size = UDim2.fromOffset(430, 20)
	title.Position = UDim2.fromOffset(10, 8)
	title.Text = "Scramble Vote"
	title.Parent = frame
	titleLabel = title

	local selected = Instance.new("TextLabel")
	selected.Name = "SelectedVote"
	selected.BackgroundTransparency = 1
	selected.Font = Enum.Font.GothamMedium
	selected.TextColor3 = Color3.fromRGB(246, 248, 245)
	selected.TextSize = 12
	selected.TextXAlignment = Enum.TextXAlignment.Left
	selected.Size = UDim2.fromOffset(430, 18)
	selected.Position = UDim2.fromOffset(10, 31)
	selected.Text = "Selected: --"
	selected.Parent = frame
	selectedLabel = selected

	local options = Instance.new("Frame")
	options.Name = "VoteOptions"
	options.BackgroundTransparency = 1
	options.Size = UDim2.fromOffset(430, 88)
	options.Position = UDim2.fromOffset(10, 55)
	options.Parent = frame
	buttonsFrame = options
end

local function clearOptionButtons()
	local parent = buttonsFrame
	if parent == nil then
		return
	end

	for _, child in parent:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function optionLabel(option: any): string
	local distance = if type(option.distanceToPinYards) == "number"
		then tostring(math.floor(option.distanceToPinYards + 0.5)) .. " yd"
		else "-- yd"
	local suffix = ""
	if option.penalty == true then
		suffix ..= " PEN"
	end
	if option.holed == true then
		suffix ..= " HOLED"
	end

	return tostring(option.playerUserId)
		.. " "
		.. tostring(option.surface)
		.. " "
		.. distance
		.. suffix
end

function ScrambleController.start()
	if started then
		return
	end

	started = true
	ensureGui()
	bindRemote("ScrambleVoteUpdated", function(payload: any)
		ScrambleController.showVote(payload)
	end)
end

function ScrambleController.showVote(payload: any)
	ensureGui()
	latestVote = payload
	local frame = panel :: Frame
	if type(payload) ~= "table" or type(payload.options) ~= "table" or #payload.options == 0 then
		frame.Visible = false
		return
	end

	frame.Visible = true
	if titleLabel ~= nil then
		titleLabel.Text = "Team "
			.. tostring(payload.teamId)
			.. " hole "
			.. tostring(payload.holeIndex)
			.. " cycle "
			.. tostring(payload.shotCycle)
	end
	if selectedLabel ~= nil then
		selectedLabel.Text = "Selected: " .. tostring(payload.selectedBallId or "--")
	end

	clearOptionButtons()
	local parent = buttonsFrame :: Frame
	for index, option in payload.options do
		local button = Instance.new("TextButton")
		button.Name = "Option" .. tostring(index)
		button.BackgroundColor3 = Color3.fromRGB(58, 82, 68)
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamMedium
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextSize = 11
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.Size = UDim2.fromOffset(430, 24)
		button.Position = UDim2.fromOffset(0, (index - 1) * 28)
		button.Text = "  " .. optionLabel(option)
		button.Parent = parent
		button.Activated:Connect(function()
			ScrambleController.submitVote(option.ballId)
		end)
	end
end

function ScrambleController.submitVote(ballId: string)
	if type(latestVote) ~= "table" then
		return
	end

	local remote = remoteEvent("RequestScrambleBallVote")
	if remote == nil then
		return
	end

	remote:FireServer({
		roundId = latestVote.roundId,
		holeIndex = latestVote.holeIndex,
		shotCycle = latestVote.shotCycle,
		selectedBallId = ballId,
	})
end

function ScrambleController.getDebugState()
	return {
		vote = latestVote,
		hasPanel = panel ~= nil,
		visible = panel ~= nil and (panel :: Frame).Visible,
	}
end

return ScrambleController
