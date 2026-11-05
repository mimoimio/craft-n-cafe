-- Shared/ReactComponents/PlaytestLogger.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local PlaytestConfig = require(ReplicatedStorage.Shared.Configs.PlaytestConfig)
local PlaytestSnapshot = require(ReplicatedStorage.Shared.Utils.PlaytestSnapshot)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local SmallButton = require(Primitives.SmallButton)

local e = React.createElement
local useEffect = React.useEffect
local useRef = React.useRef

local FAST_INTERVAL = 15
local SLOW_INTERVAL = 30
local FAST_PHASE_SECONDS = 180

local function PlaytestLogger(props: { PlayerId: string? })
	local player = Players.LocalPlayer
	local playerId = props.PlayerId or (player and tostring(player.UserId)) or "MockUser"

	local sessionId = useRef(
		`{os.date("!%Y%m%d-%H%M%S", os.time())}-{math.random(1000, 9999)}`
	)
	local startedAt = useRef(workspace:GetServerTimeNow())
	local rows = useRef({})
	local printed = useRef(false)

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

	return e(SmallButton, {
		Text = "Print CSV",
		Size = UDim2.fromOffset(92, 32),
		AutomaticSize = Enum.AutomaticSize.None,
		Position = UDim2.new(0, 8, 0, 8),
		AnchorPoint = Vector2.new(0, 0),
		BackgroundColor3 = Color3.fromRGB(32, 92, 138),
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 14,
		ZIndex = 50,
		[React.Event.Activated] = function()
			printCsv("Manual CSV")
		end,
	})
end

return PlaytestLogger
