local biz = require("ShillenSilent_core.businesses.shared")

-- Acid Lab uses slot 7 in the shared production timer system.
local ACID_SLOT = 7

-- Instant sell: manipulate fm_content_acid_lab_sell script locals (EE offsets).
local SELL_SCRIPT = "fm_content_acid_lab_sell"
local SELL_STATE_OFFSET = 7050
local SELL_FLAGS_OFFSET = 7059
local SELL_BIT_WON = 11

local ACID_STOCK_STAT = "PRODTOTALFORFACTORY6"
local ACID_MAX_CAPACITY = 160
local FAST_LOOP_INTERVAL_MS = 150

local _fast_prod_active = false
local _fast_prod_thread_started = false
local _fast_prod_status = "Stopped"

local function production_tick()
	biz.production_tick(ACID_SLOT)
	if notify then
		notify.push("Acid Lab", "Production tick completed", 2000)
	end
end

local function refill_supplies()
	biz.run_guarded_job("acidlab_refill", function()
		biz.fill_supply_slot(ACID_SLOT)
		if notify then
			notify.push("Acid Lab", "Supplies refill completed", 2000)
		end
	end, function()
		if notify then
			notify.push("Acid Lab", "Supplies refill failed (already in progress)", 1500)
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
			notify.push("Acid Lab", (ok1 and ok2) and "Instant sell completed" or "Instant sell failed to apply", 2200)
		end
	end, function()
		if notify then
			notify.push("Acid Lab", "Instant sell failed (already running)", 1500)
		end
	end)
end

local function set_fast_production(enabled)
	enabled = enabled == true
	if enabled then
		if not util or not util.create_thread then
			if notify then
				notify.push("Acid Lab", "Fast production unavailable on this runtime", 2200)
			end
			return
		end
		if not _fast_prod_thread_started then
			_fast_prod_thread_started = true
			util.create_thread(function()
				while true do
					if _fast_prod_active then
						local mp = biz.GetMP()
						local units = biz.get_stat_int(mp .. ACID_STOCK_STAT, 0) or 0
						if units >= ACID_MAX_CAPACITY then
							_fast_prod_active = false
							_fast_prod_status = "Full"
							if notify then
								notify.push("Acid Lab", "Fast production stopped: stock is full", 2200)
							end
						else
							_fast_prod_status = "Running"
							biz.production_tick(ACID_SLOT)
						end
						util.yield(FAST_LOOP_INTERVAL_MS)
					else
						if _fast_prod_status == "Running" then
							_fast_prod_status = "Stopped"
						end
						util.yield(200)
					end
				end
			end)
		end
	end
	_fast_prod_active = enabled
	_fast_prod_status = enabled and "Running" or "Stopped"
	if notify then
		notify.push("Acid Lab", enabled and "Fast production enabled" or "Fast production disabled", 2000)
	end
end

local function get_fast_prod_active()
	return _fast_prod_active
end

local function get_fast_prod_status()
	return _fast_prod_status
end

local acidlab_logic = {
	production_tick = production_tick,
	refill_supplies = refill_supplies,
	instant_sell = instant_sell,
	set_fast_production = set_fast_production,
	get_fast_prod_active = get_fast_prod_active,
	get_fast_prod_status = get_fast_prod_status,
}

return acidlab_logic
