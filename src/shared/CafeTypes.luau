-- Shared/CafeTypes.luau

export type CafeBase = Model & {
	Anchor: Part, -- NEW: The invisible Studio part that determines the plot's real-world location
	Entrance: Part, -- PrimaryPart. Also the part npc spawns on.
	Mailbox: Model & {
		Mailbox: Part & {
			TriggerPrompt: ProximityPrompt,
		},
	},

	Grid: Folder, -- where grid items are placed
	Spatial: Folder, -- where spatial items are placed

	Cafe: Cafe?, -- the main cafe building, rendered in Services/CafeRenderingService
	Part: Part, -- The dynamic green plot part rendered by React at runtime

	GetAttribute: (self: CafeBase, attribute: string & "OwnerId") -> string,
}

export type IngredientId = string

export type Cafe = Model & {
	Stations: Model & { [IngredientId]: Station },
	-- Spots removed! Customers now pathfind dynamically to placed items.
	FeedbackPrompt: Part & {
		ProximityPrompt: ProximityPrompt,
	},
}

export type Station = Model & {
	StationModel: Model,
	Part: Part & {
		TriggerPrompt: ProximityPrompt,
	},
}

export type Mixer = Model & {
	MixerModel: Model?,
	TriggerPrompt: ProximityPrompt,
	Part: Part,
}

export type CustomerRig = Model & {
	TriggerPrompt: ProximityPrompt,
}

return {}
