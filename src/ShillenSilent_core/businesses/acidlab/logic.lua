local biz = require("ShillenSilent_core.businesses.shared")

-- Acid Lab uses slot 7 in the shared production timer system.
local ACID_SLOT = 7

-- Instant sell: manipulate fm_content_acid_lab_sell script locals (EE offsets).
local SELL_SCRIPT = "fm_content_acid_lab_sell"
local SELL_STATE_OFFSET = 7050
local SELL_FLAGS_OFFSET = 7059
local SELL_BIT_WON = 11

-- Fast production: halves BIKER_ACID_PRODUCTION_TIME tunable.
local ACID_PROD_TIME_TUNABLE = "BIKER_ACID_PRODUCTION_TIME"
local _fast_prod_default = nil
local _fast_prod_active = false

local function production_tick()
	biz.production_tick(ACID_SLOT)
	if notify then
		notify.push("Acid Lab", "Production tick applied", 2000)
	end
end

local function refill_supplies()
	biz.run_guarded_job("acidlab_refill", function()
		biz.fill_supply_slot(ACID_SLOT)
		if notify then
			notify.push("Acid Lab", "Supplies refilled", 2000)
		end
	end, function()
		if notify then
			notify.push("Acid Lab", "Refill already in progress", 1500)
		end
	end)
end

local function instant_sell()
	biz.run_guarded_job("acidlab_sell", function()
		if not biz.is_script_running(SELL_SCRIPT) then
			if notify then
				notify.push("Acid Lab", "Start your Acid Lab sell mission first", 2200)
			end
			return
		end

		local flags = biz.get_local_int(SELL_SCRIPT, SELL_FLAGS_OFFSET, 0)
		flags = flags | (1 << SELL_BIT_WON)
		local ok1 = biz.set_local_int(SELL_SCRIPT, SELL_STATE_OFFSET, 1)
		local ok2 = biz.set_local_int(SELL_SCRIPT, SELL_FLAGS_OFFSET, flags)

		if notify then
			notify.push("Acid Lab", (ok1 and ok2) and "Instant sell triggered" or "Sell write failed", 2200)
		end
	end, function()
		if notify then
			notify.push("Acid Lab", "Sell already running", 1500)
		end
	end)
end

local function set_fast_production(enabled)
	if enabled then
		if _fast_prod_default == nil then
			_fast_prod_default = biz.get_tunable_int(ACID_PROD_TIME_TUNABLE, 10000)
		end
		local target = math.max(1, math.floor((_fast_prod_default or 10000) / 2))
		biz.set_tunable_int(ACID_PROD_TIME_TUNABLE, target)
		_fast_prod_active = true
	else
		if _fast_prod_default ~= nil then
			biz.set_tunable_int(ACID_PROD_TIME_TUNABLE, _fast_prod_default)
		end
		_fast_prod_active = false
	end
	if notify then
		notify.push("Acid Lab", enabled and "Fast production enabled" or "Fast production disabled", 2000)
	end
end

local function get_fast_prod_active()
	return _fast_prod_active
end

local acidlab_logic = {
	production_tick = production_tick,
	refill_supplies = refill_supplies,
	instant_sell = instant_sell,
	set_fast_production = set_fast_production,
	get_fast_prod_active = get_fast_prod_active,
}

return acidlab_logic
