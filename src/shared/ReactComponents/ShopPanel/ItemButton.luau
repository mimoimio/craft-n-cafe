-- Shared/ReactComponents/BuildPanel/CategoryRow.luau
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage.Packages.React)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local Reflex = require(ReplicatedStorage.Packages.Reflex)

local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local PlacementController = require(ReplicatedStorage.Shared.Controllers.PlacementController)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)
local PaintConfig = require(ReplicatedStorage.Shared.Configs.PaintConfig)
local Types = require(ReplicatedStorage.Shared.Types)
local BuildersIcon = require(ReplicatedStorage.Shared.Utils.BuildersIcon)
local RedDot = require(script.Parent.Parent.RedDot).RedDot

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local Grid = require(Primitives.Grid)
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local Padding = require(Primitives.Padding)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local function ItemButton(props: {
	isSelected: boolean,
	isLocked: boolean,
	maxed: boolean?,
	config: Types.PlaceableConfig,
	mobile: boolean,
	cleared: boolean,
	selectingCategory: React.ReactBinding<boolean>?,
	Visible: boolean?,
	OnMount: ((GuiObject) -> ())?,
})
	local itemId = props.config.Id
	local isSelected = props.isSelected
	local isLocked = props.isLocked
	local currentCamera: Camera, setCurrentCamera = useState(nil)
	local worldModel, setWorldModel = useState(nil)
	local modelClone, setModelClone = useState(nil)
	local mobile = props.mobile

	useEffect(function()
		if not worldModel then
			return
		end
		local prefab = ReplicatedStorage.Shared.Models:FindFirstChild(itemId)
		if not prefab then
			return
		end

		local clone = prefab:Clone()
		clone:PivotTo(CFrame.new(Vector3.zero))
		clone.Parent = worldModel
		setModelClone(clone)

		return function()
			clone:Destroy()
			setModelClone(nil)
		end
	end, { worldModel })

	useEffect(function()
		if not (worldModel and currentCamera and modelClone) then
			return
		end
		currentCamera:ZoomToExtents(modelClone:GetBoundingBox())
	end, { worldModel, currentCamera, modelClone })

	return e(SmallButton, {
		Size = UDim2.new(0, mobile and 60 or 80, 0, mobile and 60 or 80),
		AutomaticSize = Enum.AutomaticSize.None,
		[React.Event.Activated] = props[React.Event.Activated],
		-- BackgroundColor3 = isSelected and Color3.new(0.2, 0.6, 0.2) or nil,
		LayoutOrder = props.config.UnlockLevel,
		Padding = { All = UDim.new() },
		-- Image = "rbxassetid://76169596898587",

		Rounded = false,
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(8, 8, 92, 92),
		Visible = props.Visible,
		OnMount = props.OnMount,
		Selectable = props.selectingCategory and props.selectingCategory:map(function(is)
			return not is
		end) or nil,
	}, {
		e("ImageLabel", {
			ZIndex = 1,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			AnchorPoint = Vector2.one * 0.5,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			-- ImageColor3 = isSelected and Color3.new(0, 1, 0) or nil,
			Image = isSelected and "rbxassetid://92291108480114" or "rbxassetid://77002938843500",
		}, { e("UIScale", { Scale = isSelected and 1.1 or 1 }) }),
		stroke = e("UIStroke", { Thickness = isSelected and 2 or 0 }),
		-- Make reddot cleared when GuiService.SelectedObject == this.
		reddot = not props.cleared and e(RedDot, { Position = UDim2.new(1, -8, 0, 8), SizeNum = 48 }),
		e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = isLocked and 0.5 or props.maxed and 0.8 or 1,
			ZIndex = 4,
			Visible = isLocked or props.maxed,
		}, {
			e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			e(SmallText, {
				Text = isLocked and "🔒" or "",
				TextSize = 24,
				Size = UDim2.fromScale(1, 1),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
		}) or nil,

		e("ViewportFrame", {
			ZIndex = 1,
			CurrentCamera = currentCamera,
			Size = UDim2.new(1, 0, 1, 0),
			LightDirection = Vector3.new(0, -1, -1),
			BackgroundTransparency = 1,
			Active = false,
			ImageTransparency = isLocked and 0.5 or 0,
		}, {
			World = e("WorldModel", { ref = setWorldModel }, {
				Camera = e("Camera", {
					ref = setCurrentCamera,
					CFrame = CFrame.new(Vector3.new(20, 20, -20), Vector3.zero),
					FieldOfView = 45,
				}),
			}),
		}),
	})
end
return ItemButton
