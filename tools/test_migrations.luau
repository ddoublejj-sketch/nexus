--!strict

local ProfileSchema = require("../src/ReplicatedStorage/Shared/Data/ProfileSchema")
local MigrationLogic = require("../src/ReplicatedStorage/Shared/Data/MigrationLogic")

local function assertEqual(actual: any, expected: any, label: string)
	if actual ~= expected then
		error(("%s: expected %s, got %s"):format(label, tostring(expected), tostring(actual)))
	end
end

local defaults = ProfileSchema.createDefaultProfile()

local migrated = MigrationLogic.migrate({
	currencies = {
		coins = 25,
	},
	stats = {
		xp = 10,
	},
}, defaults, ProfileSchema.CURRENT_VERSION)

assertEqual(migrated.schema_version, 1, "schema_version")
assertEqual(migrated.currencies.coins, 25, "coins preserved")
assertEqual(migrated.currencies.gems, 0, "gems defaulted")
assertEqual(migrated.inventory.items ~= nil, true, "inventory defaulted")
assertEqual(migrated.stats.level, 1, "level defaulted")
assertEqual(migrated.stats.xp, 10, "xp preserved")
assertEqual(migrated.flags ~= nil, true, "flags defaulted")

local empty = MigrationLogic.migrate(nil, defaults, ProfileSchema.CURRENT_VERSION)
assertEqual(empty.schema_version, 1, "nil schema_version")
assertEqual(empty.stats.level, 1, "nil level defaulted")

print("Migration fixtures passed")
