local registry = require("ShillenSilent_core.features.registry")
local layout = require("ShillenSilent_core.ui.click.layout")
local widgets = require("ShillenSilent_core.ui.click.widgets")

local click = {}

local function find_or_create_heist_tab()
	for i = 1, #widgets.tabs do
		local tab = widgets.tabs[i]
		if tab and tab.id == "heist" then
			return tab
		end
	end
	return widgets.tab("heist", "HEIST")
end

function click.register_all()
	layout.configure_subtabs(registry)
	local heist_tab = find_or_create_heist_tab()
	local manifests = registry.list()
	for i = 1, #manifests do
		local manifest = manifests[i]
		local click_module = registry.load_module(manifest, "click")
		if click_module and type(click_module.register) == "function" then
			click_module.register(heist_tab, manifest)
		end
	end
	return heist_tab
end

return click
