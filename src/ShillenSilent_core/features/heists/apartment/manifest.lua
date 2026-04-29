return {
	id = "apartment",
	kind = "heist",
	order = 50,
	label_key = "feature.apartment.name",
	support = { current = true, legacy = false },
	modules = {
		data = "ShillenSilent_core.features.heists.apartment.data",
		state = "ShillenSilent_core.features.heists.apartment.state",
		actions = "ShillenSilent_core.features.heists.apartment.actions",
		presets = "ShillenSilent_core.features.heists.apartment.presets",
		click = "ShillenSilent_core.features.heists.apartment.click",
		controller = "ShillenSilent_core.features.heists.apartment.controller",
	},
	jobs = {
		{
			id = "apartment.refresh_max_payout",
			interval_ms = 1000,
			module = "ShillenSilent_core.features.heists.apartment.actions",
			fn = "refresh_max_payout",
		},
		{
			id = "apartment.refresh_click_ui",
			interval_ms = 1000,
			module = "ShillenSilent_core.features.heists.apartment.click",
			fn = "refresh",
		},
		{
			id = "apartment.maintain_solo_launch",
			interval_ms = 150,
			module = "ShillenSilent_core.features.heists.apartment.actions",
			fn = "maintain_solo_launch",
		},
	},
}
