-- Shared/ReactComponents/PlaytestLogger.luau
--[[
TODO: 
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local PlaytestConfig = require(ReplicatedStorage.Shared.Configs.PlaytestConfig)
local PlaytestSnapshot = require(ReplicatedStorage.Shared.Utils.PlaytestSnapshot)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local VStack = require(Primitives.VStack)
local SmallButton = require(Primitives.SmallButton)

local e = React.createElement
local useEffect = React.useEffect
local useRef = React.useRef
local useState = React.useState

local FAST_INTERVAL = 15
local SLOW_INTERVAL = 30
local FAST_PHASE_SECONDS = 180

-- Roblox can only render ~16,384 glyphs per TextBox, so split the CSV into
-- multiple boxes that are just under the limit.
local MAX_TEXTBOX_GLYPHS = 16000

local function splitIntoChunks(text: string): { string }
	if text == "" then
		return { "" }
	end

	local chunks = {}
	local start = 1
	local length = #text

	while start <= length do
		local stop = math.min(start + MAX_TEXTBOX_GLYPHS - 1, length)

		-- Prefer ending on a row boundary so the CSV stays readable.
		if stop < length then
			local lastNewline = string.sub(text, start, stop):match(".*()\n")
			if lastNewline and lastNewline > 1 then
				stop = start + lastNewline - 1
			end
		end

		table.insert(chunks, string.sub(text, start, stop))
		start = stop + 1
	end

	return chunks
end

local function PlaytestLogger(props: { PlayerId: string? })
	local player = Players.LocalPlayer
	local playerId = props.PlayerId or (player and tostring(player.UserId)) or "MockUser"

	local sessionId = useRef(`{os.date("!%Y%m%d-%H%M%S", os.time())}-{math.random(1000, 9999)}`)
	local startedAt = useRef(workspace:GetServerTimeNow())
	local rows = useRef({})
	local printed = useRef(false)

	local visible, setVisible = useState(false)
	local chunks, setChunks = useState({})

	local function takeSnapshot()
		local state = GlobalState:getState()
		local previousRow = rows.current[#rows.current]
		local row = PlaytestSnapshot.BuildRow(
			state,
			playerId,
			sessionId.current,
			PlaytestConfig.Variant,
			startedAt.current,
			previousRow
		)
		table.insert(rows.current, row)
	end

	local function printCsv(label: string)
		local csv = PlaytestSnapshot.ToCsv(rows.current)
		print(`[PlaytestLogger] {label} ({#rows.current} rows)\n{csv}`)
	end

	local function showCsv()
		setChunks(splitIntoChunks(PlaytestSnapshot.ToCsv(rows.current)))
	end

	local function updateChunk(index: number, text: string)
		setChunks(function(previous)
			local nextChunks = table.clone(previous)
			nextChunks[index] = text
			return nextChunks
		end)
	end

	useEffect(function()
		printed.current = false
		local alive = true

		-- Baseline at t=0.
		takeSnapshot()

		local thread = task.spawn(function()
			while alive do
				local elapsed = workspace:GetServerTimeNow() - startedAt.current
				local waitTime = if elapsed < FAST_PHASE_SECONDS then FAST_INTERVAL else SLOW_INTERVAL
				task.wait(waitTime)

				if not alive then
					break
				end
				takeSnapshot()
			end
		end)

		return function()
			alive = false
			pcall(task.cancel, thread)

			if not printed.current then
				printed.current = true
				printCsv("Final CSV")
			end
		end
	end, { playerId })

	local textBoxes = {}
	for index, chunk in ipairs(chunks) do
		textBoxes[`Chunk{index}`] = e("TextBox", {
			TextEditable = false,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = index,
			BackgroundColor3 = Color3.fromRGB(16, 16, 20),
			Text = chunk,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 12,
			Font = Enum.Font.Code,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			MultiLine = true,
			ClearTextOnFocus = false,
			Selectable = true,
			ClipsDescendants = true,
			ZIndex = 51,
			[React.Change.Text] = function(textBox)
				updateChunk(index, textBox.Text)
			end,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
			UIPadding = e("UIPadding", {
				PaddingTop = UDim.new(0, 6),
				PaddingBottom = UDim.new(0, 6),
				PaddingLeft = UDim.new(0, 6),
				PaddingRight = UDim.new(0, 6),
			}),
		})
	end

	return e(VStack, {
		Size = UDim2.fromScale(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		Position = UDim2.new(0, 8, 0, 8),
		AnchorPoint = Vector2.new(0, 0),
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		HorizontalFlex = "None",
		VerticalFlex = "None",
		Spacing = UDim.new(0, 6),
		ZIndex = 50,
	}, {
		Toggle = e(SmallButton, {
			Text = if visible then "Hide CSV" else "Show CSV",
			Size = UDim2.fromOffset(92, 32),
			AutomaticSize = Enum.AutomaticSize.None,
			LayoutOrder = 1,
			BackgroundColor3 = Color3.fromRGB(32, 92, 138),
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 14,
			ZIndex = 50,
			[React.Event.Activated] = function()
				setVisible(function(value)
					return not value
				end)
			end,
		}),
		Snapshot = visible and e(VStack, {
			Size = UDim2.fromOffset(384, 300),
			LayoutOrder = 2,
			BackgroundColor3 = Color3.fromRGB(24, 24, 28),
			BackgroundTransparency = 0,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalFlex = "None",
			Spacing = UDim.new(0, 6),
			Padding = { All = UDim.new(0, 8) },
			ZIndex = 50,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			Scroll = e("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, -38),
				LayoutOrder = 1,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 6,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ZIndex = 51,
			}, {
				Content = e(VStack, {
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					HorizontalFlex = "Fill",
					VerticalFlex = "None",
					Spacing = UDim.new(0, 4),
					ZIndex = 51,
				}, textBoxes),
			}),
			Print = e(SmallButton, {
				Text = "Print",
				Size = UDim2.new(1, 0, 0, 32),
				AutomaticSize = Enum.AutomaticSize.None,
				LayoutOrder = 2,
				BackgroundColor3 = Color3.fromRGB(32, 92, 138),
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 14,
				ZIndex = 51,
				[React.Event.Activated] = showCsv,
			}),
		}),
	})
end

return PlaytestLogger
