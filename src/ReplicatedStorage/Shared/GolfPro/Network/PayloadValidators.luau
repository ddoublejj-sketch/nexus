--!strict

local ClubRegistry = require("../Clubs/ClubRegistry")
local Constants = require("../Constants")
local CourseRegistry = require("../Courses/CourseRegistry")

local PayloadValidators = {}

local function inRange(value: any, min: number, max: number): boolean
	return type(value) == "number" and value >= min and value <= max
end

local function nonEmptyString(value: any): boolean
	return type(value) == "string" and value ~= ""
end

local function listContains(list: { string }, value: string): boolean
	for _, item in list do
		if item == value then
			return true
		end
	end

	return false
end

function PayloadValidators.validateShotIntent(payload: any): (boolean, string?)
	if type(payload) ~= "table" then
		return false, "ShotIntent must be a table."
	end

	if not nonEmptyString(payload.roundId) then
		return false, "roundId is required."
	end
	if
		type(payload.holeIndex) ~= "number"
		or payload.holeIndex < 1
		or payload.holeIndex % 1 ~= 0
	then
		return false, "holeIndex must be a positive integer."
	end
	if
		type(payload.playerUserId) ~= "number"
		or payload.playerUserId < 1
		or payload.playerUserId % 1 ~= 0
	then
		return false, "playerUserId must be a positive integer."
	end

	local club = if nonEmptyString(payload.clubId) then ClubRegistry.get(payload.clubId) else nil
	if club == nil then
		return false, "clubId is unknown."
	end
	if
		not nonEmptyString(payload.shotType)
		or not listContains(club.allowedShotTypes, payload.shotType)
	then
		return false, "shotType is not allowed for club."
	end

	if not inRange(payload.aimYawDeg, -180, 180) then
		return false, "aimYawDeg out of range."
	end
	if not inRange(payload.aimPitchDeg, -15, 45) then
		return false, "aimPitchDeg out of range."
	end
	if not inRange(payload.power01, 0, 1) then
		return false, "power01 out of range."
	end
	if not inRange(payload.accuracy01, 0, 1) then
		return false, "accuracy01 out of range."
	end
	if not inRange(payload.spin01, 0, 1) then
		return false, "spin01 out of range."
	end
	if not inRange(payload.drawFade01, -1, 1) then
		return false, "drawFade01 out of range."
	end
	if not nonEmptyString(payload.clientShotNonce) or #payload.clientShotNonce > 64 then
		return false, "clientShotNonce invalid."
	end
	if type(payload.clientTimestamp) ~= "number" or payload.clientTimestamp < 0 then
		return false, "clientTimestamp invalid."
	end

	return true, nil
end

function PayloadValidators.validateRoundStartPayload(payload: any): (boolean, string?)
	if type(payload) ~= "table" then
		return false, "Round start payload must be a table."
	end

	local mode = payload.mode
	if
		mode ~= Constants.Mode.PRACTICE
		and mode ~= Constants.Mode.SOLO_STROKE_3_DEBUG
		and mode ~= Constants.Mode.SOLO_STROKE_18
		and mode ~= Constants.Mode.PRIVATE_STROKE
	then
		return false, "Unsupported Golf Pro round mode."
	end

	if not nonEmptyString(payload.courseId) then
		return false, "courseId is required."
	end

	local course = CourseRegistry.get(payload.courseId)
	if course == nil then
		return false, "courseId is unknown."
	end

	local teeSet = payload.teeSet or Constants.DEFAULT_TEE_SET
	local pinSet = payload.pinSet or Constants.DEFAULT_PIN_SET
	if type(teeSet) ~= "string" or not CourseRegistry.hasTeeSet(course, teeSet) then
		return false, "teeSet is invalid."
	end
	if type(pinSet) ~= "string" or not CourseRegistry.hasPinSet(course, pinSet) then
		return false, "pinSet is invalid."
	end

	if type(payload.ranked) ~= "boolean" then
		return false, "ranked must be boolean."
	end
	if payload.ranked and not course.rankedEnabled then
		return false, "course is not ranked-enabled."
	end

	return true, nil
end

return PayloadValidators
