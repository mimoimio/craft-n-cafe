-- Shared/ReactComponents/CustomersPanel.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local DefaultPanel = require(script.Parent.DefaultPanel)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)

local function CustomersPanel(props: {
	Open: boolean,
	OnClose: () -> (),
})
	local playerId = tostring(Players.LocalPlayer and Players.LocalPlayer.UserId or "")
	local customersState, setCustomersState =
		React.useState({ { id = "huh", customerId = "", drinkIds = { "son", "sonion" } } })

	-- Sync locally with the player's Customers state slice
	React.useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Customers[playerId]
		end, function(newCustomersState)
			setCustomersState(newCustomersState or {})
		end)

		-- Initial fetch
		local state = GlobalState:getState()
		if state.Customers and state.Customers[playerId] then
			setCustomersState(state.Customers[playerId])
		end

		return unsub
	end, { playerId })

	local customerElements = {}

	-- Build out the list of current customers
	for i, customerData in pairs(customersState) do
		local uid = customerData.id
		local status = "Waiting..."

		-- Give a quick visual status if they've successfully grabbed drinks from the tables
		if customerData.drinkIds and #customerData.drinkIds > 0 then
			status = "Items: " .. tostring(#customerData.drinkIds)
		end

		table.insert(
			customerElements,
			e(HStack, {
				Size = UDim2.new(1, 0, 0, 50),
				HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween,
				VerticalFlex = Enum.UIFlexAlignment.Fill,
				key = uid,
			}, {
				Info = e(SmallText, {
					Text = string.format("Cust [%s] - %s", string.sub(uid, 1, 4), status),
					Size = UDim2.new(0.6, 0, 1, 0),
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
				}),
				TendBtn = e(SmallButton, {
					Text = "Tend",
					Size = UDim2.new(0, 100, 0, 40),
					[React.Event.Activated] = function()
						-- Fire to server with the specific customer uid to tend them
						Remotes.TendCustomer:FireServer(uid)
					end,
				}),
			})
		)
	end

	-- Display empty state if no customers are spawned
	if #customerElements == 0 then
		table.insert(
			customerElements,
			e(SmallText, {
				Text = "No customers waiting.",
				Size = UDim2.new(1, 0, 0, 40),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				key = "empty",
			})
		)
	end

	return e(DefaultPanel, {
		Title = "Active Customers",
		Size = UDim2.new(0, 400, 0, 500),
		OnClose = props.OnClose,
		Open = props.Open,
	}, {
		Content = e(VStack, {
			VerticalFlex = Enum.UIFlexAlignment.None,
			Spacing = UDim.new(0, 10),
		}, customerElements),
	})
end

return CustomersPanel
