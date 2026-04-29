return {
	id = "info",
	kind = "heist",
	order = 10,
	label_key = "feature.info.name",
	support = { current = true, legacy = false },
	modules = {
		data = "ShillenSilent_core.features.heists.info.data",
		state = "ShillenSilent_core.features.heists.info.state",
		actions = "ShillenSilent_core.features.heists.info.actions",
		click = "ShillenSilent_core.features.heists.info.click",
		controller = "ShillenSilent_core.features.heists.info.controller",
	},
	jobs = {},
}
