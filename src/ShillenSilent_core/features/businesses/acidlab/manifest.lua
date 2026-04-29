return {
	id = "acidlab",
	kind = "business",
	order = 150,
	label_key = "feature.acidlab.name",
	support = { current = true, legacy = false },
	modules = {
		data = "ShillenSilent_core.features.businesses.acidlab.data",
		state = "ShillenSilent_core.features.businesses.acidlab.state",
		actions = "ShillenSilent_core.features.businesses.acidlab.actions",
		click = "ShillenSilent_core.features.businesses.acidlab.click",
		controller = "ShillenSilent_core.features.businesses.acidlab.controller",
	},
	jobs = {
		{
			id = "acidlab.fast_production",
			interval_ms = 150,
			module = "ShillenSilent_core.features.businesses.acidlab.actions",
			fn = "tick_fast_production",
		},
		{
			id = "acidlab.refresh_click_ui",
			interval_ms = 250,
			module = "ShillenSilent_core.features.businesses.acidlab.click",
			fn = "refresh",
		},
		{
			id = "acidlab.refresh_controller_ui",
			interval_ms = 250,
			module = "ShillenSilent_core.features.businesses.acidlab.controller",
			fn = "refresh_controls",
		},
	},
}
