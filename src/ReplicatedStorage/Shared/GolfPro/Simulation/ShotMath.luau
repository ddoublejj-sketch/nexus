--!strict

local LieModel = require("./LieModel")
local SurfaceResolver = require("./SurfaceResolver")
local Types = require("../Types")

type ClubSpec = Types.ClubSpec
type HoleSpec = Types.HoleSpec
type ShotIntent = Types.ShotIntent
type ShotResult = Types.ShotResult
type Vector2Yards = Types.Vector2Yards

type Wind = {
	xYards: number,
	yYards: number,
	speedMph: number,
}

local ShotMath = {}

local function clamp(value: number, min: number, max: number): number
	if value < min then
		return min
	end
	if value > max then
		return max
	end
	return value
end

local function powerCurve(power01: number): number
	local power = clamp(power01, 0, 1)
	return power * power * 0.35 + power * 0.65
end

function ShotMath.solve(
	club: ClubSpec,
	hole: HoleSpec,
	startPosition: Vector2Yards,
	surface: string,
	intent: ShotIntent,
	wind: Wind
): ShotResult
	local lie = LieModel.get(surface)
	local power = powerCurve(intent.power01)
	local carryYards = (club.minCarryYards + (club.maxCarryYards - club.minCarryYards) * power)
		* lie.carryMultiplier

	local impactError = (clamp(intent.accuracy01, 0, 1) - 0.5) * 2
	local shape = clamp(intent.drawFade01, -1, 1) * club.baseDispersionYards * 0.5
	local lateralOffsetYards = impactError * club.baseDispersionYards + shape + wind.xYards
	local rollYards = carryYards * club.rollBias * lie.rollMultiplier * 0.18 + wind.yYards
	local totalYards = math.max(0, carryYards + rollYards)

	local yawRadians = math.rad(intent.aimYawDeg)
	local forwardX = math.sin(yawRadians)
	local forwardY = math.cos(yawRadians)
	local lateralX = math.cos(yawRadians)
	local lateralY = -math.sin(yawRadians)

	local finalPosition = {
		x = startPosition.x + forwardX * totalYards + lateralX * lateralOffsetYards,
		y = startPosition.y + forwardY * totalYards + lateralY * lateralOffsetYards,
	}

	return {
		carryYards = carryYards,
		rollYards = rollYards,
		totalYards = totalYards,
		lateralOffsetYards = lateralOffsetYards,
		finalPosition = finalPosition,
		finalSurface = SurfaceResolver.resolve(hole, finalPosition),
	}
end

return ShotMath
