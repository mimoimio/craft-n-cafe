local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- ====================================================================
-- GLOBAL MODEL POOL
-- ====================================================================
local CoffeeModule = require(script.Parent.Parent.CoffeeModule)
local GlobalModelPool = {
	Templates = {},
	Available = {},
	RandomIds = {},
	Initialized = false,
}

function GlobalModelPool.initialize()
	if GlobalModelPool.Initialized then
		return
	end
	GlobalModelPool.Initialized = true

	for _, config in CoffeeModule.IngredientConfigs do
		local template = ReplicatedStorage.Shared.Models:FindFirstChild(config.Id)
		if not template then
			continue
		end

		local model = template:Clone()
		local packageLink = model:FindFirstChildWhichIsA("PackageLink")
		if packageLink then
			packageLink:Destroy()
		end

		for _, desc in model:GetDescendants() do
			if desc:IsA("BasePart") then
				desc.CanCollide = false
				desc.Anchored = true
			end
		end

		local hi = Instance.new("Highlight", model)
		hi.FillColor = Color3.new()
		hi.FillTransparency = 0.2
		hi.DepthMode = Enum.HighlightDepthMode.Occluded

		GlobalModelPool.Templates[config.Id] = model
		GlobalModelPool.Available[config.Id] = {}
		table.insert(GlobalModelPool.RandomIds, config.Id)
	end
end
function GlobalModelPool.cleanup()
	--
end

local function GetFromPool(id: string): Model?
	if not GlobalModelPool.Templates[id] then
		return nil
	end
	local pool = GlobalModelPool.Available[id]
	if #pool > 0 then
		return table.remove(pool)
	end
	return GlobalModelPool.Templates[id]:Clone()
end

local function ReturnToPool(id: string, model: Model)
	if not model then
		return
	end
	if not GlobalModelPool.Available[id] then
		model:Destroy()
		return
	end
	model.Parent = nil
	table.insert(GlobalModelPool.Available[id], model)
end

-- return GlobalModelPool
return {}
