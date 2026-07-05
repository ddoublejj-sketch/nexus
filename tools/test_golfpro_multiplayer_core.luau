--!strict

local Constants = require("../src/ReplicatedStorage/Shared/GolfPro/Constants")
local PartyService = require("../src/ServerScriptService/Server/Services/PartyService")
local MatchService = require("../src/ServerScriptService/Server/Services/MatchService")
local ScrambleService = require("../src/ServerScriptService/Server/Services/ScrambleService")
local RoundService = require("../src/ServerScriptService/Server/Services/RoundService")

local function assertTrue(condition: boolean, label: string)
	if not condition then
		error(label)
	end
end

local function assertFalse(condition: boolean, label: string)
	if condition then
		error(label)
	end
end

local function assertEqual(actual: any, expected: any, label: string)
	if actual ~= expected then
		error(("%s: expected %s, got %s"):format(label, tostring(expected), tostring(actual)))
	end
end

local function fakePlayer(userId: number, displayName: string): any
	return {
		UserId = userId,
		Name = displayName,
		DisplayName = displayName,
	}
end

local A = fakePlayer(101, "A")
local B = fakePlayer(202, "B")
local C = fakePlayer(303, "C")
local D = fakePlayer(404, "D")
local E = fakePlayer(505, "E")

local function privatePayload(): any
	return {
		mode = Constants.Mode.PRIVATE_STROKE,
		courseId = Constants.DEFAULT_COURSE_ID,
		teeSet = Constants.DEFAULT_TEE_SET,
		pinSet = Constants.DEFAULT_PIN_SET,
		ranked = false,
	}
end

local function scramblePayload(ranked: boolean?): any
	return {
		mode = Constants.Mode.SCRAMBLE_2V2,
		courseId = Constants.DEFAULT_COURSE_ID,
		teeSet = Constants.DEFAULT_TEE_SET,
		pinSet = Constants.DEFAULT_PIN_SET,
		ranked = ranked == true,
	}
end

local function resetAll()
	PartyService.resetForTests()
	MatchService.resetForTests()
	ScrambleService.resetForTests()
	RoundService.resetForTests()
end

local function memberByUserId(snapshot: any, userId: number): any?
	for _, member in snapshot.members do
		if member.userId == userId then
			return member
		end
	end

	return nil
end

local function includes(list: { number }, value: number): boolean
	for _, item in list do
		if item == value then
			return true
		end
	end

	return false
end

local function makePrivateParty(): any
	resetAll()
	local party = PartyService.createParty(A)
	assertTrue(select(1, PartyService.joinByCode(B, party.code)), "B join private party")
	assertTrue(select(1, PartyService.configure(A, privatePayload())), "configure private")
	assertTrue(select(1, PartyService.setReady(B, true)), "B ready private")
	return party
end

local function makeScrambleParty(): any
	resetAll()
	local party = PartyService.createParty(A)
	assertTrue(select(1, PartyService.joinByCode(B, party.code)), "B join scramble")
	assertTrue(select(1, PartyService.joinByCode(C, party.code)), "C join scramble")
	assertTrue(select(1, PartyService.joinByCode(D, party.code)), "D join scramble")
	assertTrue(select(1, PartyService.configure(A, scramblePayload(false))), "configure scramble")
	assertTrue(select(1, PartyService.setTeam(A, Constants.TeamId.RED)), "A red")
	assertTrue(select(1, PartyService.setTeam(B, Constants.TeamId.RED)), "B red")
	assertTrue(select(1, PartyService.setTeam(C, Constants.TeamId.BLUE)), "C blue")
	assertTrue(select(1, PartyService.setTeam(D, Constants.TeamId.BLUE)), "D blue")
	assertTrue(select(1, PartyService.setReady(B, true)), "B ready scramble")
	assertTrue(select(1, PartyService.setReady(C, true)), "C ready scramble")
	assertTrue(select(1, PartyService.setReady(D, true)), "D ready scramble")
	return party
end

resetAll()
local party = PartyService.createParty(A)
local firstSnapshot = PartyService.snapshot(party)
assertEqual(firstSnapshot.leaderUserId, A.UserId, "A leader")
assertEqual(firstSnapshot.members[1].ready, true, "creator ready")
assertEqual(#firstSnapshot.members, 1, "party size 1")
assertTrue(type(firstSnapshot.code) == "string" and #firstSnapshot.code == 6, "party code exists")
local originalCode = party.code
local originalPartyId = party.partyId

assertTrue(select(1, PartyService.joinByCode(B, originalCode)), "B joins by code")
local joinedSnapshot = PartyService.snapshot(party)
assertTrue(memberByUserId(joinedSnapshot, B.UserId) ~= nil, "B member")
assertEqual((memberByUserId(joinedSnapshot, B.UserId) :: any).ready, false, "B not ready")
assertTrue(select(1, PartyService.setReady(B, true)), "B ready before configure")
assertTrue(select(1, PartyService.configure(A, privatePayload())), "A configures private")
assertEqual(
	(memberByUserId(PartyService.snapshot(party), B.UserId) :: any).ready,
	false,
	"config unready non-leader"
)
assertFalse(select(1, PartyService.configure(B, privatePayload())), "B cannot configure")
assertTrue(select(1, PartyService.setReady(B, true)), "B ready true")
assertTrue(select(1, PartyService.canStartRound(A)), "A can start private")
assertTrue(select(1, PartyService.joinByCode(C, originalCode)), "C joins")
assertTrue(select(1, PartyService.joinByCode(D, originalCode)), "D joins")
assertFalse(select(1, PartyService.joinByCode(E, originalCode)), "fifth rejected")
assertTrue(select(1, PartyService.leaveParty(A)), "leader leaves")
assertEqual(PartyService.snapshot(party).leaderUserId, B.UserId, "leader transfers")
assertTrue(select(1, PartyService.leaveParty(B)), "B leaves")
assertTrue(select(1, PartyService.leaveParty(C)), "C leaves")
assertTrue(select(1, PartyService.leaveParty(D)), "D leaves")
assertEqual(PartyService.getPartyById(originalPartyId), nil, "empty party deleted")
assertFalse(select(1, PartyService.joinByCode(E, originalCode)), "deleted code rejected")

makeScrambleParty()
assertTrue(select(1, PartyService.canStartRound(A)), "scramble can start")
assertFalse(select(1, PartyService.setTeam(D, Constants.TeamId.RED)), "three red rejected")
assertFalse(select(1, PartyService.configure(A, scramblePayload(true))), "ranked scramble rejected")

local privateParty = makePrivateParty()
local privateMatch = MatchService.buildMatchInfo(privateParty)
assertEqual(privateMatch.transport, Constants.MatchTransport.LOCAL, "private transport local")
assertTrue(includes(privateMatch.playerUserIds, A.UserId), "private match has A")
assertTrue(includes(privateMatch.playerUserIds, B.UserId), "private match has B")
local privateStartOk, privateStarted = MatchService.startPrivateRound(A, privatePayload())
assertTrue(privateStartOk, "party private start")
assertEqual(
	privateStarted.transport,
	Constants.MatchTransport.LOCAL,
	"started private transport local"
)
assertEqual((RoundService.getPlayerRound(A) :: any).holeCount, 18, "private stroke uses 18 holes")

local matchScrambleParty = makeScrambleParty()
local scrambleMatch = MatchService.buildMatchInfo(matchScrambleParty)
assertEqual(scrambleMatch.transport, Constants.MatchTransport.LOCAL, "scramble transport local")
assertTrue(scrambleMatch.teams[Constants.TeamId.RED] ~= nil, "red team exists")
assertTrue(scrambleMatch.teams[Constants.TeamId.BLUE] ~= nil, "blue team exists")

local serviceParty = makeScrambleParty()
local okStart, scrambleRound =
	ScrambleService.startScrambleRound(serviceParty, scramblePayload(false))
assertTrue(okStart, "start scramble round")
local roundId = scrambleRound.roundId
assertTrue(
	select(
		1,
		ScrambleService.recordShotOption(roundId, A, {
			ballId = "red_40",
			position = { x = 10, y = 10 },
			surface = Constants.Surface.FAIRWAY,
			holed = false,
			penalty = false,
			distanceToPinYards = 40,
		})
	),
	"red 40 option"
)
assertTrue(
	select(
		1,
		ScrambleService.recordShotOption(roundId, B, {
			ballId = "red_20",
			position = { x = 20, y = 20 },
			surface = Constants.Surface.FAIRWAY,
			holed = false,
			penalty = false,
			distanceToPinYards = 20,
		})
	),
	"red 20 option"
)
assertTrue(
	select(
		1,
		ScrambleService.submitVote(A, {
			roundId = roundId,
			holeIndex = 1,
			shotCycle = 1,
			selectedBallId = "red_40",
		})
	),
	"A votes red 40"
)
assertTrue(
	select(
		1,
		ScrambleService.submitVote(B, {
			roundId = roundId,
			holeIndex = 1,
			shotCycle = 1,
			selectedBallId = "red_20",
		})
	),
	"B votes red 20"
)
local voteState = ScrambleService.getVoteState(roundId, Constants.TeamId.RED)
assertTrue(voteState ~= nil and voteState.selectedBallId == nil, "disagree no selection")
local selectedOk, selectedRed = ScrambleService.submitVote(A, {
	roundId = roundId,
	holeIndex = 1,
	shotCycle = 1,
	selectedBallId = "red_20",
})
assertTrue(selectedOk, "A revotes red 20")
assertEqual(selectedRed.selectedBallId, "red_20", "20-yard selected")
assertEqual(ScrambleService.snapshot(roundId).teamScores[Constants.TeamId.RED], 1, "red score one")

assertTrue(
	select(
		1,
		ScrambleService.recordShotOption(roundId, C, {
			ballId = "blue_holed",
			position = { x = 30, y = 30 },
			surface = Constants.Surface.GREEN,
			holed = true,
			penalty = false,
			distanceToPinYards = 50,
		})
	),
	"blue holed option"
)
assertTrue(
	select(
		1,
		ScrambleService.recordShotOption(roundId, D, {
			ballId = "blue_close",
			position = { x = 31, y = 31 },
			surface = Constants.Surface.GREEN,
			holed = false,
			penalty = false,
			distanceToPinYards = 1,
		})
	),
	"blue close option"
)
local autoHoledOk, autoHoled = ScrambleService.autoSelectBestBall(roundId, Constants.TeamId.BLUE)
assertTrue(autoHoledOk, "auto holed")
assertEqual(autoHoled.selectedBallId, "blue_holed", "holed wins")

assertTrue(
	select(
		1,
		ScrambleService.recordShotOption(roundId, A, {
			ballId = "red_penalty",
			position = { x = 40, y = 40 },
			surface = Constants.Surface.WATER,
			holed = false,
			penalty = true,
			distanceToPinYards = 5,
		})
	),
	"red penalty option"
)
assertTrue(
	select(
		1,
		ScrambleService.recordShotOption(roundId, B, {
			ballId = "red_safe",
			position = { x = 45, y = 45 },
			surface = Constants.Surface.FAIRWAY,
			holed = false,
			penalty = false,
			distanceToPinYards = 20,
		})
	),
	"red safe option"
)
local autoSafeOk, autoSafe = ScrambleService.autoSelectBestBall(roundId, Constants.TeamId.RED)
assertTrue(autoSafeOk, "auto safe")
assertEqual(autoSafe.selectedBallId, "red_safe", "non-penalty wins")
assertEqual(ScrambleService.snapshot(roundId).teamScores[Constants.TeamId.RED], 2, "red score two")

print("Golf Pro multiplayer core tests passed")
