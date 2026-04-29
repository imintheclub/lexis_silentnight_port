return {
	id = "moneyfronts",
	kind = "business",
	order = 140,
	label_key = "feature.moneyfronts.name",
	display_group = "misc",
	display_group_label_key = "feature.misc.name",
	display_group_order = 110,
	support = { current = true, legacy = false },
	modules = {
		data = "ShillenSilent_core.features.businesses.moneyfronts.data",
		state = "ShillenSilent_core.features.businesses.moneyfronts.state",
		actions = "ShillenSilent_core.features.businesses.moneyfronts.actions",
		click = "ShillenSilent_core.features.businesses.moneyfronts.click",
		controller = "ShillenSilent_core.features.businesses.moneyfronts.controller",
	},
	jobs = {
		{
			id = "moneyfronts.front_heat_locks",
			interval_ms = 1000,
			module = "ShillenSilent_core.features.businesses.moneyfronts.actions",
			fn = "tick_front_heat_locks",
		},
		{
			id = "moneyfronts.refresh_click_ui",
			interval_ms = 1000,
			module = "ShillenSilent_core.features.businesses.moneyfronts.click",
			fn = "refresh",
		},
		{
			id = "moneyfronts.refresh_controller_ui",
			interval_ms = 1000,
			module = "ShillenSilent_core.features.businesses.moneyfronts.controller",
			fn = "refresh_controls",
		},
	},
}
