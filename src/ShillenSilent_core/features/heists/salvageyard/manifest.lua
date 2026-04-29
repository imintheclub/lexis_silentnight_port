return {
	id = "salvageyard",
	kind = "heist",
	order = 80,
	label_key = "feature.salvageyard.name",
	support = { current = true, legacy = false },
	modules = {
		data = "ShillenSilent_core.features.heists.salvageyard.data",
		state = "ShillenSilent_core.features.heists.salvageyard.state",
		actions = "ShillenSilent_core.features.heists.salvageyard.actions",
		presets = "ShillenSilent_core.features.heists.salvageyard.presets",
		click = "ShillenSilent_core.features.heists.salvageyard.click",
		controller = "ShillenSilent_core.features.heists.salvageyard.controller",
	},
	jobs = {
		{
			id = "salvageyard.enforce_toggles",
			interval_ms = 250,
			module = "ShillenSilent_core.features.heists.salvageyard.actions",
			fn = "enforce_heist_toggles",
		},
		{
			id = "salvageyard.popularity_lock",
			interval_ms = 250,
			module = "ShillenSilent_core.features.heists.salvageyard.actions",
			fn = "popularity_lock_tick",
		},
		{
			id = "salvageyard.refresh_collect_safe",
			interval_ms = 5000,
			module = "ShillenSilent_core.features.heists.salvageyard.actions",
			fn = "refresh_collect_safe_state",
		},
		{
			id = "salvageyard.refresh_click_ui",
			interval_ms = 1000,
			module = "ShillenSilent_core.features.heists.salvageyard.click",
			fn = "refresh",
		},
	},
}
