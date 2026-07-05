--!strict

local NexusService = require(script.Services.NexusService)
local DataService = require(script.Services.DataService)
local MapService = require(script.Services.MapService)
local CmdrService = require(script.Services.CmdrService)
local ShotService = require(script.Services.ShotService)

NexusService.start()
DataService.start()
MapService.start()
CmdrService.start()
ShotService.start()
