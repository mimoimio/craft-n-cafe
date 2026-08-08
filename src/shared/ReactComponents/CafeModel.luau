-- CafeRenderingService/CafeModel.luau
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage.Packages.React)
local Promise = require(ReplicatedStorage.Packages.Promise)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef
local useBinding = React.useBinding
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local ShelfCollectorUI = require(game.ReplicatedStorage.Shared.ReactComponents.ShelfCollectorUI)
local ShelfManager = require(game.ReplicatedStorage.Shared.ReactComponents.ShelfManager)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)

local player = game.Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""

local feedbackPrompt = function(props: { prompt: ProximityPrompt })
	useEffect(function()
		if not (props.prompt and props.prompt.Parent) then
			return
		end
		props.prompt.ActionText = "Share Feedbacks"
		props.prompt.ObjectText = "Thanks for playing!"
		local conn = props.prompt.Triggered:Connect(function(_player)
			if _player == player then
				SocialService:PromptFeedbackSubmissionAsync()
			end
		end)
		return function()
			conn:Disconnect()
		end
	end, { props.prompt })
	return e(React.Fragment)
end

local CafeModel = function(props: {})
	local cafeModel, setCafeModel = useState(nil)
	local prompt, setPrompt = useState(nil)
	local shelfCollector, setShelfCollector = useState(nil)

	useEffect(function()
		if not player then
			setShelfCollector(workspace.ShelfCollector)
			return
		end
		local tag = playerId .. "Cafe"

		local function syncInstances()
			local model = nil
			for _, inst in ipairs(CollectionService:GetTagged(tag)) do
				model = inst
				break
			end
			setCafeModel(model)
		end

		syncInstances()

		local connAdd = CollectionService:GetInstanceAddedSignal(tag):Connect(syncInstances)
		local connRem = CollectionService:GetInstanceRemovedSignal(tag):Connect(syncInstances)

		return function()
			connAdd:Disconnect()
			connRem:Disconnect()
		end
	end, { playerId })

	useEffect(function()
		if not cafeModel then
			return
		end
		local promise = Promise.defer(function(resolve, reject, onCancel)
			local feedback = cafeModel:WaitForChild("FeedbackPrompt"):WaitForChild("ProximityPrompt")
			setPrompt(feedback)

			local collector = cafeModel:WaitForChild("ShelfCollector")
			setShelfCollector(collector)
			return resolve()
		end):catch(function(err)
			warn(`React/CafeModel err:{err}`)
		end)
		return function()
			promise:cancel()
		end
	end, { cafeModel })

	local children = {}
	children.feedbackPrompt = prompt and e(feedbackPrompt, { prompt = prompt }) or nil
	children.shelfCollector = shelfCollector and e(ShelfCollectorUI, { collectorModel = shelfCollector }) or nil
	children.shelfManager = e(ShelfManager, { CafeModel = cafeModel })
	return e(React.Fragment, nil, children)
end

return CafeModel
