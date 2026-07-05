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

local function scanDir(path: string, callback: (string, string) -> ())
	for _, child in fs.readDir(path) do
		local fullPath = path .. "/" .. tostring(child)
		if fs.isDir(fullPath) then
			scanDir(fullPath, callback)
		elseif fs.isFile(fullPath) then
			callback(fullPath, fs.readFile(fullPath))
		end
	end
end

local forbiddenRuntime = {
	"Robux",
	"cash prize",
	"Cash prize",
	"wager",
	"Wager",
	"entry fee",
	"Entry fee",
	"casino",
	"slot machine",
	"paid random reward",
	"pay-to-win",
	"Augusta National",
	"The Masters",
	"Masters Tournament",
	"PGA Tour",
	"PGA Championship",
	"Pebble Beach",
	"Google Earth",
	"Google Maps",
}

scanDir("src", function(path, contents)
	for _, needle in forbiddenRuntime do
		assertTrue(
			contents:find(needle, 1, true) == nil,
			path .. " contains forbidden launch/IP runtime text: " .. needle
		)
	end
end)

local project = read("default.project.json")
for _, needle in forbiddenRuntime do
	assertTrue(
		project:find(needle, 1, true) == nil,
		"project file contains forbidden text: " .. needle
	)
end

local sourceTruth = read("docs/product/GolfPro_Source_of_Truth.md")
for _, expected in { "Augusta National", "The Masters", "PGA Tour", "Google Earth", "Google Maps" } do
	assertTrue(
		sourceTruth:find(expected, 1, true) ~= nil,
		"source truth missing avoid-list item " .. expected
	)
end

local checklist = read("docs/product/GolfPro_Launch_QA_Checklist.md")
for _, expected in
	{
		"Practice range",
		"18-hole Pinebrook solo stroke",
		"Ball, club, tracer",
		"Party/private stroke",
		"2v2 scramble core",
		"Records update only",
		"Leaderboard rows",
		"Mystery Range rewards",
		"Locker equip rejects unowned cosmetics",
		"Tournament page shows Weekend Open",
		"No live publish",
		"No OpenAI/API-cost feature",
		"cosmetic-only",
	}
do
	assertTrue(checklist:find(expected, 1, true) ~= nil, "launch checklist missing " .. expected)
end

local hud = read("src/StarterPlayer/StarterPlayerScripts/Client/Controllers/HUDController.luau")
assertTrue(
	hud:find("panel.Size = UDim2.fromOffset(324, 428)", 1, true) ~= nil,
	"HUD panel has stable mobile-sized dimensions"
)
assertTrue(
	hud:find("label.Size = UDim2.fromOffset(300, 20)", 1, true) ~= nil,
	"HUD labels have fixed height"
)
assertTrue(hud:find("12 + order * 21", 1, true) ~= nil, "HUD label rows have non-overlap spacing")
assertTrue(
	hud:find("button.Size = UDim2.fromOffset(86, 28)", 1, true) ~= nil,
	"HUD buttons fit mobile panel"
)

local swing = read("src/StarterPlayer/StarterPlayerScripts/Client/Controllers/SwingController.luau")
for _, inputNeedle in { "MouseButton1", "Touch", "ButtonA", "Space" } do
	assertTrue(swing:find(inputNeedle, 1, true) ~= nil, "swing input missing " .. inputNeedle)
end

local ballRender =
	read("src/StarterPlayer/StarterPlayerScripts/Client/Controllers/BallRenderController.luau")
assertTrue(
	ballRender:find("TweenService", 1, true) ~= nil,
	"ball render keeps tracer/camera effects centralized"
)
assertTrue(ballRender:find("0.35", 1, true) ~= nil, "ball render uses mild MVP tween duration")

print("Golf Pro launch audit tests passed")
