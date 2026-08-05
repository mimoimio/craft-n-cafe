-- CafeRenderingService/Drinks.luau

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Promise = require(ReplicatedStorage.Packages.Promise)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Types = require(ReplicatedStorage.Shared.Types)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local HStack = require(ReplicatedStorage.Shared.ReactComponents.ui.HStack)
local DrinkModelUtil = require(ReplicatedStorage.Shared.Utils.DrinkModelUtil)

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
    local tool = Instance.new("Tool")
    tool.Name = drink.id
    tool.RequiresHandle = true
    tool.CanBeDropped = false

    local drinkModelTemplate = ReplicatedStorage.Shared.Models:FindFirstChild(drink.drinkId)
    if drinkModelTemplate then
        local ingredientPackageLink = drinkModelTemplate:FindFirstChildWhichIsA("PackageLink", true)
        if ingredientPackageLink then
            local numericId = string.match(tostring(ingredientPackageLink.PackageId), "%d+")
            tool.TextureId = string.format("rbxthumb://type=Asset&id=%s&w=150&h=150", numericId)
        end
    end

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Anchored = false
    handle.CanCollide = false
    handle.Massless = true
    handle.Transparency = 1
    handle.Parent = tool

    local clonedModel, modelBasePart = DrinkModelUtil.BuildDrinkModel(drink.drinkId, drink.variationId, {
        Anchored = false,
        CanCollide = false, -- Matches your previous logic
    })
    
    if not modelBasePart then
        warn(`Drink tool render failed: {drink.id} has no BasePart to weld`)
        tool:Destroy()
        return nil
    end

    clonedModel.Parent = tool
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
	local tool, setTool = useState(nil :: Tool?)

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
		if not (player and character) then
			return
		end
		local tool
		local promise = Promise.defer(function(resolve, reject)
			local backpack = player:WaitForChild("Backpack")

			if not backpack then
				return reject("Not backpack")
			end

			tool = buildDrinkTool(player, props.Drink)
			if not tool then
				return reject("Not tool")
			end

			-- tool.Parent = backpack
			local foundTool = character:FindFirstChildWhichIsA("Tool")
			if foundTool then
				foundTool.Parent = backpack
			end
			tool.Parent = character
			setTool(tool)

			warn(`Parented`)
		end):catch(function(err)
			warn(`Error: {error}`)
		end)
		return function()
			if tool then
				tool:Destroy()
			end
			setTool(nil)
			promise:cancel()
		end
	end, { player, props.Drink.id, props.Drink.drinkId, character })

	-- useEffect(function()

	-- 	return
	-- end, {})
	local variation, displayname, config
	if props.Drink and props.Drink.stock > 0 and tool then
		config = CoffeeModule.Config[props.Drink.drinkId]
		displayname = config and config.DisplayName
		variation = props.Drink.variationId and VariationsConfig[props.Drink.variationId] or nil
		local adornee = tool
		local VariationLabel = variation
				and e(SmallText, {
					TextXAlignment = Enum.TextXAlignment.Center,
					BackgroundTransparency = 1,
					Text = variation.DisplayName,
					TextColor3 = variation.ColorPrimary or Color3.new(1, 1, 1),
					TextSize = 18,
					TextTruncate = Enum.TextTruncate.SplitWord,
					Active = false,
					ZIndex = 20,
					LayoutOrder = 1,
				}, {
					UIStroke = e("UIStroke", {
						Thickness = 4,
						Color = Color3.new(0.070588, 0.070588, 0.168627),
					}, {

						UIGradient = e("UIGradient", {
							-- Color = ColorGradient,
							Rotation = 78,
						}),
					}),
					UIGradient = e("UIGradient", {
						-- Color = ColorGradient,
						Rotation = 69,
					}),
					UIPadding = e("UIPadding", {
						PaddingTop = UDim.new(0, 4),
						PaddingBottom = UDim.new(0, 4),
						PaddingLeft = UDim.new(0, 4),
						PaddingRight = UDim.new(0, 4),
					}),
				})
			or nil
		return ReactRoblox.createPortal({
			e(React.Fragment, nil, {
				BBGui = e("BillboardGui", {
					Active = true,
					Adornee = adornee,
					Size = UDim2.new(0, 60, 0, 30),
					StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0),
					AlwaysOnTop = false,
					MaxDistance = 100,
				}, {
					Label = e(SmallText, {
						TextXAlignment = Enum.TextXAlignment.Center,
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,
						Text = `{props.Drink.stock}x`,
						TextColor3 = Color3.new(1, 1, 1),
						TextStrokeTransparency = 0,
						TextStrokeColor3 = Color3.new(0, 0, 0),
					}),
				}),
				BBGui2 = e("BillboardGui", {
					Active = true,
					Adornee = adornee,
					Size = UDim2.new(0, 60, 0, 30),
					StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0),
					AlwaysOnTop = false,
					MaxDistance = 100,
				}, {
					label = e(HStack, {
						Size = UDim2.new(3, 0, 0, 0),
						Position = UDim2.new(0.5, 0, 1, 0),
						AnchorPoint = Vector2.new(0.5, 1),
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
					}, {
						VariationLabel = VariationLabel,
						NameAndPrice = e(SmallText, {
							LayoutOrder = 2,
							TextXAlignment = Enum.TextXAlignment.Center,
							Text = `{displayname}: {variation and config and (variation.Multiplier * config.Price) or config and config.Price or 0}$`,
						}),
					}),
				}),
			}),
		}, adornee)
	end
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
		setTables(state.Tables[props.PlayerId])

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
