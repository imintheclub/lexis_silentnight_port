return {
	id = "casino",
	kind = "heist",
	order = 30,
	label_key = "feature.casino.name",
	support = { current = true, legacy = false },
	modules = {
		data = "ShillenSilent_core.features.heists.casino.data",
		state = "ShillenSilent_core.features.heists.casino.state",
		actions = "ShillenSilent_core.features.heists.casino.actions",
		presets = "ShillenSilent_core.features.heists.casino.presets",
		click = "ShillenSilent_core.features.heists.casino.click",
		controller = "ShillenSilent_core.features.heists.casino.controller",
	},
	jobs = {
		{
			id = "casino.solo_launch",
			interval_ms = 150,
			module = "ShillenSilent_core.features.heists.casino.actions",
			fn = "maintain_solo_launch",
		},
		{
			id = "casino.refresh_max_payout",
			interval_ms = 1000,
			module = "ShillenSilent_core.features.heists.casino.actions",
			fn = "refresh_max_payout",
		},
		{
			id = "casino.enforce_toggles",
			interval_ms = 250,
			module = "ShillenSilent_core.features.heists.casino.actions",
			fn = "enforce_heist_toggles",
		},
	},
}
