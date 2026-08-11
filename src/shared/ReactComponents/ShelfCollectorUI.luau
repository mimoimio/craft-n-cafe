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
	local shelves, setShelves = useState({})

	local amountBinding, setAmountBinding = useBinding("$0")

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state)
			return state.Shelves[playerId]
		end, function(newShelves)
			setShelves(newShelves or {})
		end)

		local state = GlobalState:getState()
		setShelves(state.Shelves[playerId] or {})

		return unsub
	end, {})

	-- Fast visual update loop
	useEffect(function()
		local running = true
		local t = task.defer(function()
			while running do
				local currentTime = workspace:GetServerTimeNow()
				local totalAmount = 0
				for _, shelf in shelves do
					for _, slotData in shelf.Slots do
						if type(slotData) == "table" and slotData.drinkId and slotData.lastClaimTime then
							local config = CoffeeModule.Config[slotData.drinkId]
							local variation = VariationsConfig[slotData.variationId] or VariationsConfig["none"]
							if config and config.Rate then
								local sizeMultiplier = slotData.size or 1
								local rate = config.Rate * variation.Multiplier * sizeMultiplier

								local timePassed =
									math.min(currentTime - slotData.lastClaimTime, MAX_ACCUMULATION_SECONDS)
								totalAmount += math.floor(timePassed * rate)
							end
						end
					end
				end
				local displayString = `$ {Mionum.new(totalAmount):toString()}`
				setAmountBinding(displayString)

				if prompt then
					prompt.ActionText = "Collect"
					prompt.ObjectText = displayString
				end
				task.wait(1)
			end
		end)

		return function()
			running = false
			task.cancel(t)
		end
	end, { shelves, prompt })

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
