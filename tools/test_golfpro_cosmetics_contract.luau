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

local catalog = read("src/ReplicatedStorage/Shared/GolfPro/Config/CosmeticCatalog.luau")
for _, needle in
	{
		"ball_skin",
		"trail",
		"bag_tag",
		"title",
		"profile_banner",
		"classic_white_ball",
		"classic_arc_trail",
		"enabled = false",
		"cosmeticOnly = true",
		"purchases = {}",
	}
do
	assertContains(catalog, needle, "catalog missing " .. needle)
end
for _, forbidden in { "productId", "productIds", "MarketplaceService", "PromptProductPurchase" } do
	assertNotContains(catalog, forbidden, "catalog contains forbidden purchase hook " .. forbidden)
end

local service = read("src/ServerScriptService/Server/Services/CosmeticService.luau")
for _, needle in
	{
		"function CosmeticService.start",
		"function CosmeticService.resetForTests",
		"function CosmeticService.getInventorySnapshot",
		"function CosmeticService.grantCosmetic",
		"function CosmeticService.equipCosmetic",
		"function CosmeticService.ownsCosmetic",
		"service.grantCosmetic",
		"service.equipCosmetic",
	}
do
	assertContains(service, needle, "service missing " .. needle)
end

local net = read("src/ReplicatedStorage/Shared/Net/init.luau")
for _, needle in { "RequestCosmeticInventory", "RequestEquipCosmetic", "CosmeticInventoryUpdated" } do
	assertContains(net, needle, "Net missing " .. needle)
end

local profile = read("src/ReplicatedStorage/Shared/Data/ProfileSchema.luau")
assertContains(profile, "cosmetics", "profile schema missing cosmetics")
assertContains(profile, "owned: { [string]: boolean }", "profile schema missing owned cosmetics")
assertContains(
	profile,
	"equipped: { [string]: string }",
	"profile schema missing equipped cosmetics"
)

local locker =
	read("src/StarterPlayer/StarterPlayerScripts/Client/Controllers/LockerController.luau")
for _, needle in
	{
		"GolfProLockerGui",
		"RequestCosmeticInventory",
		"RequestEquipCosmetic",
		"CosmeticInventoryUpdated",
		"Locked",
		"Equipped",
	}
do
	assertContains(locker, needle, "locker missing " .. needle)
end
for _, forbidden in
	{ "MarketplaceService", "PromptProductPurchase", "productId", "developerProduct" }
do
	assertNotContains(locker, forbidden, "locker contains purchase path " .. forbidden)
end

local ballRender =
	read("src/StarterPlayer/StarterPlayerScripts/Client/Controllers/BallRenderController.luau")
assertContains(ballRender, "CosmeticCatalog", "ball renderer missing catalog")
assertContains(
	ballRender,
	"CosmeticInventoryUpdated",
	"ball renderer missing cosmetic update remote"
)
assertContains(ballRender, "ball_skin", "ball renderer missing ball skin hook")
assertContains(ballRender, "trail", "ball renderer missing trail hook")
assertContains(ballRender, "currentBallColor", "ball renderer missing ball color state")
assertContains(ballRender, "currentTrailColor", "ball renderer missing trail color state")

local clientInit = read("src/StarterPlayer/StarterPlayerScripts/Client/init.client.luau")
assertContains(clientInit, "LockerController.start", "client init missing locker controller")
local serverInit = read("src/ServerScriptService/Server/init.server.luau")
assertContains(serverInit, "CosmeticService.start", "server init missing cosmetic service")

for _, path in
	{
		"src/ReplicatedStorage/Shared/GolfPro/Clubs/default_club_set_v1.luau",
		"src/ReplicatedStorage/Shared/GolfPro/Simulation/ShotMath.luau",
		"src/ServerScriptService/Server/Services/ScoreService.luau",
		"src/ServerScriptService/Server/Services/RecordService.luau",
		"src/ServerScriptService/Server/Services/LeaderboardService.luau",
	}
do
	local contents = read(path)
	assertNotContains(contents, "CosmeticService", path .. " must not depend on CosmeticService")
	assertNotContains(contents, "CosmeticCatalog", path .. " must not depend on CosmeticCatalog")
	assertNotContains(contents, "cosmetic", path .. " must not depend on cosmetics")
end

local forbiddenRuntime = {
	"MarketplaceService",
	"PromptProductPurchase",
	"ProcessReceipt",
	"UserOwnsGamePassAsync",
	"PromptGamePassPurchase",
	"productId",
	"developerProduct",
	"GamePass",
	"Robux",
}

local function scanDir(path: string)
	for _, child in fs.readDir(path) do
		local fullPath = path .. "/" .. tostring(child)
		if fs.isDir(fullPath) then
			scanDir(fullPath)
		elseif fs.isFile(fullPath) then
			local contents = fs.readFile(fullPath)
			for _, word in forbiddenRuntime do
				assertNotContains(
					contents,
					word,
					fullPath .. " contains forbidden purchase path " .. word
				)
			end
		end
	end
end
scanDir("src")

print("Golf Pro cosmetics contract tests passed")
