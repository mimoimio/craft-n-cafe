local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Mionum = require(ReplicatedStorage.Packages.Mionum)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local Types = require(ReplicatedStorage.Shared.Types)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local DrinkValue = require(ReplicatedStorage.Shared.Utils.DrinkValue)
local e = React.createElement
local createSelector = Reflex.createSelector
local useEffect = React.useEffect
local useState = React.useState
local useRef = React.useRef
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local scoregui = require(ReplicatedStorage.Shared.ReactComponents.scoregui)
local HStack = require(ReplicatedStorage.Shared.ReactComponents.ui.HStack)
local useBreakpoint = require(ReplicatedStorage.Shared.Hooks.useBreakpoint)

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or "MockUser"

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

	local mdTextSize, smTextSize = mobile and 16 or 32, mobile and 10 or 12
	local cup: Types.CupEntity?, setCup: (cup: Types.CupEntity) -> nil = useState(nil)
	local stats, setStats = useState(nil)
	local cupInstance, setCupInstance = useState(nil)

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			local cup = state.Cups[playerId] and state.Cups[playerId].player or nil
			return cup
		end, setCup)

		local state = GlobalState:getState()
		local playersCup = state.Cups[playerId] and state.Cups[playerId].player
		setCup(playersCup)

		if not player then
			setCup({
				drinkId = "shavedice",
				score = 3,
				status = 3,
			})
		end

		return unsub
	end, {})

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Stats[playerId]
		end, setStats)

		setStats(GlobalState:getState().Stats[playerId])
		return unsub
	end, {})

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
	useEffect(function()
		local id = playerId .. "Cup"
		local conn = CollectionService:GetInstanceAddedSignal(id):Connect(function()
			local tagged = CollectionService:GetTagged(id)
			setCupInstance(tagged[1])
		end)
		local tagged = CollectionService:GetTagged(id)
		setCupInstance(tagged[1])
		return function()
			conn:Disconnect()
			setCupInstance(nil)
		end
	end, {})

	local config = CoffeeModule.Config[cup and cup.drinkId]
	local drinkValue = DrinkValue.Calculate(cup, stats and stats.Upgrades, stats and stats.OwnedGamePasses)
	local qualityText = cup and cup.status and statuses[cup.status] or ""

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

		SoundController.Sound(getIngredientSound(newIngConfig.Id), {
			PlaybackSpeed = math.random() * 0.2 + 0.9,
		})

		prevCupRef.current = cup
	end, { cup })


	return e("Frame", {
		Transparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Visible = visible,
		LayoutOrder = props.LayoutOrder,
	}, {
		Text =e(SmallText, {
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(1, -40, 0, 40),
			AnchorPoint = Vector2.new(1, 0),
			-- BackgroundTransparency = 0.4,

			Text = config and `<font size="{mdTextSize}">Drink in hand: {config.DisplayName}\n${Mionum.new(
				drinkValue.Cash
			)
				:toString()} {qualityText ~= "" and `({qualityText})` or ""}</font>` or "",
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Top,
			RichText = true,
			MinTextSize = smTextSize,
			MaxTextSize = mdTextSize,
		}),
		bbgui = cupInstance and cupInstance.Parent and (cupInstance.PrimaryPart or cupInstance:FindFirstChildWhichIsA("BasePart")) and e("BillboardGui", {
				Adornee = cupInstance and cupInstance.Parent and (cupInstance.PrimaryPart or cupInstance:FindFirstChildWhichIsA("BasePart")) or nil,
				Size = UDim2.fromScale(3.5, 1),
				ExtentsOffsetWorldSpace = Vector3.new(0, 0, 0),
				AlwaysOnTop = true,
				ref = function() end,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			}, {
				scoregui = e(scoregui, {
					cup = cup,
				}),
			}) or nil,
		-- portal = (cup and cup.status and cupInstance and cupInstance.Parent) and ReactRoblox.createPortal({
		-- --[[
		-- currently just player's cup, later add
		-- workers cups
		-- ]]
		-- 	bbgui = e("BillboardGui", {
		-- 		Adornee = cupInstance and cupInstance.Parent and cupInstance.PrimaryPart or nil,
		-- 		Size = UDim2.fromScale(3.5, 1),
		-- 		ExtentsOffsetWorldSpace = Vector3.new(0, 0, 0),
		-- 		AlwaysOnTop = true,
		-- 		ref = function() end,
		-- 		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		-- 	}, {
		-- 		scoregui = e(scoregui, {
		-- 			cup = cup,
		-- 		}),
		-- 	}),
		-- }, cupInstance) or nil,
	})
end
