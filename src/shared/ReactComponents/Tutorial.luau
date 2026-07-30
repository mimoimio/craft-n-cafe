-- Shared/ReactComponents/Tutorial.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local React = require(ReplicatedStorage.Packages.React)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Promise = require(ReplicatedStorage.Packages.Promise)
local e = React.createElement
local useEffect = React.useEffect
local Toasts = require(ReplicatedStorage.Shared.ReactComponents.Toasts)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local useToast = Toasts.useToast
local useState = React.useState
local useBinding = React.useBinding
local useCallback = React.useCallback
local useRef = React.useRef
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local SmallText = require(script.Parent.ui.SmallText)
local HStack = require(script.Parent.ui.HStack)

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""

--[[
1. "Close the letter" Until: UIState.panel ~= "rejectionletter"

2. "Go to summoning circle" Until: UIState.SpawnerPromptShown
display Beam and BillboardGuiArrow Adornee'd to Spawner's Instance.

3. "Summon an Espresso Ingredient" Until: table.find(GlobalState.Spawner[playerId].IngredientIds, "espresso")
display BillboardGuiArrow Adornee'd to Spawner's Instance

-- scrap this
-- 3. "..." Until: UIState.SummonedModelShown
-- do nothing


4. "Buy the Espresso" Until: #GlobalState.Spawner[playerId].IngredientIds == 0 and GlobalState.Ingredients.[playerId].espresso and it's >0
Beam and BillboardGuiArrow Adornee'd to UIState.BuypadInstance

5. "Summon a Milk Ingredient" Until: table.find(GlobalState.Spawner[playerId].IngredientIds, "milk")
display BillboardGuiArrow Adornee'd to UIState.SpawnerInstance

6. "Buy the Milk" Until: #GlobalState.Spawner[playerId].IngredientIds == 0 and GlobalState.Ingredients.[playerId].milk and it's >0
Beam and BillboardGuiArrow Adornee'd to UIState.BuypadInstance

7. "Go to your Cauldron" Until: UIState.Mixer1PromptShown
Beam and BillboardGuiArrow Adornee'd to UIState.Mixer1Instance

8. "Interact with the Cauldron" Until: UIState.panel == "mixer"
BillboardGuiArrow Adornee'd to UIState.Mixer1Instance

9. "Tap on Espresso to insert" Until: UIState.isEspressoInserted
ScreenGuiCircle positioned on UIState.EspressoButton's Absolute position

10. "Now Tap on Milk to inseret" Until: UIState.isMilkInserted
ScreenGuiCircle positioned on UIState.MilkButton's Absolute position

11. "Tap "Craft" to craft a latte" Until: GlobalState.Mixers[playerId] and it's.Mixer1 and it's.drinkId ~= "none"
ScreenGuiCircle positioned on UIState.CraftButton's Absolute position

12. "Wait until the Latte is done" Until: CoffeeModule.Configs.latte.duration + GlobalState.Mixers[playerId] and it's.Mixer1 and it's.startTime < workspace:GetServerTimeNow()
do nothing

13. "Pick up the drink" Until: #GlobalState.Drinks[playerId] > 0
Beam and BillboardGuiArrow Adornee'd to UIState.Mixer1Instance

14. "Place the drink on the table" Until: any of GlobalState.Tables[playerId][TableId][SlotId] ~= "none"
Beam and BillboarGuiArrow Adornee'd to UIState.TableInstance

15. "Wait for a customer to buy the drink" Until: any of GlobalState.Customers[playerId][number].customerAction == "queuing"
if not playerStats.CafeOpen then 
	Remotes.ToggleCafeOpen:FireServer() 
end
do nothing

16. "Tend the customer" Until: any customer's customerAction == "paid"
Beam and BillboardGuiArrow Adornee'd to UIState.FirstCustomer

17. "Congrats, you've completed the tutorial"
tutorialCompletedRef.current = true
-- this is so the ladder doesnt go back to 16 or below
task.delay(5, function()
	Remotes.CompleteTutorial:FireServer()
	-- after firing this, this component is no longer rendered, the parent is conditioned to render only if not TutorialCompleted
end)

]]

return function()
	local globalStates, setGlobalStates = useState(nil)
	local uiStates, setUiStates = useState(nil)

	-- when this is set to true, let there be delay of 5 seconds, but this is just to prevent going back
	local tutorialCompleted, setTutorialCompleted = useState(nil)

	useEffect(function()
		-- globalstate listener
		local unsub = GlobalState:subscribe(Reflex.createSelector(
			{
				-- this state true, then 18, this component shouldnt be shown.
				getTutorialCompleted = function(state)
					local playerStats = state.Stats[playerId]
					if playerStats then
						return playerStats.TutorialCompleted
					end
				end,
				-- 17
				getCustomerPaid = function(state)
					local customers = state.Customers[playerId]
					if customers then
						for i, customer in pairs(customers) do
							if customer.customerAction == "paid" then
								return true
							end
						end
					end
				end,
				-- 16
				getCustomerQueued = function(state)
					local customers = state.Customers[playerId]
					if customers then
						for i, customer in pairs(customers) do
							if customer.customerAction == "queue" then
								return true
							end
						end
					end
				end,
				-- 15
				getATableSlotFilled = function(state)
					local tables = state.Tables[playerId]
					if tables then
						for i, table in pairs(tables) do
							if table.Slots then
								for slotName, slot in table.Slots do
									if slot ~= "none" then
										return true
									end
								end
							end
						end
					end
				end,
				-- 14
				getIsDrinkPickedUp = function(state)
					local drinks = state.Drinks[playerId]
					if #drinks > 0 then
						return true
					end
				end,
				-- 13
				getIsDrinkBrewed = function(state)
					local playersMixers = state.Mixers[playerId]
					if not playersMixers then
						return false
					end
					local mixer1 = playersMixers.Mixer1
					if not mixer1 then
						return false
					end
					local duration = CoffeeModule.Config[mixer1.drinkId].Duration
					if not mixer1.startTime or (mixer1.startTime + duration > workspace:GetServerTimeNow()) then
						return false
					end
				end,
				-- 12
				getIsMixerFilled = function(state)
					local playersMixers = state.Mixers[playerId]
					if not playersMixers then
						return false
					end
					local mixer1 = playersMixers.Mixer1
					if not mixer1 then
						return false
					end
					local isMixer1Filled = mixer1.drinkId and not (mixer1.drinkId == "none" or mixer1.drinkId == nil)
					if not isMixer1Filled then
						return false
					end
					return true
				end,
				-- 7
				getIsMilkBought = function(state)
					local spawner = state.Spawner[playerId]
					local ingredients = state.Ingredients[playerId]

					if not (spawner and ingredients) then
						return
					end

					local spawnerEmpty = spawner.IngredientIds == 0
					local hasMilk = ingredients.milk and ingredients.milk > 0
				end,
				-- 6
				getIsMilkSpawned = function(state)
					local spawner = state.Spawner[playerId]

					if not (spawner and spawner.IngredientIds) then
						return
					end
					local milkSpawned = table.find(spawner.IngredientIds, "milk")
					return milkSpawned and true
				end,
				-- 5
				getIsEspressoBought = function(state)
					local spawner = state.Spawner[playerId]
					local ingredients = state.Ingredients[playerId]

					if not (spawner and spawner.IngredientIds and ingredients) then
						return
					end

					local spawnerEmpty = spawner.IngredientIds == 0
					local hasMilk = ingredients.espresso and ingredients.espresso > 0

					return spawnerEmpty and hasMilk
				end,
				-- 4
				getIsEspressoSpawned = function(state)
					local spawner = state.Spawner[playerId]

					if not (spawner and spawner.IngredientIds) then
						return
					end
					local espressoSpawned = table.find(spawner.IngredientIds, "espresso")
					return espressoSpawned and true
				end,
			} :: { (state: GlobalState.GlobalState) -> () },
			function() end
		))
		return unsub
	end)
	useEffect(function()
		-- uistate listener
		local unsub = UIState:subscribe(Reflex.createSelector(
			{
				-- 11
				getIsMilkInserted = function(state)
					return state.isMilkInserted
				end,
				-- 10
				getIsEspressoInserted = function(state)
					return state.isEspressoInserted
				end,
				-- 9
				getIsMixerPanel = function(state)
					local panel = state.panel
					if not (panel and panel == "mixer") then
						return false
					end
					return true
				end,
				-- 8
				getMixerNodePromptShown = function(state)
					local mixerNodeShown = state.mixerNodeShown
					if not mixerNodeShown then
						return false
					end
					return true
				end,
				-- 3
				getSpawnerPromptShown = function(state)
					local mixerNodeShown = state.spawnerPromptShown
					if not mixerNodeShown then
						return false
					end
					return true
				end,
			} :: { (state: UIState.UIState) -> () },
			function() end
		))
		return unsub
	end)

	-- ladder
	useEffect(function()
		if globalStates.TutorialCompleted == true then
			return
		end

		if globalStates.CustomerPaid then
		end
		return
	end, { globalStates, uiStates })

	e(React.Fragment)
end
