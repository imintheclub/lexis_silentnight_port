return {
	id = "bailoffice",
	kind = "business",
	order = 130,
	label_key = "feature.bailoffice.name",
	display_group = "misc",
	display_group_label_key = "feature.misc.name",
	display_group_order = 110,
	support = { current = true, legacy = false },
	modules = {
		data = "ShillenSilent_core.features.businesses.bailoffice.data",
		state = "ShillenSilent_core.features.businesses.bailoffice.state",
		actions = "ShillenSilent_core.features.businesses.bailoffice.actions",
		click = "ShillenSilent_core.features.businesses.bailoffice.click",
		controller = "ShillenSilent_core.features.businesses.bailoffice.controller",
	},
	jobs = {},
}
