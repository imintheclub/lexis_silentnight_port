return {
	id = "hangar",
	kind = "business",
	order = 170,
	label_key = "feature.hangar.name",
	support = { current = true, legacy = false },
	modules = {
		data = "ShillenSilent_core.features.businesses.hangar.data",
		state = "ShillenSilent_core.features.businesses.hangar.state",
		actions = "ShillenSilent_core.features.businesses.hangar.actions",
		click = "ShillenSilent_core.features.businesses.hangar.click",
		controller = "ShillenSilent_core.features.businesses.hangar.controller",
	},
	jobs = {
		{
			id = "hangar.fill_cargo",
			interval_ms = 1000,
			module = "ShillenSilent_core.features.businesses.hangar.actions",
			fn = "tick_fill_cargo",
		},
		{
			id = "hangar.refresh_click_ui",
			interval_ms = 250,
			module = "ShillenSilent_core.features.businesses.hangar.click",
			fn = "refresh",
		},
		{
			id = "hangar.refresh_controller_ui",
			interval_ms = 250,
			module = "ShillenSilent_core.features.businesses.hangar.controller",
			fn = "refresh_controls",
		},
	},
}
