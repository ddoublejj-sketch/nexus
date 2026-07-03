--!strict

return function(_, mapName: string?): string
	return ("Reload map queued for %q. Map service arrives after Studio bridge validation."):format(
		mapName or "current"
	)
end
