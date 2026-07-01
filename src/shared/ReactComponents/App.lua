local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement

local Main = require(script.Parent.Main)
local ToastProvider = require(script.Parent.Toasts).ToastProvider
-- game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
local function App(props)
	return e(ToastProvider, {}, { e(Main) })
end

return App
