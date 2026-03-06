local core = require("ShillenSilent_core.core.bootstrap")
local ui = require("ShillenSilent_core.core.ui")

local config = core.config

local cooldown_danger_warning_lines = {
	"WARNING: DO NOT USE THIS. IF YOU GET BANNED GG",
	"I WARNED YOU. Only use this if you know what you're doing",
	"but honestly still don't.",
}

local function build_skip_cooldown_danger_group(tab_ref, heist_subtab, button_id, on_click)
	local group = ui.group(tab_ref, "DANGER", nil, nil, nil, nil, heist_subtab)
	for i = 1, #cooldown_danger_warning_lines do
		ui.label(group, cooldown_danger_warning_lines[i], config.colors.danger_text)
	end
	ui.button(group, button_id, "Skip Heist Cooldown", on_click, nil, false, "danger")
	return group
end

local danger_groups = {
	cooldown_danger_warning_lines = cooldown_danger_warning_lines,
	build_skip_cooldown_danger_group = build_skip_cooldown_danger_group,
}

return danger_groups
