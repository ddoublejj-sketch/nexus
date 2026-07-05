--!strict

local DataStoreKeys = {}

local function valueOrDefault(value: any, defaultValue: string): string
	if value == nil or value == "" then
		return defaultValue
	end

	return tostring(value)
end

function DataStoreKeys.contextKey(context: any): string
	return table.concat({
		valueOrDefault(context.courseId, "unknown_course"),
		valueOrDefault(context.courseVersion, "v0"),
		valueOrDefault(context.mode, "unknown_mode"),
		valueOrDefault(context.teeSet, "default_tee"),
		valueOrDefault(context.pinSet, "default_pin"),
		valueOrDefault(context.rulesetId, "default_ruleset"),
		valueOrDefault(context.physicsVersion, "default_physics"),
	}, "|")
end

function DataStoreKeys.roundAudit(roundId: string): string
	return "round|" .. tostring(roundId)
end

function DataStoreKeys.courseRecord(context: any): string
	return "record|" .. DataStoreKeys.contextKey(context)
end

function DataStoreKeys.playerBest(playerUserId: number, context: any): string
	return ("best|%d|%s"):format(playerUserId, DataStoreKeys.contextKey(context))
end

function DataStoreKeys.leaderboard(context: any): string
	return "lb|" .. DataStoreKeys.contextKey(context)
end

return DataStoreKeys
