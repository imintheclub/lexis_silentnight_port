return {
	id = "mc",
	kind = "business",
	order = 200,
	label_key = "feature.mc.name",
	support = { current = true, legacy = false },
	modules = {
		data = "ShillenSilent_core.features.businesses.mc.data",
		state = "ShillenSilent_core.features.businesses.mc.state",
		actions = "ShillenSilent_core.features.businesses.mc.actions",
		click = "ShillenSilent_core.features.businesses.mc.click",
		controller = "ShillenSilent_core.features.businesses.mc.controller",
	},
	jobs = {
		{
			id = "mc.fast_production",
			interval_ms = 150,
			module = "ShillenSilent_core.features.businesses.mc.actions",
			fn = "tick_fast_production",
		},
		{
			id = "mc.sub_production",
			interval_ms = 150,
			module = "ShillenSilent_core.features.businesses.mc.actions",
			fn = "tick_sub_production",
		},
		{
			id = "mc.refresh_click_ui",
			interval_ms = 250,
			module = "ShillenSilent_core.features.businesses.mc.click",
			fn = "refresh",
		},
		{
			id = "mc.refresh_controller_ui",
			interval_ms = 250,
			module = "ShillenSilent_core.features.businesses.mc.controller",
			fn = "refresh_controls",
		},
	},
}
