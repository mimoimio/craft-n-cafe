local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local DefaultScrollFrame = require(ReplicatedStorage.Shared.ReactComponents.DefaultScrollFrame)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local Grid = require(ReplicatedStorage.Shared.ReactComponents.ui.Grid)

local function App(props: { module: {} })
	local children = {}
	for id, config in props.module.Config do
		-- if config.Ingredients and #config.Ingredients > 1 then
		-- 	continue
		-- end
		children[id] = e("ImageLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			Image = config.Image,
			LayoutOrder = config.Price,
			BackgroundColor3 = config.Ingredients and #config.Ingredients > 1 and Color3.new(1, 0.5, 0.5) or nil,
		}, {
			text = e(SmallText, {
				Text = `{config.DisplayName}\nPrice: {config.Price}\nCost: {config.Cost}\nDuration: {config.Duration // 60}m {config.Duration % 60}s\nInitialStock: {config.InitialStock}`,
				BackgroundTransparency = 0.8,
				TextWrapped = true,
			}),
		})
	end
	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	}, {

		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, 20),
			PaddingBottom = UDim.new(0, 20),
			PaddingLeft = UDim.new(0, 20),
			PaddingRight = UDim.new(0, 20),
		}),
		DefaultScrollFrame = e(DefaultScrollFrame, {
			AutomaticSize = Enum.AutomaticSize.XY,
			-- BackgroundColor3 = Color3.new(1, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			-- AutomaticSize = Enum.AutomaticSize.Y,
			-- BackgroundTransparency = 0,
		}, {
			Grid = e(Grid, {
				Size = UDim2.new(1, 0, 0, 0),
				CellSize = UDim2.new(0, 200, 0, 200),
				AutomaticSize = Enum.AutomaticSize.Y,
			}, children),
		}),
	})
end

local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	require(ReplicatedStorage.Shared.CoffeeModule)
	local module = require(ReplicatedStorage.Shared.CoffeeModule:Clone())
	root:render(e(App, {
		module = module,
	}))

	return function()
		root:unmount()
	end
end

return story
