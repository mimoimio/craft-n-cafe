-- Shared/ReactComponents/Main.luau
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage.Packages.React)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local ShopCycle = require(ReplicatedStorage.Shared.ShopCycle)
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

-- UIState actions
local toggle = UIState.toggle
local toggleMixerInteract = UIState.toggleMixerInteract

local CashHud = require(script.Parent.CashHud)
local MixerPanel = require(script.Parent.MixerPanel)
local IngredientShopPanel = require(script.Parent.IngredientShopPanel)
local SettingsPanel = require(script.Parent.SettingsPanel)
local CoinVFXContainer = require(script.Parent.CoinVFXContainer)
local RecipePanel = require(script.Parent.RecipePanel)
local CafePanel = require(script.Parent.CafePanel)
local MixerManager = require(script.Parent.MixerManager)
local CustomerManager = require(script.Parent.CustomerManager)
local Spawner = require(script.Parent.Spawner)
local TableManager = require(script.Parent.TableManager)
local Mailbox = require(script.Parent.Mailbox)
local CafeBase = require(script.Parent.CafeBase)
local VStack = require(script.Parent.ui.VStack)

local player = game.Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""

local onMountShopButton = UIState.setShopButton
local onMountCafeButton = UIState.setCafeButton

local function Main(props)
	local admin, setAdmin = useState(false)
	local tutorialDone, setTutorialDone = useState((player and nil) or (not player and false))

	local textRef = React.useRef(nil)

	local cashRef = React.useRef(nil)
	local finalCash, setFinalCash = useState(nil)
	local activeCoins, setActiveCoins = useState({})

	local cash, setCash = useState(nil)

	local closeAllPanels = React.useCallback(function()
		toggle("none")
	end, {})
	local time, setTime = React.useBinding("")

	useEffect(function()
		local unsub = GlobalState:subscribe(function(newState: GlobalState.GlobalState)
			local playersStats = newState.Stats[playerId]
			if playersStats then
				setTutorialDone(playersStats.TutorialCompleted or false)
			end
		end)

		local newState = GlobalState:getState()
		local playersStats = newState.Stats[playerId]
		if playersStats then
			setTutorialDone(playersStats.TutorialCompleted or false)
		end

		return unsub
	end, {})

	useEffect(function()
		local unsub = GlobalState:subscribe(function(newState: GlobalState.GlobalState)
			local playersStats = newState.Stats[playerId]
			if playersStats and playersStats.Cash then
				setCash(playersStats.Cash)
			end
		end)

		local newState = GlobalState:getState()
		local playersStats = newState.Stats[playerId]
		if playersStats and playersStats.Cash then
			setCash(playersStats.Cash)
		end

		return unsub
	end, {})

	-- Handle Cash & VFX updates
	useEffect(function()
		if not cash then
			return
		end

		if not cashRef.current then
			cashRef.current = cash
			setFinalCash(cash)
			return
		end

		local id = tostring(tick())
		local diff = cash - cashRef.current

		if diff <= 0 then
			setFinalCash(cash)
			cashRef.current = cash
			return
		end

		setActiveCoins(function(prevCoins)
			local nextCoins = table.clone(prevCoins)
			local done
			for i = 1, 2 do
				nextCoins[id .. i] = {
					id = id .. i,
					amount = (not done) and (cash - cashRef.current) or nil,
					startPos = workspace.CurrentCamera.ViewportSize / 2,
					hudPos = textRef.current
							and textRef.current.AbsolutePosition + textRef.current.AbsoluteSize / 2 + GuiService:GetGuiInset()
						or nil,
				}
				done = true
			end

			cashRef.current = cash
			return nextCoins
		end)
	end, { cash })

	useEffect(function()
		local t = task.spawn(function()
			while task.wait(0.5) do
				local cycle = ShopCycle.getCurrentState()
				setTime(
					-- `seed({cycle.seed}), timeLeft({cycle.timeLeft // 1}), timeToSpecial({cycle.timeToSpecial // 1})`
					`Shop refreshes in: {cycle.timeLeft // 60}m {cycle.timeLeft // 1 % 60}s\nSpecial Event in: {cycle.timeToSpecial // 60}m {cycle.timeToSpecial // 1 % 60}s`
				)
			end
		end)
		return function()
			task.cancel(t)
		end
	end, {})

	local timehud = e(require(script.Parent.ui.SmallText), {
		Text = time,
		AutomaticSize = Enum.AutomaticSize.XY,
		Position = UDim2.new(1, 0, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
	})

	-- local upgradeCafeTutorial = cash > 400 and not UpgradeCafeCompleted

	return e("Frame", {
		Transparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
	}, {
		-- Background Manager mapping to the 3D world (Invisible)
		MixerManager = e(MixerManager),
		CustomerManager = e(CustomerManager),
		Spawner = e(Spawner),
		Tables = e(TableManager),
		Mailbox = e(Mailbox),
		CafeBase = e(CafeBase),

		-- Active Panel Overlay
		ActiveOverlay = e("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, {
			-- Shop = e(IngredientShopPanel, {
			-- 	OnClose = closeAllPanels,
			-- }),
			Settings = e(SettingsPanel, {
				OnClose = closeAllPanels,
			}),
			Mixer = e(MixerPanel, {
				OnClose = closeAllPanels,
			}),
			Recipes = e(RecipePanel, {
				OnClose = closeAllPanels,
			}),
			CafePanel = e(CafePanel, {
				OnClose = closeAllPanels,
			}),
		}),

		-- HUD Elements
		Cash = e(CashHud, {
			OnMount = function(rbx)
				textRef.current = rbx
			end,
			coins = finalCash,
		}),
		Bonus = e(require(script.Parent.BonusHud)),
		timehud = timehud,

		Top = e(HStack, {
			Position = UDim2.new(0.5, 0, 0, 1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(),
			AutomaticSize = Enum.AutomaticSize.XY,
			Spacing = UDim.new(0, 8),
		}, {
			-- ShopButton = e(SmallButton, {
			-- 	BackgroundTransparency = 1,
			-- 	TextSize = 32,
			-- 	ScaleType = Enum.ScaleType.Slice,
			-- 	SliceCenter = Rect.new(8, 8, 92, 92),
			-- 	Size = UDim2.new(0, 160, 0, 40),
			-- 	Image = "rbxassetid://127657596958436",
			-- 	Rounded = false,
			-- 	[React.Event.Activated] = function()
			-- 		Players.LocalPlayer.Character:PivotTo(workspace.Shop:GetPivot())
			-- 		UIState.toggle("none")
			-- 		RunService.RenderStepped:Wait()
			-- 		workspace.CurrentCamera:PivotTo(
			-- 			CFrame.new(
			-- 				workspace.CurrentCamera:GetPivot().Position,
			-- 				workspace.Shop.Building:GetPivot().Position - Vector3.new(0, 3, 0)
			-- 			)
			-- 		)
			-- 	end,
			-- 	ImageColor3 = Color3.new(1, 0.2, 0.2),
			-- 	OnMount = onMountShopButton,
			-- 	LayoutOrder = 1,
			-- }, {
			-- 	e(SmallText, {
			-- 		Text = "Shop",
			-- 		Size = UDim2.new(1, 0, 1, 0),
			-- 		BackgroundTransparency = 1,
			-- 		TextWrapped = true,
			-- 		TextSize = 32,
			-- 		AutomaticSize = Enum.AutomaticSize.None,
			-- 		TextXAlignment = Enum.TextXAlignment.Center,
			-- 		TextYAlignment = Enum.TextYAlignment.Center,
			-- 	}, {}),
			-- }),
			Cafe = e(SmallButton, {
				LayoutOrder = 2,
				BackgroundTransparency = 1,
				TextSize = 32,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(8, 8, 92, 92),
				Size = UDim2.new(0, 160, 0, 40),
				Image = "rbxassetid://127657596958436",
				Rounded = false,
				[React.Event.Activated] = function()
					local cf, s = UIState:getState().cafeBase.Cafe:GetBoundingBox()
					Players.LocalPlayer.Character:PivotTo(cf)
					UIState.toggle("none")
				end,
				ImageColor3 = Color3.new(0, 1, 0.368627),
				OnMount = onMountCafeButton,
			}, {
				e(SmallText, {
					Text = "Cafe",
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					TextWrapped = true,
					TextSize = 32,
					AutomaticSize = Enum.AutomaticSize.None,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
				}, {}),
			}),
			-- Restock = e(SmallButton, {
			-- 	LayoutOrder = 2,
			-- 	BackgroundTransparency = 1,
			-- 	TextSize = 32,
			-- 	ScaleType = Enum.ScaleType.Slice,
			-- 	SliceCenter = Rect.new(8, 8, 92, 92),
			-- 	Size = UDim2.new(0, 160, 0, 40),
			-- 	Image = "rbxassetid://127657596958436",
			-- 	Rounded = false,
			-- 	[React.Event.Activated] = function()
			-- 		Remotes.Restock:FireServer()
			-- 	end,
			-- 	ImageColor3 = Color3.new(0.960784, 0.949019, 0.352941),
			-- 	OnMount = onMountCafeButton,
			-- }, {
			-- 	e(SmallText, {
			-- 		Text = "Restock",
			-- 		Size = UDim2.new(1, 0, 1, 0),
			-- 		BackgroundTransparency = 1,
			-- 		TextWrapped = true,
			-- 		TextSize = 32,
			-- 		AutomaticSize = Enum.AutomaticSize.None,
			-- 		TextXAlignment = Enum.TextXAlignment.Center,
			-- 		TextYAlignment = Enum.TextYAlignment.Center,
			-- 	}, {}),
			-- }),
		}),
		Left = e(VStack, {
			VerticalFlex = Enum.UIFlexAlignment.None,
			HorizontalFlex = Enum.UIFlexAlignment.None,
			-- BackgroundColor3 = Color3.new(1, 0, 0),
			-- BackgroundTransparency = 0,
			Spacing = UDim.new(0, 8),
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.new(0, 0, 0, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
		}, {
			CafeButton = e(SmallButton, {
				LayoutOrder = 1,
				BackgroundTransparency = 1,
				TextSize = 32,
				Image = "rbxassetid://122526927441389",
				Size = UDim2.new(0, 50, 0, 50),
				[React.Event.Activated] = function()
					toggle("cafe")
				end,
			}),
			SettingsButton = e(SmallButton, {
				LayoutOrder = 2,
				BackgroundTransparency = 1,
				Image = "rbxassetid://135990132441809",
				TextSize = 32,
				Size = UDim2.new(0, 50, 0, 50),
				[React.Event.Activated] = function()
					toggle("settings")
				end,
			}),
			recipeButton = e(SmallButton, {
				LayoutOrder = 4,
				-- Image = "rbxassetid://112161362547076",
				Text = "",
				ButtonClass = "ImageButton",
				BackgroundTransparency = 0,
				TextSize = 12,
				Size = UDim2.new(0, 50, 0, 50),
				BackgroundColor3 = Color3.new(0.5, 0.5, 0.5),
				[React.Event.Activated] = function()
					toggle("recipe")
				end,
				AutomaticSize = Enum.AutomaticSize.None,
				Padding = { All = UDim.new() },
			}, {
				e("Frame", {
					Size = UDim2.new(0, 50, 0, 46),
					BackgroundColor3 = Color3.new(0.8, 0.8, 0.8),
				}, {
					UIStroke = e("UIStroke", {
						Thickness = 2,
						BorderStrokePosition = Enum.BorderStrokePosition.Inner,
						Color = Color3.new(0.6, 0.6, 0.6),
					}),
					UICorner = e("UICorner", {
						CornerRadius = UDim.new(0, 8),
					}),

					e(SmallText, {
						Text = "Recipe",
						Size = UDim2.new(0, 50, 0, 46),
						BackgroundTransparency = 1,
						TextWrapped = true,
						AutomaticSize = Enum.AutomaticSize.None,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextYAlignment = Enum.TextYAlignment.Center,
						TextSize = 12,
					}, {}),
				}),
				UIStroke = e("UIStroke", {
					Thickness = 2,
					Color = Color3.new(0.5, 0.5, 0.5),
					BorderStrokePosition = Enum.BorderStrokePosition.Inner,
				}),
			}),
			daylybutton = e(SmallButton, {
				LayoutOrder = 4,
				-- Image = "rbxassetid://112161362547076",
				Text = "",
				ButtonClass = "ImageButton",
				BackgroundTransparency = 0,
				TextSize = 12,
				Size = UDim2.new(0, 50, 0, 50),
				BackgroundColor3 = Color3.new(0.5, 0.5, 0.5),
				[React.Event.Activated] = function()
					toggle("daily")
				end,
				AutomaticSize = Enum.AutomaticSize.None,
				Padding = { All = UDim.new() },
			}, {
				e("Frame", {
					Size = UDim2.new(0, 50, 0, 46),
					BackgroundColor3 = Color3.new(0.8, 0.8, 0.8),
				}, {
					UIStroke = e("UIStroke", {
						Thickness = 2,
						BorderStrokePosition = Enum.BorderStrokePosition.Inner,
						Color = Color3.new(0.6, 0.6, 0.6),
					}),
					UICorner = e("UICorner", {
						CornerRadius = UDim.new(0, 8),
					}),

					e(SmallText, {
						Text = "Daily",
						Size = UDim2.new(0, 50, 0, 46),
						BackgroundTransparency = 1,
						TextWrapped = true,
						AutomaticSize = Enum.AutomaticSize.None,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextYAlignment = Enum.TextYAlignment.Center,
						TextSize = 12,
					}, {}),
				}),
				UIStroke = e("UIStroke", {
					Thickness = 2,
					Color = Color3.new(0.5, 0.5, 0.5),
					BorderStrokePosition = Enum.BorderStrokePosition.Inner,
				}),
			}),
		}),
		CoinVFXContainer = e(CoinVFXContainer, {
			activeCoins = activeCoins,
			hudPos = Vector2.new(100, 50),
			onCoinComplete = function(completedId)
				setActiveCoins(function(prevCoins)
					local nextCoins = table.clone(prevCoins)
					local coin = nextCoins[completedId]
					if not coin then
						return prevCoins
					end

					setFinalCash(function(prev)
						SoundController.Sound("handleCoins")
						return prev + (coin.amount or 0)
					end)

					nextCoins[completedId] = nil
					-- SoundController
					return nextCoins
				end)
			end,
		}),
		e(SmallButton, {
			RichText = true,
			Text = `<font size="12">console\n(playtest)</font>`,
			Position = UDim2.new(1, 0, 0, 0),
			AnchorPoint = Vector2.new(1, 1),
			[React.Event.Activated] = function()
				setAdmin(function(prev)
					return not prev
				end)
			end,
			MinTextSize = 8,
		}),
		admin = admin and e(require(script.Parent.ConsoleApp)),
		e(require(script.Parent.DiscoveredDrink), { closeAllPanels = closeAllPanels }),
		e(require(script.Parent.LevelUp)),
		e(require(script.Parent.DailyPanel)),
		e(require(script.Parent.SpecialEvent)),
		e(require(script.Parent.DailyClaimPopup)),
		e(require(script.Parent.ShopPrompt)),
		e(require(script.Parent.UpgradePanel)),
		Tutorial = tutorialDone == false and e(require(script.Parent.Tutorial)) or nil,
	})
end

return Main
