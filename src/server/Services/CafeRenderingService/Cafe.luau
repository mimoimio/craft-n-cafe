-- CafeRenderingService/Cafe.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RENDERTAG = "RENDEREDOBJECT"
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CafeTypes = require(game.ReplicatedStorage.Shared.CafeTypes) -- = require(script.Parent.CafeTypes)

local Tables = require(script.Parent.Tables)
local Stations = require(script.Parent.Stations)
local Mixers = require(script.Parent.Mixers)
local Customers = require(script.Parent.Customers)

local function getCafeTemplate(Level: number): Model
	local ref: ObjectValue = ReplicatedStorage.Shared.InstanceReferences:WaitForChild("CafeTemplateModelsRef")
	local cafetemplateModels: Model = ref and ref.Value
	local template = cafetemplateModels:FindFirstChild("Cafe" .. tostring(Level))
	if not template then
		warn(`{ref},{cafetemplateModels},{template}`)
	end
	return template
end

local function Cafe(props: {
	BaseModel: CafeTypes.CafeBase,
	PlayerId: string,
})
	local stats, setStats = useState(nil)
	local clonedCafe: Model, setClonedCafe = useState(nil)
	local level = stats and stats.Level
	useEffect(function()
		local state = GlobalState:getState()
		local playerStats = state.Stats[props.PlayerId]
		setStats(playerStats)
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			for playerId, stats in state.Stats do
				if playerId == props.PlayerId then
					return stats
				end
			end
		end, function(newStats, prevStats)
			setStats(newStats)
		end)

		return function()
			unsub()
		end
	end, { props.PlayerId })

	useEffect(function()
		if not level then
			return
		end
		local cafeTemplate = getCafeTemplate(stats.Level)
		if cafeTemplate then
			local clone = cafeTemplate:Clone()
			clone:PivotTo(props.BaseModel:GetPivot())
			clone.Name = "Cafe"
			-- Parent it to the BaseModel so your type definitions hold true in the Explorer!
			clone.Parent = props.BaseModel
			for i, desc: Part in clone:GetDescendants() do
				if not desc:IsA("BasePart") or desc == clone.Part then
					continue
				end
				desc.CollisionGroup = "Walls"
			end

			-- Tell React the model is ready!
			setClonedCafe(clone)

			return function()
				clone:Destroy()
				-- We don't need to setClonedCafe(nil) because the component is unmounting
			end
		else
			warn("CAFE TEMPLATE NOT FOUND")
		end
	end, { level, props.BaseModel })

	local children = {}
	-- 3. ONLY render children if the dynamic object exists!
	if clonedCafe then
		-- Pass the clone directly down so children don't have to drill props.BaseModel.Cafe
		children.tables = e(Tables, {
			PlayerId = props.PlayerId,
			Stats = stats,
			CafeModel = clonedCafe,
		})
		children.stations = e(Stations, {
			PlayerId = props.PlayerId,
			Stats = stats,
			CafeModel = clonedCafe,
		})
		-- Fixed a bug here where Mixers was overwriting children.stations
		children.mixers = e(Mixers, {
			PlayerId = props.PlayerId,
			Stats = stats,
			CafeModel = clonedCafe,
		})

		children.Customers = e(Customers, {
			PlayerId = props.PlayerId,
			CafeModel = clonedCafe,
			BaseModel = props.BaseModel,
		})
	end
	return e(React.Fragment, nil, children)
end

return Cafe
