--!strict

local MysteryRangeConfig =
	require("../src/ReplicatedStorage/Shared/GolfPro/Config/MysteryRangeConfig")
local MysteryRangeService =
	require("../src/ServerScriptService/Server/Services/MysteryRangeService")

local function assertEqual(actual: any, expected: any, label: string)
	if actual ~= expected then
		error(("%s: expected %s, got %s"):format(label, tostring(expected), tostring(actual)))
	end
end

local player = { UserId = 6501, Name = "RangeTester" }

MysteryRangeService.resetForTests()
MysteryRangeService.resetForTests(player)

local ok, hit = MysteryRangeService.recordTargetHit(player, { zoneId = "starter" })
assertEqual(ok, true, "starter target hit ok")
assertEqual(hit.tokens, MysteryRangeConfig.targets.starter.tokenReward, "target token reward")
assertEqual(
	hit.snapshot.discoveryMeter,
	MysteryRangeConfig.targets.starter.meterReward,
	"target meter reward"
)

local lockedOk, lockedReason = MysteryRangeService.recordTargetHit(player, { zoneId = "canyon" })
assertEqual(lockedOk, false, "locked target rejected")
assertEqual(lockedReason, "zone_locked", "locked target reason")

for _ = 1, 10 do
	MysteryRangeService.recordTargetHit(player, { zoneId = "starter" })
end
local full = MysteryRangeService.getSnapshot(player)
assertEqual(full.discoveryMeter, full.meterCapacity, "meter clamps")

MysteryRangeService.resetForTests(player)
local belowOk, belowReason = MysteryRangeService.deposit(player)
assertEqual(belowOk, false, "deposit below full rejected")
assertEqual(belowReason, "meter_not_full", "deposit below full reason")

MysteryRangeService.resetForTests(player, {
	rangeTokens = 0,
	discoveryMeter = 100,
	depositCount = 0,
	unlockedZones = { starter = true },
	upgrades = {},
	cosmeticShards = {},
})
local depositOk, deposit = MysteryRangeService.deposit(player)
assertEqual(depositOk, true, "full deposit succeeds")
assertEqual(deposit.snapshot.discoveryMeter, 0, "deposit resets meter")
assertEqual(deposit.snapshot.depositCount, 1, "deposit count increments")

MysteryRangeService.resetForTests(player, {
	rangeTokens = 0,
	discoveryMeter = 100,
	depositCount = 2,
	unlockedZones = { starter = true },
	upgrades = {},
	cosmeticShards = {},
})
local thirdOk, third = MysteryRangeService.deposit(player)
assertEqual(thirdOk, true, "third deposit succeeds")
assertEqual(third.shardId, MysteryRangeConfig.depositReward.shardId, "third deposit shard")
assertEqual(
	third.snapshot.cosmeticShards[MysteryRangeConfig.depositReward.shardId],
	1,
	"shard stored"
)

MysteryRangeService.resetForTests(player, {
	rangeTokens = 100,
	discoveryMeter = 0,
	depositCount = 0,
	unlockedZones = { starter = true },
	upgrades = {},
	cosmeticShards = {},
})
local upgradeOk, upgrade = MysteryRangeService.purchaseUpgrade(player, "unlock_canyon")
assertEqual(upgradeOk, true, "upgrade purchase ok")
assertEqual(upgrade.snapshot.rangeTokens, 20, "upgrade deducts tokens")
assertEqual(MysteryRangeService.hasZoneUnlocked(player, "canyon"), true, "upgrade unlocks zone")
local duplicateOk, duplicateReason = MysteryRangeService.purchaseUpgrade(player, "unlock_canyon")
assertEqual(duplicateOk, false, "duplicate upgrade rejected")
assertEqual(duplicateReason, "already_owned", "duplicate reason")

print("Golf Pro Mystery Range core tests passed")
