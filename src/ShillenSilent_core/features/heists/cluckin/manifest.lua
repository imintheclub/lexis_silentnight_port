return {
	id = "cluckin",
	kind = "heist",
	order = 90,
	label_key = "feature.cluckin.name",
	support = { current = true, legacy = false },
	modules = {
		data = "ShillenSilent_core.features.heists.cluckin.data",
		state = "ShillenSilent_core.features.heists.cluckin.state",
		actions = "ShillenSilent_core.features.heists.cluckin.actions",
		click = "ShillenSilent_core.features.heists.cluckin.click",
		controller = "ShillenSilent_core.features.heists.cluckin.controller",
	},
	jobs = {},
}
