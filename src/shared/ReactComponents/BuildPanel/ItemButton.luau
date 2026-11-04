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
	config: Types.PlaceableConfig,
	count: number,
	mobile: boolean,
	Visible: boolean,
	OnMount: ((GuiObject) -> ())?,
})
	local itemId = props.config.Id
	local isSelected = props.isSelected
	local count = props.count
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
		-- Size = UDim2.new(0, mobile and 60 or 80, 0, mobile and 60 or 80),
		Size = UDim2.fromOffset(80, 80),
		AutomaticSize = Enum.AutomaticSize.None,
		[React.Event.Activated] = function()
			UIState.selectBuildItem(itemId)
		end,
		-- BackgroundColor3 = isSelected and Color3.new(0, 1, 0) or nil,
		BackgroundTransparency = 1,
		Padding = { All = UDim.new() },
		Visible = props.Visible,
		OnMount = props.OnMount,
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
		e("ViewportFrame", {
			ZIndex = 2,
			CurrentCamera = currentCamera,
			Size = UDim2.new(1, 0, 1, mobile and -6 or -12),
			LightDirection = Vector3.new(0, -1, -1),
			BackgroundTransparency = 1,
			Active = false,
			ImageTransparency = 0,
		}, {
			World = e("WorldModel", {
				ref = setWorldModel,
			}, {
				Camera = e("Camera", {
					ref = setCurrentCamera,
					CFrame = CFrame.new(Vector3.new(20, 20, -20), Vector3.zero),
					FieldOfView = 45,
				}),
			}),
		}),
		e(SmallText, {
			TextSize = 10,
			Text = `{props.config.DisplayName}`,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			TextWrapped = true,
			ZIndex = 3,
			AutomaticSize = Enum.AutomaticSize.None,
			Size = UDim2.new(1, 0, 1, mobile and -6 or -12),
		}),
		e(SmallText, {
			TextSize = mobile and 12 or 20,
			Text = `x{count}`,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			TextWrapped = true,
			ZIndex = 3,
			AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2.new(0, 8, 0, 0),
		}),
	})
end
return ItemButton
