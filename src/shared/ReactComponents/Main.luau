-- Shared/ReactComponents/Main.luau
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage.Packages.React)
local Promise = require(ReplicatedStorage.Packages.Promise)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

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
local RedDot = require(script.Parent.RedDot).RedDot

local CafeBase = require(script.Parent.CafeBase)
local CashOverlay = require(script.Parent.CashOverlay)
local EXPOverlay = require(script.Parent.EXPOverlay)
local VStack = require(script.Parent.ui.VStack)
local BuildPanel = require(script.Parent.BuildPanel)
local ShopPanel = require(script.Parent.ShopPanel)
local Sidebar = require(script.Parent.Sidebar)

local player = game:GetService("Players").LocalPlayer
local playerId = player and tostring(player.UserId) or "MockUser"
local admin = not player or playerId == "5470482596"

local function MainMenu()
	local cafeBase, setCafeBase = useState(nil)

	-- 1. Listen for the CafeBase to be loaded by the background component
	useEffect(function()
		local unsub = UIState:subscribe(function(state: UIState.UIState)
			return state.cafeBase
		end, setCafeBase)

		setCafeBase(UIState:getState().cafeBase)
		return unsub
	end, {})

	-- 2. Once the CafeBase is found, snap the camera to it
	useEffect(function()
		if not cafeBase then
			return
		end

		local cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Scriptable

		-- Zoom explicitly to THIS player's assigned plot, not the whole map
		local cf: CFrame, s: Vector3 = cafeBase:GetBoundingBox()
		local newcamcf = CFrame.new((cf + Vector3.new(-s.X, s.Y, s.Z)).Position, cf.Position)
		cam:PivotTo(newcamcf)
		cam:ZoomToExtents(cf, s)
		local controls
		local controlPromise = Promise.defer(function(resolve, reject, onCancel)
			if not player then
				return reject("not player")
			end
			local playerScripts = player:WaitForChild("PlayerScripts", 10)
			local playerModule = require(playerScripts:WaitForChild("PlayerModule", 10))

			return resolve(playerModule)
		end)
			:andThen(function(playerModule)
				-- Get the controls object
				controls = playerModule:GetControls()
				controls:Disable()
			end)
			:catch(function(err)
				warn(err)
			end)

		if player then
			local loadingScreen = player.PlayerGui:FindFirstChild("LoadingScreen")
			if loadingScreen then
				task.delay(1, function()
					loadingScreen:Destroy()
				end)
			end
		end

		return function()
			-- Explicitly lock camera back to the character when they press Play
			cam.CameraType = Enum.CameraType.Custom
			if player and player.Character then
				local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					cam.CameraSubject = humanoid
				end
			end
			controlPromise:cancel()
			if controls then
				controls:Enable()
			end
		end
	end, { cafeBase })

	return e(VStack, {
		VerticalFlex = Enum.UIFlexAlignment.None,
		HorizontalFlex = Enum.UIFlexAlignment.None,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}, {
		e(SmallText, {
			Text = cafeBase and "Cafe Builder" or "Loading Plot...",
			TextXAlignment = "Center",
		}),

		e(SmallButton, {
			-- Visual feedback so they know it's loading vs ready
			BackgroundColor3 = cafeBase and Color3.new(0.2, 0.7, 0.2) or Color3.new(0.4, 0.4, 0.4),
			[React.Event.Activated] = function()
				-- Only allow playing if the plot has been successfully loaded
				if cafeBase then
					UIState.setPlayerPhase("playing")
				end
			end,
		}, {
			e(SmallText, {
				Text = cafeBase and "Play" or "Wait",
				Size = UDim2.new(1, 0, 1, 0),
				TextYAlignment = "Center",
				TextXAlignment = "Center",
			}),
		}),
	})
end
local function Tutorial(props)
	local TutorialCompleted, setTutorialCompleted = useState(nil)
	useEffect(function()
		local unsub = GlobalState:subscribe(function(s: GlobalState.GlobalState)
			return s.Stats[playerId] and s.Stats[playerId].TutorialCompleted or nil
		end, setTutorialCompleted)
		local s = GlobalState:getState()
		setTutorialCompleted(s.Stats[playerId] and s.Stats[playerId].TutorialCompleted)

		return unsub
	end, {})
	if TutorialCompleted == true or TutorialCompleted == nil then
		return
	end
	return e(require(script.Parent.Tutorial))
end
local function Main(props)
	local playerPhase: "mainMenu" | "playing", setPlayerPhase = useState("mainMenu")

	useEffect(function()
		local unsub = UIState:subscribe(function(state: UIState.UIState)
			return state.playerPhase
		end, setPlayerPhase)

		setPlayerPhase(UIState:getState().playerPhase)
		return unsub
	end, {})

	return e(React.Fragment, {}, {
		-- Mount CafeBase loader outside the phase check so it secretly loads the plot in the background
		CafeBaseLoader = e(CafeBase),

		-- The Main Menu UI
		MenuPhase = (playerPhase == "mainMenu") and e(MainMenu) or nil,

		-- The Active Gameplay UI
		PlayPhase = (playerPhase == "playing") and e("Frame", {
			Transparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
		}, {
			admin and e(require(script.Parent.ConsoleApp)),
			e(BuildPanel),
			e(ShopPanel),
			e(Tutorial),
			e(require(script.Parent.CustomersOrder)),
			e(require(script.Parent.CustomerPrompts)),
			e(require(script.Parent.StationPrompts)),
			e(require(script.Parent.SettingsPanel)),
			e("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.XY,
			}, {
				layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 5),
				}),
				e("Frame", {
					BackgroundTransparency = 1,
					LayoutOrder = 1,
					AutomaticSize = Enum.AutomaticSize.XY,
				}, {
					layout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 5),
					}),
					e(EXPOverlay),
					e(CashOverlay),
				}),
			}),
			e(require(script.Parent.PlayersCup), {
				LayoutOrder = 2,
			}),
			e(Sidebar),
		}) or nil,
	})
end

return Main
