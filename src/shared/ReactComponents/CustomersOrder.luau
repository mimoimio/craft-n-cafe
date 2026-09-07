local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Types = require(ReplicatedStorage.Shared.Types)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local e = React.createElement
local createSelector = Reflex.createSelector
local useEffect = React.useEffect
local useState = React.useState
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local useBreakpoint = require(ReplicatedStorage.Shared.Hooks.useBreakpoint)

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""

return function(props)
	local config, setConfig = useState(nil)

	local xs, sm, md, lg, xl = useBreakpoint()
	local mobile = xs or sm or md

	local mdTextSize, smTextSize = mobile and 16 or 44, mobile and 10 or 12
	print(`mobile {mobile}`)
	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Customers[playerId]
		end, function(playersCustomers)
			if not (playersCustomers and type(playersCustomers) == "table") then
				return
			end

			for i, customer: Types.CustomerEntity in playersCustomers do
				if customer.servedBy == "player" then
					local config = CoffeeModule.Config[customer.order]
					setConfig(config)
					return
				end
			end
			setConfig(nil)
		end)
		local state = GlobalState:getState()
		local playersCustomers = state.Customers[playerId]
		if playersCustomers and type(playersCustomers) == "table" then
			for i, customer: Types.CustomerEntity in playersCustomers do
				if customer.servedBy == "player" then
					local config = CoffeeModule.Config[customer.order]
					setConfig(config)
				end
			end
		end

		if not player then
			setConfig(CoffeeModule.Config.frappuccino)
		end

		return unsub
	end)
	return e("Frame", {
		Transparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
	}, {
		e(SmallText, {
			Size = UDim2.new(1, 0, 1, 0),
			Text = `<font size="{mdTextSize}">{config and config.DisplayName or ""}</font>\n<font size="{smTextSize}">{config and `({table.concat(
				config.RecipePath,
				", "
			)})` or ""}</font>`,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			RichText = true,
			MinTextSize = smTextSize,
			MaxTextSize = mdTextSize,
		}),
	})
end
