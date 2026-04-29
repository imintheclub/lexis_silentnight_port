local data = require("ShillenSilent_core.features.heists.agency.data")

local state = {
	config = {
		contract = 3,
		payout = data.payout.default,
	},
	flags = {
		collect_safe_ee_only = true,
	},
	runtime = {
		computer_interior_id = nil,
	},
}

function state.contract_index()
	return data.option_index_by_value(data.contracts, state.config.contract, 1)
end

function state.set_contract(value)
	state.config.contract = data.resolve_contract_value(value, state.config.contract)
end

function state.set_payout(value)
	state.config.payout = data.clamp_payout(value)
end

return state
