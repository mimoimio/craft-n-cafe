-- GeneralHud.story.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ViewportController = require(ReplicatedStorage.Shared.Controllers.ViewportController)
local Main = require(ReplicatedStorage.Shared.ReactComponents.Main)

local PlacementController = require(ReplicatedStorage.Shared.Controllers.PlacementController)
local InputAdapter = require(ReplicatedStorage.Shared.Controllers.InputAdapter)

local CafeRenderingService = require(ServerScriptService.Server.Services.CafeRenderingService)
local function formatValue(value, depth)
	local indent = string.rep("\t", depth)
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
				table.insert(results, indent .. "}")
			else
				table.insert(
					results,
					-- string.format(`%s%s : "%s"`, indent, k == "customerAction" and k or "", tostring(v))
					string.format(
						"%s%-20s = %s,",
						indent,
						if type(k) == "string" then `["{tostring(k)}"]` else tostring(k),
						if type(v) == "string" then `"{v}"` else tostring(v)
					)
					-- string.format("%s%24s (%s): %s(%s),", indent, tostring(k), type(k), tostring(v), type(v))
				)
			end
		end
		return table.concat(results, "\n")
	else
		return string.format("%s%s,", indent, tostring(value))
	end
end

local function story(frame: Frame)
	local plot = workspace.CafeBase.Part
	local models = game.ReplicatedStorage.Shared.Models

	-- 1. Initialize Mock State for UI Labs
	GlobalState.startPlayerSession("MockUser", {
		Plot = { grid = {}, placedItems = {}, nextId = 1 }, -- Updated to unified 'grid'
		Stats = {
			Level = 1,
		} :: any,
		Ingredients = {},
		Customers = {},
		Workers = {},
		Cups = {},
	})

	-- 2. Mock Server: Listen for Mock Remote Events
	local placeListener = Remotes.PlaceItem.OnServerEvent:Connect(function(player, itemId, startX, startZ, rotation)
		local playerId = player and tostring(player.UserId) or "MockUser"

		-- 1. Authoritative Prefab Lookup
		local prefab = game.ReplicatedStorage.Shared.Models:FindFirstChild(itemId)
		if not prefab then
			return
		end

		-- 2. Authoritative Type Resolution
		local itemTypeAttr = prefab:GetAttribute("ItemType") or "Solid"
		local resolvedItemType = "Solid"

		if itemTypeAttr == "Wall" then
			local isRotated = math.abs(rotation % 180) == 90

			-- FIX: 90 degrees now means it's running along the Z-axis (Wall_V)
			resolvedItemType = isRotated and "Wall_V" or "Wall_H"
		end

		-- 3. Authoritative Math
		local _, itemSize = prefab:GetBoundingBox()
		local Grid = require(game.ReplicatedStorage.Shared.Grid)
		local width, length = Grid.getFootprint(itemSize, rotation)

		-- Dispatch to the slice using the trusted resolvedItemType
		GlobalState.placeItem(playerId, {
			itemId = itemId,
			itemType = resolvedItemType,
			startX = startX,
			startZ = startZ,
			width = width,
			length = length,
			rotation = rotation,
		})
		warn(formatValue(GlobalState:getState().Plot["MockUser"], 0))
	end)
	local destroyListener = Remotes.DestroyItem.OnServerEvent:Connect(function(player, uuid)
		local playerId = player and tostring(player.UserId) or "MockUser"
		GlobalState.destroyItem(playerId, { uuid = uuid })
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
