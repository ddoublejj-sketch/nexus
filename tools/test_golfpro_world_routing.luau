--!strict

local fs = require("@lune/fs")

local Constants = require("../src/ReplicatedStorage/Shared/GolfPro/Constants")
local CourseRegistry = require("../src/ReplicatedStorage/Shared/GolfPro/Courses/CourseRegistry")
local WorldConfig = require("../src/ReplicatedStorage/Shared/GolfPro/World/WorldConfig")

local function assertTrue(condition: boolean, label: string)
	if not condition then
		error(label)
	end
end

local function assertEqual(actual: any, expected: any, label: string)
	if actual ~= expected then
		error(("%s: expected %s, got %s"):format(label, tostring(expected), tostring(actual)))
	end
end

local function read(path: string): string
	assertTrue(fs.isFile(path), "Missing file: " .. path)
	return fs.readFile(path)
end

local function assertContains(contents: string, needle: string, label: string)
	assertTrue(contents:find(needle, 1, true) ~= nil, label)
end

local function distance(a: { x: number, z: number }, b: { x: number, z: number }): number
	local dx = a.x - b.x
	local dz = a.z - b.z
	return math.sqrt(dx * dx + dz * dz)
end

assertEqual(WorldConfig.STUDS_PER_YARD, Constants.STUDS_PER_YARD, "world scale constant")
assertEqual(WorldConfig.STUDS_PER_YARD, 3, "Golf Pro world must render real yardage scale")

local rangeOrigin =
	WorldConfig.originFor(Constants.DEFAULT_PRACTICE_COURSE_ID, Constants.Mode.PRACTICE, 1)
local practiceOrigin =
	WorldConfig.originFor(Constants.DEFAULT_COURSE_ID, Constants.Mode.SOLO_STROKE_3_DEBUG, 1)
local championshipOrigin =
	WorldConfig.originFor(Constants.DEFAULT_COURSE_ID, Constants.Mode.SOLO_STROKE_18, 1)
local championship18Origin =
	WorldConfig.originFor(Constants.DEFAULT_COURSE_ID, Constants.Mode.SOLO_STROKE_18, 18)

assertTrue(
	distance(rangeOrigin, practiceOrigin) > 1800,
	"driving range and practice holes must be separated"
)
assertTrue(
	distance(practiceOrigin, championshipOrigin) > 2000,
	"practice holes and championship course must be separated"
)
assertTrue(
	distance(championshipOrigin, championship18Origin) > 4500,
	"18-hole route must occupy a large world footprint"
)

assertEqual(
	WorldConfig.destinationName(Constants.DEFAULT_PRACTICE_COURSE_ID, Constants.Mode.PRACTICE, 99),
	"DrivingRange_Hole01_Spawn",
	"range destination"
)
assertEqual(
	WorldConfig.destinationName(Constants.DEFAULT_COURSE_ID, Constants.Mode.SOLO_STROKE_3_DEBUG, 2),
	"PracticeHoles_Hole02_Spawn",
	"practice destination"
)
assertEqual(
	WorldConfig.destinationName(Constants.DEFAULT_COURSE_ID, Constants.Mode.SOLO_STROKE_18, 18),
	"Pinebrook18_Hole18_Spawn",
	"championship destination"
)
assertEqual(
	WorldConfig.destinationName(Constants.DEFAULT_COURSE_ID, Constants.Mode.PRIVATE_STROKE, 1),
	"Pinebrook18_Hole01_Spawn",
	"private stroke destination"
)
assertEqual(
	WorldConfig.destinationName(Constants.DEFAULT_COURSE_ID, Constants.Mode.SCRAMBLE_2V2, 1),
	"Pinebrook18_Hole01_Spawn",
	"scramble destination"
)

local pinebrook = CourseRegistry.requireCourse(Constants.DEFAULT_COURSE_ID)
local totalPar = 0
local totalYards = 0
for _, hole in pinebrook.holes do
	totalPar += hole.par
	totalYards += hole.yardage
end
assertEqual(totalPar, 72, "Pinebrook par total")
assertEqual(totalYards, 7305, "Pinebrook yardage total")

local builder = read("tools/build_golfpro_world.luau")
for _, needle in
	{
		"WorldHub_UltraPass",
		"WorldDestinations",
		"WorldCartSpawns",
		"DrivingRange_UltraPass",
		"PracticeHoles_UltraPass",
		"PinebrookNational_Blockout_Phase4",
		"PlaytestSpawn",
		"MysteryRangeRoot",
	}
do
	assertContains(builder, needle, "world builder missing " .. needle)
end

local hud = read("src/StarterPlayer/StarterPlayerScripts/Client/Controllers/HUDController.luau")
for _, needle in
	{
		"Driving Range",
		"Practice Holes",
		"Pinebrook 18",
		"7,305-yard",
		"fireRoundStart(Constants.Mode.PRACTICE, Constants.DEFAULT_PRACTICE_COURSE_ID)",
		"fireRoundStart(Constants.Mode.SOLO_STROKE_3_DEBUG, Constants.DEFAULT_COURSE_ID)",
		"fireRoundStart(Constants.Mode.SOLO_STROKE_18, Constants.DEFAULT_COURSE_ID)",
	}
do
	assertContains(hud, needle, "HUD menu missing " .. needle)
end

local roundService = read("src/ServerScriptService/Server/Services/RoundService.luau")
assertContains(roundService, "courseId = round.courseId", "round snapshots must include course")
assertContains(roundService, "mode = round.mode", "round snapshots must include mode")
assertContains(
	roundService,
	"holeCount = round.holeCount",
	"hole snapshots must include hole count"
)

local matchService = read("src/ServerScriptService/Server/Services/MatchService.luau")
assertContains(
	matchService,
	"MapService.teleportPlayerToRound(player, roundOrReason)",
	"solo/private start must teleport player"
)
assertContains(
	matchService,
	"teleportPartyToRound(party, roundOrReason)",
	"party stroke start must teleport party"
)
assertContains(matchService, "teleportPartyToRound(party, {", "scramble start must teleport party")

local mapService = read("src/ServerScriptService/Server/Services/MapService.luau")
for _, needle in
	{
		"terrain:Clear()",
		"terrain:FillBlock",
		"Enum.Material.Sand",
		"Enum.Material.Water",
		"Enum.Material.LeafyGrass",
		"VehicleSeat",
		"WorldCartSpawns",
		"GolfCarts",
		"spawnGolfCarts(clone)",
	}
do
	assertContains(mapService, needle, "MapService missing world polish " .. needle)
end

local shotService = read("src/ServerScriptService/Server/Services/ShotService.luau")
assertContains(shotService, "courseId = roundContext.courseId", "BallPath must include course")
assertContains(shotService, "mode = roundContext.mode", "BallPath must include mode")
assertContains(shotService, "holeIndex = roundContext.holeIndex", "BallPath must include hole")
assertContains(
	shotService,
	"MapService.teleportPlayerToRound(player, finishPayload.round)",
	"hole advance must teleport player to next tee"
)

local ballRender =
	read("src/StarterPlayer/StarterPlayerScripts/Client/Controllers/BallRenderController.luau")
assertContains(ballRender, "WorldConfig.originFor", "ball renderer must use world origins")
assertContains(ballRender, "WorldConfig.STUDS_PER_YARD", "ball renderer must use world scale")
assertContains(
	ballRender,
	"updateWorldOrigin(payload)",
	"ball renderer must update origin by payload"
)
assertContains(ballRender, "GolfProBallTrackerGui", "ball renderer must show tracker UI")
assertContains(ballRender, "BallDirectionMarker", "ball renderer must show ball arrow")
assertContains(ballRender, "WorldToViewportPoint", "ball tracker must follow ball screen position")

local swing = read("src/StarterPlayer/StarterPlayerScripts/Client/Controllers/SwingController.luau")
assertContains(swing, "GolfProSwingMeterGui", "swing controller must show swing meter")
assertContains(swing, "SwingMeter", "swing controller must build meter frame")
assertContains(swing, "RunService.RenderStepped", "swing meter must animate")
assertContains(swing, "activeRound == nil", "swing input must ignore no-round clicks")

print("Golf Pro world routing tests passed")
