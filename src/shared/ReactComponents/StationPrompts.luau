-- Shared/ReactComponents/StationPrompts.luau
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Promise = require(ReplicatedStorage.Packages.Promise)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local ScreenPromptButton = require(script.Parent.ui.ScreenPromptButton)
local SmallText = require(script.Parent.ui.SmallText)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or "MockUser"
local tag = "Station" .. playerId

local function StationPromptNode(props: { Model: Model })
	local prompt, setPrompt = useState(nil)

	local visible, setVisible = useState(nil)
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
	useEffect(function()
		if not props.Model then
			return
		end
		-- Use recursive (true) because the prompt is inside the newCenterPart!
		local foundPrompt = props.Model:FindFirstChildWhichIsA("ProximityPrompt", true)
		local promise
		if not foundPrompt then
			Promise.defer(function(resolve, reject, onCancel)
				local prompt = props.Model:WaitForChild("TriggerPrompt", 5)
				if not prompt then
					reject("not prompt")
				end
				resolve(prompt)
			end)
				:andThen(setPrompt)
				:catch(function(err)
					warn("err", err)
				end)
		end

		setPrompt(foundPrompt)
		return function()
			setPrompt(nil)
		end
	end, { props.Model })

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

	return e(React.Fragment, {}, {
		e(ScreenPromptButton, {
			ProximityPrompt = prompt,
			Position = UDim2.new(1, -200, 1, -200),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(200, 50),
			Visible = visible and shown,
		}, {
			e(SmallText, {
				Size = UDim2.new(1, 0, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Center,
				Text = prompt and prompt.ActionText or "",
			}),
		}),
		hi = props.Model and ReactRoblox.createPortal({
			e("Highlight", {
				Adornee = props.Model,
				Enabled = visible and shown,
				FillColor = Color3.new(1, 1, 1),
				-- ref = function(rbx)
				-- 	warn(rbx, props.Model)
				-- end,
				FillTransparency = 0.4,
				OutlineColor = Color3.new(),
			}),
		}, props.Model) or nil,
	})
end

return function()
	local instances, setInstances = useState({})

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

	if not instances or #instances == 0 then
		return nil
	end

	local children = {}
	for _, instance in ipairs(instances) do
		-- Using the instance's UUID name as the React key
		children[instance.Name] = e(StationPromptNode, {
			Model = instance,
		})
	end

	return e(React.Fragment, {}, children)
end
