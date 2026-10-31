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
local useRef = React.useRef

-- =====================================================================
-- 1. GRID PLACEABLE COMPONENT (Spawns the item into workspace)
-- =====================================================================
local Placeable = function(props)
	local part, setPart = useState(nil)
	local cloneRef = useRef(nil)

	-- Create & destroy the physical model
	useEffect(function()
		if not (props.Prefab and part) then
			return
		end
		local clone = props.Prefab:Clone()
		cloneRef.current = clone

		-- Tag this anchor part so we know to delete it when saving!
		-- part:SetAttribute("IsReactAnchor", true)

		local originalParent = part.Parent
		part.Parent = clone
		clone.Parent = originalParent

		props.OnMount(clone)
		part.Size = Vector3.zero

		return function()
			clone:Destroy()
			cloneRef.current = nil
		end
	end, { props.Prefab, part })

	-- Update the CFrame dynamically
	useEffect(function()
		local clone = cloneRef.current
		if not (clone and part and props.CFrame) then
			return
		end

		part:PivotTo(props.PrefabCFrame)
		local originalPrimaryPart = clone.PrimaryPart
		clone.PrimaryPart = part
		clone:PivotTo(props.CFrame)
		clone.PrimaryPart = originalPrimaryPart
		part.Parent = clone.Parent
	end, { props.CFrame, props.PrefabCFrame, part })

	return e("Part", {
		CFrame = props.CFrame,
		Size = props.Size,
		Transparency = 1,
		ref = setPart,
	})
end


-- =====================================================================
-- 2. MAIN APP
-- =====================================================================
local App = function()
	local localConfigs, setLocalConfigs = useState(PlaceablesModule.Array)
	
	-- Paint Editor States
	local activeModel, setActiveModel = useState(nil)
	local selectedParts, setSelectedParts = useState({})
	local tick, setTick = useState(0) -- Forces highlight refresh
	local modelsMounted, setModelsMounted = useState(0) -- Tracks when models actually load

	-- ==============================================
	-- A. Selection Listener
	-- ==============================================
	useEffect(function()
		local function onSelectionChanged()
			local sel = Selection:Get()
			local nextActive = nil
			local nextParts = {}

			for _, item in sel do
				if item:IsA("BasePart") then
					-- Traverse up to find if this part belongs to a model in our generated grid
					local current = item
					local foundModel = nil
					while current and current ~= workspace do
						if current.Parent and current.Parent.Name == "Placeables Folder" then
							foundModel = current
							break
						end
						current = current.Parent
					end

					if foundModel then
						nextActive = foundModel
						table.insert(nextParts, item)
					end
				elseif item:IsA("Model") and item.Parent and item.Parent.Name == "Placeables Folder" then
					nextActive = item
				end
			end

			setActiveModel(nextActive)
			setSelectedParts(nextParts)
		end
		local conn = Selection.SelectionChanged:Connect(onSelectionChanged)
		onSelectionChanged()
		return function()
			conn:Disconnect()
		end
	end, {})


	-- ==============================================
	-- B. Visual Highlights (SelectionBoxes)
	-- ==============================================
	useEffect(function()
		local folder = workspace:FindFirstChild("_PaintHighlights")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "_PaintHighlights"
			folder.Archivable = false
			folder.Parent = workspace
		else
			folder:ClearAllChildren()
		end

		local placeablesFolder = workspace:FindFirstChild("Placeables Folder")
		if placeablesFolder then
			for _, part in placeablesFolder:GetDescendants() do
				if part:IsA("BasePart") and not part:GetAttribute("IsReactAnchor") then
					if part.Name == "Primary" or part.Name == "Secondary" then
						local box = Instance.new("SelectionBox")
						box.Adornee = part
						box.LineThickness = 0.05
						box.SurfaceTransparency = 0.8
						
						if part.Name == "Primary" then
							box.Color3 = Color3.new(0, 1, 0)
							box.SurfaceColor3 = Color3.new(0, 1, 0)
						elseif part.Name == "Secondary" then
							box.Color3 = Color3.new(0, 0.5, 1)
							box.SurfaceColor3 = Color3.new(0, 0.5, 1)
						end
						
						box.Parent = folder
					end
				end
			end
		end

		return function()
			if folder then folder:Destroy() end
		end
	end, { tick, localConfigs, modelsMounted }) -- Added modelsMounted to dependencies


	-- ==============================================
	-- C. Cached 3D Rendering Calculations (The Grid)
	-- ==============================================
	local children = {}
	local origin = CFrame.new(0, 100, 0)
	local layoutState = useRef(nil)
	if not layoutState.current then
		layoutState.current = {
			cache = {},
			furthestRow = 0,
			furthesCol = 0,
			currentRowsLength = 0,
			maxColWidth = 0,
			count = 0,
			prevLevel = nil,
		}
	end

	local state = layoutState.current
	for i, config in ipairs(localConfigs) do
		local cached = state.cache[config.Id]
		if not cached then
			local prefab = ReplicatedStorage.Shared.Models:FindFirstChild(config.Id)
			if prefab then
				local cf, s = Grid.getModelBounds(prefab)
				state.currentRowsLength = math.max(state.currentRowsLength, s.Z)
				state.furthesCol += s.X / 2
				local newCF = origin + Vector3.new(state.furthesCol, s.Y / 2, state.furthestRow + s.Z / 2)
				state.furthesCol += s.X / 2 + 5

				cached = {
					PrefabCFrame = cf,
					CFrame = newCF,
					Size = s,
				}
				state.cache[config.Id] = cached
				state.count += 1

				if (state.count % 10) == 0 then
					state.furthestRow += state.currentRowsLength + 5
					state.furthesCol = 0
					state.currentRowsLength = 0
				end
				state.maxColWidth = math.max(state.maxColWidth, state.furthesCol)
			end
		end

		local prefab = ReplicatedStorage.Shared.Models:FindFirstChild(config.Id)
		if cached and prefab then
			children[config.Id] = e(Placeable, {
				PrefabCFrame = cached.PrefabCFrame,
				Prefab = prefab,
				Config = config,
				CFrame = cached.CFrame,
				Size = cached.Size,
				OnMount = function() 
					setModelsMounted(function(prev) return prev + 1 end) 
				end,
			})
		end
	end

	local totalRowsLength = state.furthestRow + state.currentRowsLength
	local maxColWidth = state.maxColWidth
	local size = Vector3.new(maxColWidth, 1, totalRowsLength)
	local cframe = origin + Vector3.new(maxColWidth / 2, -0.5, totalRowsLength / 2)


	-- ==============================================
	-- D. Action Handlers
	-- ==============================================
	local function renameSelected(newName)
		for _, part in selectedParts do
			-- Exclude the react anchor part from being accidentally renamed
			if part.Name ~= "Hitbox" then
				part.Name = newName or part.ClassName
			end
		end
		setTick(tick + 1)
	end

	local function saveToShared()
		if not activeModel then return end
		
		local targetFolder = ReplicatedStorage.Shared.Models
		local prefabName = activeModel.Name
		local existing = targetFolder:FindFirstChild(prefabName)
		
		if existing then
			existing:Destroy()
		end
		
		local cloneToSave = activeModel:Clone()
		
		-- Strip out the React Anchor part before saving
		for _, desc in cloneToSave:GetDescendants() do
			if desc:GetAttribute("IsReactAnchor") then
				desc:Destroy()
			end
		end
		
		cloneToSave.Parent = targetFolder
		print(`[Paint Channel Editor] Successfully saved '{prefabName}' to Shared.Models!`)
	end


	-- ==============================================
	-- E. UI Layout
	-- ==============================================
	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	}, {
		-- Left Panel: The Editor
		EditorPanel = e(VStack, {
			Size = UDim2.new(0, 320, 1, 0),
			BackgroundColor3 = Color3.new(0.12, 0.12, 0.12),
			Padding = e("UIPadding", {
				PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
				PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
			}),
			Spacing = UDim.new(0, 10),
			VerticalFlex = Enum.UIFlexAlignment.None,
		}, {
			Header = e(SmallText, { Text = "Paint Channel Editor", TextSize = 24, Size = UDim2.new(1, 0, 0, 30) }),

			SelectedInfo = e(SmallText, {
				Text = activeModel and `Editing: {activeModel.Name}` or "Select a part in the Workspace grid",
				TextColor3 = activeModel and Color3.new(0.4, 1, 0.4) or Color3.new(1, 0.4, 0.4),
				Size = UDim2.new(1, 0, 0, 20),
			}),

			PartsCount = activeModel and e(SmallText, {
				Text = `{math.max(1, #selectedParts)} parts selected`,
				TextColor3 = Color3.new(0.7, 0.7, 0.7),
				Size = UDim2.new(1, 0, 0, 20),
			}) or nil,

			-- Channel Buttons
			Buttons = activeModel and e(VStack, { Spacing = UDim.new(0, 8), Size = UDim2.new(1, 0, 0, 110) }, {
				PrimaryBtn = e(SmallButton, {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundColor3 = Color3.new(0.2, 0.6, 0.2), -- Green
					[React.Event.Activated] = function() renameSelected("Primary") end,
				}, { e(SmallText, { Text = "Set Primary (Green)" }) }),

				SecondaryBtn = e(SmallButton, {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundColor3 = Color3.new(0.2, 0.4, 0.8), -- Blue
					[React.Event.Activated] = function() renameSelected("Secondary") end,
				}, { e(SmallText, { Text = "Set Secondary (Blue)" }) }),

				ClearBtn = e(SmallButton, {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundColor3 = Color3.new(0.3, 0.3, 0.3),
					[React.Event.Activated] = function() renameSelected(nil) end,
				}, { e(SmallText, { Text = "Clear Channel (Reset Name)" }) }),
			}) or nil,

			-- Save Button
			SaveBtn = activeModel and e(SmallButton, {
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundColor3 = Color3.new(0.8, 0.5, 0.1),
				[React.Event.Activated] = saveToShared,
			}, { e(SmallText, { Text = "Save to Shared.Models" }) }) or nil,
		}),

		-- 3D Workspace Portal
		ReactRoblox.createPortal({
			e("Folder", { Name = "Placeables Folder" }, children),
			e("Part", {
				Size = size,
				CFrame = cframe,
				Locked = true,
				Transparency = 0.8,
			}),
		}, workspace),
	})
end


-- =====================================================================
-- STORY MOUNT
-- =====================================================================
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