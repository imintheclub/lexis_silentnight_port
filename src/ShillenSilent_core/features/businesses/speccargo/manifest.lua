return {
	id = "speccargo",
	kind = "business",
	order = 180,
	label_key = "feature.speccargo.name",
	support = { current = true, legacy = false },
	modules = {
		data = "ShillenSilent_core.features.businesses.speccargo.data",
		state = "ShillenSilent_core.features.businesses.speccargo.state",
		actions = "ShillenSilent_core.features.businesses.speccargo.actions",
		click = "ShillenSilent_core.features.businesses.speccargo.click",
		controller = "ShillenSilent_core.features.businesses.speccargo.controller",
	},
	jobs = {
		{
			id = "speccargo.fill_cargo",
			interval_ms = 5000,
			module = "ShillenSilent_core.features.businesses.speccargo.actions",
			fn = "tick_fill_cargo",
		},
		{
			id = "speccargo.sale_price",
			interval_ms = 1000,
			module = "ShillenSilent_core.features.businesses.speccargo.actions",
			fn = "tick_sale_price",
		},
		{
			id = "speccargo.supplier",
			interval_ms = 1000,
			module = "ShillenSilent_core.features.businesses.speccargo.actions",
			fn = "tick_supplier",
		},
		{
			id = "speccargo.refresh_click_ui",
			interval_ms = 1000,
			module = "ShillenSilent_core.features.businesses.speccargo.click",
			fn = "refresh",
		},
		{
			id = "speccargo.refresh_controller_ui",
			interval_ms = 1000,
			module = "ShillenSilent_core.features.businesses.speccargo.controller",
			fn = "refresh_controls",
		},
	},
}
