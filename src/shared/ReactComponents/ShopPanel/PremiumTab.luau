-- Shared/ReactComponents/ShopPanel/PremiumTab.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local StorePanel = require(script.Parent.Parent.StorePanel)

local e = React.createElement

local function PremiumTab()
	return e(StorePanel, { Embedded = true })
end

return PremiumTab
