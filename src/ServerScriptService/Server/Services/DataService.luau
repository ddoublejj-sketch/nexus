--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Net = require(ReplicatedStorage.Shared.Net)
local ProfileSchema = require(ReplicatedStorage.Shared.Data.ProfileSchema)
local Migrations = require(ReplicatedStorage.Shared.Data.Migrations)
local ProfileStore: any = require(ServerScriptService.ServerPackages.ProfileStore)

export type ProfileData = ProfileSchema.ProfileData

local STORE_NAME = "NexusPlayerProfiles_v1"

local baseStore = ProfileStore.New(STORE_NAME, ProfileSchema.createDefaultProfile())
local playerStore: any = if RunService:IsStudio() then baseStore.Mock else baseStore
local profiles: { [Player]: any } = {}

local DataService = {}

local started = false

local function profileKey(player: Player): string
	return tostring(player.UserId)
end

local function loadProfile(player: Player)
	local profile = playerStore:StartSessionAsync(profileKey(player), {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		player:Kick("Profile load failed. Please rejoin.")
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()
	profile.Data = Migrations.migrate(profile.Data)

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		if player.Parent == Players then
			player:Kick("Profile session ended. Please rejoin.")
		end
	end)

	if player.Parent == Players then
		profiles[player] = profile
	else
		profile:EndSession()
	end
end

local function releaseProfile(player: Player)
	local profile = profiles[player]
	if profile ~= nil then
		profiles[player] = nil
		profile:EndSession()
	end
end

local function snapshotProfile(player: Player): any
	local profile = profiles[player]
	if profile == nil then
		return nil
	end

	local data = profile.Data :: ProfileData
	return {
		schema_version = data.schema_version,
		currencies = data.currencies,
		stats = data.stats,
		golf = data.golf,
	}
end

function DataService.start()
	if started then
		return
	end

	started = true

	for _, player in Players:GetPlayers() do
		task.spawn(loadProfile, player)
	end

	Players.PlayerAdded:Connect(loadProfile)
	Players.PlayerRemoving:Connect(releaseProfile)
	Net.setServerInvoke("RequestProfileSnapshot", snapshotProfile)

	print(
		("[Nexus] DataService online (%s mode)"):format(
			if RunService:IsStudio() then "mock" else "live"
		)
	)
end

function DataService.getProfile(player: Player): ProfileData?
	local profile = profiles[player]
	if profile == nil then
		return nil
	end

	return profile.Data :: ProfileData
end

function DataService.getSnapshot(player: Player): any
	return snapshotProfile(player)
end

function DataService.setKey(player: Player, key: string, value: any): boolean
	local profile = profiles[player]
	if profile == nil then
		return false
	end

	profile.Data[key] = value
	return true
end

function DataService.addInventoryItem(player: Player, itemKey: string, amount: number): boolean
	local profile = profiles[player]
	if profile == nil then
		return false
	end

	local data = profile.Data :: ProfileData
	data.inventory.items[itemKey] = (data.inventory.items[itemKey] or 0) + amount
	return true
end

function DataService.recordRoundStarted(player: Player, _roundContext: any): boolean
	local profile = profiles[player]
	if profile == nil then
		return false
	end

	local data = profile.Data :: ProfileData
	data.stats.roundsStarted += 1
	return true
end

function DataService.recordRoundCompleted(player: Player, roundResult: any): boolean
	local profile = profiles[player]
	if profile == nil then
		return false
	end

	local data = profile.Data :: ProfileData
	local totalScore = tonumber(roundResult.totalScore or roundResult.score or roundResult.total)
		or 0
	data.stats.roundsCompleted += 1
	data.stats.totalStrokes += totalScore
	if roundResult.ranked == true then
		data.stats.rankedRoundsCompleted += 1
	end
	if
		data.stats.bestScoreToPar == nil
		or (roundResult.toPar or 0) < (data.stats.bestScoreToPar :: number)
	then
		data.stats.bestScoreToPar = roundResult.toPar or 0
	end
	data.stats.longestDriveYards =
		math.max(data.stats.longestDriveYards, tonumber(roundResult.longestDriveYards) or 0)
	return true
end

function DataService.upsertBestRound(
	player: Player,
	bestRoundKey: string,
	roundResult: any
): boolean
	local profile = profiles[player]
	if profile == nil then
		return false
	end

	local data = profile.Data :: ProfileData
	local current = data.golf.bestRounds[bestRoundKey]
	local nextScore = tonumber(roundResult.totalScore or roundResult.score or roundResult.total)
	if nextScore == nil then
		return false
	end
	if current ~= nil and nextScore >= current.totalScore then
		return true
	end

	data.golf.bestRounds[bestRoundKey] = {
		roundId = roundResult.roundId,
		totalScore = nextScore,
		toPar = roundResult.toPar,
		completedAtUnix = roundResult.completedAtUnix,
	}
	return true
end

function DataService.addCourseRecordHeld(player: Player, recordKey: string): boolean
	local profile = profiles[player]
	if profile == nil then
		return false
	end

	local data = profile.Data :: ProfileData
	data.golf.courseRecordsHeld[recordKey] = true
	return true
end

function DataService.getBestRound(player: Player, bestRoundKey: string): any?
	local profile = profiles[player]
	if profile == nil then
		return nil
	end

	local data = profile.Data :: ProfileData
	return data.golf.bestRounds[bestRoundKey]
end

function DataService.addCurrency(
	player: Player,
	currencyKey: string,
	amount: number,
	_reason: string?
): boolean
	local profile = profiles[player]
	if profile == nil then
		return false
	end

	local data = profile.Data :: ProfileData
	if data.currencies[currencyKey] == nil then
		return false
	end
	data.currencies[currencyKey] = math.max(0, data.currencies[currencyKey] + amount)
	return true
end

function DataService.grantCosmetic(player: Player, cosmeticId: string, _reason: string?): boolean
	local profile = profiles[player]
	if profile == nil then
		return false
	end

	local data = profile.Data :: ProfileData
	data.golf.cosmetics.owned[cosmeticId] = true
	return true
end

function DataService.equipCosmetic(
	player: Player,
	slot: string,
	cosmeticId: string
): (boolean, string?)
	local profile = profiles[player]
	if profile == nil then
		return false, "Profile is not loaded."
	end

	local data = profile.Data :: ProfileData
	if data.golf.cosmetics.owned[cosmeticId] ~= true then
		return false, "Cosmetic is not owned."
	end
	data.golf.cosmetics.equipped[slot] = cosmeticId
	return true, nil
end

function DataService.setStat(player: Player, statKey: string, value: number): (boolean, string?)
	local profile = profiles[player]
	if profile == nil then
		return false, "Profile is not loaded."
	end

	local data = profile.Data :: ProfileData
	if statKey == "level" then
		data.stats.level = value
	elseif statKey == "xp" then
		data.stats.xp = value
	else
		return false, ("Unknown stat %q. Expected level or xp."):format(statKey)
	end

	return true, nil
end

function DataService.resetProfile(player: Player): boolean
	local profile = profiles[player]
	if profile == nil then
		return false
	end

	profile.Data = ProfileSchema.createDefaultProfile()
	return true
end

function DataService.release(player: Player)
	releaseProfile(player)
end

function DataService.isMockMode(): boolean
	return RunService:IsStudio()
end

return DataService
