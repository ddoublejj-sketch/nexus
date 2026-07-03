--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local DataService = require(ServerScriptService.Server.Services.DataService)

return function(_, targetPlayers: { Player }, statKey: string, value: number): string
	local updated = 0
	local lastReason = nil
	for _, player in targetPlayers do
		local ok, reason = DataService.setStat(player, statKey, value)
		if ok then
			updated += 1
		else
			lastReason = reason or lastReason
		end
	end

	if updated == 0 and lastReason then
		return lastReason
	end

	return ("Set stat %q = %s on %d/%d loaded profile(s)."):format(
		statKey,
		tostring(value),
		updated,
		#targetPlayers
	)
end
