-- CafeRenderingService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RENDERTAG = "RENDEREDOBJECT"
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CafeTypes = require(script.CafeTypes)
local Cafe = require(script.Cafe)

local CafeRenderingService = {}

local function selectPlayerStatsById(state: GlobalState.GlobalState)
	return state.Stats -- Capitalized to match GlobalState definition
end

local function getPlayerId(stats, playerId: string)
	return playerId
end

local function BasesManager()
	local bases, setBases = useState({})

	useEffect(function()
		local unsub = GlobalState:observe(selectPlayerStatsById, getPlayerId, function(stats, playerId)
			-- Mount/Update logic
			setBases(function(prev)
				local new = table.clone(prev)
				local baseModels = workspace.Bases:GetChildren()

				for _, base in baseModels do
					local taken = new[base]
					if taken then
						continue
					end
					new[base] = playerId
					-- break -- Assigns only one base per player observed
					return new
				end

				local newBases = {}
				for base, pId in new do
					table.insert(newBases, "" .. #newBases .. ")" .. pId)
				end

				warn("[CafeRenderingService] NO BASES LEFT", table.concat(newBases, "\n"))
				return new
			end)

			-- Cleanup logic when the observed state changes/disconnects
			return function()
				setBases(function(prev)
					local new = table.clone(prev)
					-- Remove the base assigned to this specific player
					for base, prevPlayerId in new do
						if prevPlayerId == playerId then
							new[base] = nil
						end
					end
					return new
				end)
			end
		end)

		return function()
			unsub()
		end
	end, {})

	local children = {}
	for base, playerId in bases do
		children[playerId] = e(Cafe, {
			BaseModel = base,
			PlayerId = playerId,
		})
	end

	return e(React.Fragment, nil, children) -- Ensure children are rendered in a Fragment
end

function CafeRenderingService.initialize()
	local rootValue = Instance.new("StringValue", workspace)
	rootValue.Name = "root"

	local root = ReactRoblox.createRoot(rootValue)
	root:render(e(BasesManager))
end

return CafeRenderingService
