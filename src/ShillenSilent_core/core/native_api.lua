-- ---------------------------------------------------------
-- 6. native api (Safe Input Filtering)
-- ---------------------------------------------------------
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
			invoker.call(0xFE99B66D079CF6BC, group, keys[i], true)
		end
	end
end

local function heist_skip_cutscene(heist_name)
	local ok = pcall(function()
		invoker.call(0xD220BDD222AC4A1E) -- STOP_CUTSCENE_IMMEDIATELY
	end)

	if notify then
		local title = (heist_name and heist_name ~= "") and (heist_name .. " Tools") or "Heist Tools"
		if ok then
			notify.push(title, "Cutscene skip completed", 2000)
		else
			notify.push(title, "Cutscene skip failed", 2000)
		end
	end
end

local native_api = {
	CONTROL_ACTION_BLOCK_LIST = CONTROL_ACTION_BLOCK_LIST,
	disable_control_action = disable_control_action,
	heist_skip_cutscene = heist_skip_cutscene,
}

return native_api
