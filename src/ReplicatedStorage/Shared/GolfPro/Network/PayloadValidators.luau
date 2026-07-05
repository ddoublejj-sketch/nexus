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

local function trim(value: string): string
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function nonBlankString(value: any): boolean
	return type(value) == "string" and trim(value) ~= ""
end

local function positiveInteger(value: any): boolean
	return type(value) == "number" and value >= 1 and value % 1 == 0
end

local function validMode(mode: any): boolean
	return mode == Constants.Mode.PRACTICE
		or mode == Constants.Mode.SOLO_STROKE_3_DEBUG
		or mode == Constants.Mode.SOLO_STROKE_9
		or mode == Constants.Mode.SOLO_STROKE_18
		or mode == Constants.Mode.PRIVATE_STROKE
		or mode == Constants.Mode.SCRAMBLE_2V2
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
	if not validMode(mode) then
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
	if payload.ranked and mode == Constants.Mode.SCRAMBLE_2V2 then
		return false, "ranked scramble disabled."
	end

	return true, nil
end

function PayloadValidators.validatePartyCodePayload(payload: any): (boolean, string?)
	if type(payload) ~= "table" then
		return false, "payload table required"
	end
	if not nonBlankString(payload.code) then
		return false, "code required"
	end
	if #trim(payload.code) > 12 then
		return false, "code too long"
	end

	return true, nil
end

function PayloadValidators.validatePartyConfigurePayload(payload: any): (boolean, string?)
	if type(payload) ~= "table" then
		return false, "payload table required"
	end
	if not validMode(payload.mode) then
		return false, "mode invalid"
	end
	if not nonBlankString(payload.courseId) then
		return false, "courseId required"
	end
	if not nonBlankString(payload.teeSet) then
		return false, "teeSet required"
	end
	if not nonBlankString(payload.pinSet) then
		return false, "pinSet required"
	end
	if type(payload.ranked) ~= "boolean" then
		return false, "ranked required"
	end
	if payload.mode == Constants.Mode.SCRAMBLE_2V2 and payload.ranked then
		return false, "ranked scramble disabled"
	end

	return true, nil
end

function PayloadValidators.validatePartyReadyPayload(payload: any): (boolean, string?)
	if type(payload) ~= "table" then
		return false, "payload table required"
	end
	if type(payload.ready) ~= "boolean" then
		return false, "ready required"
	end

	return true, nil
end

function PayloadValidators.validatePartyTeamPayload(payload: any): (boolean, string?)
	if type(payload) ~= "table" then
		return false, "payload table required"
	end
	if payload.teamId ~= Constants.TeamId.RED and payload.teamId ~= Constants.TeamId.BLUE then
		return false, "team invalid"
	end

	return true, nil
end

function PayloadValidators.validateScrambleBallVotePayload(payload: any): (boolean, string?)
	if type(payload) ~= "table" then
		return false, "payload table required"
	end
	if not nonBlankString(payload.roundId) then
		return false, "roundId required"
	end
	if not positiveInteger(payload.holeIndex) then
		return false, "holeIndex invalid"
	end
	if not positiveInteger(payload.shotCycle) then
		return false, "shotCycle invalid"
	end
	if not nonBlankString(payload.selectedBallId) then
		return false, "selectedBallId required"
	end

	return true, nil
end

return PayloadValidators
