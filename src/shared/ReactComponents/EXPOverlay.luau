local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoinVFXContainer = require(ReplicatedStorage.Shared.ReactComponents.CoinVFXContainer)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local Mionum = require(ReplicatedStorage.Packages.Mionum)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local SmallText = require(Primitives.SmallText)
local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or "MockUser"
local useBreakpoint = require(ReplicatedStorage.Shared.Hooks.useBreakpoint)
local LevelConfig = require(ReplicatedStorage.Shared.Configs.LevelConfig)
local function EXPHud(props: {
	EXP: number,
})
	local xs, sm, md, lg, xl = useBreakpoint()
	local mobile = xs or sm or md
	local exp = props.EXP
	local level = exp and LevelConfig.GetLevel(exp) or nil
	local levelsLowerBoundExp = exp and LevelConfig.GetExpOnLevel(level - 1) or nil
	local percent = exp and (exp - levelsLowerBoundExp) / (LevelConfig.GetExpOnLevel(level) - levelsLowerBoundExp)
		or nil
	local textSize = mobile and 24 or 32
	local height = mobile and 30 or 50
	local width = mobile and 120 or 200
	-- warn(`level ({level}) levelsLowerBoundExp ({levelsLowerBoundExp}) percent ({percent})`)
	return e("Frame", {
		AutomaticSize = Enum.AutomaticSize.XY,
		Position = UDim2.new(0, 0, 0, 0),
		AnchorPoint = Vector2.new(0, 0),
		BackgroundTransparency = 1,
		ZIndex = -1,
	}, {
		-- Stacks the Text and the Toasts Container
		layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 5),
		}),

		text = e("ImageLabel", {
			Size = UDim2.new(0, width, 0, height),
			BackgroundTransparency = 1,
			Image = "rbxassetid://103478691850846",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(8, 8, 92, 92),
		}, {
			e("ImageLabel", {
				Size = UDim2.new(percent or 1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = "rbxassetid://103478691850846",
				ImageColor3 = Color3.new(0.2, 0.6, 1),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(8, 8, 92, 92),
				ZIndex = 0,
			}, {}),
			e("ImageLabel", {
				ZIndex = 1,
				Image = "rbxassetid://15402964203",
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromOffset(height - 8, height - 8),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				BackgroundTransparency = 1,
			}),
			e(SmallText, {
				-- Text = (
				-- 	([[<font family="rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json">%s</font>]]):format(
				-- 		COINICON
				-- 	) .. [[%s]]
				-- ):format(coins or 0),
				Text = "Level " .. Mionum.new(exp and level or 0):toString(),
				RichText = true,
				TextSize = textSize,
				TextColor3 = Color3.new(1, 1, 1),
				Size = UDim2.new(0, width, 0, height),
				AutomaticSize = Enum.AutomaticSize.None,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Top,
				LayoutOrder = 1, -- Force it to stay on top
			}, {}),
		}),
	})
end
local function EXPOverlay(props)
	local exp, setEXP = useState(nil)
	useEffect(function()
		local unsub = GlobalState:subscribe(function(newState: GlobalState.GlobalState)
			local playersStats = newState.Stats[playerId]
			if playersStats and playersStats.EXP then
				setEXP(playersStats.EXP)
			end
		end)
		local newState = GlobalState:getState()
		local playersStats = newState.Stats[playerId]
		if playersStats and playersStats.EXP then
			setEXP(playersStats.EXP)
		end
		local t
		if not player then
			t = task.defer(function()
				while task.wait(0.1) do
					setEXP(function(prev)
						return prev + 1
					end)
				end
			end)
		end
		return function()
			unsub()
			task.cancel(t)
		end
	end, {})

	return e("Frame", {
		Transparency = 1,
		Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		LayoutOrder = 2,
	}, {
		EXP = e(EXPHud, {
			EXP = exp,
		}),
	})
end

return EXPOverlay
