--!strict

local AnalyticsService = {}

local started = false
local events: { any } = {}

local EVENT_NAMES = {
	"menu_opened",
	"practice_shot_hit",
	"round_started",
	"hole_completed",
	"round_completed",
	"round_abandoned",
	"ranked_round_completed",
	"course_record_set",
	"course_record_beaten",
	"leaderboard_submit",
	"mystery_range_deposit",
	"cosmetic_equipped",
	"tournament_attempt_submitted",
}

local knownEvents: { [string]: boolean } = {}
for _, eventName in EVENT_NAMES do
	knownEvents[eventName] = true
end

local function copy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for key, child in value do
		out[key] = copy(child)
	end
	return out
end

local function playerUserId(player: any?): number?
	if player == nil then
		return nil
	end
	local ok, value = pcall(function()
		return player.UserId
	end)
	return if ok and type(value) == "number" then value else nil
end

local function playerName(player: any?): string?
	if player == nil then
		return nil
	end
	local ok, value = pcall(function()
		return player.Name
	end)
	return if ok and type(value) == "string" then value else nil
end

function AnalyticsService.start()
	if started then
		return
	end
	started = true
end

function AnalyticsService.resetForTests()
	started = false
	events = {}
end

function AnalyticsService.eventNames(): { string }
	return table.clone(EVENT_NAMES)
end

function AnalyticsService.isKnownEvent(eventName: string): boolean
	return knownEvents[eventName] == true
end

function AnalyticsService.log(player: any?, eventName: string, payload: any?): (boolean, any)
	if not AnalyticsService.isKnownEvent(eventName) then
		return false, "unknown_event"
	end

	local entry = {
		eventName = eventName,
		playerUserId = playerUserId(player),
		playerName = playerName(player),
		payload = copy(payload or {}),
		recordedAtUnix = os.time(),
	}
	table.insert(events, entry)
	return true, copy(entry)
end

function AnalyticsService.getEvents(eventName: string?): { any }
	local out = {}
	for _, entry in events do
		if eventName == nil or entry.eventName == eventName then
			table.insert(out, copy(entry))
		end
	end
	return out
end

function AnalyticsService.count(eventName: string): number
	return #AnalyticsService.getEvents(eventName)
end

return AnalyticsService
