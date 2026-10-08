-- Shared/ReactComponents/Sidebar.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState
local RedDot = require(script.Parent.RedDot).RedDot

local VStack = require(script.Parent.ui.VStack)

local player = game:GetService("Players").LocalPlayer
local playerId = player and tostring(player.UserId) or "MockUser"
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
		OnMount = props.OnMount,
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
		}, props.children),
	})
end

--[[

The logics for the red dots.
Shop:
	conditions:
		1. An Item hasn't been seen by the player.
		

]]

function Sidebar(props)
	local level, setLevel = useState(nil)
	local TutorialCompleted, setTutorialCompleted = useState(nil)
	local panelCleared, setPanelCleared = useState(nil)
	useEffect(function()
		local unsub = UIState:subscribe(function(state: UIState.UIState)
			return state.panelCleared
		end, setPanelCleared)
		local state = UIState:getState()
		setPanelCleared(state.panelCleared)
		return unsub
	end, {})
	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Stats[playerId] and state.Stats[playerId].Level or nil
		end, function(level)
			setLevel(level)
		end)
		local state = GlobalState:getState()
		setLevel(state.Stats[playerId] and state.Stats[playerId].Level or nil)
		return unsub
	end, {})
	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Stats[playerId] and state.Stats[playerId].TutorialCompleted or nil
		end, setTutorialCompleted)
		local state = GlobalState:getState()
		setTutorialCompleted(state.Stats[playerId] and state.Stats[playerId].TutorialCompleted or nil)
		return unsub
	end, {})
	level = level or 0
	return e(VStack, {
		VerticalFlex = Enum.UIFlexAlignment.None,
		HorizontalFlex = Enum.UIFlexAlignment.None,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Spacing = UDim.new(0, 8),
	}, {

		ToggleShop = level > 2 and e(SidebarButton, {
			[React.Event.Activated] = function()
				UIState.toggle("shop")
			end,
			OnMount = function(rbx)
				UIState.setTutorialTarget("ShopButton", rbx)
			end, -- NEW
			Image = "rbxassetid://15403066964",
			Text = "Shop",
			LayoutOrder = 1,
		}, {
			panelCleared.shop == false and e(RedDot, {}, {}),
		}),
		ToggleIndex = level > 3 and e(SidebarButton, {
			[React.Event.Activated] = function()
				UIState.toggle("recipe")
			end,
			Image = "rbxassetid://127110909372919",
			Text = "Index",
			LayoutOrder = 2,
		}),
		ToggleBuild = level > 2 and e(SidebarButton, {
			OnMount = function(rbx)
				UIState.setTutorialTarget("BuildButton", rbx)
			end, -- NEW
			[React.Event.Activated] = function()
				UIState.toggle("build")
			end,
			Image = "rbxassetid://17368183719",
			Text = "Build",
			LayoutOrder = 3,
		}),
		-- Console = admin and e(SidebarButton, {
		-- 	[React.Event.Activated] = function()
		-- 		UIState.toggle("admin")
		-- 	end,
		-- 	Image = "rbxassetid://17368118782",
		-- 	Text = "Console",
		-- 	LayoutOrder = 4,
		-- }) or nil,
		Settings = TutorialCompleted and e(SidebarButton, {
			OnMount = UIState.setSettingsButton,
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
