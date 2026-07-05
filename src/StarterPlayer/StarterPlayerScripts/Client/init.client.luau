--!strict

local NexusController = require(script.Controllers.NexusController)
local CmdrController = require(script.Controllers.CmdrController)
local EquipmentController = require(script.Controllers.EquipmentController)
local BallRenderController = require(script.Controllers.BallRenderController)
local HUDController = require(script.Controllers.HUDController)
local PartyController = require(script.Controllers.PartyController)
local ScrambleController = require(script.Controllers.ScrambleController)
local SwingController = require(script.Controllers.SwingController)

NexusController.start()
CmdrController.start()
EquipmentController.start()
BallRenderController.start()
HUDController.start()
PartyController.start()
ScrambleController.start()
SwingController.start()
