local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local data = require("ShillenSilent_core.features.businesses.moneyfronts.data")
local state = require("ShillenSilent_core.features.businesses.moneyfronts.state")
local actions = require("ShillenSilent_core.features.businesses.moneyfronts.actions")

local click = {}
local refs = {
	front_heat = {},
	front_lock = {},
	overall_heat = nil,
	overall_lock = nil,
}

local t = i18n.t

function click.refresh()
	if refs.overall_heat then
		refs.overall_heat.value = state.config.overall_heat
	end
	if refs.overall_lock then
		refs.overall_lock.state = state.flags.overall_heat_lock == true
	end
	for _, key in ipairs(data.front_keys) do
		local available = actions.is_front_available(key)
		if refs.front_heat[key] then
			refs.front_heat[key].value = state.config.front_heat[key]
			refs.front_heat[key].disabled = not available
		end
		if refs.front_lock[key] then
			refs.front_lock[key].state = state.flags.front_heat_lock[key] == true
			refs.front_lock[key].disabled = not available
		end
	end
	return true
end

function click.register(heist_tab, manifest)
	if type(heist_tab) ~= "table" then
		return nil
	end

	local subtab = (manifest and manifest.display_group) or data.feature_id

	local overall = ui.group(heist_tab, t("feature.moneyfronts.name"), nil, nil, nil, nil, subtab)
	refs.overall_heat = ui.slider(
		overall,
		"mf_overall_heat",
		t("moneyfronts.field.heat"),
		data.heat.min,
		data.heat.max,
		state.config.overall_heat,
		function(value)
			actions.set_overall_heat_value(value)
			click.refresh()
		end,
		t("moneyfronts.tooltip.heat"),
		data.heat.step
	)
	ui.button(overall, "mf_overall_apply", t("moneyfronts.action.apply_heat"), function()
		actions.apply_overall_heat_value()
		click.refresh()
	end)
	ui.button(overall, "mf_overall_max", t("moneyfronts.action.max_heat"), function()
		actions.max_overall_heat()
		click.refresh()
	end)
	ui.button(overall, "mf_overall_min", t("moneyfronts.action.min_heat"), function()
		actions.min_overall_heat()
		click.refresh()
	end)
	refs.overall_lock = ui.toggle(
		overall,
		"mf_overall_lock",
		t("moneyfronts.action.lock_heat"),
		actions.get_overall_heat_lock_active(),
		function(enabled)
			actions.set_overall_heat_lock_active(enabled)
			click.refresh()
		end
	)

	for _, key in ipairs(data.front_keys) do
		local loc = data.location_by_key(key)
		local available = actions.is_front_available(key)
		local front = ui.group(heist_tab, t(loc.heat_label_key), nil, nil, nil, nil, subtab)
		local entrance = ui.button(
			front,
			"mf_" .. key .. "_entrance",
			t("moneyfronts.action.teleport_entrance"),
			function()
				actions.teleport_front(key)
			end,
			nil,
			not available
		)
		entrance.disabled = not available
		local laptop = ui.button(front, "mf_" .. key .. "_laptop", t("moneyfronts.action.teleport_laptop"), function()
			actions.teleport_laptop(key)
		end, nil, not available)
		laptop.disabled = not available
		if key == "car_wash" then
			ui.button(
				front,
				"mf_carwash_safe_collect",
				t("moneyfronts.action.collect_car_wash_safe"),
				actions.car_wash_collect_safe,
				nil,
				not available
			)
		end
		refs.front_heat[key] = ui.slider(
			front,
			"mf_" .. key .. "_heat",
			t("moneyfronts.field.heat"),
			data.heat.min,
			data.heat.max,
			state.config.front_heat[key],
			function(value)
				actions.set_front_heat_value(key, value)
				click.refresh()
			end,
			t("moneyfronts.tooltip.heat"),
			data.heat.step
		)
		refs.front_heat[key].disabled = not available
		ui.button(front, "mf_" .. key .. "_apply", t("moneyfronts.action.apply_heat"), function()
			actions.apply_front_heat_value(key)
			click.refresh()
		end, nil, not available)
		ui.button(front, "mf_" .. key .. "_max", t("moneyfronts.action.max_heat"), function()
			actions.max_front_heat(key)
			click.refresh()
		end, nil, not available)
		ui.button(front, "mf_" .. key .. "_min", t("moneyfronts.action.min_heat"), function()
			actions.min_front_heat(key)
			click.refresh()
		end, nil, not available)
		refs.front_lock[key] = ui.toggle(
			front,
			"mf_" .. key .. "_lock",
			t("moneyfronts.action.lock_heat"),
			actions.get_front_heat_lock_active(key),
			function(enabled)
				actions.set_front_heat_lock_active(key, enabled)
				click.refresh()
			end
		)
		refs.front_lock[key].disabled = not available
	end

	click.refresh()
	return heist_tab
end

return click
