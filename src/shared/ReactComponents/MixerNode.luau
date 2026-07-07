-- Shared/ReactComponents/MixerNode.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local useEffect = React.useEffect
local useRef = React.useRef
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local MixerProgressBar = require(script.Parent.MixerProgressBar)

local e = React.createElement

local function MixerNode(props: {
	MixerName: string,
	MixerData: any,
	Instance: Instance?,
	onInteract: (mixerName: string) -> (),
})
	local isOccupied = props.MixerData.drinkId ~= "none"

	-- Bind the ProximityPrompt
	useEffect(function()
		if not props.Instance then
			return
		end

		local prompt = props.Instance:FindFirstChildWhichIsA("ProximityPrompt", true)
		if not prompt then
			return
		end

		-- warn(`MixerName({props.MixerName}) {props.MixerData.drinkId}[][] isOccupied({isOccupied})`)

		prompt.ActionText = isOccupied and "Pick Up" or "Craft"

		local conn = prompt.Triggered:Connect(function(player)
			if player == Players.LocalPlayer then
				if isOccupied then
					Remotes.PickUpDrink:FireServer(props.MixerName)
					-- warn(props.MixerData.drinkId)
				else
					props.onInteract(props.MixerName)
				end
			end
		end)

		return function()
			conn:Disconnect()
		end
	end, { props.Instance, isOccupied, props.MixerName, props.onInteract })

	local isOccupiedRef = useRef(nil)
	useEffect(function()
		if isOccupiedRef.current == nil then
			-- first time mount no need to sound
			isOccupiedRef.current = isOccupied
			return
		end
		if isOccupied then
			SoundController.Sound("Success")
		else
			SoundController.Sound("drop_001")
		end
		isOccupiedRef.current = isOccupied
	end, { isOccupied })

	-- Render Progress Bar
	if props.Instance and isOccupied and props.MixerData.startTime then
		local config = CoffeeModule.Config[props.MixerData.drinkId]
		local duration = (config and config.Duration) or 5

		return e(MixerProgressBar, {
			Adornee = props.Instance,
			StartTime = props.MixerData.startTime,
			Duration = duration,
			DrinkName = config and config.DisplayName or "Mixing...",
		})
	end

	return nil
end

return MixerNode
