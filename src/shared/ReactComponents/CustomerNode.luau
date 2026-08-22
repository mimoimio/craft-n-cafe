-- Shared/ReactComponents/SlotNode.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local Promise = require(ReplicatedStorage.Packages.Promise)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local SmallButton = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallButton)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)
local useInputDevice = require(ReplicatedStorage.Shared.Hooks.useInputDevice)
local useBreakpoint = require(ReplicatedStorage.Shared.Hooks.useBreakpoint)
local BuildersIcon = require(ReplicatedStorage.Shared.Utils.BuildersIcon)
local useSpring = ReactFlow.useSpring

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState
local useRef = React.useRef

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""

local function CustomerNode(props: {
	CustomerUid: string,
	CustomerData: {
		id: string,
		customerId: string,
		drinkEntities: {
			drinkId: string,
			variationId: string?,
		},
	},
	Instance: CafeTypes.CustomerRig,
	numberInLine: number,
})
	local prompt: ProximityPrompt, setPrompt = useState(nil)
	local shown: boolean, setShown = useState(false)
	local enabled: boolean, setEnabled = useState(false)
	local currentInput = useInputDevice()
	local rotation, setRotation = useSpring({ start = 0, target = 0, damper = 0.4, speed = 10 })
	local scale, setScale = useSpring({ start = 1, target = 1, damper = 0.4, speed = 10 })
	-- 3. Render BillboardGui

	useEffect(function()
		if not (props.CustomerData and props.CustomerData.customerAction) then
			return
		end

		local action = props.CustomerData.customerAction
		if action == "paid" then
			SoundController.Sound("glass_005")
		end
	end, { props.CustomerData and props.CustomerData.customerAction })
	-- useEffect(function()
	-- 	if not (props.CustomerData and props.CustomerData.id) then
	-- 		return
	-- 	end
	-- 	SoundController.Sound("phaserUp6")
	-- end, { props.CustomerData and props.CustomerData.id })
	useEffect(function()
		if not props.Instance then
			return
		end

		local promise = Promise.defer(function(resolve, reject, onCancel)
			return resolve(props.Instance:WaitForChild("TriggerPrompt"))
		end)
			:andThen(setPrompt)
			:catch(function(err)
				warn(`customernode prompt err: {err}`)
			end)
		return function()
			promise:cancel()
		end
	end, { props.Instance })
	useEffect(function()
		if not prompt then
			return
		end
		local conn = prompt.PromptShown:Connect(function()
			setShown(true)
		end)
		local conn2 = prompt.PromptHidden:Connect(function()
			setShown(false)
		end)
		return function()
			conn:Disconnect()
			conn2:Disconnect()
		end
	end, { prompt })
	useEffect(function()
		if shown then
			setRotation({ start = 20, target = 0, damper = 0.4, speed = 40 })
			setScale({ start = 0.5, target = 1, damper = 0.4, speed = 40 })
		else
			setScale({ start = 0, target = 0, damper = 0.4, speed = 40 })
			setRotation({ start = 0, target = 0, damper = 0.4, speed = 40 })
		end
	end, { shown })
	useEffect(function()
		if not player then
			task.delay(1, function()
				setShown(true)
				task.wait(1)
				setShown(false)
			end)
		end
	end, {})
	useEffect(function()
		if not prompt then
			return
		end
		local conn = prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
			setEnabled(prompt.Enabled)
		end)
		return function()
			conn:Disconnect()
		end
	end, { prompt })
	local interactIcon = prompt
			and BuildersIcon.GetPromptText(
				currentInput == "Gamepad" and prompt.GamepadKeyCode or prompt.KeyboardKeyCode,
				currentInput
			)
		or BuildersIcon.GetPromptText(
			currentInput == "Gamepad" and Enum.KeyCode.ButtonX or Enum.KeyCode.E,
			currentInput
		)

	local xs, sm, md, lg, xl = useBreakpoint()
	local mobile = xs or sm

	-- warn(`no. {props.numberInLine}\n(props.Instance ({props.Instance}) and prompt ({prompt}) and shown ({shown}))`)
	return if (props.Instance and prompt and shown and enabled or not player)
		then e(React.Fragment, nil, {
			btn = e(SmallButton, {
				Text = `{interactIcon} Tend Customer`,
				Position = mobile and UDim2.new(1, -200, 1, -100) or UDim2.new(0.5, 200, 0.5, 0),
				Rotation = rotation,
				AnchorPoint = Vector2.new(0.5, 0.5),
				[React.Event.MouseButton1Down] = function()
					if prompt then
						prompt:InputHoldBegin()
					end
				end,
				[React.Event.MouseButton1Up] = function()
					if prompt then
						prompt:InputHoldEnd()
					end
				end,
				TextSize = scale:map(function(n)
					return n * 18
				end),
				RichText = true,
			}, { e("UIScale", {
				Scale = scale,
			}) }),
			highlight = ReactRoblox.createPortal(
				e("Highlight", {
					Adornee = props.Instance,
					FillColor = Color3.new(1, 1, 1),
					FillTransparency = 0.9,
				}),
				props.Instance
			),
		})
		else nil
end

return CustomerNode
