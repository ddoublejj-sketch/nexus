--!strict

local MysteryRangeConfig = {}

MysteryRangeConfig.meterCapacity = 100
MysteryRangeConfig.zones = {
	starter = {
		id = "starter",
		displayName = "Starter",
		unlockedByDefault = true,
	},
	canyon = {
		id = "canyon",
		displayName = "Canyon",
		unlockedByUpgrade = "unlock_canyon",
	},
	deep_green = {
		id = "deep_green",
		displayName = "Deep Green",
		unlockedByUpgrade = "unlock_deep_green",
	},
}

MysteryRangeConfig.targets = {
	starter = {
		id = "starter_target",
		zoneId = "starter",
		displayName = "Starter Target",
		position = { x = 0, y = 160 },
		radiusYards = 85,
		tokenReward = 5,
		meterReward = 25,
	},
	canyon = {
		id = "canyon_target",
		zoneId = "canyon",
		displayName = "Canyon Target",
		position = { x = -85, y = 225 },
		radiusYards = 65,
		tokenReward = 12,
		meterReward = 35,
	},
	deep_green = {
		id = "deep_green_target",
		zoneId = "deep_green",
		displayName = "Deep Green Target",
		position = { x = 90, y = 300 },
		radiusYards = 55,
		tokenReward = 20,
		meterReward = 45,
	},
}

MysteryRangeConfig.upgrades = {
	unlock_canyon = {
		id = "unlock_canyon",
		displayName = "Canyon Pass",
		cost = 80,
		unlocksZone = "canyon",
	},
	unlock_deep_green = {
		id = "unlock_deep_green",
		displayName = "Deep Green Pass",
		cost = 160,
		unlocksZone = "deep_green",
		requiresZone = "canyon",
	},
	meter_capacity_2 = {
		id = "meter_capacity_2",
		displayName = "Bigger Meter",
		cost = 60,
		meterCapacity = 150,
	},
}

MysteryRangeConfig.depositReward = {
	tokens = 30,
	shardEvery = 3,
	shardId = "range_shard_prismatic",
}

return MysteryRangeConfig
