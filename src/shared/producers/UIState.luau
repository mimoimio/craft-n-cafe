--!strict
-- Shared/producers/UIState.luau
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Types = require(ReplicatedStorage.Shared.Types)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Dictionary = Sift.Dictionary
local Set = Dictionary.set
local Merge = Dictionary.merge
local RemoveKey = Dictionary.removeKey

export type UIState = {
	panel: string,
	activeMixerId: string,
	mixerNodeShown: string,
	isEspressoInserted: boolean,
	isMilkInserted: boolean,
	tableSlotNodeShown: boolean,
	shopButton: GuiButton,
	cafeButton: GuiButton,
	cafeBase: CafeTypes.CafeBase?,
	shopPromptShown: boolean,
	spawnerPromptShown: boolean,
	spawnerInstance: Model?,
	espressoButton: GuiButton?,
	milkButton: GuiButton?,
	craftButton: GuiButton?,
	buypadInstance: Model?,
	firstCustomer: Model?,
}
export type UIActions = {
	toggle: (panel: string) -> (),
	toggleMixerInteract: (mixerName: string) -> (),
	setMixerNodeShown: (mixerName: string) -> (),
	setIsEspressoInserted: (is: boolean) -> (),
	setIsMilkInserted: (is: boolean) -> (), -- ADD THIS
	setTableSlotNodeShown: (is: boolean) -> (),
	setShopButton: (shopButton: GuiButton) -> (),
	setCafeButton: (cafeButton: GuiButton) -> (),
	setCafeBase: (model: Model) -> (),
	setShopPromptShown: (is: boolean) -> (),
	setSpawnerPromptShown: (is: boolean) -> (),
	setSpawnerInstance: (model: Model) -> (),
	setEspressoButton: (button: GuiButton?) -> (),
	setMilkButton: (button: GuiButton?) -> (),
	setCraftButton: (button: GuiButton?) -> (),
	setBuypadInstance: (model: Model?) -> (),
	setFirstCustomer: (model: Model?) -> (),
}
local initialState = {
	panel = "none",
	activeMixerId = nil,
	mixerNodeShown = nil,
	isEspressoInserted = false,
	isMilkInserted = false, -- ADD THIS
	tableSlotNodeShown = false,
	cafeBase = nil,
}
local producer = Reflex.createProducer(initialState, {
	toggle = function(state: UIState, panel: string)
		local newPanel
		if state.panel == panel then
			newPanel = "none"
		else
			newPanel = panel
		end

		if newPanel == "none" then
			GuiService.SelectedObject = nil
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
		return Set(state, "isMilkInserted", is and true or false)
	end,
	setIsEspressoInserted = function(state: UIState, is: boolean)
		return Set(state, "isEspressoInserted", is and true or false)
	end,
	setTableSlotNodeShown = function(state: UIState, is: boolean)
		return Set(state, "tableSlotNodeShown", is and true or false)
	end,
	setShopButton = function(state: UIState, shopButton: GuiButton?)
		return Set(state, "shopButton", shopButton)
	end,
	setCafeButton = function(state: UIState, cafeButton: GuiButton?)
		return Set(state, "cafeButton", cafeButton)
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
	setShopPromptShown = function(state: UIState, is: boolean)
		return Set(state, "shopPromptShown", is)
	end,
	setSpawnerPromptShown = function(state: UIState, is: boolean)
		return Set(state, "spawnerPromptShown", is)
	end,
	setSpawnerInstance = function(state: UIState, spawner: Model)
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
}) :: Reflex.Producer<UIState, UIActions>

return producer
