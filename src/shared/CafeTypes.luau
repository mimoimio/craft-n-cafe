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
	Spots: Model & { -- the customers wait here
		[string]: Part,
	},
	FeedbackPrompt: Part & {
		ProximityPrompt: ProximityPrompt,
	},
}

export type Station = Model & {
	StationModel: Model, -- the cloned drinks from ReplicatedStorage.Shared.Models
	Part: Part & { -- the PrimaryPart
		TriggerPrompt: ProximityPrompt,
	},
}

export type Mixer = Model & {
	MixerModel: Model?, -- the cloned model
	TriggerPrompt: ProximityPrompt,
	Part: Part,
}

export type CustomerRig = Model & {
	TriggerPrompt: ProximityPrompt,
}

return {}
