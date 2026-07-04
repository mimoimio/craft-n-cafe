-- CoinVFXContainer.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

-- Point this to wherever your CoinParticle component is housed
local CoinParticle = require(script.Parent.CoinParticle)

local function CoinVFXContainer(props)
	-- Decoupled! We now expect data and callbacks to be passed strictly via props
	local activeCoins = props.activeCoins
	local onCoinComplete = props.onCoinComplete

	-- Passing hudPos via props makes this component completely agnostic to screen layout

	local particles = {}

	if activeCoins then
		local coinsCount = 0
		for id, coinData in pairs(activeCoins) do
			local hudPos = coinData.hudPos or Vector2.new(100, 50)
			if coinsCount >= 100 then
				continue
			end
			coinsCount += 1
			particles[id] = React.createElement(CoinParticle, {
				id = id,
				startPos = coinData.startPos,
				targetPos = hudPos,
				Color3 = coinData.side
						and (coinData.side == "left" and Color3.new(0.5, 0.2, 0.2) or Color3.new(0.2, 0.2, 0.5))
					or nil,
				onComplete = function(completedId)
					-- We just bubble the event up. The parent handles the data logic!
					if onCoinComplete then
						onCoinComplete(completedId)
					end
				end,
			})
		end
	end

	return React.createElement("ScreenGui", {
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 100,
	}, particles)
end

return CoinVFXContainer
