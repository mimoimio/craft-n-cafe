-- Shared/ReactComponents/SlotNode.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)

local e = React.createElement

local function SlotNode(props: {
	SlotName: string,
	DrinkUid: string,
	Instance: Instance,
})
	local playerId = tostring(Players.LocalPlayer.UserId)
	local drink, setDrink = React.useState(nil)

	-- 1. Granular state subscription to prevent unnecessary rerenders
	React.useEffect(function()
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
	React.useEffect(function()
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

		return e("BillboardGui", {
			Adornee = adornee,
			Size = UDim2.new(0, 60, 0, 30),
			StudsOffset = Vector3.new(0, 1.5, 0),
			AlwaysOnTop = true,
			MaxDistance = 20,
		}, {
			Label = e("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = `{drink.stock}x`,
				TextColor3 = Color3.new(1, 1, 1),
				TextStrokeTransparency = 0,
				TextStrokeColor3 = Color3.new(0, 0, 0),
				Font = Enum.Font.GothamBold,
				TextScaled = true,
			}),
		})
	end

	return nil
end

return SlotNode
