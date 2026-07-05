--!strict

local Constants = require("../Constants")
local SurfaceResolver = require("./SurfaceResolver")
local Types = require("../Types")

type HoleSpec = Types.HoleSpec
type Vector2Yards = Types.Vector2Yards

local GreenModel = {}

local CUP_RADIUS_YARDS = 1.25
local MAX_CAPTURE_SPEED_YARDS = 8

function GreenModel.distanceYards(a: Vector2Yards, b: Vector2Yards): number
	local dx = a.x - b.x
	local dy = a.y - b.y

	return math.sqrt(dx * dx + dy * dy)
end

function GreenModel.puttRollYards(power01: number, greenSpeed: number?, slope01: number?): number
	local power = math.clamp(power01, 0, 1)
	local speed = greenSpeed or 1
	local slope = slope01 or 0

	return math.max(0, 2 + power * 58 * speed + slope * 6)
end

function GreenModel.isHoled(hole: HoleSpec, position: Vector2Yards, speedYards: number?): boolean
	if SurfaceResolver.resolve(hole, position) ~= Constants.Surface.GREEN then
		return false
	end

	local speed = speedYards or 0
	return GreenModel.distanceYards(position, hole.pin) <= CUP_RADIUS_YARDS
		and speed <= MAX_CAPTURE_SPEED_YARDS
end

return GreenModel
