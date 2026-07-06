--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local Constants = require("../src/ReplicatedStorage/Shared/GolfPro/Constants")
local WorldConfig = require("../src/ReplicatedStorage/Shared/GolfPro/World/WorldConfig")
local Pinebrook = require("../src/ReplicatedStorage/Shared/GolfPro/Courses/course_pinebrook_v1")
local PracticeRange =
	require("../src/ReplicatedStorage/Shared/GolfPro/Courses/course_practice_range_v1")
local MysteryRangeConfig =
	require("../src/ReplicatedStorage/Shared/GolfPro/Config/MysteryRangeConfig")

local OUT = "maps/Default.model.json"
local SCALE = WorldConfig.STUDS_PER_YARD

local function rgb(r: number, g: number, b: number): { number }
	return { r / 255, g / 255, b / 255 }
end

local COLORS = {
	rough = rgb(24, 83, 36),
	fairway = rgb(67, 150, 73),
	tee = rgb(70, 183, 82),
	green = rgb(54, 190, 91),
	bunker = rgb(218, 195, 128),
	water = rgb(36, 111, 164),
	path = rgb(132, 112, 84),
	stone = rgb(74, 80, 79),
	wood = rgb(115, 76, 43),
	white = rgb(244, 244, 236),
	gold = rgb(232, 188, 91),
	treeTrunk = rgb(84, 58, 31),
	treeTop = rgb(28, 111, 54),
}

local MATERIALS = {
	rough = "Grass",
	fairway = "Grass",
	tee = "Grass",
	green = "Grass",
	bunker = "Sand",
	water = "Glass",
	path = "Cobblestone",
	stone = "Slate",
	wood = "WoodPlanks",
	metal = "Metal",
	neon = "Neon",
}

local function props(
	size: { number },
	position: { number },
	color: { number },
	material: string
): any
	return {
		Anchored = true,
		Size = size,
		Position = position,
		Color = color,
		Material = material,
	}
end

local function part(
	name: string,
	size: { number },
	position: { number },
	color: { number },
	material: string
): any
	return {
		Name = name,
		ClassName = "Part",
		Properties = props(size, position, color, material),
	}
end

local function spawn(name: string, position: { number }, color: { number }): any
	local properties = props({ 18, 1, 18 }, position, color, MATERIALS.wood)
	properties.Neutral = true
	properties.Duration = 0
	properties.AllowTeamChangeOnTouch = false
	return {
		Name = name,
		ClassName = "SpawnLocation",
		Properties = properties,
	}
end

local function folder(name: string, children: { any }): any
	return {
		Name = name,
		ClassName = "Folder",
		Children = children,
	}
end

local function world(origin: { x: number, z: number }, point: any, y: number): { number }
	return {
		origin.x + (point.x or 0) * SCALE,
		y,
		origin.z + (point.y or 0) * SCALE,
	}
end

local function rectPart(
	name: string,
	origin: { x: number, z: number },
	bounds: any,
	y: number,
	height: number,
	color: { number },
	material: string
): any
	local width = math.max(2, (bounds.maxX - bounds.minX) * SCALE)
	local depth = math.max(2, (bounds.maxY - bounds.minY) * SCALE)
	local center = {
		x = (bounds.minX + bounds.maxX) * 0.5,
		y = (bounds.minY + bounds.maxY) * 0.5,
	}
	local guide = part(name, { width, height, depth }, world(origin, center, y), color, material)
	guide.Properties.Transparency = 0.62
	guide.Properties.CanCollide = false
	guide.Properties.CanTouch = false
	guide.Properties.CanQuery = false
	return guide
end

local function surfaceMeta(surface: string): (string, { number }, string, number, number)
	if surface == Constants.Surface.TEE then
		return "Tee", COLORS.tee, MATERIALS.tee, 1.2, 1.1
	end
	if surface == Constants.Surface.FAIRWAY then
		return "Fairway", COLORS.fairway, MATERIALS.fairway, 0.75, 0.65
	end
	if surface == Constants.Surface.GREEN then
		return "Green", COLORS.green, MATERIALS.green, 1.05, 0.95
	end
	if surface == Constants.Surface.BUNKER then
		return "Bunker", COLORS.bunker, MATERIALS.bunker, 0.55, 0.5
	end
	if surface == Constants.Surface.WATER then
		return "Water", COLORS.water, MATERIALS.water, 0.25, 0.2
	end
	return "Rough", COLORS.rough, MATERIALS.rough, 0.45, 0.35
end

local function treeParts(name: string, x: number, z: number): { any }
	return {
		part(name .. "_Trunk", { 4, 24, 4 }, { x, 12, z }, COLORS.treeTrunk, "Wood"),
		part(name .. "_Canopy", { 28, 24, 28 }, { x, 34, z }, COLORS.treeTop, "Grass"),
	}
end

local function addHoleScenery(
	children: { any },
	holeName: string,
	origin: { x: number, z: number },
	hole: any
)
	local yardage = hole.yardage
	for _, marker in { 100, 150, 200 } do
		if marker < yardage - 40 then
			table.insert(
				children,
				part(
					("%s_%dYdMarker"):format(holeName, marker),
					{ 10, 0.8, 4 },
					world(origin, { x = -72, y = marker }, 1.5),
					COLORS.white,
					"SmoothPlastic"
				)
			)
		end
	end

	local flagBase = world(origin, hole.pin, 14)
	table.insert(
		children,
		part(holeName .. "_PinFlagPole", { 0.8, 28, 0.8 }, flagBase, COLORS.white, "Metal")
	)
	table.insert(
		children,
		part(
			holeName .. "_PinFlag",
			{ 16, 8, 0.6 },
			{ flagBase[1] + 8, 24, flagBase[3] },
			COLORS.gold,
			"SmoothPlastic"
		)
	)

	for index, spec in
		{
			{ x = -118, y = math.max(70, yardage * 0.24) },
			{ x = 116, y = math.max(90, yardage * 0.42) },
			{ x = -122, y = math.max(130, yardage * 0.68) },
			{ x = 124, y = math.max(160, yardage * 0.82) },
		}
	do
		for _, tree in
			treeParts(
				("%s_Tree%02d"):format(holeName, index),
				world(origin, spec, 0)[1],
				world(origin, spec, 0)[3]
			)
		do
			table.insert(children, tree)
		end
	end
end

local function addHole(folderChildren: { any }, hole: any, origin: { x: number, z: number })
	local holeName = ("Hole%02d"):format(hole.index)
	local children = {}
	table.insert(
		children,
		rectPart(
			holeName .. "_Rough",
			origin,
			{ minX = -132, maxX = 132, minY = -26, maxY = hole.yardage + 56 },
			0,
			0.45,
			COLORS.rough,
			MATERIALS.rough
		)
	)

	local counts: { [string]: number } = {
		Rough = 1,
	}
	local hasFairway = false
	for _, zone in hole.zones do
		if zone.surface == Constants.Surface.FAIRWAY then
			hasFairway = true
			break
		end
	end
	if not hasFairway then
		local approachEnd = math.max(70, hole.yardage - 38)
		table.insert(
			children,
			rectPart(
				holeName .. "_Fairway",
				origin,
				{ minX = -18, maxX = 18, minY = 34, maxY = approachEnd },
				0.75,
				0.65,
				COLORS.fairway,
				MATERIALS.fairway
			)
		)
		counts.Fairway = 1
	end
	for _, zone in hole.zones do
		local label, color, material, y, height = surfaceMeta(zone.surface)
		counts[label] = (counts[label] or 0) + 1
		local name = if counts[label] == 1
			then holeName .. "_" .. label
			else ("%s_%s_%d"):format(holeName, label, counts[label])
		table.insert(children, rectPart(name, origin, zone.bounds, y, height, color, material))
	end

	addHoleScenery(children, holeName, origin, hole)
	table.insert(folderChildren, folder(holeName, children))
end

local function addConnectors(children: { any }, course: any, mode: string, holeCount: number)
	local paths = {}
	for index = 1, holeCount - 1 do
		local fromOrigin = WorldConfig.originFor(course.id, mode, index)
		local toOrigin = WorldConfig.originFor(course.id, mode, index + 1)
		local a = world(fromOrigin, course.holes[index].pin, 0.9)
		local b = world(toOrigin, course.holes[index + 1].tee, 0.9)
		local center = {
			(a[1] + b[1]) * 0.5,
			0.65,
			(a[3] + b[3]) * 0.5,
		}
		table.insert(
			paths,
			part(("Hole%02d_ToHole%02d_Path"):format(index, index + 1), {
				math.max(18, math.abs(a[1] - b[1]) + 18),
				0.4,
				math.max(18, math.abs(a[3] - b[3]) + 18),
			}, center, COLORS.path, MATERIALS.path)
		)
	end
	if #paths > 0 then
		table.insert(children, folder("DebugCartPaths", paths))
	end
end

local function courseFolder(name: string, course: any, mode: string, holeCount: number): any
	local children = {}
	if mode == Constants.Mode.SOLO_STROKE_18 then
		table.insert(
			children,
			spawn(
				"PlaytestSpawn",
				world(WorldConfig.originFor(course.id, mode, 1), course.holes[1].tee, 5),
				COLORS.gold
			)
		)
	end
	for index = 1, holeCount do
		addHole(children, course.holes[index], WorldConfig.originFor(course.id, mode, index))
	end
	addConnectors(children, course, mode, holeCount)
	return folder(name, children)
end

local function destinations(): any
	local children = {
		spawn("ClubhouseSpawn", { 0, 5, -560 }, COLORS.gold),
	}
	for index = 1, 18 do
		local origin = WorldConfig.originFor(Pinebrook.id, Constants.Mode.SOLO_STROKE_18, index)
		table.insert(
			children,
			spawn(
				WorldConfig.destinationName(Pinebrook.id, Constants.Mode.SOLO_STROKE_18, index),
				world(origin, Pinebrook.holes[index].tee, 5),
				COLORS.tee
			)
		)
	end
	for index = 1, 3 do
		local origin =
			WorldConfig.originFor(Pinebrook.id, Constants.Mode.SOLO_STROKE_3_DEBUG, index)
		table.insert(
			children,
			spawn(
				WorldConfig.destinationName(Pinebrook.id, Constants.Mode.SOLO_STROKE_3_DEBUG, index),
				world(origin, Pinebrook.holes[index].tee, 5),
				COLORS.tee
			)
		)
	end
	local rangeOrigin = WorldConfig.originFor(PracticeRange.id, Constants.Mode.PRACTICE, 1)
	table.insert(
		children,
		spawn(
			WorldConfig.destinationName(PracticeRange.id, Constants.Mode.PRACTICE, 1),
			world(rangeOrigin, PracticeRange.holes[1].tee, 5),
			COLORS.tee
		)
	)
	return folder("WorldDestinations", children)
end

local function cartSpawn(name: string, position: { number }): any
	local marker = part(name, { 22, 1, 28 }, position, COLORS.gold, MATERIALS.neon)
	marker.Properties.Transparency = 0.35
	marker.Properties.CanCollide = false
	marker.Properties.CanTouch = false
	marker.Properties.CanQuery = false
	return marker
end

local function cartSpawns(): any
	local children = {
		cartSpawn("ClubhouseCartSpawn", { -360, 3, -310 }),
		cartSpawn(
			"DrivingRangeCartSpawn",
			world(
				WorldConfig.originFor(PracticeRange.id, Constants.Mode.PRACTICE, 1),
				{ x = 54, y = -20 },
				3
			)
		),
	}
	for _, index in { 1, 6, 12, 18 } do
		table.insert(
			children,
			cartSpawn(
				("PinebrookHole%02dCartSpawn"):format(index),
				world(
					WorldConfig.originFor(Pinebrook.id, Constants.Mode.SOLO_STROKE_18, index),
					{ x = 58, y = -22 },
					3
				)
			)
		)
	end
	for index = 1, 3 do
		table.insert(
			children,
			cartSpawn(
				("PracticeHole%02dCartSpawn"):format(index),
				world(
					WorldConfig.originFor(Pinebrook.id, Constants.Mode.SOLO_STROKE_3_DEBUG, index),
					{ x = 48, y = -18 },
					3
				)
			)
		)
	end
	return folder("WorldCartSpawns", children)
end

local function hub(): any
	local children = {
		part("ClubhousePlaza", { 900, 1, 540 }, { 0, 0, -540 }, COLORS.stone, MATERIALS.stone),
		part("ClubhouseMain", { 260, 70, 120 }, { 0, 36, -730 }, COLORS.wood, MATERIALS.wood),
		part("ClubhouseRoof", { 300, 24, 150 }, { 0, 84, -730 }, rgb(42, 48, 55), "Slate"),
		part(
			"PuttingGreenPreview",
			{ 190, 0.6, 130 },
			{ -280, 0.7, -455 },
			COLORS.green,
			MATERIALS.green
		),
		part("DrivingRangePortal", { 150, 2, 88 }, { -270, 1.5, -290 }, COLORS.tee, MATERIALS.tee),
		part("PracticeHolesPortal", { 150, 2, 88 }, { 0, 1.5, -290 }, COLORS.gold, MATERIALS.neon),
		part("Pinebrook18Portal", { 150, 2, 88 }, { 270, 1.5, -290 }, COLORS.water, MATERIALS.neon),
		part("WorldMapBoard", { 430, 72, 8 }, { 0, 42, -210 }, COLORS.wood, MATERIALS.wood),
		part("WorldScaleMarker", { 300, 1, 10 }, { 0, 1.2, -120 }, COLORS.white, "SmoothPlastic"),
	}
	return folder("WorldHub_UltraPass", children)
end

local function targetParts(parentName: string): any
	local origin = WorldConfig.originFor(PracticeRange.id, Constants.Mode.PRACTICE, 1)
	local children = {}
	for _, target in MysteryRangeConfig.targets do
		local color = if target.zoneId == "starter"
			then COLORS.gold
			elseif target.zoneId == "canyon" then rgb(196, 109, 53)
			else rgb(76, 204, 176)
		table.insert(
			children,
			part(
				target.displayName:gsub("%s+", "") .. "_TargetPad",
				{ target.radiusYards * 2, 0.8, target.radiusYards * 2 },
				world(origin, target.position, 2),
				color,
				MATERIALS.neon
			)
		)
	end
	table.insert(
		children,
		part(
			"RangeVaultMachine",
			{ 28, 42, 22 },
			world(origin, { x = -58, y = 24 }, 22),
			COLORS.gold,
			"Metal"
		)
	)
	table.insert(
		children,
		part(
			"UpgradeBoard",
			{ 62, 34, 6 },
			world(origin, { x = 58, y = 28 }, 20),
			COLORS.wood,
			MATERIALS.wood
		)
	)
	table.insert(
		children,
		part(
			"RangeSharkObstacle",
			{ 54, 16, 130 },
			world(origin, { x = 88, y = 236 }, 9),
			rgb(45, 80, 105),
			"Slate"
		)
	)
	return folder(parentName, children)
end

local model = {
	ClassName = "Folder",
	Children = {
		hub(),
		destinations(),
		cartSpawns(),
		courseFolder("DrivingRange_UltraPass", PracticeRange, Constants.Mode.PRACTICE, 1),
		courseFolder("PracticeHoles_UltraPass", Pinebrook, Constants.Mode.SOLO_STROKE_3_DEBUG, 3),
		courseFolder(
			"PinebrookNational_Blockout_Phase4",
			Pinebrook,
			Constants.Mode.SOLO_STROKE_18,
			18
		),
		targetParts("MysteryRangeRoot"),
	},
}

fs.writeFile(OUT, serde.encode("json", model, true) .. "\n")
print("Wrote upgraded Golf Pro world to " .. OUT)
