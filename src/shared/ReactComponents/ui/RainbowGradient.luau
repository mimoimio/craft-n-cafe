local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React) -- Adjust path to your React library
local useBinding = React.useBinding
local useEffect = React.useEffect
local e = React.createElement

local resolution = 15 -- Number of anchored points (Roblox max is 20)
local speed = 10 -- Seconds for one full wave to pass
local function RainbowWaveGradient(props)
	-- Default to a solid color before the first frame renders
	local colorBinding, setColorBinding = useBinding(ColorSequence.new(Color3.new(1, 0, 0)))

	useEffect(function()
		-- Configuration

		local connection = RunService.Heartbeat:Connect(function()
			-- Time mapped from 0 to 1 based on speed
			local t = (os.clock() % speed) / speed

			local keypoints = {}

			-- Generate fixed positions, but shifting colors
			for i = 0, resolution do
				local position = i / resolution

				-- The magic: Hue is based on its physical position PLUS the time offset.
				-- Subtracting 't' moves the wave right. Adding 't' moves it left.
				local hue = (position - t) % 1
				hue = math.sin(hue * math.pi * 2) * 0.5 + 0.5

				table.insert(
					keypoints,
					ColorSequenceKeypoint.new(position, Color3.new(hue, 0.5 - hue * 0.5, 1 - hue * 0.25))
				)
				-- table.insert(keypoints, ColorSequenceKeypoint.new(position, Color3.fromHSV(hue, 1, 1)))
			end

			setColorBinding(ColorSequence.new(keypoints))
		end)

		return function()
			connection:Disconnect()
		end
	end, { props.speed }) -- Re-bind if speed prop changes

	return React.createElement("UIGradient", {
		Color = colorBinding,
		-- You can expose Rotation to change the wave's angle!
		Rotation = props.rotation or 0,
	})
end

return RainbowWaveGradient
