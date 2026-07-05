--!strict

local Constants = require("../Constants")
local Types = require("../Types")
local Pinebrook = require("./course_pinebrook_v1")
local PracticeRange = require("./course_practice_range_v1")

export type CourseSpec = typeof(Pinebrook)
export type HoleSpec = typeof(Pinebrook.holes[1])
type Bounds2Yards = Types.Bounds2Yards
type Vector2Yards = Types.Vector2Yards

local CourseRegistry = {}

local courses: { [string]: CourseSpec } = {
	[Pinebrook.id] = Pinebrook,
	[PracticeRange.id] = PracticeRange,
}

local LEGAL_SURFACES = {
	[Constants.Surface.TEE] = true,
	[Constants.Surface.FAIRWAY] = true,
	[Constants.Surface.ROUGH] = true,
	[Constants.Surface.GREEN] = true,
	[Constants.Surface.BUNKER] = true,
	[Constants.Surface.WATER] = true,
	[Constants.Surface.OUT_OF_BOUNDS] = true,
}

local function contains(bounds: Bounds2Yards, position: Vector2Yards): boolean
	return position.x >= bounds.minX
		and position.x <= bounds.maxX
		and position.y >= bounds.minY
		and position.y <= bounds.maxY
end

local function validateLegal(course: CourseSpec)
	assert(course.legal ~= nil, course.id .. " missing legal block")
	assert(
		course.legal.category == "fictional_premium" or course.legal.category == "licensed_real",
		course.id .. " legal category must be fictional_premium or licensed_real"
	)
	if course.legal.category == "fictional_premium" then
		assert(
			not course.legal.approvedNameUsage,
			course.id .. " should not claim real name rights"
		)
		assert(
			not course.legal.approvedLayoutUsage,
			course.id .. " should not claim real layout rights"
		)
		assert(
			not course.legal.approvedImageryUsage,
			course.id .. " should not claim real imagery rights"
		)
	end

	assert(course.legal.sourceNotes ~= "", course.id .. " needs legal source notes")
end

local function validateHole(hole: HoleSpec)
	assert(hole.index >= 1, "hole index must be positive")
	assert(hole.name ~= "", "hole name is required")
	assert(hole.par >= 3 and hole.par <= 5, "hole par must be 3, 4, or 5")
	assert(hole.yardage > 0, "hole yardage must be positive")
	assert(type(hole.tee.x) == "number" and type(hole.tee.y) == "number", "hole tee invalid")
	assert(type(hole.pin.x) == "number" and type(hole.pin.y) == "number", "hole pin invalid")
	assert(#hole.zones > 0, "hole needs surface zones")

	local teeCovered = false
	local pinCovered = false
	local seenZoneIds = {}

	for _, surfaceZone in hole.zones do
		assert(surfaceZone.id ~= "", "surface zone id is required")
		assert(seenZoneIds[surfaceZone.id] == nil, "duplicate surface zone: " .. surfaceZone.id)
		seenZoneIds[surfaceZone.id] = true
		assert(LEGAL_SURFACES[surfaceZone.surface] == true, surfaceZone.id .. " surface invalid")
		assert(surfaceZone.priority >= 0, surfaceZone.id .. " priority invalid")
		assert(
			surfaceZone.bounds.minX <= surfaceZone.bounds.maxX,
			surfaceZone.id .. " x bounds invalid"
		)
		assert(
			surfaceZone.bounds.minY <= surfaceZone.bounds.maxY,
			surfaceZone.id .. " y bounds invalid"
		)

		if
			surfaceZone.surface == Constants.Surface.TEE and contains(surfaceZone.bounds, hole.tee)
		then
			teeCovered = true
		end
		if
			surfaceZone.surface == Constants.Surface.GREEN
			and contains(surfaceZone.bounds, hole.pin)
		then
			pinCovered = true
		end
	end

	assert(teeCovered, "hole tee must be inside a tee zone")
	assert(pinCovered, "hole pin must be inside a green zone")
end

function CourseRegistry.validate(course: CourseSpec)
	assert(course.id ~= "", "course id required")
	assert(course.displayName ~= "", "course displayName required")
	assert(course.physicsVersion == Constants.PHYSICS_VERSION, course.id .. " physics mismatch")
	assert(#course.teeSets > 0, course.id .. " needs at least one tee set")
	assert(#course.pinSets > 0, course.id .. " needs at least one pin set")
	validateLegal(course)
	assert(course.record == nil, course.id .. " must launch with an unclaimed record")

	local seenHoles = {}
	for _, hole in course.holes do
		assert(seenHoles[hole.index] == nil, "duplicate hole index: " .. tostring(hole.index))
		seenHoles[hole.index] = true
		validateHole(hole)
	end
end

for _, course in courses do
	CourseRegistry.validate(course)
end

function CourseRegistry.all(): { CourseSpec }
	return { Pinebrook, PracticeRange }
end

function CourseRegistry.get(courseId: string): CourseSpec?
	return courses[courseId]
end

function CourseRegistry.requireCourse(courseId: string): CourseSpec
	local course = CourseRegistry.get(courseId)
	assert(course ~= nil, "Unknown course: " .. courseId)
	return course :: CourseSpec
end

function CourseRegistry.recordDisplay(course: CourseSpec): string
	if course.record == nil then
		return Constants.UNCLAIMED_RECORD_DISPLAY
	end

	return ("Course Record: %d"):format((course.record :: any).score)
end

function CourseRegistry.hasTeeSet(course: CourseSpec, teeSet: string): boolean
	for _, value in course.teeSets do
		if value == teeSet then
			return true
		end
	end

	return false
end

function CourseRegistry.hasPinSet(course: CourseSpec, pinSet: string): boolean
	for _, value in course.pinSets do
		if value == pinSet then
			return true
		end
	end

	return false
end

return CourseRegistry
