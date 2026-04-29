return {
	id = "doomsday",
	kind = "heist",
	order = 40,
	label_key = "feature.doomsday.name",
	support = { current = true, legacy = false },
	modules = {
		data = "ShillenSilent_core.features.heists.doomsday.data",
		state = "ShillenSilent_core.features.heists.doomsday.state",
		actions = "ShillenSilent_core.features.heists.doomsday.actions",
		presets = "ShillenSilent_core.features.heists.doomsday.presets",
		click = "ShillenSilent_core.features.heists.doomsday.click",
		controller = "ShillenSilent_core.features.heists.doomsday.controller",
	},
	jobs = {
		{
			id = "doomsday.refresh_max_payout",
			interval_ms = 1000,
			module = "ShillenSilent_core.features.heists.doomsday.actions",
			fn = "refresh_max_payout",
		},
		{
			id = "doomsday.refresh_click_ui",
			interval_ms = 1000,
			module = "ShillenSilent_core.features.heists.doomsday.click",
			fn = "refresh",
		},
		{
			id = "doomsday.maintain_solo_launch",
			interval_ms = 150,
			module = "ShillenSilent_core.features.heists.doomsday.actions",
			fn = "maintain_solo_launch",
		},
	},
}
