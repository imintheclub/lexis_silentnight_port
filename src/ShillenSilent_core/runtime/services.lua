local core = require("ShillenSilent_core.core.bootstrap")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_core.shared.heist_state")
local solo_launch = require("ShillenSilent_core.runtime.solo_launch")
local cayo_logic = require("ShillenSilent_core.heists.cayo.logic")
local casino_logic = require("ShillenSilent_core.heists.casino.logic")
local salvageyard_logic = require("ShillenSilent_core.heists.salvageyard.logic")
local agency_logic = require("ShillenSilent_core.heists.agency.logic")
local moneyfronts_logic = require("ShillenSilent_core.businesses.moneyfronts.logic")
local nightclub_logic = require("ShillenSilent_core.businesses.nightclub.logic")

local state = core.state

local solo_launch_generic = solo_launch.solo_launch_generic
local solo_launch_casino_setup = solo_launch.solo_launch_casino_setup
local solo_launch_reset_casino = solo_launch.solo_launch_reset_casino
local solo_launch_reset_doomsday = solo_launch.solo_launch_reset_doomsday
local solo_launch_reset_apartment = solo_launch.solo_launch_reset_apartment

local SOLO_LAUNCH_HANDLERS = {
	{ key = "casino", setup = solo_launch_casino_setup, reset = solo_launch_reset_casino },
	{ key = "apartment", setup = nil, reset = solo_launch_reset_apartment },
	{ key = "doomsday", setup = nil, reset = solo_launch_reset_doomsday },
}

-- Cadence intervals (ms) — split services into fast/medium/slow buckets.
local SOLO_LAUNCH_INTERVAL_MS = 150
local PAYOUT_SYNC_INTERVAL_MS = 1000
local HEIST_ENFORCE_INTERVAL_MS = 250
local BIZ_ENFORCE_INTERVAL_MS = 1000

local runtime_services = {
	started = false,
	next_solo_launch_tick = 0,
	next_payout_sync_tick = 0,
	next_heist_enforce_tick = 0,
	next_biz_enforce_tick = 0,
}

local function get_tick()
	return (util and util.get_tick_count and util.get_tick_count()) or 0
end

local function maybe_sync_max_payouts()
	local now = get_tick()
	if now < runtime_services.next_payout_sync_tick then
		return
	end
	runtime_services.next_payout_sync_tick = now + PAYOUT_SYNC_INTERVAL_MS

	pcall(presets.hp_refresh_apartment_max_payout, false, true)
	pcall(cayo_logic.cayo_refresh_max_payout, false, true)
	pcall(casino_logic.casino_refresh_max_payout, false, true)
	pcall(agency_logic.agency_refresh_tp_computer_state)

	local doomsday_callbacks = heist_state.doomsday and heist_state.doomsday.callbacks or nil
	if doomsday_callbacks and type(doomsday_callbacks.refresh_max_payout) == "function" then
		pcall(doomsday_callbacks.refresh_max_payout, false, true)
	end
end

local function maybe_enforce_heist_toggles()
	local now = get_tick()
	if now < runtime_services.next_heist_enforce_tick then
		return
	end
	runtime_services.next_heist_enforce_tick = now + HEIST_ENFORCE_INTERVAL_MS

	pcall(cayo_logic.cayo_enforce_heist_toggles)
	pcall(casino_logic.casino_enforce_heist_toggles)
	pcall(salvageyard_logic.salvage_enforce_heist_toggles)
	pcall(salvageyard_logic.salvage_popularity_lock_tick)
end

local function maybe_enforce_business_toggles()
	local now = get_tick()
	if now < runtime_services.next_biz_enforce_tick then
		return
	end
	runtime_services.next_biz_enforce_tick = now + BIZ_ENFORCE_INTERVAL_MS

	pcall(moneyfronts_logic.tick_heat_lock)
	pcall(nightclub_logic.popularity_lock_tick)
end

local function maybe_maintain_solo_launch()
	-- Resets must run immediately on toggle-off (not gated), so check
	-- transitions every tick but gate the maintenance writes.
	local any_active = false
	for i = 1, #SOLO_LAUNCH_HANDLERS do
		local handler = SOLO_LAUNCH_HANDLERS[i]
		local key = handler.key
		local enabled = state.solo_launch[key]
		local was_enabled = state.solo_launch_prev[key]

		if not enabled and was_enabled and handler.reset then
			pcall(handler.reset)
		end

		state.solo_launch_prev[key] = enabled
		if enabled then
			any_active = true
		end
	end

	if not any_active then
		return
	end

	local now = get_tick()
	if now < runtime_services.next_solo_launch_tick then
		return
	end
	runtime_services.next_solo_launch_tick = now + SOLO_LAUNCH_INTERVAL_MS

	for i = 1, #SOLO_LAUNCH_HANDLERS do
		local handler = SOLO_LAUNCH_HANDLERS[i]
		if state.solo_launch[handler.key] then
			pcall(solo_launch_generic)
			if handler.setup then
				pcall(handler.setup)
			end
		end
	end
end

function runtime_services.start()
	if runtime_services.started then
		return false
	end
	runtime_services.started = true

	util.create_thread(function()
		while true do
			pcall(maybe_maintain_solo_launch)
			pcall(maybe_sync_max_payouts)
			pcall(maybe_enforce_heist_toggles)
			pcall(maybe_enforce_business_toggles)
			util.yield(0)
		end
	end)

	return true
end

return runtime_services
