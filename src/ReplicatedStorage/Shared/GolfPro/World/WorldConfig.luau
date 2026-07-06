--!strict

local Constants = require("../Constants")

local WorldConfig = {}

WorldConfig.STUDS_PER_YARD = 3

local layouts = {
	drivingRange = {
		base = { x = -2600, z = -850 },
		holesPerRow = 1,
		holeStrideX = 760,
		holeStrideZ = 2200,
		destinationPrefix = "DrivingRange",
	},
	practiceHoles = {
		base = { x = -1450, z = 950 },
		holesPerRow = 3,
		holeStrideX = 760,
		holeStrideZ = 2200,
		destinationPrefix = "PracticeHoles",
	},
	championship = {
		base = { x = 1050, z = 950 },
		holesPerRow = 6,
		holeStrideX = 760,
		holeStrideZ = 2200,
		destinationPrefix = "Pinebrook18",
	},
}

local function layoutFor(courseId: string?, mode: string?): any
	if courseId == Constants.DEFAULT_PRACTICE_COURSE_ID or mode == Constants.Mode.PRACTICE then
		return layouts.drivingRange
	end
	if mode == Constants.Mode.SOLO_STROKE_3_DEBUG then
		return layouts.practiceHoles
	end
	return layouts.championship
end

function WorldConfig.layoutFor(courseId: string?, mode: string?): any
	return layoutFor(courseId, mode)
end

function WorldConfig.originFor(
	courseId: string?,
	mode: string?,
	holeIndex: number?
): { x: number, z: number }
	local layout = layoutFor(courseId, mode)
	local index = math.max(1, holeIndex or 1)
	if layout == layouts.drivingRange then
		index = 1
	end

	local zeroIndex = index - 1
	local column = zeroIndex % layout.holesPerRow
	local row = math.floor(zeroIndex / layout.holesPerRow)

	return {
		x = layout.base.x + column * layout.holeStrideX,
		z = layout.base.z + row * layout.holeStrideZ,
	}
end

function WorldConfig.destinationName(courseId: string?, mode: string?, holeIndex: number?): string
	local layout = layoutFor(courseId, mode)
	local index = if layout == layouts.drivingRange then 1 else math.max(1, holeIndex or 1)
	return ("%s_Hole%02d_Spawn"):format(layout.destinationPrefix, index)
end

return WorldConfig
