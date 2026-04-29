local option_helpers = require("ShillenSilent_core.core.options")
local number_helpers = require("ShillenSilent_core.core.numbers")
local data = {}

data.max_transaction = 2100000
data.multiplier = {
	min = 0.0,
	max = 5.0,
	default = 0.8,
	step = 0.1,
}
data.sell_value = {
	default = 0,
	min = 0,
	max = data.max_transaction,
	step = 100000,
}
data.popularity = {
	min = 0,
	max = 100,
	default = 100,
	step = 5,
}

data.options = {
	robberies = {
		{ label_key = "salvageyard.robbery.cargo_ship", value = 0 },
		{ label_key = "salvageyard.robbery.gangbanger", value = 1 },
		{ label_key = "salvageyard.robbery.duggan", value = 2 },
		{ label_key = "salvageyard.robbery.podium", value = 3 },
		{ label_key = "salvageyard.robbery.mctony", value = 4 },
	},
	vehicles = {
		{ name = "LM87", value = 1 },
		{ name = "Cinquemila", value = 2 },
		{ name = "Autarch", value = 3 },
		{ name = "Tigon", value = 4 },
		{ name = "Champion", value = 5 },
		{ name = "10F", value = 6 },
		{ name = "SM722", value = 7 },
		{ name = "Omnis e-GT", value = 8 },
		{ name = "Growler", value = 9 },
		{ name = "Deity", value = 10 },
		{ name = "Itali RSX", value = 11 },
		{ name = "Coquette D10", value = 12 },
		{ name = "Jubilee", value = 13 },
		{ name = "Astron", value = 14 },
		{ name = "Comet S2 Cabr.", value = 15 },
		{ name = "Torero", value = 16 },
		{ name = "Cheetah Classic", value = 17 },
		{ name = "Turismo Classic", value = 18 },
		{ name = "Infernus Classic", value = 19 },
		{ name = "Stafford", value = 20 },
		{ name = "GT500", value = 21 },
		{ name = "Viseris", value = 22 },
		{ name = "Mamba", value = 23 },
		{ name = "Coquette Black.", value = 24 },
		{ name = "Stinger GT", value = 25 },
		{ name = "Z-Type", value = 26 },
		{ name = "Broadway", value = 27 },
		{ name = "Vigero ZX", value = 28 },
		{ name = "Buffalo STX", value = 29 },
		{ name = "Ruston", value = 30 },
		{ name = "Gauntl. Hellfire", value = 31 },
		{ name = "Dominator GTT", value = 32 },
		{ name = "Roosevelt Valor", value = 33 },
		{ name = "Swinger", value = 34 },
		{ name = "Stirling GT", value = 35 },
		{ name = "Omnis", value = 36 },
		{ name = "Tropos Rallye", value = 37 },
		{ name = "Jugular", value = 38 },
		{ name = "Patriot Mil-Spec", value = 39 },
		{ name = "Toros", value = 40 },
		{ name = "Caracara 4x4", value = 41 },
		{ name = "Sentinel Classic", value = 42 },
		{ name = "Weevil", value = 43 },
		{ name = "Blista Kanjo", value = 44 },
		{ name = "Eudora", value = 45 },
		{ name = "Kamacho", value = 46 },
		{ name = "Hellion", value = 47 },
		{ name = "Ellie", value = 48 },
		{ name = "Hermes", value = 49 },
		{ name = "Hustler", value = 50 },
		{ name = "Turismo Om.", value = 51 },
		{ name = "Buffalo EVX", value = 52 },
		{ name = "Itali GTO St.", value = 53 },
		{ name = "Virtue", value = 54 },
		{ name = "Ignus", value = 55 },
		{ name = "Zentorno", value = 56 },
		{ name = "Neon", value = 57 },
		{ name = "Furia", value = 58 },
		{ name = "Zorrusso", value = 59 },
		{ name = "Thrax", value = 60 },
		{ name = "Vagner", value = 61 },
		{ name = "Panthere", value = 62 },
		{ name = "Itali GTO", value = 63 },
		{ name = "S80RR", value = 64 },
		{ name = "Tyrant", value = 65 },
		{ name = "Entity MT", value = 66 },
		{ name = "Torero XO", value = 67 },
		{ name = "Neo", value = 68 },
		{ name = "Corsita", value = 69 },
		{ name = "Paragon R", value = 70 },
		{ name = "Franken Stange", value = 71 },
		{ name = "Comet Safari", value = 72 },
		{ name = "FR36", value = 73 },
		{ name = "Hotring Everon", value = 74 },
		{ name = "Komoda", value = 75 },
		{ name = "Tailgater S", value = 76 },
		{ name = "Jester Classic", value = 77 },
		{ name = "Jester RR", value = 78 },
		{ name = "Euros", value = 79 },
		{ name = "ZR350", value = 80 },
		{ name = "Cypher", value = 81 },
		{ name = "Dominator ASP", value = 82 },
		{ name = "Baller ST-D", value = 83 },
		{ name = "Casco", value = 84 },
		{ name = "Drift Yosemite", value = 85 },
		{ name = "Everon", value = 86 },
		{ name = "Penumbra FF", value = 87 },
		{ name = "V-STR", value = 88 },
		{ name = "Dominator GT", value = 89 },
		{ name = "Schlagen GT", value = 90 },
		{ name = "Cavalcade XL", value = 91 },
		{ name = "Clique", value = 92 },
		{ name = "Boor", value = 93 },
		{ name = "Sugoi", value = 94 },
		{ name = "Greenwood", value = 95 },
		{ name = "Brigham", value = 96 },
		{ name = "Issi Rally", value = 97 },
		{ name = "Seminole Fr.", value = 98 },
		{ name = "Kanjo SJ", value = 99 },
		{ name = "Previon", value = 100 },
	},
	modifications = {
		{ label_key = "salvageyard.mod.version1", value = 0 },
		{ label_key = "salvageyard.mod.version2", value = 1 },
		{ label_key = "salvageyard.mod.version3", value = 2 },
		{ label_key = "salvageyard.mod.version4", value = 3 },
		{ label_key = "salvageyard.mod.version5", value = 4 },
	},
	keep_statuses = {
		{ label_key = "salvageyard.status.cant_claim", value = 0 },
		{ label_key = "salvageyard.status.can_claim", value = 1 },
	},
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

function data.resolve_option_value(options, raw_value, fallback_value)
	local numeric = tonumber(raw_value)
	for i = 1, #options do
		local value = options[i].value
		if value == raw_value or (numeric and type(value) == "number" and value == numeric) then
			return value
		end
	end

	return fallback_value
end

data.clamp_number = number_helpers.clamp_number

data.clamp_int = number_helpers.clamp_int

return data
