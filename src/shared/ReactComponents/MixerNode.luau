-- Shared/ReactComponents/MixerNode.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local toggleMixerInteract = UIState.toggleMixerInteract
local MixerProgressBar = require(script.Parent.MixerProgressBar)

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState
local useRef = React.useRef

local function MixerNode(props: {
	MixerName: string,
	MixerData: any,
	Instance: Instance?,
})
	local isOccupied = props.MixerData.drinkId ~= "none"

	-- State for asynchronously resolved descendants
	local prompt, setPrompt = useState(nil)

	-- 1. Asynchronously resolve descendants following CafeTypes strictly
	useEffect(function()
		if not props.Instance then
			return
		end

		local promise = Promise.defer(function(resolve, reject)
			-- CafeTypes dictates: Mixer -> Part -> TriggerPrompt
			local part = props.Instance:WaitForChild("Part", 5)
			if not part then
				return reject("Mixer 'Part' replication timeout")
			end

			local resolvedPrompt = part:WaitForChild("TriggerPrompt", 5)
			if not resolvedPrompt then
				return reject("TriggerPrompt replication timeout")
			end

			resolve(resolvedPrompt)
		end)

		promise
			:andThen(function(resolvedPrompt)
				setPrompt(resolvedPrompt)
			end)
			:catch(function(err)
				warn(`[MixerNode] Failed to resolve descendants for {props.MixerName}: {err}`)
			end)

		return function()
			promise:cancel()
		end
	end, { props.Instance })

	-- 2. Bind the ProximityPrompt safely
	useEffect(function()
		if not prompt then
			return
		end

		prompt.ActionText = isOccupied and "Pick Up" or "Craft"

		local conn = prompt.Triggered:Connect(function(player)
			if player == Players.LocalPlayer then
				if isOccupied then
					Remotes.PickUpDrink:FireServer(props.MixerName)
				else
					toggleMixerInteract(props.MixerName)
				end
			end
		end)

		return function()
			conn:Disconnect()
		end
	end, { prompt, isOccupied, props.MixerName, props.onInteract })

	-- set UIState's mixernodeshown
	useEffect(function()
		if not prompt then
			return
		end
		local conn = prompt.PromptShown:Connect(function()
			UIState.setMixerNodeShown(props.MixerName)
		end)
		local conn2 = prompt.PromptHidden:Connect(function()
			UIState.setMixerNodeShown(nil)
		end)
		return function()
			conn:Disconnect()
			conn2:Disconnect()
		end
	end, { prompt })

	-- 3. Sound Effects
	local isOccupiedRef = useRef(nil)
	useEffect(function()
		if isOccupiedRef.current == nil then
			isOccupiedRef.current = isOccupied
			return
		end

		if isOccupied then
			SoundController.Sound("maximize_006")
		else
			SoundController.Sound("drop_001")
		end

		isOccupiedRef.current = isOccupied
	end, { isOccupied })

	-- 4. Render Progress Bar
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
