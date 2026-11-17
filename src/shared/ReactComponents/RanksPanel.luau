local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local LeaderboardConfig = require(ReplicatedStorage.Shared.Configs.LeaderboardConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local DefaultScrollFrame = require(script.Parent.DefaultScrollFrame)
local Panel = require(Primitives.Panel)
local HStack = require(Primitives.HStack)
local VStack = require(Primitives.VStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local useBreakpoint = require(ReplicatedStorage.Shared.Hooks.useBreakpoint)

local e = React.createElement
local useEffect = React.useEffect
local useRef = React.useRef
local useState = React.useState

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or "MockUser"

local function formatValue(boardId: string, value: number): string
	if boardId == "PerfectCups" then
		return `{value} perfect`
	elseif boardId == "Customers" then
		return `{value} served`
	elseif boardId == "TimePlayed" then
		return `{value} min`
	end
	return tostring(value)
end

local function RanksPanel()
	local xs, sm, md = useBreakpoint()
	local mobile = xs or sm or md

	local isOpen, setIsOpen = useState(false)
	local boardId, setBoardId = useState("PerfectCups")
	local data, setData = useState(nil)
	local loading, setLoading = useState(false)
	local requestId = useRef(0)

	useEffect(function()
		local unsub = UIState:subscribe(function(state)
			return state.panel == "ranks"
		end, setIsOpen)

		setIsOpen(UIState:getState().panel == "ranks")
		return unsub
	end, {})

	useEffect(function()
		if not isOpen then
			return
		end

		local id = requestId.current + 1
		requestId.current = id
		setLoading(true)

		task.spawn(function()
			local ok, result = pcall(function()
				return Remotes.FetchLeaderboard:InvokeServer(boardId)
			end)

			if requestId.current ~= id then
				return
			end

			if ok and result then
				setData(result)
			else
				setData({
					BoardId = boardId,
					DisplayName = LeaderboardConfig.Boards[boardId] and LeaderboardConfig.Boards[boardId].DisplayName
						or boardId,
					Available = false,
					Entries = {},
					You = nil,
				})
			end

			setLoading(false)
		end)
	end, { isOpen, boardId })

	local tabButtons = {}
	for index, id in ipairs(LeaderboardConfig.Order) do
		local board = LeaderboardConfig.Boards[id]
		tabButtons[id] = e(SmallButton, {
			Size = UDim2.new(0, mobile and 92 or 130, 0, 34),
			AutomaticSize = Enum.AutomaticSize.None,
			BackgroundTransparency = boardId == id and 0.1 or 0.35,
			BackgroundColor3 = boardId == id and Color3.fromRGB(80, 60, 120) or Color3.fromRGB(42, 39, 48),
			LayoutOrder = index,
			[React.Event.Activated] = function()
				setBoardId(id)
			end,
		}, {
			e(SmallText, {
				Text = board.DisplayName,
				Size = UDim2.new(1, 0, 1, 0),
				TextSize = mobile and 12 or 14,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
		})
	end

	local rowChildren = {}
	local entries = data and data.Entries or {}

	for index, entry in ipairs(entries) do
		local isPlayer = entry.UserId == playerId
		rowChildren[`Row{index}`] = e(HStack, {
			Size = UDim2.new(1, 0, 0, 28),
			AutomaticSize = Enum.AutomaticSize.Y,
			HorizontalFlex = "Fill",
			VerticalFlex = "None",
			Spacing = UDim.new(0, 8),
			Padding = { Left = UDim.new(0, 6), Right = UDim.new(0, 6) },
			BackgroundTransparency = 0.85,
			BackgroundColor3 = isPlayer and Color3.fromRGB(80, 65, 120) or Color3.fromRGB(25, 24, 30),
			LayoutOrder = index,
		}, {
			Rank = e(SmallText, {
				Text = `#{entry.Rank}`,
				Size = UDim2.fromOffset(48, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				TextSize = 14,
				TextColor3 = entry.Rank <= 3 and Color3.fromRGB(255, 211, 110) or Color3.fromRGB(200, 200, 210),
				LayoutOrder = 1,
			}),
			Name = e(SmallText, {
				Text = entry.Name,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				TextSize = 14,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextColor3 = isPlayer and Color3.fromRGB(255, 232, 170) or Color3.fromRGB(235, 235, 235),
				LayoutOrder = 2,
			}),
			Value = e(SmallText, {
				Text = formatValue(boardId, entry.Value),
				Size = UDim2.fromOffset(110, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextColor3 = Color3.fromRGB(200, 210, 230),
				LayoutOrder = 3,
			}),
		})
	end

	local youText = "No score yet"
	if data and data.You then
		local rankText = data.You.Rank and `#{data.You.Rank}` or "Top 100+"
		youText = `You: {formatValue(boardId, data.You.Value)} | {rankText}`
	end

	local resetText = data and data.Daily and "Resets daily at 00:00 UTC" or "All-time"
	local stateText = if loading or not data
		then "Loading ranks..."
		elseif not data.Available then "Leaderboard unavailable. Try again later."
		elseif #entries == 0 then "No scores yet. Be the first!"
		else nil

	if stateText then
		rowChildren.Status = e(SmallText, {
			Text = stateText,
			TextSize = 14,
			TextColor3 = Color3.fromRGB(200, 200, 210),
			TextWrapped = true,
			LayoutOrder = 999,
		})
	end

	return e(Panel, {
		Title = "Cafe Ranks",
		Open = isOpen,
		Size = mobile and UDim2.fromScale(0.92, 0.8) or UDim2.fromScale(0.5, 0.75),
		Spacing = UDim.new(0, 8),
		Padding = { All = UDim.new(0, 12) },
		BackgroundImage = "rbxassetid://120520009441669",
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(8, 8, 92, 92),
		BackgroundImageColor3 = Color3.fromRGB(70, 62, 88),
		BackgroundImageTransparency = 0.1,
		OpenPosition = UDim2.fromScale(0.5, 0.5),
		HiddenPosition = UDim2.fromScale(0.5, 1.5),
		OnClose = function()
			UIState.toggle("none")
		end,
	}, {
		Tabs = e(HStack, {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			HorizontalFlex = "Fill",
			VerticalFlex = "None",
			Spacing = UDim.new(0, 6),
		}, tabButtons),

		Summary = e(VStack, {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Spacing = UDim.new(0, 2),
		}, {
			You = e(SmallText, {
				Text = youText,
				TextSize = 15,
				TextColor3 = Color3.fromRGB(255, 232, 170),
			}),
			Reset = e(SmallText, {
				Text = resetText,
				TextSize = 12,
				TextColor3 = Color3.fromRGB(180, 180, 195),
			}),
		}),

		List = e(DefaultScrollFrame, {
			Size = UDim2.new(1, 0, 1, -120),
			BackgroundTransparency = 1,
			Padding = { All = UDim.new(0, 4) },
		}, {
			Rows = e(VStack, {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Spacing = UDim.new(0, 4),
				VerticalFlex = Enum.UIFlexAlignment.None,
			}, rowChildren),
		}),

		State = nil,
	})
end

return RanksPanel
