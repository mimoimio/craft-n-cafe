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
local useBinding = React.useBinding
local useEffect = React.useEffect

-- UIState actions
local toggle = UIState.toggle
local toggleMixerInteract = UIState.toggleMixerInteract

local CashHud = require(script.Parent.CashHud)
local MixerPanel = require(script.Parent.MixerPanel)
local SettingsPanel = require(script.Parent.SettingsPanel)
local CoinVFXContainer = require(script.Parent.CoinVFXContainer)
local RecipePanel = require(script.Parent.RecipePanel)
local CafePanel = require(script.Parent.CafePanel)
local CafeBase = require(script.Parent.CafeBase)
local CafeModel = require(script.Parent.CafeModel)
local VStack = require(script.Parent.ui.VStack)
local BillboardPromptButton = require(ReplicatedStorage.Shared.ReactComponents.ui.BillboardPromptButton)

local player = game:GetService("Players").LocalPlayer
local playerId = player and tostring(player.UserId) or ""
local admin = not player or playerId == "5470482596"

local function CashOverlay(props)
	local textRef = React.useRef(nil)

	local cashRef = React.useRef(nil)
	local finalCash, setFinalCash = useState(nil)
	local activeCoins, setActiveCoins = useState({})
	local cash, setCash = useState(nil)
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

	return e("Frame", {
		Transparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
	}, {
		Cash = e(CashHud, {
			OnMount = function(rbx)
				textRef.current = rbx
			end,
			coins = finalCash,
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
	})
end
local function Main(props)
	local adminOpen, setAdminOpen = useState(false)

	return e("Frame", {
		Transparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
	}, {
		e(SmallButton, {
			RichText = true,
			Text = `<font size="12">console\n(playtest)</font>`,
			Position = UDim2.new(1, 0, 0, 0),
			AnchorPoint = Vector2.new(1, 1),
			[React.Event.Activated] = function()
				setAdminOpen(function(prev)
					return not prev
				end)
			end,
			MinTextSize = 8,
		}),
		admin and e(require(script.Parent.ConsoleApp)),
		e(require(script.Parent.CustomersOrder)),
		e(CashOverlay),
		e(Sidebar),
	})
end
function Sidebar(props)
	return e(VStack, {
		VerticalFlex = Enum.UIFlexAlignment.None,
		HorizontalFlex = Enum.UIFlexAlignment.None,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
	}, {
		e(SmallButton, {
			Size = UDim2.fromOffset(160, 40),
			AutomaticSize = Enum.AutomaticSize.None,
			[React.Event.Activated] = function()
				
			end,
		}, {
			e(VStack, {
				VerticalFlex = Enum.UIFlexAlignment.None,
				HorizontalFlex = Enum.UIFlexAlignment.None,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
			}, {
				e(SmallText, { Text = "Toggle Build" }),
			}),
		}),
	})
end

return Main
