local GuiModule = {}

function GuiModule.FindGui(player, guiName): ScreenGui
	local playerGui = player:WaitForChild("PlayerGui")
	local coreGui = playerGui:WaitForChild("CoreGui")
	local gui = coreGui:WaitForChild(guiName)
	return gui
end

return GuiModule
