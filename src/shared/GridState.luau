-- GridState.luau
local GridState = {}
GridState.__index = GridState

export type GridState = typeof(setmetatable({}, GridState))

function GridState.new()
	local self = setmetatable({}, GridState)

	-- Format: ["X_Z"] = "ItemUUID"
	self.occupiedCoordinates = {}

	-- Map of items currently placed: ["ItemUUID"] = { id = "Crate", x = 1, z = 2, w = 2, l = 2 }
	self.placedItems = {}

	return self
end

-- Verifies if a specific area is completely free of other items
function GridState:isAreaFree(startX: number, startZ: number, width: number, length: number): boolean
	for x = startX, startX + width - 1 do
		for z = startZ, startZ + length - 1 do
			local key = `{x}_{z}`
			if self.occupiedCoordinates[key] ~= nil then
				return false
			end
		end
	end
	return true
end

-- Fulfills Use Case: Place Item
function GridState:occupy(uuid: string, itemId: string, startX: number, startZ: number, width: number, length: number)
	if not self:isAreaFree(startX, startZ, width, length) then
		return false
	end

	for x = startX, startX + width - 1 do
		for z = startZ, startZ + length - 1 do
			local key = `{x}_{z}`
			self.occupiedCoordinates[key] = uuid
		end
	end

	self.placedItems[uuid] = {
		id = itemId,
		x = startX,
		z = startZ,
		w = width,
		l = length,
	}

	return true
end

-- Fulfills Use Case: Destroy Item
function GridState:free(uuid: string)
	local itemData = self.placedItems[uuid]
	if not itemData then
		return false
	end

	for x = itemData.x, itemData.x + itemData.w - 1 do
		for z = itemData.z, itemData.z + itemData.l - 1 do
			local key = `{x}_{z}`
			self.occupiedCoordinates[key] = nil
		end
	end

	self.placedItems[uuid] = nil
	return true
end

return GridState
