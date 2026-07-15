local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Mionum = require(ReplicatedStorage.Packages.Mionum)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef

local SmallButton = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallButton)
local HStack = require(ReplicatedStorage.Shared.ReactComponents.ui.HStack)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local DefaultPanel = require(ReplicatedStorage.Shared.ReactComponents.DefaultPanel)
local VStack = require(ReplicatedStorage.Shared.ReactComponents.ui.VStack)
local LevelConfig = require(ReplicatedStorage.Shared.Configs.LevelConfig)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)

local ICON =
	[[<font family="rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json"><b>robux</b></font>]]

local player = game.Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""
local function CafePanel(props: {})
	--listen to active panel
	local panelOpen, setPanelOpen = useState((not player) or false)
	useEffect(function()
		local unsub = UIState:subscribe(function(state: UIState.UIState)
			setPanelOpen(state.panel == "cafe")
		end)
		return unsub
	end, {})

	local stats, setStats = useState((not player) and {
		Sfx = 0.5,
		Music = 0.5,
		SecondsPlayed = 0,
		Cash = 100,
		Level = 4,
		CafeOpen = false,
	} or nil)

	-- listen to player's stats
	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Stats[playerId]
		end, function(playersStats)
			setStats(playersStats)
		end)
		local state = GlobalState:getState()
		local playersStats = state.Stats[playerId]
		if playersStats then
			setStats(playersStats)
		end
		return unsub
	end, {})

	local nextLevel = stats and (stats.Level + 1)
	local config = LevelConfig[nextLevel]
	local nextIngredients, nextNumOfTables, nextNumOfMixers
	if config then
		local texts = {}
		local count = 1
		for i, id in config.NewIngredients do
			local cofeeg = CoffeeModule.IngredientLookup[id]
			table.insert(texts, `{count}. {cofeeg and cofeeg.DisplayName}`)
			count += 1
		end
		nextIngredients = table.concat(texts, "\n")

		local mixers = config.Mixers
		if type(mixers) == "table" and #mixers >= 1 then
			nextNumOfMixers = #mixers
		end
		local tables = config.Tables
		if type(tables) == "table" and #tables >= 1 then
			nextNumOfTables = #tables
		end
	end

	return e(DefaultPanel, {
		Title = "Cafe",
		Size = UDim2.new(0.5, 0, 1, 0),
		-- MinSize = Vector2.new(500, 320),
		MaxSize = Vector2.new(500, 500),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		OnClose = props.OnClose,
		BackgroundImageTransparency = 0,
		Open = panelOpen,
	}, {
		Grid = e(VStack, {
			-- CellSize = UDim2.new(1, -20, 0, 150),
			Spacing = UDim.new(0, 4),
			Size = UDim2.new(1, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			VerticalFlex = Enum.UIFlexAlignment.Fill,
		}, {

			e(VStack, {
				Size = UDim2.new(1, 0, 1, 0),
				VerticalFlex = Enum.UIFlexAlignment.None,
				BackgroundTransparency = 1,
			}, {
				e(SmallText, {
					Text = `Next Cafe Level: {nextLevel}`,
					TextSize = 30,
				}),
				e(SmallText, {
					Text = `<font size="10">Ingredients Unlocked Next Level:</font>\n{nextIngredients or ". . ."}`,
					TextSize = 18,
					RichText = true,
					MinTextSize = 14,
				}),
				e(SmallText, {
					Text = `Unlock {nextNumOfMixers and `+{nextNumOfMixers} mixers` or ""}{nextNumOfMixers and nextNumOfTables and " and " or ""}{nextNumOfTables and `+{nextNumOfTables} tables`}! `,
					TextSize = 18,
				}),
			}),
			LevelUp = e(SmallButton, {
				Text = `Level Up: {ICON}{config and config.Cost and Mionum.new(config.Cost):toString()}`,
				RichText = true,
				[React.Event.Activated] = function()
					Remotes.LevelUp:FireServer()
				end,
			}),
		}),
	})
	-- return e(VStack, {
	-- 	Size = UDim2.new(1, -80, 1, -80),
	-- 	Visible = panelOpen,
	-- 	AnchorPoint = Vector2.new(0.5, 0.5),
	-- 	Position = UDim2.fromScale(0.5, 0.5),

	-- 	VerticalFlex = Enum.UIFlexAlignment.Fill,
	-- 	BackgroundTransparency = 1,
	-- }, {
	-- 	UISizeConstraint = e("UISizeConstraint", {
	-- 		MinSize = Vector2.new(300, 200),
	-- 		MaxSize = Vector2.new(400, 400),
	-- 	}),
	-- 	e(VStack, {
	-- 		Size = UDim2.new(1, 0, 1, 0),
	-- 		VerticalFlex = Enum.UIFlexAlignment.None,
	-- 		BackgroundTransparency = 1,
	-- 	}, {
	-- 		e(SmallButton, {
	-- 			Text = `Next Cafe Level: {nextLevel}`,
	-- 			TextSize = 30,
	-- 		}),
	-- 		e(SmallButton, {
	-- 			Text = `<font size="10">Ingredients Unlocked Next Level:</font>\n{nextIngredients or ". . ."}`,
	-- 			TextSize = 18,
	-- 			RichText = true,
	-- 			MinTextSize = 14,
	-- 		}),
	-- 		e(SmallButton, {
	-- 			Text = `Unlock {nextNumOfMixers and `+{nextNumOfMixers} mixers` or ""}{nextNumOfMixers and nextNumOfTables and " and " or ""}{nextNumOfTables and `+{nextNumOfTables} tables`}! `,
	-- 			TextSize = 18,
	-- 		}),
	-- 	}),
	-- 	LevelUp = e(SmallButton, {
	-- 		Text = `Level Up: {ICON}{config and config.Cost and Mionum.new(config.Cost):toString()}`,
	-- 		RichText = true,
	-- 		[React.Event.Activated] = function()
	-- 			Remotes.LevelUp:FireServer()
	-- 		end,
	-- 	}),
	-- })
end

return CafePanel
