local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CashHud = require(ReplicatedStorage.Shared.ReactComponents.CashHud)
local CoinVFXContainer = require(ReplicatedStorage.Shared.ReactComponents.CoinVFXContainer)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or "MockUser"


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

return CashOverlay