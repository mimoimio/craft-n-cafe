-- GeneralHud.story.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Grid = require(ReplicatedStorage.Shared.Grid)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ViewportController = require(ReplicatedStorage.Shared.Controllers.ViewportController)
local Main = require(ReplicatedStorage.Shared.ReactComponents.Main)
local PlotConfig = require(ReplicatedStorage.Shared.Configs.PlotConfig:Clone())

local PlacementController = require(ReplicatedStorage.Shared.Controllers.PlacementController)
local InputAdapter = require(ReplicatedStorage.Shared.Controllers.InputAdapter)

local CafeRenderingService = require(ServerScriptService.Server.Services.CafeRenderingService)
local playersPlotString
local function formatValue(value, depth)
	local indent = string.rep("\t", depth)
	-- local indent = ""
	if type(value) == "table" then
		local results = {}
		for k, v in value do
			if type(v) == "table" then
				-- table.insert(
				-- 	results,
				-- 	string.format("%s%s (%s): {", indent, k == "customerAction" and k or "", "")
				-- )
				table.insert(
					results,
					string.format("%s%s = {", indent, if type(k) == "string" then `["{tostring(k)}"]` else tostring(k))
				)
				table.insert(results, formatValue(v, depth + 1))
				table.insert(results, indent .. "},")
			else
				table.insert(
					results,
					-- string.format(`%s%s : "%s"`, indent, k == "customerAction" and k or "", tostring(v))
					string.format(
						"%s%s=%s,",
						indent,
						if type(k) == "string" then `["{tostring(k)}"]` else tostring(k),
						if type(v) == "string"
							then `"{v}"`
							elseif typeof(v) == "CFrame" then `CFrame.new({tostring(v)})`
							else tostring(v)
					)
					-- string.format("%s%24s (%s): %s(%s),", indent, tostring(k), type(k), tostring(v), type(v))
				)
			end
		end
		-- return table.concat(results)
		return table.concat(results, "\n") -- not needed, not for viewing
	else
		return string.format("%s%s,", indent, tostring(value))
	end
end

local function getPlot()
	return PlotConfig.FirstPlot
end

local function story(frame: Frame)
	local plot = workspace.CafeBase.Part
	local models = game.ReplicatedStorage.Shared.Models

	-- 1. Initialize Mock State for UI Labs
	GlobalState.startPlayerSession("MockUser", {
		Plot = getPlot(), -- Updated to unified 'grid'
		Stats = {
			Level = 1,
		} :: any,
		Ingredients = {},
		Customers = {},
		Workers = {},
		Cups = {},
	})

	-- 2. Mock Server: Listen for Mock Remote Events
	local placeListener = Remotes.PlaceItem.OnServerEvent:Connect(function(player, payload)
		local playerId = player and tostring(player.UserId) or "MockUser"

		-- 1. Authoritative Prefab Lookup
		local prefab = game.ReplicatedStorage.Shared.Models:FindFirstChild(payload.itemId)
		if not prefab then
			return
		end

		if payload.placementType == "Free" then
			-- [[ SERVER-SIDE GUARD FOR SPATIAL ITEMS ]]
			local _, itemSize = Grid.getModelBounds(prefab)
			local maxRadius = math.max(itemSize.X, itemSize.Z) / 2
			local plotSize = workspace.CafeBase.Part.Size

			local relativePos = payload.cframe.Position
			local isWithinBounds = math.abs(relativePos.X) + maxRadius <= (plotSize.X / 2)
				and math.abs(relativePos.Z) + maxRadius <= (plotSize.Z / 2)

			if not isWithinBounds then
				warn(`Exploit prevented: Player {playerId} attempted to place {payload.itemId} outside plot bounds.`)
				return
			end

			GlobalState.placeItem(playerId, payload)
		else
			-- [[ GRID PLACEMENT ]]
			-- FIX: Properly preserve Roof and Floor tags
			local itemTypeAttr = prefab:GetAttribute("ItemType") or "Solid"
			local resolvedItemType = itemTypeAttr

			if itemTypeAttr == "Wall" then
				local isRotated = math.abs(payload.rotation % 180) == 90
				resolvedItemType = isRotated and "Wall_V" or "Wall_H"
			end

			-- 3. Authoritative Math
			local _, itemSize = Grid.getModelBounds(prefab)
			local Grid = require(game.ReplicatedStorage.Shared.Grid)
			local width, length = Grid.getFootprint(itemSize, payload.rotation)

			-- Dispatch to the slice using the trusted resolvedItemType
			GlobalState.placeItem(playerId, {
				itemId = payload.itemId,
				placementType = "Grid",
				itemType = resolvedItemType, -- Now correctly passes "Roof"
				startX = payload.startX,
				startZ = payload.startZ,
				width = width,
				length = length,
				rotation = payload.rotation,
			})
		end

		playersPlotString = formatValue(GlobalState:getState().Plot["MockUser"], 1)
	end)

	local destroyListener = Remotes.DestroyItem.OnServerEvent:Connect(function(player, uuid)
		local playerId = player and tostring(player.UserId) or "MockUser"
		GlobalState.destroyItem(playerId, { uuid = uuid })
		playersPlotString = formatValue(GlobalState:getState().Plot["MockUser"], 1)
	end)

	-- 3. Initialize Controllers & Services
	PlacementController.new(plot, models)
	PlacementController:setBuildMode(false)

	CafeRenderingService.initialize()

	-- 4. Wire Inputs & Update Loop
	local connection = RunService.RenderStepped:Connect(function()
		local hitPos = InputAdapter.getCursorWorldPosition(plot)
		PlacementController:update(hitPos)
	end)

	local inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.R then
			PlacementController:rotateItem()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			if PlacementController.deleteModeActive then
				-- EXECUTE DELETE
				PlacementController:attemptDestroyAtCursor()
			else
				-- EXECUTE PLACE
				local hitPos = InputAdapter.getCursorWorldPosition(plot)
				local success, uuid = PlacementController:placeItem(hitPos)
				if success then
					print("Successfully placed item with UUID:", uuid)
				end
			end
		end
	end)

	-- Render UI
	local root = ReactRoblox.createRoot(frame)
	root:render(e(Main))
	ViewportController.initialize()

	-- 5. Cleanup
	return function()
		connection:Disconnect()
		inputConnection:Disconnect()
		placeListener:Disconnect()
		destroyListener:Disconnect()
		local PlotTemplate = ServerStorage:FindFirstChild("PlotTemplate")
		if PlotTemplate and playersPlotString then
			PlotTemplate.Source = `return \{\n{playersPlotString}\n}`
		end

		PlacementController:setBuildMode(false)
		root:unmount()
		ViewportController.cleanup()

		CafeRenderingService.cleanup()

		GlobalState:resetState()
		UIState:resetState()

		Remotes.PlaceItem._clearListeners()
		Remotes.DestroyItem._clearListeners()
	end
end

return story
