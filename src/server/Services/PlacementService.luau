-- ServerScriptService/Server/Services/PlacementService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Grid = require(ReplicatedStorage.Shared.Grid)
local Models = ReplicatedStorage.Shared.Models

local PlacementService = {}

function PlacementService.PlaceItem(player: Player, payload: any)
	local playerId = tostring(player.UserId)

	-- 1. Authoritative Prefab Lookup
	local prefab = Models:FindFirstChild(payload.itemId)
	if not prefab then
		warn(`Placement failed: Prefab '{payload.itemId}' does not exist.`)
		return
	end

	if payload.placementType == "Free" then
		-- [[ SERVER-SIDE GUARD FOR SPATIAL ITEMS ]]
		local _, itemSize = prefab:GetBoundingBox()
		local maxRadius = math.max(itemSize.X, itemSize.Z) / 2

		-- Note: Replace this with however you fetch the player's true plot size on the server.
		-- For the Mock Server (story.luau), it's workspace.CafeBase.Part.Size
		local plotSize = workspace.CafeBase.Part.Size

		local relativePos = payload.cframe.Position
		local isWithinBounds = math.abs(relativePos.X) + maxRadius <= (plotSize.X / 2)
			and math.abs(relativePos.Z) + maxRadius <= (plotSize.Z / 2)

		if not isWithinBounds then
			warn(`Exploit prevented: Player {playerId} attempted to place {payload.itemId} outside plot bounds.`)
			return
		end

		-- If it passed the bounds check, commit it to state
		GlobalState.placeItem(playerId, payload)
	else
		-- [[ GRID PLACEMENT ]]

		-- FIX: Properly preserve Roof and Floor tags, instead of defaulting to Solid!
		local itemTypeAttr = prefab:GetAttribute("ItemType") or "Solid"
		local resolvedItemType = itemTypeAttr

		if itemTypeAttr == "Wall" then
			local isRotated = math.abs(payload.rotation % 180) == 90
			resolvedItemType = isRotated and "Wall_V" or "Wall_H"
		end

		-- 3. Authoritative Math
		local _, itemSize = prefab:GetBoundingBox()
		local width, length = Grid.getFootprint(itemSize, payload.rotation)

		-- 4. Dispatch to the slice using the trusted resolvedItemType
		GlobalState.placeItem(playerId, {
			itemId = payload.itemId,
			placementType = "Grid",
			itemType = resolvedItemType, -- Now this correctly passes "Roof" instead of "Solid"
			startX = payload.startX,
			startZ = payload.startZ,
			width = width,
			length = length,
			rotation = payload.rotation,
		})
	end
end

function PlacementService.DestroyItem(player: Player, uuid: string)
	local playerId = tostring(player.UserId)

	GlobalState.destroyItem(playerId, {
		uuid = uuid,
	})
end

function PlacementService.initialize()
	Remotes.PlaceItem.OnServerEvent:Connect(PlacementService.PlaceItem)
	Remotes.DestroyItem.OnServerEvent:Connect(PlacementService.DestroyItem)
end

return PlacementService
