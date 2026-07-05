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

local function assertNotContains(contents: string, needle: string, label: string)
	assertTrue(contents:find(needle, 1, true) == nil, label)
end

local config = read("src/ReplicatedStorage/Shared/GolfPro/Config/TournamentConfig.luau")
for _, needle in
	{
		"weekend_open_001",
		"Pinebrook National",
		"SOLO_STROKE_18",
		"ranked = true",
		"maxAttempts = 3",
		"rewardCosmeticId",
		"cosmetic_only",
		"realMoneyEnabled = false",
		"platformCurrencyEnabled = false",
		"paidEntryEnabled = false",
		"stakeEnabled = false",
		"paidChanceRewardEnabled = false",
	}
do
	assertContains(config, needle, "TournamentConfig missing " .. needle)
end

local service = read("src/ServerScriptService/Server/Services/TournamentService.luau")
for _, needle in
	{
		"function TournamentService.start",
		"function TournamentService.resetForTests",
		"function TournamentService.getActiveEvents",
		"function TournamentService.canSubmitAttempt",
		"function TournamentService.submitAttempt",
		"function TournamentService.getEventLeaderboard",
		"function TournamentService.grantEventRewards",
		"LeaderboardService.packScore",
		"CosmeticService.grantCosmetic",
	}
do
	assertContains(service, needle, "TournamentService missing " .. needle)
end

local net = read("src/ReplicatedStorage/Shared/Net/init.luau")
for _, needle in { "RequestTournamentEvents", "RequestTournamentLeaderboard", "TournamentUpdated" } do
	assertContains(net, needle, "Net missing " .. needle)
end

local controller =
	read("src/StarterPlayer/StarterPlayerScripts/Client/Controllers/TournamentController.luau")
for _, needle in
	{
		"GolfProTournamentGui",
		"RequestTournamentEvents",
		"RequestTournamentLeaderboard",
		"TournamentUpdated",
		"Attempts:",
		"Reward:",
		"Leaderboard:",
	}
do
	assertContains(controller, needle, "TournamentController missing " .. needle)
end

local clientInit = read("src/StarterPlayer/StarterPlayerScripts/Client/init.client.luau")
assertContains(clientInit, "TournamentController.start", "client init missing TournamentController")
local serverInit = read("src/ServerScriptService/Server/init.server.luau")
assertContains(serverInit, "TournamentService.start", "server init missing TournamentService")

local forbiddenRuntimeText = {
	"Cash prize",
	"cash prize",
	"Robux",
	"wager",
	"Wager",
	"entry fee",
	"Entry fee",
	"jackpot",
	"casino",
	"slot machine",
	"paid random reward",
}

local function scanDir(path: string)
	for _, child in fs.readDir(path) do
		local fullPath = path .. "/" .. tostring(child)
		if fs.isDir(fullPath) then
			scanDir(fullPath)
		elseif fs.isFile(fullPath) then
			local contents = fs.readFile(fullPath)
			for _, word in forbiddenRuntimeText do
				assertNotContains(
					contents,
					word,
					fullPath .. " contains forbidden runtime text " .. word
				)
			end
		end
	end
end
scanDir("src")

print("Golf Pro tournament contract tests passed")
