local data = require("ShillenSilent_core.features.heists.agency.data")
local state = require("ShillenSilent_core.features.heists.agency.state")

local presets = {}

function presets.collect()
	return {
		contract = state.config.contract,
		payout = data.clamp_payout(state.config.payout),
	}
end

function presets.apply(payload)
	if type(payload) ~= "table" then
		return false
	end

	if payload.contract ~= nil then
		state.set_contract(data.resolve_contract_value(payload.contract, state.config.contract))
	end

	if payload.payout ~= nil then
		state.set_payout(payload.payout)
	end
	return true
end

return presets
