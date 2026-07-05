--!strict

local CosmeticCatalog = require("../src/ReplicatedStorage/Shared/GolfPro/Config/CosmeticCatalog")
local ShotMath = require("../src/ReplicatedStorage/Shared/GolfPro/Simulation/ShotMath")
local ClubRegistry = require("../src/ReplicatedStorage/Shared/GolfPro/Clubs/ClubRegistry")
local ProfileSchema = require("../src/ReplicatedStorage/Shared/Data/ProfileSchema")
local CosmeticService = require("../src/ServerScriptService/Server/Services/CosmeticService")

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

local function clubStats(club: any): string
	return table.concat({
		tostring(club.minCarryYards),
		tostring(club.maxCarryYards),
		tostring(club.baseDispersionYards),
		tostring(club.rollBias),
		tostring(club.spinBias),
		tostring(club.mishitPenalty),
	}, ":")
end

local player = { UserId = 7107, Name = "CosmeticTester" }

CosmeticService.resetForTests()
CosmeticService.resetForTests(player)

local initial = CosmeticService.getInventorySnapshot(player)
assertTrue(initial.owned.classic_white_ball == true, "default ball skin should be owned")
assertTrue(initial.owned.classic_arc_trail == true, "default trail should be owned")
assertEqual(initial.items.sunrise_gold_ball.owned, false, "premium ball starts locked")
assertEqual(initial.shopHooks.enabled, false, "shop hooks must stay disabled")
assertEqual(initial.shopHooks.cosmeticOnly, true, "shop hooks must be cosmetic-only")

local unownedOk, unownedReason = CosmeticService.equipCosmetic(player, "sunrise_gold_ball")
assertEqual(unownedOk, false, "unowned cosmetic rejected")
assertEqual(unownedReason, "not_owned", "unowned cosmetic reason")

local grantOk = CosmeticService.grantCosmetic(player, "sunrise_gold_ball", "test_grant")
assertEqual(grantOk, true, "grant cosmetic succeeds")
assertEqual(CosmeticService.ownsCosmetic(player, "sunrise_gold_ball"), true, "grant marks owned")

local equipOk, equipped = CosmeticService.equipCosmetic(player, "sunrise_gold_ball")
assertEqual(equipOk, true, "owned cosmetic equips")
assertEqual(equipped.equipped.ball_skin, "sunrise_gold_ball", "equipped ball persists")
assertEqual(equipped.items.sunrise_gold_ball.equipped, true, "snapshot marks equipped")

local unknownOk, unknownReason = CosmeticService.grantCosmetic(player, "unknown_cosmetic", "test")
assertEqual(unknownOk, false, "unknown cosmetic rejected")
assertEqual(unknownReason, "unknown_cosmetic", "unknown cosmetic reason")

local profile = ProfileSchema.createDefaultProfile()
assertEqual(type(profile.golf.cosmetics.owned), "table", "profile has owned cosmetics table")
assertEqual(type(profile.golf.cosmetics.equipped), "table", "profile has equipped cosmetics table")

local club = ClubRegistry.requireClub("driver")
local statsBefore = clubStats(club)
local hole = {
	id = "test_hole",
	par = 4,
	tee = { x = 0, y = 0 },
	pin = { x = 0, y = 420 },
	fairway = { centerYards = { x = 0, y = 210 }, halfWidthYards = 28, lengthYards = 430 },
	green = { centerYards = { x = 0, y = 420 }, radiusYards = 16 },
	zones = {
		{
			surface = "fairway",
			priority = 1,
			bounds = { minX = -35, maxX = 35, minY = -10, maxY = 390 },
		},
		{
			surface = "green",
			priority = 2,
			bounds = { minX = -18, maxX = 18, minY = 400, maxY = 440 },
		},
	},
}
local intent = {
	clubId = "driver",
	power01 = 0.83,
	accuracy01 = 0.61,
	aimYawDeg = 2,
	drawFade01 = -0.2,
	shotType = "normal",
}
local wind = { xYards = 2, yYards = -1, speedMph = 4 }
local before = ShotMath.solve(club, hole, { x = 0, y = 0 }, "tee", intent, wind)
CosmeticService.grantCosmetic(player, "copper_arc_trail", "test_grant")
CosmeticService.equipCosmetic(player, "copper_arc_trail")
local after = ShotMath.solve(club, hole, { x = 0, y = 0 }, "tee", intent, wind)
assertEqual(
	clubStats(ClubRegistry.requireClub("driver")),
	statsBefore,
	"cosmetics must not alter club stats"
)
assertEqual(after.carryYards, before.carryYards, "cosmetics must not alter carry")
assertEqual(
	after.lateralOffsetYards,
	before.lateralOffsetYards,
	"cosmetics must not alter dispersion"
)
assertEqual(after.rollYards, before.rollYards, "cosmetics must not alter roll")
assertEqual(after.totalYards, before.totalYards, "cosmetics must not alter total distance")

assertTrue(CosmeticCatalog.get("classic_white_ball") ~= nil, "catalog exposes ball skins")
assertTrue(CosmeticCatalog.get("classic_arc_trail") ~= nil, "catalog exposes trails")
assertTrue(CosmeticCatalog.get("fairway_member_tag") ~= nil, "catalog exposes bag tags")
assertTrue(CosmeticCatalog.get("starter_title") ~= nil, "catalog exposes titles")
assertTrue(CosmeticCatalog.get("clubhouse_banner") ~= nil, "catalog exposes profile banners")

print("Golf Pro cosmetics core tests passed")
