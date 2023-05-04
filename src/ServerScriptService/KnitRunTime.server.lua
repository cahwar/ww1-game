local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)

local Components = ServerScriptService.Server.Components
local Services = ServerScriptService.Server.Services

for _,v: ModuleScript in Services:GetChildren() do
    if v:GetAttribute("IsActive") ~= false then require(v) end
end

Knit:Start():andThen(function()
    for _,v: ModuleScript in Components:GetChildren() do
        if v:GetAttribute("IsActive") ~= false then require(v) end
    end
end):catch(warn)