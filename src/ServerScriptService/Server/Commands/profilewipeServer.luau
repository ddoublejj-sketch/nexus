--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Permissions = require(ReplicatedStorage.Shared.Config.Permissions)
local DataService = require(ServerScriptService.Server.Services.DataService)

return function(context, targetPlayer: Player, confirm: string): string
	local allowed, reason = Permissions.canRun(context.Executor, "Owner")
	if not allowed then
		return reason or "Permission denied."
	end

	if confirm ~= "CONFIRM_WIPE" then
		return "Refused. Re-run with confirm value CONFIRM_WIPE."
	end

	if not DataService.resetProfile(targetPlayer) then
		return ("Profile wipe failed for %s because no loaded profile was found."):format(
			targetPlayer.Name
		)
	end

	return ("Profile wiped for %s and reset to schema defaults."):format(targetPlayer.Name)
end
