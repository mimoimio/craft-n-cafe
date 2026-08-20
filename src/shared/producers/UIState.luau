-- Shared/producers/UIState.luau
--!strict
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GamepadService = game:GetService("GamepadService")
local StarterGui = game:GetService("StarterGui")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Dictionary = Sift.Dictionary
local Set = Dictionary.set
local Merge = Dictionary.merge

export type Breakpoint = "xs" | "sm" | "md" | "lg" | "xl"

export type UIState = {
	panel: string,
	activeMixerId: string?,
	mixerNodeShown: string?,
	isEspressoInserted: boolean,
	isMilkInserted: boolean,
	tableSlotNodeShown: boolean,
	shopButton: GuiButton?,
	cafeButton: GuiButton?,
	shopPromptShown: boolean,
	spawnerPromptShown: boolean,
	spawnerInstance: Model?,
	espressoButton: GuiButton?,
	milkButton: GuiButton?,
	craftButton: GuiButton?,
	buypadInstance: Model?,
	firstCustomer: Model?,
	viewportSize: Vector2,
	breakpoint: Breakpoint,
}

export type UIActions = {
	toggle: (panel: string) -> (),
	toggleMixerInteract: (mixerName: string) -> (),
	setMixerNodeShown: (mixerName: string) -> (),
	setIsEspressoInserted: (is: boolean) -> (),
	setIsMilkInserted: (is: boolean) -> (),
	setTableSlotNodeShown: (is: boolean) -> (),
	setShopButton: (shopButton: GuiButton?) -> (),
	setCafeButton: (cafeButton: GuiButton?) -> (),
	setShopPromptShown: (is: boolean) -> (),
	setSpawnerPromptShown: (is: boolean) -> (),
	setSpawnerInstance: (spawner: Model?) -> (),
	setEspressoButton: (button: GuiButton?) -> (),
	setMilkButton: (button: GuiButton?) -> (),
	setCraftButton: (button: GuiButton?) -> (),
	setBuypadInstance: (model: Model?) -> (),
	setFirstCustomer: (model: Model?) -> (),
	setViewportSize: (viewportSize: Vector2) -> (),
}

-- Shared/producers/UIState.luau

local function calculateBreakpoint(viewportSize: Vector2): Breakpoint
	local width = viewportSize.X
	local height = viewportSize.Y

	-- 1. Mobile Phone Check (Landscape)
	-- If the vertical space is highly constrained (<= 500px), it is a phone.
	if height <= 500 then
		if width <= 800 then
			return "xs" -- Smaller or older phones (e.g., iPhone 7, standard Galaxy)
		else
			return "sm" -- Modern ultra-wide phones (e.g., iPhone 11, iPhone 16 Pro Max)
		end
	end

	-- 2. Tablet Check
	-- Devices with decent height, but constrained width compared to desktop.
	if width <= 1180 then
		return "md" -- Fits most iPads shown in the emulator (e.g., iPad 10th Gen, iPad Air)
	end

	-- 3. Desktop & Console Check
	if width <= 1440 then
		return "lg" -- Average Laptops (1366x768) and smaller desktop monitors
	else
		return "xl" -- 1080p+ Desktops, Xbox, PS5, Android TV
	end
end

local initialState: UIState = {
	panel = "none",
	activeMixerId = nil,
	mixerNodeShown = nil,
	isEspressoInserted = false,
	isMilkInserted = false,
	tableSlotNodeShown = false,
	shopButton = nil,
	cafeButton = nil,
	shopPromptShown = false,
	spawnerPromptShown = false,
	spawnerInstance = nil,
	espressoButton = nil,
	milkButton = nil,
	craftButton = nil,
	buypadInstance = nil,
	firstCustomer = nil,
	viewportSize = Vector2.zero,
	breakpoint = "md",
	mixerInstance = nil,
	tableInstance = nil,
	cafeBase = nil,
}

local producer = Reflex.createProducer(initialState, {
	toggle = function(state: UIState, panel: string)
		local newPanel = if state.panel == panel then "none" else panel
		if newPanel == "none" then
			GuiService.SelectedObject = nil
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
			GamepadService:DisableGamepadCursor()
		else
			print("setted")
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end
		return Set(state, "panel", newPanel)
	end,
	toggleMixerInteract = function(state: UIState, mixerName: string)
		return Merge(state, {
			panel = "mixer",
			activeMixerId = mixerName,
		})
	end,
	setMixerNodeShown = function(state: UIState, mixerName: string)
		return Set(state, "mixerNodeShown", mixerName)
	end,
	setIsMilkInserted = function(state: UIState, is: boolean)
		return Set(state, "isMilkInserted", is)
	end,
	setIsEspressoInserted = function(state: UIState, is: boolean)
		return Set(state, "isEspressoInserted", is)
	end,
	setTableSlotNodeShown = function(state: UIState, is: boolean)
		return Set(state, "tableSlotNodeShown", is)
	end,
	setShopButton = function(state: UIState, shopButton: GuiButton?)
		return Set(state, "shopButton", shopButton)
	end,
	setCafeButton = function(state: UIState, cafeButton: GuiButton?)
		return Set(state, "cafeButton", cafeButton)
	end,
	setShopPromptShown = function(state: UIState, is: boolean)
		return Set(state, "shopPromptShown", is)
	end,
	setSpawnerPromptShown = function(state: UIState, is: boolean)
		return Set(state, "spawnerPromptShown", is)
	end,
	setSpawnerInstance = function(state: UIState, spawner: Model?)
		return Set(state, "spawnerInstance", spawner)
	end,
	setEspressoButton = function(state: UIState, button: GuiButton?)
		return Set(state, "espressoButton", button)
	end,
	setMilkButton = function(state: UIState, button: GuiButton?)
		return Set(state, "milkButton", button)
	end,
	setCraftButton = function(state: UIState, button: GuiButton?)
		return Set(state, "craftButton", button)
	end,
	setBuypadInstance = function(state: UIState, model: Model?)
		return Set(state, "buypadInstance", model)
	end,
	setFirstCustomer = function(state: UIState, model: Model?)
		return Set(state, "firstCustomer", model)
	end,
	setViewportSize = function(state: UIState, viewportSize: Vector2)
		local currentBreakpoint = calculateBreakpoint(viewportSize)
		if state.viewportSize == viewportSize and state.breakpoint == currentBreakpoint then
			return state
		end
		return Merge(state, {
			viewportSize = viewportSize,
			breakpoint = currentBreakpoint,
		})
	end,
	setMixerInstance = function(state: UIState, model: Model?)
		return Set(state, "mixerInstance", model)
	end,
	setTableInstance = function(state: UIState, model: Model?)
		return Set(state, "tableInstance", model)
	end,
	setCafeBase = function(state: UIState, model: Model?)
		return Set(state, "cafeBase", model)
	end,
}) :: Reflex.Producer<UIState, UIActions>

-- if game.Players.LocalPlayer then
-- 	producer:subscribe(function(state)
-- 		return state.panel
-- 	end, function(panel)
-- 		if panel == "none" then
-- 		end
-- 	end)
-- end

return producer
