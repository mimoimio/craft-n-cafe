local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement

local Main = require(script.Parent.Main)
local ToastProvider = require(script.Parent.Toasts).ToastProvider
local RedDotProvider = require(script.Parent.RedDot).RedDotProvider

local function App(props)
	return e(ToastProvider, nil, {
		-- Assign specific dictionary keys to ensure children pass down properly
		AppRedDotProvider = e(RedDotProvider, nil, {
			AppMain = e(Main),
		}),
	})
end

return App
