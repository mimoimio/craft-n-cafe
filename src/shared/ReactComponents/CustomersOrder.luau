-- shared/ReactComponents/CustomersOrder.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Types = require(ReplicatedStorage.Shared.Types)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local DispatchEvent = require(ReplicatedStorage.Shared.Controllers.DispatchEvent)
local Toasts = require(script.Parent.Toasts) -- Adjust path if Toasts.luau is located elsewhere

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState
local useSpring = ReactFlow.useSpring
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local useBreakpoint = require(ReplicatedStorage.Shared.Hooks.useBreakpoint)
local useToast = Toasts.useToast

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or "MockUser"

return function(props)
	local config, setConfig = useState(nil)
	local toast = useToast() -- Access your custom ToastContext!

	local xs, sm, md, lg, xl = useBreakpoint()
	local mobile = xs or sm or md

	local mdTextSize, smTextSize = mobile and 16 or 44, mobile and 10 or 12

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

		local t
		if not player then
			t = task.defer(function()
				while task.wait(1) do
					setConfig(function(prev)
						return not prev and CoffeeModule.Config.chocolatesyrup or nil
					end)
				end
			end)
		end

		return function()
			unsub()
			if t then
				task.cancel(t)
			end
		end
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

	local position, setPosition = useSpring({
		start = -1,
		target = -1,
		speed = 1,
		damper = 1,
	})

	useEffect(function()
		if config then
			setPosition({
				target = 0,
				speed = 10,
				damper = 0.8,
			})
			return
		end
		setPosition({
			target = -1,
			speed = 10,
			damper = 1,
		})
	end, { config })

	-- [[ Fire Toasts from DispatchEvent ]]
	useEffect(function()
		if not toast then
			return
		end -- Failsafe if context is missing

		local unsubTimeOut = DispatchEvent.OnEvent("timeOut", function(actPlayerId, payload)
			if actPlayerId == playerId then
				toast.open("Customer Left!", 3, Color3.new(1, 0.2, 0.2))
			end
		end)

		local unsubWrongOrder = DispatchEvent.OnEvent("wrongOrder", function(actPlayerId, payload)
			if actPlayerId == playerId then
				if payload.workerUid == "player" then
					toast.open("Wrong Order!", 3, Color3.new(1, 0.4, 0.4))
				else
					toast.open("Worker Gave Wrong Order!", 3, Color3.new(1, 0.4, 0.4))
				end
			end
		end)

		return function()
			unsubTimeOut()
			unsubWrongOrder()
		end
	end, { toast })

	return e("ImageLabel", {
		Transparency = 1,
		Visible = visible,
		Size = UDim2.new(0, mobile and 200 or 400, 0, mobile and 60 or 100),
		Image = "rbxassetid://82823552269615",
		ScaleType = Enum.ScaleType.Crop,
		Position = position:map(function(n)
			return UDim2.new(n, 0, 0, 30)
		end),
		ZIndex = -1,
	}, {
		config
				and e(SmallText, {
					Size = UDim2.new(1, 0, 1, 0),
					Text = `<font size="{smTextSize}">{config and `Customer order:` or ""}</font>\n<font size="{mdTextSize}">{config and config.DisplayName or ""}</font>\n<font size="{smTextSize}">{config and `({config.Instruction})` or ""}</font>`,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
					RichText = true,
					MinTextSize = smTextSize,
					MaxTextSize = mdTextSize,
				})
			or nil,
	})
end
