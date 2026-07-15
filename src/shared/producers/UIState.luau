--!strict
-- Shared/producers/UIState.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Types = require(ReplicatedStorage.Shared.Types)
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
	tableSlotNodeShown: boolean,
	shopButton: GuiButton,
}
export type UIActions = {
	toggle: (panel: string) -> (),
	toggleMixerInteract: (mixerName: string) -> (),
	setMixerNodeShown: (mixerName: string) -> (),
	setIsEspressoInserted: (is: boolean) -> (),
	setTableSlotNodeShown: (is: boolean) -> (),
	setShopButton: (shopButton: GuiButton) -> (),
}
local initialState = {
	panel = "none",
	activeMixerId = nil,
	mixerNodeShown = nil,
	isEspressoInserted = false,
	tableSlotNodeShown = false,
}
local producer = Reflex.createProducer(initialState, {
	toggle = function(state: UIState, panel: string)
		if state.panel == panel then
			return Set(state, "panel", "none")
		end
		return Set(state, "panel", panel)
	end,
	toggleMixerInteract = function(state: UIState, mixerName: string)
		return Merge(state, {
			panel = "mixer",
			activeMixerId = mixerName,
		})
	end,
	setMixerNodeShown = function(state: UIState, mixerName: string)
		return Merge(state, "mixerNodeShown", mixerName)
	end,
	setIsEspressoInserted = function(state: UIState, is: boolean)
		return Set(state, "isEspressoInserted", is and true or false)
	end,
	setTableSlotNodeShown = function(state: UIState, is: boolean)
		return Set(state, "tableSlotNodeShown", is and true or false)
	end,
	setShopButton = function(state: UIState, shopButton: GuiButton?)
		warn(`setting shop button: {shopButton}`)
		return Set(state, "shopButton", shopButton)
	end,
}) :: Reflex.Producer<UIState, UIActions>

return producer
