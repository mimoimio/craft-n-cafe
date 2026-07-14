local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local e = React.createElement
local useEffect = React.useEffect
local Toasts = require(ReplicatedStorage.Shared.ReactComponents.Toasts)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local useToast = Toasts.useToast
local useState = React.useState
local useRef = React.useRef
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local SmallText = require(script.Parent.ui.SmallText)

type Everything = {
	EspressoBought: boolean,
	MixerNodePromptShown: boolean,
	IsMixerPanel: boolean,
	IsEspressoInserted: boolean,
	IsMixerFilled: boolean,
	DrinkBrewed: boolean,
	IsDrinkPickedUp: boolean,
	TableSlotNodeShown: boolean,
	ATableSlotFilled: boolean,
	ACustomerQueuing: boolean,
	PlayerTendedCustomer: boolean,
}
local player = game.Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""

local getEspressoBought = function()
	local state: GlobalState.GlobalState = GlobalState:getState()
	local playersIngredients = state.Ingredients[playerId]
	if not playersIngredients then
		return false
	end
	if not (playersIngredients.espresso and playersIngredients.espresso > 0) then
		return false
	end
	-- warn("EspressoBought")
	return true
end
local getMixerNodePromptShown = function()
	local state: UIState.UIState = UIState:getState()
	local mixerNodeShown = state.mixerNodeShown
	if not mixerNodeShown then
		return false
	end
	return true
end
local getIsMixerPanel = function()
	local state: UIState.UIState = UIState:getState()
	local panel = state.panel
	if not (panel and panel == "mixer") then
		return false
	end
	return true
end
local getIsEspressoInserted = function()
	local state: UIState.UIState = UIState:getState()
	return state.isEspressoInserted
end
local getIsMixerFilled = function()
	local state: GlobalState.GlobalState = GlobalState:getState()
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
end

local getDrinkBrewed = function()
	local state: GlobalState.GlobalState = GlobalState:getState()
	local playersMixers = state.Mixers[playerId]
	if not playersMixers then
		return false
	end
	local mixer1 = playersMixers.Mixer1
	if not mixer1 then
		return false
	end
	local duration = CoffeeModule.Config.espresso.Duration
	if not mixer1.startTime or (mixer1.startTime + duration > workspace:GetServerTimeNow()) then
		return false
	end
	return true
end

local getIsDrinkPickedUp = function()
	local state: GlobalState.GlobalState = GlobalState:getState()
	local playersDrinks = state.Drinks[playerId]
	if not playersDrinks then
		return false
	end
	if #playersDrinks < 1 then
		return false
	end
	return true
end

local getTableSlotNodeShown = function(s)
	local state: UIState.UIState = UIState:getState()
	return state.tableSlotNodeShown
end

local getATableSlotFilled = function()
	local state: GlobalState.GlobalState = GlobalState:getState()
	local playersTables = state.Tables[playerId]
	if not playersTables then
		return false
	end
	local isFilled = false
	for slotId, drinkUid in playersTables.Table1.Slots do
		if drinkUid == "none" then
			continue
		end
		isFilled = true
	end
	return isFilled
end
local getACustomerQueuing = function()
	local state: GlobalState.GlobalState = GlobalState:getState()
	local playersCustomers = state.Customers[playerId]
	if not playersCustomers then
		return false
	end
	local isQueuing = false
	for i, customer in playersCustomers do
		if customer.customerAction ~= "queuing" then
			continue
		end
		isQueuing = true
	end
	return isQueuing
end
local getAPlayerTendedCustomer = function()
	local state: GlobalState.GlobalState = GlobalState:getState()
	local playersCustomers = state.Customers[playerId]
	if not playersCustomers then
		return false
	end
	local paid = false
	for i, customer in playersCustomers do
		if customer.customerAction ~= "paid" then
			continue
		end
		paid = true
	end
	return paid
end

local selectEverything: () -> Everything = Reflex.createSelector(
	{
		getEspressoBought,
		getMixerNodePromptShown,
		getIsMixerPanel,
		getIsEspressoInserted,
		getIsMixerFilled,
		getDrinkBrewed,
		getIsDrinkPickedUp,
		getTableSlotNodeShown,
		getATableSlotFilled,
		getACustomerQueuing,
		getAPlayerTendedCustomer,
	},
	function(
		EspressoBought,
		MixerNodePromptShown,
		IsMixerPanel,
		IsEspressoInserted,
		IsMixerFilled,
		DrinkBrewed,
		IsDrinkPickedUp,
		TableSlotNodeShown,
		ATableSlotFilled,
		ACustomerQueuing,
		PlayerTendedCustomer
	)
		-- warn("selectEverything")
		return {
			EspressoBought = EspressoBought,
			MixerNodePromptShown = MixerNodePromptShown,
			IsMixerPanel = IsMixerPanel,
			IsEspressoInserted = IsEspressoInserted,
			IsMixerFilled = IsMixerFilled,
			DrinkBrewed = DrinkBrewed,
			IsDrinkPickedUp = IsDrinkPickedUp,
			TableSlotNodeShown = TableSlotNodeShown,
			ATableSlotFilled = ATableSlotFilled,
			ACustomerQueuing = ACustomerQueuing,
			PlayerTendedCustomer = PlayerTendedCustomer,
		}
	end
)

-- local React = require(ReplicatedStorage.Shared.ReactComponents)

local function Tutorial(props)
	--[[
    ladder step, condition/check, action/render
    1) Player buys an "espresso" ingredient     | Ingredients.espresso and > 1              | highlight in IngredientShopPanel
    2) Player go to the mixer                   | MixerNode's PromptShown                   | "Go to mixer" if already then "Click to open"
    3) Player open the mixer panel              | UIState.panel == "mixer"                  | "Tap espresso to craft"
    4) Player insert the ingredient             | MixerPanel's ingredients has "espresso"   |  "Tap Craft to craft"
    5) Player clicks the Craft button           | mixer.drinkId ~= "none"                   | "Wait until done."
    6) Player waits a bit                       |  now > mixer.StartTime + Duration         | "Pick up the espresso"
    7) Player click the prompt to pick up       | #Drinks > 0                               | "Go to a table to place espresso"
    8) Player goes to a table                   | PromptShown from SlotNode                 | "Tap to place"
    9) Player places a drink                    | Check if any table has any slots filled   | "Wait for a customer to buy the drink!" and ToggleCafeOpen:FireServer()
    10) Player wait for a customer to checkout  | any customer.customerAction == "queuing"  | "Tap to tend the customers!"
    11) Player tends the customer               | stats.totalCustomer > 1                   | "Tutorial Complete!"

    then fire server to toggle CafeOpen if isn't already open
    ]]
	local toast = useToast()
	local everything: Everything, setEveryting = useState(nil)
	local tutorialCompleted, setTutorialCompleted = useState(nil)
	local text: string, setText = useState("")
	local completedRef = useRef(nil)

	useEffect(function()
		if completedRef.current then
			return
		end
		local unsub = GlobalState:subscribe(function(state)
			local playersStats = state.Stats[playerId]
			if not playersStats then
				return
			end
			local tutorialCompleted = playersStats.TutorialCompleted or false
			setTutorialCompleted(tutorialCompleted)
		end)
		local state = GlobalState:getState()
		local playersStats = state.Stats[playerId]
		if playersStats then
			local tutorialCompleted = playersStats.TutorialCompleted
			setTutorialCompleted(tutorialCompleted)
		end
		return unsub
	end, {})

	useEffect(function()
		if completedRef.current then
			return
		end
		if tutorialCompleted then
			completedRef.current = true
			return
		end
		local t = task.spawn(function()
			while task.wait(0.5) do
				-- warn("selecting everything")
				setEveryting(selectEverything({}))
			end
		end)
		return function()
			task.cancel(t)
		end
	end, { tutorialCompleted })

	useEffect(function()
		if completedRef.current then
			return
		end
		if tutorialCompleted then
			return
		end
		if not everything then
			-- warn("not everything")
			return
		end
		-- 11) See if player already got a customer paid
		if everything.PlayerTendedCustomer then
			setText(`Congrats, you completed the tutorial! Have Fun!`, 10)
			Remotes.CompleteTutorial:FireServer()
			task.delay(5, function()
				setText("")
			end)
			return
		end

		if everything.ACustomerQueuing then
			setText(`Tend to the customer at the cashier`)
			return
		end

		if everything.ATableSlotFilled then
			local state = GlobalState:getState()
			local playerStats = state.Stats[playerId]
			local open = playerStats.CafeOpen

			if not open then
				Remotes.ToggleCafeOpen:FireServer()
				warn("opened")
			end
			-- setText(`ATableSlotFilled`)
			setText("Wait until a customer comes in")
			return
		end
		if everything.IsDrinkPickedUp and everything.TableSlotNodeShown then
			-- setText(`TableSlotNodeShown`)
			setText("Place it.")
			return
		end

		if everything.IsDrinkPickedUp then
			-- setText(`IsDrinkPickedUp`)
			setText("Go to the table to place")
			return
		end
		if everything.DrinkBrewed then
			-- setText(`DrinkBrewed`)
			setText("Pick it up")
			return
		end

		if everything.IsMixerFilled then
			-- setText(`IsMixerFilled`)
			setText("Wait until the mixer is done")
			return
		end

		if everything.IsEspressoInserted then
			-- setText(`IsEspressoInserted`)
			setText("Click Craft")
			return
		end

		if everything.EspressoBought and everything.IsMixerPanel then
			-- setText(`IsMixerPanel`)
			setText("Click on the espresso to craft")
			return
		end
		if everything.EspressoBought and everything.MixerNodePromptShown then
			-- setText(`MixerNodePromptShown`)
			setText("Open the mixer")
			return
		end

		if everything.EspressoBought then
			-- setText(`EspressoBought`)
			setText("Go to your mixer")
			return
		end

		setText("Open the shop and Buy an Espresso")

		return function()
			--
		end
	end, { everything })

	return e("ScreenGui", {}, {
		e(SmallText, {
			Text = text,
			Size = UDim2.new(1, 0, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Center,
		}),
	}) or nil
end

return Tutorial
