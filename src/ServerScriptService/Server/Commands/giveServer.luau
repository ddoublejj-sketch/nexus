--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local DataService = require(ServerScriptService.Server.Services.DataService)

return function(_, targetPlayers: { Player }, itemKey: string, amount: number): string
	if amount <= 0 then
		return "Amount must be greater than zero."
	end

	local updated = 0
	for _, player in targetPlayers do
		if DataService.addInventoryItem(player, itemKey, amount) then
			updated += 1
		end
	end

	return ("Granted item %q x%s to %d/%d loaded profile(s)."):format(
		itemKey,
		tostring(amount),
		updated,
		#targetPlayers
	)
end
