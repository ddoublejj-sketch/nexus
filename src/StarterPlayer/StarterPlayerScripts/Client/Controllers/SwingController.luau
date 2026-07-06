--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage.Shared.GolfPro.Constants)
local EquipmentController = require(script.Parent.EquipmentController)

local SwingController = {}

local activeRound: any = nil
local currentClubId = "driver"
local meterFrame: Frame? = nil
local meterFill: Frame? = nil
local meterLabel: TextLabel? = nil
local state = {
	phase = "idle",
	powerStartedAt = 0,
	accuracyStartedAt = 0,
	power01 = 0,
	accuracy01 = 0.5,
}
local started = false

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

local function triangle01(elapsed: number, period: number): number
	local t = (elapsed % period) / period
	return if t <= 0.5 then t * 2 else (1 - t) * 2
end

local function ensureSwingMeter()
	if meterFrame ~= nil then
		return
	end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local screen = Instance.new("ScreenGui")
	screen.Name = "GolfProSwingMeterGui"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "SwingMeter"
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.BackgroundColor3 = Color3.fromRGB(9, 18, 16)
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Position = UDim2.new(0.5, 0, 1, -42)
	frame.Size = UDim2.fromOffset(360, 42)
	frame.Visible = false
	frame.Parent = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "Phase"
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = "POWER"
	label.TextColor3 = Color3.fromRGB(244, 248, 240)
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Position = UDim2.fromOffset(12, 5)
	label.Size = UDim2.fromOffset(120, 14)
	label.Parent = frame

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.BackgroundColor3 = Color3.fromRGB(31, 45, 39)
	track.BorderSizePixel = 0
	track.Position = UDim2.fromOffset(12, 24)
	track.Size = UDim2.new(1, -24, 0, 8)
	track.Parent = frame

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = Color3.fromRGB(232, 188, 91)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	fill.Parent = track

	meterFrame = frame
	meterFill = fill
	meterLabel = label
end

local function updateSwingMeter(now: number)
	ensureSwingMeter()
	local frame = meterFrame :: Frame
	local fill = meterFill :: Frame
	local label = meterLabel :: TextLabel
	if state.phase == "idle" then
		frame.Visible = false
		return
	end

	local elapsed = if state.phase == "power"
		then now - state.powerStartedAt
		else now - state.accuracyStartedAt
	local period = if state.phase == "power" then 1.6 else 1.1
	frame.Visible = true
	label.Text = if state.phase == "power" then "POWER" else "ACCURACY"
	fill.Size = UDim2.fromScale(triangle01(elapsed, period), 1)
end

local function shotTypeFor(clubId: string, lie: string): string
	if clubId == "putter" then
		return Constants.ShotType.PUTT
	end
	if lie == Constants.Surface.GREEN then
		return Constants.ShotType.CHIP
	end

	return Constants.ShotType.NORMAL
end

function SwingController.setRoundSnapshot(snapshot: any)
	activeRound = snapshot
end

function SwingController.setClub(clubId: string)
	currentClubId = clubId
	EquipmentController.setClub(clubId)
end

function SwingController.getState()
	return state
end

function SwingController.click(now: number): any?
	if state.phase == "idle" then
		state.phase = "power"
		state.powerStartedAt = now
		updateSwingMeter(now)
		EquipmentController.playBackswing(0)
		return nil
	end

	if state.phase == "power" then
		state.phase = "accuracy"
		state.power01 = triangle01(now - state.powerStartedAt, 1.6)
		state.accuracyStartedAt = now
		updateSwingMeter(now)
		EquipmentController.playBackswing(state.power01)
		return nil
	end

	if state.phase == "accuracy" then
		state.phase = "idle"
		state.accuracy01 = triangle01(now - state.accuracyStartedAt, 1.1)
		updateSwingMeter(now)
		EquipmentController.playStrike(state.accuracy01)
		return {
			power01 = state.power01,
			accuracy01 = state.accuracy01,
		}
	end

	return nil
end

function SwingController.buildIntent(swing: any): any?
	if activeRound == nil then
		return nil
	end

	local lie = activeRound.ball and activeRound.ball.surface or Constants.Surface.TEE
	local userId = Players.LocalPlayer.UserId
	return {
		roundId = activeRound.roundId,
		holeIndex = activeRound.holeIndex,
		playerUserId = userId,
		clubId = currentClubId,
		shotType = shotTypeFor(currentClubId, lie),
		aimYawDeg = 0,
		aimPitchDeg = 0,
		power01 = swing.power01,
		accuracy01 = swing.accuracy01,
		spin01 = 0,
		drawFade01 = 0,
		clientShotNonce = ("%d_%.3f"):format(userId, os.clock()),
		clientTimestamp = os.clock(),
	}
end

function SwingController.start()
	if started then
		return
	end

	started = true
	ensureSwingMeter()
	RunService.RenderStepped:Connect(function()
		updateSwingMeter(os.clock())
	end)
	UserInputService.InputBegan:Connect(function(input, processed: boolean)
		if processed then
			return
		end

		local isSwing = input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA
			or input.KeyCode == Enum.KeyCode.Space
		if not isSwing then
			return
		end
		if activeRound == nil then
			return
		end

		local swing = SwingController.click(os.clock())
		if swing == nil then
			return
		end

		local intent = SwingController.buildIntent(swing)
		local remote = remoteEvent("SubmitShotIntent")
		if intent ~= nil and remote ~= nil then
			remote:FireServer(intent)
		end
	end)
end

return SwingController
