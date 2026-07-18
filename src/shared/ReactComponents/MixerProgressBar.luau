-- Shared/ReactComponents/MixerProgressBar.luau
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local Types = require(ReplicatedStorage.Shared.Types)
local VStack = require(ReplicatedStorage.Shared.ReactComponents.ui.VStack)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)
local e = React.createElement
local useCallback = React.useCallback

local function MixerProgressBar(props: {
	Adornee: Instance,
	StartTime: number,
	Duration: number,
	Config: Types.CoffeeConfigType,
	DrinkName: string,
	Variation: string,
	time: React.ReactBinding<number>,
	progress: React.ReactBinding<number>,
})
	-- We use bindings here so we can update the UI at 60FPS without re-rendering the component
	local textMap = useCallback(function(t)
		local now = t
		local timePassed = now - props.StartTime
		local p = math.clamp(timePassed / props.Duration, 0, 1)
		local timeLeft = props.Duration - timePassed

		if p >= 1 then
			return `(Done!)`
		else
			return `{timeLeft // 60}m {timeLeft % 60 // 1}s`
		end
		return
	end, { props.StartTime, props.Duration, props.DrinkName })

	local variation = props.Variation and VariationsConfig[props.Variation] or nil
	local ColorGradient = variation
			and ColorSequence.new({
				ColorSequenceKeypoint.new(0, variation.ColorPrimary),
				ColorSequenceKeypoint.new(0.22, variation.ColorPrimary),
				ColorSequenceKeypoint.new(0.255, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(0.3, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(0.35, variation.ColorPrimary),
				ColorSequenceKeypoint.new(0.399, variation.ColorPrimary),
				ColorSequenceKeypoint.new(0.4, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(0.6, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(0.601, variation.ColorPrimary),
				ColorSequenceKeypoint.new(0.62, variation.ColorPrimary),
				ColorSequenceKeypoint.new(0.655, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(0.7, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(0.9, variation.ColorPrimary),
				ColorSequenceKeypoint.new(1, variation.ColorPrimary),
			})
		or nil

	return e(VStack, {
		-- Size = UDim2.new(0, 100, 0, 100),
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

		VariationLabel = variation and e(SmallText, {
			TextXAlignment = Enum.TextXAlignment.Center,
			BackgroundTransparency = 1,
			Text = variation.DisplayName,
			TextColor3 = variation.ColorPrimary or Color3.new(1, 1, 1),
			Size = UDim2.new(2, 0, 1 / 6, 0),
			TextSize = 18,
			TextTruncate = Enum.TextTruncate.SplitWord,
			LayoutOrder = 2,
			Active = false,
			ZIndex = 20,
		}, {
			UIStroke = e("UIStroke", {
				Thickness = 4,
				Color = Color3.new(0.070588, 0.070588, 0.168627),
			}, {

				UIGradient = e("UIGradient", {
					Color = ColorGradient,
					Rotation = 78,
				}),
			}),
			UIGradient = e("UIGradient", {
				Color = ColorGradient,
				Rotation = 69,
			}),
			UIPadding = e("UIPadding", {
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
			}),
		}),
		FillBackground = e(VStack, {
			-- Map the 0-1 progress binding to the X scale of the fill frame
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
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundColor3 = Color3.fromRGB(30, 30, 38),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Image = props.Config.Image or "",
						Active = false,
						-- ImageColor3 = bg,
						ScaleType = Enum.ScaleType.Fit,
						ZIndex = 10,
						Position = UDim2.new(0.5, 0, 0, 0),
						AnchorPoint = Vector2.new(0.5, 0),
					}, {}),
					ImageLeft = e("ImageLabel", {
						Size = UDim2.new(0.5, 0, 1, 0),
						Active = false,
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						BackgroundColor3 = Color3.fromRGB(30, 30, 38),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						-- ImageColor3 = bg,
						ScaleType = Enum.ScaleType.Fit,
						ZIndex = 9,
						Position = UDim2.new(0, 0, 0.5, 0),
						AnchorPoint = Vector2.new(0, 0.5),
						ClipsDescendants = true,
					}, {
						ImageLeft = e("ImageLabel", {
							Size = UDim2.new(2, 0, 2, 0),
							SizeConstraint = Enum.SizeConstraint.RelativeXX,
							BackgroundColor3 = Color3.fromRGB(30, 30, 38),
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Image = "rbxassetid://125013557801199",
							ImageColor3 = variation and variation.ColorPrimary or nil,
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
					ImageRight = e("ImageLabel", {
						Size = UDim2.new(0.5, 0, 1, 0),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						Active = false,
						BackgroundColor3 = Color3.fromRGB(30, 30, 38),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						-- ImageColor3 = bg,
						ScaleType = Enum.ScaleType.Fit,
						ZIndex = 9,
						Position = UDim2.new(1, 0, 0.5, 0),
						AnchorPoint = Vector2.new(1, 0.5),
						ClipsDescendants = true,
					}, {
						ImageLeft = e("ImageLabel", {
							Size = UDim2.new(2, 0, 2, 0),
							SizeConstraint = Enum.SizeConstraint.RelativeXX,
							BackgroundColor3 = Color3.fromRGB(30, 30, 38),
							Active = false,
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Image = "rbxassetid://125013557801199",
							ImageColor3 = variation and variation.ColorPrimary or nil,
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
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
		}),

		DisplayName = e(SmallText, {
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = props.DrinkName,
			TextColor3 = Color3.new(1, 1, 1),
			Size = UDim2.new(2, 0, 1 / 6, 0),
			TextSize = 18,
			Active = false,
			TextTruncate = Enum.TextTruncate.SplitWord,
			LayoutOrder = 3,
		}, {
			UIPadding = e("UIPadding", {
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
			}),
		}),
		TimeLeft = e(SmallText, {
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.new(2, 0, 0, 0),
			Active = false,
			Text = props.time:map(textMap),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 1, 0),
			-- AutomaticSize = Enum.AutomaticSize.XY,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 18,
			TextTruncate = Enum.TextTruncate.SplitWord,
			LayoutOrder = 4,
			ZIndex = 20,
		}),
	})
end

return MixerProgressBar
