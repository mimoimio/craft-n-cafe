-- Shared/ReactComponents/ShopPanel/StaffTab.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local WorkersConfig = require(ReplicatedStorage.Shared.Configs.WorkersConfig)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local VStack = require(Primitives.VStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local WorkerManagementCard = require(script.Parent.WorkerManagementCard)

local e = React.createElement

local function StaffTab(props: { playerWorkers: { any }?, playerStats: any })
	local children = {}
	local workerCount = props.playerWorkers and #props.playerWorkers or 0
	local nextWorkerTier = WorkersConfig[workerCount + 1]

	if nextWorkerTier then
		local canAfford = props.playerStats.Cash >= nextWorkerTier.Cost
		local levelMet = props.playerStats.Level >= nextWorkerTier.UnlockLevel
		local statusText = `(${nextWorkerTier.Cost})`
		local bgColor = Color3.new(0.2, 0.5, 0.8)

		if not levelMet then
			statusText = `(Unlocks Lvl {nextWorkerTier.UnlockLevel})`
			bgColor = Color3.new(0.4, 0.4, 0.4)
		elseif not canAfford then
			statusText = `(TOO EXPENSIVE)`
			bgColor = Color3.new(0.6, 0.2, 0.2)
		end

		children.HireWorker = e(SmallButton, {
			Size = UDim2.new(1, -8, 0, 76),
			AutomaticSize = Enum.AutomaticSize.None,
			BackgroundColor3 = bgColor,
			LayoutOrder = -10,
			[React.Event.Activated] = function()
				if levelMet then
					if canAfford then
						Remotes.HireWorker:FireServer()
					else
						UIState.toggle("store")
					end
				end
			end,
			Image = canAfford and "rbxassetid://128846321008253" or "rbxassetid://91750414973277",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(50, 50, 54, 57),
			Rounded = false,
			HoverScale = true,
		}, {
			-- e("UIStroke", { Thickness = 2, Color = Color3.new(0.5, 0.8, 1) }),
			e(SmallText, {
				Text = `Hire a Barista (${nextWorkerTier.Cost})`
					.. `{not levelMet and `\nUnlocked at {nextWorkerTier.UnlockLevel}` or ""}`,
				RichText = true,
				Size = UDim2.new(1, 0, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextWrapped = true,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
			-- not levelMet and e(SmallText, {
			-- 	Text = `Unlocked at {nextWorkerTier.UnlockLevel}`,
			-- 	RichText = true,
			-- 	Size = UDim2.new(1, 0, 1, 0),
			-- 	TextXAlignment = Enum.TextXAlignment.Center,
			-- 	TextYAlignment = Enum.TextYAlignment.Center,
			-- }),
		})
	else
		children.MaxWorkers = e(SmallButton, {
			Size = UDim2.new(1, -8, 0, 64),
			AutomaticSize = Enum.AutomaticSize.None,
			BackgroundColor3 = Color3.new(0.4, 0.4, 0.4),
			LayoutOrder = -10,
		}, {
			e("UIStroke", { Thickness = 2, Color = Color3.new(0.8, 0.8, 0.8) }),
			e(SmallText, {
				Text = `Maximum Staff Reached!`,
				RichText = true,
				Size = UDim2.new(1, 0, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
		})
	end

	for idx, worker in ipairs(props.playerWorkers or {}) do
		children["WORKER_CARD_" .. worker.id] = e(WorkerManagementCard, {
			worker = worker,
			index = idx,
			playerCash = props.playerStats.Cash,
			Visible = true,
			LayoutOrder = idx,
		})
	end

	return e(VStack, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		VerticalFlex = "None",
		Spacing = UDim.new(0, 8),
		Padding = { All = UDim.new(0, 12) },
	}, children)
end

return StaffTab
