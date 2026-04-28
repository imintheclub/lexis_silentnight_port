local biz = require("ShillenSilent_core.businesses.shared")

-- Safe collect global (EE).
local SAFE_COLLECT = 2708841

local function collect_safe()
	local ok = biz.set_global_int(SAFE_COLLECT, 1)
	if notify then
		notify.push("Arcade", ok and "Safe collect completed" or "Safe collect failed to apply", 2000)
	end
end

local arcade_logic = {
	collect_safe = collect_safe,
}

return arcade_logic
