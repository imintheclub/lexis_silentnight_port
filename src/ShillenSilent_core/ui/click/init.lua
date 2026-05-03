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
	local manifests_by_subtab = {}
	local loaded_subtabs = {}

	for i = 1, #manifests do
		local manifest = manifests[i]
		if manifest.show_in_click ~= false then
			local subtab = manifest.display_group or manifest.id
			if not manifests_by_subtab[subtab] then
				manifests_by_subtab[subtab] = {}
			end
			manifests_by_subtab[subtab][#manifests_by_subtab[subtab] + 1] = manifest
		end
	end

	widgets.set_heist_subtab_loader(function(subtab)
		if loaded_subtabs[subtab] then
			return true
		end

		local subtab_manifests = manifests_by_subtab[subtab]
		for i = 1, #(subtab_manifests or {}) do
			local manifest = subtab_manifests[i]
			local click_module = registry.load_module(manifest, "click")
			if click_module and type(click_module.register) == "function" then
				click_module.register(heist_tab, manifest)
			end
		end
		loaded_subtabs[subtab] = true
		return true
	end)

	return heist_tab
end

return click
