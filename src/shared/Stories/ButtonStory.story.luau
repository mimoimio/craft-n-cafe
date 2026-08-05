local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local React = require(ReplicatedStorage.Packages.React)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local e = React.createElement
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local SmallButton = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallButton)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)

local localPlayer = Players.LocalPlayer

-- 1. Create our mock GlobalState

-- 2. Create a Wrapper component to handle the layout and test callbacks
local function StoryWrapper()
	local scale, setScale = ReactFlow.useSpring({
		start = 1,
		target = 1,
		damper = 0.4,
		speed = 10,
	})
	local transparency, setTransparency = ReactFlow.useSpring({
		start = 0,
		target = 0,
		damper = 1,
		speed = 40,
	})

	return e("BillboardGui", {
		-- Size = UDim2.fromScale(8, 4),
		Size = UDim2.fromOffset(200, 50),
		-- BackgroundTransparency = 1,
		Adornee = workspace.cher,
		AlwaysOnTop = true,
		Active = true,
		ClipsDescendants = false,
	}, {
		Button = e("ImageButton", {
			Size = scale:map(function(n)
				return UDim2.new(1 * n, 0, 1 * n, 0)
			end),
			BackgroundTransparency = transparency,
			[React.Event.MouseEnter] = function()
				setScale({
					target = 1.2,
					damper = 0.4,
					speed = 40,
				})
			end,
			[React.Event.MouseLeave] = function()
				setScale({
					target = 1,
					damper = 0.4,
					speed = 10,
				})
				setTransparency({
					target = 0,
					damper = 1,
					speed = 40,
				})
			end,
			[React.Event.MouseButton1Down] = function()
				setTransparency({
					target = 1,
					damper = 1,
					speed = 40,
				})
			end,
			[React.Event.MouseButton1Up] = function()
				setTransparency({
					target = 0,
					damper = 1,
					speed = 40,
				})
			end,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			UIStroke = e("UIStroke", {
				Thickness = 4,
				Color = Color3.new(1, 1, 1),
				Transparency = transparency,
			}),
			BackgroundImage = e("ImageLabel", {
				Active = false,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(8, 8, 92, 92),
				Image = "rbxassetid://127657596958436",
				ImageTransparency = transparency,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				ZIndex = 1,
			}, {}),
			SmallText = e(SmallText, {
				Text = "BUY",
				TextTransparency = transparency,
				TextSize = 42,
				Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
		}),
	})
end

-- 3. Mount the story
local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)

	root:render(e(StoryWrapper))

	return function()
		root:unmount()
	end
end

return story
