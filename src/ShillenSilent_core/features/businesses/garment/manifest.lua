return {
	id = "garment",
	kind = "business",
	order = 120,
	label_key = "feature.garment.name",
	display_group = "misc",
	display_group_label_key = "feature.misc.name",
	display_group_order = 110,
	support = { current = true, legacy = false },
	modules = {
		data = "ShillenSilent_core.features.businesses.garment.data",
		state = "ShillenSilent_core.features.businesses.garment.state",
		actions = "ShillenSilent_core.features.businesses.garment.actions",
		click = "ShillenSilent_core.features.businesses.garment.click",
		controller = "ShillenSilent_core.features.businesses.garment.controller",
	},
	jobs = {},
}
