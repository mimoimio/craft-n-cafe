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

return LevelConfig
