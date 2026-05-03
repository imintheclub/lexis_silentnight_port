local notify_core = require("ShillenSilent_core.core.notify")
local config = require("ShillenSilent_core.ui.click.config")

local common = {}

local BUTTON_COLOR_STYLES = {
	disabled = {
		normal = { bg = config.colors.danger, border = config.colors.danger, text = config.colors.text_on_accent },
		hover = {
			bg = config.colors.danger_hover,
			border = config.colors.danger_hover,
			text = config.colors.text_on_accent,
		},
	},
	primary = {
		normal = { bg = config.colors.accent, border = config.colors.accent, text = config.colors.text_on_accent },
		hover = {
			bg = config.colors.accent_hover,
			border = config.colors.accent_hover,
			text = config.colors.text_on_accent,
		},
	},
	success = {
		normal = { bg = config.colors.success, border = config.colors.success, text = config.colors.text_on_accent },
		hover = {
			bg = config.colors.success_hover,
			border = config.colors.success_hover,
			text = config.colors.text_on_accent,
		},
	},
	danger = {
		normal = { bg = config.colors.danger, border = config.colors.danger, text = config.colors.text_on_accent },
		hover = {
			bg = config.colors.danger_hover,
			border = config.colors.danger_hover,
			text = config.colors.text_on_accent,
		},
	},
	ghost = {
		normal = { bg = config.colors.transparent, border = config.colors.transparent, text = config.colors.text_main },
		hover = {
			bg = config.colors.bg_ghost_hover,
			border = config.colors.transparent,
			text = config.colors.text_main,
		},
	},
	ghost_danger = {
		normal = {
			bg = config.colors.transparent,
			border = config.colors.transparent,
			text = config.colors.danger_text,
		},
		hover = { bg = config.colors.danger_soft, border = config.colors.transparent, text = config.colors.danger_text },
	},
	outline = {
		normal = {
			bg = config.colors.bg_ghost_hover,
			border = config.colors.transparent,
			text = config.colors.text_main,
		},
		hover = { bg = config.colors.bg_panel, border = config.colors.transparent, text = config.colors.text_main },
	},
}

local function button_variant_for(btn)
	if btn.color == "green" then
		return "success"
	end
	if btn.color == "danger" then
		return "danger"
	end
	if btn.color == "ghost" then
		return "ghost"
	end
	if btn.color == "primary" then
		return "primary"
	end

	local id = string.lower(tostring(btn.id or ""))
	if id == "" then
		return "outline"
	end

	if id:find("instant_finish", 1, true) or id == "cayo_tool_finish" then
		return "success"
	end

	if
		id:find("preset_copy", 1, true)
		or id:find("preset_refresh", 1, true)
		or id:find("preset_set_name", 1, true)
		or id:find("preset_name_clip", 1, true)
	then
		return "outline"
	end

	if id:find("preset_remove", 1, true) then
		return "ghost_danger"
	end

	if id:find("cooldown", 1, true) then
		return "danger"
	end

	if id:find("_tp_", 1, true) or id:find("teleport", 1, true) then
		return "outline"
	end

	if id == "doomsday_preset_apply" then
		return "outline"
	end

	if
		id:find("cuts_apply", 1, true)
		or id:find("cuts_reset", 1, true)
		or id:find("reset_cuts", 1, true)
		or id:find("_apply", 1, true)
		or id:find("preset_save", 1, true)
		or id:find("preset_load", 1, true)
	then
		return "primary"
	end

	return "outline"
end

function common.button_colors_for(btn, hovered)
	if btn.disabled then
		return hovered and BUTTON_COLOR_STYLES.disabled.hover or BUTTON_COLOR_STYLES.disabled.normal
	end

	local variant = button_variant_for(btn)
	if variant == "primary" then
		return hovered and BUTTON_COLOR_STYLES.primary.hover or BUTTON_COLOR_STYLES.primary.normal
	elseif variant == "success" then
		return hovered and BUTTON_COLOR_STYLES.success.hover or BUTTON_COLOR_STYLES.success.normal
	elseif variant == "danger" then
		return hovered and BUTTON_COLOR_STYLES.danger.hover or BUTTON_COLOR_STYLES.danger.normal
	elseif variant == "ghost" then
		return hovered and BUTTON_COLOR_STYLES.ghost.hover or BUTTON_COLOR_STYLES.ghost.normal
	elseif variant == "ghost_danger" then
		return hovered and BUTTON_COLOR_STYLES.ghost_danger.hover or BUTTON_COLOR_STYLES.ghost_danger.normal
	else
		return hovered and BUTTON_COLOR_STYLES.outline.hover or BUTTON_COLOR_STYLES.outline.normal
	end
end

function common.safe_call_ui_handler(kind, id, fn, ...)
	if type(fn) ~= "function" then
		return true
	end
	local ok, err = pcall(fn, ...)
	if not ok then
		notify_core.push("notify.ui_callback_error_title", "notify.ui_callback_error", 4500, {
			kind = tostring(kind),
			id = tostring(id),
			error = tostring(err),
		})
	end
	return ok
end

return common
