--!strict

local WindModel = {}

export type Wind = {
	xYards: number,
	yYards: number,
	speedMph: number,
}

function WindModel.calm(): Wind
	return {
		xYards = 0,
		yYards = 0,
		speedMph = 0,
	}
end

function WindModel.daily(courseId: string, holeIndex: number): Wind
	local seed = #courseId * 17 + holeIndex * 31
	local direction = if seed % 2 == 0 then 1 else -1
	local speed = 4 + seed % 9

	return {
		xYards = direction * speed * 0.35,
		yYards = speed * 0.12,
		speedMph = speed,
	}
end

return WindModel
