--!strict

local RoundAuditService = {}

local audits: { [string]: any } = {}
local started = false

local function shallowCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end

	return table.clone(value)
end

function RoundAuditService.start()
	if started then
		return
	end
	started = true
end

function RoundAuditService.resetForTests()
	audits = {}
	started = false
end

function RoundAuditService.beginRound(roundState: any)
	local roundId = roundState.id or roundState.roundId
	assert(type(roundId) == "string", "round id is required")

	audits[roundId] = {
		roundId = roundId,
		courseId = roundState.courseId,
		mode = roundState.mode,
		teeSet = roundState.teeSet,
		pinSet = roundState.pinSet,
		ranked = roundState.ranked == true,
		holeCount = roundState.holeCount,
		playerUserId = roundState.playerUserId,
		shots = {},
		holes = {},
		completed = false,
		suspiciousFlags = {},
	}
	return audits[roundId]
end

function RoundAuditService.recordShot(roundId: string, shotAudit: any)
	local audit = audits[roundId]
	if audit == nil then
		return false, "unknown round"
	end

	table.insert(audit.shots, shallowCopy(shotAudit))
	return true, audit
end

function RoundAuditService.recordHoleCompleted(roundId: string, holeAudit: any)
	local audit = audits[roundId]
	if audit == nil then
		return false, "unknown round"
	end

	table.insert(audit.holes, shallowCopy(holeAudit))
	return true, audit
end

function RoundAuditService.completeRound(roundId: string, result: any)
	local audit = audits[roundId]
	if audit == nil then
		return false, "unknown round"
	end

	audit.completed = true
	audit.result = shallowCopy(result)
	return true, audit
end

function RoundAuditService.getAudit(roundId: string): any?
	return audits[roundId]
end

function RoundAuditService.isRankedCompletionAuditable(roundId: string): boolean
	local audit = audits[roundId]
	return audit ~= nil
		and audit.ranked == true
		and audit.completed == true
		and #audit.suspiciousFlags == 0
end

return RoundAuditService
