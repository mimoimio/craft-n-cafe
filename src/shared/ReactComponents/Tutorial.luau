-- Shared/ReactComponents/Tutorial.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Promise = require(ReplicatedStorage.Packages.Promise)

local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local SmallText = require(Primitives.SmallText)

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState
local useBinding = React.useBinding
local useCallback = React.useCallback
local useRef = React.useRef

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or "MockUser"

-------------------------------------------------------------------------------
-- Local Component: ScreenGuiCircle (For 2D UI Targets)
-------------------------------------------------------------------------------
local function ScreenGuiCircle(props: { TargetButton: GuiButton?, Color: Color3? })
	local time, setTime = useBinding(workspace:GetServerTimeNow())

	useEffect(function()
		local running = true
		local t = task.spawn(function()
			while running do
				task.wait()
				setTime(workspace:GetServerTimeNow())
			end
		end)
		return function()
			running = false
			task.cancel(t)
		end
	end, {})

	local sizeMap = useCallback(function(t)
		local pulse = math.sin(t * 5) * 5
		return UDim2.fromOffset(60 + pulse, 60 + pulse)
	end, {})

	local posMap = useCallback(function(t)
		if not props.TargetButton then
			return UDim2.new()
		end
		local center = props.TargetButton.AbsolutePosition + (props.TargetButton.AbsoluteSize / 2)
		return UDim2.fromOffset(center.X, center.Y)
	end, { props.TargetButton })

	if not props.TargetButton then
		return nil
	end

	return e("ScreenGui", { DisplayOrder = 1010 }, {
		Wrapper = e("Frame", {
			BackgroundTransparency = 1,
			Position = time:map(posMap),
			Size = UDim2.fromOffset(60, 60),
			AnchorPoint = Vector2.new(0.5, 0.5),
		}, {
			Circle = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = time:map(sizeMap),
				BackgroundColor3 = props.Color or Color3.new(1, 1, 1),
				BackgroundTransparency = 0.8,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Stroke = e("UIStroke", {
					Color = props.Color or Color3.new(1, 1, 1),
					Thickness = 3,
				}),
			}),
		}),
	})
end

-------------------------------------------------------------------------------
-- Local Component: PointerBeam (For 3D Workspace Targets)
-------------------------------------------------------------------------------
local function PointerBeam(props: { Adornee: PVInstance? })
	local char: Model?, setChar = useState(nil)
	local time, setTime = useBinding(workspace:GetServerTimeNow())

	useEffect(function()
		local running = true
		local t = task.spawn(function()
			while running do
				task.wait()
				setTime(workspace:GetServerTimeNow())
			end
		end)
		return function()
			running = false
			task.cancel(t)
		end
	end, {})

	useEffect(function()
		if not player then
			return
		end
		local conn = player.CharacterAdded:Connect(function(character)
			setChar(character)
		end)
		if player.Character then
			setChar(player.Character)
		end

		return function()
			if conn then
				conn:Disconnect()
			end
		end
	end, {})

	useEffect(function()
		if not (char and props.Adornee) then
			return
		end

		local part0 = Instance.new("Part")
		part0.Anchored = false
		part0.CanCollide = false
		part0.Transparency = 1
		part0:PivotTo(char:GetPivot() - Vector3.new(0, 2, 0))
		part0.Parent = workspace

		local weld = Instance.new("WeldConstraint", part0)
		weld.Part0 = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
		weld.Part1 = part0

		local att0 = Instance.new("Attachment", part0)
		local att1 = Instance.new("Attachment", props.Adornee)

		local beam = Instance.new("Beam", part0)
		beam.Attachment0 = att0
		beam.Attachment1 = att1
		beam.FaceCamera = true
		beam.Texture = "rbxassetid://139863296810113" -- Adjust to your beam texture
		beam.Width0 = 1
		beam.Width1 = 1
		beam.LightEmission = 1
		beam.Brightness = 10

		return function()
			if att1 then
				att1:Destroy()
			end
			part0:Destroy()
		end
	end, { char, props.Adornee })

	local positionMap = useCallback(function(t)
		return UDim2.new(0.5, 0, 0.5, math.sin(t * 5) * 50)
	end, {})

	if not props.Adornee then
		return nil
	end

	return e("BillboardGui", {
		Adornee = props.Adornee,
		AlwaysOnTop = true,
		Size = UDim2.new(0, 1000, 0, 1000),
	}, {
		Holder = e("Frame", {
			Size = UDim2.new(0, 50, 0, 50),
			Position = time:map(positionMap),
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
		}, {
			Arrow = e("ImageLabel", {
				Size = UDim2.new(0, 50, 0, 50),
				BackgroundTransparency = 1,
				Rotation = 0,
				Image = "rbxassetid://8152628560", -- Bouncing arrow texture
			}),
		}),
	})
end

-------------------------------------------------------------------------------
-- Main Tutorial Component
-------------------------------------------------------------------------------
local function Tutorial()
	local globalStates, setGlobalStates = useState(GlobalState:getState())
	local uiStates, setUiStates = useState(UIState:getState())
	local completed, setCompleted = useState(false)

	local time, setTime = useBinding(workspace:GetServerTimeNow())

	-- warn("son")
	-- 1. Subscriptions
	useEffect(function()
		local unsubGlobal = GlobalState:subscribe(function(s)
			return s
		end, setGlobalStates)
		local unsubUI = UIState:subscribe(function(s)
			return s
		end, setUiStates)

		setGlobalStates(GlobalState:getState())
		setUiStates(UIState:getState())

		return function()
			unsubGlobal()
			unsubUI()
		end
	end, {})

	-- Text Animation loop
	useEffect(function()
		local running = true
		local t = task.spawn(function()
			while running do
				task.wait(1 / 15)
				setTime(workspace:GetServerTimeNow())
			end
		end)
		return function()
			running = false
			task.cancel(t)
		end
	end, {})

	local stats = globalStates.Stats[playerId]
	local plotState = globalStates.Plot[playerId]
	local customers = globalStates.Customers[playerId] or {}
	local cups = globalStates.Cups[playerId] or {}
	local myCup = cups["player"] -- Assuming the local player is the worker

	-- ==========================================
	-- Helper: Find Dynamic 3D Models in Plot
	-- ==========================================
	local function findTargetModel(itemId: string): PVInstance?
		if not plotState or not uiStates.cafeBase then
			return nil
		end
		local targetUuid = nil

		for uuid, item in pairs(plotState.placedItems or {}) do
			if item.id == itemId then
				targetUuid = uuid
				break
			end
		end
		if not targetUuid then
			for uuid, item in pairs(plotState.spatialItems or {}) do
				if item.id == itemId then
					targetUuid = uuid
					break
				end
			end
		end

		if targetUuid then
			-- Find the model by UUID inside the CafeBase
			local model = uiStates.cafeBase:FindFirstChild(targetUuid, true)
			if model then
				-- return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart") or model
				return model
			end
		end
		return nil
	end

	-- ==========================================
	-- Logic Ladder
	-- ==========================================
	local stepText = ""
	local beamTarget3D = nil
	local circleTarget2D = nil
	local customersServed = stats and stats.CustomersServed or 0

	local activeCustomer = nil
	for _, customer in pairs(customers) do
		if customer.customerAction == "queuing" or customer.customerAction == "waiting" then
			activeCustomer = customer
			break
		end
	end

	-- warn("completed", completed)
	-- warn("customersServed", customersServed)
	if completed or customersServed >= 2 then
		stepText = "Tutorial Complete! You're ready to run the cafe!"

		-- Fire Completion only once
		if not completed then
			setCompleted(true)
			task.delay(5, function()
				if Remotes.CompleteTutorial then
					Remotes.CompleteTutorial:FireServer()
				end
			end)
		end
	elseif not stats then
		stepText = "Loading Cafe Data..."
	elseif not stats.CafeOpen then
		stepText = "Welcome to your Cafe! Let's open for business."
		-- Assuming your Open Cafe button registers its ref into UIState, e.g., uiStates.openCafeButton
		circleTarget2D = uiStates.openCafeButton
	elseif not activeCustomer then
		stepText = customersServed == 1 and "Great job! Let's wait for one more customer."
			or "Your cafe is open! Wait for a customer to enter."
	elseif activeCustomer.customerAction == "queuing" then
		stepText = "A customer is at the register! Go take their order."
		local char = workspace:FindFirstChild(activeCustomer.id)
		if char then
			beamTarget3D = char:FindFirstChild("HumanoidRootPart")
		end
	elseif activeCustomer.customerAction == "waiting" and activeCustomer.order then
		local orderConfig = CoffeeModule.Config[activeCustomer.order]
		local cupConfig = (myCup and myCup.drinkId and myCup.drinkId ~= "none") and CoffeeModule.Config[myCup.drinkId]
			or nil

		local orderIngredients = orderConfig and orderConfig.Ingredients or {}
		local cupIngredients = cupConfig and cupConfig.Ingredients or {}

		local ruined = false
		local nextIngredient = nil

		if myCup and myCup.drinkId == activeCustomer.order then
			stepText = "Perfect! Bring the order to the customer."
			local char = workspace:FindFirstChild(activeCustomer.id)
			if char then
				beamTarget3D = char:FindFirstChild("HumanoidRootPart")
			end
		else
			-- Verify ingredients one by one
			for i, neededIng in ipairs(orderIngredients) do
				local currentIng = cupIngredients[i]
				if currentIng == nil then
					nextIngredient = neededIng
					break
				elseif currentIng ~= neededIng then
					ruined = true
					break
				end
			end
			-- Ruined if cup has more ingredients than needed
			if #cupIngredients > #orderIngredients then
				ruined = true
			end

			if ruined then
				stepText = "Oh no, you messed up the recipe! Throw it in the trash."
				beamTarget3D = findTargetModel("trash") or findTargetModel("trash_can")
			-- elseif not myCup or myCup.drinkId == "none" then
			elseif not myCup then
				stepText = "Grab a fresh Cup to start the order."
				beamTarget3D = findTargetModel("cup_station")
			elseif nextIngredient then
				local ingConfig = CoffeeModule.IngredientLookup[nextIngredient]
				stepText = `Go to the {ingConfig and ingConfig.DisplayName or nextIngredient} station.`
				-- Dynamically find the station for the needed ingredient!
				beamTarget3D = findTargetModel(nextIngredient .. "_station")
			end
		end
	end

	-- Text Bouncy Animation
	local textRef = useRef("")
	useEffect(function()
		textRef.current = stepText
	end, { stepText })

	local textMap = useCallback(function(t)
		local finalTexts = {}
		local originalText = textRef.current or ""
		local length = string.len(originalText)
		for i = 1, length do
			local offset = (math.sin((t + i) * 5) + 1) * 2
			table.insert(finalTexts, `<font size="{18 + offset // 1}">{string.sub(originalText, i, i)}</font>`)
		end
		return table.concat(finalTexts)
	end, {})

	if completed and customersServed >= 2 and stepText == "" then
		return nil
	end

	return e("ScreenGui", {
		DisplayOrder = 1005,
	}, {
		-- Main Text Banner
		Banner = e("ImageLabel", {
			Size = UDim2.new(0.5, 0, 0, 40),
			AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2.new(0.5, 0, 1, -80),
			AnchorPoint = Vector2.new(0.5, 1),
			Image = "rbxassetid://127657596958436",
			ImageTransparency = 0.6,
			ImageColor3 = Color3.new(0.2, 0.2, 0.2),
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(8, 8, 92, 92),
			BackgroundTransparency = 1,
		}, {
			Padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 20),
				PaddingRight = UDim.new(0, 20),
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
			}),
			Text = e(SmallText, {
				RichText = true,
				Size = UDim2.new(1, 0, 1, 0),
				Text = time:map(textMap),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				MaxTextSize = 24,
			}),
		}),

		-- Dynamic 3D Beam
		PointerBeam = beamTarget3D and e(PointerBeam, {
			Adornee = beamTarget3D,
		}),

		-- Highlight Outline around target
		AdorneeHighlight = beamTarget3D and e("Highlight", {
			Adornee = beamTarget3D:FindFirstChildWhichIsA("Model") or beamTarget3D,
			FillColor = Color3.new(0.5, 1, 0.5),
			FillTransparency = 0.5,
			OutlineColor = Color3.new(0, 1, 0),
			OutlineTransparency = 0,
		}),

		-- 2D UI Target Tracker (e.g., Open Cafe Button)
		ScreenGuiCircle = circleTarget2D and e(ScreenGuiCircle, {
			TargetButton = circleTarget2D,
			Color = Color3.new(1, 0.8, 0),
		}),
	})
end

return Tutorial
