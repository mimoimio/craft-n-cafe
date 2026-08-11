-- Shared/Hooks/useBreakpoint.luau
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(game:GetService("ReplicatedStorage").Packages.React)
local useEffect, useState = React.useEffect, React.useState

local UIState = require(ReplicatedStorage.Shared.producers.UIState)

local function selectBreakpoint(state: UIState.UIState): UIState.Breakpoint
	return state.breakpoint
end

return function(): (boolean, boolean, boolean, boolean, boolean)
	local bp, setBreakpoint = useState(UIState:getState().breakpoint)
	useEffect(function()
		local unsub = UIState:subscribe(selectBreakpoint, function(breakpoint)
			setBreakpoint(breakpoint)
		end)
		setBreakpoint(UIState:getState().breakpoint)
		return unsub
	end, {})
	local xs, sm, md, lg, xl = bp == "xs", bp == "sm", bp == "md", bp == "lg", bp == "xl"
	return xs, sm, md, lg, xl
end
