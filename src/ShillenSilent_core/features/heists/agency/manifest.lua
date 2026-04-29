return {
	id = "agency",
	kind = "heist",
	order = 60,
	label_key = "feature.agency.name",
	support = { current = true, legacy = false },
	modules = {
		data = "ShillenSilent_core.features.heists.agency.data",
		state = "ShillenSilent_core.features.heists.agency.state",
		actions = "ShillenSilent_core.features.heists.agency.actions",
		presets = "ShillenSilent_core.features.heists.agency.presets",
		click = "ShillenSilent_core.features.heists.agency.click",
		controller = "ShillenSilent_core.features.heists.agency.controller",
	},
	jobs = {
		{
			id = "agency.refresh_collect_safe",
			interval_ms = 5000,
			module = "ShillenSilent_core.features.heists.agency.actions",
			fn = "refresh_collect_safe_state",
		},
		{
			id = "agency.refresh_click_ui",
			interval_ms = 1000,
			module = "ShillenSilent_core.features.heists.agency.click",
			fn = "refresh",
		},
	},
}
