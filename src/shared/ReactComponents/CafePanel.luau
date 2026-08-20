local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Mionum = require(ReplicatedStorage.Packages.Mionum)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local useSpring = ReactFlow.useSpring

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local DefaultPanel = require(ReplicatedStorage.Shared.ReactComponents.DefaultPanel)
local VStack = require(ReplicatedStorage.Shared.ReactComponents.ui.VStack)

local player = game:GetService("Players").LocalPlayer
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
	local nextIngredients, nextNumOfTables, nextNumOfMixers
	local position, setPosition = useSpring({
		start = -1,
		target = -1,
		speed = 1,
		damper = 1,
	})

	useEffect(function()
		if panelOpen then
			setPosition({
				target = 0,
				speed = 30,
				damper = 0.6,
			})
		else
			setPosition({
				target = -1,
				speed = 30,
				damper = 0.6,
			})
		end
	end, { panelOpen })

	return e(DefaultPanel, {
		Title = "Cafe",
		Size = UDim2.new(0.5, 0, 1, 0),
		-- MinSize = Vector2.new(500, 320),
		MaxSize = Vector2.new(500, 500),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position:map(function(n)
			return UDim2.new(0.5 - n, 0, 0.5, 0)
		end),
		OnClose = props.OnClose,
		BackgroundImageTransparency = 0,

		-- Open = panelOpen,
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
		}),
	})
end

return CafePanel
