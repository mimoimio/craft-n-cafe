local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement

local STEP_AMOUNT = 0.1 -- How much to increase/decrease per button press (0.1 = 10%)

local function Slider(props: {
	Value: number,
	OnChange: (number) -> (),
	OnDrag: ((number) -> ())?,
	Label: string,
})
	local barRef = React.useRef(nil)

	local isDragging, setIsDragging = React.useState(false)
	-- Takes the initial props.Value on mount and NEVER listens to it again
	local localValue, setLocalValue = React.useState(props.Value)

	local valRef = React.useRef(localValue)
	valRef.current = localValue

	-- Handles Mouse/Touch drag
	local updateValue = React.useCallback(function(inputPosition)
		if not barRef.current then
			return
		end
		
		local bar = barRef.current
		local relativeX = inputPosition.X - bar.AbsolutePosition.X
		local percentage = math.clamp(relativeX / bar.AbsoluteSize.X, 0, 1)
		percentage = math.round(percentage * 100) / 100

		setLocalValue(percentage)

		if props.OnDrag then
			props.OnDrag(percentage)
		end
	end, { props.OnDrag })

	-- Handles Gamepad/Keyboard steps
	local stepValue = React.useCallback(function(direction)
		local newValue = math.clamp(valRef.current + (direction * STEP_AMOUNT), 0, 1)
		newValue = math.round(newValue * 100) / 100

		setLocalValue(newValue)
		valRef.current = newValue -- Update immediately for rapid button presses

		-- Fire both so the preview updates AND the server saves it
		if props.OnDrag then
			props.OnDrag(newValue)
		end
		props.OnChange(newValue)
	end, { props.OnDrag, props.OnChange })

	-- Gamepad/Keyboard Input Hook
	React.useEffect(function()
		local bar = barRef.current
		if not bar then return end

		-- 1. Trap the selection engine
		bar.NextSelectionLeft = bar
		bar.NextSelectionRight = bar

		-- 2. Listen for Left/Right presses
		local inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			-- Only apply if this specific slider is currently selected
			if GuiService.SelectedObject ~= bar then return end

			local code = input.KeyCode
			if code == Enum.KeyCode.DPadLeft or code == Enum.KeyCode.Left then
				stepValue(-1)
			elseif code == Enum.KeyCode.DPadRight or code == Enum.KeyCode.Right then
				stepValue(1)
			end
		end)

		return function()
			inputConn:Disconnect()
			-- Clean up selection trapping
			if bar then
				bar.NextSelectionLeft = nil
				bar.NextSelectionRight = nil
			end
		end
	end, { stepValue })

	-- Mouse/Touch Drag Hook
	React.useEffect(function()
		if not isDragging then
			return
		end

		local inputChangedConn = UserInputService.InputChanged:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			then
				updateValue(input.Position)
			end
		end)

		local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				setIsDragging(false)
				props.OnChange(valRef.current)
			end
		end)

		return function()
			inputChangedConn:Disconnect()
			inputEndedConn:Disconnect()
		end
	end, { isDragging, updateValue })

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
	}, {
		Label = e("TextLabel", {
			Text = `{props.Label}: {math.floor(localValue * 100)}%`,
			Size = UDim2.new(1, 0, 0.4, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
		}),

		BarContainer = e("TextButton", {
			ref = barRef,
			Size = UDim2.new(1, 0, 0, 12),
			Position = UDim2.new(0, 0, 0.7, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			AutoButtonColor = false,
			Text = "",
			Selectable = true, -- Ensures the button can be selected by GuiService
			[React.Event.InputBegan] = function(rbx, input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					setIsDragging(true)
					updateValue(input.Position)
				end
			end,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),

			Fill = e("Frame", {
				Size = UDim2.new(localValue, 0, 1, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 0,
			}, {
				UICorner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
			}),

			Knob = e("Frame", {
				Size = UDim2.new(0, 16, 0, 16),
				Position = UDim2.new(localValue, -8, 0.5, -8),
				BackgroundColor3 = Color3.new(1, 1, 1),
			}, {
				UICorner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
				UIStroke = e("UIStroke", {
					Color = Color3.fromRGB(150, 150, 150),
					Thickness = 1,
				}),
			}),
		}),
	})
end

return Slider