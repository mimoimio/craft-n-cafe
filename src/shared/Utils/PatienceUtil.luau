-- Shared/Utils/PatienceUtil.luau
local PatienceUtil = {}

-- Central source of truth for how long a customer will wait.
-- Increase this to make customers more patient.
PatienceUtil.MAX_WAITING_TIME = 30

-- The color meter shifts from green -> yellow -> red across the full duration.
local WARNING_RATIO = 0.5

function PatienceUtil.getRatio(secondsWaited: number): number
	local maxTime = PatienceUtil.MAX_WAITING_TIME
	if maxTime <= 0 then
		return 1
	end
	return math.clamp(secondsWaited / maxTime, 0, 1)
end

function PatienceUtil.getColor(secondsWaited: number): Color3
	local ratio = PatienceUtil.getRatio(secondsWaited)

	if ratio < WARNING_RATIO then
		return Color3.new(0, 1, 0.2):Lerp(Color3.new(1, 1, 0), math.clamp(ratio / WARNING_RATIO, 0, 1))
	end

	return Color3.new(1, 1, 0):Lerp(
		Color3.new(1, 0, 0),
		math.clamp((ratio - WARNING_RATIO) / (1 - WARNING_RATIO), 0, 1)
	)
end

return PatienceUtil
