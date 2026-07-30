-- PointerBeam.luau

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Promise = require(ReplicatedStorage.Packages.Promise)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useBinding = React.useBinding
local useCallback = React.useCallback

local player = Players.LocalPlayer

local function PointerBeam(props: { Adornee: PVInstance })
	local char: Model?, setChar = useState(nil)
	local time, setTime = useBinding(workspace:GetServerTimeNow())

	-- Animation loop for the bouncing arrow
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

	-- Character fetching for the Beam
	useEffect(function()
		local conn = player and player.CharacterAdded:Connect(function(character)
			setChar(character)
		end)
		local promise = Promise.defer(function(resolve, reject)
			if not player then
				reject(`player is {player}`)
			end
			return resolve(player.Character or player.CharacterAdded:Wait())
		end)

		promise
			:andThen(function(character: Model)
				setChar(character)
			end)
			:catch(function(err)
				warn(`PointerBeam get character failed:`, err)
			end)

		return function()
			promise:cancel()
			if conn then
				conn:Disconnect()
			end
		end
	end, {})

	-- Beam instance creation
	useEffect(function()
		if not (char and props.Adornee) then
			return
		end

		local part = Instance.new("Part")
		part.Anchored = false
		part:PivotTo(char:GetPivot())
		part.CanCollide = false
		part.Transparency = 1

		local weld = Instance.new("WeldConstraint", part)
		weld.Part0 = part
		weld.Part1 = char.PrimaryPart or char:FindFirstChildWhichIsA("BasePart") or nil

		local att0 = Instance.new("Attachment", part)
		local att1 = Instance.new("Attachment", props.Adornee)

		part.Parent = workspace

		local beam = Instance.new("Beam", part)
		beam.Attachment0 = att0
		beam.Attachment1 = att1
		beam.Texture = "rbxassetid://17476697388"
		beam.TextureSpeed = 0.5

		return function()
			if part and part.Parent then
				part:Destroy()
			end
			if att1 and att1.Parent then
				att1:Destroy()
			end
		end
	end, { char, props.Adornee })

	-- Oscillating logic for the arrow
	local positionMap = useCallback(function(t)
		-- Oscillate the Y axis. Adjust the multiplier (50) to change the bounce height.
		return UDim2.new(0.5, 0, 0.5, math.sin(t * 5) * 50)
	end, {})

	-- Render the BillboardGui arrow directly over the Adornee
	return props.Adornee
			and e("BillboardGui", {
				Adornee = props.Adornee,
				AlwaysOnTop = true,
				Size = UDim2.new(0, 1000, 0, 1000),
			}, {
				Holder = e("Frame", {
					Size = UDim2.new(0, 50, 0, 50),
					Position = time:map(positionMap),
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
				}, {
					Arrow = e("ImageLabel", {
						Size = UDim2.new(0, 50, 0, 50),
						AutomaticSize = Enum.AutomaticSize.XY,
						BackgroundTransparency = 1,
						Rotation = 0, -- Arrow points down
						Image = "rbxassetid://8152628560",
					}),
				}),
			})
		or nil
end

return PointerBeam
