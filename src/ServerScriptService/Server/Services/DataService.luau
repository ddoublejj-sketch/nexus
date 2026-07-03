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
