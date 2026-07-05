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

local profile = read("src/ReplicatedStorage/Shared/Data/ProfileSchema.luau")
assertContains(profile, "mysteryRange", "profile schema missing mysteryRange")
assertContains(profile, "rangeTokens", "profile schema missing rangeTokens")
assertContains(profile, "unlockedZones = { starter = true }", "starter zone default missing")

local config = read("src/ReplicatedStorage/Shared/GolfPro/Config/MysteryRangeConfig.luau")
for _, needle in
	{ "starter", "canyon", "deep_green", "unlock_canyon", "unlock_deep_green", "meter_capacity_2" }
do
	assertContains(config, needle, "config missing " .. needle)
end

local service = read("src/ServerScriptService/Server/Services/MysteryRangeService.luau")
for _, needle in
	{
		"function MysteryRangeService.start",
		"function MysteryRangeService.getSnapshot",
		"function MysteryRangeService.recordTargetHit",
		"function MysteryRangeService.deposit",
		"function MysteryRangeService.purchaseUpgrade",
		"function MysteryRangeService.hasZoneUnlocked",
	}
do
	assertContains(service, needle, "service missing " .. needle)
end

local shot = read("src/ServerScriptService/Server/Services/ShotService.luau")
assertContains(
	shot,
	"MysteryRangeService.recordPracticeShot",
	"practice shots must feed Mystery Range"
)

local net = read("src/ReplicatedStorage/Shared/Net/init.luau")
for _, needle in
	{
		"RequestMysteryRangeSnapshot",
		"RequestMysteryRangeDeposit",
		"RequestMysteryRangeUpgrade",
		"MysteryRangeUpdated",
		"MysteryRangeRewardRevealed",
	}
do
	assertContains(net, needle, "Net missing " .. needle)
end

local controller =
	read("src/StarterPlayer/StarterPlayerScripts/Client/Controllers/MysteryRangeController.luau")
for _, needle in
	{
		"discoveryMeter",
		"RequestMysteryRangeDeposit",
		"RequestMysteryRangeUpgrade",
		"MysteryRangeRewardRevealed",
	}
do
	assertContains(controller, needle, "controller missing " .. needle)
end

local clientInit = read("src/StarterPlayer/StarterPlayerScripts/Client/init.client.luau")
assertContains(clientInit, "MysteryRangeController.start", "client init missing controller")
local serverInit = read("src/ServerScriptService/Server/init.server.luau")
assertContains(serverInit, "MysteryRangeService.start", "server init missing service")

local map = read("maps/Default.model.json")
for _, needle in
	{
		"MysteryRangeRoot",
		"StarterTarget",
		"CanyonTarget",
		"DeepGreenTarget",
		"RangeVaultMachine",
		"UpgradeBoard",
		"RangeSharkObstacle",
	}
do
	assertContains(map, needle, "map missing " .. needle)
end

local forbidden = {
	"slot",
	"casino",
	"gamble",
	"wager",
	"jackpot",
	"cashout",
	"cash-out",
	"Robux prize",
}

local function scanDir(path: string)
	for _, child in fs.readDir(path) do
		local fullPath = path .. "/" .. tostring(child)
		if fs.isDir(fullPath) then
			scanDir(fullPath)
		elseif fs.isFile(fullPath) then
			local contents = fs.readFile(fullPath)
			for _, word in forbidden do
				assertTrue(
					contents:find('"' .. word .. '"', 1, true) == nil
						and contents:find("'" .. word .. "'", 1, true) == nil,
					fullPath .. " contains forbidden runtime text " .. word
				)
			end
		end
	end
end
scanDir("src")

print("Golf Pro Mystery Range contract tests passed")
