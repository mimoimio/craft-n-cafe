local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useBinding = React.useBinding
local useEffect = React.useEffect
local useCallback = React.useCallback

local function ScreenGuiCircle(
	props: {
		Position: any, -- UDim2 or React Binding
		Size: any?, -- Defaults to 60x60
		Color: Color3?,
	}
)
	local time, setTime = useBinding(workspace:GetServerTimeNow())

	-- Run loop for the pulsing animation
	useEffect(function()
		local t = task.spawn(function()
			while task.wait(1 / 30) do
				setTime(workspace:GetServerTimeNow())
			end
		end)
		return function()
			task.cancel(t)
		end
	end, {})

	-- Pulse the circle size slightly for a "click me" effect
	local sizeMap = useCallback(function(t)
		local pulse = math.sin(t * 5) * 5
		return UDim2.fromOffset(60 + pulse, 60 + pulse)
	end, {})

	local targetSize = props.Size or UDim2.fromOffset(60, 60)

	return e("ScreenGui", {
		DisplayOrder = 1010, -- Ensures it renders above standard UI panels
	}, {
		Wrapper = e("Frame", {
			BackgroundTransparency = 1,
			Position = props.Position,
			Size = targetSize,
			AnchorPoint = Vector2.new(0.5, 0.5),
		}, {
			Circle = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = time:map(sizeMap),
				BackgroundColor3 = props.Color or Color3.new(1, 1, 1),
				BackgroundTransparency = 0.8,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Stroke = e("UIStroke", {
					Color = props.Color or Color3.new(1, 1, 1),
					Thickness = 3,
				}),
			}),
		}),
	})
end

return ScreenGuiCircle
