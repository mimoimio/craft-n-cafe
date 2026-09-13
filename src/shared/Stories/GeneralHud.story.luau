-- GeneralHud.story.luau
local Debris = game:GetService("Debris")
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
				table.insert(
					results,
					string.format("%s%s = {", indent, if type(k) == "string" then `["{tostring(k)}"]` else tostring(k))
				)
				table.insert(results, formatValue(v, depth + 1))
				table.insert(results, indent .. "},")
			else
				local cFrameText
				local isCFrame = typeof(v) == "CFrame"
				if isCFrame then
					local components = { v:GetComponents() }
					local texts = {}
					for i, num in components do
						table.insert(texts, `[{i}]=num,`)
					end
					cFrameText = table.concat(texts)
				end
				table.insert(
					results,
					string.format(
						"%s%s=%s,",
						indent,
						if type(k) == "string"
							then `["{tostring(k)}"]`
							elseif type(k) == "number" then `[{tostring(k)}]`
							else tostring(k),
						if isCFrame then cFrameText elseif type(v) == "string" then `"{v}"` else tostring(v)
					)
				)
			end
		end
		return table.concat(results, "\n")
	else
		return string.format("%s%s,", indent, tostring(value))
	end
end

local function getPlot()
	return PlotConfig.FirstPlot
end

local function story(frame: Frame)
	local models = game.ReplicatedStorage.Shared.Models

	-- 1. Initialize Mock State for UI Labs
	GlobalState.startPlayerSession("MockUser", {
		Plot = getPlot(),
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

		-- Fetch the dynamic plot size from Reflex State
		local state = GlobalState:getState()
		local plotState = state.Plot and state.Plot[playerId]
		if not plotState then
			warn(`Placement failed: No plot state found for Player {playerId}.`)
			return
		end

		local placementType = prefab:GetAttribute("PlacementType") or "Grid"
		local plotSizeNum = plotState.plotSize or 32
		local plotSize = Vector3.new(plotSizeNum, 1, plotSizeNum)

		if placementType == "Free" then
			if typeof(payload.cframe) ~= "CFrame" then
				return warn("Spatial Placement has no cframe")
			end

			-- [[ SERVER-SIDE GUARD FOR SPATIAL ITEMS ]]
			local _, itemSize = Grid.getModelBounds(prefab)

			if not Grid.isSpatialInBounds(payload.cframe, itemSize, plotSize) then
				warn(`Place item error: Player {playerId} attempted to place {payload.itemId} outside plot bounds.`)
				return
			end

			local playerbase = CafeRenderingService.getCafeBaseFromPlayerId(playerId)
			if not (playerbase and playerbase.Spatial) then
				return
			end
			-- 1. Get the Anchor's World CFrame
			local anchor = playerbase:FindFirstChild("Anchor")
			local plotCFrame = anchor and anchor.CFrame or CFrame.new(0, 0, 0)
			-- 2. Convert the relative payload CFrame back to World Space
			local worldCFrame = Grid.spatialToWorld(payload.cframe, plotCFrame, plotSize)

			local _, s = prefab:GetBoundingBox()
			s = Vector3.new(math.max(0, s.X - 0.2), math.max(0, s.Y - 0.2), math.max(0, s.Z - 0.2))

			local overlapparams = OverlapParams.new()
			overlapparams.FilterType = Enum.RaycastFilterType.Include
			overlapparams.FilterDescendantsInstances = { playerbase.Spatial }
			local parts = workspace:GetPartBoundsInBox(worldCFrame, s, overlapparams)
			if parts and #parts > 0 then
				return
			end

			-- Serialize to the State Payload
			local statePayload = {
				itemId = payload.itemId,
				placementType = "Free",
				cframe = { payload.cframe:GetComponents() },
				parentUuid = payload.parentUuid or "Plot",
			}
			GlobalState.placeItem(playerId, statePayload)
		else
			-- [[ GRID PLACEMENT SERVER GUARDS ]]
			local itemTypeAttr = prefab:GetAttribute("ItemType") or "Solid"
			local resolvedItemType = itemTypeAttr

			if itemTypeAttr == "Wall" then
				local isRotated = math.abs(payload.rotation % 180) == 90
				resolvedItemType = isRotated and "Wall_V" or "Wall_H"
			end

			local _, itemSize = Grid.getModelBounds(prefab)
			local width, length = Grid.getFootprint(itemSize, payload.rotation)

			if typeof(payload.startX) ~= "number" or typeof(payload.startZ) ~= "number" then
				return warn(`PlaceItem failed: coordinates must be numbers`)
			end

			-- 1. Bounds Check
			local clampedX, clampedZ =
				Grid.clampToGrid(resolvedItemType, payload.startX, payload.startZ, width, length, plotSize)

			if payload.startX ~= clampedX or payload.startZ ~= clampedZ then
				warn(`Place item error: Player {playerId} attempted to place {payload.itemId} outside grid bounds.`)
				return
			end

			-- 2. Collision Check
			if not Grid.isAreaFree(plotState, resolvedItemType, payload.startX, payload.startZ, width, length) then
				warn(`Place item error: Player {playerId} attempted to place {payload.itemId} in an occupied space.`)
				return
			end

			local statePayload = {
				itemId = payload.itemId,
				placementType = "Grid",
				itemType = resolvedItemType,
				startX = payload.startX,
				startZ = payload.startZ,
				width = width,
				length = length,
				rotation = payload.rotation,
			}
			GlobalState.placeItem(playerId, statePayload)
		end

		playersPlotString = formatValue(GlobalState:getState().Plot["MockUser"], 1)
	end)

	local destroyListener = Remotes.DestroyItem.OnServerEvent:Connect(function(player, uuid)
		local playerId = player and tostring(player.UserId) or "MockUser"
		GlobalState.destroyItem(playerId, { uuid = uuid })
		playersPlotString = formatValue(GlobalState:getState().Plot["MockUser"], 1)
	end)

	CafeRenderingService.initialize()

	-- 3. Render UI FIRST so React mounts the dynamic CafeBase.Part
	local root = ReactRoblox.createRoot(frame)
	root:render(e(Main))
	ViewportController.initialize()

	-- 5. Initialize Controllers & Services with the dynamic plot
	PlacementController.initialize()
	PlacementController:setBuildMode(false)
	return function()
		placeListener:Disconnect()
		destroyListener:Disconnect()
		local playerId = "MockUser"
		GlobalState.expandPlot(playerId, { newSize = 32 })
		local PlotTemplate = ServerStorage:FindFirstChild("PlotTemplate")
		if PlotTemplate and playersPlotString then
			PlotTemplate.Source = `return \{\n{playersPlotString}\n}`
		end

		PlacementController:setBuildMode(false)
		PlacementController.cleanup()
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
