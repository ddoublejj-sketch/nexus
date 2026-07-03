--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Net = require(ReplicatedStorage.Shared.Net)

local NexusService = {}

local started = false

function NexusService.start()
	if started then
		return
	end

	started = true
	Net.ensureRemotes()

	print(("[Nexus] %s %s server online"):format(GameConfig.PROJECT_NAME, GameConfig.VERSION))
end

return NexusService
