-- Shared/ReactComponents/CustomerPrompts.luau
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Promise = require(ReplicatedStorage.Packages.Promise)

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)

local ScreenPromptButton = require(script.Parent.ui.ScreenPromptButton)
local SmallText = require(script.Parent.ui.SmallText)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or "MockUser"
local tag = "Customer" .. playerId

local function CustomerPromptNode(props: {
	Model: Model,
	CustomerData: any,
})
	local prompt, setPrompt = useState(nil)
	local visible, setVisible = useState(true)

	-- 1. Sync with UIState (Hide standard prompt UI when menus are open)
	useEffect(function()
		local function selectPanel(state)
			return state.panel
		end
		local unsub = UIState:subscribe(selectPanel, function(panel)
			setVisible(panel == "none")
		end)
		setVisible(selectPanel(UIState:getState()) == "none")
		return unsub
	end, {})

	-- 2. Find TriggerPrompt securely
	useEffect(function()
		if not props.Model then
			return
		end

		local foundPrompt = props.Model:FindFirstChildWhichIsA("ProximityPrompt", true)
		if not foundPrompt then
			Promise.defer(function(resolve, reject)
				local p = props.Model:WaitForChild("TriggerPrompt", 5)
				if not p then
					reject("not prompt")
				end
				resolve(p)
			end)
				:andThen(setPrompt)
				:catch(function(err)
					warn("err", err)
				end)
		else
			setPrompt(foundPrompt)
		end

		return function()
			setPrompt(nil)
		end
	end, { props.Model })

	-- 3. Hover state
	local shown, setShown = useState(false)
	useEffect(function()
		if not (prompt and prompt.Parent) then
			return
		end
		prompt.Style = Enum.ProximityPromptStyle.Custom
		local conn1 = prompt.PromptShown:Connect(function()
			setShown(true)
		end)
		local conn2 = prompt.PromptHidden:Connect(function()
			setShown(false)
		end)
		return function()
			setShown(false)
			conn1:Disconnect()
			conn2:Disconnect()
		end
	end, { prompt, prompt and prompt.Parent })

	-- 4. Check if the player is currently serving this specific customer
	local isServing = props.CustomerData and props.CustomerData.servedBy == "player"

	return e(React.Fragment, {}, {
		-- The Interactive Custom UI (Only shows when hovered and panels are closed)
		PromptUI = e(ScreenPromptButton, {
			ProximityPrompt = prompt,
			Position = UDim2.new(1, -200, 1, -200),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(200, 50),
			Visible = visible,
		}, {
			e(SmallText, {
				Size = UDim2.new(1, 0, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Center,
				Text = prompt and prompt.ActionText or "",
			}),
		}),

		-- The Highlight (Shows when hovered, OR permanently stays on if currently serving!)
		Highlight = props.Model and ReactRoblox.createPortal({
			e("Highlight", {
				Adornee = props.Model and props.Model.Parent and props.Model or nil,
				Enabled = isServing or (visible and shown),
				FillColor = Color3.new(1, 1, 1),
				FillTransparency = 0.4,
				OutlineColor = shown and Color3.new() or isServing and Color3.new(0.4, 1, 0.4) or nil, -- Green outline if serving
				-- ref = warn,
			}),
		}, props.Model) or nil,

		-- The Serving Indicator (Stays visible even if panels are open)
		ServingBillboard = isServing and e("BillboardGui", {
			Adornee = props.Model and props.Model.Parent and props.Model.PrimaryPart or nil,
			Size = UDim2.fromOffset(200, 40),
			ExtentsOffsetWorldSpace = Vector3.new(0, 3.5, 0), -- Floats safely above the customer model
			AlwaysOnTop = true,
			ref = function() end,
		}, {
			e(SmallText, {
				Size = UDim2.new(1, 0, 1, 0),
				Text = "Currently Serving",
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextColor3 = Color3.new(0.4, 1, 0.4), -- Matching green text
				TextStrokeTransparency = 0,
			}),
		}) or nil,
	})
end

return function()
	local instances, setInstances = useState({})
	local customers, setCustomers = useState({})

	-- Listen for Tags
	useEffect(function()
		local function updateInstances()
			setInstances(CollectionService:GetTagged(tag))
		end

		local onTagAdded = CollectionService:GetInstanceAddedSignal(tag):Connect(updateInstances)
		local onTagRemoved = CollectionService:GetInstanceRemovedSignal(tag):Connect(updateInstances)

		updateInstances()

		return function()
			onTagAdded:Disconnect()
			onTagRemoved:Disconnect()
		end
	end, {})

	-- Listen for Customer State natively
	useEffect(function()
		local function selectCustomers(state)
			return state.Customers and state.Customers[playerId] or nil
		end

		local unsub = GlobalState:subscribe(selectCustomers, setCustomers)
		setCustomers(selectCustomers(GlobalState:getState()))

		return unsub
	end, {})

	if not instances or #instances == 0 then
		return nil
	end

	local children = {}
	local cusdict = {}
	for _, customer in customers or {} do
		cusdict[customer.id] = customer
	end

	for _, instance in ipairs(instances) do
		if not cusdict[instance.Name] then
			continue
		end

		-- Pass BOTH the 3D model and the State data to the prompt!
		children[instance.Name .. "cus"] = e(CustomerPromptNode, {
			Model = instance,
			CustomerData = cusdict[instance.Name],
		})
	end

	return e(React.Fragment, {}, children)
end
