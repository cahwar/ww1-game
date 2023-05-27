local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)

local Controllers = ReplicatedStorage.Common.Controllers
local Components = ReplicatedStorage.Common.Components

for _,v: ModuleScript in Controllers:GetChildren() do
    if v:GetAttribute("IsActive") ~= false then require(v) end
end

Knit:Start():andThen(function()
    for _,v: ModuleScript in Components:GetChildren() do
        if v:GetAttribute("IsActive") ~= false then require(v) end
    end
end):catch(warn)