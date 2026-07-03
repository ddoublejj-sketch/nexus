--!strict

return function(_, targetPlayers: { Player }, itemKey: string, amount: number): string
	if amount <= 0 then
		return "Amount must be greater than zero."
	end

	return ("Grant queued: %d player(s), item %q, amount %s. Inventory service arrives in WO-7."):format(
		#targetPlayers,
		itemKey,
		tostring(amount)
	)
end
