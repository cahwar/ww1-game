local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local GameAnalytics = require(ServerScriptService.Server.StateSystem.GameAnalytics)

local TIMEOUT = 30 -- seconds
local RETRIES_DEFAULT = 3
local RETRY_DELAY_DEFAULT = 0.5 -- seconds
local reportError -- forward func declaration

local module = {}

--[[
    Calls function "func" with the given arguments in protected mode with additional settings.
    See more info in the documentation of the `module.Do` function below.
    
    Params:
    - retries (required) - number of retries on error in previous call
    - retryDelay (required) - delay between retries, multiplies every retry
    - func (required) - the function to be called
    - ... - any arguments that will be passed to "func"
    
    Returns:
      result of the "func" plus `true` on success, or `nil, false, false, false`
    
    Example:
      local pages = RetryCall.DoWithOptions(2, 0, AssetService.GetGamePlacesAsync, AssetService)
]]
function module.DoWithOptions(retries, retryDelay, func, ...)
	local deadline = tick() + TIMEOUT
	local timeIsOver = false
	local err
	while retries >= 0 do
		if tick() >= deadline then
			timeIsOver = true
			break
		end
		retries -= 1
		local success, res1, res2, res3 = pcall(func, ...)
		if success then
			if err then
				reportError(func, err, true)
			end
			if res3 ~= nil then
				return res1, res2, res3, true
			elseif res2 ~= nil then
				return res1, res2, true
			else
				return res1, true
			end
		else
			err = res1
		end
		wait(retryDelay)
		retryDelay *= 2
	end
	reportError(func, err, false, timeIsOver)
	return nil, false, false, false
end

--[[
    Calls function "func" with the given arguments in protected mode. This means that
    any error inside func is not propagated; instead, `Do` catches the error and makes retry.
    It uses default settings of the retry logic.
    
    Params:
    - func (required) - the function to be called
    - ... - any arguments that will be passed to "func"
    
    Returns:
      result of the "func" plus `true` on success, or `nil, false, false, false`
    
    Example:
      local pages, ok = RetryCall.Do(AssetService.GetGamePlacesAsync, AssetService)
]]
function module.Do(func, ...)
	return module.DoWithOptions(RETRIES_DEFAULT, RETRY_DELAY_DEFAULT, func, ...)
end


---------------- local stuff ----------------

function reportError(func, err, justWarn, timeIsOver)
	local trace = debug.traceback(nil, 3)
	local sourceName, sourceLine, funcName = debug.info(func, "sln")
	if trace == nil then
		trace = "(null)"
	end
	if sourceName == nil then
		sourceName = "(null)"
	end
	if sourceLine < 1 then
		sourceLine = "??"
	end
	if funcName == nil then
		funcName = "anonymous"
	end
	if err == nil then
		err = "(null)"
	end
	local timeIsOverMsg = timeIsOver and "retry timeout, " or ""
	local message = "SafeCall.DoWithOptions failed: "..timeIsOverMsg.."function: "..funcName.." ["..sourceName..":"..sourceLine.."], error: "..err..", trace: "..trace;
	if string.len(message) > 8192 then
		message = string.sub(message, 1, 8192)
	end
	warn(message)
	local severity = justWarn and GameAnalytics.EGAErrorSeverity.warning or GameAnalytics.EGAErrorSeverity.error
	GameAnalytics:addErrorEvent(nil, {severity = severity, message = message})
end

return module
