-- Shared/ReactComponents/ShopPanel.luau
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Mionum = require(ReplicatedStorage.Packages.Mionum)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local Reflex = require(ReplicatedStorage.Packages.Reflex)

local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)
local PlotExpansionsConfig = require(ReplicatedStorage.Shared.Configs.PlotExpansionsConfig)
local WorkersConfig = require(ReplicatedStorage.Shared.Configs.WorkersConfig)
local UpgradesConfig = require(ReplicatedStorage.Shared.Configs.UpgradesConfig)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)

local e = React.createElement
local useState = React.useState
local useRef = React.useRef
local useBinding = React.useBinding
local useEffect = React.useEffect
local useSpring = ReactFlow.useSpring
local BuildersIcon = require(script.Parent.Parent.Parent.Utils.BuildersIcon)

local DOWN_ICON = BuildersIcon["chevron-large-down"]
local function Padding(props: { All: UDim })
	local All = props.All or UDim.new(0, 4)
	return e("UIPadding", { PaddingTop = All, PaddingBottom = All, PaddingLeft = All, PaddingRight = All })
end

local playerId = Players.LocalPlayer and tostring(Players.LocalPlayer.UserId) or "MockUser"

--[[
TODO: use images for buttons and cards
]]

local function WorkerManagementCard(props: {
	worker: Types.WorkerEntity,
	index: number,
	playerCash: number,
	Visible: boolean,
	LayoutOrder: number,
})
	local worker = props.worker
	local statKeys: { Types.WorkerStatType } = { "walkSpeed", "craftSpeed", "quality" }
	local statButtons = {}

	for idx, statKey in ipairs(statKeys) do
		local statCfg = WorkersConfig.StatUpgrades[statKey]
		local currentLevel = if statKey == "walkSpeed"
			then (worker.walkSpeedLevel or 1)
			elseif statKey == "craftSpeed" then (worker.craftSpeedLevel or 1)
			else (worker.qualityLevel or 1)

		local maxLevel = #statCfg.Levels
		local currentVal = statCfg.Levels[math.clamp(currentLevel, 1, maxLevel)].Value
		local _, nextEntry = WorkersConfig.GetNextUpgrade(statKey, currentLevel)

		local isMaxed = nextEntry == nil
		local canAfford = nextEntry and (props.playerCash >= nextEntry.Cost) or false

		local btnColor = Color3.new(0.2, 0.65, 0.3)
		local btnLabel = ""

		if isMaxed then
			btnColor = Color3.new(0.35, 0.35, 0.35)
			btnLabel = `<b>{statCfg.DisplayName}</b> (MAX)\n<font size="12">{statCfg.FormatValue(currentVal)}</font>`
		else
			if not canAfford then
				btnColor = Color3.new(0.65, 0.25, 0.25)
			end
			btnLabel =
				`<b>{statCfg.DisplayName}</b> Lvl {currentLevel}/{maxLevel}\n<font size="12">{statCfg.FormatValue(
					currentVal
				)} ➔ {statCfg.FormatValue(nextEntry.Value)} (${nextEntry.Cost})</font>`
		end

		statButtons[statKey] = e(SmallButton, {
			LayoutOrder = idx,
			Size = UDim2.new(1, 0, 0, 48),
			AutomaticSize = Enum.AutomaticSize.None,
			BackgroundColor3 = btnColor,
			[React.Event.Activated] = function()
				if not isMaxed and canAfford and Remotes.UpgradeWorker then
					Remotes.UpgradeWorker:FireServer({
						workerUid = worker.id,
						statType = statKey,
					})
				end
			end,
		}, {
			e(SmallText, {
				Text = btnLabel,
				RichText = true,
				Size = UDim2.new(1, 0, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
		})
	end

	return e("Frame", {
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.new(0.18, 0.18, 0.22),
		BackgroundTransparency = 0.15,
		Visible = props.Visible,
		LayoutOrder = props.LayoutOrder,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
		Stroke = e("UIStroke", { Thickness = 2, Color = Color3.new(0.4, 0.6, 0.9) }),
		Content = e(VStack, {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Padding = { All = UDim.new(0, 8) },
			Spacing = UDim.new(0, 6),
		}, {
			Header = e(SmallText, {
				LayoutOrder = 0,
				-- Text = `<b>{worker.name or ("Barista #" .. props.index)}</b> <font size="12" color="rgb(180,220,255)">({worker.action})</font>`,
				Text = `{worker.name or ("Barista #" .. props.index)}`,
				RichText = true,
				Size = UDim2.new(1, 0, 0, 24),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			StatsList = e(VStack, {
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Spacing = UDim.new(0, 4),
			}, statButtons),
		}),
	})
end

return WorkerManagementCard
