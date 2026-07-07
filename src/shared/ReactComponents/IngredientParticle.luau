local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactOtter = require(ReplicatedStorage.Packages.ReactOtter)

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
	local maxScale = 1.3
	if t < 0.15 then
		local popProgress = t / 0.15
		return math.sin(popProgress * (math.pi / 2) * 2) * maxScale
	else
		return maxScale
	end
end

local function IngredientParticle(props)
	local startPos = props.startPos
	local targetPos = props.targetPos
	local onComplete = props.onComplete
	local image = props.image

	local randSizeOffset = React.useState(math.random(0, 5))

	local controlPoints = React.useMemo(function()
		local randomSpread = math.random(-10, 10)
		local p1 = startPos + Vector2.new(randomSpread, math.random(-10, 10))
		local p2 = p1 + Vector2.new(0, -math.random(-10, 10))
		return { p1 = p1, p2 = p2 }
	end, { startPos, targetPos })

	local tBinding, setTGoal = ReactOtter.useAnimatedBinding(0, function()
		if onComplete then
			onComplete(props.id, props.ingredientId)
		end
	end)

	React.useEffect(function()
		setTGoal(ReactOtter.spring(1, {
			dampingRatio = 0.9,
			frequency = 6.2 - 0.5 * math.random(),
		}))
	end, {})

	local uiElements = {}
	local mainSize = 40 + randSizeOffset

	uiElements.MainIcon = React.createElement("ImageLabel", {
		Size = UDim2.fromOffset(mainSize, mainSize),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Image = image,
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

return IngredientParticle
