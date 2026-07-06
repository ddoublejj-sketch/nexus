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

local ui = read("src/StarterPlayer/StarterPlayerScripts/Client/Controllers/UIController.luau")
for _, needle in
	{
		"GolfProUI",
		"MenuLayer",
		"PlayLayer",
		"BackToMenu",
		"createHudPanel",
		"createToolPanel",
		"createOverlayPanel",
		"showToolPanel",
	}
do
	assertContains(ui, needle, "UIController missing " .. needle)
end

local clientInit = read("src/StarterPlayer/StarterPlayerScripts/Client/init.client.luau")
assertContains(clientInit, "UIController.start", "client init missing UIController.start")
local uiStart = clientInit:find("UIController.start", 1, true) or 0
local hudStart = clientInit:find("HUDController.start", 1, true) or 0
assertTrue(uiStart > 0 and hudStart > uiStart, "UIController must start before HUDController")

local hud = read("src/StarterPlayer/StarterPlayerScripts/Client/Controllers/HUDController.luau")
for _, needle in
	{
		"UIController.setMainMenuActions",
		"Driving Range",
		"Practice Holes",
		"Pinebrook 18",
		"Party Lobby",
		"Constants.Mode.SOLO_STROKE_18",
	}
do
	assertContains(hud, needle, "HUDController missing menu flow " .. needle)
end

for _, path in
	{
		"src/StarterPlayer/StarterPlayerScripts/Client/Controllers/PartyController.luau",
		"src/StarterPlayer/StarterPlayerScripts/Client/Controllers/LockerController.luau",
		"src/StarterPlayer/StarterPlayerScripts/Client/Controllers/MysteryRangeController.luau",
		"src/StarterPlayer/StarterPlayerScripts/Client/Controllers/TournamentController.luau",
	}
do
	local contents = read(path)
	assertContains(contents, "UIController.createToolPanel", path .. " must use shell tool panel")
	for _, oldPosition in
		{
			"UDim2.fromOffset(18, 82)",
			"UDim2.fromOffset(360, 82)",
			"UDim2.fromOffset(828, 82)",
			"UDim2.fromOffset(18, 300)",
			"UDim2.fromOffset(340, 300)",
		}
	do
		assertTrue(
			contents:find(oldPosition, 1, true) == nil,
			path .. " still uses old overlapping fixed position " .. oldPosition
		)
	end
end

local scramble =
	read("src/StarterPlayer/StarterPlayerScripts/Client/Controllers/ScrambleController.luau")
assertContains(scramble, "UIController.createOverlayPanel", "Scramble vote must use overlay dock")

print("Golf Pro UI shell tests passed")
