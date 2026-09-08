-- CafeRenderingService.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local RENDERTAG = "RENDEREDOBJECT"
local React = require(ReplicatedStorage.Packages.React)
local Promise = require(ReplicatedStorage.Packages.Promise)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CafeTypes = require(game.ReplicatedStorage.Shared.CafeTypes) -- = require(script.CafeTypes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local Types = require(ReplicatedStorage.Shared.Types)

local isEdit = not RunService:IsRunning() and RunService:IsStudio()

local function Cup(props: { Character: Model, PlayerId: string, WorkerId: string })
	local children = {}
	local config, setConfig = useState(nil)
	local character = props.Character
	local workerId = props.WorkerId or "player"

	useEffect(function()
		if not (props.PlayerId and workerId) then
			return
		end
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Cups[props.PlayerId]
		end, function(playersCups)
			if playersCups and type(playersCups) == "table" then
				local cup: Types.CupEntity = playersCups[workerId]
				local config = CoffeeModule.Config[cup and cup.drinkId or nil]
				if cup and not config then
					config = { Id = "cup", DisplayName = "Cup" }
				end
				setConfig(config)
			end
		end)
		local state = GlobalState:getState()
		local playersCups = state.Cups[props.PlayerId]
		if playersCups and type(playersCups) == "table" then
			local cup: Types.CupEntity = playersCups[workerId]
			local config = CoffeeModule.Config[cup and cup.drinkId or nil]
			if cup and not config then
				config = { Id = "cup", DisplayName = "Cup" }
			end
			setConfig(config)
		end
		return unsub
	end, { props.PlayerId })

	useEffect(function()
		if not (config and character) then
			return
		end
		local model = ReplicatedStorage.Shared.Models:FindFirstChild(config.Id)
		if not model then
			warn("model not found")
			return
		end
		local clone = model:Clone()
		local pl = clone:FindFirstChildWhichIsA("PackageLink", true)

		local tool = Instance.new("Tool")
		tool.Name = config.DisplayName
		if pl then
			local numericId = string.match(tostring(pl.PackageId), "%d+")
			tool.TextureId = string.format("rbxthumb://type=Asset&id=%s&w=150&h=150", numericId)
			pl:Destroy()
		end

		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Parent = tool
		handle.Transparency = 1
		handle.CanCollide = false
		clone:PivotTo(tool:GetPivot())
		clone.Parent = tool
		for i, desc: BasePart in clone:GetDescendants() do
			if not desc:IsA("BasePart") then
				continue
			end

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = handle
			weld.Part1 = desc
			weld.Parent = handle

			desc.Anchored = false
			desc.CanCollide = false
		end
		local toolInCharacter = character:FindFirstChildWhichIsA("Tool")
		if toolInCharacter then
			local player = Players:GetPlayerByUserId(tonumber(props.PlayerId))
			if player and player.Backpack then
				toolInCharacter.Parent = player.Backpack
			end
		end
		tool.Parent = character
		return function()
			tool:Destroy()
		end
	end, { config, character })

	return e(React.Fragment, nil, children)
end

local function Character(props: {
	PlayerId: string,
	BaseModel: CafeTypes.CafeBase,
})
	local children = {}
	local character: Model, setCharacter = useState(nil)
	children.Cup = e(Cup, {
		Character = character,
		PlayerId = props.PlayerId,
	})
	useEffect(function()
		if isEdit then
			return
		end
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
		local promise = Promise.defer(function(resolve)
			local cafe = props.BaseModel:WaitForChild("Cafe", 1)
			-- local cf, _s = cafe:GetBoundingBox()
			local cf = cafe:WaitForChild("SpawnPoint", 1):GetPivot()
			character:PivotTo((cf + Vector3.new(0, 5, 0)))
			return resolve()
		end)
			:catch(function(err)
				-- warn(`No spawnpoint: {tostring(err)}`)
				local cafe = props.BaseModel:WaitForChild("Cafe", 1)
				character:PivotTo(cafe:GetPivot())
			end)
			:catch(function(err)
				warn("pivot error")
			end)
		return function()
			promise:cancel()
		end
	end, { character, props.BaseModel })

	return e(React.Fragment, nil, children) -- Ensure children are rendered in a Fragment
end

return Character
