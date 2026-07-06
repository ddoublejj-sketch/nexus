--!strict

local DurableStore = {}

local function runService(): any?
	if game == nil then
		return nil
	end

	local ok, service = pcall(function()
		return game:GetService("RunService")
	end)
	return if ok then service else nil
end

local function dataStoreService(): any?
	if not DurableStore.isLive() then
		return nil
	end

	local ok, service = pcall(function()
		return game:GetService("DataStoreService")
	end)
	return if ok then service else nil
end

function DurableStore.isLive(): boolean
	local service = runService()
	return service ~= nil and not service:IsStudio()
end

function DurableStore.getDataStore(name: string): any?
	local service = dataStoreService()
	if service == nil then
		return nil
	end

	local ok, store = pcall(function()
		return service:GetDataStore(name)
	end)
	return if ok then store else nil
end

function DurableStore.getOrderedDataStore(name: string): any?
	local service = dataStoreService()
	if service == nil then
		return nil
	end

	local ok, store = pcall(function()
		return service:GetOrderedDataStore(name)
	end)
	return if ok then store else nil
end

return DurableStore
