-- Shared/ReactComponents/CashierNode.luau -- client side
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Types = require(ReplicatedStorage.Shared.Types)

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState

local COOLDOWN_DURATION = 3 -- Update this to match your actual cooldown logic

local function CashierNode(props: {
	CashierUid: string,
	CashierData: Types.CashierEntity,
	Instance: Model,
})
	local progress, setProgress = React.useBinding(0)
	local isVisible, setIsVisible = useState(false)

	-- Handle Cooldown Progress
	useEffect(function()
		if not props.CashierData.lastTend then return end
		
		local conn = RunService.RenderStepped:Connect(function()
			local now = workspace:GetServerTimeNow()
			local elapsed = now - props.CashierData.lastTend
			
			local currentProgress = math.clamp(elapsed / COOLDOWN_DURATION, 0, 1)
			setProgress(currentProgress)
			
			-- Only show the wheel if it's currently on cooldown
			if currentProgress < 1 and not isVisible then
				setIsVisible(true)
			elseif currentProgress >= 1 and isVisible then
				setIsVisible(false)
			end
		end)

		return function()
			conn:Disconnect()
		end
	end, { props.CashierData.lastTend, isVisible })

	if not props.Instance or not isVisible then
		return nil
	end

	local mappedImage = progress:map(function(p)
		return "rbxassetid://125013557801199" -- Assuming this is your circle mask from MixerProgressBar
	end)

	local wheelColor = Color3.fromRGB(80, 200, 120) -- Green color for the fill

	return ReactRoblox.createPortal(
		e("BillboardGui", {
			Adornee = props.Instance,
			Size = UDim2.fromOffset(60, 60),
			StudsOffset = Vector3.new(0, 3, 0), -- Position above the cashier's head
			AlwaysOnTop = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		}, {
			ProgressContainer = e("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}, {
				BackgroundCircle = e("ImageLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.fromRGB(30, 30, 38),
					BackgroundTransparency = 1,
					Image = "rbxassetid://125013557801199",
					ImageColor3 = Color3.fromRGB(30, 30, 38),
					ImageTransparency = 0.5,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 1,
				}),
				ImageLeft = e("Frame", {
					Size = UDim2.new(0.5, 0, 1, 0),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					BackgroundTransparency = 1,
					ZIndex = 2,
					Position = UDim2.new(0, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					ClipsDescendants = true,
				}, {
					HalfCircle = e("ImageLabel", {
						Size = UDim2.new(2, 0, 2, 0),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						BackgroundTransparency = 1,
						ImageTransparency = progress:map(function(p)
							return p < 0.5 and 1 or 0
						end),
						Image = mappedImage,
						ImageColor3 = wheelColor,
						ScaleType = Enum.ScaleType.Fit,
						ZIndex = 2,
						Position = UDim2.new(0, 0, 0.5, 0),
						AnchorPoint = Vector2.new(0, 0.5),
					}, {
						UIGradient = e("UIGradient", {
							Transparency = NumberSequence.new({
								NumberSequenceKeypoint.new(0, 1),
								NumberSequenceKeypoint.new(0.499, 1),
								NumberSequenceKeypoint.new(0.500, 0),
								NumberSequenceKeypoint.new(1, 0),
							}),
							Rotation = progress:map(function(n)
								return math.clamp(n * 360 - 180, 0, 180)
							end),
						}),
					}),
				}),
				ImageRight = e("Frame", {
					Size = UDim2.new(0.5, 0, 1, 0),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					BackgroundTransparency = 1,
					ZIndex = 2,
					Position = UDim2.new(1, 0, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					ClipsDescendants = true,
				}, {
					HalfCircle = e("ImageLabel", {
						Size = UDim2.new(2, 0, 2, 0),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						BackgroundTransparency = 1,
						Image = mappedImage,
						ImageColor3 = wheelColor,
						ScaleType = Enum.ScaleType.Fit,
						ZIndex = 2,
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
							Rotation = progress:map(function(n)
								return math.clamp(n * 360, 0, 180)
							end),
						}),
					}),
				}),
			}),
		}),
		props.Instance
	)
end

return CashierNode