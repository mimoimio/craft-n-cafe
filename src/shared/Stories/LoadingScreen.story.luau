local TweenService = game:GetService("TweenService")

local function story(frame: Frame)
	-- Cozy, dark background

	local bg = Instance.new("Frame")
	bg.Name = "LoadingScreen"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(38, 28, 21) -- Deep espresso brown
	bg.BorderSizePixel = 0
	bg.ClipsDescendants = true -- Prevents the oversized overlay from spilling out
	bg.Parent = frame

	-- Tiled Scrolling Overlay
	local overlay = Instance.new("ImageLabel")
	overlay.Name = "PatternOverlay"
	overlay.Size = UDim2.new(0, 8000, 0, 8000)
	overlay.Position = UDim2.new(0, 0, 0, 0)
	overlay.AnchorPoint = Vector2.new(0, 0)
	overlay.ScaleType = Enum.ScaleType.Tile
	overlay.TileSize = UDim2.new(0, 200, 0, 200)
	overlay.Image = "rbxassetid://84364030718064" -- Subtle noise/pattern
	overlay.ImageTransparency = 0.92
	overlay.BackgroundTransparency = 1
	overlay.ZIndex = 1
	overlay.Parent = bg

	-- Main Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Text = "COFFEE TAVERN"
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 52
	title.TextColor3 = Color3.fromRGB(240, 222, 195) -- Warm cream
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromScale(0.5, 0.45)
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.ZIndex = 2
	title.Parent = bg

	-- Pulsing Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Text = "Brewing up the menu..."
	subtitle.Font = Enum.Font.GothamMedium
	subtitle.TextSize = 20
	subtitle.TextColor3 = Color3.fromRGB(196, 164, 132) -- Light mocha
	subtitle.BackgroundTransparency = 1
	subtitle.Position = UDim2.fromScale(0.5, 0.55)
	subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
	subtitle.ZIndex = 2
	subtitle.Parent = bg

	-- Progress Bar Container
	local barBg = Instance.new("Frame")
	barBg.Name = "ProgressBarBg"
	barBg.Size = UDim2.fromScale(0.4, 0.02)
	barBg.Position = UDim2.fromScale(0.5, 0.65)
	barBg.AnchorPoint = Vector2.new(0.5, 0.5)
	barBg.BackgroundColor3 = Color3.fromRGB(25, 18, 13)
	barBg.BorderSizePixel = 0
	barBg.ZIndex = 2
	barBg.Parent = bg

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = barBg

	-- Progress Bar Fill
	local barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.Size = UDim2.fromScale(0, 1)
	barFill.BackgroundColor3 = Color3.fromRGB(212, 154, 106) -- Caramel accent
	barFill.BorderSizePixel = 0
	barFill.ZIndex = 3
	barFill.Parent = barBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = barFill

	-- Animation: Diagonal scrolling for the overlay
	local overlayTweenInfo = TweenInfo.new(30, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local overlayTween = TweenService:Create(overlay, overlayTweenInfo, {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, 0),
	})
	overlayTween:Play()

	-- Animation: Looping progress bar for the story preview
	local barTweenInfo = TweenInfo.new(2.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut, -1, true)
	local progressTween = TweenService:Create(barFill, barTweenInfo, { Size = UDim2.fromScale(1, 1) })
	progressTween:Play()

	-- Animation: Gentle pulse effect on the subtitle text
	local textTweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local pulseTween = TweenService:Create(subtitle, textTweenInfo, { TextTransparency = 0.6 })
	pulseTween:Play()

	-- Cleanup function for the story viewer
	return function()
		overlayTween:Cancel()
		progressTween:Cancel()
		pulseTween:Cancel()
		bg:Destroy()
	end
end

return story
