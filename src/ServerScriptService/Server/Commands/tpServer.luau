--!strict

return function(_, fromPlayers: { Player }, destination: Player | Vector3): string
	local destinationCFrame: CFrame?

	if typeof(destination) == "Instance" then
		local character = destination.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") then
			destinationCFrame = root.CFrame
		end
	elseif typeof(destination) == "Vector3" then
		destinationCFrame = CFrame.new(destination)
	end

	if destinationCFrame == nil then
		return "Destination is not available."
	end

	local moved = 0
	for _, player in fromPlayers do
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") then
			root.CFrame = destinationCFrame
			moved += 1
		end
	end

	return ("Teleported %d player(s)."):format(moved)
end
