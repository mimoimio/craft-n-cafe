-- Shared/ReactComponents/Main.luau
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage.Packages.React)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local ShopCycle = require(ReplicatedStorage.Shared.ShopCycle)
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)

local e = React.createElement
local useState = React.useState
local useBinding = React.useBinding
local useEffect = React.useEffect

-- UIState actions

local CafeBase = require(script.Parent.CafeBase)
local CashOverlay = require(script.Parent.CashOverlay)
local VStack = require(script.Parent.ui.VStack)
local BuildPanel = require(script.Parent.BuildPanel)

local player = game:GetService("Players").LocalPlayer
local playerId = player and tostring(player.UserId) or ""
local admin = not player or playerId == "5470482596"

local function Main(props)
	return e("Frame", {
		Transparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
	}, {
		admin and e(require(script.Parent.ConsoleApp)),
		e(BuildPanel),
		e(require(script.Parent.CustomersOrder)),
		e(require(script.Parent.PlayersCup)),
		e(CashOverlay),
		e(Sidebar),
		e(CafeBase),
	})
end

function SidebarButton(props)
	return e(SmallButton, {
		Size = UDim2.fromOffset(160, 40),
		AutomaticSize = Enum.AutomaticSize.None,
		[React.Event.Activated] = props[React.Event.Activated],
	}, {
		e(VStack, {
			VerticalFlex = Enum.UIFlexAlignment.None,
			HorizontalFlex = Enum.UIFlexAlignment.None,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
		}, {
			e(SmallText, { Text = props.Text }),
		}),
	})
end

function Sidebar(props)
	return e(VStack, {
		VerticalFlex = Enum.UIFlexAlignment.None,
		HorizontalFlex = Enum.UIFlexAlignment.None,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
	}, {
		ToggleBuild = e(SidebarButton, {
			[React.Event.Activated] = function()
				UIState.toggle("build")
			end,
			Text = "Toggle Build",
		}),
		Console = e(SidebarButton, {
			[React.Event.Activated] = function()
				UIState.toggle("admin")
			end,
			Text = "Console",
		}),
	})
end

return Main
