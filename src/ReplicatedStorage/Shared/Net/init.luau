--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

export type RemoteKind = "RemoteEvent" | "RemoteFunction"
export type RemoteDefinition = {
	name: string,
	kind: RemoteKind,
}

local REMOTES_FOLDER_NAME = "NexusRemotes"

local Net = {}

local remoteDefinitions: { [string]: RemoteDefinition } = {
	Ping = {
		name = "Ping",
		kind = "RemoteEvent",
	},
}

local function getOrCreateFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = REMOTES_FOLDER_NAME
	folder.Parent = ReplicatedStorage

	return folder
end

function Net.ensureRemotes(): Folder
	local folder = getOrCreateFolder()

	for _, definition in remoteDefinitions do
		local existing = folder:FindFirstChild(definition.name)
		if existing == nil then
			local remote = Instance.new(definition.kind)
			remote.Name = definition.name
			remote.Parent = folder
		end
	end

	return folder
end

function Net.getRemote(name: string): Instance?
	local folder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	if folder == nil then
		return nil
	end

	return folder:FindFirstChild(name)
end

return Net
