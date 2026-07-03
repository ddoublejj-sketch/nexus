--!strict

return function(_, targetPlayers: { Player }, statKey: string, value: number): string
	return ("Setstat queued: %d player(s), stat %q = %s. Data service arrives in WO-7."):format(
		#targetPlayers,
		statKey,
		tostring(value)
	)
end
