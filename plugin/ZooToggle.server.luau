-- Coffee Zoo Toggle Plugin
-- Only works in Game ID: 9692753637

local GAME_IDs = {
	[9692753637] = true,
	[10457683856] = true,
	[9907213736] = true,
}

-- Check if we're in the correct game
if not GAME_IDs[game.GameId] and game.PlaceId ~= 0 then
	warn("[Zoo Plugin] This plugin only works in Game ID: ", GAME_IDs)
	return
end

local toolbar = plugin:CreateToolbar("Coffee Zoo")
local toggleButton = toolbar:CreateButton("Toggle Zoo", "Show/Hide the Coffee Zoo display", "")
local syncButton = toolbar:CreateButton("Sync Models", "Replace old models in Models folder with new ones from Zoo", "")

local Selection = game:GetService("Selection")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local isZooActive = false

local MODELS_PER_ROW = 10
local TILE_SIZE = 4
local s, msg = xpcall(function()
	return workspace:WaitForChild("CoffeePlatform")
end, function(msg)
	warn("msg", msg)
end)

warn(msg)

local function createModelDisplay(item: {}, displayName: string, position: Vector3, parent: Instance)
	local ORIGIN = s and msg and msg:GetPivot().Position or Vector3.new()
	local itemId = item.id
	-- Create base platform
	local platform = Instance.new("Part")
	platform.Name = itemId .. "_Platform"
	platform.Size = Vector3.new(TILE_SIZE, 0.5, TILE_SIZE)
	platform.Position = position + ORIGIN
	platform.Anchored = true
	platform.Material = Enum.Material.SmoothPlastic
	platform.Color = Color3.fromRGB(200, 200, 200)
	platform.Parent = parent

	-- Find and clone model
	local modelTemplate = ReplicatedStorage:FindFirstChild("Shared")
		and ReplicatedStorage.Shared:FindFirstChild("Models")
		and ReplicatedStorage.Shared.Models:FindFirstChild(itemId)

	if modelTemplate then
		local model = modelTemplate:Clone()
		-- Position model on platform
		local modelCF, modelSize = model:GetBoundingBox()
		local yOffset = platform.Size.Y / 2 + modelSize.Y / 2
		model:PivotTo(CFrame.new(position.X, position.Y + yOffset, position.Z) + ORIGIN)

		-- Anchor all parts
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end

		model.Parent = parent
	else
		local model = ReplicatedStorage.Shared.Models:FindFirstChild("error"):Clone()
		-- Position model on platform
		local modelCF, modelSize = model:GetBoundingBox()
		local yOffset = platform.Size.Y / 2 + modelSize.Y / 2
		model:PivotTo(CFrame.new(position.X, position.Y + yOffset, position.Z) + ORIGIN)

		-- Anchor all parts
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end

		model.Parent = parent
	end

	-- Create BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Adornee = platform
	billboard.Size = UDim2.new(4, 0, 1, 0)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = platform

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = displayName
	label.TextColor3 = item.ingredients and Color3.new(1, 1, 1) or Color3.new(0.25, 0.25, 0.75)
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.1, 0)
	padding.PaddingRight = UDim.new(0.1, 0)
	padding.PaddingTop = UDim.new(0.15, 0)
	padding.PaddingBottom = UDim.new(0.15, 0)
	padding.Parent = label
end

local function renderZoo()
	-- Create container folder
	local zooFolder = workspace:FindFirstChild("CoffeeZoo")
	if zooFolder then
		zooFolder:ClearAllChildren()
	else
		zooFolder = Instance.new("Folder")
		zooFolder.Name = "CoffeeZoo"
		zooFolder.Parent = workspace
	end

	-- Get CoffeeConfig (clone module to avoid caching)
	local CoffeeConfig
	local success, err = pcall(function()
		local coffeeModuleOriginal = ReplicatedStorage.Shared.Configs.CoffeeConfig
		local coffeeModuleClone = coffeeModuleOriginal:Clone()
		CoffeeConfig = require(coffeeModuleClone)
		coffeeModuleClone:Destroy()
	end)

	if not success or not CoffeeConfig then
		warn("[Zoo Plugin] Could not load CoffeeConfig: " .. tostring(err))
		return
	end

	-- Collect all coffee items
	local items = {}
	for _, config in ipairs(CoffeeConfig) do
		table.insert(items, {
			id = config.Id,
			name = config.Id,
			ingredients = config.Ingredients,
		})
	end

	-- Sort alphabetically
	table.sort(items, function(a, b)
		local ia, ib = a.ingredients, b.ingredients
		local na, nb = (ia and #ia or 0), (ib and #ib or 0)
		local same = na == nb
		if same then
			return a.name < b.name
		end
		return na < nb
	end)

	-- Create grid
	local startPosition = Vector3.new(0, 10, 0)

	for index, item in ipairs(items) do
		local row = math.floor((index - 1) / MODELS_PER_ROW)
		local col = (index - 1) % MODELS_PER_ROW

		local x = startPosition.X + (col * (TILE_SIZE + 1))
		local y = startPosition.Y
		local z = startPosition.Z + (row * (TILE_SIZE + 1))

		createModelDisplay(item, item.name, Vector3.new(x, y, z), zooFolder)
	end

	print(string.format("[Zoo Plugin] Rendered %d coffee items", #items))
	ChangeHistoryService:SetWaypoint("Render Coffee Zoo")
end

local function cleanupZoo()
	local zooFolder = workspace:FindFirstChild("CoffeeZoo")
	if zooFolder then
		zooFolder:Destroy()
		print("[Zoo Plugin] Cleaned up Coffee Zoo")
		ChangeHistoryService:SetWaypoint("Cleanup Coffee Zoo")
	end
end

local function syncModelsFromZoo()
	local zooFolder = workspace:FindFirstChild("CoffeeZoo")
	if not zooFolder then
		warn("[Zoo Plugin] CoffeeZoo folder not found. Please toggle the zoo on first.")
		return
	end

	local modelsFolder = ReplicatedStorage:FindFirstChild("Shared")
		and ReplicatedStorage.Shared:FindFirstChild("Models")

	if not modelsFolder then
		warn("[Zoo Plugin] Models folder not found in ReplicatedStorage.Shared")
		return
	end

	local updatedCount = 0
	local createdCount = 0

	for _, child in ipairs(zooFolder:GetChildren()) do
		-- Skip platforms, only process actual models
		if not child.Name:match("_Platform$") and child:IsA("Model") then
			local modelId = child.Name
			local existingModel = modelsFolder:FindFirstChild(modelId)

			if existingModel then
				-- Replace existing model
				local newModel = child:Clone()
				newModel.Parent = modelsFolder
				existingModel:Destroy()
				updatedCount += 1
				print("✓ Updated model: " .. modelId)
			else
				-- Create new model
				local newModel = child:Clone()
				newModel.Parent = modelsFolder
				createdCount += 1
				print("✓ Created new model: " .. modelId)
			end
		end
	end

	if updatedCount > 0 or createdCount > 0 then
		print(string.format("[Zoo Plugin] Sync complete! Updated: %d, Created: %d", updatedCount, createdCount))
		ChangeHistoryService:SetWaypoint("Sync Models from Zoo")
	else
		warn("[Zoo Plugin] No models found to sync")
	end
end

local function toggleZoo()
	isZooActive = not isZooActive
	toggleButton:SetActive(isZooActive)

	if isZooActive then
		renderZoo()
	else
		cleanupZoo()
	end
end

toggleButton.Click:Connect(toggleZoo)
syncButton.Click:Connect(syncModelsFromZoo)

-- print("[Zoo Plugin] Loaded for Game ID: " .. GAME_ID)
