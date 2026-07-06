--!strict

local fs = require("@lune/fs")

local function assertTrue(condition: boolean, label: string)
	if not condition then
		error(label)
	end
end

local function read(path: string): string
	assertTrue(fs.isFile(path), "Missing file: " .. path)
	return fs.readFile(path)
end

local function assertContains(contents: string, needle: string, label: string)
	assertTrue(contents:find(needle, 1, true) ~= nil, label)
end

local sourceTruth = read("docs/product/GolfPro_Source_of_Truth.md")
assertContains(
	sourceTruth,
	"Phase 4.5 - Ball and club presentation",
	"missing Phase 4.5 source truth"
)
assertContains(sourceTruth, "GP-011A: Ball and club presentation", "missing GP-011A source truth")

local presentationConfigPath =
	"src/ReplicatedStorage/Shared/GolfPro/Presentation/PresentationConfig.luau"
local equipmentPath =
	"src/StarterPlayer/StarterPlayerScripts/Client/Controllers/EquipmentController.luau"
local ballRenderPath =
	"src/StarterPlayer/StarterPlayerScripts/Client/Controllers/BallRenderController.luau"
assertTrue(fs.isFile(presentationConfigPath), "PresentationConfig file missing")
assertTrue(fs.isFile(equipmentPath), "EquipmentController file missing")
assertTrue(fs.isFile(ballRenderPath), "BallRenderController file missing")

local clientInit = read("src/StarterPlayer/StarterPlayerScripts/Client/init.client.luau")
assertContains(clientInit, "EquipmentController", "client init must require EquipmentController")
assertContains(clientInit, "BallRenderController", "client init must require BallRenderController")
local equipmentStart = clientInit:find("EquipmentController.start", 1, true) or 0
local hudStart = clientInit:find("HUDController.start", 1, true) or 0
local ballRenderStart = clientInit:find("BallRenderController.start", 1, true) or 0
local swingStart = clientInit:find("SwingController.start", 1, true) or 0
assertTrue(
	equipmentStart > 0 and hudStart > equipmentStart,
	"EquipmentController must start before HUDController"
)
assertTrue(
	ballRenderStart > 0 and swingStart > ballRenderStart,
	"BallRenderController must start before SwingController"
)

local equipment = read(equipmentPath)
for _, needle in
	{
		"GolfProEquippedClub",
		"GolfProClubGripMotor",
		"Motor6D",
		"CharacterAdded",
		"function EquipmentController.setClub",
		"function EquipmentController.playBackswing",
		"function EquipmentController.playStrike",
		"ClubRegistry",
		"PresentationConfig",
	}
do
	assertContains(equipment, needle, "EquipmentController missing " .. needle)
end
assertTrue(
	equipment:find('Instance.new("Tool")', 1, true) == nil,
	"EquipmentController must not create Tool instances"
)

local ballRender = read(ballRenderPath)
for _, needle in
	{
		"LocalGolfBall",
		"GolfProRuntime",
		"ShotTracerSegment",
		"LandingMarker",
		"TweenService",
		"BallPath",
		"BallAtRest",
		"RoundStateUpdated",
		"GolfProBallTrackerGui",
		"BallDirectionMarker",
		"WorldToViewportPoint",
		"function BallRenderController.renderPath",
		"function BallRenderController.applyBallAtRest",
		"function BallRenderController.yardsPointToWorld",
	}
do
	assertContains(ballRender, needle, "BallRenderController missing " .. needle)
end

local hud = read("src/StarterPlayer/StarterPlayerScripts/Client/Controllers/HUDController.luau")
assertContains(hud, "EquipmentController", "HUDController must require EquipmentController")
assertContains(hud, "BallPath", "HUDController must bind BallPath")
assertContains(hud, "ClubScroll", "HUDController must contain ClubScroll")
assertContains(hud, "UIGridLayout", "HUDController must contain UIGridLayout")
assertContains(hud, "Carry:", "HUDController missing Carry stat")
assertContains(hud, "Roll:", "HUDController missing Roll stat")
assertContains(hud, "Total:", "HUDController missing Total stat")
assertContains(hud, "Offline:", "HUDController missing Offline stat")
assertTrue(
	hud:find("if x > 196 then", 1, true) == nil,
	"HUDController still has old club button limit"
)
local clubLoopStart = hud:find("for index, club in ClubRegistry.all() do", 1, true)
local clubLoopEnd = hud:find('bindRemote("RoundStateUpdated"', 1, true)
assertTrue(clubLoopStart ~= nil and clubLoopEnd ~= nil, "HUDController club loop region not found")
local clubLoopRegion = hud:sub(clubLoopStart :: number, clubLoopEnd :: number)
assertTrue(
	clubLoopRegion:find("break", 1, true) == nil,
	"HUDController club loop must not break early"
)

local swing = read("src/StarterPlayer/StarterPlayerScripts/Client/Controllers/SwingController.luau")
assertContains(swing, "EquipmentController", "SwingController must require EquipmentController")
assertContains(swing, "EquipmentController.playBackswing", "SwingController must play backswing")
assertContains(swing, "EquipmentController.playStrike", "SwingController must play strike")
assertContains(swing, "GolfProSwingMeterGui", "SwingController must show swing meter")
assertContains(swing, "RunService.RenderStepped", "SwingController meter must animate")

local net = read("src/ReplicatedStorage/Shared/Net/init.luau")
assertContains(net, "BallPath", "Net must declare BallPath")
assertContains(net, "BallAtRest", "Net must declare BallAtRest")

print("Golf Pro presentation contract tests passed")
