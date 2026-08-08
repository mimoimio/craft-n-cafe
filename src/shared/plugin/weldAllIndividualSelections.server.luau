-- Weld All Descendants Plugin
-- Welds all BasePart descendants of each selected model using WeldConstraints

local toolbar = plugin:CreateToolbar("Welding Tools")
local weldButton = toolbar:CreateButton("Weld Descendants", "Weld all BasePart descendants in each selected model", "")
local destroyButton = toolbar:CreateButton("Destroy Welds", "Destroy all WeldConstraints in each selected model", "")

local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local function weldSelections()
	local selectedObjects = Selection:Get()

	if #selectedObjects == 0 then
		warn("No objects selected. Please select one or more models.")
		return
	end

	local totalWelded = 0

	for _, object in selectedObjects do
		-- Get all BasePart descendants
		local parts = {}
		for _, descendant in object:GetDescendants() do
			if descendant:IsA("BasePart") then
				table.insert(parts, descendant)
			end
		end

		if #parts == 0 then
			warn("No BaseParts found in " .. object.Name)
			continue
		end

		if #parts == 1 then
			warn(object.Name .. " only has 1 BasePart, skipping")
			continue
		end

		-- Use PrimaryPart as anchor if available, otherwise use the first part
		local anchorPart = nil
		if object:IsA("Model") and object.PrimaryPart then
			anchorPart = object.PrimaryPart
		else
			anchorPart = parts[1]
		end

		-- Create WeldConstraints from all other parts to the anchor
		local weldCount = 0
		for _, part in parts do
			if part ~= anchorPart then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = anchorPart
				weld.Part1 = part
				weld.Parent = part
				weldCount += 1
			end
		end

		totalWelded += weldCount
		print("✓ Welded " .. weldCount .. " parts in " .. object.Name)
	end

	if totalWelded > 0 then
		print("Welding complete! Total: " .. totalWelded .. " WeldConstraints created")
		ChangeHistoryService:SetWaypoint("Weld Descendants")
	end
end

local function destroyWeldConstraints()
	local selectedObjects = Selection:Get()

	if #selectedObjects == 0 then
		warn("No objects selected. Please select one or more models.")
		return
	end

	local totalDestroyed = 0

	for _, object in selectedObjects do
		local weldCount = 0
		for _, descendant in object:GetDescendants() do
			if descendant:IsA("WeldConstraint") then
				descendant:Destroy()
				weldCount += 1
			end
		end

		if weldCount > 0 then
			totalDestroyed += weldCount
			print("✓ Destroyed " .. weldCount .. " WeldConstraints in " .. object.Name)
		else
			warn("No WeldConstraints found in " .. object.Name)
		end
	end

	if totalDestroyed > 0 then
		print("Destruction complete! Total: " .. totalDestroyed .. " WeldConstraints removed")
		ChangeHistoryService:SetWaypoint("Destroy WeldConstraints")
	end
end

weldButton.Click:Connect(weldSelections)
destroyButton.Click:Connect(destroyWeldConstraints)
