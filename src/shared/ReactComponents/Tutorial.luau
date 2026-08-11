-- Shared/ReactComponents/Tutorial.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Promise = require(ReplicatedStorage.Packages.Promise)
local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState
local useBinding = React.useBinding
local useCallback = React.useCallback
local useRef = React.useRef

local Toasts = require(ReplicatedStorage.Shared.ReactComponents.Toasts)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local SmallText = require(script.Parent.ui.SmallText)

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""

-------------------------------------------------------------------------------
-- Local Component: ScreenGuiCircle
-------------------------------------------------------------------------------
local function ScreenGuiCircle(props: { TargetButton: GuiButton?, Color: Color3? })
	local time, setTime = useBinding(workspace:GetServerTimeNow())

	useEffect(function()
		local running = true
		local t = task.spawn(function()
			while running do
				task.wait()
				setTime(workspace:GetServerTimeNow())
			end
		end)
		return function()
			running = false
			task.cancel(t)
		end
	end, {})

	local sizeMap = useCallback(function(t)
		local pulse = math.sin(t * 5) * 5
		return UDim2.fromOffset(60 + pulse, 60 + pulse)
	end, {})

	local posMap = useCallback(function(t)
		if not props.TargetButton then
			return UDim2.new()
		end
		local center = props.TargetButton.AbsolutePosition + (props.TargetButton.AbsoluteSize / 2)
		return UDim2.fromOffset(center.X, center.Y)
	end, { props.TargetButton })

	if not props.TargetButton then
		return nil
	end

	return e("ScreenGui", {
		ResetOnSpawn = false,
		DisplayOrder = 1010,
	}, {
		Wrapper = e("Frame", {
			BackgroundTransparency = 1,
			Position = time:map(posMap),
			Size = UDim2.fromOffset(60, 60),
			AnchorPoint = Vector2.new(0.5, 0.5),
		}, {
			Circle = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = time:map(sizeMap),
				BackgroundColor3 = props.Color or Color3.new(1, 1, 1),
				BackgroundTransparency = 0.8,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Stroke = e("UIStroke", {
					Color = props.Color or Color3.new(1, 1, 1),
					Thickness = 3,
				}),
			}),
		}),
	})
end

-------------------------------------------------------------------------------
-- Local Component: PointerBeam
-------------------------------------------------------------------------------
local function PointerBeam(props: { Adornee: PVInstance? })
	local char: Model?, setChar = useState(nil)
	local time, setTime = useBinding(workspace:GetServerTimeNow())

	useEffect(function()
		local running = true
		local t = task.spawn(function()
			while running do
				task.wait()
				setTime(workspace:GetServerTimeNow())
			end
		end)
		return function()
			running = false
			task.cancel(t)
		end
	end, {})

	useEffect(function()
		local conn = player and player.CharacterAdded:Connect(function(character)
			setChar(character)
		end)
		local promise = Promise.defer(function(resolve, reject)
			if not player then
				reject(`player is nil`)
			end
			return resolve(player.Character or player.CharacterAdded:Wait())
		end)
		promise:andThen(setChar):catch(warn)

		return function()
			promise:cancel()
			if conn then
				conn:Disconnect()
			end
		end
	end, {})

	useEffect(function()
		if not (char and props.Adornee) then
			return
		end

		local part = Instance.new("Part")
		part.Anchored = false
		part:PivotTo(char:GetPivot())
		part.CanCollide = false
		part.Transparency = 1

		local weld = Instance.new("WeldConstraint", part)
		weld.Part0 = part
		weld.Part1 = char.PrimaryPart or char:FindFirstChildWhichIsA("BasePart") or nil

		local att0 = Instance.new("Attachment", part)
		local att1 = Instance.new("Attachment", props.Adornee)

		part.Parent = workspace

		local beam = Instance.new("Beam", part)
		beam.Attachment0 = att0
		beam.Attachment1 = att1
		beam.FaceCamera = true
		beam.Texture = "rbxassetid://17476697388"
		beam.Transparency = NumberSequence.new(0)
		beam.LightInfluence = 0
		beam.Brightness = 10
		beam.TextureSpeed = 2

		return function()
			if part then
				part:Destroy()
			end
			if att1 then
				att1:Destroy()
			end
		end
	end, { char, props.Adornee })

	local positionMap = useCallback(function(t)
		return UDim2.new(0.5, 0, 0.5, math.sin(t * 5) * 50)
	end, {})

	if not props.Adornee then
		return nil
	end

	return e("BillboardGui", {
		Adornee = props.Adornee,
		AlwaysOnTop = true,
		Size = UDim2.new(0, 300, 0, 300),
		SizeOffset = Vector2.new(0, 1 / 3),
	}, {
		Holder = e("Frame", {
			Size = UDim2.new(0, 50, 0, 50),
			Position = time:map(positionMap),
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
		}, {
			Arrow = e("ImageLabel", {
				Size = UDim2.new(0, 50, 0, 50),
				BackgroundTransparency = 1,
				Rotation = 0,
				Image = "rbxassetid://8152628560",
			}),
		}),
	})
end

-------------------------------------------------------------------------------
-- Selectors
-------------------------------------------------------------------------------
local selectGlobalStates = Reflex.createSelector({
	function(state: GlobalState.GlobalState)
		local stats = state.Stats[playerId]
		local spawner = state.Spawner[playerId]
		local ingredients = state.Ingredients[playerId]
		local mixers = state.Mixers[playerId]
		local drinks = state.Drinks[playerId]
		local tables = state.Tables[playerId]
		local customers = state.Customers[playerId]

		local s = {
			StatsLoaded = stats ~= nil,
			CafeOpen = stats and stats.CafeOpen or false,

			EspressoSpawned = spawner
				and spawner.IngredientIds
				and table.find(spawner.IngredientIds, "espresso") ~= nil,
			EspressoBought = spawner
				and ingredients
				and spawner.IngredientIds
				and (ingredients.espresso and ingredients.espresso > 0),

			MilkSpawned = spawner and spawner.IngredientIds and table.find(spawner.IngredientIds, "milk") ~= nil,
			MilkBought = spawner
				and ingredients
				and spawner.IngredientIds
				and (ingredients.milk and ingredients.milk > 0),

			MixerFilled = false,
			DrinkBrewed = false,
			DrinkPickedUp = drinks and #drinks > 0 or false,

			TableSlotFilled = false,
			CustomerQueuing = false,
			CustomerPaid = false,
		}

		if mixers and mixers.Mixer1 then
			s.MixerFilled = mixers.Mixer1.drinkId and mixers.Mixer1.drinkId ~= "none"
			if s.MixerFilled and mixers.Mixer1.startTime then
				local config = CoffeeModule.Config[mixers.Mixer1.drinkId]
				local duration = config and config.Duration or 0
				s.DrinkBrewed = workspace:GetServerTimeNow() > mixers.Mixer1.startTime + duration
			end
		end

		if tables and tables.Table1 and tables.Table1.Slots then
			for _, drinkUid in pairs(tables.Table1.Slots) do
				if drinkUid ~= "none" then
					s.TableSlotFilled = true
					break
				end
			end
		end

		if customers then
			for _, customer in pairs(customers) do
				if customer.customerAction == "queuing" then
					s.CustomerQueuing = true
				elseif customer.customerAction == "paid" then
					s.CustomerPaid = true
				end
			end
		end

		return s
	end,
}, function(s)
	return s
end)

local selectUiStates = Reflex.createSelector({
	function(state: UIState.UIState)
		return {
			Panel = state.panel,
			SpawnerPromptShown = state.spawnerPromptShown,
			MixerNodeShown = state.mixerNodeShown,
			IsEspressoInserted = state.isEspressoInserted,
			IsMilkInserted = state.isMilkInserted,
			SpawnerInstance = state.spawnerInstance,
			BuypadInstance = state.buypadInstance,
			MixerInstance = state.mixerInstance,
			TableInstance = state.tableInstance,
			EspressoButton = state.espressoButton,
			MilkButton = state.milkButton,
			CraftButton = state.craftButton,
			FirstCustomer = state.firstCustomer,
		}
	end,
}, function(s)
	return s
end)

-------------------------------------------------------------------------------
-- Main Tutorial Component
-------------------------------------------------------------------------------
return function()
	local globalStates, setGlobalStates = useState({})
	local uiStates, setUiStates = useState({})
	local step, setStep = useState(1)
	local text, setText = useState("")

	local hasForcedLetterOpen = useRef(false)
	local completedRef = useRef(false)
	local highestStepRef = useRef(0)

	local time, setTime = useBinding(workspace:GetServerTimeNow())

	-- Subscriptions
	useEffect(function()
		local unsubGlobal = GlobalState:subscribe(selectGlobalStates, setGlobalStates)
		local unsubUi = UIState:subscribe(selectUiStates, setUiStates)

		setGlobalStates(selectGlobalStates(GlobalState:getState()))
		setUiStates(selectUiStates(UIState:getState()))

		return function()
			unsubGlobal()
			unsubUi()
		end
	end, {})

	-- Binding updater loop
	useEffect(function()
		local running = true
		local t = task.spawn(function()
			while running do
				task.wait(1 / 15)
				setTime(workspace:GetServerTimeNow())
				setGlobalStates(function(prev)
					if not prev or type(prev) ~= "table" then
						return
					end
					local new = table.clone(prev)
					local mixers = GlobalState:getState().Mixers[playerId]
					if mixers and mixers.Mixer1 then
						new.MixerFilled = mixers.Mixer1.drinkId and mixers.Mixer1.drinkId ~= "none"
						if new.MixerFilled and mixers.Mixer1.startTime then
							local config = CoffeeModule.Config[mixers.Mixer1.drinkId]
							local duration = config and config.Duration or 0
							new.DrinkBrewed = workspace:GetServerTimeNow() > mixers.Mixer1.startTime + duration
						end
					end
					return new
				end)
			end
		end)
		return function()
			running = false
			task.cancel(t)
		end
	end, {})

	-- Step 1: Force open letter when stats load
	useEffect(function()
		if not globalStates.StatsLoaded then
			return
		end
		if step == 1 and not hasForcedLetterOpen.current then
			hasForcedLetterOpen.current = true
			if uiStates.Panel ~= "rejectionletter" then
				UIState.toggle("rejectionletter")
			end
		end
	end, { globalStates.StatsLoaded, step, uiStates.Panel })

	-- Step 15: Toggle Cafe Open automatically
	useEffect(function()
		if step == 15 and globalStates.CafeOpen == false then
			Remotes.ToggleCafeOpen:FireServer()
		end
	end, { step, globalStates.CafeOpen })

	-- Step 17: Complete Tutorial
	useEffect(function()
		if step == 17 and not completedRef.current then
			completedRef.current = true
			task.delay(5, function()
				Remotes.CompleteTutorial:FireServer()
			end)
		end
	end, { step })

	-- Core Ladder Logic
	useEffect(function()
		if completedRef.current then
			return
		end

		local newStep = 1
		if globalStates.CustomerPaid then
			newStep = 17
		elseif globalStates.CustomerQueuing then
			newStep = 16
		elseif globalStates.TableSlotFilled then
			newStep = 15
		elseif globalStates.DrinkPickedUp then
			newStep = 14
		elseif globalStates.DrinkBrewed then
			newStep = 13
		elseif globalStates.MixerFilled then
			newStep = 12
		elseif uiStates.IsMilkInserted and uiStates.IsEspressoInserted then
			newStep = 11
		elseif uiStates.IsEspressoInserted then
			newStep = 10
		elseif uiStates.Panel == "mixer" and globalStates.MilkBought and globalStates.EspressoBought then
			newStep = 9
		elseif uiStates.MixerNodeShown == "Mixer1" and globalStates.MilkBought and globalStates.EspressoBought then
			newStep = 8
		elseif globalStates.MilkBought then
			newStep = 7
		elseif globalStates.MilkSpawned then
			newStep = 6
		elseif globalStates.EspressoBought then
			newStep = 5
		elseif globalStates.EspressoSpawned then
			newStep = 4
		elseif uiStates.SpawnerPromptShown then
			newStep = 3
		elseif hasForcedLetterOpen.current and uiStates.Panel ~= "rejectionletter" then
			newStep = 2
		end

		setStep(newStep)

		local texts = {
			[1] = "Read and close the letter.",
			[2] = "Go to the summoning circle.",
			[3] = "Summon an Espresso Ingredient.",
			[4] = "Buy the Espresso.",
			[5] = "Summon a Milk Ingredient.",
			[6] = "Buy the Milk.",
			[7] = "Go to your Cauldron.",
			[8] = "Interact with the Cauldron.",
			[9] = "Tap on Espresso to insert.",
			[10] = "Now Tap on Milk to insert.",
			[11] = "Tap 'Craft' to craft a Latte!",
			[12] = "Wait until the Latte is done.",
			[13] = "Pick up the drink.",
			[14] = "Place the drink on the table.",
			[15] = "Wait for a customer to buy the drink.",
			[16] = "Tend to the customer at the cashier.",
			[17] = "Congrats, you've completed the tutorial!",
		}
		setText(texts[newStep] or "")
	end, { globalStates, uiStates })

	-- Step Tracking Funnel
	useEffect(function()
		if step > highestStepRef.current then
			highestStepRef.current = step

			local stepNames = {
				[1] = "01_ReadLetter",
				[2] = "02_GoToCircle",
				[3] = "03_SummonEspresso",
				[4] = "04_BuyEspresso",
				[5] = "05_SummonMilk",
				[6] = "06_BuyMilk",
				[7] = "07_GoToCauldron",
				[8] = "08_InteractCauldron",
				[9] = "09_InsertEspresso",
				[10] = "10_InsertMilk",
				[11] = "11_TapCraft",
				[12] = "12_WaitBrew",
				[13] = "13_PickUpDrink",
				[14] = "14_PlaceDrink",
				[15] = "15_WaitCustomer",
				[16] = "16_TendCustomer",
				[17] = "17_CompleteTutorial",
			}

			local stepName = stepNames[step] or ("Step_" .. tostring(step))

			if Remotes.LogTutorialStep then
				Remotes.LogTutorialStep:FireServer(step, stepName)
			end
		end
	end, { step })

	-- Determine Targets for Visuals
	local adorneeTarget = nil
	if step == 2 or step == 3 or step == 5 then
		adorneeTarget = uiStates.SpawnerInstance
	end
	if step == 4 or step == 6 then
		adorneeTarget = uiStates.BuypadInstance
	end
	if step == 7 or step == 8 or step == 13 then
		adorneeTarget = uiStates.MixerInstance
	end
	if step == 14 then
		adorneeTarget = uiStates.TableInstance
	end
	if step == 16 then
		adorneeTarget = uiStates.FirstCustomer
	end

	local circleTarget = nil
	local circleColor = Color3.new(1, 1, 1)
	if step == 9 then
		circleTarget = uiStates.EspressoButton
		circleColor = Color3.fromRGB(111, 78, 55)
	end
	if step == 10 then
		circleTarget = uiStates.MilkButton
		circleColor = Color3.new(1, 1, 1)
	end
	if step == 11 then
		circleTarget = uiStates.CraftButton
		circleColor = Color3.fromRGB(128, 255, 0)
	end

	-- Text Animation Map
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

	-- Render
	return e("ScreenGui", {
		ResetOnSpawn = false,
		DisplayOrder = 1005,
	}, {
		-- Main Text Banner
		Banner = e("ImageLabel", {
			Size = UDim2.new(0.5, 0, 0, 40),
			AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2.new(0.5, 0, step == 14 and 0 or 1, step == 14 and 20 or -20),
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
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				MaxTextSize = 24,
			}),
		}),

		-- Conditional VFX
		PointerBeam = adorneeTarget and e(PointerBeam, {
			Adornee = adorneeTarget,
		}),

		ScreenGuiCircle = circleTarget and e(ScreenGuiCircle, {
			TargetButton = circleTarget,
			Color = circleColor,
		}),

		AdorneeHighlight = adorneeTarget and e("Highlight", {
			Adornee = adorneeTarget:FindFirstChildWhichIsA("Model") or adorneeTarget,
			FillColor = Color3.new(1, 1, 1),
			FillTransparency = 0.5,
			OutlineColor = Color3.new(1, 1, 1),
			OutlineTransparency = 0,
		}),
	})
end
