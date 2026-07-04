local React = require(game.ReplicatedStorage.Packages.React)
local ReactFlow = require(game.ReplicatedStorage.Packages.ReactFlow)
local e = React.createElement
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Grid = require(game.ReplicatedStorage.Shared.ReactComponents.ui.Grid)
local SmallText = require(game.ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local SmallButton = require(game.ReplicatedStorage.Shared.ReactComponents.ui.SmallButton)
local VStack = require(game.ReplicatedStorage.Shared.ReactComponents.ui.VStack)
local HStack = require(game.ReplicatedStorage.Shared.ReactComponents.ui.HStack)
local SoundController = require(game.ReplicatedStorage.Shared.Controllers.SoundController)
local function DefaultScrollFrame(props)
	return e("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = props.BackgroundTransparency or 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 20,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar, -- Only inset for the bar that exists
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(1, 0, 0, 0), -- X scale will override inset. Set to 0
		ScrollingDirection = Enum.ScrollingDirection.Y,
		LayoutOrder = 2,
		ClipsDescendants = true,
		ref = function(this: ScrollingFrame)
			-- this.CanvasPosition = Vector2.new(0.1, 1)
		end,
	}, {
		InsetWrapper = e("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ClipsDescendants = true,
		}, {

			Padding = e("UIPadding", {
				PaddingTop = UDim.new(0, 0),
				PaddingBottom = UDim.new(0, 0),
				PaddingLeft = UDim.new(0, 0),
				PaddingRight = UDim.new(0, 20),
			}),

			VStack = e(VStack, {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Spacing = UDim.new(0, 2),
				VerticalFlex = Enum.UIFlexAlignment.None,
				ClipsDescendants = true,
			}, props.children),
			--[[{
				e(SmallButton, {
					Text = "Yeah",
					BackgroundTransparency = 0,
					BackgroundColor3 = Color3.new(),
					Size = UDim2.new(0, 50, 0, 50),
				}),
			}
            ]]
		}),
	})
end

return DefaultScrollFrame
