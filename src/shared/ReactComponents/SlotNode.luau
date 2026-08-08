-- Shared/ReactComponents/SlotNode.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Promise = require(ReplicatedStorage.Packages.Promise)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local Types = require(ReplicatedStorage.Shared.Types)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)
local SmallText = require(script.Parent.ui.SmallText)
local SmallButton = require(script.Parent.ui.SmallButton)
local HStack = require(script.Parent.ui.HStack)

local useInputDevice = require(ReplicatedStorage.Shared.Hooks.useInputDevice)
local BuildersIcon = require(ReplicatedStorage.Shared.Utils.BuildersIcon)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local ColorGradient = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.new(1, 0.95, 0.7)),
	ColorSequenceKeypoint.new(1, Color3.new(1, 0.65, 0.2)),
})

local function SlotNode(props: {
	SlotName: string,
	DrinkUid: string,
	Instance: CafeTypes.Slot,
})
	local currentInput = useInputDevice()

	local playerId = tostring(Players.LocalPlayer.UserId)
	local drink: Types.DrinkEntity, setDrink = useState(nil)
	local on, setOn = useState(false)

	-- State to hold our asynchronously resolved instances
	local prompt, setPrompt = useState(nil)
	local placePart: Part?, setPlacePart = useState(nil)

	-- 1. Asynchronously resolve descendants using Promise to avoid yielding React
	useEffect(function()
		if not props.Instance then
			return
		end

		local promise = Promise.defer(function(resolve, reject)
			local resolvedPlacePart = props.Instance:WaitForChild("PlacePart", 5)
			if not resolvedPlacePart then
				return reject("PlacePart replication timeout")
			end

			local resolvedPrompt = resolvedPlacePart:WaitForChild("TriggerPrompt", 5)
			if not resolvedPrompt then
				return reject("TriggerPrompt replication timeout")
			end

			resolve({
				placePart = resolvedPlacePart,
				prompt = resolvedPrompt,
			})
		end)

		promise
			:andThen(function(resolved)
				setPlacePart(resolved.placePart)
				setPrompt(resolved.prompt)
			end)
			:catch(function(err)
				warn(`[SlotNode] Failed to resolve descendants for {props.SlotName}: {err}`)
			end)

		return function()
			promise:cancel()
		end
	end, { props.Instance })

	-- 2. Handle Proximity Prompt events
	useEffect(function()
		if not prompt then
			return
		end

		prompt.Style = Enum.ProximityPromptStyle.Custom

		local conn1 = prompt.PromptShown:Connect(function()
			UIState.setTableSlotNodeShown(true)
			setOn(true)
		end)
		local conn2 = prompt.PromptHidden:Connect(function()
			UIState.setTableSlotNodeShown(nil)
			setOn(false)
		end)

		return function()
			prompt.Style = Enum.ProximityPromptStyle.Default
			conn1:Disconnect()
			conn2:Disconnect()
		end
	end, { prompt })

	-- 3. Granular state subscription to prevent unnecessary rerenders
	useEffect(function()
		if not props.DrinkUid or props.DrinkUid == "none" then
			setDrink(nil)
			return
		end

		local function getSpecificDrink(state)
			local playerDrinks = state.Drinks and state.Drinks[playerId]
			if not playerDrinks then
				return nil
			end

			for _, d in pairs(playerDrinks) do
				if d.id == props.DrinkUid then
					return d
				end
			end
			return nil
		end

		local unsub = GlobalState:subscribe(getSpecificDrink, function(newDrink)
			setDrink(newDrink)
		end)

		setDrink(getSpecificDrink(GlobalState:getState()))

		return unsub
	end, { playerId, props.DrinkUid })

	local isMounted = React.useRef(false)
	local prevDrinkUid = React.useRef(props.DrinkUid)

	-- 4. Handle Sound on Drink Placement
	useEffect(function()
		if not isMounted.current then
			isMounted.current = true
			prevDrinkUid.current = props.DrinkUid
			return
		end

		if props.DrinkUid ~= "none" and props.DrinkUid ~= prevDrinkUid.current then
			SoundController.Sound("select_005")
		end

		prevDrinkUid.current = props.DrinkUid
	end, { props.DrinkUid })

	-- 5. Prepare variables for the Fragment render
	local adornee = props.Instance and (props.Instance:FindFirstChild("PlacedItem") or props.Instance) or nil
	local config = drink and CoffeeModule.Config[drink.drinkId] or nil
	local displayname = config and config.DisplayName or nil
	local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)
	local variation = (drink and drink.variationId) and VariationsConfig[drink.variationId] or nil

	local VariationLabel = variation
			and e(SmallText, {
				TextXAlignment = Enum.TextXAlignment.Center,
				BackgroundTransparency = 1,
				Text = variation.DisplayName,
				TextColor3 = variation.ColorPrimary or Color3.new(1, 1, 1),
				TextSize = 18,
				TextTruncate = Enum.TextTruncate.SplitWord,
				Active = false,
				ZIndex = 20,
				LayoutOrder = 1,
			}, {
				UIStroke = e("UIStroke", {
					Thickness = 4,
					Color = Color3.new(0.070588, 0.070588, 0.168627),
				}, {
					UIGradient = e("UIGradient", {
						Color = ColorGradient,
						Rotation = 78,
					}),
				}),
				UIGradient = e("UIGradient", {
					Color = ColorGradient,
					Rotation = 69,
				}),
				UIPadding = e("UIPadding", {
					PaddingTop = UDim.new(0, 4),
					PaddingBottom = UDim.new(0, 4),
					PaddingLeft = UDim.new(0, 4),
					PaddingRight = UDim.new(0, 4),
				}),
			})
		or nil

	-- Derived dynamically from the custom hook!
	local interactIcon = prompt
			and BuildersIcon.GetPromptText(
				currentInput == "Gamepad" and prompt.GamepadKeyCode or prompt.KeyboardKeyCode,
				currentInput
			)
		or BuildersIcon.GetPromptText(
			currentInput == "Gamepad" and Enum.KeyCode.ButtonX or Enum.KeyCode.E,
			currentInput
		)

	-- 6. Render unified Fragment
	return e(React.Fragment, nil, {
		-- Highlight rendering based on proximity shown state
		Highlight = on and e("Highlight", {
			Adornee = placePart or props.Instance,
			FillColor = Color3.new(1, 1, 1),
			FillTransparency = 0.7,
		}) or nil,

		-- Drink details (Only when a drink exists)
		DrinkInfo = (drink and drink.stock > 0 and adornee)
				and e(React.Fragment, nil, {
					StockGui = e("BillboardGui", {
						Active = true,
						Adornee = adornee,
						Size = UDim2.new(0, 60, 0, 30),
						StudsOffsetWorldSpace = Vector3.new(0, 1.5, 0),
						AlwaysOnTop = true,
						MaxDistance = 100,
					}, {
						Label = e(SmallText, {
							TextXAlignment = Enum.TextXAlignment.Center,
							Size = UDim2.new(1, 0, 1, 0),
							BackgroundTransparency = 1,
							Text = `{drink.stock}x`,
							TextColor3 = Color3.new(1, 1, 1),
							TextStrokeTransparency = 0,
							TextStrokeColor3 = Color3.new(0, 0, 0),
						}),
					}),
					VariationGui = e("BillboardGui", {
						Active = true,
						Adornee = adornee,
						Size = UDim2.new(0, 60, 0, 30),
						StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0),
						AlwaysOnTop = true,
						MaxDistance = 100,
					}, {
						LabelContainer = on
							and e(HStack, {
								Size = UDim2.new(3, 0, 0, 0),
								Position = UDim2.new(0.5, 0, 1, 0),
								AnchorPoint = Vector2.new(0.5, 1),
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
							}, {
								VariationLabel = VariationLabel,
								NameAndPrice = e(SmallText, {
									LayoutOrder = 2,
									TextXAlignment = Enum.TextXAlignment.Center,
									Text = `{displayname}: {variation and (variation.Multiplier * config.Price * drink.size) or config.Price}$`,
								}),
							}),
					}),
				})
			or nil,

		-- Contextual Interaction Button
		InteractGui = e("BillboardGui", {
			ResetOnSpawn = false,
			Adornee = placePart or props.Instance,
			Size = UDim2.new(0, 200, 0, 100),
			StudsOffsetWorldSpace = Vector3.new(0, -1.5, 0),
			AlwaysOnTop = true,
			MaxDistance = 100,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			Active = true,
		}, {
			SmallButton = on and e(SmallButton, {
				AnchorPoint = Vector2.new(0.5, 0),
				Size = UDim2.new(1.2, 0, 0.5, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				BackgroundTransparency = 1,
				Image = "rbxassetid://127657596958436",
				Rounded = false,
				ScaleType = Enum.ScaleType.Slice,
				HoverScale = true,
				SliceCenter = Rect.new(8, 8, 92, 92),
				ImageColor3 = Color3.new(0, 1, 0),
				[React.Event.MouseButton1Down] = function()
					if prompt then
						(prompt :: ProximityPrompt):InputHoldBegin()
					end
				end,
				[React.Event.MouseButton1Up] = function()
					if prompt then
						(prompt :: ProximityPrompt):InputHoldEnd()
					end
				end,
			}, {
				e(SmallText, {
					Text = `{interactIcon} {drink and "Pickup" or "Place"}`,
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					RichText = true,
					TextWrapped = false,
					TextSize = 24,
					AutomaticSize = Enum.AutomaticSize.None,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
				}),
			}),
		}),
	})
end

return SlotNode
