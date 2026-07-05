--!strict

local CosmeticCatalog = {}

CosmeticCatalog.shopHooks = {
	enabled = false,
	cosmeticOnly = true,
	purchases = {},
}

CosmeticCatalog.categories = {
	ball_skin = {
		id = "ball_skin",
		displayName = "Ball Skin",
	},
	trail = {
		id = "trail",
		displayName = "Shot Trail",
	},
	bag_tag = {
		id = "bag_tag",
		displayName = "Bag Tag",
	},
	title = {
		id = "title",
		displayName = "Title",
	},
	profile_banner = {
		id = "profile_banner",
		displayName = "Profile Banner",
	},
}

CosmeticCatalog.items = {
	classic_white_ball = {
		id = "classic_white_ball",
		category = "ball_skin",
		displayName = "Classic White",
		defaultOwned = true,
		ballColor = { r = 244, g = 244, b = 236 },
		material = "SmoothPlastic",
	},
	sunrise_gold_ball = {
		id = "sunrise_gold_ball",
		category = "ball_skin",
		displayName = "Sunrise Gold",
		ballColor = { r = 250, g = 202, b = 84 },
		material = "SmoothPlastic",
	},
	pine_matte_ball = {
		id = "pine_matte_ball",
		category = "ball_skin",
		displayName = "Pine Matte",
		ballColor = { r = 74, g = 151, b = 112 },
		material = "SmoothPlastic",
	},
	classic_arc_trail = {
		id = "classic_arc_trail",
		category = "trail",
		displayName = "Classic Arc",
		defaultOwned = true,
		trailColor = { r = 145, g = 224, b = 255 },
	},
	copper_arc_trail = {
		id = "copper_arc_trail",
		category = "trail",
		displayName = "Copper Arc",
		trailColor = { r = 235, g = 151, b = 86 },
	},
	fairway_member_tag = {
		id = "fairway_member_tag",
		category = "bag_tag",
		displayName = "Fairway Member",
		defaultOwned = true,
	},
	range_regular_tag = {
		id = "range_regular_tag",
		category = "bag_tag",
		displayName = "Range Regular",
	},
	starter_title = {
		id = "starter_title",
		category = "title",
		displayName = "Starter",
		defaultOwned = true,
	},
	pin_seeker_title = {
		id = "pin_seeker_title",
		category = "title",
		displayName = "Pin Seeker",
	},
	clubhouse_banner = {
		id = "clubhouse_banner",
		category = "profile_banner",
		displayName = "Clubhouse Green",
		defaultOwned = true,
	},
	sunrise_banner = {
		id = "sunrise_banner",
		category = "profile_banner",
		displayName = "Sunrise Fairway",
	},
}

function CosmeticCatalog.get(cosmeticId: string): any?
	return (CosmeticCatalog.items :: any)[cosmeticId]
end

function CosmeticCatalog.all(): { any }
	local list = {}
	for _, item in CosmeticCatalog.items :: any do
		table.insert(list, item)
	end
	table.sort(list, function(a: any, b: any): boolean
		if a.category == b.category then
			return a.displayName < b.displayName
		end
		return a.category < b.category
	end)
	return list
end

function CosmeticCatalog.defaultEquipped(): { [string]: string }
	local equipped = {}
	for _, item: any in CosmeticCatalog.items :: any do
		if item.defaultOwned == true and equipped[item.category] == nil then
			equipped[item.category] = item.id
		end
	end
	return equipped
end

return CosmeticCatalog
