local UserInputService = game:GetService("UserInputService")

local FONT = `rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json`

local Icons = {
	["clock"] = `<font family="{FONT}"><b>clock</b></font>`,
	["three-stacked-squares-tilted"] = `<font family="{FONT}">three-stacked-squares-tilted</font>`,
	["hand-half-ellipse"] = `<font family="{FONT}">hand-half-ellipse</font>`,

	["xbox-a"] = `<font family="{FONT}">xbox-a</font>`,
	["ps-x"] = `<font family="{FONT}">ps-x</font>`,
	["xbox-b"] = `<font family="{FONT}">xbox-b</font>`,
	["ps-circle"] = `<font family="{FONT}">ps-circle</font>`,
	["xbox-y"] = `<font family="{FONT}">xbox-y</font>`,
	["ps-triagle"] = `<font family="{FONT}">ps-triagle</font>`,
	["xbox-x"] = `<font family="{FONT}">xbox-x</font>`,
	["ps-square"] = `<font family="{FONT}">ps-square</font>`,
}

-- Maps a Roblox KeyCode to our Dictionary keys based on Console Type
local GamepadMap = {
	[Enum.KeyCode.ButtonA] = { Xbox = "xbox-a", PS = "ps-x" },
	[Enum.KeyCode.ButtonB] = { Xbox = "xbox-b", PS = "ps-circle" },
	[Enum.KeyCode.ButtonX] = { Xbox = "xbox-x", PS = "ps-square" },
	[Enum.KeyCode.ButtonY] = { Xbox = "xbox-y", PS = "ps-triagle" },
}

-- The master abstraction function
Icons.GetPromptText = function(keyCode: Enum.KeyCode, inputType: string): string
	if inputType == "Touch" then
		return Icons["hand-half-ellipse"]
	end

	if inputType == "Gamepad" and GamepadMap[keyCode] then
		-- Ask the engine what hardware is actually plugged in
		local hardwareString = UserInputService:GetStringForKeyCode(keyCode)

		-- PlayStation controllers return "ButtonCross", "ButtonSquare", etc.
		local isPlayStation = string.find(hardwareString, "Cross")
			or string.find(hardwareString, "Square")
			or string.find(hardwareString, "Circle")
			or string.find(hardwareString, "Triangle")

		local iconKey = isPlayStation and GamepadMap[keyCode].PS or GamepadMap[keyCode].Xbox
		return Icons[iconKey] or ""
	end

	-- Fallback to Keyboard string (e.g. "[E]")
	return `[{keyCode.Name}]`
end

return Icons
