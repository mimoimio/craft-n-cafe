-- Placeables.story.luau
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local UserInputService = game:GetService("UserInputService")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Grid = require(ReplicatedStorage.Shared.Grid)
local Types = require(ReplicatedStorage.Shared.Types)
local ViewportController = require(ReplicatedStorage.Shared.Controllers.ViewportController)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local SmallText = require(Primitives.SmallText)
local SmallButton = require(Primitives.SmallButton)
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState

local CATEGORIES = { "Architecture", "Surface", "Cashier", "Station", "Furniture", "Decoration" }

-- Serialize the configs back into valid Lua code
local function serializeConfigs(configs)
	local lines = { "return {" }
	for _, c in ipairs(configs) do
		local maxAll = c.MaxAllowed == math.huge and "math.huge" or tostring(c.MaxAllowed or math.huge)
		table.insert(lines, "\t{")
		table.insert(lines, `\t\tId = "{c.Id}",`)
		table.insert(lines, `\t\tDisplayName = "{c.DisplayName}",`)
		table.insert(lines, `\t\tCategory = "{c.Category}",`)
		table.insert(lines, `\t\tPrice = {c.Price},`)
		table.insert(lines, `\t\tUnlockLevel = {c.UnlockLevel},`)
		table.insert(lines, `\t\tMaxAllowed = {maxAll},`)
		table.insert(lines, "\t},")
	end
	table.insert(lines, "}")
	return table.concat(lines, "\n")
end

local Placeable = function(props)
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
	local localConfigs, setLocalConfigs = useState(PlaceablesModule.Array)
	local models, setModels = useState({})

	-- Attribute States
	local itemTypeAttr, setItemTypeAttr = useState("Solid")
	local placementTypeAttr, setPlacementTypeAttr = useState("Grid")

	-- Selection Listener
	useEffect(function()
		local setSelected = function()
			local selecteds = Selection:Get()
			if #selecteds == 1 and selecteds[1]:IsA("Model") then
				local sel = selecteds[1]
				Select(sel)
				-- Load attributes when selection changes
				setItemTypeAttr(sel:GetAttribute("ItemType") or "Solid")
				setPlacementTypeAttr(sel:GetAttribute("PlacementType") or "Grid")
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

	local function OnMount(model: Model)
		setModels(function(prev)
			local clone = table.clone(prev)
			clone[model] = true
			return clone
		end)
	end

	-- Current Config Editor Logic
	local selectedIndex = nil
	local currentConfig = nil
	if selected then
		for i, c in ipairs(localConfigs) do
			if c.Id == selected.Name then
				selectedIndex = i
				currentConfig = c
				break
			end
		end
	end

	local function updateConfig(field, value)
		if not selectedIndex then
			return
		end
		setLocalConfigs(function(prev)
			local nextConfigs = table.clone(prev)
			local updated = table.clone(nextConfigs[selectedIndex])
			updated[field] = value
			nextConfigs[selectedIndex] = updated
			return nextConfigs
		end)
	end

	-- 3D Rendering Calculations
	local children = {}
	local origin = CFrame.new(0, 100, 0)
	local furthestRow = 0
	local furthesCol = 0
	local currentRowsLength = 0

	for i, config in ipairs(localConfigs) do
		local prefab = ReplicatedStorage.Shared.Models:FindFirstChild(config.Id)
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
		end

		if (i % 5) == 0 then
			furthestRow += currentRowsLength + 5
			furthesCol = 0
			currentRowsLength = 0
		end
	end

	-- Helper for text inputs
	local function createInput(label, value, isNum, onFocusLost)
		return e(HStack, { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 }, {
			e(SmallText, { Text = label, Size = UDim2.new(0.4, 0, 1, 0) }),
			e("TextBox", {
				Text = tostring(value),
				Size = UDim2.new(0.6, 0, 1, 0),
				BackgroundColor3 = Color3.new(0.2, 0.2, 0.2),
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 14,
				ClearTextOnFocus = false,
				[React.Event.FocusLost] = function(rbx, enterPressed)
					local val = rbx.Text
					if isNum then
						val = tonumber(val) or value
					end
					onFocusLost(val)
				end,
			}),
		})
	end

	-- Evaluate Action Buttons dynamically based on selection state
	local modelInShared = selected and ReplicatedStorage.Shared.Models:FindFirstChild(selected.Name)
	local isSelectedAlreadyInFolder = selected and selected.Parent == ReplicatedStorage.Shared.Models

	local ModelActionButton = nil
	if selected and not isSelectedAlreadyInFolder then
		ModelActionButton = e(SmallButton, {
			Size = UDim2.new(1, 0, 0, 40),
			-- Orange if replacing, Blue if adding new
			BackgroundColor3 = modelInShared and Color3.new(0.8, 0.5, 0.2) or Color3.new(0.2, 0.4, 0.8),
			[React.Event.Activated] = function()
				local clone = selected:Clone()
				-- If it exists in Shared.Models, safely remove it first
				if modelInShared then
					modelInShared:Destroy()
				end
				clone.Parent = ReplicatedStorage.Shared.Models
				Selection:Set({ clone }) -- Selects the new version inside Shared.Models
			end,
		}, {
			e(SmallText, {
				Text = modelInShared and "Replace in Shared.Models" or "Clone to Shared.Models",
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
		})
	end

	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	}, {
		-- Left Panel: The Editor
		EditorPanel = e(VStack, {
			Size = UDim2.new(0, 300, 1, 0),
			BackgroundColor3 = Color3.new(0.1, 0.1, 0.1),
			Padding = e("UIPadding", {
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
			Spacing = UDim.new(0, 10),
			VerticalFlex = Enum.UIFlexAlignment.None,
		}, {
			Header = e(SmallText, { Text = "Config Editor", TextSize = 24, Size = UDim2.new(1, 0, 0, 30) }),

			SelectedInfo = e(SmallText, {
				Text = selected and `Selected: {selected.Name}` or "Select a Model in Explorer",
				TextColor3 = selected and Color3.new(0.4, 1, 0.4) or Color3.new(1, 0.4, 0.4),
				Size = UDim2.new(1, 0, 0, 20),
			}),

			-- Prefab Attributes Fields (Edits the physical model's attributes)
			AttributesFields = selected and e(VStack, {
				Size = UDim2.new(1, 0, 0, 90),
				Spacing = UDim.new(0, 5),
				BackgroundTransparency = 1,
			}, {
				AttrLabel = e(SmallText, {
					Text = "Prefab Attributes (Saves with Replace)",
					Size = UDim2.new(1, 0, 0, 20),
					TextColor3 = Color3.new(0.6, 0.8, 1),
				}),
				ItemTypeInput = createInput("ItemType", itemTypeAttr, false, function(v)
					if selected then
						selected:SetAttribute("ItemType", v)
						setItemTypeAttr(v)
					end
				end),
				PlacementTypeInput = createInput("PlacementType", placementTypeAttr, false, function(v)
					if selected then
						selected:SetAttribute("PlacementType", v)
						setPlacementTypeAttr(v)
					end
				end),
			}) or nil,

			-- Action: Add or Replace in Shared.Models
			CloneOrReplaceAction = ModelActionButton,

			-- Action: Add to Config
			AddConfigAction = (selected and modelInShared and not currentConfig) and e(SmallButton, {
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundColor3 = Color3.new(0.2, 0.6, 0.2),
				[React.Event.Activated] = function()
					setLocalConfigs(function(prev)
						local nextConfigs = table.clone(prev)
						table.insert(nextConfigs, {
							Id = selected.Name,
							DisplayName = selected.Name,
							Category = "Decoration",
							Price = 100,
							UnlockLevel = 1,
							MaxAllowed = math.huge,
						})
						return nextConfigs
					end)
				end,
			}, {
				e(SmallText, { Text = "Add to Config", HorizontalAlignment = Enum.HorizontalAlignment.Center }),
			}) or nil,

			-- Config Editor Fields
			EditorFields = currentConfig and e(VStack, {
				Size = UDim2.new(1, 0, 0, 200),
				Spacing = UDim.new(0, 5),
				BackgroundTransparency = 1,
			}, {
				NameInput = createInput("Display Name", currentConfig.DisplayName, false, function(v)
					updateConfig("DisplayName", v)
				end),
				PriceInput = createInput("Price", currentConfig.Price, true, function(v)
					updateConfig("Price", v)
				end),
				LevelInput = createInput("Unlock Level", currentConfig.UnlockLevel, true, function(v)
					updateConfig("UnlockLevel", v)
				end),
				MaxInput = createInput(
					"Max Allowed",
					currentConfig.MaxAllowed == math.huge and -1 or currentConfig.MaxAllowed,
					true,
					function(v)
						updateConfig("MaxAllowed", v == -1 and math.huge or v)
					end
				),

				CategoryCycler = e(HStack, { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 }, {
					e(SmallText, { Text = "Category", Size = UDim2.new(0.4, 0, 1, 0) }),
					e(SmallButton, {
						Size = UDim2.new(0.6, 0, 1, 0),
						[React.Event.Activated] = function()
							local currentIndex = table.find(CATEGORIES, currentConfig.Category) or 1
							local nextIndex = (currentIndex % #CATEGORIES) + 1
							updateConfig("Category", CATEGORIES[nextIndex])
						end,
					}, {
						e(
							SmallText,
							{ Text = currentConfig.Category, HorizontalAlignment = Enum.HorizontalAlignment.Center }
						),
					}),
				}),

				RemoveBtn = e(SmallButton, {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundColor3 = Color3.new(0.8, 0.2, 0.2),
					[React.Event.Activated] = function()
						setLocalConfigs(function(prev)
							local nextConfigs = table.clone(prev)
							table.remove(nextConfigs, selectedIndex)
							return nextConfigs
						end)
					end,
				}, {
					e(
						SmallText,
						{ Text = "Remove from Config", HorizontalAlignment = Enum.HorizontalAlignment.Center }
					),
				}),
			}) or nil,

			-- Raw Output
			OutputLabel = e(SmallText, {
				Text = "Raw Config (Copy Paste this!)",
				Size = UDim2.new(1, 0, 0, 20),
				TextColor3 = Color3.new(1, 1, 0),
			}),
			OutputString = e("TextBox", {
				Size = UDim2.new(0, 200, 0, 200), -- Fills remaining space
				Text = serializeConfigs(localConfigs),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				ClearTextOnFocus = false,
				TextEditable = false,
				TextWrapped = true,
				BackgroundColor3 = Color3.new(0.05, 0.05, 0.05),
				TextColor3 = Color3.new(0.8, 0.8, 0.8),
				Font = Enum.Font.Code,
				TextSize = 12,
			}),
		}),

		-- 3D Workspace Portal
		ReactRoblox.createPortal({ e("Folder", { Name = "Placeables Folder" }, children) }, workspace),
	})
end

local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	root:render(e(App))
	ViewportController.initialize()

	return function()
		root:unmount()
		ViewportController.cleanup()
		GlobalState:resetState()
		UIState:resetState()
	end
end

return story
