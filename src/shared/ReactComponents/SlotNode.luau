-- Shared/ReactComponents/SlotNode.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local SmallText = require(script.Parent.ui.SmallText)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef
local function SlotNode(props: {
	SlotName: string,
	DrinkUid: string,
	Instance: Instance,
})
	local playerId = tostring(Players.LocalPlayer.UserId)
	local drink, setDrink = useState(nil)
	local on, setOn = useState(false)
	local model, setModel = useState(nil)
	local promptText, setPromptText = useState("")

	useEffect(function()
		if not props.Instance then
			return
		end
		props.Instance.PlacePart.TriggerPrompt.Style = Enum.ProximityPromptStyle.Custom

		local conn = props.Instance.PlacePart.TriggerPrompt.PromptShown:Connect(
			function(inputType: Enum.ProximityPromptInputType)
				setOn(true)
				local mobile = Enum.ProximityPromptInputType == Enum.ProximityPromptInputType.Touch
				setPromptText(mobile and "" or `[E]`)
			end
		)
		local conn2 = props.Instance.PlacePart.TriggerPrompt.PromptHidden:Connect(function()
			setOn(false)
			setPromptText("")
		end)
		return function()
			props.Instance.PlacePart.TriggerPrompt.Style = Enum.ProximityPromptStyle.Default
			conn:Disconnect()
			conn2:Disconnect()
		end
	end, { props.Instance })
	-- 1. Granular state subscription to prevent unnecessary rerenders
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

			-- Accommodate array iteration structure based on CustomersService logic
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

	-- 2. Handle Sound on Drink Placement
	useEffect(function()
		if not isMounted.current then
			isMounted.current = true
			prevDrinkUid.current = props.DrinkUid
			-- warn(`isMounted.current: ({isMounted.current})`)
			return
		end

		-- Play sound only when transitioning to a new valid drink
		if props.DrinkUid ~= "none" and props.DrinkUid ~= prevDrinkUid.current then
			-- warn(`[success] props.DrinkUid: ({props.DrinkUid}) prevDrinkUid.current: ({prevDrinkUid.current})`)
			SoundController.Sound("select_005")
		else
			-- warn(`[failed] props.DrinkUid: ({props.DrinkUid}) prevDrinkUid.current: ({prevDrinkUid.current})`)
		end

		prevDrinkUid.current = props.DrinkUid
	end, { props.DrinkUid })

	-- 3. Render BillboardGui
	if drink and drink.stock > 0 and props.Instance then
		-- Fall back to the PlacedItem if it exists for precise offset, otherwise track the Slot model
		local adornee = props.Instance:FindFirstChild("PlacedItem") or props.Instance
		local config = CoffeeModule.Config[drink.drinkId]
		local displayname = config and config.DisplayName

		return e("ScreenGui", nil, {
			label = on and e(SmallText, {
				TextXAlignment = Enum.TextXAlignment.Center,
				Text = `{displayname}: {config.Price}$`,
				Position = UDim2.new(0.5, 0, 1, -80),
				AnchorPoint = Vector2.new(0.5, 0),
			}),
			highlight = on and e("Highlight", {
				Adornee = props.Instance:FindFirstChildWhichIsA("Model"),
				FillColor = Color3.new(1, 1, 1),
				FillTransparency = 0.7,
			}),
			BBGui = e("BillboardGui", {
				Adornee = adornee,
				Size = UDim2.new(0, 60, 0, 30),
				StudsOffset = Vector3.new(0, 1.5, 0),
				AlwaysOnTop = true,
				MaxDistance = 20,
			}, {
				Label = e(SmallText, {
					TextXAlignment = Enum.TextXAlignment.Center,
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = `{drink.stock}x`,
					TextColor3 = Color3.new(1, 1, 1),
					TextStrokeTransparency = 0,
					TextStrokeColor3 = Color3.new(0, 0, 0),
					TextScaled = true,
				}),
			}),
			custom = e("BillboardGui", {
				Adornee = adornee,
				Size = UDim2.new(0, 60, 0, 30),
				StudsOffset = Vector3.new(0, -1.5, 0),
				AlwaysOnTop = true,
				MaxDistance = 20,
			}, {
				Label = on and e(SmallText, {
					TextXAlignment = Enum.TextXAlignment.Center,
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 0,
					Text = `{promptText} {drink and "Pickup" or "Place"}`,
					TextColor3 = Color3.new(1, 1, 1),
					TextStrokeTransparency = 0,
					TextStrokeColor3 = Color3.new(0, 0, 0),
					Font = Enum.Font.FredokaOne,
					TextScaled = true,
				}, {
					UICorner = e("UICorner", {
						CornerRadius = UDim.new(0, 8),
					}),
				}),
			}),
		})
	end

	local adornee = props.Instance:FindFirstChild("PlacedItem") or props.Instance
	return on
		and e("BillboardGui", {
			Adornee = adornee,
			Size = UDim2.new(0, 60, 0, 30),
			StudsOffset = Vector3.new(0, -1.5, 0),
			AlwaysOnTop = true,
			MaxDistance = 20,
		}, {
			Highlihgt = e("Highlight", {
				Adornee = props.Instance.PlacePart,
				FillColor = Color3.new(1, 1, 1),
				FillTransparency = 0.7,
			}),
			Label = e(SmallText, {
				Size = UDim2.new(1, 0, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Center,
				BackgroundTransparency = 0,
				Text = `{promptText} {drink and "Pickup" or "Place"}`,
				TextColor3 = Color3.new(1, 1, 1),
				TextStrokeTransparency = 0,
				TextStrokeColor3 = Color3.new(0, 0, 0),
				Font = Enum.Font.FredokaOne,
				TextScaled = true,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			}),
		})
end

return SlotNode
