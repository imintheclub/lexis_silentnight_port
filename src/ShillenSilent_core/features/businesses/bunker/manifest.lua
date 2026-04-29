return {
	id = "bunker",
	kind = "business",
	order = 160,
	label_key = "feature.bunker.name",
	support = { current = true, legacy = false },
	modules = {
		data = "ShillenSilent_core.features.businesses.bunker.data",
		state = "ShillenSilent_core.features.businesses.bunker.state",
		actions = "ShillenSilent_core.features.businesses.bunker.actions",
		click = "ShillenSilent_core.features.businesses.bunker.click",
		controller = "ShillenSilent_core.features.businesses.bunker.controller",
	},
	jobs = {
		{
			id = "bunker.fast_production",
			interval_ms = 150,
			module = "ShillenSilent_core.features.businesses.bunker.actions",
			fn = "tick_fast_production",
		},
		{
			id = "bunker.refresh_click_ui",
			interval_ms = 250,
			module = "ShillenSilent_core.features.businesses.bunker.click",
			fn = "refresh",
		},
		{
			id = "bunker.refresh_controller_ui",
			interval_ms = 250,
			module = "ShillenSilent_core.features.businesses.bunker.controller",
			fn = "refresh_controls",
		},
	},
}
