local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Common.Packages.Promise)

local Queue = {}
Queue.__index = Queue

function Queue.new()
	return setmetatable({
		Members = {},
	}, Queue)
end

function Queue:Enqueue(element: any?)
	local promise = Promise.new(function(resolve)
		table.insert(self.members, {
			Element = element,
			_resolve = resolve,
		})
	end)

	return promise
end

function Queue:Dequeue()
	local topMember = self.Members[1]
	if not topMember then
		return false
	end
	topMember._resolve()
	return topMember
end

return Queue
