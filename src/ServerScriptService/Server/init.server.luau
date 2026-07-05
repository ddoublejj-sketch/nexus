--!strict

local NexusService = require(script.Services.NexusService)
local DataService = require(script.Services.DataService)
local MapService = require(script.Services.MapService)
local CmdrService = require(script.Services.CmdrService)
local PartyService = require(script.Services.PartyService)
local ScrambleService = require(script.Services.ScrambleService)
local MatchService = require(script.Services.MatchService)
local ShotService = require(script.Services.ShotService)

NexusService.start()
DataService.start()
MapService.start()
CmdrService.start()
PartyService.start()
ScrambleService.start()
MatchService.start()
ShotService.start()
