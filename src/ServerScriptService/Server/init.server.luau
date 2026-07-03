--!strict

local NexusService = require(script.Services.NexusService)
local DataService = require(script.Services.DataService)
local MapService = require(script.Services.MapService)
local CmdrService = require(script.Services.CmdrService)

NexusService.start()
DataService.start()
MapService.start()
CmdrService.start()
