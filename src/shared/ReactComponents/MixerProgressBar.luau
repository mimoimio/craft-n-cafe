-- Shared/ReactComponents/MixerProgressBar.luau
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local e = React.createElement

local function MixerProgressBar(props: {
	Adornee: Instance,
	StartTime: number,
	Duration: number,
	DrinkName: string,
})
	-- We use bindings here so we can update the UI at 60FPS without re-rendering the component
	local progress, setProgress = React.useBinding(0)
	local text, setText = React.useBinding(props.DrinkName .. " (0%)")

	local finishRangRef = React.useRef(false)

	React.useEffect(function()
		local running = true
		local t = task.spawn(function()
			while running do
				task.wait(1 / 15)
				local now = workspace:GetServerTimeNow()
				local timePassed = now - props.StartTime
				local p = math.clamp(timePassed / props.Duration, 0, 1)
				local timeLeft = props.Duration - timePassed

				setProgress(p)

				if p >= 1 then
					setText(props.DrinkName .. " (Done!)")
					if finishRangRef.current == true then
						continue
					end
					finishRangRef.current = true
					SoundController.Sound("Success")
				else
					local str = string.format("%s (%dm %ds)", props.DrinkName, timeLeft // 60, timeLeft % 60)
					setText(str)
				end
			end
		end)

		return function()
			running = false
			finishRangRef.current = false
			task.cancel(t)
		end
	end, { props.StartTime, props.Duration, props.DrinkName })

	return e("BillboardGui", {
		Adornee = props.Adornee,
		Size = UDim2.new(0, 120, 0, 30),
		StudsOffset = Vector3.new(0, 3, 0),
		AlwaysOnTop = true,
		MaxDistance = 50,
	}, {
		Background = e("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.new(0.15, 0.15, 0.15),
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),

			Fill = e("Frame", {
				-- Map the 0-1 progress binding to the X scale of the fill frame
				Size = progress:map(function(val)
					return UDim2.new(val, 0, 1, 0)
				end),
				BackgroundColor3 = Color3.new(0.2, 0.8, 0.2),
				BorderSizePixel = 0,
			}, {
				UICorner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
			}),

			Label = e("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = text,
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.GothamBold,
				TextScaled = true,
				ZIndex = 2,
			}, {
				UIPadding = e("UIPadding", {
					PaddingTop = UDim.new(0, 4),
					PaddingBottom = UDim.new(0, 4),
					PaddingLeft = UDim.new(0, 4),
					PaddingRight = UDim.new(0, 4),
				}),
			}),
		}),
	})
end

return MixerProgressBar
