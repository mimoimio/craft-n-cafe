-- SettingsPanel.luau
local GroupService = game:GetService("GroupService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local e = React.createElement
local useState = React.useState
local useSpring = ReactFlow.useSpring

local useBinding = React.useBinding
local useEffect = React.useEffect
local useRef = React.useRef
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local GroupRewardConfig = require(ReplicatedStorage.Shared.Configs.GroupRewardConfig)
local FeedbackPromptController = require(ReplicatedStorage.Shared.Controllers.FeedbackPromptController)

-- Require the controllers so UI can update them directly
local MusicController = require(ReplicatedStorage.Shared.Controllers.MusicController)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local DefaultScrollFrame = require(script.Parent.DefaultScrollFrame)
local Toasts = require(script.Parent.Toasts)
local useToast = Toasts.useToast
local Panel = require(Primitives.Panel)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local useBreakpoint = require(script.Parent.Parent.Hooks.useBreakpoint)
local Slider = require(Primitives.Slider)

local player = game:GetService("Players").LocalPlayer
local playerId = player and tostring(player.UserId) or "MockUser"

local function SettingsPanel(props: {
	OnClose: () -> (),
})
	local toast = useToast()

	local stats, setStats = useState(nil)

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Stats[playerId]
		end, function(playersStats)
			setStats(playersStats)
		end)
		local state = GlobalState:getState()
		local playersStats = state.Stats[playerId]
		if playersStats then
			setStats(playersStats)
		end
		return unsub
	end, {})

	local prevCafeOpenRef = useRef(nil)
	useEffect(function()
		if not (stats ~= nil and stats.CafeOpen ~= nil) then
			return
		end
		if prevCafeOpenRef.current == nil then
			prevCafeOpenRef.current = stats.CafeOpen
			return
		end
		if prevCafeOpenRef.current ~= stats.CafeOpen then
			toast.open(prevCafeOpenRef.current and "Cafe Closed!" or "Cafe Opened!")
			prevCafeOpenRef.current = stats.CafeOpen
		end
	end, { stats and stats.CafeOpen })

	local function requestGroupReward()
		if stats and stats.GroupRewardClaimed then
			toast.open("Group reward already claimed.", 3)
			return
		end

		task.spawn(function()
			local ok, status = pcall(function()
				return GroupService:PromptJoinAsync(GroupRewardConfig.GroupId)
			end)

			if not ok then
				toast.open("Group prompt is unavailable right now.", 3, Color3.fromRGB(255, 90, 90))
				return
			end

			if status == Enum.GroupMembershipStatus.Joined or status == Enum.GroupMembershipStatus.AlreadyMember then
				local claimedOk, claimed = pcall(function()
					return Remotes.ClaimGroupReward:InvokeServer()
				end)

				if claimedOk and claimed then
					toast.open(`Group reward claimed! +{GroupRewardConfig.Cash} cash`, 4, Color3.fromRGB(255, 211, 110))
				else
					toast.open(
						"Could not claim the group reward. Try rejoining the group.",
						4,
						Color3.fromRGB(255, 90, 90)
					)
				end
			elseif status == Enum.GroupMembershipStatus.JoinRequestPending then
				toast.open("Join request pending. Try again after approval.", 4)
			else
				toast.open("Join the group to claim the reward.", 3)
			end
		end)
	end

	local function requestFeedback()
		local started = FeedbackPromptController.request()
		if not started and FeedbackPromptController.isStudio() then
			toast.open("Feedback is only available in the published game.", 4)
		end
	end

	local position, setPosition = useSpring({
		start = -1,
		target = -1,
		speed = 1,
		damper = 1,
	})

	local visible, setVisible = useState(false)
	useEffect(function()
		if visible then
			setPosition({ target = 0, speed = 30, damper = 0.6 })
		else
			setPosition({ target = -1, speed = 30, damper = 0.6 })
		end
	end, { visible })
	useEffect(function()
		local unsub = UIState:subscribe(function(state)
			return state.panel
		end, function(panel)
			setVisible(panel == "settings")
		end)
		setVisible(UIState:getState().panel == "settings")
		return unsub
	end, {})
	local xs, sm, md = useBreakpoint()
	local mobile = xs or sm or md
	return e(Panel, {
		Title = "Settings",
		Open = visible,
		Size = mobile and UDim2.fromScale(0.96, 0.92) or UDim2.fromScale(0.9, 0.88),
		Spacing = UDim.new(0, 8),
		Padding = { All = UDim.new(0, 12) },
		BackgroundImage = "rbxassetid://136108798032529",

		-- BackgroundImage = "rbxassetid://93437537630442",
		-- BackgroundImage = "rbxassetid://120520009441669",
		ScaleType = Enum.ScaleType.Slice,
		-- SliceCenter = Rect.new(200, 200, 209, 209),
		BackgroundImageColor3 = Color3.fromRGB(180, 170, 160),
		OpenPosition = UDim2.fromScale(0.5, 0.5),
		HiddenPosition = UDim2.fromScale(0.5, 1.5),
		-- BackgroundImageTransparency = 0.15,
		BackgroundImageTransparency = 0,
		OnClose = function()
			UIState.toggle("none")
		end,
		SliceCenter = Rect.new(140, 150, 142, 152),
		MaxSize = Vector2.new(mobile and 320 or 600, 600),
	}, {
		DefaultScrollFrame = e(DefaultScrollFrame, {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Padding = { All = UDim.new(0, 8) },
		}, {
			Grid = e(VStack, {
				Spacing = UDim.new(0, 12),
				Size = UDim2.new(1, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				VerticalFlex = Enum.UIFlexAlignment.None,
			}, {
				cafetoggle = e(SmallButton, {
					Size = UDim2.new(0, props.mobile and 78 or 110, 0, 34),
					AutomaticSize = Enum.AutomaticSize.None,
					-- BackgroundColor3 = (not unlocked) and Color3.new(0.4, 0.4, 0.4) or nil,
					BackgroundTransparency = 1,
					-- ImageColor3 = not isActive and Color3.new(0.4, 0.4, 0.6) or nil,
					-- ImageTransparency = (not unlocked) and 0.8 or 0,
					Image = "rbxassetid://128846321008253",
					HoverScale = true,
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(50, 50, 54, 57),
					LayoutOrder = 3,
					Rounded = false,
				}, {
					e(SmallText, {
						Text = stats
								and stats.CafeOpen
								and `Your Cafe is Open!\n<font size="12">Click to close cafe</font>`
							or `Your Cafe is Closed!\n<font size="12">Click to open cafe</font>`,
						[React.Event.Activated] = function()
							Remotes.ToggleCafeOpen:FireServer()
						end,
						RichText = true,
						MinTextSize = 14,
					}),
				}),

				-- GroupReward = e(SmallButton, {
				-- 	Text = stats and stats.GroupRewardClaimed and "Group Reward Claimed"
				-- 		or `Join Group (+{GroupRewardConfig.Cash} Cash)`,
				-- 	MinTextSize = 14,
				-- 	BackgroundColor3 = stats and stats.GroupRewardClaimed and Color3.fromRGB(70, 70, 80)
				-- 		or Color3.fromRGB(70, 105, 180),
				-- 	[React.Event.Activated] = requestGroupReward,
				-- }),

				-- Feedback = e(SmallButton, {
				-- 	Text = "Send Feedback",
				-- 	MinTextSize = 14,
				-- 	BackgroundColor3 = Color3.fromRGB(95, 75, 140),
				-- 	[React.Event.Activated] = requestFeedback,
				-- }),

				-- Music Slider
				MusicSlider = stats and stats.MusicVolume ~= nil and e(Slider, {
					Label = "Music Volume",
					Value = stats.MusicVolume,
					OnDrag = function(newValue)
						MusicController.setVolume(newValue) -- Client updates locally immediately
					end,
					OnChange = function(newValue)
						MusicController.setVolume(newValue) -- Ensure state holds on release
						Remotes.SetMusicVolume:FireServer(newValue) -- Tell server to save it silently
					end,
				}),

				-- SFX Slider
				SfxSlider = stats and stats.SfxVolume ~= nil and e(Slider, {
					Label = "SFX Volume",
					Value = stats.SfxVolume,
					OnDrag = function(newValue)
						SoundController.setVolume(newValue)
					end,
					OnChange = function(newValue)
						SoundController.setVolume(newValue)
						Remotes.SetSfxVolume:FireServer(newValue)
					end,
				}),
			}),
		}),
	})
end

return SettingsPanel
