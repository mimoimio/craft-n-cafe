local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local Types = require(ReplicatedStorage.Shared.Types)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local e = React.createElement
local createSelector = Reflex.createSelector
local useEffect = React.useEffect
local useState = React.useState
local useRef = React.useRef
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local useBreakpoint = require(ReplicatedStorage.Shared.Hooks.useBreakpoint)

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""

local statuses = {
	[1] = "Good Enough",
	[2] = "Nice",
	[3] = "Perfect",
}
local sounds = {
	espresso = "water",
	water = "water",
	milk = "water",
	ice = "ice",
	foam = "foam",
	chocolate = "water",
	teabag = "powder",
	icecream = "splat",
	matchapowder = "powder",
	lemon = "splat",
	boba = "splat",
	carbonator = "bubbles",
}
local function getIngredientSound(ing: string): string?
	return sounds[ing]
end

return function(props)
	local xs, sm, md, lg, xl = useBreakpoint()
	local mobile = xs or sm or md

	local mdTextSize, smTextSize = mobile and 16 or 44, mobile and 10 or 12
	local cup: Types.CupEntity?, setCup: (cup: Types.CupEntity) -> nil = useState(nil)

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Cups[playerId] and state.Cups[playerId].player or nil
		end, setCup)

		local state = GlobalState:getState()
		local playersCup = state.Customers[playerId] and state.Cups[playerId].player
		setCup(playersCup)

		if not player then
			setCup({
				drinkId = "shavedice",
				score = 5,
			})
		end

		return unsub
	end)

	local visible, setVisible = useState(nil)
	useEffect(function()
		local unsub = UIState:subscribe(function(state)
			return state.panel
		end, function(panel)
			setVisible(panel == "none")
		end)
		setVisible(UIState:getState().panel == "none")
		return unsub
	end, {})

	local config = CoffeeModule.Config[cup and cup.drinkId]

	local prevCupRef = useRef(nil)
	useEffect(function()
		if cup then
			SoundController.Sound("cup")
		end
		if not cup and prevCupRef.current then
			SoundController.Sound("TrashcanToss")
			prevCupRef.current = cup
			print("trashed")
			return
		end

		local prevCupDrink = CoffeeModule.Config[prevCupRef.current and prevCupRef.current.drinkId]
		local newCupDrink = CoffeeModule.Config[cup and cup.drinkId]

		local prevIngredients = {}
		for i, ing in prevCupDrink and prevCupDrink.Ingredients or {} do
			prevIngredients[ing] = true
		end
		local newIng = nil
		for i, ing in newCupDrink and newCupDrink.Ingredients or {} do
			if not prevIngredients[ing] then
				newIng = ing
				break
			end
		end
		local newIngConfig = CoffeeModule.IngredientLookup[newIng]
		if not newIngConfig then
			prevCupRef.current = cup
			print("not newIngConfig", newIng)
			return
		end

		SoundController.Sound(getIngredientSound(newIngConfig.Id))

		print("yeah")
		prevCupRef.current = cup
	end, { cup })

	return e("Frame", {
		Transparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Visible = visible,
		LayoutOrder = props.LayoutOrder,
	}, {
		e(SmallText, {
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(0.5, 0, 1, -100),
			AnchorPoint = Vector2.new(0.5, 1),
			-- BackgroundTransparency = 0.4,

			Text = config
					and `<font size="{mdTextSize}">Drink in hand: {config and config.DisplayName or ""}\n${cup.score} ({statuses[cup.status]})</font>`
				or "",
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			RichText = true,
			MinTextSize = smTextSize,
			MaxTextSize = mdTextSize,
		}),
	})
end
