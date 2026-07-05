--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage.Shared.GolfPro.Constants)

local SwingController = {}

local activeRound: any = nil
local currentClubId = "driver"
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
end

function SwingController.getState()
	return state
end

function SwingController.click(now: number): any?
	if state.phase == "idle" then
		state.phase = "power"
		state.powerStartedAt = now
		return nil
	end

	if state.phase == "power" then
		state.phase = "accuracy"
		state.power01 = triangle01(now - state.powerStartedAt, 1.6)
		state.accuracyStartedAt = now
		return nil
	end

	if state.phase == "accuracy" then
		state.phase = "idle"
		state.accuracy01 = triangle01(now - state.accuracyStartedAt, 1.1)
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
