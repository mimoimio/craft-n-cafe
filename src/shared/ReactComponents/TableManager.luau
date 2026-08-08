-- Shared/ReactComponents/TableManager.luau
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.React)
local Promise = require(ReplicatedStorage.Packages.Promise)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local DispatchEvent = require(ReplicatedStorage.Shared.Controllers.DispatchEvent)
local Types = require(ReplicatedStorage.Shared.Types)
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef

local TableNode = require(script.Parent.TableNode)
local e = React.createElement
local ANIM_DURATION = 1

local player = game.Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""

local function animateModelToTable(model: Model, finalCFrame: CFrame, initialPosition: Vector3) -- :Promise
	local initialCFrame = CFrame.new(initialPosition)

	-- 2. Create a CFrameValue proxy to tween the entire model beautifully!
	local cframeValue = Instance.new("CFrameValue")
	cframeValue.Value = initialCFrame

	local updateConn = cframeValue.Changed:Connect(function(newCFrame)
		model:PivotTo(newCFrame)
	end)
	local tween = TweenService:Create(
		cframeValue,
		TweenInfo.new(ANIM_DURATION, Enum.EasingStyle.Back, Enum.EasingDirection.InOut, 0, false, 0),
		{ Value = finalCFrame }
	)

	-- tween:Play()

	-- return Promise.fromEvent(tween.Completed)
	return Promise.defer(function(resolve, reject, onCancel)
		local descNum = model:GetAttribute("BasePartDescendants")
		if not descNum then
			return reject("No descnum")
		end

		local basePartDescendants = 0
		local transparencies = {} -- to not flash
		for i, desc in model:GetDescendants() do
			if not desc:IsA("BasePart") then
				continue
			end
			transparencies[desc] = desc.Transparency
			basePartDescendants += 1
		end
		if basePartDescendants >= descNum then
			return resolve(model, transparencies)
		end
		local connection
		connection = model.DescendantAdded:Connect(function(desc)
			if desc:IsA("BasePart") then
				transparencies[desc] = desc.Transparency
			end
			if not desc:IsA("BasePart") then
				return
			end
			basePartDescendants += 1
			if basePartDescendants < descNum then
				return
			end
			resolve(model, transparencies)
			connection:Disconnect()
		end)
		onCancel(function()
			if connection then
				connection:Disconnect()
			end
		end)
		task.wait(1)
	end)
		:andThen(function(model, transparencies)
			for i, desc in model:GetDescendants() do
				if not desc:IsA("BasePart") then
					continue
				end
				desc.Transparency = transparencies[desc]
			end
			model:PivotTo(initialCFrame)
			tween:Play()
			tween.Completed:Wait()
		end)
		:timeout(ANIM_DURATION + 5)
		:andThen(function(playbackState)
			-- warn("Animation completed beautifully with state:", playbackState)
		end)
		:andThen(function()
			updateConn:Disconnect()
			cframeValue:Destroy()
		end)
end
local function DrinksAnimation(props)
	-- this thing sometimes do animations on already placed drinks idk why
	local tag = player and (playerId .. "DrinkModel") or ""
	local drinksRef: { current: { [Model]: true } } = useRef({})
	useEffect(function()
		if not player then
			return
		end
		local conn = CollectionService:GetInstanceAddedSignal(tag):Connect(function()
			-- get models
			local models = CollectionService:GetTagged(tag)

			-- animate each new one

			for i, model in models do
				local found = drinksRef.current[model]
				if found then
					continue
				end
				drinksRef.current[model] = true

				local finalCFrame = model:GetPivot()
				local initialPosition = player and player.Character and player.Character:GetPivot().Position
					or Vector3.zero
				local promis = animateModelToTable(model, finalCFrame, initialPosition)
				-- will doing it like this cause memory leak? it's all uncanceled.
				promis:catch(function(err)
					warn(`Error in animation:`, err)
				end)
			end
		end)

		local conn2 = CollectionService:GetInstanceRemovedSignal(tag):Connect(function()
			local models = CollectionService:GetTagged(tag)
			for ref, _: Model in drinksRef.current do
				if not (ref and ref.Parent) then
					drinksRef.current[ref] = nil
					-- warn("removing", ref)
					continue
				end
				local found = table.find(models, ref)
				if not found then
					-- warn("removing", ref)
					drinksRef.current[ref] = nil
				end
			end
		end)
		return function()
			conn:Disconnect()
			conn2:Disconnect()
		end
	end, {})
	useEffect(function()
		local unsub = DispatchEvent.OnEvent("restockDrinks", function(_playerId, payload: Types.RestockDrinksPayload)
			local models = CollectionService:GetTagged(tag)
			local modelsById = {}

			for i, model in models do
				local uid = model:GetAttribute("uid")
				if not uid then
					warn("not uid")
					continue
				end
				modelsById[uid] = model
			end
			for uid, stock in payload.stockToAdd do
				local templateModel: Model = modelsById[uid]
				if not templateModel then
					continue
				end
				local model = templateModel:Clone()
				model:RemoveTag(tag)

				local finalCFrame = templateModel:GetPivot()
				local initialPosition = (player and player.Character) and player.Character:GetPivot().Position
					or Vector3.zero

				model.Parent = workspace
				local promise = animateModelToTable(model, finalCFrame, initialPosition)

				promise
					:finally(function()
						model:Destroy()
					end)
					:catch(function(err)
						warn(`Error in animation:`, err)
					end)
			end
		end)
		return unsub
	end, {})
	return e(React.Fragment)
end
local function TableManager(props)
	local tablesState, setTablesState = useState({})
	local drinks, setDrinks = useState({})
	local tableInstances, setTableInstances = useState({})

	-- 1. Subscribe strictly to the Tables state slice
	React.useEffect(function()
		local unsub = GlobalState:subscribe(function(state)
			return state.Tables[playerId]
		end, function(newTables)
			setTablesState(newTables or {})
		end)
		local unsub2 = GlobalState:subscribe(function(state)
			return state.Drinks[playerId]
		end, function(newDrinks)
			setDrinks(newDrinks or {})
		end)

		local state = GlobalState:getState()
		if state.Tables and state.Tables[playerId] then
			setTablesState(state.Tables[playerId])
		end
		if state.Drinks and state.Drinks[playerId] then
			setDrinks(state.Drinks[playerId])
		end

		return function()
			unsub()
			unsub2()
		end
	end, { playerId })

	-- 2. Sync Table instances from CollectionService generically
	React.useEffect(function()
		local tag = "Table" .. playerId

		local function syncInstances()
			local currentInstances = {}
			for _, inst in ipairs(CollectionService:GetTagged(tag)) do
				-- Discern specific table via its Name property (e.g. Table1, Table2)
				currentInstances[inst.Name] = inst
			end
			setTableInstances(currentInstances)
		end

		syncInstances()

		local connAdd = CollectionService:GetInstanceAddedSignal(tag):Connect(syncInstances)
		local connRem = CollectionService:GetInstanceRemovedSignal(tag):Connect(syncInstances)

		return function()
			connAdd:Disconnect()
			connRem:Disconnect()
		end
	end, { playerId })

	local children = {}

	for tableId, tableData in pairs(tablesState) do
		children[tableId] = e(TableNode, {
			TableId = tableId,
			TableData = tableData,
			Instance = tableInstances[tableId],
			Drinks = drinks,
		})
	end
	children.DrinksAnimation = e(DrinksAnimation)

	return e(React.Fragment, nil, children)
end

return TableManager
