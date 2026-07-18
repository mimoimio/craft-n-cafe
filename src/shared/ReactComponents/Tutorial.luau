-- Shared/ReactComponents/Tutorial.luau
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
	return true
end
local getIsShopPanel = function()
	local state: UIState.UIState = UIState:getState()
	return state.panel == "ingredientShop"
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
		getIsShopPanel,
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
		IsShopPanel,
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
		return {
			EspressoBought = EspressoBought,
			IsShopPanel = IsShopPanel,
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

local function Tutorial(props)
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

	-- New State to hold the dynamically resolved Mixer instance
	local mixerInstance, setMixerInstance = useState(nil)
	local tableInstance, setTableInstance = useState(nil)

	useEffect(function()
		local t = task.spawn(function()
			while task.wait() do
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
			return
		end
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
			setStep(9)
			setText("Wait until a customer comes in")
			return
		end
		if everything.IsDrinkPickedUp and everything.TableSlotNodeShown then
			setStep(8)
			setText("Place it.")
			return
		end

		if everything.IsDrinkPickedUp then
			setText("Go to the table to place")
			setStep(7)
			return
		end
		if everything.DrinkBrewed then
			setStep(6)
			setText("Pick it up")
			return
		end

		if everything.IsMixerFilled then
			setStep(5)
			setText("Wait until the mixer is done")
			return
		end

		if everything.IsEspressoInserted then
			setStep(4)
			setText("Click Craft")
			return
		end

		if everything.EspressoBought and everything.IsMixerPanel then
			setStep(4)
			setText("Click on the espresso to craft")
			return
		end
		if everything.EspressoBought and everything.MixerNodePromptShown then
			setStep(3)
			setText("Open the mixer")
			return
		end

		if everything.EspressoBought then
			setStep(2)
			setText("Close shop and go to your mixer")
			return
		end

		if everything.IsShopPanel then
			setStep(1.1) -- additional. I dont bother to restep everything else
			setText("Click espresso and buy it")
			return
		end
		setStep(1)
		setText("Open the shop and Buy an Espresso")

		return
	end, { everything })

	-- Resolve the Mixer instance asynchronously using CollectionService tags
	useEffect(function()
		if (step == 2 or step == 3 or step == 6) and not mixerInstance then
			local promise = Promise.defer(function(resolve, reject)
				local tag = "Mixer" .. playerId

				-- 1. Check if the instance is already loaded and tagged
				for _, inst in CollectionService:GetTagged(tag) do
					if inst.Name == "Mixer1" then
						return resolve(inst)
					end
				end

				-- 2. If not, wait for it to be added by CafeRenderingService
				local conn
				conn = CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst)
					if inst.Name == "Mixer1" then
						conn:Disconnect()
						resolve(inst)
					end
				end)

				-- 3. Fail-safe timeout
				task.delay(10, function()
					if promise:getStatus() == Promise.Status.Started then
						if conn and conn.Connected then
							conn:Disconnect()
						end
						reject("Timeout waiting for Mixer1 replication via CollectionService")
					end
				end)
			end)

			promise
				:andThen(function(resolvedMixer)
					setMixerInstance(resolvedMixer)
					setArrow({
						rotation = 0,
						positionFromTarget = UDim2.new(0, 0, 0, -100),
					})
					setArrowTarget(nil)
				end)
				:catch(function(err)
					warn(`[Tutorial] Failed to resolve Mixer1: {err}`)
				end)

			return function()
				promise:cancel()
			end
		end
	end, { step, mixerInstance, playerId })

	-- Resolve the table instance asynchronously using CollectionService tags
	useEffect(function()
		if (step == 2 or step == 3 or step == 6) and not mixerInstance then
			local promise = Promise.defer(function(resolve, reject)
				local tag = "Table" .. playerId

				-- 1. Check if the instance is already loaded and tagged
				for _, inst in CollectionService:GetTagged(tag) do
					if inst.Name == "Table1" then
						return resolve(inst)
					end
				end

				-- 2. If not, wait for it to be added by CafeRenderingService
				local conn
				conn = CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst)
					if inst.Name == "Table1" then
						conn:Disconnect()
						resolve(inst)
					end
				end)

				-- 3. Fail-safe timeout
				task.delay(10, function()
					if promise:getStatus() == Promise.Status.Started then
						if conn and conn.Connected then
							conn:Disconnect()
						end
						reject("Timeout waiting for Table1 replication via CollectionService")
					end
				end)
			end)

			promise
				:andThen(function(resolvedMixer)
					setTableInstance(resolvedMixer)
					setArrow({
						rotation = 0,
						positionFromTarget = UDim2.new(0, 0, 0, -100),
					})
					setArrowTarget(nil)
				end)
				:catch(function(err)
					warn(`[Tutorial] Failed to resolve Table1: {err}`)
				end)
			return function()
				promise:cancel()
			end
		end
	end, { step, tableInstance, playerId })

	-- action
	useEffect(function()
		if step == 1 then
			local unsub = UIState:subscribe(function(state: UIState.UIState)
				local shopButton = state.shopButton
				setArrowTarget(shopButton)
			end)
			local shopButton = UIState:getState().shopButton
			setArrowTarget(shopButton)
			setArrow({
				rotation = 90,
				positionFromTarget = UDim2.fromOffset(100, 0),
			})
			return function()
				unsub()
			end
		elseif step == 2 or step == 3 then
			-- Handled natively via the ScreenGui Highlight below
		elseif step == 4 then
			--
		elseif step == 5 then
			--
		elseif step == 6 then
			-- Handled natively via the ScreenGui Highlight below
		elseif step == 7 then
			-- highlight the table instance
		elseif step == 8 then
			--
		elseif step == 9 then
			--
		elseif step == 10 then
			-- highlight the customer instance
			return function() end
		end
		return
	end, { step })

	-- This now calculates the arrow target position continuously!
	local positionMap = useCallback(function(t)
		local rot = arrow and arrow.rotation
		if not rot then
			return UDim2.new()
		end

		-- Dynamically fetch AbsolutePosition here so it perfectly tracks moving UI elements!
		local currentAbsPos = arrowTarget and arrowTarget.AbsolutePosition or Vector2.new()
		local posFromTarget = arrow and arrow.positionFromTarget or UDim2.new()

		-- Combine them into our base position
		local basePos = UDim2.fromOffset(currentAbsPos.X, currentAbsPos.Y) + posFromTarget

		local xMag, yMag = math.cos((rot - 90) * math.pi / 180), math.sin((rot - 90) * math.pi / 180)
		return basePos + UDim2.fromOffset(math.sin(t * 5) * xMag * 50, math.sin(t * 5) * yMag * 50)
	end, { arrow, arrowTarget })

	local arrowRotation = arrow and arrow.rotation or 0

	-- Determine if the highlight should be visible right now
	local showMixerHighlight = (step == 2 or step == 3 or step == 6) and mixerInstance ~= nil
	local showTableHighlight = (step == 7 or step == 8) and tableInstance ~= nil

	local textRef = useRef("")
	useEffect(function()
		textRef.current = text
	end, { text })

	local textMap = useCallback(function(t)
		local finalTexts = {}
		local originalText = textRef.current or ""
		local length = string.len(originalText)
		for i = 1, length do
			local offset = (math.sin((t + i) * 5) + 1) * 2
			table.insert(finalTexts, `<font size="{18 + offset // 1}">{string.sub(originalText, i, i)}</font>`)
		end
		return table.concat(finalTexts)
	end, {})

	return not tutorialCompleted
			and e("ScreenGui", {
				DisplayOrder = 1005,
			}, {
				-- The Dynamic Highlight
				MixerHighlight = showMixerHighlight and e("Highlight", {
					Adornee = mixerInstance:FindFirstChildWhichIsA("Model") or mixerInstance,
					FillColor = Color3.new(1, 1, 1),
					FillTransparency = 0.5,
					OutlineColor = Color3.new(1, 1, 1),
					OutlineTransparency = 0,
				}),
				TableHighlight = showTableHighlight and e("Highlight", {
					Adornee = tableInstance or nil,
					FillColor = Color3.new(1, 1, 1),
					FillTransparency = 0.5,
					OutlineColor = Color3.new(1, 1, 1),
					OutlineTransparency = 0,
				}),

				-- Existing UI...
				e("ImageLabel", {
					Size = UDim2.new(0.5, 0, 0, 40),
					AutomaticSize = Enum.AutomaticSize.XY,
					Position = UDim2.new(0.5, 0, 1, -100),
					AnchorPoint = Vector2.new(0.5, 1),
					Image = "rbxassetid://127657596958436",
					ImageTransparency = 0.6,
					ImageColor3 = Color3.new(0.768627, 0.549019, 0.549019),
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(8, 8, 92, 92),
					BackgroundTransparency = 1,
				}, {
					e(SmallText, {
						RichText = true,
						Size = UDim2.new(1, 0, 1, 0),
						Text = time:map(textMap),
						-- Font = Enum.Font.RobotoMono,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextYAlignment = Enum.TextYAlignment.Center,
						MaxTextSize = 24,
					}),
				}),

				BBGui = step and (step == 2 or step == 3 or step == 6) and e("BillboardGui", {
					Adornee = mixerInstance or nil,
					AlwaysOnTop = true,
					Size = UDim2.new(0, 1000, 0, 1000),
				}, {
					Holderer = e("Frame", {
						Size = UDim2.new(0, 50, 0, 50),
						Position = UDim2.new(0.5, 0, 0.5, 0),
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(0.5, 0.5),
					}, {
						Holder = e("Frame", {
							Size = UDim2.new(0, 50, 0, 50),
							AutomaticSize = Enum.AutomaticSize.XY,
							BackgroundTransparency = 1,
							Position = time:map(positionMap),
							-- Holder bc rotation only in imagelable
						}, {
							Arrow = e("ImageLabel", {
								Size = UDim2.new(0, 50, 0, 50),
								AutomaticSize = Enum.AutomaticSize.XY,
								BackgroundTransparency = 1,
								Rotation = arrowRotation,
								Image = "rbxassetid://8152628560",
							}),
						}),
					}),
				}) or nil,
				TableBBGui = showTableHighlight and e("BillboardGui", {
					Adornee = tableInstance or nil,
					AlwaysOnTop = true,
					Size = UDim2.new(0, 1000, 0, 1000),
				}, {
					Holderer = e("Frame", {
						Size = UDim2.new(0, 50, 0, 50),
						Position = UDim2.new(0.5, 0, 0.5, 0),
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(0.5, 0.5),
					}, {
						Holder = e("Frame", {
							Size = UDim2.new(0, 50, 0, 50),
							AutomaticSize = Enum.AutomaticSize.XY,
							BackgroundTransparency = 1,
							Position = time:map(positionMap),
							-- Holder bc rotation only in imagelable
						}, {
							Arrow = e("ImageLabel", {
								Size = UDim2.new(0, 50, 0, 50),
								AutomaticSize = Enum.AutomaticSize.XY,
								BackgroundTransparency = 1,
								Rotation = arrowRotation,
								Image = "rbxassetid://8152628560",
							}),
						}),
					}),
				}) or nil,
				step and step == 1 and e("Frame", {
					Size = UDim2.new(0, 50, 0, 50),
					AutomaticSize = Enum.AutomaticSize.XY,
					BackgroundTransparency = 1,
					Position = time:map(positionMap),
					Rotation = 0,
					-- Holder bc rotation only in imagelable
				}, {
					e("ImageLabel", {
						Size = UDim2.new(0, 50, 0, 50),
						AutomaticSize = Enum.AutomaticSize.XY,
						-- Position = time:map(positionMap),
						BackgroundTransparency = 1,
						Rotation = arrowRotation,
						Image = "rbxassetid://8152628560",
					}),
				}),
			})
		or nil
end

return Tutorial
