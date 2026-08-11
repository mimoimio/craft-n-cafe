-- CharacterAnimation.story.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useBinding = React.useBinding
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local Animations = ReplicatedStorage.Shared.Animations
-- local holdcupAnim = Animations.HoldCup
local holdcupAnim = Animations.Walk

local player = Players.LocalPlayer
local playerId = player and "player.UserId" or ""

local lookVector = Vector3.new(-1, 0, 1)
local initVector = Vector3.new(20, 0, -55)
local initCFrame = CFrame.new(initVector, initVector + lookVector)
local endCFrame = initCFrame:ToWorldSpace(CFrame.new(0, 0, -80))

local function Skeleton()
	local currentCamera, setCurrentCamera = useBinding(nil)
	local character, setCharacter = useState(nil)

	-- State to hold the WorldModel reference instead of the ViewportFrame
	local worldModel, setWorldModel = useState(nil)

	useEffect(function()
		-- Wait for the WorldModel ref to resolve
		if not worldModel then
			return
		end

		local c = workspace.Skeleton:Clone()
		c.Parent = worldModel -- Parent the rig to the WorldModel
		c:PivotTo(initCFrame)
		setCharacter(c)

		-- Set up the Animator
		local humanoid = c:FindFirstChild("Humanoid")
		local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

		-- Load and play the animation
		local track = animator:LoadAnimation(holdcupAnim)
		track.Looped = true
		track:Play(nil, 10, 2)

		-- Manually step the animation since stories run in Edit Mode
		local isRunning = RunService:IsRunning()
		print("isRunning:", isRunning)
		local connection = not isRunning
				and RunService.Heartbeat:Connect(function(deltaTime)
					animator:StepAnimations(deltaTime)
				end)
			or nil

		-- Cleanup function runs when the story is unmounted
		return function()
			if connection then
				connection:Disconnect()
			end
			track:Stop()
			track:Destroy()
			c:Destroy()
			setCharacter(nil)
		end
	end, { worldModel }) -- Depend on worldModel instead of viewport

	useEffect(function()
		local cframeValue = Instance.new("CFrameValue")
		cframeValue.Value = initCFrame
		local conn = cframeValue.Changed:Connect(function(cf)
			if character then
				character:PivotTo(cf)
			end
		end)

		local tween = TweenService:Create(
			cframeValue,
			TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
			{ Value = endCFrame }
		)
		tween:Play()
		return function()
			conn:Disconnect()
			tween:Destroy()
		end
	end, { character })

	return e("ScreenGui", {
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 1010,
		ScreenInsets = Enum.ScreenInsets.None,
		ClipToDeviceSafeArea = false,
		SafeAreaCompatibility = Enum.SafeAreaCompatibility.None,
	}, {
		e("ViewportFrame", {
			CurrentCamera = currentCamera,
			Size = UDim2.new(1.3, 0, 1, 0),
			LightDirection = Vector3.new(0, -1, -1),
			BackgroundTransparency = 1,
			Active = false,
			ImageTransparency = 0,
		}, {
			-- Add the WorldModel here to enable animation and physics processing
			World = e("WorldModel", {
				ref = setWorldModel,
			}, {

				Camera = e("Camera", {
					ref = setCurrentCamera,
					CFrame = CFrame.new(0, 0, 100),
					FieldOfView = 5,
				}),
			}),
		}),
	})
end

local SkeletonApp = function()
	local skels, setSkels = useState({})
	useEffect(function()
		local running = true
		local t = task.defer(function()
			while task.wait(1) and running do
				local _now = workspace:GetServerTimeNow()
				-- print("ticked")
				local random = math.random()
				if random < (player and 1 / 200 or 1) then
					-- print("👀👀👀👀")
					local id = tostring(_now)
					task.defer(function()
						setSkels(function(prev)
							local new = table.clone(prev)
							new[id] = true
							return new
						end)
						task.wait(4)

						setSkels(function(prev)
							local new = table.clone(prev)
							new[id] = nil
							return new
						end)
					end)
				end
			end
		end)
		return function()
			running = false
			task.cancel(t)
		end
	end)
	local children = {}
	for i, _skel: true in skels do
		children[i] = e(Skeleton)
	end
	return e(React.Fragment, nil, children)
end

return SkeletonApp
