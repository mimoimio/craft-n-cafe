-- CoinParticle.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactOtter = require(ReplicatedStorage.Packages.ReactOtter)

local ICON = "<b>robux</b>"
-- local ICON = "<b>two-folders</b>"
local TRAILICON = "<b>circle</b>"

local trailCount = 3
local trailSpacing = 1 -- Tighter spacing since the end velocity is much higher now

local function getCubicBezierPoint(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: number): Vector2
	local l1 = p0:Lerp(p1, t)
	local l2 = p1:Lerp(p2, t)
	local l3 = p2:Lerp(p3, t)

	local a = l1:Lerp(l2, t)
	local b = l2:Lerp(l3, t)

	return a:Lerp(b, t)
end

local exp = 6

local scaleMap = function(t)
	-- The desired scale you want it to stay at (e.g., 1.5x bigger)
	local maxScale = 1.5

	if t < 0.15 then
		-- PHASE 1: The Pop
		-- Normalizes 't' from 0->0.15 into a 0->1 range
		local popProgress = t / 0.15

		-- Use a Sine curve so it slows down right as it hits the max scale
		return math.sin(popProgress * (math.pi / 2) * 2) * maxScale
	-- elseif t > .75 then
	-- 	-- PHASE 3 (Optional Polish): The Slurp
	-- 	-- Shrinks the coin back down to normal size (1.0) right as it hits the HUD
	-- 	local shrinkProgress = (t - 0.75) / .75
	-- 	local scale = maxScale - (shrinkProgress * (maxScale - 1.0))
	-- 	print(1-shrinkProgress)
	-- 	return .75 - shrinkProgress
	else
		-- PHASE 2: The Move
		-- It just stays at the max scale while traveling!
		return maxScale
	end
end

local function CoinParticle(props)
	local startPos = props.startPos
	local targetPos = props.targetPos
	local onComplete = props.onComplete
	local randSizeOffset = React.useState(math.random(0, 3))
	local startTick = React.useState(tick())

	local controlPoints = React.useMemo(function()
		local randomSpread = math.random(-200, 200)

		-- P1: The initial pop up and out.
		local p1 = startPos + Vector2.new(randomSpread, math.random(-200, 200))
		-- local p1 = startPos

		-- P2: Clustered right next to P1! This anchors the curve in the air,
		-- forcing the particle to hang around this area before diving.
		local p2 = p1 + Vector2.new(0, -math.random(-200, 200))

		return { p1 = p1, p2 = p2 }
	end, { startPos, targetPos })

	local tBinding, setTGoal = ReactOtter.useAnimatedBinding(0, function()
		if onComplete then
			onComplete(props.id)
		end
	end)

	React.useEffect(function()
		setTGoal(ReactOtter.spring(1, {
			dampingRatio = 0.9,
			frequency = 1.5 - 0.5 * math.random(),
		}))
	end, {})

	local uiElements = {}

	for i = 1, trailCount do
		local taperScale = 1 - (i / (trailCount + 1))
		local size = (18 + randSizeOffset) * taperScale

		uiElements["Trail" .. i] = React.createElement("ImageLabel", {
			Image = "rbxassetid://17368060122",
			Size = UDim2.fromOffset(size, size),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			ZIndex = -1 - i,
			Position = tBinding:map(function(t)
				local easedT = t ^ exp
				local collapseMultiplier = math.max(0, 1 - t)
				local delayedT = math.max(0, easedT - (i * trailSpacing * collapseMultiplier))
				local pos = getCubicBezierPoint(startPos, controlPoints.p1, controlPoints.p2, targetPos, delayedT)
				return UDim2.fromOffset(pos.X, pos.Y)
			end),
		}, {
			Scale = React.createElement("UIScale", {
				Scale = tBinding:map(scaleMap),
			}),
		})
	end
	-- local mainCoinSize = 30 + randSizeOffset

	uiElements.MainCoin = React.createElement("ImageLabel", {
		Image = "rbxassetid://17368060122",
		Size = UDim2.fromOffset(20 + randSizeOffset, 20 + randSizeOffset),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 100,
		Position = tBinding:map(function(t)
			local easedT = t ^ exp
			local pos = getCubicBezierPoint(startPos, controlPoints.p1, controlPoints.p2, targetPos, easedT)
			return UDim2.fromOffset(pos.X, pos.Y)
		end),
	}, {
		Scale = React.createElement("UIScale", {
			Scale = tBinding:map(scaleMap),
		}),
	})
	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, uiElements)
end

return CoinParticle
