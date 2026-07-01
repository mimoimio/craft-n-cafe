local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local React = require(ReplicatedStorage.Packages.React)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local function ConsoleApp(props)
	local text, setText = useState("Hello")
	local currentGlobalState = props.state
	useEffect(function()
		if not currentGlobalState then
			return
		end

		local function formatValue(value, depth)
			local indent = string.rep("\t", depth)
			if type(value) == "table" then
				local results = {}
				for k, v in value do
					if type(v) == "table" then
						table.insert(results, string.format("%s%s: {", indent, tostring(k)))
						table.insert(results, formatValue(v, depth + 1))
						table.insert(results, indent .. "}")
					else
						table.insert(results, string.format("%s%s: %s,", indent, tostring(k), tostring(v)))
					end
				end
				return table.concat(results, "\n")
			else
				return string.format("%s%s,", indent, tostring(value))
			end
		end

		local lines = {}
		for key, slice in currentGlobalState do
			table.insert(lines, string.format("%s:", key))
			if type(slice) == "table" then
				for k, v in slice do
					if type(v) == "table" then
						table.insert(lines, string.format("\t%s: {", tostring(k)))
						table.insert(lines, formatValue(v, 2))
						table.insert(lines, "\t}")
					else
						table.insert(lines, string.format("\t%s: %s,", tostring(k), tostring(v)))
					end
				end
			end
		end
		setText(table.concat(lines, "\n"))
		return
	end, { currentGlobalState })
	return e(HStack, {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 0.8,
	}, {
		ScrollingFrame = e("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 0.8,
		}, {
			textdisplay = e(SmallText, {
				Text = text,
			}),
		}),
		button = e(SmallButton, {
			Text = "Buy",
			[React.Event.Activated] = function()
				Remotes.BuyDragon:FireServer()
				SoundController.Sound("Click")
			end,
		}),
	})
end

return ConsoleApp
