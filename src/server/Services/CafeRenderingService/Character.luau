-- CafeRenderingService.luau
--[[
The cup is welded to the character's HumanoidRootPart (or PrimaryPart),
positioned Vector3.new(0, -1, 2) away from it, while the hold-cup
animation plays. Everything is cleaned up on unmount.
]]
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
		local hrp: BasePart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
		if not hrp then
			print("[Cup] no HumanoidRootPart/PrimaryPart on", character:GetFullName())
			return
		end
		print("[Cup] effect running for", character:GetFullName(), "armed with", hrp:GetFullName())

		local clone = model:Clone()
		local basePart = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart", true)
		if not basePart then
			clone:Destroy()
			return
		end
		clone.PrimaryPart = basePart

		local pl = clone:FindFirstChildWhichIsA("PackageLink", true)
		if pl then
			pl:Destroy()
		end

		for _, desc in clone:GetDescendants() do
			if desc:IsA("BasePart") then
				desc.Anchored = false
				desc.CanCollide = false
				desc.Massless = true
			end
		end

		clone:PivotTo(hrp:GetPivot() * CFrame.new(0, -0.2, -2))
		local id = props.PlayerId .. "Cup"
		clone:AddTag(id)
		clone.Parent = workspace

		for _, part in clone:GetDescendants() do
			if part:IsA("BasePart") then
				part:SetNetworkOwner(nil)
			end
		end
		-- proxy:SetNetworkOwner(nil)

		local clonepart = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart")
		local hrpWeld = Instance.new("WeldConstraint")
		hrpWeld.Part0 = hrp
		hrpWeld.Part1 = clonepart
		hrpWeld.Parent = clonepart

		local holdingAnimation: AnimationTrack? = nil
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if animator then
			local animation = Instance.new("Animation")
			animation.AnimationId = "rbxassetid://507768375"
			holdingAnimation = animator:LoadAnimation(animation)
			holdingAnimation.Looped = true
			holdingAnimation.Priority = Enum.AnimationPriority.Action
			holdingAnimation:Play(0.1, 1, 2)
		end

		return function()
			if holdingAnimation then
				holdingAnimation:Stop()
				holdingAnimation:Destroy()
			end
			hrpWeld:Destroy()
			clone:Destroy()
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
		local entrance = props.BaseModel:FindFirstChild("Entrance")
		if entrance then
			character:PivotTo(entrance:GetPivot() + Vector3.new(0, 5, 0))
		else
			character:PivotTo(props.BaseModel:GetPivot() + Vector3.new(0, 5, 0))
		end
	end, { character, props.BaseModel })

	return e(React.Fragment, nil, children) -- Ensure children are rendered in a Fragment
end

return Character
