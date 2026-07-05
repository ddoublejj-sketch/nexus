--!strict

local NexusController = require(script.Controllers.NexusController)
local CmdrController = require(script.Controllers.CmdrController)
local HUDController = require(script.Controllers.HUDController)
local SwingController = require(script.Controllers.SwingController)

NexusController.start()
CmdrController.start()
HUDController.start()
SwingController.start()
