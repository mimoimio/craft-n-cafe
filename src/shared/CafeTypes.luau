-- Shared/CafeTypes.luau

export type CafeBase = Model & {
	Cafe: Cafe?, -- the main cafe building, rendered in Services/CafeRenderingService
	Part: Part, -- part acting as the plot
	Entrance: Part, -- PrimaryPart. Also the part npc spawns on.
	Mailbox: Model & {
		Mailbox: Part & {
			TriggerPrompt: ProximityPrompt,
		},
	},
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
