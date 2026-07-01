local DispatchEvent = {}

-- Store our callbacks in a dictionary where the key is the action name
local callbacks: { [string]: { (...any) -> () } } = {}

-- Type definition for the action structure matching Reflex's network payload
type ActionPayload = {
	arguments: { any },
	name: string,
}

function DispatchEvent.OnActionsDispatched(actions: { ActionPayload })
	for _, action in ipairs(actions) do
		local actionCallbacks = callbacks[action.name]

		-- If there are any listeners for this specific action, fire them
		if actionCallbacks then
			for _, callback in ipairs(actionCallbacks) do
				-- Use task.spawn so if a callback yields or errors,
				-- it doesn't break the loop or the rest of the dispatch process
				task.spawn(callback, table.unpack(action.arguments))
			end
		end
	end
end

-- Subscribes a callback to a specific action name
function DispatchEvent.OnEvent(actionName: string, callback: (...any) -> ())
	-- Initialize the table for this action if it doesn't exist yet
	if not callbacks[actionName] then
		callbacks[actionName] = {}
	end

	table.insert(callbacks[actionName], callback)

	-- Return a "disconnect" function so listeners can clean up after themselves
	-- (Very important to prevent memory leaks!)
	return function()
		local actionCallbacks = callbacks[actionName]
		if actionCallbacks then
			local index = table.find(actionCallbacks, callback)
			if index then
				table.remove(actionCallbacks, index)
			end
		end
	end
end

return DispatchEvent
