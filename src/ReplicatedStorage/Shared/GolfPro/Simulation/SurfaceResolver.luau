--!strict

local Constants = require("../Constants")
local Types = require("../Types")

type Bounds2Yards = Types.Bounds2Yards
type HoleSpec = Types.HoleSpec
type Surface = Types.Surface
type Vector2Yards = Types.Vector2Yards

local SurfaceResolver = {}

local function contains(bounds: Bounds2Yards, position: Vector2Yards): boolean
	return position.x >= bounds.minX
		and position.x <= bounds.maxX
		and position.y >= bounds.minY
		and position.y <= bounds.maxY
end

function SurfaceResolver.resolve(hole: HoleSpec, position: Vector2Yards): Surface
	local bestZone = nil
	for _, zone in hole.zones do
		if
			contains(zone.bounds, position)
			and (bestZone == nil or zone.priority > bestZone.priority)
		then
			bestZone = zone
		end
	end

	if bestZone == nil then
		return Constants.Surface.ROUGH :: Surface
	end

	return bestZone.surface :: Surface
end

return SurfaceResolver
