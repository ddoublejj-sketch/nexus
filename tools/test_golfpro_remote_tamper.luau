--!strict

local fs = require("@lune/fs")
local Constants = require("../src/ReplicatedStorage/Shared/GolfPro/Constants")
local CosmeticService = require("../src/ServerScriptService/Server/Services/CosmeticService")
local LeaderboardService = require("../src/ServerScriptService/Server/Services/LeaderboardService")
local MysteryRangeService =
	require("../src/ServerScriptService/Server/Services/MysteryRangeService")
local RecordService = require("../src/ServerScriptService/Server/Services/RecordService")
local RoundService = require("../src/ServerScriptService/Server/Services/RoundService")
local ShotService = require("../src/ServerScriptService/Server/Services/ShotService")
local TournamentService = require("../src/ServerScriptService/Server/Services/TournamentService")

local function assertEqual(actual: any, expected: any, label: string)
	if actual ~= expected then
		error(("%s: expected %s, got %s"):format(label, tostring(expected), tostring(actual)))
	end
end

local function assertTrue(condition: boolean, label: string)
	if not condition then
		error(label)
	end
end

local function intent(round: any, player: any, nonce: string, overrides: any?): any
	local payload = {
		roundId = round.id,
		holeIndex = round.holeIndex,
		playerUserId = player.UserId,
		clubId = "driver",
		shotType = Constants.ShotType.NORMAL,
		aimYawDeg = 0,
		aimPitchDeg = 0,
		power01 = 0.6,
		accuracy01 = 0.5,
		spin01 = 0,
		drawFade01 = 0,
		clientShotNonce = nonce,
		clientTimestamp = 1,
		claimedScore = -100,
	}
	for key, value in overrides or {} do
		payload[key] = value
	end
	return payload
end

local function context(): any
	return {
		courseId = Constants.DEFAULT_COURSE_ID,
		courseVersion = "v1",
		mode = Constants.Mode.SOLO_STROKE_18,
		teeSet = Constants.DEFAULT_TEE_SET,
		pinSet = Constants.DEFAULT_PIN_SET,
		rulesetId = Constants.DEFAULT_RULESET_ID,
		physicsVersion = Constants.PHYSICS_VERSION,
	}
end

RoundService.resetForTests()
ShotService.resetForTests()
LeaderboardService.resetForTests()
RecordService.resetForTests()
CosmeticService.resetForTests()
MysteryRangeService.resetForTests()
TournamentService.resetForTests()

local player = { UserId = 9301, Name = "TamperTester" }
local other = { UserId = 9302, Name = "WrongTurn" }
local startOk, round = RoundService.startRound(player, {
	mode = Constants.Mode.SOLO_STROKE_18,
	courseId = Constants.DEFAULT_COURSE_ID,
	teeSet = Constants.DEFAULT_TEE_SET,
	pinSet = Constants.DEFAULT_PIN_SET,
	ranked = false,
})
assertEqual(startOk, true, "round starts")

local invalidOk, invalidReason = ShotService.submitShot(player, { roundId = round.id }, 10)
assertEqual(invalidOk, false, "invalid shot rejected")
assertTrue(
	tostring(invalidReason):find(Constants.Rejection.INVALID_PAYLOAD, 1, true) ~= nil,
	"invalid payload reason"
)

local wrongOk, wrongReason = ShotService.submitShot(other, intent(round, other, "wrong_turn"), 11)
assertEqual(wrongOk, false, "wrong turn rejected")
assertEqual(wrongReason, Constants.Rejection.NO_ROUND, "wrong turn cannot use another round")

assertEqual(
	select(1, ShotService.submitShot(player, intent(round, player, "nonce_one"), 12)),
	true,
	"first shot accepted"
)
local duplicateOk, duplicateReason =
	ShotService.submitShot(player, intent(round, player, "nonce_one"), 13)
assertEqual(duplicateOk, false, "duplicate nonce rejected")
assertEqual(duplicateReason, Constants.Rejection.DUPLICATE_NONCE, "duplicate nonce reason")

local clientClaimResult = {
	ranked = true,
	completed = true,
	holeCount = 18,
	totalScore = 72,
	claimedScore = -99,
	completedAtUnix = 3000,
	playerUserId = player.UserId,
	playerName = player.Name,
	roundId = "client_claim_ignored",
}
assertEqual(
	select(1, LeaderboardService.submitRound(context(), clientClaimResult)),
	true,
	"server leaderboard submit accepts valid result"
)
assertEqual(
	LeaderboardService.getPage(context(), { pageSize = 1 }).rows[1].score,
	72,
	"client score claim ignored by leaderboard"
)
assertEqual(
	RecordService.tryUpdateCourseRecord(context(), clientClaimResult).current.score,
	72,
	"client score claim ignored by record"
)

local netSource = fs.readFile("src/ReplicatedStorage/Shared/Net/init.luau")
assertTrue(
	netSource:find("SubmitLeaderboard", 1, true) == nil,
	"no client leaderboard write remote"
)
assertTrue(
	netSource:find("SubmitCourseRecord", 1, true) == nil,
	"no client course-record write remote"
)

local unownedOk, unownedReason = CosmeticService.equipCosmetic(player, "sunrise_gold_ball")
assertEqual(unownedOk, false, "unowned cosmetic rejected")
assertEqual(unownedReason, "not_owned", "unowned cosmetic reason")

local lockedOk, lockedReason = MysteryRangeService.recordTargetHit(player, { zoneId = "canyon" })
assertEqual(lockedOk, false, "locked Mystery Range zone rejected")
assertEqual(lockedReason, "zone_locked", "locked zone reason")

local tournamentOk, tournamentReason = TournamentService.submitAttempt(player, "weekend_open_001", {
	ranked = false,
	completed = true,
	holeCount = 18,
	totalScore = 70,
})
assertEqual(tournamentOk, false, "invalid tournament attempt rejected")
assertEqual(tournamentReason, "invalid_ranked_completion", "invalid tournament reason")

print("Golf Pro remote tamper tests passed")
