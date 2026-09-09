-- PlacementService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Grid = require(ReplicatedStorage.Shared.Grid)
local Models = ReplicatedStorage.Shared.Models

local PlacementService = {}

function PlacementService.PlaceItem(player: Player, itemId: string, startX: number, startZ: number, rotation: number)
	local playerId = tostring(player.UserId)

	-- 1. Authoritative Prefab Lookup
	local prefab = Models:FindFirstChild(itemId)
	if not prefab then
		warn(`Placement failed: Prefab '{itemId}' does not exist.`)
		return
	end

	-- 2. Authoritative Type Resolution
	local itemTypeAttr = prefab:GetAttribute("ItemType") or "Solid"
	local resolvedItemType = "Solid"

	if itemTypeAttr == "Wall" then
		local isRotated = math.abs(rotation % 180) == 90
		resolvedItemType = isRotated and "Wall_V" or "Wall_H"
	end

	-- 3. Authoritative Math
	local _, itemSize = prefab:GetBoundingBox()
	local width, length = Grid.getFootprint(itemSize, rotation)

	-- Note: Server-side validation (Grid.isAreaFree) could be added here
	-- to prevent malicious exploits before dispatching to the state.

	-- 4. Dispatch to the slice using the trusted resolvedItemType
	GlobalState.placeItem(playerId, {
		itemId = itemId,
		itemType = resolvedItemType,
		startX = startX,
		startZ = startZ,
		width = width,
		length = length,
		rotation = rotation,
	})
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
