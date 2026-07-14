-- CafeRenderingService.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RENDERTAG = "RENDEREDOBJECT"
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CafeTypes = require(game.ReplicatedStorage.Shared.CafeTypes) -- = require(script.CafeTypes)

local CafeRenderingService = {}

local function selectPlayerStatsById(state: GlobalState.GlobalState)
	return state.Stats -- Capitalized to match GlobalState definition
end

local function getPlayerId(stats, playerId: string)
	return playerId
end

local function Character(props: {
	PlayerId: string,
	BaseModel: CafeTypes.CafeBase,
})
	local children = {}
	local character: Model, setCharacter = useState(nil)
	useEffect(function()
		if not props.PlayerId then
			return
		end
		local player = Players:GetPlayerByUserId(tonumber(props.PlayerId))
		if not player then
			return
		end
		setCharacter(player.Character)
		local conn = player.CharacterAdded:Connect(function(model: Model)
			setCharacter(model)
		end)
		return function()
			conn:Disconnect()
		end
	end, { props.PlayerId })
	useEffect(function()
		if not (character and props.BaseModel) then
			-- warn(`not character ({character}) and props.BaseModel ({props.BaseModel})`)
			return
		end
		for i, d in character:GetDescendants() do
			if d:IsA("BasePart") then
				d.CollisionGroup = "Players"
			end
		end
		character:PivotTo(
			(props.BaseModel.Entrance:GetPivot() + Vector3.new(0, 10, 0)) * CFrame.Angles(0, math.pi / 2, 0)
		)
		return function() end
	end, { character, props.BaseModel })
	return e(React.Fragment, nil, children) -- Ensure children are rendered in a Fragment
end

return Character
