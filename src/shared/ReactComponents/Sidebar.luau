-- Shared/ReactComponents/Sidebar.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)

local e = React.createElement
local RedDot = require(script.Parent.RedDot).RedDot

local VStack = require(script.Parent.ui.VStack)

local player = game:GetService("Players").LocalPlayer
local playerId = player and tostring(player.UserId) or ""
local admin = not player or playerId == "5470482596"

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
		LayoutOrder = props.LayoutOrder,
	}, {

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
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(1, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1,
		}, {

			e(RedDot, {
				Position = UDim2.new(1, 0, 0, 8),
				SizeNum = 48,
			}),
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

		ToggleShop = e(SidebarButton, {
			[React.Event.Activated] = function()
				UIState.toggle("shop")
			end,
			Image = "rbxassetid://15403066964",
			Text = "Shop",
			LayoutOrder = 1,
		}),
		ToggleIndex = e(SidebarButton, {
			[React.Event.Activated] = function()
				UIState.toggle("recipe")
			end,
			Image = "rbxassetid://127110909372919",
			Text = "Index",
			LayoutOrder = 2,
		}),
		ToggleBuild = e(SidebarButton, {
			[React.Event.Activated] = function()
				UIState.toggle("build")
			end,

			Image = "rbxassetid://17368183719",
			Text = "Build",
			LayoutOrder = 3,
		}),
		Console = admin and e(SidebarButton, {
			[React.Event.Activated] = function()
				UIState.toggle("admin")
			end,
			Image = "rbxassetid://17368118782",
			Text = "Console",
			LayoutOrder = 4,
		}) or nil,
		Settings = e(SidebarButton, {
			[React.Event.Activated] = function()
				UIState.toggle("settings")
			end,
			Image = "rbxassetid://17368089841",
			Text = "Settings",
			LayoutOrder = 5,
		}),
	})
end

return Sidebar
