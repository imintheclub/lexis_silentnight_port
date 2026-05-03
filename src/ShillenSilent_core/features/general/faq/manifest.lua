return {
	id = "faq",
	kind = "general",
	order = 20,
	label_key = "feature.faq.name",
	support = { current = true, legacy = false },
	modules = {
		data = "ShillenSilent_core.features.general.faq.data",
		click = "ShillenSilent_core.features.general.faq.click",
	},
	jobs = {},
}
