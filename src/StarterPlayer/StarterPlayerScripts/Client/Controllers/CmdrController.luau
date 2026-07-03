--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CmdrController = {}

local started = false

function CmdrController.start()
	if started then
		return
	end

	started = true

	task.spawn(function()
		local cmdrClient = ReplicatedStorage:WaitForChild("CmdrClient", 10)
		if cmdrClient == nil then
			warn("[Nexus] CmdrClient was not replicated within 10 seconds")
			return
		end

		local ok, cmdr = pcall(require, cmdrClient :: any)
		if not ok then
			warn("[Nexus] Cmdr client failed to load: " .. tostring(cmdr))
			return
		end

		cmdr:SetActivationKeys({ Enum.KeyCode.F2 })
		cmdr:SetPlaceName("Nexus")
		print("[Nexus] Cmdr client online")
	end)
end

return CmdrController
