-- Shared/ReactComponents/ShopPanel/WorkerManagementCard.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)
local WorkersConfig = require(ReplicatedStorage.Shared.Configs.WorkersConfig)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local BuildersIcon = require(script.Parent.Parent.Parent.Utils.BuildersIcon)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local CARD_IMAGE = "rbxassetid://76169596898587"
local BUTTON_IMAGE = "rbxassetid://76169596898587"
local PORTRAIT_FALLBACK = "rbxassetid://15403066964"

local STAT_ICONS = {
	walkSpeed = BuildersIcon["shoe"],
	craftSpeed = BuildersIcon["clock"],
	quality = BuildersIcon["three-stacked-squares-tilted"],
}

local function WorkerPortrait()
	local world, setWorld = useState(nil)
	local camera, setCamera = useState(nil)
	local model, setModel = useState(nil)
	local hasFallback, setHasFallback = useState(false)

	useEffect(function()
		if not world then
			return
		end

		local template = workspace:FindFirstChild("Rig")
		if not template then
			setHasFallback(true)
			return
		end

		local clone = template:Clone()
		clone.PrimaryPart = clone:FindFirstChild("HumanoidRootPart") or clone.PrimaryPart
		for _, desc in clone:GetDescendants() do
			if desc:IsA("BasePart") then
				desc.Anchored = true
				desc.CanCollide = false
				desc.CanTouch = false
			elseif desc:IsA("Script") or desc:IsA("LocalScript") then
				desc:Destroy()
			end
		end

		clone:PivotTo(CFrame.new())
		clone.Parent = world
		setModel(clone)

		return function()
			clone:Destroy()
			setModel(nil)
		end
	end, { world })

	useEffect(function()
		if not (model and camera) then
			return
		end

		local cf, size = model:GetBoundingBox()
		local distance = math.max(size.X, size.Y, size.Z) * 1.9
		camera.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, size.Y * 0.12, distance), cf.Position)
		camera.FieldOfView = 40
	end, { model, camera })

	return e("ViewportFrame", {
		Size = UDim2.fromOffset(48, 48),
		BackgroundColor3 = Color3.new(0.1, 0.1, 0.12),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Active = false,
		CurrentCamera = camera,
		ZIndex = 1,
	}, {
		e("UICorner", { CornerRadius = UDim.new(1, 0) }),
		e("WorldModel", { ref = setWorld }, {
			Camera = e("Camera", { ref = setCamera }),
		}),
		hasFallback and e("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = PORTRAIT_FALLBACK,
			ScaleType = Enum.ScaleType.Fit,
			ImageTransparency = 0.15,
			ZIndex = 2,
		}) or nil,
	})
end

local function WorkerManagementCard(props: {
	worker: Types.WorkerEntity,
	index: number,
	playerCash: number,
	Visible: boolean,
	LayoutOrder: number,
})
	local worker = props.worker
	local statKeys: { Types.WorkerStatType } = { "walkSpeed", "craftSpeed", "quality" }
	local statButtons = {}

	for idx, statKey in ipairs(statKeys) do
		local statCfg = WorkersConfig.StatUpgrades[statKey]
		local currentLevel = if statKey == "walkSpeed"
			then (worker.walkSpeedLevel or 1)
			elseif statKey == "craftSpeed" then (worker.craftSpeedLevel or 1)
			else (worker.qualityLevel or 1)

		local maxLevel = #statCfg.Levels
		local currentVal = statCfg.Levels[math.clamp(currentLevel, 1, maxLevel)].Value
		local _, nextEntry = WorkersConfig.GetNextUpgrade(statKey, currentLevel)

		local isMaxed = nextEntry == nil
		local canAfford = nextEntry and (props.playerCash >= nextEntry.Cost) or false

		local btnColor = Color3.new(0.2, 0.65, 0.3)
		local btnLabel = ""

		if isMaxed then
			btnColor = Color3.new(0.35, 0.35, 0.35)
			btnLabel = `<b>{statCfg.DisplayName}</b> (MAX)\n<font size="12">{statCfg.FormatValue(currentVal)}</font>`
		else
			if not canAfford then
				btnColor = Color3.new(0.65, 0.25, 0.25)
			end
			btnLabel =
				`<b>{statCfg.DisplayName}</b> Lvl {currentLevel}/{maxLevel}\n<font size="12">{statCfg.FormatValue(
					currentVal
				)} ➔ {statCfg.FormatValue(nextEntry.Value)} (${nextEntry.Cost})</font>`
		end

		statButtons[statKey] = e(SmallButton, {
			LayoutOrder = idx,
			Size = UDim2.new(1, 0, 0, 48),
			AutomaticSize = Enum.AutomaticSize.None,
			BackgroundTransparency = 1,
			HoverScale = true,
			[React.Event.Activated] = function()
				if not isMaxed and canAfford and Remotes.UpgradeWorker then
					Remotes.UpgradeWorker:FireServer({
						workerUid = worker.id,
						statType = statKey,
					})
				end
			end,
			-- Image = BUTTON_IMAGE,
			-- ScaleType = Enum.ScaleType.Slice,
			-- SliceCenter = Rect.new(8, 8, 92, 92),
			Image = canAfford and "rbxassetid://128846321008253" or "rbxassetid://91750414973277",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(50, 50, 54, 57),

			-- ImageColor3 = btnColor,
			Rounded = false,
		}, {
			-- ButtonImage = e("ImageLabel", {
			-- 	Size = UDim2.fromScale(1, 1),
			-- 	BackgroundTransparency = 1,
			-- 	Image = BUTTON_IMAGE,
			-- 	ScaleType = Enum.ScaleType.Slice,
			-- 	SliceCenter = Rect.new(8, 8, 92, 92),
			-- 	ImageColor3 = btnColor,
			-- 	ImageTransparency = isMaxed and 0.15 or 0,
			-- 	ZIndex = 0,
			-- }),
			Label = e(SmallText, {
				Text = `{STAT_ICONS[statKey]} {btnLabel}`,
				RichText = true,
				Size = UDim2.new(1, 0, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextWrapped = true,
				ZIndex = 2,
			}),
		})
	end

	return e("ImageLabel", {
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Image = CARD_IMAGE,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(8, 8, 92, 92),
		ImageColor3 = Color3.new(0.82, 0.86, 1),
		ImageTransparency = 0.08,
		Visible = props.Visible,
		LayoutOrder = props.LayoutOrder,
	}, {
		-- Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
		-- Stroke = e("UIStroke", { Thickness = 2, Color = Color3.new(0.4, 0.6, 0.9) }),
		Content = e(VStack, {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Padding = { All = UDim.new(0, 8) },
			Spacing = UDim.new(0, 6),
		}, {
			Header = e(HStack, {
				LayoutOrder = 0,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				Spacing = UDim.new(0, 8),
			}, {
				Portrait = e(WorkerPortrait),
				Name = e(SmallText, {
					LayoutOrder = 2,
					Text = `{worker.name or ("Barista #" .. props.index)}`,
					RichText = true,
					Size = UDim2.new(1, 0, 0, 24),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
				}),
			}),
			StatsList = e(VStack, {
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Spacing = UDim.new(0, 4),
			}, statButtons),
		}),
	})
end

return WorkerManagementCard
