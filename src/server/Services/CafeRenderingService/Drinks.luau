-- CafeRenderingService/Drinks.luau

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Types = require(ReplicatedStorage.Shared.Types)

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState

export type DrinkEntity = Types.DrinkEntity
export type TableEntity = Types.TableEntity

local function getPlayer(playerId: string): Player?
	local userId = tonumber(playerId)
	if not userId then
		return nil
	end

	return Players:GetPlayerByUserId(userId)
end

local function buildDrinkTool(player: Player, drink: DrinkEntity): Tool?
	local drinkModel = ReplicatedStorage.Shared.Models:FindFirstChild(drink.drinkId)
	if not drinkModel then
		warn(`Drink tool render failed: model {drink.id} not found for {player.Name}`)
		return nil
	end

	local tool = Instance.new("Tool")
	tool.Name = drink.id
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	local ingredientPackageLink = drinkModel:FindFirstChildWhichIsA("PackageLink", true)
	if ingredientPackageLink then
		local numericId = string.match(tostring(ingredientPackageLink.PackageId), "%d+")
		tool.TextureId = string.format("rbxthumb://type=Asset&id=%s&w=150&h=150", numericId)
	end

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Anchored = false
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool
	handle.Transparency = 1

	local clonedModel = drinkModel:Clone()
	clonedModel.Parent = tool

	for i, desc: Part in clonedModel:GetDescendants() do
		if not desc:IsA("BasePart") then
			continue
		end
		desc.CollisionGroup = "Walls"
	end

	local modelBasePart = clonedModel:FindFirstChildWhichIsA("BasePart", true)
	if not modelBasePart then
		warn(`Drink tool render failed: {drink.id} has no BasePart to weld`)
		tool:Destroy()
		return nil
	end

	for _, descendant in clonedModel:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
		end
	end

	modelBasePart.Anchored = false
	handle.CFrame = modelBasePart.CFrame

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = modelBasePart
	weld.Parent = handle

	return tool
end

local function DrinkTool(props: {
	PlayerId: string,
	Drink: DrinkEntity,
})
	local player, setPlayer = useState(nil :: Player?)
	local character, setCharacter = useState(nil :: Model?)

	useEffect(function()
		local currentPlayer = getPlayer(props.PlayerId)
		setPlayer(currentPlayer)

		if not currentPlayer then
			warn(`Drink renderer could not find player for id {props.PlayerId}`)
			return
		end

		setCharacter(currentPlayer.Character)

		local characterAdded = currentPlayer.CharacterAdded:Connect(function(newCharacter)
			setCharacter(newCharacter)
		end)

		local characterRemoving = currentPlayer.CharacterRemoving:Connect(function()
			setCharacter(nil)
		end)

		return function()
			characterAdded:Disconnect()
			characterRemoving:Disconnect()
		end
	end, { props.PlayerId })

	useEffect(function()
		if not player then
			return
		end

		local backpack = player:FindFirstChildOfClass("Backpack")
		if not backpack then
			return
		end

		local tool = buildDrinkTool(player, props.Drink)
		if not tool then
			return
		end

		tool.Parent = backpack

		return function()
			tool:Destroy()
		end
	end, { player, props.Drink.id, props.Drink.drinkId })

	return e(React.Fragment)
end
-- local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
-- 	local t = {
-- 		drinks = state.Drinks[props.PlayerId],
-- 		tables = state.Tables[props.PlayerId],
-- 	}
-- 	warn(t)
-- 	return t
-- end, function(newState: { drinks: { DrinkEntity }, tables: { [string]: TableEntity } })
-- 	setDrinks(newState.drinks)
-- 	setTables(newState.tables)
-- end)
local selectDrinks = function(state)
	return state.Drinks
end
local selectTables = function(state)
	return state.Tables
end
local selectValuesByPlayerId = function(playerId: string)
	return Reflex.createSelector({ selectDrinks, selectTables }, function(drinks, tables)
		return {
			drinks = drinks[playerId],
			tables = tables[playerId],
		}
	end)
end
local function Drinks(props: {
	PlayerId: string,
})
	local player, setPlayer = useState(nil :: Player?)
	local drinks, setDrinks = useState(nil :: { DrinkEntity }?)
	local tables: { [string]: TableEntity }, setTables = useState(nil :: { [string]: TableEntity }?)

	useEffect(function()
		local currentPlayer = getPlayer(props.PlayerId)
		setPlayer(currentPlayer)

		if not currentPlayer then
			warn(`Drink renderer could not find player for id {props.PlayerId}`)
		end
		local selectValues = selectValuesByPlayerId(props.PlayerId)
		local unsub = GlobalState:subscribe(selectValues, function(newState: {
			drinks: { DrinkEntity },
			tables: {
				[string]: TableEntity,
			},
		})
			setDrinks(newState.drinks)
			setTables(newState.tables)
		end)

		local state = GlobalState:getState()
		setDrinks(state.Drinks[props.PlayerId])

		return function()
			unsub()
		end
	end, { props.PlayerId })

	local children = {}
	if player and drinks and tables then
		local drinktoslots = {}
		for tableUid, table in tables do
			for slotName, drinkUid in table.Slots do
				if drinkUid == "none" then
					continue
				end
				drinktoslots[drinkUid] = true
			end
		end
		for _, drink in drinks do
			if drinktoslots[drink.id] then
				continue
			end
			children[drink.id] = e(DrinkTool, {
				PlayerId = props.PlayerId,
				Drink = drink,
			})
		end
	end

	return e(React.Fragment, nil, children)
end

return Drinks
