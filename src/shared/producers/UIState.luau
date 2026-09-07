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
	viewportSize: Vector2,
}

export type UIActions = {
	toggle: (panel: string) -> (),
	setViewportSize: (viewportSize: Vector2) -> (),
	setCafeBase: (model: Model?) -> (),
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
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end
		return Set(state, "panel", newPanel)
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
	setCafeBase = function(state: UIState, model: Model?)
		return Set(state, "cafeBase", model)
	end,
}) :: Reflex.Producer<UIState, UIActions>

return producer
