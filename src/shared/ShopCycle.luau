--ReplicatedStorage/Shared/ShopCycle.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)
local ShopCycle = {}

-- CONFIG
local SMALL_CYCLE_DURATION = 5 * 60 -- 5 mins
local CYCLES_PER_BIG_CYCLE = 6 -- 6 rotations
local BIG_CYCLE_DURATION = CYCLES_PER_BIG_CYCLE * SMALL_CYCLE_DURATION

ShopCycle.SMALL_CYCLE_DURATION = SMALL_CYCLE_DURATION
ShopCycle.CYCLES_PER_BIG_CYCLE = CYCLES_PER_BIG_CYCLE
ShopCycle.BIG_CYCLE_DURATION = BIG_CYCLE_DURATION

function ShopCycle.getCurrentState(): Types.ShopCycle
	local currentTime = workspace:GetServerTimeNow() -- UTC Timestamp

	-- The unique ID for the current shop rotation
	local currentSmallSeed = math.floor(currentTime / SMALL_CYCLE_DURATION)

	-- Where we are in the big rotation (1 to 6)
	local currentPosition = (currentSmallSeed % CYCLES_PER_BIG_CYCLE) + 1

	local isSpecialEvent = (currentPosition == CYCLES_PER_BIG_CYCLE)

	local timeLeft = ((currentSmallSeed + 1) * SMALL_CYCLE_DURATION) - currentTime

	-- Calculate time to next special event
	local cyclesUntilSpecial = isSpecialEvent and CYCLES_PER_BIG_CYCLE or (CYCLES_PER_BIG_CYCLE - currentPosition)
	local timeToSpecial = timeLeft + (cyclesUntilSpecial - 1) * SMALL_CYCLE_DURATION

	return {
		seed = currentSmallSeed,
		position = currentPosition,
		isSpecial = isSpecialEvent,
		timeLeft = timeLeft,
		timeToSpecial = timeToSpecial,
	}
end

function ShopCycle.formatTime(seconds)
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%02d:%02d", mins, secs)
end

return ShopCycle
