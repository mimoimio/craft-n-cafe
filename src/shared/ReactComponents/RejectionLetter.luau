-- Shared/ReactComponents/Tutorial.luau
local GuiService = game:GetService("GuiService")
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

local function setFocus(rbx)
	if rbx and rbx.Parent and rbx.Visible then
		GuiService.SelectedObject = rbx
		return
	end
	GuiService.SelectedObject = nil
end

local function ScreenGuiCircle(props: { TargetButton: GuiButton?, Color: Color3? })
	local time, setTime = useBinding(workspace:GetServerTimeNow())

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

	local sizeMap = useCallback(function(t)
		local pulse = math.sin(t * 5) * 5
		return UDim2.fromOffset(60 + pulse, 60 + pulse)
	end, {})

	local posMap = useCallback(function(t)
		if not props.TargetButton then
			return UDim2.new()
		end
		local center = props.TargetButton.AbsolutePosition + (props.TargetButton.AbsoluteSize / 2)
		return UDim2.fromOffset(center.X, center.Y)
	end, { props.TargetButton })

	if not props.TargetButton then
		return nil
	end

	return e("ScreenGui", {
		DisplayOrder = 1010,
	}, {
		Wrapper = e("Frame", {
			BackgroundTransparency = 1,
			Position = time:map(posMap),
			Size = UDim2.fromOffset(60, 60),
			AnchorPoint = Vector2.new(0.5, 0.5),
		}, {
			Circle = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = time:map(sizeMap),
				BackgroundColor3 = props.Color or Color3.new(1, 1, 1),
				BackgroundTransparency = 0.8,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Stroke = e("UIStroke", {
					Color = props.Color or Color3.new(1, 1, 1),
					Thickness = 3,
				}),
			}),
		}),
	})
end

return function()
	local visible, setVisible = useState(false)

	local time, setTime = useBinding(workspace:GetServerTimeNow())

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

	local sizeMap = useCallback(function(t)
		local pulse = math.sin(t * 10) * 10
		return UDim2.fromOffset(60 + pulse, 60 + pulse)
	end, {})

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
		ZIndex = 100,
	}, {
		UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
			AspectRatio = 16 / 9,
		}),
		UISizeConstraint = e("UISizeConstraint", {
			MinSize = Vector2.new(0, 350),
			MaxSize = Vector2.new(1000, 400),
		}),
		CloseBtn = e("TextButton", {
			Size = UDim2.new(0, 32, 0, 32),
			Position = UDim2.new(1, 0, 0, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(80, 40, 40),
			BorderSizePixel = 0,
			Text = "X",
			ref = setFocus,
			TextColor3 = Color3.fromRGB(255, 120, 120),
			TextSize = 16,
			Font = Enum.Font.FredokaOne,
			[React.Event.MouseButton1Click] = function()
				UIState.toggle("none")
			end,
			ZIndex = 5,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Wrapper = e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.fromOffset(60, 60),
				AnchorPoint = Vector2.new(0.5, 0.5),
			}, {
				Circle = e("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = time:map(sizeMap),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 0.8,
				}, {
					Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
					Stroke = e("UIStroke", {
						Color = Color3.new(1, 1, 1),
						Thickness = 3,
					}),
				}),
			}),
		}),
		VStack = e(VStack, {
			VerticalFlex = Enum.UIFlexAlignment.Fill,
			Padding = { All = UDim.new(0, 24) },
			Spacing = UDim.new(0, 24),
		}, {
			UIStroke = e("UIStroke", {
				Thickness = 2,
			}),
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			Title = e(SmallText, {
				Text = "WITCHCRAFT SCHOOL REJECTION LETTER",
				LayoutOrder = 1,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextColor3 = Color3.new(1, 0.1, 0.1),
				TextWrapped = true,
				TextSize = 30,
				TextStrokeTransparency = 1,
			}, {
				UIStroke = e("UIStroke", {
					Thickness = 2,
					-- Color = Color3.new(0.2, 0.2, 0.2),
				}),
			}),
			Separator = e("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				LayoutOrder = 2,
			}, {
				UIStroke = e("UIStroke", {
					Thickness = 1,
					-- Color = Color3.new(0.2, 0.2, 0.2),
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
					Text = `Dear, {Players.LocalPlayer and Players.LocalPlayer.DisplayName or "Player"}\nYou're too poor, sorry. Maybe try apply again when you're rich. Like at least $100,000 rich.`,
					TextWrapped = true,
				}, {
					UIStroke = e("UIStroke", {
						Thickness = 2,
					}),
				}),
				Down = e(SmallText, {
					LayoutOrder = 3,
					Text = "Sincerely, Witchcraft School",
					TextWrapped = true,
				}, {
					UIStroke = e("UIStroke", {
						Thickness = 2,
					}),
				}),
			}),
		}),
	})
end
