local option_helpers = require("ShillenSilent_core.core.options")
local number_helpers = require("ShillenSilent_core.core.numbers")
local data = {}

data.payout = {
	default = 0,
	max = 2500000,
	step = 50000,
}

data.contracts = {
	{ label_key = "agency.contract.none", value = 3 },
	{ label_key = "agency.contract.nightclub", value = 4 },
	{ label_key = "agency.contract.marina", value = 12 },
	{ label_key = "agency.contract.nightlife_leak", value = 28 },
	{ label_key = "agency.contract.country_club", value = 60 },
	{ label_key = "agency.contract.guest_list", value = 123 },
	{ label_key = "agency.contract.high_society_leak", value = 254 },
	{ label_key = "agency.contract.davis", value = 508 },
	{ label_key = "agency.contract.ballas", value = 1020 },
	{ label_key = "agency.contract.south_central_leak", value = 2044 },
	{ label_key = "agency.contract.studio_time", value = 2045 },
	{ label_key = "agency.contract.dont_with_dre", value = 4095 },
}

data.blips = {
	entrance = 826,
	franklin = 88,
}

data.option_names = option_helpers.names

function data.localized_options(options, translate)
	local out = {}
	for i = 1, #options do
		local option = options[i]
		local label = option.name or option.label_key
		if option.label_key and type(translate) == "function" then
			label = translate(option.label_key)
		end
		out[i] = {
			name = label,
			value = option.value,
		}
	end
	return out
end

data.option_index_by_value = option_helpers.index_by_value

data.option_value_by_name = option_helpers.value_by_name

function data.clamp_payout(value)
	return number_helpers.clamp_int(value, 0, data.payout.max, data.payout.default)
end

function data.story_strand_from_contract(contract)
	local value = math.floor(tonumber(contract) or 0)
	if value < 18 then
		return 0
	end
	if value < 128 then
		return 1
	end
	if value < 2044 then
		return 2
	end
	return -1
end

function data.resolve_contract_value(value, default_value)
	local number = tonumber(value)
	if number then
		number = math.floor(number)
		for i = 1, #data.contracts do
			if data.contracts[i].value == number then
				return number
			end
		end
	end
	if type(value) == "string" then
		return data.option_value_by_name(data.contracts, value, default_value)
	end
	return default_value
end

return data
