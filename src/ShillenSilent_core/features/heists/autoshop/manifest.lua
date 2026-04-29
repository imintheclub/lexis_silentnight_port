return {
	id = "autoshop",
	kind = "heist",
	order = 70,
	label_key = "feature.autoshop.name",
	support = { current = true, legacy = false },
	modules = {
		data = "ShillenSilent_core.features.heists.autoshop.data",
		state = "ShillenSilent_core.features.heists.autoshop.state",
		actions = "ShillenSilent_core.features.heists.autoshop.actions",
		presets = "ShillenSilent_core.features.heists.autoshop.presets",
		click = "ShillenSilent_core.features.heists.autoshop.click",
		controller = "ShillenSilent_core.features.heists.autoshop.controller",
	},
	jobs = {},
}
