-- Shared/ReactComponents/Tutorial.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
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
	local step, setStep = useState(1)
	local arrow, setArrow = useState({
		rotation = 0,
		positionFromTarget = UDim2.new(),
	})
	local arrowTarget, setArrowTarget = useState(nil)
	local time, setTime = useBinding(workspace:GetServerTimeNow())

	useEffect(function()
		local t = task.spawn(function()
			while task.wait(1 / 30) do
				setTime(workspace:GetServerTimeNow())
			end
		end)
		return function()
			task.cancel(t)
		end
	end, {})

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

	-- run loop
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

	-- ladder
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
			setStep(10)
			setText(`Congrats, you completed the tutorial! Have Fun!`, 10)
			Remotes.CompleteTutorial:FireServer()
			task.delay(5, function()
				setText("")
			end)
			return
		end

		if everything.ACustomerQueuing then
			setStep(10)
			setText(`Tend to the customer at the cashier`)
			return
		end

		if everything.ATableSlotFilled then
			local state = GlobalState:getState()
			local playerStats = state.Stats[playerId]
			local open = playerStats.CafeOpen

			if not open then
				Remotes.ToggleCafeOpen:FireServer()
			end
			-- setText(`ATableSlotFilled`)
			setStep(9)
			setText("Wait until a customer comes in")
			return
		end
		if everything.IsDrinkPickedUp and everything.TableSlotNodeShown then
			-- setText(`TableSlotNodeShown`)
			setStep(8)
			setText("Place it.")
			return
		end

		if everything.IsDrinkPickedUp then
			-- setText(`IsDrinkPickedUp`)
			setText("Go to the table to place")
			setStep(7)
			return
		end
		if everything.DrinkBrewed then
			-- setText(`DrinkBrewed`)
			setStep(6)
			setText("Pick it up")
			return
		end

		if everything.IsMixerFilled then
			-- setText(`IsMixerFilled`)
			setStep(5)
			setText("Wait until the mixer is done")
			return
		end

		if everything.IsEspressoInserted then
			-- setText(`IsEspressoInserted`)
			setStep(4)
			setText("Click Craft")
			return
		end

		if everything.EspressoBought and everything.IsMixerPanel then
			-- setText(`IsMixerPanel`)
			setStep(4)
			setText("Click on the espresso to craft")
			return
		end
		if everything.EspressoBought and everything.MixerNodePromptShown then
			-- setText(`MixerNodePromptShown`)
			setStep(3)
			setText("Open the mixer")
			return
		end

		if everything.EspressoBought then
			-- setText(`EspressoBought`)
			setStep(2)
			setText("Go to your mixer")
			return
		end

		setStep(1)
		setText("Open the shop and Buy an Espresso")

		return function()
			--
		end
	end, { everything })

	-- action
	useEffect(function()
		if step == 1 then
			-- arrow to shop button

			local unsub = UIState:subscribe(function(state: UIState.UIState)
				local shopButton = state.shopButton
				setArrowTarget(shopButton)
			end)
			local shopButton = UIState:getState().shopButton
			setArrowTarget(shopButton)
			setArrow({
				rotation = 90, -- the arrow image is down, rotate to left
				positionFromTarget = UDim2.fromOffset(100, 0), -- 50, 50 size
			})
			return unsub
		elseif step == 2 or step == 3 then
			-- highlight the mixer instance
		elseif step == 4 then
			--
		elseif step == 5 then
			--
		elseif step == 6 then
			-- highlight the mixer instance
		elseif step == 7 then
			-- highlight the table instance
		elseif step == 8 then
			--
		elseif step == 9 then
			--
		elseif step == 10 then
			-- highlight the customer instance
			-- local unsub = UIState:subscribe(function(state: UIState.UIState)
			-- 	local customerInstance = state.firstCustomerInstance
			-- end)
			return function() end
		end
		return
	end, { step })

	local positionFromTarget = (arrow and arrow.positionFromTarget or UDim2.new())
	local targetAbsolutePosition: Vector2 = arrowTarget and arrowTarget.AbsolutePosition or Vector2.new()
	local targetPosition = UDim2.fromOffset(targetAbsolutePosition.X, targetAbsolutePosition.Y)
	local arrowPosition = (positionFromTarget + targetPosition) or nil
	local arrowRotation = arrow and arrow.rotation or nil

	local positionMap = useCallback(function(t)
		return arrowPosition + UDim2.fromOffset(math.sin(t * 5) * 50, 0)
	end, { arrowPosition })

	return e("ScreenGui", {}, {
		e("ImageLabel", {
			Size = UDim2.new(0.5, 0, 0, 40),
			AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2.new(0.5, 0, 1, -100),
			AnchorPoint = Vector2.new(0.5, 1),
			Image = "rbxassetid://127657596958436",
			ImageColor3 = Color3.new(0.768627, 0.549019, 0.549019),
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(8, 8, 92, 92),
			BackgroundTransparency = 1,
		}, {
			e(SmallText, {
				Size = UDim2.new(1, 0, 1, 0),
				Text = text,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
		}),
		e("ImageLabel", {
			Size = UDim2.new(0, 50, 0, 50),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			Position = time:map(positionMap),
			Rotation = arrowRotation,
			Image = "rbxassetid://8152628560",
		}),
	})
end

return Tutorial
