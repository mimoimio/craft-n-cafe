-- CafeRenderingService/CafeModel.luau
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage.Packages.React)
local Mionum = require(ReplicatedStorage.Packages.Mionum)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Promise = require(ReplicatedStorage.Packages.Promise)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef
local useBinding = React.useBinding
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)

local player = game.Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""

local MAX_ACCUMULATION_SECONDS = 8 * 60 * 60
local function ShelfCollectorUI(props: { collectorModel: Model })
	local collectorPart = props.collectorModel:FindFirstChild("Part")
	local prompt = collectorPart and collectorPart:FindFirstChild("TriggerPrompt")

	local amountBinding, setAmountBinding = useBinding("$0")

	local lastClaimTimeRef = useRef(workspace:GetServerTimeNow())
	local totalRateRef = useRef(0)

	-- Synchronize with GlobalState for Shelves & Collector
	useEffect(function()
		local function calculateRate(shelves)
			local rate = 0
			if shelves then
				for _, shelf in shelves do
					for _, slot in shelf.Slots do
						if type(slot) == "table" and slot.drinkId then
							local config = CoffeeModule.Config[slot.drinkId]
							local variation = VariationsConfig[slot.variationId] or VariationsConfig["none"]
							if config and config.Rate then
								rate += (config.Rate * variation.Multiplier)
							end
						end
					end
				end
			end
			return rate
		end

		local unsub = GlobalState:subscribe(
			Reflex.createSelector({
				function(state)
					return state.ShelfCollector[playerId]
				end,
				function(state)
					return state.Shelves[playerId]
				end,
			}, function(collector, shelves)
				return {
					collector = collector,
					shelves = shelves,
				}
			end),
			function(newData)
				if newData.collector then
					lastClaimTimeRef.current = newData.collector.LastClaimTime or workspace:GetServerTimeNow()
				end
				if newData.shelves then
					totalRateRef.current = calculateRate(newData.shelves)
				end
			end
		)

		-- Initial fetch
		local state = GlobalState:getState()
		if state.ShelfCollector[playerId] then
			lastClaimTimeRef.current = state.ShelfCollector[playerId].LastClaimTime or workspace:GetServerTimeNow()
		end
		totalRateRef.current = calculateRate(state.Shelves[playerId])

		return unsub
	end, {})

	-- Fast visual update loop
	useEffect(function()
		local running = true
		local t = task.defer(function()
			while task.wait(1 / 10) and running do
				local currentTime = workspace:GetServerTimeNow()
				local timePassed = math.min(currentTime - lastClaimTimeRef.current, MAX_ACCUMULATION_SECONDS)
				local amount = math.floor(timePassed * totalRateRef.current)

				local displayString = `$ {Mionum.new(amount):toString()}`
				setAmountBinding(displayString)

				if prompt and prompt.Parent then
					prompt.ActionText = "Collect"
					prompt.ObjectText = displayString
				end
			end
		end)

		return function()
			running = false
			task.cancel(t)
		end
	end, { prompt })

	-- Handle Prompt Trigger
	useEffect(function()
		if not prompt then
			return
		end
		local conn = prompt.Triggered:Connect(function(_player)
			if _player == player then
				Remotes.ClaimShelfCollector:FireServer()
			end
		end)
		return function()
			conn:Disconnect()
		end
	end, { prompt })

	if not collectorPart then
		return nil
	end

	return ReactRoblox.createPortal({
		CollectorGui = e("BillboardGui", {
			Size = UDim2.fromScale(4, 1.5),
			StudsOffset = Vector3.new(0, 3.5, 0), -- Floats above the part
			AlwaysOnTop = true,
			MaxDistance = 50,
			Adornee = collectorPart,
		}, {
			CashLabel = e("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = amountBinding,
				TextColor3 = Color3.fromRGB(115, 255, 135), -- A nice money green
				TextScaled = true,
				Font = Enum.Font.FredokaOne,
			}, {
				UIStroke = e("UIStroke", {
					Thickness = 3,
					Color = Color3.new(0, 0, 0),
				}),
			}),
		}),
	}, player and player.PlayerGui or collectorPart)
end
return ShelfCollectorUI
