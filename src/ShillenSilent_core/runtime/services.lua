local core = require("ShillenSilent_core.core.bootstrap")
local presets = require("ShillenSilent_core.shared.presets_and_shared")
local heist_state = require("ShillenSilent_core.shared.heist_state")
local solo_launch = require("ShillenSilent_core.runtime.solo_launch")
local cayo_logic = require("ShillenSilent_core.heists.cayo.logic")
local casino_logic = require("ShillenSilent_core.heists.casino.logic")
local salvageyard_logic = require("ShillenSilent_core.heists.salvageyard.logic")

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

local HEIST_ENFORCE_INTERVAL_MS = 150

local runtime_services = {
	started = false,
	next_heist_enforce_tick = 0,
}

local function maybe_sync_max_payouts()
	pcall(presets.hp_refresh_apartment_max_payout, false, false)
	pcall(cayo_logic.cayo_refresh_max_payout, false, false)
	pcall(casino_logic.casino_refresh_max_payout, false, false)

	local doomsday_callbacks = heist_state.doomsday and heist_state.doomsday.callbacks or nil
	if doomsday_callbacks and type(doomsday_callbacks.refresh_max_payout) == "function" then
		pcall(doomsday_callbacks.refresh_max_payout, false, false)
	end
end

local function maybe_enforce_heist_toggles()
	local now_tick = (util and util.get_tick_count and util.get_tick_count()) or nil
	if now_tick and now_tick < runtime_services.next_heist_enforce_tick then
		return
	end

	pcall(cayo_logic.cayo_enforce_heist_toggles)
	pcall(casino_logic.casino_enforce_heist_toggles)
	pcall(salvageyard_logic.salvage_enforce_heist_toggles)

	if now_tick then
		runtime_services.next_heist_enforce_tick = now_tick + HEIST_ENFORCE_INTERVAL_MS
	end
end

local function maybe_maintain_solo_launch()
	for i = 1, #SOLO_LAUNCH_HANDLERS do
		local handler = SOLO_LAUNCH_HANDLERS[i]
		local key = handler.key

		local enabled = state.solo_launch[key]
		local was_enabled = state.solo_launch_prev[key]

		if enabled then
			pcall(solo_launch_generic)
			if handler.setup then
				pcall(handler.setup)
			end
		elseif was_enabled and handler.reset then
			pcall(handler.reset)
		end

		state.solo_launch_prev[key] = enabled
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
			util.yield(0)
		end
	end)

	return true
end

return runtime_services
