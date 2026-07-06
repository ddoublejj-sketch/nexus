--!strict

local DataStoreKeys = require("../Data/DataStoreKeys")
local DurableStore = require("../Data/DurableStore")

local RoundAuditService = {}

local AUDIT_STORE_NAME = "GolfProRoundAudits_v1"
local audits: { [string]: any } = {}
local started = false

local function shallowCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end

	return table.clone(value)
end

local function liveStore(): any?
	return DurableStore.getDataStore(AUDIT_STORE_NAME)
end

local function remember(audit: any?)
	if audit ~= nil then
		audits[audit.roundId] = audit
	end
end

local function markSuspicious(audit: any?, flag: string)
	if audit == nil then
		return
	end

	table.insert(audit.suspiciousFlags, flag)
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

	local store = liveStore()
	if store ~= nil then
		local ok = pcall(function()
			store:SetAsync(DataStoreKeys.roundAudit(roundId), audits[roundId])
		end)
		if not ok then
			markSuspicious(audits[roundId], "audit_store_failed")
		end
	end

	return audits[roundId]
end

function RoundAuditService.recordShot(roundId: string, shotAudit: any)
	local audit = audits[roundId]
	if audit == nil then
		return false, "unknown round"
	end

	table.insert(audit.shots, shallowCopy(shotAudit))
	local store = liveStore()
	if store ~= nil then
		local ok = pcall(function()
			store:UpdateAsync(DataStoreKeys.roundAudit(roundId), function(current: any)
				current = if type(current) == "table" then current else audit
				current.shots = current.shots or {}
				table.insert(current.shots, shallowCopy(shotAudit))
				return current
			end)
		end)
		if not ok then
			markSuspicious(audit, "audit_shot_store_failed")
		end
	end
	return true, audit
end

function RoundAuditService.recordHoleCompleted(roundId: string, holeAudit: any)
	local audit = audits[roundId]
	if audit == nil then
		return false, "unknown round"
	end

	table.insert(audit.holes, shallowCopy(holeAudit))
	local store = liveStore()
	if store ~= nil then
		local ok = pcall(function()
			store:UpdateAsync(DataStoreKeys.roundAudit(roundId), function(current: any)
				current = if type(current) == "table" then current else audit
				current.holes = current.holes or {}
				table.insert(current.holes, shallowCopy(holeAudit))
				return current
			end)
		end)
		if not ok then
			markSuspicious(audit, "audit_hole_store_failed")
		end
	end
	return true, audit
end

function RoundAuditService.completeRound(roundId: string, result: any)
	local audit = audits[roundId]
	if audit == nil then
		return false, "unknown round"
	end

	audit.completed = true
	audit.result = shallowCopy(result)
	local store = liveStore()
	if store ~= nil then
		local ok = pcall(function()
			store:UpdateAsync(DataStoreKeys.roundAudit(roundId), function(current: any)
				current = if type(current) == "table" then current else nil
				if current == nil then
					return nil
				end
				current.completed = true
				current.result = shallowCopy(result)
				return current
			end)
		end)
		if not ok then
			markSuspicious(audit, "audit_complete_store_failed")
			return false, "audit_store_failed"
		end
	end
	return true, audit
end

function RoundAuditService.getAudit(roundId: string): any?
	local audit = audits[roundId]
	if audit == nil then
		local store = liveStore()
		if store ~= nil then
			local ok, stored = pcall(function()
				return store:GetAsync(DataStoreKeys.roundAudit(roundId))
			end)
			if ok and type(stored) == "table" then
				audit = stored
				remember(audit)
			end
		end
	end
	return audit
end

function RoundAuditService.isRankedCompletionAuditable(roundId: string): boolean
	local audit = RoundAuditService.getAudit(roundId)
	return audit ~= nil
		and audit.ranked == true
		and audit.completed == true
		and #audit.suspiciousFlags == 0
end

return RoundAuditService
