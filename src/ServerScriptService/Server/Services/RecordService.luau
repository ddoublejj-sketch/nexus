--!strict

local Constants = require("../../../ReplicatedStorage/Shared/GolfPro/Constants")
local DataStoreKeys = require("../Data/DataStoreKeys")
local DurableStore = require("../Data/DurableStore")

local RecordService = {}

local RECORD_STORE_NAME = "GolfProCourseRecords_v1"
local records: { [string]: any } = {}
local started = false

local function isValidRanked18(context: any, roundResult: any): boolean
	return roundResult.ranked == true
		and roundResult.completed == true
		and roundResult.holeCount == 18
		and roundResult.pendingReview ~= true
		and roundResult.suspicious ~= true
		and context.mode ~= Constants.Mode.SOLO_STROKE_3_DEBUG
		and context.mode ~= Constants.Mode.SOLO_STROKE_9
end

local function copyRecord(record: any): any
	if record == nil then
		return nil
	end
	return {
		key = record.key,
		score = record.score,
		holderUserId = record.holderUserId,
		holderName = record.holderName,
		roundId = record.roundId,
		setAtUnix = record.setAtUnix,
		unclaimed = false,
	}
end

local function liveStore(): any?
	return DurableStore.getDataStore(RECORD_STORE_NAME)
end

local function remember(record: any?)
	if record ~= nil then
		records[record.key] = copyRecord(record)
	end
end

function RecordService.start()
	if started then
		return
	end
	started = true
end

function RecordService.resetForTests()
	records = {}
	started = false
end

function RecordService.getCourseRecord(context: any): any?
	local key = DataStoreKeys.courseRecord(context)
	local record = records[key]
	if record == nil then
		local store = liveStore()
		if store ~= nil then
			local ok, stored = pcall(function()
				return store:GetAsync(key)
			end)
			if ok and type(stored) == "table" then
				record = stored
				records[key] = stored
			end
		end
	end
	return copyRecord(record)
end

function RecordService.getDisplayRecord(context: any): any
	local record = RecordService.getCourseRecord(context)
	if record == nil then
		return {
			score = 0,
			holderName = "Unclaimed",
			unclaimed = true,
			label = Constants.UNCLAIMED_RECORD_DISPLAY,
		}
	end

	return record
end

function RecordService.tryUpdateCourseRecord(context: any, roundResult: any): any
	if not isValidRanked18(context, roundResult) then
		return {
			changed = false,
			reason = "invalid_ranked_completion",
			current = RecordService.getCourseRecord(context),
		}
	end

	local key = DataStoreKeys.courseRecord(context)
	local score = tonumber(roundResult.totalScore or roundResult.score or roundResult.total)
	if score == nil then
		return {
			changed = false,
			reason = "missing_score",
			current = RecordService.getCourseRecord(context),
		}
	end

	local store = liveStore()
	if store ~= nil then
		local updateResult = nil
		local ok = pcall(function()
			store:UpdateAsync(key, function(current: any)
				current = if type(current) == "table" then current else nil
				if current ~= nil and score >= current.score then
					updateResult = {
						changed = false,
						reason = if score == current.score
							then "tie_kept_existing"
							else "not_better",
						current = copyRecord(current),
					}
					return current
				end

				local nextRecord = {
					key = key,
					score = score,
					holderUserId = roundResult.playerUserId,
					holderName = roundResult.playerName or "Unknown",
					roundId = roundResult.roundId,
					setAtUnix = roundResult.completedAtUnix or os.time(),
				}
				updateResult = {
					changed = true,
					reason = if current == nil then "first_record" else "record_beaten",
					previous = copyRecord(current),
					current = copyRecord(nextRecord),
				}
				return nextRecord
			end)
		end)
		if not ok or updateResult == nil then
			return {
				changed = false,
				reason = "record_store_failed",
				current = RecordService.getCourseRecord(context),
			}
		end
		remember(updateResult.current)
		return updateResult
	end

	local current = records[key]

	if current ~= nil and score >= current.score then
		return {
			changed = false,
			reason = if score == current.score then "tie_kept_existing" else "not_better",
			current = copyRecord(current),
		}
	end

	local nextRecord = {
		key = key,
		score = score,
		holderUserId = roundResult.playerUserId,
		holderName = roundResult.playerName or "Unknown",
		roundId = roundResult.roundId,
		setAtUnix = roundResult.completedAtUnix or os.time(),
	}
	records[key] = nextRecord

	return {
		changed = true,
		reason = if current == nil then "first_record" else "record_beaten",
		previous = copyRecord(current),
		current = copyRecord(nextRecord),
	}
end

function RecordService.snapshot(context: any): any
	return {
		key = DataStoreKeys.courseRecord(context),
		record = RecordService.getDisplayRecord(context),
	}
end

return RecordService
