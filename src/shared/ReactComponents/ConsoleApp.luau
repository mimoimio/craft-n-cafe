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

local function ConsoleApp()
	local text, setText = useState("Hello")
	local state, setState = useState(nil)
	local currentGlobalState = state
	-- Keep global state in sync
	useEffect(function()
		local unsub = GlobalState:subscribe(function(newState)
			setState(newState)
		end)

		setState(GlobalState:getState())

		return unsub
	end, {})
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
						-- table.insert(
						-- 	results,
						-- 	string.format("%s%s (%s): {", indent, k == "customerAction" and k or "", "")
						-- )
						table.insert(results, string.format("%s%s (%s): {", indent, tostring(k), type(k)))
						table.insert(results, formatValue(v, depth + 1))
						table.insert(results, indent .. "}")
					elseif k == "customerAction" then
						table.insert(
							results,
							string.format(`%s%s : "%s"`, indent, k == "customerAction" and k or "", tostring(v))
							-- string.format("%s%s (%s): %s(%s),", indent, tostring(k), type(k), tostring(v), type(v))
						)
					end
				end
				return table.concat(results, "\n")
			else
				return string.format("%s%s,", indent, tostring(value))
			end
		end

		local lines = {}
		for key, slice in currentGlobalState do
			if
				key == "Shelves"
				or key == "Tables"
				or key == "Drinks"
				or key == "DiscoveredDrinks"
				or key == "Mixers"
				or key == "Ingredients"
				or key == "Cashiers"
				or key == "Stats"
			then
				continue
			end
			table.insert(lines, string.format("%s (%s):", key, type(key)))
			if type(slice) == "table" then
				for k, v in slice do
					if type(v) == "table" then
						table.insert(lines, string.format("\t%s (%s): {", tostring(k), tostring(type(k))))
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
	return e(VStack, {
		Size = UDim2.new(0, 400, 1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 0.8,
		Active = false,
	}, {
		e(SmallButton, {
			Text = "+500 Cash",
			[React.Event.Activated] = function()
				Remotes.Add500:FireServer()
			end,
		}),
		ScrollingFrame = e("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 0.8,
			Active = false,
		}, {
			textdisplay = e(SmallText, {
				Text = text,
				Active = false,
			}),
		}),
	})
end

return ConsoleApp
