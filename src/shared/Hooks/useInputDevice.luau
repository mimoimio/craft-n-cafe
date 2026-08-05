local UserInputService = game:GetService("UserInputService")
local React = require(game:GetService("ReplicatedStorage").Packages.React)
local useEffect, useState = React.useEffect, React.useState

-- Returns: "Keyboard", "Gamepad", or "Touch"
return function()
	-- Default to Keyboard, or Touch if no keyboard exists (mobile)
	local initialState = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and "Touch"
		or "Keyboard"
	local inputType, setInputType = useState(initialState)

	useEffect(function()
		local conn = UserInputService.LastInputTypeChanged:Connect(function(lastInputType)
			if lastInputType == Enum.UserInputType.Keyboard or lastInputType == Enum.UserInputType.MouseMovement then
				setInputType("Keyboard")
			elseif lastInputType.Name:find("Gamepad") then
				setInputType("Gamepad")
			elseif lastInputType == Enum.UserInputType.Touch then
				setInputType("Touch")
			end
		end)

		-- Initial check just in case
		local current = UserInputService:GetLastInputType()
		if current.Name:find("Gamepad") then
			setInputType("Gamepad")
		elseif current == Enum.UserInputType.Touch then
			setInputType("Touch")
		end

		return function()
			conn:Disconnect()
		end
	end, {})

	return inputType
end
