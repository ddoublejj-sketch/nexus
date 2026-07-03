--!strict

local ServerStorage = game:GetService("ServerStorage")

return function(context, assetName: string, position: Vector3?): string
	local assets = ServerStorage:FindFirstChild("Assets")
	local template = if assets then assets:FindFirstChild(assetName) else nil

	if template == nil then
		return ("No spawnable asset named %q exists under ServerStorage.Assets."):format(assetName)
	end

	local clone = template:Clone()
	clone.Parent = workspace

	local spawnPosition = position or Vector3.new(0, 5, 0)
	if clone:IsA("Model") then
		clone:PivotTo(CFrame.new(spawnPosition))
	elseif clone:IsA("BasePart") then
		clone.CFrame = CFrame.new(spawnPosition)
	end

	return ("%s spawned %q."):format(context.Executor.Name, assetName)
end
