local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local DataStore = require(script.Parent.DataStore)

local storeUniqueName
local initState = {}
local initStarted = false
local isReady = Instance.new("BoolValue")
-- forward func declaration:
local istanceTreeToTable, tableToInstanceTree, validateInitState, validateKeyParts,
generateStoreUniqueName, createValueBasedStore, initDataStoreBasedStore, destroyValueBasedStore,
createRemoteFn

-- TODO: split implementation into general and Roblox Players specifiс

--[[
    Retrieves a value stored in the state.
    
    Params:
    - player - the Player instance of the player whose data is needed, you should omit this for global data 
    
    Returns:
      value stored in the state
    
    Example:
      local cp = cpState:Get(player)
]]
local function Get(self, player)
	if self.storeType == "Persistent" then
		-- DataStore
		if self.owner == "Player" then
			return DataStore.GetData(self.keyOfValue, player)
		else
			return DataStore.GetGlobalData(self.keyOfValue)
		end
	else
		-- Value Instance
		local valueStore = self.getValueStore(player)
		if valueStore.ClassName == "ObjectValue" then
			return istanceTreeToTable(valueStore.Value)
		else
			return valueStore.Value
		end
	end
end

--[[
    Sets the value of the given state, and then fires off any OnUpdate/Watch callbacks.
    
    Params:
    - value - the value that the state will be set to
    - player - the Player instance of the player whose state is used, you should omit this for global data
    
    Returns:
      nothing
    
    Example:
      cpState:Set(42, player)
]]
local function Set(self, value, player)
	if self.storeType == "Persistent" then
		-- DataStore
		if self.owner == "Player" then
			return DataStore.SetData(self.keyOfValue, value, player)
		else
			return DataStore.SetGlobalData(self.keyOfValue, value)
		end
	else
		-- Value Instance
		local valueStore = self.getValueStore(player)
		if valueStore.ClassName == "ObjectValue" then
			local oldFolder = valueStore.Value
			if oldFolder then
				oldFolder.Name = "_deleted"
			end
			local newFolder = tableToInstanceTree(value)
			if newFolder then
				newFolder.Name = "Content"
				newFolder.Parent = valueStore
				valueStore.Value = newFolder
			end
			if oldFolder then
				oldFolder:Destroy()
			end
		else
			valueStore.Value = value
		end
	end
end

--[[
    Sets the value of the given state to the return of updateCallback when passed with the current value,
    and then fires off any OnUpdate/Watch callbacks.
    
    Params:
    - updateCallback - callback function that takes the current value as parameters and returns the new value
    - player - the Player instance of the player whose state is used, you should omit this for global data
    
    Returns:
      nothing
    
    Example:
      cpState:Update(function(oldValue)
          return oldValue + 10
      end)
]]
local function Update(self, updateCallback, player)
	if self.storeType == "Persistent" then
		-- DataStore
		if self.owner == "Player" then
			return DataStore.UpdateData(self.keyOfValue, updateCallback, player)
		else
			return DataStore.UpdateGlobalData(self.keyOfValue, updateCallback)
		end
	else
		-- Value Instance
		local value = self:Get(player)
		self:Set(updateCallback(value), player)
	end
end

--[[
    Will call the provided callback whenever the value of the specified state is updated.
    The callback is NOT called on the initial get. The callback is called with two params:
    	1. The value after the change.
    	2. Player, whose state is changed, nil for global data.
    
    Params:
    - callback - callback function (see above)
    - player - the Player instance of the player whose state is tracked, you should omit this for global data
    
    Returns:
      nothing
    
    Example:
      cpState:OnUpdate(function(newVal, player) print("newVal updated:", newVal, player.Name) end, player)
]]
local function OnUpdate(self, callback, player)
	if self.storeType == "Persistent" then
		-- DataStore
		if self.owner == "Player" then
			DataStore.OnUpdate(self.keyOfValue, function(val)
				callback(val, player)
			end, player)
		else
			DataStore.OnUpdateGlobal(self.keyOfValue, callback)
		end
	else
		-- Value Instance
		local valueStore = self.getValueStore(player)
		if valueStore.ClassName == "ObjectValue" then
			valueStore.Changed:Connect(function(istance)
				callback(istanceTreeToTable(istance), player)
			end)
		else
			valueStore.Changed:Connect(function(val)
				callback(val, player)
			end)
		end
	end
end

--[[
    Will call the provided callback whenever the value of the specified state is updated.
    Also, the callback is called immediately after the function call. The callback is called
    with two params:
    	1. The value after the change.
    	2. Player, whose state is changed, nil for global data.
    
    Params:
    - player - the Player instance of the player whose state is tracked, you should omit this for global data
    
    Returns:
      nothing
    
    Example:
      cpState:Watch(function(newVal, player) print("watching newVal:", newVal, player.Name) end, player)
]]
local function Watch(self, callback, player)
	if self.storeType == "Persistent" then
		-- DataStore
		if self.owner == "Player" then
			local value = DataStore.GetData(self.keyOfValue, player)
			DataStore.OnUpdate(self.keyOfValue, function(val)
				callback(val, player)
			end, player)
			callback(value, player)
		else
			local value = DataStore.GetGlobalData(self.keyOfValue)
			DataStore.OnUpdateGlobal(self.keyOfValue, callback)
			callback(value)
		end
	else
		-- Value Instance
		local valueStore = self.getValueStore(player)
		if valueStore.ClassName == "ObjectValue" then
			valueStore.Changed:Connect(function(istance)
				callback(istanceTreeToTable(istance), player)
			end)
			callback(istanceTreeToTable(valueStore.Value), player)
		else
			valueStore.Changed:Connect(function(val)
				callback(val, player)
			end)
			callback(valueStore.Value, player)
		end
	end
end

local module = {}

function module.Init(_initState)
	if initStarted then
		spawn(function()
			error("State already initialized", 3)
		end)
		return
	end
	initStarted = true
	validateInitState(_initState)
	initState = _initState
	storeUniqueName = generateStoreUniqueName()
	createValueBasedStore(initState.Server.Global, ServerStorage)
	createValueBasedStore(initState.Replicated.Global, ReplicatedStorage)
	initDataStoreBasedStore(initState.Persistent.Global)
	local initPlayer = function(player)
		createValueBasedStore(initState.Server.Player, ServerStorage, player)
		createValueBasedStore(initState.Replicated.Player, player:WaitForChild("PlayerGui"))
		initDataStoreBasedStore(initState.Persistent.Player, player)
	end
	for _, player in pairs(Players:GetPlayers()) do
		coroutine.wrap(initPlayer)(player)
	end
	Players.PlayerAdded:Connect(initPlayer)
	Players.PlayerRemoving:Connect(function(player)
		wait(0.5)
		destroyValueBasedStore(ServerStorage, player)
	end)
	createRemoteFn()
	isReady.Value = true
end

--[[
    Creates a new state object, located at path of the initial state passed in keyPath.
    
    Params:
    - keyPath (required) - path to the state, parts are joined by "." symbol
    
    Returns:
      the state object that is ready to work with data
    
    Example:
      local cpState = BeelineState.new("Server.Player.CharacterPoints")
]]
function module.new(keyPath)
	-- TODO: pre init states
	if not isReady.Value then
		isReady.Changed:Wait()
	end
	local keyParts = string.split(keyPath, ".")
	validateKeyParts(keyParts)
	local stateStore = {
		Update = Update,
		Get = Get,
		Set = Set,
		OnUpdate = OnUpdate,
		Watch = Watch,
	}
	stateStore.storeType = keyParts[1]
	stateStore.owner = keyParts[2]
	stateStore.keyOfValue = keyParts[3]
	if stateStore.storeType == "Replicated" then
		if stateStore.owner == "Player" then
			stateStore.getValueStore = function(player)
				return player:WaitForChild("PlayerGui"):WaitForChild(storeUniqueName)[stateStore.keyOfValue]
			end
		else
			stateStore.getValueStore = function()
				return ReplicatedStorage[storeUniqueName][stateStore.keyOfValue]
			end
		end
	elseif stateStore.storeType == "Server" then
		if stateStore.owner == "Player" then
			stateStore.getValueStore = function(player)
				return ServerStorage[storeUniqueName]:WaitForChild(player.Name)[stateStore.keyOfValue]
			end
		else
			stateStore.getValueStore = function()
				return ServerStorage[storeUniqueName][stateStore.keyOfValue]
			end
		end
	end
	return stateStore
end


---------------- local stuff ----------------

function istanceTreeToTable(folder)
	if folder == nil then
		return nil
	else
		local function iterateFolder(subFolder)
			local result = {}
			for _, valObj in pairs(subFolder:GetChildren()) do
				local key = valObj.Name
				if string.sub(key, 1, 6) == "#num#:" then
					key = tonumber(string.sub(key, 7))
				end
				if valObj.ClassName == "Configuration" then
					result[key] = iterateFolder(valObj)
				elseif valObj:IsA("ValueBase") then
					result[key] = valObj.Value
				else
					result[key] = valObj
				end
			end
			return result
		end
		return iterateFolder(folder)
	end
end

function tableToInstanceTree(aTable)
	-- TODO: add reusing old Instances
	if aTable == nil then
		return nil
	else
		local function iterateTable(subTable)
			local result = Instance.new("Configuration")
			for key, val in pairs(subTable) do
				if typeof(key) == "number" then
					key = "#num#:"..key
				end
				if typeof(val) == "table" then
					local folder = iterateTable(val)
					folder.Name = key
					folder.Parent = result
				else
					local typesMapping = {
						["number"] = "NumberValue",
						["boolean"] = "BoolValue",
						["string"] = "StringValue",
						["Instance"] = "ObjectValue",
					}
					local valObj = Instance.new(typesMapping[typeof(val)] or error("BeelineState: not implemented yet"))
					valObj.Name = key
					valObj.Value = val
					valObj.Parent = result
				end
			end
			return result
		end
		return iterateTable(aTable)
	end
end

function validateInitState(initState)
	--  TODO
end

function validateKeyParts(keyParts)
	if table.getn(keyParts) ~= 3 then
		error("State: wrong key path format, key path format - <StorageType>.<OwnershipType>.<Key>", 3)
	end
	local storeType = keyParts[1]
	local owner = keyParts[2]
	local key = keyParts[3]
	if storeType ~= "Persistent" and storeType ~= "Server" and storeType ~= "Replicated" then
		error("State: storage type \""..storeType.."\" is incorrect", 3)
	end
	if owner ~= "Player" and owner ~= "Global" then
		error("State: ownership type can only be one of two: Player or Global, got - "..owner, 3)
	end
	local initStatesOfOwner = initState[storeType] and initState[storeType][owner] or {}
	if initStatesOfOwner[key] == nil then
		error("State: key \""..key.."\" not found in \""..storeType.."."..owner.."\", check the correctness of the key path", 3)
	end
end

function generateStoreUniqueName()
	return string.sub(HttpService:GenerateGUID(false), 1, 8).."_State"
end

function createValueBasedStore(defaultState, parent, player)
	local root = parent:FindFirstChild(storeUniqueName)
	if root == nil then
		if parent.Name == "PlayerGui" then
			root = Instance.new("ScreenGui")
			root.ResetOnSpawn = false
		else
			root = Instance.new("Configuration")
		end
		root.Name = storeUniqueName
		root.Parent = parent
	end
	if player then
		local playerRoot = root:FindFirstChild(player.Name)
		if playerRoot ~= nil then
			spawn(function()
				error("State: duplicate player.Name found")
			end)
		else
			playerRoot = Instance.new("Configuration")
			playerRoot.Name = player.Name
			playerRoot.Parent = root
			root = playerRoot
		end
	end
	for key, val in pairs(defaultState) do
		local typesMapping = {
			["number"] = "NumberValue",
			["boolean"] = "BoolValue",
			["string"] = "StringValue",
			["table"] = "ObjectValue",
		}
		local valObj = Instance.new(typesMapping[typeof(val)] or error("State: not implemented yet"))
		valObj.Name = key
		if typeof(val) == "table" then
			local tableHolder = Instance.new("Configuration")
			tableHolder.Name = "Content"
			tableHolder.Parent = valObj
			valObj.Value = tableHolder
		else
			valObj.Value = val
		end
		valObj.Parent = root
	end
end

function destroyValueBasedStore(parent, player)
	pcall(function()
		parent[storeUniqueName][player.Name]:Destroy()
	end)
end

function initDataStoreBasedStore(defaultState, player)
	for key, val in pairs(defaultState) do
		if player then
			local storedVal = DataStore.GetData(key, player)
			if storedVal == nil then
				DataStore.SetData(key, val, player)
			end
		else
			local storedVal = DataStore.GetGlobalData(key)
			if storedVal == nil then
				DataStore.SetGlobalData(key, val)
			end
		end
	end
end

function createRemoteFn()
	local remoteFn = Instance.new("RemoteFunction")
	remoteFn.Name = "StateCommunications"
	remoteFn.OnServerInvoke = function(player, method, ...)
		if method == "getStoreUniqueName" then
			return storeUniqueName
		elseif method == "setValue" then
			local key, value = ...
			module.new("Replicated.Player."..key):Set(value, player)
		end
	end
	remoteFn.Parent = ReplicatedStorage
end


--function hashstr(srt)
--	local length = string.len(srt);
--	local hash = length;					-- seed the hash with the length
--	local step = bit32.rshift(hash, 5) + 1;	-- if the string is too long, don't hash everything
--	local length1 = length;

--	while length1 >= step do				-- compute the hash
--		hash = bit32.bxor(
--			hash,
--			bit32.lshift(hash, 5)
--				+ bit32.rshift(hash, 2)
--				+ srt:sub(length1, length1):byte()
--		); -- h = h ^ ((h<<5)+(h>>2)+cast(unsigned char, str[l1-1]));
--		length1 = length1 - step;
--	end
--	return string.format("%x", hash);
--end

return module
