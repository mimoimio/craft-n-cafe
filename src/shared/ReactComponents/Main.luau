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
local BuildersIcon = require(script.Parent.Parent.Utils.BuildersIcon)
local useInputDevice = require(script.Parent.Parent.Hooks.useInputDevice)

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
local UserInputService = game:GetService("UserInputService")
local playerId = player and tostring(player.UserId) or "MockUser"
local admin = not player or playerId == "5470482596"

local function MainMenu(props)
	local cafeBase, setCafeBase = useState(nil)

	-- 1. Listen for the CafeBase to be loaded by the background component
	useEffect(function()
		local unsub = UIState:subscribe(function(state: UIState.UIState)
			return state.cafeBase
		end, function(newCafeBase)
			setCafeBase(newCafeBase)
		end)

		local initialBase = UIState:getState().cafeBase

		setCafeBase(initialBase)
		return unsub
	end, {})

	local buttonRef = React.useRef(nil)
	-- 2. Once the CafeBase is found, snap the camera to it
	useEffect(function()
		if not cafeBase then
			return
		end

		local cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Scriptable

		-- Zoom explicitly to THIS player's assigned plot, not the whole map
		local cf: CFrame, s: Vector3 = cafeBase:GetBoundingBox()
		local newcamcf = CFrame.new((cf:ToWorldSpace(CFrame.new(-s.X, s.Y, -s.Z))).Position, cf.Position)
		cam:PivotTo(newcamcf)
		cam:ZoomToExtents(cf, s)

		local controls

		local controlPromise = Promise.defer(function(resolve, reject, onCancel)
			if not player then
				return reject("not player")
			end

			local playerScripts = player:WaitForChild("PlayerScripts", 10)
			if not playerScripts then
				return reject("PlayerScripts timeout")
			end

			local playerModuleScript = playerScripts:WaitForChild("PlayerModule", 10)
			if not playerModuleScript then
				return reject("PlayerModule timeout")
			end

			local playerModule = require(playerModuleScript)
			return resolve(playerModule)
		end)
			:andThen(function(playerModule)
				controls = playerModule:GetControls()
				controls:Disable()
			end)
			:catch(function(err)
				warn("[Main] ControlPromise Error:", err)
			end)

		if player then
			local loadingScreen = player.PlayerGui:FindFirstChild("LoadingScreen")
			if loadingScreen then
				task.delay(1, function()
					if loadingScreen.Parent then
						loadingScreen:Destroy()
						GuiService.SelectedObject = buttonRef.current
					end
				end)
			else
			end
		end

		return function()
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
	local OnMount = React.useCallback(function(rbx: GuiObject)
		if not (rbx and rbx:FindFirstAncestorWhichIsA("PlayerGui")) then
			return
		end
		GuiService.SelectedObject = rbx
	end, {})
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
			BackgroundColor3 = cafeBase and Color3.new(0.2, 0.7, 0.2) or Color3.new(0.4, 0.4, 0.4),
			[React.Event.Activated] = function()
				if cafeBase then
					Remotes.Play:FireServer()
				end
			end,
			OnMount = OnMount,
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
		return nil
	end
	return e(require(script.Parent.Tutorial))
end

local function PlayPhase(props)
	local panel, setPanel = useBinding("none")
	useEffect(function()
		local unsub = UIState:subscribe(function(state: UIState.UIState)
			return state.panel
		end, setPanel)
		local conn = UserInputService.InputBegan:Connect(function(io: InputObject, gp: boolean)
			if io.KeyCode == Enum.KeyCode.ButtonY then
				GuiService.SelectedObject = UIState:getState().settingsButton
			elseif io.KeyCode == Enum.KeyCode.ButtonB then
				UIState.toggle("none")
			end
		end)
		return function()
			conn:Disconnect()
			unsub()
		end
	end, {})
	local currentInput = useInputDevice()
	local gamepad = currentInput == "Gamepad"
	return e("Frame", {
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
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 24),
			}),
			gamepad and e(SmallText, {
				Text = `{BuildersIcon.GetPromptText(Enum.KeyCode.ButtonY, currentInput)} Menu`,
				RichText = true,
				TextSize = 34,
				Visible = panel:map(function(panel)
					return panel == "none"
				end),
			}),
			gamepad and e(SmallText, {
				Text = `{BuildersIcon.GetPromptText(Enum.KeyCode.ButtonB, currentInput)} Close`,
				RichText = true,
				TextSize = 34,
				Visible = panel:map(function(panel)
					return panel ~= "none"
				end),
			}),
		}),
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
	})
end

local function Main(props)
	local playerPhase, setPlayerPhase = useState("mainMenu")

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			local stats = state.Stats[playerId]
			local phase = stats and stats.PlayerPhase or "mainMenu"
			return phase
		end, function(newPhase)
			setPlayerPhase(newPhase)
		end)

		local state = GlobalState:getState()
		local stats = state.Stats[playerId]
		local initialPhase = stats and stats.PlayerPhase or "mainMenu"

		setPlayerPhase(initialPhase)

		return unsub
	end, {})

	return e(React.Fragment, {}, {
		CafeBaseLoader = e(CafeBase),

		MenuPhase = (playerPhase == "mainMenu") and e(MainMenu) or nil,

		PlayPhase = (playerPhase == "playing") and e(PlayPhase) or nil,
	})
end

return Main
