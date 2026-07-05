--!strict

local CosmeticCatalog = require("../../../ReplicatedStorage/Shared/GolfPro/Config/CosmeticCatalog")

local CosmeticService = {}

local started = false
local testProfiles: { [number]: any } = {}

local function playerUserId(player: any): number
	local ok, value = pcall(function()
		return player.UserId
	end)
	return if ok and type(value) == "number" then value else 0
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

local function defaultCosmetics(): any
	local owned = {}
	for _, item: any in CosmeticCatalog.items :: any do
		if item.defaultOwned == true then
			owned[item.id] = true
		end
	end
	return {
		owned = owned,
		equipped = CosmeticCatalog.defaultEquipped(),
	}
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

local function cosmeticsFor(player: any): any
	local service = dataService()
	local profile = if service ~= nil then service.getProfile(player) else nil
	if profile ~= nil then
		profile.golf.cosmetics = profile.golf.cosmetics or defaultCosmetics()
		profile.golf.cosmetics.owned = profile.golf.cosmetics.owned or {}
		profile.golf.cosmetics.equipped = profile.golf.cosmetics.equipped or {}
		for _, item: any in CosmeticCatalog.items :: any do
			if item.defaultOwned == true then
				profile.golf.cosmetics.owned[item.id] = true
				if profile.golf.cosmetics.equipped[item.category] == nil then
					profile.golf.cosmetics.equipped[item.category] = item.id
				end
			end
		end
		return profile.golf.cosmetics
	end

	local userId = playerUserId(player)
	testProfiles[userId] = testProfiles[userId] or defaultCosmetics()
	return testProfiles[userId]
end

local function snapshot(player: any): any
	local cosmetics = cosmeticsFor(player)
	local items = {}
	for _, item: any in CosmeticCatalog.all() do
		items[item.id] = {
			id = item.id,
			category = item.category,
			displayName = item.displayName,
			owned = cosmetics.owned[item.id] == true,
			equipped = cosmetics.equipped[item.category] == item.id,
		}
	end
	return {
		owned = copy(cosmetics.owned),
		equipped = copy(cosmetics.equipped),
		items = items,
		shopHooks = copy(CosmeticCatalog.shopHooks),
	}
end

local function emitUpdate(player: any, payload: any?)
	local service = net()
	if service ~= nil and typeof(player) == "Instance" and player:IsA("Player") then
		service.fireClient("CosmeticInventoryUpdated", player, payload or snapshot(player))
	end
end

function CosmeticService.start()
	if started then
		return
	end
	started = true

	local service = net()
	assert(service ~= nil, "Net is required")

	service.setServerInvoke("RequestCosmeticInventory", function(player: Player)
		return snapshot(player)
	end)
	service.onServerEvent("RequestEquipCosmetic", function(player: Player, payload: any)
		if type(payload) == "table" and type(payload.cosmeticId) == "string" then
			CosmeticService.equipCosmetic(player, payload.cosmeticId)
		end
		emitUpdate(player)
	end)
end

function CosmeticService.resetForTests(player: any?, cosmetics: any?)
	if player == nil then
		testProfiles = {}
		started = false
		return
	end
	testProfiles[playerUserId(player)] = cosmetics or defaultCosmetics()
end

function CosmeticService.getInventorySnapshot(player: any): any
	return snapshot(player)
end

function CosmeticService.ownsCosmetic(player: any, cosmeticId: string): boolean
	local item = CosmeticCatalog.get(cosmeticId)
	if item == nil then
		return false
	end
	local cosmetics = cosmeticsFor(player)
	return cosmetics.owned[cosmeticId] == true or item.defaultOwned == true
end

function CosmeticService.grantCosmetic(
	player: any,
	cosmeticId: string,
	reason: string?
): (boolean, any)
	local item = CosmeticCatalog.get(cosmeticId)
	if item == nil then
		return false, "unknown_cosmetic"
	end

	local service = dataService()
	local ok = if service ~= nil then service.grantCosmetic(player, cosmeticId, reason) else false
	local cosmetics = cosmeticsFor(player)
	if not ok then
		cosmetics.owned[cosmeticId] = true
	end
	local result = snapshot(player)
	emitUpdate(player, result)
	return true, result
end

function CosmeticService.equipCosmetic(player: any, cosmeticId: string): (boolean, any)
	local item = CosmeticCatalog.get(cosmeticId)
	if item == nil then
		return false, "unknown_cosmetic"
	end
	if not CosmeticService.ownsCosmetic(player, cosmeticId) then
		return false, "not_owned"
	end

	local service = dataService()
	local ok = if service ~= nil
		then service.equipCosmetic(player, item.category, cosmeticId)
		else false
	local cosmetics = cosmeticsFor(player)
	if not ok then
		cosmetics.equipped[item.category] = cosmeticId
	end
	local result = snapshot(player)
	emitUpdate(player, result)
	return true, result
end

return CosmeticService
