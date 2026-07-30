-- Shared/ReactComponents/Tutorial.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local React = require(ReplicatedStorage.Packages.React)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Promise = require(ReplicatedStorage.Packages.Promise)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local e = React.createElement
local useEffect = React.useEffect
local useSpring = ReactFlow.useSpring
local Toasts = require(ReplicatedStorage.Shared.ReactComponents.Toasts)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local useToast = Toasts.useToast
local useState = React.useState
local useBinding = React.useBinding
local useCallback = React.useCallback
local useRef = React.useRef
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local SmallText = require(script.Parent.ui.SmallText)
local HStack = require(script.Parent.ui.HStack)
local VStack = require(script.Parent.ui.VStack)

return function()
	local visible, setVisible = useState(false)

	-- listen to panel
	useEffect(function()
		local unsub = UIState:subscribe(function(state: UIState.UIState)
			setVisible(state.panel == "rejectionletter")
		end)
		local panel = UIState:getState().panel
		if panel then
			setVisible(panel == "rejectionletter")
		end
		return unsub
	end, {})

	local position, setPosition = useSpring({
		start = -1,
		target = -1,
		speed = 1,
		damper = 1,
	})
	useEffect(function()
		if visible then
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
	end, { visible })
	return e("ImageLabel", {
		Image = "rbxassetid://127657596958436",
		-- Size = UDim2.new(1, -24, 0.5, -24),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(8, 8, 92, 92),
		-- AnchorPoint = Vector2.new(0.5, 0.5),
		-- Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 1,

		Size = UDim2.new(0.8, -48, 1, -48),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position:map(function(n)
			return UDim2.new(0.5 + n, 0, 0.5 + 0, 0)
		end),
	}, {
		UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
			AspectRatio = 16 / 9,
		}),
		UISizeConstraint = e("UISizeConstraint", {
			MinSize = Vector2.new(0, 350),
		}),
		VStack = e(VStack, {
			VerticalFlex = Enum.UIFlexAlignment.Fill,
			Padding = { All = UDim.new(0, 8) },
			Spacing = UDim.new(0, 8),
		}, {
			Title = e(SmallText, {
				Text = "WITCHCRAFT SCHOOL REJECTION LETTER",
				LayoutOrder = 1,
				TextColor3 = Color3.new(1, 0.1, 0.1),
				TextWrapped = true,
				TextSize = 30,
				TextStrokeTransparency = 1,
			}, {
				UIStroke = e("UIStroke", {
					Thickness = 1,
					Color = Color3.new(0.2, 0.2, 0.2),
				}),
			}),
			Separator = e("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				LayoutOrder = 2,
			}, {
				UIStroke = e("UIStroke", {
					Thickness = 1,
					Color = Color3.new(0.2, 0.2, 0.2),
				}),
			}),
			VStack = e(VStack, {
				VerticalFlex = Enum.UIFlexAlignment.SpaceBetween,
				Padding = { All = UDim.new(0, 8) },
				Size = UDim2.new(1, 0, 1, 0),
				Spacing = UDim.new(0, 8),
				LayoutOrder = 3,
			}, {
				Up = e(SmallText, {
					LayoutOrder = 2,
					Text = `Dear, {Players.LocalPlayer and Players.LocalPlayer.DisplayName or "Player"}\nYou're too poor, sorry. Maybe try apply again when you're rich`,
				}),
				Down = e(SmallText, {
					LayoutOrder = 3,
					Text = "Sincerely, Witchcraft School",
				}),
			}),
		}),
	})
end
