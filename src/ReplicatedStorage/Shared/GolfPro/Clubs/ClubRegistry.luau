--!strict

local defaultClubSet = require("./default_club_set_v1")

export type ClubSpec = typeof(defaultClubSet[1])

local ClubRegistry = {}

local byId: { [string]: ClubSpec } = {}

local REQUIRED_FIELDS = {
	"id",
	"displayName",
	"category",
	"maxCarryYards",
	"minCarryYards",
	"loftDeg",
	"baseDispersionYards",
	"mishitPenalty",
	"spinBias",
	"rollBias",
	"allowedShotTypes",
	"rankedStatProfile",
}

local function validateClub(club: ClubSpec)
	for _, field in REQUIRED_FIELDS do
		assert(club[field] ~= nil, ("Club %s missing %s"):format(tostring(club.id), field))
	end

	assert(club.maxCarryYards > club.minCarryYards, club.id .. " carry range is invalid")
	assert(#club.allowedShotTypes > 0, club.id .. " needs at least one shot type")
end

for _, club in defaultClubSet do
	validateClub(club)
	assert(byId[club.id] == nil, "Duplicate club id: " .. club.id)
	byId[club.id] = club
end

function ClubRegistry.all(): { ClubSpec }
	return defaultClubSet
end

function ClubRegistry.get(clubId: string): ClubSpec?
	return byId[clubId]
end

function ClubRegistry.requireClub(clubId: string): ClubSpec
	local club = ClubRegistry.get(clubId)
	assert(club ~= nil, "Unknown club: " .. clubId)
	return club :: ClubSpec
end

function ClubRegistry.validateAll()
	assert(#defaultClubSet == 14, "Golf Pro must ship with exactly 14 default clubs")
	for _, club in defaultClubSet do
		validateClub(club)
	end
end

return ClubRegistry
