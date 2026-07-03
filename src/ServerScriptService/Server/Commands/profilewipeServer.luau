--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Permissions = require(ReplicatedStorage.Shared.Config.Permissions)

return function(context, targetPlayer: Player, confirm: string): string
	local allowed, reason = Permissions.canRun(context.Executor, "Owner")
	if not allowed then
		return reason or "Permission denied."
	end

	if confirm ~= "CONFIRM_WIPE" then
		return "Refused. Re-run with confirm value CONFIRM_WIPE."
	end

	return ("Profile wipe confirmed for %s. Data service wipe implementation arrives in WO-7."):format(
		targetPlayer.Name
	)
end
