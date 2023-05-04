local ServerScriptService = game:GetService("ServerScriptService")
local State = require(ServerScriptService.Server.StateSystem.State.Main)
local ServerConfig = require(script.Parent.ServerConfig)

return function()
	State.Init(ServerConfig.InitState)
end
