return {
	id = "arcade",
	kind = "business",
	order = 110,
	label_key = "feature.arcade.name",
	display_group = "misc",
	display_group_label_key = "feature.misc.name",
	display_group_order = 110,
	support = { current = true, legacy = false },
	modules = {
		data = "ShillenSilent_core.features.businesses.arcade.data",
		state = "ShillenSilent_core.features.businesses.arcade.state",
		actions = "ShillenSilent_core.features.businesses.arcade.actions",
		click = "ShillenSilent_core.features.businesses.arcade.click",
		controller = "ShillenSilent_core.features.businesses.arcade.controller",
	},
	jobs = {},
}
