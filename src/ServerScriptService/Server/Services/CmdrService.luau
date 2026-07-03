--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Permissions = require(ReplicatedStorage.Shared.Config.Permissions)
local Cmdr: any = require(ReplicatedStorage.Packages.Cmdr)
local Commands: any = script.Parent.Parent.Commands

local CmdrService = {}

local started = false

function CmdrService.start()
	if started then
		return
	end

	started = true

	Cmdr.Registry:RegisterDefaultCommands({ "DefaultUtil" })
	Cmdr.Registry:RegisterHook("BeforeRun", function(context)
		local requiredTier = Permissions.getRequiredTierForGroup(context.Group)
		local allowed, reason = Permissions.canRun(context.Executor, requiredTier)

		if not allowed then
			return reason
		end

		return nil
	end)
	Cmdr.Registry:RegisterCommandsIn(Commands)

	print("[Nexus] Cmdr service online")
end

return CmdrService
