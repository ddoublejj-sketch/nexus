--!strict

local MysteryRangeConfig =
	require("../../../ReplicatedStorage/Shared/GolfPro/Config/MysteryRangeConfig")

local MysteryRangeService = {}

local started = false
local testProfiles: { [number]: any } = {}

local function playerUserId(player: any): number
	local ok, value = pcall(function()
		return player.UserId
	end)
	return if ok and type(value) == "number" then value else 0
end

local function defaultRange(): any
	return {
		rangeTokens = 0,
		discoveryMeter = 0,
		depositCount = 0,
		unlockedZones = { starter = true },
		upgrades = {},
		cosmeticShards = {},
	}
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

local function dataService(): any?
	if game == nil then
		return nil
	end
	local ok, service = pcall(function()
		return require(script.Parent.DataService)
	end)
	return if ok then service else nil
end

local function net(): any?
	if game == nil then
		return nil
	end
	local ok, service = pcall(function()
		return require("../../../ReplicatedStorage/Shared/Net")
	end)
	return if ok then service else nil
end

local function rangeFor(player: any): any
	local service = dataService()
	local profile = if service ~= nil then service.getProfile(player) else nil
	if profile ~= nil then
		profile.golf.mysteryRange = profile.golf.mysteryRange or defaultRange()
		return profile.golf.mysteryRange
	end

	local userId = playerUserId(player)
	testProfiles[userId] = testProfiles[userId] or defaultRange()
	return testProfiles[userId]
end

local function findTarget(targetOrZoneId: string): any?
	local direct = (MysteryRangeConfig.targets :: any)[targetOrZoneId]
	if direct ~= nil then
		return direct
	end
	for _, target: any in MysteryRangeConfig.targets :: any do
		if target.id == targetOrZoneId or target.zoneId == targetOrZoneId then
			return target
		end
	end
	return nil
end

local function meterCapacity(range: any): number
	local capacity = MysteryRangeConfig.meterCapacity
	for upgradeId in range.upgrades do
		local upgrade = (MysteryRangeConfig.upgrades :: any)[upgradeId]
		if upgrade ~= nil and upgrade.meterCapacity ~= nil then
			capacity = math.max(capacity, upgrade.meterCapacity)
		end
	end
	return capacity
end

local function snapshot(player: any): any
	local range = rangeFor(player)
	return {
		rangeTokens = range.rangeTokens,
		discoveryMeter = range.discoveryMeter,
		meterCapacity = meterCapacity(range),
		depositCount = range.depositCount,
		unlockedZones = copy(range.unlockedZones),
		upgrades = copy(range.upgrades),
		cosmeticShards = copy(range.cosmeticShards),
	}
end

local function emitUpdate(player: any, payload: any?)
	local service = net()
	if service ~= nil and typeof(player) == "Instance" and player:IsA("Player") then
		service.fireClient("MysteryRangeUpdated", player, payload or snapshot(player))
	end
end

function MysteryRangeService.start()
	if started then
		return
	end
	started = true

	local service = net()
	assert(service ~= nil, "Net is required")

	service.setServerInvoke("RequestMysteryRangeSnapshot", function(player: Player)
		return snapshot(player)
	end)
	service.onServerEvent("RequestMysteryRangeDeposit", function(player: Player, _payload: any)
		local ok, result = MysteryRangeService.deposit(player)
		if ok then
			service.fireClient("MysteryRangeRewardRevealed", player, result)
		end
		return emitUpdate(player)
	end)
	service.onServerEvent("RequestMysteryRangeUpgrade", function(player: Player, payload: any)
		MysteryRangeService.purchaseUpgrade(player, payload.upgradeId)
		return emitUpdate(player)
	end)
end

function MysteryRangeService.resetForTests(player: any?, range: any?)
	if player == nil then
		testProfiles = {}
		started = false
		return
	end
	testProfiles[playerUserId(player)] = range or defaultRange()
end

function MysteryRangeService.getSnapshot(player: any): any
	return snapshot(player)
end

function MysteryRangeService.hasZoneUnlocked(player: any, zoneId: string): boolean
	local range = rangeFor(player)
	return range.unlockedZones[zoneId] == true
end

function MysteryRangeService.recordTargetHit(player: any, payload: any): (boolean, any)
	local target = findTarget(payload.targetId or payload.zoneId)
	if target == nil then
		return false, "unknown_target"
	end
	if not MysteryRangeService.hasZoneUnlocked(player, target.zoneId) then
		return false, "zone_locked"
	end

	local range = rangeFor(player)
	range.rangeTokens += target.tokenReward
	range.discoveryMeter = math.min(meterCapacity(range), range.discoveryMeter + target.meterReward)
	local result = {
		type = "target_hit",
		zoneId = target.zoneId,
		targetId = target.id,
		tokens = target.tokenReward,
		meter = target.meterReward,
		snapshot = snapshot(player),
	}
	emitUpdate(player, result.snapshot)
	return true, result
end

function MysteryRangeService.recordPracticeShot(player: any, shotResult: any): (boolean, any?)
	local finalPosition = shotResult and shotResult.finalPosition
	if type(finalPosition) ~= "table" then
		return false, nil
	end

	local bestTarget: any? = nil
	local bestDistance = math.huge
	for _, target: any in MysteryRangeConfig.targets :: any do
		if MysteryRangeService.hasZoneUnlocked(player, target.zoneId) then
			local dx = (finalPosition.x or 0) - target.position.x
			local dy = (finalPosition.y or 0) - target.position.y
			local distance = math.sqrt(dx * dx + dy * dy)
			if distance <= target.radiusYards and distance < bestDistance then
				bestTarget = target
				bestDistance = distance
			end
		end
	end

	if bestTarget == nil then
		return false, nil
	end
	return MysteryRangeService.recordTargetHit(player, { targetId = bestTarget.id })
end

function MysteryRangeService.deposit(player: any): (boolean, any)
	local range = rangeFor(player)
	local capacity = meterCapacity(range)
	if range.discoveryMeter < capacity then
		return false, "meter_not_full"
	end

	range.discoveryMeter = 0
	range.depositCount += 1
	range.rangeTokens += MysteryRangeConfig.depositReward.tokens
	local shardId = nil
	if range.depositCount % MysteryRangeConfig.depositReward.shardEvery == 0 then
		shardId = MysteryRangeConfig.depositReward.shardId
		range.cosmeticShards[shardId] = (range.cosmeticShards[shardId] or 0) + 1
	end

	local result = {
		type = "deposit",
		tokens = MysteryRangeConfig.depositReward.tokens,
		shardId = shardId,
		snapshot = snapshot(player),
	}
	emitUpdate(player, result.snapshot)
	return true, result
end

function MysteryRangeService.purchaseUpgrade(player: any, upgradeId: string): (boolean, any)
	local upgrade = (MysteryRangeConfig.upgrades :: any)[upgradeId]
	if upgrade == nil then
		return false, "unknown_upgrade"
	end

	local range = rangeFor(player)
	if range.upgrades[upgradeId] == true then
		return false, "already_owned"
	end
	if upgrade.requiresZone ~= nil and range.unlockedZones[upgrade.requiresZone] ~= true then
		return false, "requirement_locked"
	end
	if range.rangeTokens < upgrade.cost then
		return false, "not_enough_tokens"
	end

	range.rangeTokens -= upgrade.cost
	range.upgrades[upgradeId] = true
	if upgrade.unlocksZone ~= nil then
		range.unlockedZones[upgrade.unlocksZone] = true
	end

	local result = {
		type = "upgrade",
		upgradeId = upgradeId,
		unlockedZone = upgrade.unlocksZone,
		snapshot = snapshot(player),
	}
	emitUpdate(player, result.snapshot)
	return true, result
end

return MysteryRangeService
