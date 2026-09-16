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

local CafeBase = require(script.Parent.CafeBase)
local CashOverlay = require(script.Parent.CashOverlay)
local VStack = require(script.Parent.ui.VStack)
local BuildPanel = require(script.Parent.BuildPanel)
local ShopPanel = require(script.Parent.ShopPanel) -- NEW: Require the Shop

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
		e(ShopPanel), -- NEW: Mount the Shop Panel
		e(require(script.Parent.CustomersOrder)),
		e(require(script.Parent.CustomerPrompts)),
		e(require(script.Parent.StationPrompts)),
		e(require(script.Parent.PlayersCup)),
		e(CashOverlay),
		e(Sidebar),
		e(CafeBase),
	})
end

function SidebarButton(props)
	local useBreakpoint = require(ReplicatedStorage.Shared.Hooks.useBreakpoint)

	local xs, sm, md, lg, xl = useBreakpoint()
	local mobile = xs or sm or md
	local BUTTONHEIGHT = mobile and 38 or 50
	local BUTTONWIDTH = mobile and 60 or 100
	local TEXTSIZE = mobile and 12 or 18
	return e(SmallButton, {
		Size = UDim2.fromOffset(BUTTONWIDTH, BUTTONHEIGHT),
		AutomaticSize = Enum.AutomaticSize.None,
		[React.Event.Activated] = props[React.Event.Activated],
		Padding = { All = UDim.new(0, 0) },
	}, {
		-- e(VStack, {
		-- 	VerticalFlex = Enum.UIFlexAlignment.None,
		-- 	HorizontalFlex = Enum.UIFlexAlignment.None,
		-- 	VerticalAlignment = Enum.VerticalAlignment.Center,
		-- 	HorizontalAlignment = Enum.HorizontalAlignment.Left,
		-- 	ZIndex = 2,
		-- 	Size = UDim2.fromScale(1, 1),
		-- }, {
		-- }),

		e(SmallText, {
			TextSize = TEXTSIZE,
			Text = props.Text,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.new(0.5, 0, 1, 0),
			AnchorPoint = Vector2.new(0.5, 0.9),
			ZIndex = 2,
		}),
		e("ImageLabel", {
			ZIndex = 1,
			Image = props.Image,
			-- Size = UDim2.new(0, BUTTONHEIGHT, 0, BUTTONHEIGHT),
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			-- Transparency = 1,
		}),
	})
end

function Sidebar(props)
	return e(VStack, {
		VerticalFlex = Enum.UIFlexAlignment.None,
		HorizontalFlex = Enum.UIFlexAlignment.None,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Spacing = UDim.new(0, 8),
	}, {
		ToggleShop = e(SidebarButton, { -- NEW: Shop Toggle Button
			[React.Event.Activated] = function()
				UIState.toggle("shop")
			end,
			Image = "rbxassetid://15403066964",
			Text = "Shop",
		}),
		ToggleBuild = e(SidebarButton, {
			[React.Event.Activated] = function()
				UIState.toggle("build")
			end,
			Image = "rbxassetid://17368217589",
			Text = "Build",
		}),
		Console = admin and e(SidebarButton, { -- Optional: Hide console button if not admin
			[React.Event.Activated] = function()
				UIState.toggle("admin")
			end,
			Image = "rbxassetid://17368118782",
			Text = "Console",
		}) or nil,
	})
end

return Main
