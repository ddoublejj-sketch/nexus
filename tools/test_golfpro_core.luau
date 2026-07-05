--!strict

local fs = require("@lune/fs")

local Constants = require("../src/ReplicatedStorage/Shared/GolfPro/Constants")
local ClubRegistry = require("../src/ReplicatedStorage/Shared/GolfPro/Clubs/ClubRegistry")
local CourseRegistry = require("../src/ReplicatedStorage/Shared/GolfPro/Courses/CourseRegistry")
local SurfaceResolver =
	require("../src/ReplicatedStorage/Shared/GolfPro/Simulation/SurfaceResolver")
local ShotMath = require("../src/ReplicatedStorage/Shared/GolfPro/Simulation/ShotMath")
local WindModel = require("../src/ReplicatedStorage/Shared/GolfPro/Simulation/WindModel")

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

ClubRegistry.validateAll()

local clubs = ClubRegistry.all()
assertEqual(#clubs, 14, "default club count")
assertTrue(ClubRegistry.get("driver") ~= nil, "driver missing")
assertTrue(ClubRegistry.get("putter") ~= nil, "putter missing")

local pinebrook = CourseRegistry.requireCourse(Constants.DEFAULT_COURSE_ID)
CourseRegistry.validate(pinebrook)

assertEqual(pinebrook.displayName, "Pinebrook National", "first course name")
assertEqual(pinebrook.legal.category, "fictional_premium", "legal category")
assertEqual(pinebrook.record, nil, "new course record must be unset internally")
assertEqual(
	CourseRegistry.recordDisplay(pinebrook),
	Constants.UNCLAIMED_RECORD_DISPLAY,
	"unclaimed record display"
)
assertTrue(#pinebrook.holes >= 3, "Pinebrook vertical slice needs at least 3 holes")

local hole1 = pinebrook.holes[1]
assertEqual(
	SurfaceResolver.resolve(hole1, { x = 12, y = 420 }),
	Constants.Surface.GREEN,
	"green resolution"
)
assertEqual(
	SurfaceResolver.resolve(hole1, { x = 64, y = 300 }),
	Constants.Surface.WATER,
	"water priority"
)
assertEqual(
	SurfaceResolver.resolve(hole1, { x = -100, y = 100 }),
	Constants.Surface.ROUGH,
	"default rough fallback"
)

local driver = ClubRegistry.requireClub("driver")
local intent = {
	roundId = "round_test",
	holeIndex = 1,
	playerUserId = 1,
	clubId = "driver",
	shotType = "normal",
	aimYawDeg = 0,
	aimPitchDeg = 0,
	power01 = 0.82,
	accuracy01 = 0.5,
	spin01 = 0,
	drawFade01 = 0,
	clientShotNonce = "nonce",
	clientTimestamp = 0,
}

local shotA =
	ShotMath.solve(driver, hole1, hole1.tee, Constants.Surface.TEE, intent, WindModel.calm())
local shotB =
	ShotMath.solve(driver, hole1, hole1.tee, Constants.Surface.TEE, intent, WindModel.calm())

assertEqual(shotA.totalYards, shotB.totalYards, "shot solver must be deterministic")
assertTrue(shotA.carryYards > 0, "shot carry must be positive")
assertTrue(shotA.totalYards <= driver.maxCarryYards * 1.25, "driver output bound")

local spec = fs.readFile("docs/product/GolfPro_Source_of_Truth.md")
assertTrue(
	spec:find("Pinebrook National", 1, true) ~= nil
		and spec:find("server-authoritative golf", 1, true) ~= nil,
	"source-of-truth doc must be copied into the repo"
)

local net = fs.readFile("src/ReplicatedStorage/Shared/Net/init.luau")
for _, remoteName in
	{
		"RequestStartPrivateRound",
		"SubmitShotIntent",
		"RequestScrambleBallVote",
		"BallPath",
		"RoundStateUpdated",
	}
do
	assertTrue(net:find(remoteName, 1, true) ~= nil, "missing Golf Pro remote: " .. remoteName)
end

print("Golf Pro core tests passed")
