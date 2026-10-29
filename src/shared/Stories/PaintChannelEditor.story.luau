local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

-- Assuming these exist based on your Placeables.story.luau
local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local SmallText = require(Primitives.SmallText)
local SmallButton = require(Primitives.SmallButton)
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local function App()
	local activeModel, setActiveModel = useState(nil)
	local selectedParts, setSelectedParts = useState({})
	local tick, setTick = useState(0) -- Used to force re-render when names change

	-- 1. Listen to Studio Selection
	useEffect(function()
		local function onSelectionChanged()
			local sel = Selection:Get()
			local nextActive = activeModel
			local nextParts = {}

			-- Auto-detect active model if a single Model is selected
			if #sel == 1 and sel[1]:IsA("Model") then
				nextActive = sel[1]
			end

			-- If we have an active model, filter the selection for its descendant BaseParts
			if nextActive then
				for _, item in sel do
					if item:IsA("BasePart") and item:IsDescendantOf(nextActive) then
						table.insert(nextParts, item)
					end
				end
			end

			setActiveModel(nextActive)
			setSelectedParts(nextParts)
		end

		local conn = Selection.SelectionChanged:Connect(onSelectionChanged)
		onSelectionChanged() -- Initial check

		return function()
			conn:Disconnect()
		end
	end, { activeModel })

	-- 2. Non-Destructive Visual Highlights (SelectionBoxes)
	useEffect(function()
		if not activeModel then
			return
		end

		-- Create a temporary folder in Workspace that won't save with the place
		local highlightFolder = Instance.new("Folder")
		highlightFolder.Name = "_PaintChannelPreview"
		highlightFolder.Archivable = false
		highlightFolder.Parent = workspace

		for _, part in activeModel:GetDescendants() do
			if part:IsA("BasePart") then
				if part.Name == "Primary" or part.Name == "Secondary" then
					local box = Instance.new("SelectionBox")
					box.Adornee = part
					box.LineThickness = 0.05
					box.SurfaceTransparency = 0.8

					if part.Name == "Primary" then
						box.Color3 = Color3.new(0, 1, 0) -- Green
						box.SurfaceColor3 = Color3.new(0, 1, 0)
					elseif part.Name == "Secondary" then
						box.Color3 = Color3.new(0, 0.5, 1) -- Blue
						box.SurfaceColor3 = Color3.new(0, 0.5, 1)
					end

					box.Parent = highlightFolder
				end
			end
		end

		return function()
			highlightFolder:Destroy()
		end
	end, { activeModel, tick })

	-- 3. Action Handlers
	local function renameSelected(newName)
		for _, part in selectedParts do
			part.Name = newName or part.ClassName -- Fallback to "Part" / "MeshPart"
		end
		setTick(tick + 1) -- Trigger highlight refresh
	end

	local function saveToShared()
		if not activeModel then
			return
		end

		local targetFolder = ReplicatedStorage.Shared.Models
		local existing = targetFolder:FindFirstChild(activeModel.Name)

		if existing then
			existing:Destroy()
		end

		local clone = activeModel:Clone()
		clone.Parent = targetFolder

		print(`[Paint Channel Editor] Successfully saved '{activeModel.Name}' to ReplicatedStorage.Shared.Models!`)
	end

	-- 4. UI Layout
	return e("Frame", {
		Size = UDim2.new(0, 300, 0, 260),
		BackgroundColor3 = Color3.new(0.12, 0.12, 0.12),
		Active = true,
	}, {
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}),
		Layout = e(VStack, {
			Size = UDim2.fromScale(1, 1),
			Spacing = UDim.new(0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalFlex = Enum.UIFlexAlignment.SpaceBetween,
		}, {
			-- Header
			Header = e(VStack, { Spacing = UDim.new(0, 4), Size = UDim2.new(1, 0, 0, 50) }, {
				Title = e(
					SmallText,
					{ Text = "Paint Channel Editor", TextSize = 20, TextColor3 = Color3.new(1, 1, 1) }
				),
				Status = e(SmallText, {
					Text = activeModel and `Editing: {activeModel.Name}` or "Select a Model in Workspace",
					TextColor3 = activeModel and Color3.new(0.4, 1, 0.4) or Color3.new(1, 0.4, 0.4),
				}),
				PartsCount = activeModel and e(SmallText, {
					Text = `{math.max(1, #selectedParts)} parts selected`,
					TextColor3 = Color3.new(0.7, 0.7, 0.7),
					TextSize = 12,
				}) or nil,
			}),

			-- Channel Buttons
			Buttons = activeModel and e(VStack, { Spacing = UDim.new(0, 8), Size = UDim2.new(1, 0, 0, 110) }, {
				PrimaryBtn = e(SmallButton, {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundColor3 = Color3.new(0.2, 0.6, 0.2), -- Green
					[React.Event.Activated] = function()
						renameSelected("Primary")
					end,
				}, { e(SmallText, { Text = "Set Primary (Green)" }) }),

				SecondaryBtn = e(SmallButton, {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundColor3 = Color3.new(0.2, 0.4, 0.8), -- Blue
					[React.Event.Activated] = function()
						renameSelected("Secondary")
					end,
				}, { e(SmallText, { Text = "Set Secondary (Blue)" }) }),

				ClearBtn = e(SmallButton, {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundColor3 = Color3.new(0.3, 0.3, 0.3),
					[React.Event.Activated] = function()
						renameSelected(nil)
					end,
				}, { e(SmallText, { Text = "Clear Channel (Reset Name)" }) }),
			}) or nil,

			-- Save Button
			SaveBtn = activeModel and e(SmallButton, {
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundColor3 = Color3.new(0.8, 0.5, 0.1),
				[React.Event.Activated] = saveToShared,
			}, { e(SmallText, { Text = "Save/Overwrite to Shared.Models" }) }) or nil,
		}),
	})
end

local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	root:render(e(App))

	return function()
		root:unmount()
	end
end

return story
