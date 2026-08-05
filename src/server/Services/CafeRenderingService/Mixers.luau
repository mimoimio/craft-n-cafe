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

		if playerOwnsMixer then
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
			local prompt = props.Mixer.Part.TriggerPrompt
			local actionText = prompt.ActionText
			local ObjectText = prompt.ObjectText
			prompt.ActionText = "Buy ($50)"
			prompt.ObjectText = "Another Cauldron"
			local buyPromptConn = prompt.Triggered:Connect(function(player: Player)
				if tostring(player.UserId) ~= props.PlayerId then
					return
				end
				local ShopService = require(ServerScriptService.Server.Services.ShopService)
				ShopService.BuyMixer(player, props.Mixer.Name)
			end)
			return function()
				if prompt and prompt.Parent then
					prompt.ActionText = actionText
					prompt.ObjectText = ObjectText
				end
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

		local particleModel: Model? = nil

		local promise = Promise.defer(function(resolve, reject, onCancel)
			clonedMixerModel.Fill.Transparency = filled and 0 or 1
			local sound: Sound = clonedMixerModel.Fill.BubbleSFX
			sound.Looped = filled and true or false

			for _, desc in clonedMixerModel:GetDescendants() do
				if desc:IsA("ParticleEmitter") then
					desc.Enabled = filled and true or false
				end
			end

			-- Apply variation particle if it exists
			if filled and props.MixerData.variationId and props.MixerData.variationId ~= "none" then
				local particleTemplate = ReplicatedStorage.Shared.Particles:FindFirstChild(props.MixerData.variationId)
				if particleTemplate then
					particleModel = Instance.new("Model")
					particleModel.Name = "MixerVariationParticle"

					local part = particleTemplate:Clone()
					part.Transparency = 1
					part.CanCollide = false
					part.Massless = true
					part.Anchored = false
					part.Parent = particleModel

					particleModel.PrimaryPart = part

					-- Pivot slightly above the cauldron fill line
					local fillPart = clonedMixerModel.Fill
					particleModel:PivotTo(fillPart.CFrame + Vector3.new(0, 1.5, 0))

					-- Super-size the particles!
					particleModel:ScaleTo(3)
					particleModel.Parent = fillPart

					local weld = Instance.new("WeldConstraint")
					weld.Part0 = part
					weld.Part1 = fillPart
					weld.Parent = part
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
			if particleModel then
				particleModel:Destroy()
			end
		end
	end, { clonedMixerModel, filled, props.MixerData and props.MixerData.variationId })

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
