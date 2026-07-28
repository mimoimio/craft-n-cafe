local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef
local useBinding = React.useBinding
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local DefaultScrollFrame = require(ReplicatedStorage.Shared.ReactComponents.DefaultScrollFrame)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local VStack = require(ReplicatedStorage.Shared.ReactComponents.ui.VStack)
local Grid = require(ReplicatedStorage.Shared.ReactComponents.ui.Grid)

local function App(props: { module: {} })
	local config, setConfig = useState(nil)

	useEffect(function()
		if not props.module then
			return
		end
		local conn = Selection.SelectionChanged:Connect(function()
			if not workspace:FindFirstChild("CoffeeZoo") then
				print(`NO "CoffeeZoo" FOLDER FOUND`)
				return
			end
			local selection = Selection:Get()
			local any = #selection > 0
			if not any then
				return
			end
			local selectedMany = selection and #selection > 1
			local coffee = not selectedMany and selection[1] or nil

			local config = coffee and props.module.Config[coffee.Name] or nil

			setConfig(config)
		end)
		local mouse = plugin and plugin:GetMouse() or nil
		warn(`plugin {plugin}, mouse {mouse}`)
		-- local conn2 =
		return function()
			conn:Disconnect()
		end
	end, { props.module })

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
		Config = config and e(VStack, {
			Size = UDim2.new(0, 300, 0, 0),
			BackgroundTransparency = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
		}, {
			DisplayName = e(SmallText, {
				Text = `DisplayName: {config.DisplayName}`,
			}),
			Price = e(SmallText, {
				Text = `Price: {config.Price}`,
			}),
		}),
	})
end

local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	local module = require(ReplicatedStorage.Shared.CoffeeModule:Clone())
	root:render(e(App, {
		module = module,
	}))

	return function()
		root:unmount()
	end
end

return story
