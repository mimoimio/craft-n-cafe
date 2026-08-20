local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Promise = require(ReplicatedStorage.Packages.Promise)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local DefaultScrollFrame = require(script.Parent.DefaultScrollFrame)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local Grid = require(Primitives.Grid)
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)

-- Point this to your new VFX setup
local IngredientVFXContainer = require(script.Parent.IngredientVFXContainer)
local CLOCK =
	[[<font family="rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json"><b>clock</b></font>]]
local STOCK =
	[[<font family="rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json">three-stacked-squares-tilted</font>]]

local player = game:GetService("Players").LocalPlayer
local playerId: string? = player and tostring(player.UserId) or "0"

local function RecipeHint()
	local resultConfig, setresultConfig = useState(nil)
	local currentIngredients, setCurrentIngredients = useState({})
	local adornee, setAdornee = useState(nil)
	useEffect(function()
		local t = task.defer(function()
			while true do
				setresultConfig(nil)
				local config = CoffeeModule.Array[math.random() * #CoffeeModule.Array // 1]
				if not config then
					task.wait()
					continue
				end
				local ings = {}
				for i, ing in config.Ingredients do
					table.insert(ings, ing)
					setCurrentIngredients(table.clone(ings))
					task.wait(0.5)
				end
				setresultConfig(config)
				task.wait(5)
			end
		end)
		local promise = Promise.defer(function(resolve, reject)
			local RecipeHintModel = workspace:WaitForChild("RecipeHint")
			local Part = RecipeHintModel:WaitForChild("Part")
			if not Part then
				reject(`not part {Part}`)
			end
			return resolve(Part)
		end)
		promise
			:andThen(function(part)
				setAdornee(part)
			end)
			:catch(function(err)
				warn("RecipeHint error: ", err)
			end)
		return function()
			if t then
				task.cancel(t)
			end
			promise:cancel()
		end
	end, {})
	-- local resultConfig = CoffeeModule.Craft(currentIngredients)

	-- MODIFIED: Calculate used ingredients based on BOTH current AND pending
	local usedIngredients = {}
	for _, id in ipairs(currentIngredients) do
		usedIngredients[id] = (usedIngredients[id] or 0) + 1
	end

	local selectedIngredientElements = {}
	for i = 1, 9 do -- set limit to 9 ingredients later
		local id = currentIngredients[i]
		local config = CoffeeModule.IngredientLookup[id] -- Adjusted to grab from Config
		selectedIngredientElements[i] = e(SmallButton, {
			OverlayText = config and config.DisplayName,
			OverlayTextSize = 10,
			-- LayoutOrder = config and config.Price,
			LayoutOrder = i,
			OverlayTextWrapped = true,
			ButtonClass = "ImageButton",
			AutomaticSize = Enum.AutomaticSize.None,
			Image = config and config.Image,
			Size = UDim2.new(0, 50, 0, 50),
			Padding = { All = UDim.new(0, 4) },
			BackgroundColor3 = Color3.fromRGB(84, 52, 52),
		})
	end

	local min = resultConfig and resultConfig.Duration // 60 or nil
	local sec = resultConfig and resultConfig.Duration % 60 or nil
	local stocks = resultConfig and resultConfig.InitialStock
	local durationText = resultConfig and ""
		-- and `<font size="14">$$$</font><font size="18">: {resultConfig.Price} $\n{CLOCK}: {min > 0 and `{min} min ` or ""}{sec} sec </font>\n<font size="18">{STOCK}: {stocks}x</font>`
		or ""

	local new = false
	local resultLabelText = resultConfig and (not new and resultConfig.DisplayName or "???") or ""

	return adornee
			and ReactRoblox.createPortal({
				e("SurfaceGui", {
					ResetOnSpawn = false,
					Adornee = adornee,
					-- Parent = adornee,
					CanvasSize = Vector2.new(300, 450),
					ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
				}, {
					e(VStack, {
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,
						Padding = {
							Top = UDim.new(0, 12),
							Right = UDim.new(0, 12),
							Left = UDim.new(0, 12),
							Bottom = UDim.new(0, 12),
						},
					}, {

						e(HStack, {
							Size = UDim2.new(1, 0, 0.5, 0),
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.new(0, 0, 0.5, 0),
							Spacing = UDim.new(0, 0),
							HorizontalAlignment = Enum.HorizontalAlignment.Left,
							VerticalAlignment = Enum.VerticalAlignment.Top,
							-- MinSize = Vector2.new(350, 300),
							BackgroundTransparency = 1,

							VerticalFlex = Enum.UIFlexAlignment.Fill,
							HorizontalFlex = Enum.UIFlexAlignment.SpaceEvenly,
							LayoutOrder = 1,
						}, {
							IngredientList = e(HStack, {
								-- OnMount = targetRef, -- BIND REF HERE TO ACT AS TARGET POS
								VerticalFlex = Enum.UIFlexAlignment.None,
								VeticalAlignment = Enum.VerticalAlignment.Center,
								HorizontalFlex = Enum.UIFlexAlignment.None,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								AutomaticSize = Enum.AutomaticSize.XY,
								LayoutOrder = 1,
								Size = UDim2.new(0, 0, 1, 0),
							}, {
								e(VStack, {
									Size = UDim2.new(0, 0, 0, 0),
									VerticalFlex = Enum.UIFlexAlignment.None,
									VeticalAlignment = Enum.VerticalAlignment.Bottom,
									HorizontalFlex = Enum.UIFlexAlignment.None,
									HorizontalAlignment = Enum.HorizontalAlignment.Center,
									AutomaticSize = Enum.AutomaticSize.XY,
									LayoutOrder = 3,
									Spacing = UDim.new(0, 2),
								}, {
									e(HStack, {
										HorizontalFlex = Enum.UIFlexAlignment.None,
										HorizontalAlignment = Enum.HorizontalAlignment.Center,
										LayoutOrder = 3,
										Size = UDim2.new(0, 0, 0, 50),
										AutomaticSize = Enum.AutomaticSize.XY,
										Spacing = UDim.new(0, 2),
									}, {
										Ingredients = e(React.Fragment, {}, {
											selectedIngredientElements[1],
											selectedIngredientElements[2],
											selectedIngredientElements[3],
										}),
									}),
									e(HStack, {
										HorizontalFlex = Enum.UIFlexAlignment.None,
										HorizontalAlignment = Enum.HorizontalAlignment.Center,
										Size = UDim2.new(0, 0, 0, 50),
										AutomaticSize = Enum.AutomaticSize.XY,
										LayoutOrder = 3,
										Spacing = UDim.new(0, 2),
									}, {
										Ingredients = e(React.Fragment, {}, {
											selectedIngredientElements[4],
											selectedIngredientElements[5],
											selectedIngredientElements[6],
										}),
									}),
									e(HStack, {
										Size = UDim2.new(0, 0, 0, 50),
										AutomaticSize = Enum.AutomaticSize.XY,
										HorizontalFlex = Enum.UIFlexAlignment.None,
										HorizontalAlignment = Enum.HorizontalAlignment.Center,
										LayoutOrder = 3,
										Spacing = UDim.new(0, 2),
									}, {
										Ingredients = e(React.Fragment, {}, {
											selectedIngredientElements[7],
											selectedIngredientElements[8],
											selectedIngredientElements[9],
										}),
									}),
								}),
							}),
							e(SmallText, {
								Size = UDim2.new(0, 0, 1, 0),
								TextYAlignment = Enum.TextYAlignment.Center,
								LayoutOrder = 2,
								TextSize = 64,
								Text = "=",
							}),
							Result = e(VStack, {
								Size = UDim2.new(0, 0, 1, 0),
								Spacing = UDim.new(0, 2),
								LayoutOrder = 3,
								AutomaticSize = Enum.AutomaticSize.XY,
								HorizontalFlex = Enum.UIFlexAlignment.Fill,
								VerticalFlex = Enum.UIFlexAlignment.Fill,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								Padding = { All = UDim.new() },
								-- BackgroundTransparency = 0,
							}, {
								ResultFrame = e("ImageLabel", {
									Size = UDim2.new(0, 100, 0, 100),
									LayoutOrder = 1,
									BackgroundTransparency = 1,
								}, {
									ResultImageFrame = e("Frame", {
										Size = UDim2.new(0, 100, 0, 100),
										Position = UDim2.new(0.5, 0, 0.5, 0),
										BackgroundTransparency = 1,
										AnchorPoint = Vector2.new(0.5, 0.5),
									}, {
										Background = e("ImageLabel", {
											Size = UDim2.new(0, 100, 0, 100),
											Position = UDim2.new(0.5, 0, 0, 0),
											BackgroundTransparency = 1,
											AnchorPoint = Vector2.new(0.5, 0),
											Image = "rbxassetid://127657596958436",
											ImageColor3 = Color3.new(0.768627, 0.549019, 0.549019),
											ScaleType = Enum.ScaleType.Slice,
											SliceCenter = Rect.new(8, 8, 92, 92),
											ZIndex = 1,
										}, {}),
										ResultLabel = resultConfig and e(SmallText, {
											Text = resultLabelText,
											Size = UDim2.new(1, 0, 0, 0),
											TextSize = 16,
											Position = UDim2.new(0.5, 0, 1, -8),
											AnchorPoint = Vector2.new(0.5, 1),
											RichText = true,
											TextXAlignment = Enum.TextXAlignment.Center,
											ZIndex = 8,
										}),
										ResultImage = e("ImageLabel", {
											Size = UDim2.new(0, 100, 0, 100),
											Position = UDim2.new(0.5, 0, 0, 0),
											BackgroundTransparency = 1,
											AnchorPoint = Vector2.new(0.5, 0),
											Image = resultConfig and resultConfig.Image,
											ZIndex = 3,
										}, {}),
									}),
								}),
							}),
						}),
					}),
				}),
			}, adornee)
		or nil
end

return RecipeHint
