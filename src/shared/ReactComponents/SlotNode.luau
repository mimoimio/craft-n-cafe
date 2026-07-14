-- Shared/ReactComponents/SlotNode.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Promise = require(ReplicatedStorage.Packages.Promise) -- Added Promise
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local SmallText = require(script.Parent.ui.SmallText)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local TAP_ICON =
	`<font family="rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json">hand-half-ellipse</font>`

local function SlotNode(props: {
	SlotName: string,
	DrinkUid: string,
	Instance: Instance,
})
	local playerId = tostring(Players.LocalPlayer.UserId)
	local drink, setDrink = useState(nil)
	local on, setOn = useState(false)
	local promptText, setPromptText = useState("")

	-- State to hold our asynchronously resolved instances
	local prompt, setPrompt = useState(nil)
	local placePart, setPlacePart = useState(nil)

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
			-- If the component unmounts before WaitForChild finishes, cancel the Promise
			-- so it stops executing and doesn't attempt to update unmounted state.
			promise:cancel()
		end
	end, { props.Instance })

	-- 2. Handle Proximity Prompt events (only runs once the prompt is actually found)
	useEffect(function()
		if not prompt then
			return
		end

		prompt.Style = Enum.ProximityPromptStyle.Custom

		local conn1 = prompt.PromptShown:Connect(function(inputType: Enum.ProximityPromptInputType)
			UIState.setTableSlotNodeShown(true)
			setOn(true)
			local mobile = inputType == Enum.ProximityPromptInputType.Touch
			setPromptText(mobile and TAP_ICON or `[E]`)
		end)
		local conn2 = prompt.PromptHidden:Connect(function()
			UIState.setTableSlotNodeShown(nil)
			setOn(false)
			setPromptText("")
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

	local Label = e("ImageButton", {
		Size = UDim2.new(1, 0, 1, 0),
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
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 0.6,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
		SmallText = e(SmallText, {
			Size = UDim2.new(1, 0, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Text = `{promptText} {drink and "Pickup" or "Place"}`,
			AutomaticSize = Enum.AutomaticSize.XY,
			RichText = true,
			TextWrapped = false,
			TextColor3 = Color3.new(1, 1, 1),
			TextStrokeTransparency = 0,
			TextStrokeColor3 = Color3.new(0, 0, 0),
			Font = Enum.Font.FredokaOne,
			TextScaled = true,
			Active = false,
		}),
	})

	-- 5. Render BillboardGui
	if drink and drink.stock > 0 and props.Instance then
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
				Active = true,
				Adornee = adornee,
				Size = UDim2.new(0, 60, 0, 30),
				StudsOffsetWorldSpace = Vector3.new(0, 1.5, 0),
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
					-- TextScaled = true,
				}),
			}),
			custom = e("BillboardGui", {
				Active = true,
				Adornee = adornee,
				Size = UDim2.new(0, 60, 0, 30),
				StudsOffsetWorldSpace = Vector3.new(0, -1.5, 0),
				AlwaysOnTop = true,
				MaxDistance = 20,
			}, {
				Label = on and Label,
			}),
		})
	end

	local adornee = props.Instance:FindFirstChild("PlacedItem") or props.Instance
	return on
		and e("BillboardGui", {
			Active = true,
			Adornee = adornee,
			Size = UDim2.new(0, 60, 0, 30),
			AlwaysOnTop = true,
			StudsOffsetWorldSpace = Vector3.new(0, -1.5, 0),
			MaxDistance = 20,
		}, {
			Label = on and Label,
			Highlihgt = e("Highlight", {
				Adornee = placePart or props.Instance, -- Fallback to props.Instance if placePart isn't resolved yet
				FillColor = Color3.new(1, 1, 1),
				FillTransparency = 0.7,
			}),
		})
end

return SlotNode
