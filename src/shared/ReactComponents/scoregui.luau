local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local Types = require(ReplicatedStorage.Shared.Types)
local e = React.createElement
local useEffect = React.useEffect
local useSpring = ReactFlow.useSpring
local HStack = require(ReplicatedStorage.Shared.ReactComponents.ui.HStack)

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or "MockUser"

local function Star(props: {
	scoreBinding: React.ReactBinding<number>,
	scoreNumber: number,
})
	local scoreBinding = props.scoreBinding
	-- local size, setSize = useSpring({
	-- 	start = 0,
	-- 	target = 0,
	-- 	damper = 0.2,
	-- 	speed = 10,
	-- })

	-- useEffect(function()
	-- 	setSize({
	-- 		target = props.visible and 1 or 0,
	-- 		damper = 0.2,
	-- 		speed = 10,
	-- 	})
	-- end, { props.visible })
	return e("ImageLabel", {
		-- Visible = props.visible,
		-- Size = UDim2.new(0.8, 0, 0.8, 0),
		Visible = scoreBinding:map(function(n) -- 0-3
			return n >= props.scoreNumber * 0.2
		end),
		Size = scoreBinding:map(function(s)
			local step = 1.2
			local progress = math.clamp((s - (props.scoreNumber - 1) * step) / step, 0, 1)
			return UDim2.new(0, 0, 0, 0):Lerp(UDim2.new(0.8, 0, 0.8, 0), progress)
		end),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = "rbxassetid://72922560207847",
	})
end
return function(props: {
	cup: Types.CupEntity,
})
	local scoreBinding, setScoreBinding = useSpring({
		start = 0,
		target = 0,
		damper = 1,
		speed = 10,
	})
	local status = props.cup and props.cup.status

	useEffect(function()
		warn('mounted')
	end, {})
	useEffect(function()
		if not status then
			return
		end
		setScoreBinding({
			target = status * 1.2,
			--[[ usespring is inconsistent when springing, so overshoot a little]]
			damper = 1,
			speed = 5,
		})
	end, { status })

	if not status then
		return
	end
	return e(HStack, {
		VerticalFlex = "Fill",
		HorizontalFlex = Enum.UIFlexAlignment.SpaceAround,
		Size = UDim2.new(1, 0, 1, 0),
		Spacing = UDim.new(0, 4),
	}, {
		["1"] = e("ImageLabel", {
			LayoutOrder = 1,
			ScaleType = "Fit",
			BackgroundTransparency = 1,
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			Image = "rbxassetid://82536945424526",
			Size = UDim2.new(1, 0, 1, 0),
			AutomaticSize = "None",
		}, {
			e(Star, {
				scoreNumber = 1,
				scoreBinding = scoreBinding,
			}),
		}),
		["2"] = e("ImageLabel", {
			LayoutOrder = 2,
			ScaleType = "Fit",
			BackgroundTransparency = 1,
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			Image = "rbxassetid://82536945424526",
			Size = UDim2.new(1, 0, 1, 0),
			AutomaticSize = "None",
		}, {
			e(Star, {
				scoreNumber = 2,
				scoreBinding = scoreBinding,
			}),
		}),
		["3"] = e("ImageLabel", {
			LayoutOrder = 3,
			ScaleType = "Fit",
			BackgroundTransparency = 1,
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			Image = "rbxassetid://82536945424526",
			Size = UDim2.new(1, 0, 1, 0),
			AutomaticSize = "None",
		}, {
			e(Star, {
				scoreNumber = 3,
				scoreBinding = scoreBinding,
			}),
		}),
	})
end
