local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)

local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""
local BonusHud = function(props)
	local playersDiscoveredDrinks, setDD = useState(nil)
	local bonus = 0

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			local dds = state.DiscoveredDrinks[playerId]
			if dds then
				setDD(dds)
			end
		end)
		local state = GlobalState:getState()
		local dds = state.DiscoveredDrinks[playerId]
		if dds then
			setDD(dds)
		end
		return unsub
	end, {})

	for variationId, drinksOfVariation in playersDiscoveredDrinks or {} do
		for drinkId, _ in drinksOfVariation do
			bonus += 1
		end
	end
	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	}, {
		e("UIPadding", {
			PaddingTop = UDim.new(0, 20),
			PaddingBottom = UDim.new(0, 20),
			PaddingLeft = UDim.new(0, 20),
			PaddingRight = UDim.new(0, 20),
		}),
		e(SmallText, {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, 0, 1, 0),
			Text = `Discovery Bonus: {(bonus * 5) // 1}%`,
		}),
	})
end
return BonusHud
