local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Promise = require(ReplicatedStorage.Packages.Promise)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef
local useBinding = React.useBinding
local UIState = require(ReplicatedStorage.Shared.producers.UIState)

local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)

local player = game:GetService("Players").LocalPlayer
local playerId = player and player.UserId or ""

local ShopPrompt = function(props: {})
	-- local prompt: ProximityPrompt, setPrompt = useState(nil)
	-- useEffect(function()
	-- 	local promise = Promise.defer(function(resolve, reject)
	-- 		local shop = workspace:WaitForChild("Shop")
	-- 		local shopKeeper = shop:WaitForChild("ShopKeeper")
	-- 		local triggerPrompt = shopKeeper:WaitForChild("TriggerPrompt")
	-- 		if not triggerPrompt then
	-- 			return reject("no triggerPropt")
	-- 		end
	-- 		return resolve(triggerPrompt)
	-- 	end)

	-- 	promise
	-- 		:andThen(function(prompt)
	-- 			setPrompt(prompt)
	-- 		end)
	-- 		:catch(function(err)
	-- 			warn(`[ShopPrompt] Failed to resolve descendants: {err}`)
	-- 		end)

	-- 	return function()
	-- 		-- If the component unmounts before WaitForChild finishes, cancel the Promise
	-- 		-- so it stops executing and doesn't attempt to update unmounted state.
	-- 		promise:cancel()
	-- 	end
	-- end, {})
	-- useEffect(function()
	-- 	if not prompt then
	-- 		return
	-- 	end
	-- 	local conn = prompt.PromptShown:Connect(function()
	-- 		UIState.setShopPromptShown(true)
	-- 	end)
	-- 	local conn2 = prompt.PromptHidden:Connect(function()
	-- 		UIState.setShopPromptShown(false)
	-- 	end)
	-- 	local conn3 = prompt.Triggered:Connect(function(p)
	-- 		if not p == player then
	-- 			return
	-- 		end
	-- 		UIState.toggle("ingredientShop")
	-- 	end)
	-- 	prompt.RequiresLineOfSight = false
	-- 	return function()
	-- 		conn:Disconnect()
	-- 		conn2:Disconnect()
	-- 		conn3:Disconnect()
	-- 	end
	-- end, { prompt })
end

return ShopPrompt
