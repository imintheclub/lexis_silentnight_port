-- ---------------------------------------------------------
-- 6. native api (Safe Input Filtering)
-- ---------------------------------------------------------
local i18n = require("ShillenSilent_core.i18n")
local notify_core = require("ShillenSilent_core.core.notify")
local native = require("natives")

local CONTROL_ACTION_BLOCK_LIST = {
	-- Block weapon/attack/scroll/camera inputs when menu is open.
	-- DO NOT block movement (0, 30-35) or vehicle inputs (59, 60, 71, 72, 75)

	1, -- INPUT_LOOK_LR (Camera Left/Right)
	2, -- INPUT_LOOK_UD (Camera Up/Down)
	3, -- INPUT_LOOK_UP_ONLY
	4, -- INPUT_LOOK_DOWN_ONLY
	5, -- INPUT_LOOK_LEFT_ONLY
	6, -- INPUT_LOOK_RIGHT_ONLY
	14, -- WEAPON_WHEEL_NEXT (Scroll Down)
	15, -- WEAPON_WHEEL_PREV (Scroll Up)
	16, -- SELECT_NEXT_WEAPON
	17, -- SELECT_PREV_WEAPON
	24, -- ATTACK (Left Click)
	25, -- AIM (Right Click)
	37, -- WEAPON_WHEEL (Tab)
	140, -- MELEE_ATTACK_LIGHT (R)
	141, -- MELEE_ATTACK_HEAVY (Q)
	142, -- MELEE_ATTACK_ALTERNATE (Left Mouse in melee)
	143, -- MELEE_BLOCK (Space)
	257, -- ATTACK2
	258, -- MELEE_ATTACK2
	261, -- PREV_WEAPON
	262, -- NEXT_WEAPON
	338, -- VEH_FLY_ATTACK
}

local function disable_control_action(keys)
	for group = 0, 1 do
		for i = 1, #keys do
			native.disable_control_action(group, keys[i], true)
		end
	end
end

local function heist_skip_cutscene(heist_name)
	local ok = pcall(function()
		native.stop_cutscene_immediately()
	end)

	local title = (heist_name and heist_name ~= "") and i18n.t("notify.heist_tools_title", { heist = heist_name })
		or i18n.t("notify.heist_tools_default_title")
	if ok then
		notify_core.raw(title, i18n.t("notify.cutscene_skip_completed"), 2000)
	else
		notify_core.raw(title, i18n.t("notify.cutscene_skip_failed"), 2000)
	end
end

local native_api = {
	CONTROL_ACTION_BLOCK_LIST = CONTROL_ACTION_BLOCK_LIST,
	disable_control_action = disable_control_action,
	heist_skip_cutscene = heist_skip_cutscene,
}

return native_api
