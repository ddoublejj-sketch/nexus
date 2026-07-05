--!strict

local Constants = require("../Constants")
local Pinebrook = require("./course_pinebrook_v1")

export type CourseSpec = typeof(Pinebrook)
export type HoleSpec = typeof(Pinebrook.holes[1])

local CourseRegistry = {}

local courses: { [string]: CourseSpec } = {
	[Pinebrook.id] = Pinebrook,
}

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
end

local function validateHole(hole: HoleSpec)
	assert(hole.index >= 1, "hole index must be positive")
	assert(hole.par >= 3 and hole.par <= 5, "hole par must be 3, 4, or 5")
	assert(hole.yardage > 0, "hole yardage must be positive")
	assert(#hole.zones > 0, "hole needs surface zones")
end

function CourseRegistry.validate(course: CourseSpec)
	assert(course.id ~= "", "course id required")
	assert(course.displayName ~= "", "course displayName required")
	assert(course.physicsVersion == Constants.PHYSICS_VERSION, course.id .. " physics mismatch")
	validateLegal(course)
	assert(course.record == nil, course.id .. " must launch with an unclaimed record")

	for _, hole in course.holes do
		validateHole(hole)
	end
end

for _, course in courses do
	CourseRegistry.validate(course)
end

function CourseRegistry.all(): { CourseSpec }
	return { Pinebrook }
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

return CourseRegistry
