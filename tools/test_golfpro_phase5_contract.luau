--!strict

local fs = require("@lune/fs")

local function assertTrue(condition: boolean, label: string)
	if not condition then
		error(label)
	end
end

local function read(path: string): string
	assertTrue(fs.isFile(path), "Missing file: " .. path)
	return fs.readFile(path)
end

local function assertContains(contents: string, needle: string, label: string)
	assertTrue(contents:find(needle, 1, true) ~= nil, label)
end

local sourceTruth = read("docs/product/GolfPro_Source_of_Truth.md")
assertContains(sourceTruth, "Phase 5 - Multiplayer and scramble", "missing Phase 5 source truth")
assertContains(sourceTruth, "GP-012: PartyService", "missing GP-012 source truth")
assertContains(sourceTruth, "GP-013: 2v2 Scramble", "missing GP-013 source truth")

local net = read("src/ReplicatedStorage/Shared/Net/init.luau")
for _, remoteName in
	{
		"RequestCreateParty",
		"RequestJoinPartyCode",
		"RequestLeaveParty",
		"RequestPartyReady",
		"RequestPartyConfigure",
		"RequestPartyTeam",
		"PartyUpdated",
		"MatchFound",
		"ScrambleVoteUpdated",
	}
do
	assertContains(net, remoteName, "Net missing " .. remoteName)
end

local partyPath = "src/ServerScriptService/Server/Services/PartyService.luau"
local matchPath = "src/ServerScriptService/Server/Services/MatchService.luau"
local scramblePath = "src/ServerScriptService/Server/Services/ScrambleService.luau"
local party = read(partyPath)
local match = read(matchPath)
local scramble = read(scramblePath)
for _, functionName in
	{
		"function PartyService.createParty",
		"function PartyService.joinByCode",
		"function PartyService.setReady",
		"function PartyService.configure",
		"function PartyService.setTeam",
		"function PartyService.canStartRound",
	}
do
	assertContains(party, functionName, "PartyService missing " .. functionName)
end
assertContains(match, "Constants.MatchTransport.LOCAL", "MatchService must use local transport")
assertTrue(match:find("ReserveServer", 1, true) == nil, "MatchService must not reserve servers")
for _, functionName in
	{
		"function ScrambleService.startScrambleRound",
		"function ScrambleService.recordShotOption",
		"function ScrambleService.submitVote",
		"function ScrambleService.autoSelectBestBall",
	}
do
	assertContains(scramble, functionName, "ScrambleService missing " .. functionName)
end

local serverInit = read("src/ServerScriptService/Server/init.server.luau")
assertContains(serverInit, "PartyService", "server init missing PartyService")
assertContains(serverInit, "MatchService", "server init missing MatchService")
assertContains(serverInit, "ScrambleService", "server init missing ScrambleService")

local partyController =
	read("src/StarterPlayer/StarterPlayerScripts/Client/Controllers/PartyController.luau")
assertContains(partyController, "PartyUpdated", "PartyController must bind PartyUpdated")
assertContains(partyController, "MatchFound", "PartyController must bind MatchFound")
local scrambleController =
	read("src/StarterPlayer/StarterPlayerScripts/Client/Controllers/ScrambleController.luau")
assertContains(
	scrambleController,
	"ScrambleVoteUpdated",
	"ScrambleController must bind ScrambleVoteUpdated"
)
assertContains(
	scrambleController,
	"RequestScrambleBallVote",
	"ScrambleController must send vote remote"
)

local constants = read("src/ReplicatedStorage/Shared/GolfPro/Constants.luau")
assertContains(constants, 'SCRAMBLE_2V2 = "scramble_2v2"', "SCRAMBLE_2V2 changed")

for _, contents in { party, match, scramble } do
	assertTrue(
		contents:find("DataStoreService", 1, true) == nil,
		"Phase 5 service uses DataStoreService"
	)
	assertTrue(
		contents:find("OrderedDataStore", 1, true) == nil,
		"Phase 5 service uses OrderedDataStore"
	)
end

print("Golf Pro phase 5 contract tests passed")
