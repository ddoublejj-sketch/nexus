--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Net = require(ReplicatedStorage.Shared.Net)

local NexusController = {}

local started = false

function NexusController.start()
	if started then
		return
	end

	started = true
	local pingRemote = Net.getRemote("Ping")
	local remoteState = if pingRemote then "ready" else "waiting"

	print(
		("[Nexus] %s client online; Ping remote is %s"):format(GameConfig.PROJECT_NAME, remoteState)
	)
end

return NexusController
