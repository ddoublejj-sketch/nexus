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
assertContains(
	sourceTruth,
	"Phase 6 - Persistence, leaderboards, records",
	"missing Phase 6 source truth"
)

local net = read("src/ReplicatedStorage/Shared/Net/init.luau")
assertContains(net, "RequestLeaderboardPage", "Net missing RequestLeaderboardPage")
assertContains(net, "CourseRecordUpdated", "Net missing CourseRecordUpdated")
assertContains(net, "RoundCompleted", "Net missing RoundCompleted")

local record = read("src/ServerScriptService/Server/Services/RecordService.luau")
local leaderboard = read("src/ServerScriptService/Server/Services/LeaderboardService.luau")
local audit = read("src/ServerScriptService/Server/Services/RoundAuditService.luau")
local results = read("src/ServerScriptService/Server/Services/ResultsService.luau")
local roundService = read("src/ServerScriptService/Server/Services/RoundService.luau")
local shotService = read("src/ServerScriptService/Server/Services/ShotService.luau")
local hud = read("src/StarterPlayer/StarterPlayerScripts/Client/Controllers/HUDController.luau")
local keys = read("src/ServerScriptService/Server/Data/DataStoreKeys.luau")

for _, pair in
	{
		{ record, "function RecordService.tryUpdateCourseRecord" },
		{ record, "Unclaimed" },
		{ leaderboard, "function LeaderboardService.packScore" },
		{ leaderboard, "function LeaderboardService.getPage" },
		{ audit, "function RoundAuditService.beginRound" },
		{ audit, "function RoundAuditService.isRankedCompletionAuditable" },
		{ results, "function ResultsService.completeRound" },
		{ keys, "function DataStoreKeys.courseRecord" },
	}
do
	assertContains(pair[1], pair[2], "missing " .. pair[2])
end

assertContains(record, "score = 0", "RecordService display must show zero")
assertContains(record, "return nil", "RecordService must be able to keep internal nil")
assertContains(leaderboard, "Net.setServerInvoke", "LeaderboardService must register invoke")
assertContains(
	leaderboard,
	"RequestLeaderboardPage",
	"LeaderboardService missing leaderboard invoke"
)
assertContains(roundService, "RoundAuditService.beginRound", "RoundService must begin audit")
assertContains(
	roundService,
	"RoundAuditService.recordHoleCompleted",
	"RoundService must audit holes"
)
assertContains(shotService, "RoundAuditService.recordShot", "ShotService must audit accepted shots")
assertContains(
	shotService,
	"ResultsService.completeRound",
	"ShotService must complete through ResultsService"
)
assertContains(shotService, "RoundCompleted", "ShotService must fire RoundCompleted")
assertContains(shotService, "CourseRecordUpdated", "ShotService must fire record updates")
assertContains(
	results,
	"DataService.recordRoundCompleted",
	"ResultsService must update profile stats"
)
assertContains(results, "DataService.upsertBestRound", "ResultsService must update best round")
assertContains(
	results,
	"RoundAuditService.completeRound",
	"ResultsService must mark audit complete"
)
assertContains(hud, "RoundCompleted", "HUD must listen for RoundCompleted")
assertContains(hud, "CourseRecordUpdated", "HUD must listen for CourseRecordUpdated")
assertContains(hud, "Course Record: ", "HUD must display course record")

local profileSchema = read("src/ReplicatedStorage/Shared/Data/ProfileSchema.luau")
assertContains(profileSchema, "bestRounds", "profile schema missing bestRounds")
assertContains(profileSchema, "courseRecordsHeld", "profile schema missing courseRecordsHeld")
assertContains(profileSchema, "cosmetics", "profile schema missing cosmetics")

local dataService = read("src/ServerScriptService/Server/Services/DataService.luau")
assertContains(
	dataService,
	"baseStore.Mock",
	"DataService must use ProfileStore mock store in Studio"
)

for _, path in fs.readDir("src/StarterPlayer/StarterPlayerScripts/Client/Controllers") do
	local fullPath = "src/StarterPlayer/StarterPlayerScripts/Client/Controllers/" .. tostring(path)
	if fs.isFile(fullPath) then
		local contents = read(fullPath)
		assertTrue(
			contents:find("DataStoreService", 1, true) == nil,
			fullPath .. " must not use DataStoreService"
		)
		assertTrue(
			contents:find("OrderedDataStore", 1, true) == nil,
			fullPath .. " must not use OrderedDataStore"
		)
	end
end

local serverInit = read("src/ServerScriptService/Server/init.server.luau")
assertContains(serverInit, "RoundAuditService", "server init missing RoundAuditService")
assertContains(serverInit, "RecordService", "server init missing RecordService")
assertContains(serverInit, "LeaderboardService", "server init missing LeaderboardService")
assertContains(serverInit, "ResultsService", "server init missing ResultsService")

print("Golf Pro phase 6 contract tests passed")
