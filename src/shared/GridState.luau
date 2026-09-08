-- GridState.luau
export type PlacedItem = {
	id: string,
	x: number,
	z: number,
	w: number,
	l: number,
}
export type GridState = {
	occupiedCoordinates: { [string]: string },
	placedItems: { [string]: PlacedItem },
}

local GridState: GridState = {}
GridState.__index = GridState

function GridState.new(): GridState
	local self = setmetatable({
		-- Format: ["X_Z"] = "ItemUUID"
		occupiedCoordinates = {} :: { [string]: string },

		-- Map of items currently placed: ["ItemUUID"] = { id = "Crate", x = 1, z = 2, w = 2, l = 2 }
		placedItems = {} :: { [string]: PlacedItem },
	}, GridState)

	return self
end

-- Verifies if a specific area is completely free of other items
function GridState:isAreaFree(startX: number, startZ: number, width: number, length: number): boolean
	for x = startX, startX + width - 1 do
		for z = startZ, startZ + length - 1 do
			local key: string = `{x}_{z}`
			if self.occupiedCoordinates[key] ~= nil then
				return false
			end
		end
	end
	return true
end

-- Fulfills Use Case: Place Item
function GridState:occupy(
	uuid: string,
	itemId: string,
	startX: number,
	startZ: number,
	width: number,
	length: number
): boolean
	if not self:isAreaFree(startX, startZ, width, length) then
		return false
	end

	local xs: { string } = {}
	for x = startX, startX + width - 1 do
		local zs: { string } = {}
		for z = startZ, startZ + length - 1 do
			local key: string = `{x}_{z}`
			self.occupiedCoordinates[key] = uuid
			-- table.insert(zs, `({key})`)
		end
		-- table.insert(xs, table.concat(zs, ", "))
	end
	-- warn(table.concat(xs, ",\n"))

	local item: PlacedItem = {
		id = itemId,
		x = startX,
		z = startZ,
		w = width,
		l = length,
	}
	-- warn("item", item)
	self.placedItems[uuid] = item

	return true
end

-- Fulfills Use Case: Destroy Item
function GridState:free(uuid: string): boolean
	local itemData: PlacedItem? = self.placedItems[uuid]
	if not itemData then
		return false
	end

	for x = itemData.x, itemData.x + itemData.w - 1 do
		for z = itemData.z, itemData.z + itemData.l - 1 do
			local key: string = `{x}_{z}`
			self.occupiedCoordinates[key] = nil
		end
	end

	self.placedItems[uuid] = nil
	return true
end

return GridState
