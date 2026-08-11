-- CharacterAnimation.story.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useBinding = React.useBinding
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local Skeleton = require(ReplicatedStorage.Shared.ReactComponents.Skeleton)

local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	root:render(e(Skeleton))

	return function()
		root:unmount()
	end
end

return story
