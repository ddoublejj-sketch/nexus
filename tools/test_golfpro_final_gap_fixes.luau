--!strict

local fs = require("@lune/fs")

local Constants = require("../src/ReplicatedStorage/Shared/GolfPro/Constants")
local DurableStore = require("../src/ServerScriptService/Server/Data/DurableStore")
local RoundService = require("../src/ServerScriptService/Server/Services/RoundService")

local function assertTrue(condition: boolean, label: string)
	if not condition then
		error(label)
	end
end

local function assertEqual(actual: any, expected: any, label: string)
	if actual ~= expected then
		error(("%s: expected %s, got %s"):format(label, tostring(expected), tostring(actual)))
	end
end

local function read(path: string): string
	assertTrue(fs.isFile(path), "Missing file: " .. path)
	return fs.readFile(path)
end

local durableStore = read("src/ServerScriptService/Server/Data/DurableStore.luau")
assertTrue(durableStore:find("RunService", 1, true) ~= nil, "DurableStore checks RunService")
assertTrue(durableStore:find("IsStudio", 1, true) ~= nil, "DurableStore keeps Studio non-live")
assertTrue(
	durableStore:find("DataStoreService", 1, true) ~= nil,
	"DurableStore uses DataStoreService"
)
assertTrue(durableStore:find("GetDataStore", 1, true) ~= nil, "DurableStore has DataStore path")
assertTrue(
	durableStore:find("GetOrderedDataStore", 1, true) ~= nil,
	"DurableStore has OrderedDataStore path"
)
assertEqual(DurableStore.isLive(), false, "Lune test environment must not use live stores")

for _, pair in
	{
		{
			"src/ServerScriptService/Server/Services/RecordService.luau",
			{ "DurableStore", "UpdateAsync", "GetAsync" },
		},
		{
			"src/ServerScriptService/Server/Services/LeaderboardService.luau",
			{ "DurableStore", "SetAsync", "GetSortedAsync" },
		},
		{
			"src/ServerScriptService/Server/Services/RoundAuditService.luau",
			{ "DurableStore", "SetAsync", "UpdateAsync", "GetAsync" },
		},
		{
			"src/ServerScriptService/Server/Services/TournamentService.luau",
			{ "DurableStore", "SetAsync", "GetSortedAsync" },
		},
	}
do
	local contents = read(pair[1])
	for _, needle in pair[2] do
		assertTrue(contents:find(needle, 1, true) ~= nil, pair[1] .. " missing " .. needle)
	end
end

local starts = 0
RoundService.resetForTests()
RoundService.setDataServiceForTests({
	recordRoundStarted = function(_player: any, round: any)
		starts += 1
		assertTrue(type(round.id) == "string", "started round has id")
		return true
	end,
})
local ok = select(
	1,
	RoundService.startRound({
		UserId = 4444,
		Name = "Starter",
	}, {
		mode = Constants.Mode.SOLO_STROKE_18,
		courseId = Constants.DEFAULT_COURSE_ID,
		teeSet = Constants.DEFAULT_TEE_SET,
		pinSet = Constants.DEFAULT_PIN_SET,
		ranked = false,
	})
)
assertTrue(ok, "round starts")
assertEqual(starts, 1, "RoundService increments roundsStarted through DataService")
RoundService.resetForTests()

local resultsService = read("src/ServerScriptService/Server/Services/ResultsService.luau")
assertTrue(
	resultsService:find("audit_not_clean", 1, true) ~= nil,
	"ResultsService must reject unaudited ranked writes"
)
assertTrue(
	resultsService:find("isRankedCompletionAuditable", 1, true) ~= nil,
	"ResultsService must check clean audit"
)

local shotService = read("src/ServerScriptService/Server/Services/ShotService.luau")
assertTrue(
	shotService:find("ScrambleService.getShotContext", 1, true) ~= nil,
	"ShotService must route live scramble shots"
)
assertTrue(
	shotService:find("ScrambleService.recordShotOption", 1, true) ~= nil,
	"ShotService must create scramble options from shots"
)

print("Golf Pro final gap fix tests passed")
