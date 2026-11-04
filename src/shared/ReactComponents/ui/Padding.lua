local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement

return function(props: {
	All: UDim,
})
	local All = props.All or UDim.new(0, 4)
	return e("UIPadding", {
		PaddingTop = All,
		PaddingBottom = All,
		PaddingLeft = All,
		PaddingRight = All,
	})
end
