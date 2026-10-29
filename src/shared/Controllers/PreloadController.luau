-- Shared/Controllers/PreloadController.luau
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetManifest = require(script.Parent.Parent.Configs.AssetManifest)

local PreloadController = {}

local FOLDER_TIMEOUT = 10
local THUMBNAIL_FORMAT = "rbxthumb://type=Asset&id=%s&w=150&h=150"

local function getSharedFolder(name: string): Instance?
	local folder = ReplicatedStorage.Shared:FindFirstChild(name)
	if folder then
		return folder
	end
	return ReplicatedStorage.Shared:WaitForChild(name, FOLDER_TIMEOUT)
end

local function wrapContent(className: string, contentId: string): Instance
	local instance = Instance.new(className)
	if className == "Sound" then
		instance.SoundId = contentId
	else
		instance.Image = contentId
	end
	return instance
end

local function runPreload()
	local assets: { Instance } = {}
	local tempInstances: { Instance } = {}
	local expected: { [string]: boolean } = {}
	local seen: { [string]: boolean } = {}
	local expectedCount = 0

	local function expect(contentId: string)
		if contentId == "" or expected[contentId] then
			return
		end
		expected[contentId] = true
		expectedCount += 1
	end

	for _, contentId in ipairs(AssetManifest.Images) do
		expect(contentId)
		local image = wrapContent("ImageLabel", contentId)
		table.insert(assets, image)
		table.insert(tempInstances, image)
	end

	for _, contentId in ipairs(AssetManifest.Sounds) do
		expect(contentId)
		local sound = wrapContent("Sound", contentId)
		table.insert(assets, sound)
		table.insert(tempInstances, sound)
	end

	for _, folderName in ipairs({ "SFX", "Musics" }) do
		local folder = getSharedFolder(folderName)
		if folder then
			for _, child in ipairs(folder:GetChildren()) do
				if child:IsA("Sound") and child.SoundId ~= "" then
					expect(child.SoundId)
					table.insert(assets, child)
				end
			end
		else
			warn(`[PreloadController] Missing Shared.{folderName}, skipping`)
		end
	end

	local modelsFolder = getSharedFolder("Models")
	if modelsFolder then
		for _, child in ipairs(modelsFolder:GetChildren()) do
			if child:IsA("Model") then
				table.insert(assets, child)

				local packageLink = child:FindFirstChildWhichIsA("PackageLink")
				if packageLink then
					local numericId = string.match(tostring(packageLink.PackageId), "%d+")
					if numericId then
						local thumbnail = string.format(THUMBNAIL_FORMAT, numericId)
						expect(thumbnail)
						local image = wrapContent("ImageLabel", thumbnail)
						table.insert(assets, image)
						table.insert(tempInstances, image)
					end
				end
			end
		end
	else
		warn("[PreloadController] Missing Shared.Models, skipping")
	end

	local screenGui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("LoadingScreen", FOLDER_TIMEOUT)
	if not screenGui then
		warn("[PreloadController] LoadingScreen not found, preload continues without progress reporting")
	end

	local resolvedCount = 0
	local function setProgress(alpha: number)
		if screenGui then
			screenGui:SetAttribute("PreloadProgress", math.clamp(alpha, 0, 1))
		end
	end

	local function onAssetFetched(contentId: string, status: Enum.AssetFetchStatus)
		if status == Enum.AssetFetchStatus.Failure or status == Enum.AssetFetchStatus.TimedOut then
			warn(`[PreloadController] Failed to preload {contentId}: {status.Name}`)
		elseif status == Enum.AssetFetchStatus.Loading then
			return
		end

		if expected[contentId] and not seen[contentId] then
			seen[contentId] = true
			resolvedCount += 1
			if expectedCount > 0 then
				setProgress(resolvedCount / expectedCount)
			end
		end
	end

	local ok, err = pcall(function()
		ContentProvider:PreloadAsync(assets, onAssetFetched)
	end)
	if not ok then
		warn(`[PreloadController] PreloadAsync error: {err}`)
	end

	for _, temp in ipairs(tempInstances) do
		temp:Destroy()
	end

	setProgress(1)
	print(`[PreloadController] Preloaded {#assets} assets`)
end

function PreloadController.initialize()
	task.spawn(runPreload)
end

return PreloadController
