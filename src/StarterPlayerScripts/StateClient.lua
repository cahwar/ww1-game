local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local remoteFn = ReplicatedStorage:WaitForChild("StateCommunications")
local storeUniqueName = remoteFn:InvokeServer("getStoreUniqueName")
-- forward func declaration:
local istanceTreeToTable, tableToInstanceTree

local function Get(self)
	local valueStore
	if self.owner == "Player" then
		valueStore = player:WaitForChild("PlayerGui"):WaitForChild(storeUniqueName):WaitForChild(self.keyOfValue)
	else
		valueStore = ReplicatedStorage:WaitForChild(storeUniqueName):WaitForChild(self.keyOfValue)
	end
	if valueStore.ClassName == "ObjectValue" then
		return istanceTreeToTable(valueStore.Value)
	else
		return valueStore.Value
	end
end

local function Set(self, value)
	if self.owner == "Player" then
		remoteFn:InvokeServer("setValue", self.keyOfValue, value)
	else
		error("StateClient: only player states are allowed", 2)
	end
end

local function Update(self, updateCallback)
	local value = self:Get()
	self:Set(updateCallback(value))
end

local function OnUpdate(self, callback)
	local valueStore
	if self.owner == "Player" then
		valueStore = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild(storeUniqueName):WaitForChild(self.keyOfValue)
	else
		valueStore = ReplicatedStorage:WaitForChild(storeUniqueName):WaitForChild(self.keyOfValue)
	end
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

local function Watch(self, callback)
	local valueStore
	if self.owner == "Player" then
		valueStore = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild(storeUniqueName):WaitForChild(self.keyOfValue)
	else
		valueStore = ReplicatedStorage:WaitForChild(storeUniqueName):WaitForChild(self.keyOfValue)
	end
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

local module = {}

function module.new(keyPath)
	local stateStore = {
		Get = Get,
		Set = Set,
		OnUpdate = OnUpdate,
		Watch = Watch,
	}
	local keyParts = string.split(keyPath, ".")
	stateStore.storeType = keyParts[1]
	stateStore.owner = keyParts[2]
	stateStore.keyOfValue = keyParts[3]
	if stateStore.storeType ~= "Replicated" then
		error("StateClient: only Replicated states are allowed", 2)
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
					local valObj = Instance.new(typesMapping[typeof(val)] or error("State: not implemented yet"))
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

return module
