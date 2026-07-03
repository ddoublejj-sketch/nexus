--!strict

local ProfileSchema = require(script.Parent.ProfileSchema)
local MigrationLogic = require(script.Parent.MigrationLogic)

export type ProfileData = ProfileSchema.ProfileData

local Migrations = {}

function Migrations.migrate(rawData: any): ProfileData
	local defaults = ProfileSchema.createDefaultProfile()
	local data = MigrationLogic.migrate(rawData, defaults, ProfileSchema.CURRENT_VERSION)

	return data :: ProfileData
end

return Migrations
