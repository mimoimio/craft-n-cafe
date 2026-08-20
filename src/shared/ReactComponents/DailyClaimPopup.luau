-- Shared/ReactComponents/DailyClaimPopup.luau
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useBinding = React.useBinding
local useRef = React.useRef
local useEffect = React.useEffect
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local DailyConfig = require(ReplicatedStorage.Shared.Configs.DailyConfig)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local SmallButton = require(Primitives.SmallButton)
local st = require(Primitives.SmallText)
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)

local SmallText = function(props)
	props = props or {}
	props.children = props.children or {}
	table.insert(
		props.children,
		e("UIStroke", {
			Thickness = 2,
			Transparency = props.Transparency
				or props.TextTransparency
				or props.ImageTransparency
				or props.BackgroundImageTransparency,
		})
	)
	return e(st, props, props.children)
end

-- Slightly faster delay than LevelUp since Day 7 drops a lot of items!
local INTER_DELAY = 0.15

local player = game:GetService("Players").LocalPlayer
local playerId = player and tostring(player.UserId) or ""

local function delayedRevealTransMap(startTime, sec: number, minTransparency: number?)
	return function(t)
		if not startTime then
			return 1
		end
		if t > startTime then
			if t > startTime + sec then
				local elapsed = math.min(t - startTime - sec, 1)
				elapsed ^= 10
				elapsed = 1 - elapsed

				if minTransparency then
					elapsed = math.max(minTransparency, elapsed)
				end
				return elapsed
			end
		end
		return 1
	end
end

local function delayedRevealSizeMap(startTime, sec: number, finalSize: UDim2)
	return function(t)
		if not startTime then
			return
		end
		if t > startTime then
			if t > startTime + sec then
				local elapsed = math.min(t - startTime - sec, 1)
				elapsed ^= 10
				return UDim2.new(
					elapsed * finalSize.X.Scale,
					elapsed * finalSize.X.Offset,
					elapsed * finalSize.Y.Scale,
					elapsed * finalSize.Y.Offset
				)
			end
		end
		return
	end
end

local function DailyClaimPopup(props: {})
	local dailyState, setDailyState = useState(nil)
	local isActive, setIsActive = useState(false)
	local t, setT = useBinding(workspace:GetServerTimeNow())
	local startTime, setStartTime = useState(math.huge)
	local claimedDay, setClaimedDay = useState(1)

	-- 1. Subscribe to the Daily State for this player
	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: any)
			return state.Daily and state.Daily[playerId]
		end, function(newDailyState)
			-- print(
			-- 	`[DailyClaimPopup] 🔄 Reflex Store sent an update! lastClaimedDaily is now: {newDailyState and newDailyState.lastClaimedDaily or "nil"}`
			-- )
			setDailyState(newDailyState)
		end)

		local state = GlobalState:getState()
		if state.Daily and state.Daily[playerId] then
			-- print(
			-- 	`[DailyClaimPopup] 🟢 Initial State fetched! lastClaimedDaily: {state.Daily[playerId].lastClaimedDaily or "nil"}`
			-- )
			setDailyState(state.Daily[playerId])
		end

		local timer = task.spawn(function()
			while task.wait() do
				setT(workspace:GetServerTimeNow())
			end
		end)
		return function()
			unsub()
			task.cancel(timer)
		end
	end, {})

	-- 2. Watch for changes in lastClaimedDaily to trigger the popup
	local isInitialized = useRef(false) -- Added strict initialization tracker!
	local prevClaimRef = useRef(nil)

	useEffect(function()
		if not dailyState then
			-- print(`[DailyClaimPopup] ⚠️ dailyState is nil, waiting...`)
			return
		end

		-- print(
		-- 	`[DailyClaimPopup] 🔍 Checking State... Initialized: {isInitialized.current}, Previous Claim: {prevClaimRef.current or "nil"}, Current Claim: {dailyState.lastClaimedDaily or "nil"}`
		-- )

		-- Setup initial state without triggering
		if not isInitialized.current then
			-- print(`[DailyClaimPopup] 🔧 Initializing references for the first time.`)
			isInitialized.current = true
			prevClaimRef.current = dailyState.lastClaimedDaily
			return
		end

		-- Trigger if lastClaimedDaily changes!
		if prevClaimRef.current ~= dailyState.lastClaimedDaily then
			-- print(`[DailyClaimPopup] 🚀 STATE MISMATCH DETECTED! Triggering popup!`)
			prevClaimRef.current = dailyState.lastClaimedDaily

			-- Because the slice sets day = nextDay, the day they *just* claimed is day - 1
			local newlyClaimedDay = math.max(1, dailyState.day - 1)
			-- print(
			-- 	`[DailyClaimPopup] 📅 Calculating claimed day: dailyState.day is {dailyState.day}, showing Day {newlyClaimedDay}`
			-- )

			setClaimedDay(newlyClaimedDay)
			setStartTime(workspace:GetServerTimeNow())
			setIsActive(true)
			SoundController.Sound("Strike Up the Band (sting)")

			-- This perfectly closes the DailyPanel out of the way!
			UIState.toggle("none")
		else
			-- print(`[DailyClaimPopup] 🛑 State updated, but lastClaimedDaily did not change.`)
		end
	end, { dailyState })

	local visMap = React.useCallback(function(t)
		if not startTime then
			return false
		end
		if workspace:GetServerTimeNow() > startTime + 1 then
			return true
		end
		return false
	end, { startTime })

	-- 3. Prepare the ingredients mapping
	local ingredients = {}
	if isActive then
		local n = #DailyConfig
		local actualDay = claimedDay
		if n > 0 then
			actualDay = ((claimedDay - 1) % n) + 1
		end

		local currentRewards = DailyConfig[actualDay] or {}
		local i = 1

		for ingredientId, amount in currentRewards do
			if not startTime then
				continue
			end
			local config = CoffeeModule.IngredientLookup[ingredientId]

			ingredients[i .. ingredientId] = e("ImageLabel", {
				BackgroundTransparency = 1,
				Size = t:map(delayedRevealSizeMap(startTime, 0.6 + INTER_DELAY * i, UDim2.new(0, 50, 0, 60))),
				Image = config and config.Image,
				ImageTransparency = t:map(delayedRevealTransMap(startTime, 0.6 + INTER_DELAY * i)),
			}, {
				e(SmallText, {
					Text = `{amount}x`,
					TextWrapped = true,
					TextSize = 20,
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 1, 4),
					TextXAlignment = Enum.TextXAlignment.Center,
					Size = t:map(delayedRevealSizeMap(startTime, 0.6 + INTER_DELAY * i, UDim2.new(0, 100, 0, 30))),
					TextTransparency = t:map(delayedRevealTransMap(startTime, 0.6 + INTER_DELAY * i)),
				}),
			})
			i += 1
		end
	end

	if isActive then
		return e("ScreenGui", {
			IgnoreGuiInset = true,
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		}, {
			e("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = t:map(delayedRevealTransMap(startTime, 0, 0.2)),
				ClipsDescendants = false,
				ZIndex = 1,
			}),
			e(VStack, {
				ClipsDescendants = false,
				Size = UDim2.new(1, 0, 1, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				VerticalFlex = Enum.UIFlexAlignment.None,
				HorizontalFlex = Enum.UIFlexAlignment.None,
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				-- We use the beautiful blue background from LevelUp to keep it consistent
				BackgroundImage = "rbxassetid://14197626379",
				BackgroundImageColor3 = Color3.new(0.419607, 0.505882, 0.878431),
				Spacing = UDim.new(0, 16),
				ZIndex = 10,
				BackgroundImageTransparency = t:map(delayedRevealTransMap(startTime, 0)),
			}, {
				e("UIAspectRatioConstraint", {
					AspectRatio = 1,
				}),
				e(SmallText, {
					TextTransparency = t:map(delayedRevealTransMap(startTime, 0)),
					Text = `Daily Reward Claimed!`,
					TextSize = 32,
					TextXAlignment = Enum.TextXAlignment.Center,
				}),
				e("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.XY,
				}, {
					e(VStack, {
						Size = UDim2.new(0, 0, 0, 0),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						VerticalFlex = Enum.UIFlexAlignment.None,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						AutomaticSize = Enum.AutomaticSize.XY,
						ScaleType = Enum.ScaleType.Slice,
						SliceCenter = Rect.new(8, 8, 92, 92),
						BackgroundTransparency = 1,
					}, {
						e(SmallText, {
							Text = `DAY`,
							TextTransparency = t:map(delayedRevealTransMap(startTime, 0)),
							Size = UDim2.new(1, 0, 0, 0),
							TextSize = 24,
							TextXAlignment = Enum.TextXAlignment.Center,
						}),
					}),
				}),
				e(SmallText, {
					TextTransparency = t:map(delayedRevealTransMap(startTime, 0)),
					Text = `{claimedDay}`,
					TextSize = 64,
					TextXAlignment = Enum.TextXAlignment.Center,
				}),
				e(SmallText, {
					TextTransparency = t:map(delayedRevealTransMap(startTime, 0.6)),
					Text = `Loot acquired:`,
					TextSize = 18,
					TextXAlignment = Enum.TextXAlignment.Center,
				}),

				-- HStack with Wraps = true is CRITICAL here for Day 7 (12 items)
				e(HStack, {
					AutomaticSize = Enum.AutomaticSize.XY,
					Spacing = UDim.new(0, 40),
					Size = UDim2.new(0.8, 0, 0, 0), -- Constrain width slightly to force wrap if needed
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Wraps = true,
				}, ingredients),

				e(SmallButton, {
					[React.Event.Activated] = function()
						setIsActive(false)
						setStartTime(math.huge)
					end,
					Image = "rbxassetid://127657596958436",
					ImageColor3 = Color3.new(0.933333, 0.933333, 0.184313),
					BackgroundTransparency = 1,
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(8, 8, 92, 92),
					AutomaticSize = Enum.AutomaticSize.None,
					Rounded = false,
					Visible = t:map(visMap),
					Size = t:map(delayedRevealSizeMap(startTime, 2, UDim2.new(0, 200, 0, 40))),
				}, {
					Son = e(SmallText, {
						AutomaticSize = Enum.AutomaticSize.None,
						Text = `Awesome!`,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = t:map(delayedRevealSizeMap(startTime, 2, UDim2.new(0, 200, 0, 40))),
						TextTransparency = t:map(delayedRevealTransMap(startTime, 2)),
						TextSize = 32,
						TextXAlignment = Enum.TextXAlignment.Center,
					}),
				}),
			}),
		})
	end
	return nil
end

return DailyClaimPopup
