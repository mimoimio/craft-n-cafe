local LevelConfig = {}

--[[
set each level's max exp.

in statsslice, keep EXP and Level.
But Level is always determined by the EXP.
Calculated before putting in payload.
newLevel = 1 + EXP//EXPPerLevel

but if different level different max exp, then do it here
	or maybe calculated.
]]
function LevelConfig.GetExpOnLevel(lvl: number): number
	if type(lvl) ~= "number" then
		return
	end
	if lvl < 1 then
		return 0
	end
	return (2.5 ^ lvl) * 2 // 1
end
function LevelConfig.GetLevel(exp: number): number
	if type(exp) ~= "number" then
		return
	end
	local level = 1
	local ExpToLevelUp = LevelConfig.GetExpOnLevel(level)
	repeat
		local leveledUp = exp >= ExpToLevelUp
		if leveledUp then
			level += 1
			ExpToLevelUp = LevelConfig.GetExpOnLevel(level)
		else
			break
		end

	until not leveledUp

	return level
end

return LevelConfig
