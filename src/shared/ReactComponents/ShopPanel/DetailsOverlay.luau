-- Shared/ReactComponents/ShopPanel/DetailsOverlay.luau
--[[
TODO: use Mionum for numbers. and prices
unrelated TODO: make level up rewards? helps on low cash moments?
]]
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local Padding = require(Primitives.Padding)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useCallback = React.useCallback

local function ItemModelViewport(props: {
	config: Types.PlaceableConfig,
	mobile: boolean?,
	ImageTransparency: number?,
})
	local itemId = props.config.Id
	local currentCamera: Camera, setCurrentCamera = useState(nil)
	local modelClone, setModelClone = useState(nil)
	local viewportFrame: ViewportFrame, setViewportFrame = useState(nil)

	useEffect(function()
		if not (viewportFrame and props.config) then
			return
		end
		local prefab = ReplicatedStorage.Shared.Models:FindFirstChild(itemId)
		if not prefab then
			return
		end

		local clone = prefab:Clone()
		clone:PivotTo(CFrame.new(Vector3.zero))
		clone.Parent = viewportFrame
		setModelClone(clone)

		return function()
			clone:Destroy()
			setModelClone(nil)
		end
	end, { viewportFrame, props.config })

	useEffect(function()
		if not (viewportFrame and currentCamera and modelClone) then
			return
		end
		currentCamera:ZoomToExtents(modelClone:GetBoundingBox())
		viewportFrame.CurrentCamera = currentCamera
	end, { viewportFrame, currentCamera, modelClone })

	local onMount = useCallback(function(rbx)
		setViewportFrame(rbx)
	end, {})

	return e("ViewportFrame", {
		ZIndex = 1,
		CurrentCamera = currentCamera,
		Size = UDim2.new(1, 0, 1, 0),
		LightDirection = Vector3.new(0, -1, -1),
		BackgroundTransparency = 1,
		Active = false,
		ImageTransparency = props.ImageTransparency,
		ref = onMount,
	}, {
		Camera = e(
			"Camera",
			{ ref = setCurrentCamera, CFrame = CFrame.new(Vector3.new(20, 20, -20), Vector3.zero), FieldOfView = 45 }
		),
	})
end
--[[

TODO: add next and previous button. still in the scope of selected tab in the itemtab. (if cashier then next means going to the item down the listed items, which means the next register)
]]
local function DetailsOverlay(props: {
	config: Types.PlaceableConfig,
	amount: { [string]: number }?,
	playerCash: number,
	locked: boolean?,
	currentInput: string?,
	mobile: boolean,
	onClose: () -> (),
})
	local config = props.config
	local totalOwned = props.amount and props.amount[config.Id] or 0
	local isMaxed = config.MaxAllowed ~= math.huge and totalOwned >= config.MaxAllowed
	local canAfford = props.playerCash >= config.Price
	local isLocked = props.locked == true

	local btnText = `Buy ( {config.Price} )`
	local btnColor = Color3.new(0.2, 0.7, 0.2)
	local canBuy = true
	local btnTextSize = props.mobile and 14 or 20

	if isLocked then
		btnText = `Unlock at Lvl {config.UnlockLevel}`
		btnColor = Color3.new(0.4, 0.4, 0.4)
		canBuy = false
	elseif isMaxed then
		btnText = "Max Limit Reached"
		btnColor = Color3.new(0.4, 0.4, 0.4)
		canBuy = false
	elseif not canAfford then
		btnText = "Get Cash"
		btnColor = Color3.new(0.8, 0.2, 0.2)
		canBuy = false
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		Active = true,
		ZIndex = 40,
	}, {
		-- return e("TextButton", {
		-- 	AutoButtonColor = false,
		-- 	Text = "",
		-- 	[React.Event.Activated] = props.onClose,
		-- 	Size = UDim2.fromScale(1, 1),
		-- 	BackgroundColor3 = Color3.new(0, 0, 0),
		-- 	BackgroundTransparency = 0.5,
		-- 	Active = true,
		-- 	ZIndex = 40,
		-- }, {
		Card = e(VStack, {
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0, props.mobile and 260 or 400, 0, 0),
			BackgroundColor3 = Color3.new(0.1, 0.1, 0.1),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BackgroundImage = "rbxassetid://99700456312840",
			BackgroundImageTransparency = 0.05,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(8, 8, 92, 92),
			VerticalFlex = Enum.UIFlexAlignment.None,
			Padding = { All = UDim.new(0, 10) },
			Spacing = UDim.new(0, 8),
			ZIndex = 41,
		}, {
			Header = e(SmallText, {
				Text = `<font size="20"><b>{config.DisplayName}</b></font>\n<font color="rgb(180,180,180)">{config.Category}</font>`,
				RichText = true,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				AutomaticSize = Enum.AutomaticSize.XY,
				ZIndex = 42,
			}),
			Image = e("ImageLabel", {
				BackgroundTransparency = 1,
				BackgroundColor3 = Color3.new(1, 1, 1),
				Size = UDim2.new(1, 0, 0, props.mobile and 100 or 200),
				ZIndex = 42,
				Image = "rbxassetid://120520009441669",
				SliceCenter = Rect.new(8, 8, 92, 92),
				ScaleType = Enum.ScaleType.Slice,
			}, {
				itemmodelviewport = e(ItemModelViewport, { config = config }),
			}),
			Stats = e(SmallText, {
				Text = `<b>Price:</b> {config.Price}\n<b>Unlock Level:</b> {config.UnlockLevel}\n<b>Owned:</b> {totalOwned} / {config.MaxAllowed == math.huge and "∞" or config.MaxAllowed}`,
				RichText = true,
				TextWrapped = false,
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundColor3 = Color3.new(0.3, 0.3, 0.3),
				AutomaticSize = Enum.AutomaticSize.XY,
				LayoutOrder = 3,
				ZIndex = 42,
			}, { padding = e(Padding) }),
			Actions = e(HStack, {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				LayoutOrder = 4,
				HorizontalFlex = "Fill",
				Spacing = UDim.new(0, 8),
				ZIndex = 42,
			}, {
				BuyButton = e(SmallButton, {
					Size = UDim2.new(1, 0, 0, props.mobile and 40 or 60),
					AutomaticSize = Enum.AutomaticSize.None,
					BackgroundColor3 = btnColor,
					LayoutOrder = 4,
					OnMount = function(rbx)
						UIState.setTutorialTarget("BuyButton", rbx)
						if rbx and props.currentInput == "Gamepad" then
							GuiService.SelectedObject = rbx
						end
					end,
					[React.Event.Activated] = function()
						if canBuy then
							Remotes.BuyItem:FireServer({
								itemId = config.Id,
								amount = 1,
							})
						elseif not isLocked and not isMaxed then
							UIState.toggle("store")
						end
					end,
					BackgroundTransparency = 1,
					Image = (isLocked or isMaxed or not canAfford) and "rbxassetid://91750414973277"
						or "rbxassetid://128846321008253",
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(50, 50, 54, 57),
					Rounded = false,
				}, {
					e(SmallText, {
						Text = btnText,
						Size = UDim2.new(1, 0, 1, 0),
						AutomaticSize = Enum.AutomaticSize.None,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextYAlignment = Enum.TextYAlignment.Center,
						TextSize = btnTextSize,
					}),
				}),
				CloseButton = e(SmallButton, {
					Size = UDim2.new(1, 0, 0, props.mobile and 40 or 60),
					AutomaticSize = Enum.AutomaticSize.None,
					BackgroundColor3 = Color3.new(0.8, 0.2, 0.2),
					LayoutOrder = 5,
					[React.Event.Activated] = props.onClose,
					BackgroundTransparency = 1,
					Image = "rbxassetid://128846321008253",
					ImageColor3 = Color3.new(1, 0.4, 0.4),
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(50, 50, 54, 57),
					Rounded = false,
				}, {
					e(Padding),
					e("ImageLabel", {
						Image = "rbxassetid://17368177673",
						Size = UDim2.new(1, 0, 1, 0),
						SizeConstraint = Enum.SizeConstraint.RelativeYY,
						BackgroundTransparency = 1,
						Position = UDim2.new(0.5, 0, 0.5, 0),
						AnchorPoint = Vector2.new(0.5, 0.5),
					}),
				}),
			}),
		}),
	})
end

return DetailsOverlay
