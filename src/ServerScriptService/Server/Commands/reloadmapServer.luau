--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local MapService = require(ServerScriptService.Server.Services.MapService)

return function(_, mapName: string?): string
	local ok, message = MapService.reload(mapName)
	if not ok then
		return message
	end

	return message
end
