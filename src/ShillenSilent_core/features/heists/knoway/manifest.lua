return {
	id = "knoway",
	kind = "heist",
	order = 100,
	label_key = "feature.knoway.name",
	support = { current = true, legacy = false },
	modules = {
		data = "ShillenSilent_core.features.heists.knoway.data",
		state = "ShillenSilent_core.features.heists.knoway.state",
		actions = "ShillenSilent_core.features.heists.knoway.actions",
		click = "ShillenSilent_core.features.heists.knoway.click",
		controller = "ShillenSilent_core.features.heists.knoway.controller",
	},
	jobs = {},
}
