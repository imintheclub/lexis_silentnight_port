local data = require("ShillenSilent_core.features.heists.autoshop.data")

local state = {
	config = {
		contract = -1,
		payout = data.payout.default,
	},
	flags = {
		board_reload_offset_406_supported = true,
		board_reload_offset_408_supported = true,
	},
}

function state.contract_index()
	return data.option_index_by_value(data.contracts, state.config.contract, 1)
end

function state.set_contract(value)
	state.config.contract = math.floor(tonumber(value) or -1)
end

function state.set_payout(value)
	state.config.payout = data.clamp_payout(value)
end

return state
