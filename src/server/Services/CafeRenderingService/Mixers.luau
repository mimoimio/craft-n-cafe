-- Server/Services/CafeRenderingService/Mixers.luau
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local React = require(ReplicatedStorage.Packages.React)
local Promise = require(ReplicatedStorage.Packages.Promise)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CafeTypes = require(game.ReplicatedStorage.Shared.CafeTypes)
local Types = require(game.ReplicatedStorage.Shared.Types)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local function Mixer(props: {
	PlayerId: string,
	Mixer: CafeTypes.Mixer,
	MixerData: Types.MixerEntity?,
})
	local clonedMixerModel: Model, setMixerModel = useState(nil)
	useEffect(function()
		if not props.Mixer then
			return
		end

		-- Use the generic tag
		local tag = "Mixer" .. props.PlayerId
		CollectionService:AddTag(props.Mixer, tag)

		return function()
			CollectionService:RemoveTag(props.Mixer, tag)
		end
	end, { props.Mixer, props.PlayerId })

	local playerOwnsMixer = props.MixerData and true or false
	useEffect(function()
		if not props.Mixer then
			return
		end

		if props.MixerData then
			local modelTemplate = ReplicatedStorage.Shared.Models:FindFirstChild("Mixer")
			if not modelTemplate then
				warn("No mixer model template found")
				return
			end
			local clonedModel = modelTemplate:Clone()
			clonedModel:PivotTo(props.Mixer:GetPivot())
			clonedModel.Parent = props.Mixer
			setMixerModel(clonedModel)

			return function()
				if clonedModel and clonedModel.Parent then
					clonedModel:Destroy()
				end
				setMixerModel(nil)
			end
		else
			local text = props.Mixer.Part.TriggerPrompt
			local buyPromptConn = props.Mixer.Part.TriggerPrompt.Triggered:Connect(function(player: Player)
				if tostring(player.UserId) ~= props.PlayerId then
					return
				end
				local ShopService = require(ServerScriptService.Server.Services.ShopService)
				ShopService.BuyMixer(player, props.Mixer.Name)
			end)
			return function()
				if buyPromptConn then
					buyPromptConn:Disconnect()
				end
			end
		end
	end, { props.Mixer, props.PlayerId, playerOwnsMixer })

	local filled = props.MixerData and props.MixerData.drinkId ~= "none" or false
	useEffect(function()
		if not (clonedMixerModel and filled ~= nil) then
			return
		end
		local promise = Promise.defer(function(resolve, reject, onCancel)
			clonedMixerModel.Fill.Transparency = filled and 0 or 1
			local sound: Sound = clonedMixerModel.Fill.BubbleSFX
			sound.Looped = filled and true or false
			for i, desc in clonedMixerModel:GetDescendants() do
				if desc:IsA("ParticleEmitter") then
					desc.Enabled = filled and true or false
				end
			end
			if filled then
				if not sound.Playing then
					local loaded = sound.IsLoaded
					if not loaded then
						sound.Loaded:Wait()
					end
					sound:Play()
				end
			else
				sound:Stop()
			end

			return resolve()
		end)
			:timeout(10)
			:catch(function(err)
				warn(`err: {err}`)
			end)
		return function()
			promise:cancel()
		end
	end, { clonedMixerModel, filled })

	return e(React.Fragment)
end

local function Mixers(props: {
	CafeModel: CafeTypes.Cafe,
	PlayerId: string,
})
	local mixersState, setMixersState = useState()

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Mixers[props.PlayerId]
		end, function(newMixersState)
			setMixersState(newMixersState or {})
		end)

		local state = GlobalState:getState()
		if state.Mixers[props.PlayerId] then
			setMixersState(state.Mixers[props.PlayerId])
		end

		return unsub
	end, { props.PlayerId })

	local children = {}
	local mixersFolder = props.CafeModel:FindFirstChild("Mixers")

	if mixersFolder and mixersState then
		for i, mixerAnchor: CafeTypes.Mixer in mixersFolder:GetChildren() do
			local mixerName = mixerAnchor.Name
			local mixer = mixersState[mixerName]

			children[mixerName] = e(Mixer, {
				PlayerId = props.PlayerId,
				Mixer = mixerAnchor,
				MixerData = mixer or nil,
			})
		end
	else
		print(`mixersFolder({mixersFolder}), mixersState({mixersState})`)
	end

	return e(React.Fragment, nil, children)
end

return Mixers
