--!strict

local fs = require("@lune/fs")

local DATA_SERVICE_PATH = "src/ServerScriptService/Server/Services/DataService.luau"
local PROFILE_SCHEMA_PATH = "src/ReplicatedStorage/Shared/Data/ProfileSchema.luau"
local MIGRATIONS_PATH = "src/ReplicatedStorage/Shared/Data/Migrations.luau"
local MIGRATION_LOGIC_PATH = "src/ReplicatedStorage/Shared/Data/MigrationLogic.luau"
local WALLY_LOCK_PATH = "wally.lock"
local SAVE_DATA_NOTE_PATH = "C:/Users/jackw/Roblox/RobloxGameVault/02_Systems/Save Data.md"

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

local dataService = read(DATA_SERVICE_PATH)
local profileSchema = read(PROFILE_SCHEMA_PATH)
local migrations = read(MIGRATIONS_PATH)
local migrationLogic = read(MIGRATION_LOGIC_PATH)
local wallyLock = read(WALLY_LOCK_PATH)
local saveDataNote = read(SAVE_DATA_NOTE_PATH)

assertContains(wallyLock, 'name = "lm-loleris/profilestore"', "ProfileStore must be locked")
assertContains(wallyLock, 'version = "1.0.3"', "ProfileStore lock version")

assertContains(dataService, 'local STORE_NAME = "NexusPlayerProfiles_v1"', "DataService store name")
assertContains(dataService, "ProfileStore.New(STORE_NAME", "DataService must create ProfileStore")
assertContains(
	dataService,
	"ProfileSchema.createDefaultProfile()",
	"DataService must use schema defaults"
)
assertContains(
	dataService,
	"if RunService:IsStudio() then baseStore.Mock else baseStore",
	"DataService must use ProfileStore.Mock in Studio"
)
assertContains(
	dataService,
	"playerStore:StartSessionAsync(profileKey(player), {",
	"DataService must start a ProfileStore session"
)
assertContains(dataService, "Cancel = function()", "DataService session must include cancel guard")
assertContains(
	dataService,
	"return player.Parent ~= Players",
	"DataService cancel guard must stop stale loads"
)
assertContains(
	dataService,
	'player:Kick("Profile load failed. Please rejoin.")',
	"nil session must kick"
)
assertContains(dataService, "profile:AddUserId(player.UserId)", "DataService must add user id")
assertContains(dataService, "profile:Reconcile()", "DataService must reconcile template fields")
assertContains(
	dataService,
	"profile.Data = Migrations.migrate(profile.Data)",
	"DataService must migrate profile data"
)
assertContains(
	dataService,
	"profile.OnSessionEnd:Connect(function()",
	"DataService must handle session end"
)
assertContains(dataService, "profiles[player] = nil", "DataService must clear cached profiles")
assertContains(
	dataService,
	'player:Kick("Profile session ended. Please rejoin.")',
	"DataService must kick on active session end"
)
assertContains(dataService, "profile:EndSession()", "DataService must release sessions")
assertContains(
	dataService,
	"Players.PlayerAdded:Connect(loadProfile)",
	"DataService must load on join"
)
assertContains(
	dataService,
	"Players.PlayerRemoving:Connect(releaseProfile)",
	"DataService must release on leave"
)
assertContains(
	dataService,
	'Net.setServerInvoke("RequestProfileSnapshot", snapshotProfile)',
	"DataService must own profile snapshot remote"
)
assertContains(dataService, "function DataService.getProfile", "DataService must expose getProfile")
assertContains(
	dataService,
	"function DataService.setKey",
	"DataService must expose server-owned setKey"
)
assertContains(
	dataService,
	"function DataService.addInventoryItem",
	"DataService must expose inventory mutation for server commands"
)
assertContains(
	dataService,
	"data.inventory.items[itemKey] = (data.inventory.items[itemKey] or 0) + amount",
	"DataService inventory mutation must preserve existing item counts"
)
assertContains(
	dataService,
	"function DataService.setStat",
	"DataService must expose schema-backed stat mutation"
)
assertContains(
	dataService,
	'return false, ("Unknown stat %q. Expected level or xp."):format(statKey)',
	"DataService stat mutation must reject unknown stat keys"
)
assertContains(
	dataService,
	"function DataService.resetProfile",
	"DataService must expose profile reset for Owner-only profilewipe"
)
assertContains(
	dataService,
	"profile.Data = ProfileSchema.createDefaultProfile()",
	"DataService reset must use schema defaults"
)
assertContains(dataService, "function DataService.release", "DataService must expose release")
assertContains(dataService, "function DataService.isMockMode", "DataService must expose mock mode")

assertContains(dataService, "local function snapshotProfile", "Missing snapshotProfile block")
assertContains(
	dataService,
	"schema_version = data.schema_version",
	"snapshot must include schema version"
)
assertContains(dataService, "currencies = data.currencies", "snapshot must include currencies")
assertContains(dataService, "stats = data.stats", "snapshot must include stats")
assertTrue(
	dataService:find("inventory = data.inventory", 1, true) == nil,
	"snapshot must not expose inventory by default"
)
assertTrue(
	dataService:find("flags = data.flags", 1, true) == nil,
	"snapshot must not expose flags by default"
)

assertContains(profileSchema, "ProfileSchema.CURRENT_VERSION = 3", "profile schema version")
for _, field in { "schema_version", "currencies", "inventory", "stats", "flags", "golf" } do
	assertContains(profileSchema, field, "profile schema missing " .. field)
end
for _, field in
	{ "roundsCompleted", "rankedRoundsCompleted", "bestRounds", "courseRecordsHeld", "cosmetics" }
do
	assertContains(profileSchema, field, "profile schema missing phase 6 field " .. field)
end

assertContains(migrations, "MigrationLogic.migrate", "Migrations must delegate to migration logic")
assertContains(migrationLogic, "mergeDefaults", "Migration logic must merge defaults")
assertContains(
	migrationLogic,
	"data.schema_version = currentVersion",
	"Migration logic must advance version"
)

assertContains(
	saveDataNote,
	"lm-loleris/profilestore@1.0.3",
	"Save Data note must document dependency"
)
assertContains(saveDataNote, "NexusPlayerProfiles_v1", "Save Data note must document store")
assertContains(saveDataNote, "ProfileStore.Mock", "Save Data note must document Studio mock mode")
assertContains(saveDataNote, "StartSessionAsync", "Save Data note must document session start")
assertContains(saveDataNote, "OnSessionEnd", "Save Data note must document session end")
assertContains(saveDataNote, "DataService.release(player)", "Save Data note must document release")
assertContains(
	saveDataNote,
	"Studio runtime proof was accepted",
	"Save Data note must preserve G2 runtime proof"
)

print("DataService contract tests passed")
