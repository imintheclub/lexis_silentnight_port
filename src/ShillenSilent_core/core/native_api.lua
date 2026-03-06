-- ---------------------------------------------------------
-- 6. native api
-- ---------------------------------------------------------
local CONTROL_ACTION_BLOCK_LIST = {
	0,
	1,
	2,
	3,
	4,
	5,
	6, -- Movement
	24,
	25, -- Attack (Left/Right Mouse)
	30,
	31,
	32,
	33,
	34,
	35, -- Move
	37, -- Weapon Wheel
	44,
	45,
	47,
	58, -- Cover
	59,
	60, -- Veh Move
	71,
	72, -- Veh Accel/Brake
	75, -- Veh Exit
	140,
	141,
	142,
	143, -- Melee
	257,
	258,
	261,
	262,
	263,
	264,
	265, -- Attack variants
	266,
	267,
	268, -- More attack
	27, -- ESC
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
			notify.push(title, "Skip cutscene requested", 2000)
		else
			notify.push(title, "Could not skip cutscene", 2000)
		end
	end
end

local native_api = {
	CONTROL_ACTION_BLOCK_LIST = CONTROL_ACTION_BLOCK_LIST,
	disable_control_action = disable_control_action,
	heist_skip_cutscene = heist_skip_cutscene,
}

return native_api
