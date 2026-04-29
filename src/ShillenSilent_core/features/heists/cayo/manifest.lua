return {
	id = "cayo",
	kind = "heist",
	order = 20,
	label_key = "feature.cayo.name",
	support = { current = true, legacy = false },
	modules = {
		data = "ShillenSilent_core.features.heists.cayo.data",
		state = "ShillenSilent_core.features.heists.cayo.state",
		actions = "ShillenSilent_core.features.heists.cayo.actions",
		presets = "ShillenSilent_core.features.heists.cayo.presets",
		click = "ShillenSilent_core.features.heists.cayo.click",
		controller = "ShillenSilent_core.features.heists.cayo.controller",
	},
	jobs = {
		{
			id = "cayo.refresh_max_payout",
			interval_ms = 1000,
			module = "ShillenSilent_core.features.heists.cayo.actions",
			fn = "refresh_max_payout",
		},
		{
			id = "cayo.enforce_toggles",
			interval_ms = 250,
			module = "ShillenSilent_core.features.heists.cayo.actions",
			fn = "enforce_heist_toggles",
		},
	},
}
