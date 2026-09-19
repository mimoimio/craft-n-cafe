-- Placeables.story.luau
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Grid = require(ReplicatedStorage.Shared.Grid)
local Types = require(ReplicatedStorage.Shared.Types)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ViewportController = require(ReplicatedStorage.Shared.Controllers.ViewportController)
local Main = require(ReplicatedStorage.Shared.ReactComponents.Main)
local PlotConfig = require(ReplicatedStorage.Shared.Configs.PlotConfig:Clone())

local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)
local InputAdapter = require(ReplicatedStorage.Shared.Controllers.InputAdapter)

local CafeRenderingService = require(ServerScriptService.Server.Services.CafeRenderingService)
local playersPlotString

local Placeable = function(props: {
	PrefabCFrame: CFrame,
	Prefab: Model,
	Config: Types.PlaceableConfig,
	CFrame: CFrame,
	Size: Vector3,
})
	local part, setPart = useState(nil)
	useEffect(function()
		if not (props.Config and part) then
			return
		end
		local prefab = props.Prefab
		local clone: Model = prefab:Clone()
		part:PivotTo(props.PrefabCFrame)
		local originalParent = part.Parent
		part.Parent = clone
		local originalPrimaryPart = clone.PrimaryPart
		clone.PrimaryPart = part
		clone:PivotTo(props.CFrame)
		clone.PrimaryPart = originalPrimaryPart
		part.Parent = originalParent
		clone.Parent = originalParent
		props.OnMount(clone)
		part.Size = Vector3.zero
		return function()
			clone:Destroy()
		end
	end, { props.Config, part })
	return e("Part", {
		CFrame = props.CFrame,
		Size = props.Size,
		Transparency = 1,
		ref = setPart,
	})
end

local App = function()
	local selected: Instance, Select = useState(nil)
	useEffect(function()
		local setSelected = function()
			local selecteds = Selection:Get()
			if #selecteds == 1 then
				Select(selecteds[1])
			else
				Select(nil)
			end
		end
		local conn = Selection.SelectionChanged:Connect(setSelected)
		setSelected()
		return function()
			conn:Disconnect()
		end
	end, {})
	local children = {}
	local origin = CFrame.new(0, 100, 0)
	local furthestRow = 0
	local furthesCol = 0
	local currentRowsLength = 0
	local models, setModels = useState({})
	local function OnMount(model: Model)
		setModels(function(prev)
			local clone = table.clone(prev)
			clone[model] = true
			return clone
		end)
	end
	local selectedModelFromList, idTaken
	if models[selected] then
		selectedModelFromList = selected
	end
	for i, config in PlaceablesModule.Array do
		local prefab = ReplicatedStorage.Shared.Models:FindFirstChild(config.Id)
		idTaken = idTaken or selected and selected.Name == config.Id or nil
		if prefab then
			local cf, s = Grid.getModelBounds(prefab)
			currentRowsLength = math.max(currentRowsLength, s.Z)
			furthesCol += s.X / 2
			local newCF = origin + Vector3.new(furthesCol, s.Y / 2, furthestRow + s.Z / 2)
			furthesCol += s.X / 2 + 5
			children[config.Id] = e(Placeable, {
				PrefabCFrame = cf,
				Prefab = prefab,
				Config = config,
				CFrame = newCF,
				Size = s,
				OnMount = OnMount,
			})
		else
			-- warn("PREFAB FOR", config.Id, "NOT FOUND")
		end

		if (i % 5) == 0 then
			furthestRow += currentRowsLength + 5
			furthesCol = 0
			currentRowsLength = 0
		end
	end

	return e(SmallText, {
		-- Text = string.rep(selected and selected.Name .. ", " or "", 300),
		Text = selectedModelFromList and selectedModelFromList.Name
			or selected and `{idTaken and `ID Taken, ` or ""}not from list:\n{selected.Name}`
			or "...",
		TextXAlignment = Enum.TextXAlignment.Center,
		AutomaticSize = Enum.AutomaticSize.None,
		Size = UDim2.new(0, 200, 0, 200),
		AnchorPoint = Vector2.new(0, 0),
		TextWrapped = true,
	}, {
		e("TextBox", {
			BackgroundTransparency = 0.8,
			Selectable = true,
			TextEditable = false,
			Font = "FredokaOne",
			TextSize = 18,
			Size = UDim2.new(0, 200, 0, 200),
			Position = UDim2.new(0, 0, 0, 200),
			AnchorPoint = Vector2.new(0, 0),
		}),
		ReactRoblox.createPortal({ e("Folder", { Name = "Placeables Folder" }, children) }, workspace),
	})
end

local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	root:render(e(App))
	ViewportController.initialize()

	return function()
		local playerId = "MockUser"
		local PlotTemplate = ServerStorage:FindFirstChild("PlotTemplate")
		if PlotTemplate and playersPlotString then
			PlotTemplate.Source = `return \{\n{playersPlotString}\n}`
		end

		root:unmount()
		ViewportController.cleanup()
		GlobalState:resetState()
		UIState:resetState()
	end
end

return story
