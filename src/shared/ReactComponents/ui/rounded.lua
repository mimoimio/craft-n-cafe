local React = require(game.ReplicatedStorage.Packages.React)

local function rounded(props)
	return React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) })
end

return rounded
