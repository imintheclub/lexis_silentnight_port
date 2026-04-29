local layout = {}

local i18n = require("ShillenSilent_core.i18n")

function layout.configure_subtabs(registry)
	local ui = require("ShillenSilent_core.ui.click.widgets")
	if type(ui.set_heist_subtabs) ~= "function" then
		return false
	end

	local names = {}
	local keys = {}
	local seen = {}
	local entries = {}
	local all = registry.list()
	for i = 1, #all do
		local manifest = all[i]
		if manifest.show_in_click ~= false then
			local key = manifest.display_group or manifest.id
			if not seen[key] then
				entries[#entries + 1] = {
					key = key,
					label = manifest.display_group_label_key and i18n.t(manifest.display_group_label_key)
						or registry.label(manifest),
					order = manifest.display_group_order or manifest.order or 0,
				}
				seen[key] = true
			end
		end
	end
	table.sort(entries, function(a, b)
		return (a.order or 0) < (b.order or 0)
	end)
	for i = 1, #entries do
		names[#names + 1] = entries[i].label
		keys[#keys + 1] = entries[i].key
	end
	return ui.set_heist_subtabs(names, keys)
end

return layout
