-- Shared/ReactComponents/MixerProgressBar.luau
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow) -- Required for useSpring
local useSpring = ReactFlow.useSpring

local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local Types = require(ReplicatedStorage.Shared.Types)
local VStack = require(ReplicatedStorage.Shared.ReactComponents.ui.VStack)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)
local e = React.createElement
local useCallback = React.useCallback
local useState = React.useState
local useEffect = React.useEffect

local imageMap = function(p)
	return p < 1 and "rbxassetid://125013557801199" or "rbxassetid://12402862092"
end

local STAGGER_DURATION = 0.3

local function MixerProgressBar(
	props: {
		Adornee: Instance?,
		StartTime: number,
		Duration: number,
		Config: Types.CoffeeConfigType,
		DrinkName: string,
		Variation: string,
		Size: number, -- NEW: Incoming rolled Size
		time: React.ReactBinding<number>,
		progress: React.ReactBinding<number>,
	}
)
	local displayedSize, setDisplayedSize = useState(1)
	local displayedVariation, setDisplayedVariation = useState("none")
	local rotation, setRotation = useSpring({ start = 0, target = 0, speed = 1, damper = 1 })

	-- Order variations by Weight (Highest weight = most common = earliest in sequence)
	local orderedVariations = React.useMemo(function()
		local list = {}
		for _, v in VariationsConfig do
			table.insert(list, v)
		end
		table.sort(list, function(a, b)
			return a.Weight > b.Weight
		end)
		return list
	end, {})

	-- The Stagger State Machine
	useEffect(function()
		if not props.StartTime then
			return
		end

		local running = true
		local timePassed = workspace:GetServerTimeNow() - props.StartTime

		-- Catch-up logic: If you walk away and walk back, skip the animation
		if timePassed > 2 then
			setDisplayedSize(props.Size)
			setDisplayedVariation(props.Variation)
			return
		end

		task.spawn(function()
			-- Phase 1: Stagger Size
			for i = 1, props.Size do
				if not running then
					return
				end
				setDisplayedSize(i)
				setRotation({ start = 15, target = 0, speed = 40, damper = 0.4 })

				if i < props.Size or props.Variation == "none" then
					SoundController.Sound("Cranking Sound (Wrench)", {
						PlaybackSpeed = 1 + 0.2 * i,
					})
				end
				task.wait(STAGGER_DURATION)
			end
			SoundController.Sound("skate-trick-1")

			-- Phase 2: Stagger Variation (Skips if "none")
			local targetIndex = 1
			for i, v in ipairs(orderedVariations) do
				if v.VariationId == props.Variation then
					targetIndex = i
					break
				end
			end
			task.wait(STAGGER_DURATION)

			for i = 2, targetIndex do
				if not running then
					return
				end
				setDisplayedVariation(orderedVariations[i].VariationId)
				setRotation({ start = 30, target = 0, speed = 40, damper = 0.4 })

				if i < targetIndex then
					SoundController.Sound("powerUp7", {
						PlaybackSpeed = 1 + 0.2 * i,
					})
				end
				task.wait(STAGGER_DURATION)
			end

			if not running then
				return
			end

			-- Phase 3: Final Jingle
			local finalVar = props.Variation
			if finalVar == "double" then
				SoundController.Sound("Fun Jingle A")
			elseif finalVar == "gold" then
				SoundController.Sound("Premium Jingle")
			elseif finalVar == "diamond" then
				SoundController.Sound("crystal_jingle")
			elseif finalVar == "starlight" or finalVar == "hexed" then
				SoundController.Sound("Stick RPG 2 Item Get! Jingle")
			end
		end)

		return function()
			running = false
		end
	end, { props.StartTime, props.Size, props.Variation })

	local textMap = useCallback(function(t)
		local now = t
		local timePassed = now - props.StartTime
		local p = math.clamp(timePassed / props.Duration, 0, 1)
		local timeLeft = props.Duration - timePassed

		if p >= 1 then
			return ``
		else
			return `{timeLeft // 60}m {timeLeft % 60 // 1}s`
		end
	end, { props.StartTime, props.Duration, props.DrinkName })

	-- Use the dynamically ticking variation state for the UI, not props.Variation!
	local currentVarData = VariationsConfig[displayedVariation] or VariationsConfig["none"]
	local ColorGradient = nil
	if currentVarData.VariationId ~= "none" then
		ColorGradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0, currentVarData.ColorPrimary),
			ColorSequenceKeypoint.new(0.22, currentVarData.ColorPrimary),
			ColorSequenceKeypoint.new(0.255, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.3, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.35, currentVarData.ColorPrimary),
			ColorSequenceKeypoint.new(0.399, currentVarData.ColorPrimary),
			ColorSequenceKeypoint.new(0.4, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.6, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.601, currentVarData.ColorPrimary),
			ColorSequenceKeypoint.new(0.62, currentVarData.ColorPrimary),
			ColorSequenceKeypoint.new(0.655, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.7, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.9, currentVarData.ColorPrimary),
			ColorSequenceKeypoint.new(1, currentVarData.ColorPrimary),
		})
	end

	local mappedImage = props.progress and props.progress:map(imageMap) or ""

	-- Calculate visual scale of drink image
	local scaleMultiplier = 0.7 + (displayedSize * 0.3)

	return e(VStack, {
		Size = UDim2.new(1, 0, 3 / 4, 0),
		BackgroundColor3 = Color3.new(0.15, 0.15, 0.15),
		HorizontalFlex = Enum.UIFlexAlignment.None,
		ZIndex = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		LayoutOrder = 1,
		Position = UDim2.new(0.5, 0, 0, 0),
		Active = false,
	}, {
		UICorner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),

		-- VariationLabel = currentVarData.VariationId ~= "none" and e(SmallText, {
		-- 	TextXAlignment = Enum.TextXAlignment.Center,
		-- 	BackgroundTransparency = 1,
		-- 	Text = currentVarData.DisplayName,
		-- 	TextColor3 = currentVarData.ColorPrimary or Color3.new(1, 1, 1),
		-- 	Size = UDim2.new(2, 0, 1 / 6, 0),
		-- 	TextSize = 18,
		-- 	TextTruncate = Enum.TextTruncate.SplitWord,
		-- 	LayoutOrder = 2,
		-- 	Active = false,
		-- 	ZIndex = 20,
		-- }, {
		-- 	UIStroke = e("UIStroke", {
		-- 		Thickness = 4,
		-- 		Color = Color3.new(0.070588, 0.070588, 0.168627),
		-- 	}, {
		-- 		UIGradient = ColorGradient and e("UIGradient", {
		-- 			Color = ColorGradient,
		-- 			Rotation = 78,
		-- 		}),
		-- 	}),
		-- 	UIGradient = ColorGradient and e("UIGradient", {
		-- 		Color = ColorGradient,
		-- 		Rotation = 69,
		-- 	}),
		-- 	UIPadding = e("UIPadding", {
		-- 		PaddingTop = UDim.new(0, 4),
		-- 		PaddingBottom = UDim.new(0, 4),
		-- 		PaddingLeft = UDim.new(0, 4),
		-- 		PaddingRight = UDim.new(0, 4),
		-- 	}),
		-- }),
		FillBackground = e(VStack, {
			HorizontalFlex = Enum.UIFlexAlignment.None,
			Size = UDim2.new(1, 0, 2 / 3, 0),
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.new(0.031372, 0.101960, 0.031372),
			Active = false,
			LayoutOrder = 1,
		}, {
			FillFrame = e("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Active = false,
			}, {
				ProgressCircle = e("ImageLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundColor3 = Color3.fromRGB(30, 30, 38),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Active = false,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 10,
					Position = UDim2.new(0.5, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
				}, {
					ImageCenter = e("ImageLabel", {
						Size = UDim2.fromScale(scaleMultiplier, scaleMultiplier), -- Dynamically growing!
						BackgroundColor3 = Color3.fromRGB(30, 30, 38),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Image = props.Config.Image or "",
						Active = false,
						ScaleType = Enum.ScaleType.Fit,
						ZIndex = 10,
						Position = UDim2.fromScale(0.5, 0.5), -- Anchored dead center so scaling/rotating is flawless
						AnchorPoint = Vector2.new(0.5, 0.5),
						Rotation = rotation,
					}),
					ImageLeft = e("Frame", {
						Size = UDim2.new(0.5, 0, 1, 0),
						Active = false,
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						BackgroundTransparency = 1,
						ZIndex = 9,
						Position = UDim2.new(0, 0, 0.5, 0),
						AnchorPoint = Vector2.new(0, 0.5),
						ClipsDescendants = true,
					}, {
						e("ImageLabel", {
							Size = UDim2.new(2, 0, 2, 0),
							SizeConstraint = Enum.SizeConstraint.RelativeXX,
							BackgroundColor3 = Color3.fromRGB(30, 30, 38),
							BackgroundTransparency = 1,
							ImageTransparency = props.progress:map(function(p)
								return p < 0.5 and 1 or 0
							end),
							BorderSizePixel = 0,
							Image = mappedImage,
							ImageColor3 = currentVarData.VariationId ~= "none" and currentVarData.ColorPrimary or nil,
							ScaleType = Enum.ScaleType.Fit,
							ZIndex = 9,
							Position = UDim2.new(0, 0, 0.5, 0),
							Active = false,
							AnchorPoint = Vector2.new(0, 0.5),
						}, {
							UIGradient = e("UIGradient", {
								Transparency = NumberSequence.new({
									NumberSequenceKeypoint.new(0, 1),
									NumberSequenceKeypoint.new(0.499, 1),
									NumberSequenceKeypoint.new(0.500, 0),
									NumberSequenceKeypoint.new(1, 0),
								}),
								Rotation = props.progress:map(function(n)
									return math.clamp(n * 360 - 180, 0, 180)
								end),
							}),
						}),
					}),
					ImageRight = e("Frame", {
						Size = UDim2.new(0.5, 0, 1, 0),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						Active = false,
						BackgroundTransparency = 1,
						ZIndex = 9,
						Position = UDim2.new(1, 0, 0.5, 0),
						AnchorPoint = Vector2.new(1, 0.5),
						ClipsDescendants = true,
					}, {
						e("ImageLabel", {
							Size = UDim2.new(2, 0, 2, 0),
							SizeConstraint = Enum.SizeConstraint.RelativeXX,
							BackgroundColor3 = Color3.fromRGB(30, 30, 38),
							Active = false,
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Image = mappedImage,
							ImageColor3 = currentVarData.VariationId ~= "none" and currentVarData.ColorPrimary or nil,
							ScaleType = Enum.ScaleType.Fit,
							ZIndex = 9,
							Position = UDim2.new(1, 0, 0.5, 0),
							AnchorPoint = Vector2.new(1, 0.5),
						}, {
							UIGradient = e("UIGradient", {
								Transparency = NumberSequence.new({
									NumberSequenceKeypoint.new(0, 0),
									NumberSequenceKeypoint.new(0.499, 0),
									NumberSequenceKeypoint.new(0.500, 1),
									NumberSequenceKeypoint.new(1, 1),
								}),
								Rotation = props.progress:map(function(n)
									return math.clamp(n * 360, 0, 180)
								end),
							}),
						}),
					}),
				}),
			}),
		}),

		-- DisplayName = e(SmallText, {
		-- 	TextXAlignment = Enum.TextXAlignment.Center,
		-- 	Text = `{props.DrinkName} ({displayedSize}x)`, -- Displays staggered size
		-- 	TextColor3 = Color3.new(1, 1, 1),
		-- 	Size = UDim2.new(2, 0, 1 / 6, 0),
		-- 	TextSize = 18,
		-- 	Active = false,
		-- 	TextTruncate = Enum.TextTruncate.SplitWord,
		-- 	LayoutOrder = 3,
		-- 	Rotation = rotation, -- The Bounce!
		-- }, {
		-- 	UIPadding = e("UIPadding", {
		-- 		PaddingTop = UDim.new(0, 4),
		-- 		PaddingBottom = UDim.new(0, 4),
		-- 		PaddingLeft = UDim.new(0, 4),
		-- 		PaddingRight = UDim.new(0, 4),
		-- 	}),
		-- }),
		TimeLeft = e(SmallText, {
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.new(2, 0, 0, 0),
			Active = false,
			Text = props.time:map(textMap),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 1, 0),
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 18,
			TextTruncate = Enum.TextTruncate.SplitWord,
			LayoutOrder = 4,
			ZIndex = 20,
		}),
	})
end

return MixerProgressBar
