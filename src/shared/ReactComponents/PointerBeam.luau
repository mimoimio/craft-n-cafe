local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Promise = require(ReplicatedStorage.Packages.Promise)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef
local useCallback = React.useCallback

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""

local function PointerBeam(props: { Adornee: PVInstance })
	local char: Model?, setChar = useState(nil)
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

	useEffect(function()
		if not (char and props.Adornee) then
			return
		end

		local part = Instance.new("Part")
		part.Anchored = false
		part:PivotTo(char:GetPivot())
		part.CanCollide = false
		part.Transparency = 1

		local weld = Instance.new("WeldConstraint", part) -- welded instead of parented so not go invisible when zoomed in
		weld.Part0 = part
		weld.Part1 = char.PrimaryPart or char:FindFirstChildWhichIsA("BasePart") or nil

		local att0 = Instance.new("Attachment", part)
		local att1 = Instance.new("Attachment", props.Adornee)

		part.Parent = workspace

		local beam = Instance.new("Beam", part)
		beam.Attachment0 = att0
		beam.Attachment1 = att1
		beam.Texture = "rbsassetid://17476697388"
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
	return e(React.Fragment)
end
return PointerBeam
