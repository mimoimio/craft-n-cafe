-- Shared/ReactComponents/WarningsOverlay.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Reflex = require(ReplicatedStorage.Packages.Reflex)

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useBinding = React.useBinding

local playerId = Players.LocalPlayer and tostring(Players.LocalPlayer.UserId) or "MockUser"

local function WarningsOverlay()
	local plotState, setPlotState = useState(nil)
	local time, setTime = useBinding(workspace:GetServerTimeNow())

	-- 1. Observe the Plot
	useEffect(function()
		local unsub = GlobalState:subscribe(function(state)
			return state.Plot and state.Plot[playerId] or nil
		end, setPlotState)

		setPlotState(GlobalState:getState().Plot and GlobalState:getState().Plot[playerId] or nil)
		return unsub
	end, {})

	-- Bouncy animation loop for the warning
	useEffect(function()
		local running = true
		local t = task.spawn(function()
			while running do
				task.wait()
				setTime(workspace:GetServerTimeNow())
			end
		end)
		return function()
			running = false
			task.cancel(t)
		end
	end, {})

	-- 2. Check for Requirements
	local hasCashier = false
	if plotState then
		for _, item in pairs(plotState.placedItems or {}) do
			local config = PlaceablesModule.GetConfig(item.id)
			if config and config.Category == "Cashier" then
				hasCashier = true
				break
			end
		end
		if not hasCashier then
			for _, item in pairs(plotState.spatialItems or {}) do
				local config = PlaceablesModule.GetConfig(item.id)
				if config and config.Category == "Cashier" then
					hasCashier = true
					break
				end
			end
		end
	end

	-- 3. If everything is fine, render nothing!
	if hasCashier or not plotState then
		return nil
	end

	-- 4. If missing, render the pulsing warning banner
	return e("ScreenGui", {
		DisplayOrder = 100, -- Keeps it below menus but above normal HUD
	}, {
		Banner = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = time:map(function(t)
				-- Gentle vertical pulse
				return UDim2.new(0.5, 0, 0, 10 + math.sin(t * 3) * 5)
			end),
			Size = UDim2.new(0, 350, 0, 50),
			BackgroundColor3 = Color3.new(0.8, 0.2, 0.2), -- Warning Red
			BackgroundTransparency = 0.2,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			Stroke = e("UIStroke", {
				Color = Color3.new(1, 0.5, 0.5),
				Thickness = 2,
			}),
			Text = e(SmallText, {
				Text = "⚠️ <b>Warning:</b> You must place a <b>Cash Register</b> to open your cafe!",
				RichText = true,
				Size = UDim2.new(1, 0, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			})
		})
	})
end

return WarningsOverlay