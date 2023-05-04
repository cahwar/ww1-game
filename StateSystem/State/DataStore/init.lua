local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local RetryCall = require(script.Parent.RetryCall)
local DataStore2 = require(ServerScriptService.Server.StateSystem.DataStore2)

MAIN_STORE_KEY = script.NameData.Value

local globalDataStore = DataStoreService:GetGlobalDataStore()
local globaDataStoreEvents = {}
local getGlobaDataStoreEvent -- forward func declaration

DataStore2.PatchGlobalSettings({
	SavingMethod = "Standard",
})


local module = {}

function module.GetData(key, player)
	DataStore2.Combine(MAIN_STORE_KEY, key)
	return DataStore2(key, player):Get()
end

function module.SetData(key, value, player)
	DataStore2.Combine(MAIN_STORE_KEY, key)
	DataStore2(key, player):Set(value)
end

function module.UpdateData(key, updateCallback, player)
	DataStore2.Combine(MAIN_STORE_KEY, key)
	local value = DataStore2(key, player):Get()
	DataStore2(key, player):Set(updateCallback(value))
end

function module.OnUpdate(key, callback, player)
	DataStore2.Combine(MAIN_STORE_KEY, key)
	DataStore2(key, player):OnUpdate(callback)
end

function module.GetGlobalData(key)
	local data = RetryCall.Do(globalDataStore.GetAsync, globalDataStore, key)
	return data
end

function module.SetGlobalData(key, value)
	getGlobaDataStoreEvent(key):Fire(value)
	RetryCall.Do(globalDataStore.SetAsync, globalDataStore, key, value)
end

function module.UpdateGlobalData(key, updateCallback)
	RetryCall.Do(globalDataStore.UpdateAsync, globalDataStore, key, function(oldVal)
		local value = updateCallback(oldVal)
		getGlobaDataStoreEvent(key):Fire(value)
		return value
	end)
end

function module.OnUpdateGlobal(key, callback)
	getGlobaDataStoreEvent(key).Event:Connect(callback)
end


---------------- local stuff ----------------

function getGlobaDataStoreEvent(key)
	if globaDataStoreEvents[key] == nil then
		globaDataStoreEvents[key] = Instance.new("BindableEvent")
	end
	return globaDataStoreEvents[key]
end

return module
