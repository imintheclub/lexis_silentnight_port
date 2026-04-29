return {
	id = "nightclub",
	kind = "business",
	order = 190,
	label_key = "feature.nightclub.name",
	support = { current = true, legacy = false },
	modules = {
		data = "ShillenSilent_core.features.businesses.nightclub.data",
		state = "ShillenSilent_core.features.businesses.nightclub.state",
		actions = "ShillenSilent_core.features.businesses.nightclub.actions",
		click = "ShillenSilent_core.features.businesses.nightclub.click",
		controller = "ShillenSilent_core.features.businesses.nightclub.controller",
	},
	jobs = {
		{
			id = "nightclub.fast_production",
			interval_ms = 250,
			module = "ShillenSilent_core.features.businesses.nightclub.actions",
			fn = "tick_fast_production",
		},
		{
			id = "nightclub.popularity_lock",
			interval_ms = 1000,
			module = "ShillenSilent_core.features.businesses.nightclub.actions",
			fn = "popularity_lock_tick",
		},
		{
			id = "nightclub.refresh_click_ui",
			interval_ms = 1000,
			module = "ShillenSilent_core.features.businesses.nightclub.click",
			fn = "refresh",
		},
		{
			id = "nightclub.refresh_controller_ui",
			interval_ms = 1000,
			module = "ShillenSilent_core.features.businesses.nightclub.controller",
			fn = "refresh_controls",
		},
	},
}
