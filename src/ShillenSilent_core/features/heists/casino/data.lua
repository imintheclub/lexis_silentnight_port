local option_helpers = require("ShillenSilent_core.core.options")
local number_helpers = require("ShillenSilent_core.core.numbers")
local data = {}

data.feature_id = "casino"
data.label_key = "feature.casino.name"
data.safe_payout_target = 3619000

data.cuts = {
	min = 0,
	max = 300,
	step = 5,
	defaults = {
		host = 100,
		player2 = 0,
		player3 = 0,
		player4 = 0,
	},
}

data.player_keys = { "host", "player2", "player3", "player4" }

data.options = {
	difficulties = {
		{ label_key = "casino.difficulty.normal", value = 0 },
		{ label_key = "casino.difficulty.hard", value = 1 },
	},
	approaches = {
		{ label_key = "casino.approach.silent", value = 1 },
		{ label_key = "casino.approach.big_con", value = 2 },
		{ label_key = "casino.approach.aggressive", value = 3 },
	},
	gunmen = {
		{ label_key = "casino.gunman.karl", value = 1 },
		{ label_key = "casino.gunman.charlie", value = 3 },
		{ label_key = "casino.gunman.patrick", value = 5 },
		{ label_key = "casino.gunman.gustavo", value = 2 },
		{ label_key = "casino.gunman.chester", value = 4 },
	},
	loadouts = {
		{ label_key = "casino.loadout.micro_smg_s", value = 1 },
		{ label_key = "casino.loadout.machine_pistol_s", value = 1 },
		{ label_key = "casino.loadout.micro_smg", value = 1 },
		{ label_key = "casino.loadout.double_barrel", value = 1 },
		{ label_key = "casino.loadout.sawed_off", value = 1 },
		{ label_key = "casino.loadout.heavy_revolver", value = 1 },
		{ label_key = "casino.loadout.assault_smg_s", value = 3 },
		{ label_key = "casino.loadout.bullpup_shotgun_s", value = 3 },
		{ label_key = "casino.loadout.machine_pistol", value = 3 },
		{ label_key = "casino.loadout.sweeper_shotgun", value = 3 },
		{ label_key = "casino.loadout.assault_smg", value = 3 },
		{ label_key = "casino.loadout.pump_shotgun", value = 3 },
		{ label_key = "casino.loadout.combat_pdw", value = 5 },
		{ label_key = "casino.loadout.assault_rifle_s", value = 5 },
		{ label_key = "casino.loadout.sawed_off", value = 5 },
		{ label_key = "casino.loadout.compact_rifle", value = 5 },
		{ label_key = "casino.loadout.heavy_shotgun", value = 5 },
		{ label_key = "casino.loadout.combat_mg", value = 5 },
		{ label_key = "casino.loadout.carbine_rifle_s", value = 2 },
		{ label_key = "casino.loadout.assault_shotgun_s", value = 2 },
		{ label_key = "casino.loadout.carbine_rifle", value = 2 },
		{ label_key = "casino.loadout.assault_shotgun", value = 2 },
		{ label_key = "casino.loadout.carbine_rifle", value = 2 },
		{ label_key = "casino.loadout.assault_shotgun", value = 2 },
		{ label_key = "casino.loadout.pump_shotgun_mk2_s", value = 4 },
		{ label_key = "casino.loadout.carbine_rifle_mk2_s", value = 4 },
		{ label_key = "casino.loadout.smg_mk2", value = 4 },
		{ label_key = "casino.loadout.bullpup_rifle_mk2", value = 4 },
		{ label_key = "casino.loadout.pump_shotgun_mk2", value = 4 },
		{ label_key = "casino.loadout.assault_rifle_mk2", value = 4 },
	},
	drivers = {
		{ label_key = "casino.driver.karim", value = 1 },
		{ label_key = "casino.driver.zach", value = 4 },
		{ label_key = "casino.driver.taliana", value = 2 },
		{ label_key = "casino.driver.eddie", value = 3 },
		{ label_key = "casino.driver.chester", value = 5 },
	},
	vehicles = {
		{ label_key = "casino.vehicle.issi", value = 1 },
		{ label_key = "casino.vehicle.asbo", value = 1 },
		{ label_key = "casino.vehicle.blista_kanjo", value = 1 },
		{ label_key = "casino.vehicle.sentinel_classic", value = 1 },
		{ label_key = "casino.vehicle.manchez", value = 4 },
		{ label_key = "casino.vehicle.stryder", value = 4 },
		{ label_key = "casino.vehicle.defiler", value = 4 },
		{ label_key = "casino.vehicle.lectro", value = 4 },
		{ label_key = "casino.vehicle.retinue_mk2", value = 2 },
		{ label_key = "casino.vehicle.drift_yosemite", value = 2 },
		{ label_key = "casino.vehicle.sugoi", value = 2 },
		{ label_key = "casino.vehicle.jugular", value = 2 },
		{ label_key = "casino.vehicle.sultan_classic", value = 3 },
		{ label_key = "casino.vehicle.gauntlet_classic", value = 3 },
		{ label_key = "casino.vehicle.ellie", value = 3 },
		{ label_key = "casino.vehicle.komoda", value = 3 },
		{ label_key = "casino.vehicle.zhaba", value = 5 },
		{ label_key = "casino.vehicle.vagrant", value = 5 },
		{ label_key = "casino.vehicle.outlaw", value = 5 },
		{ label_key = "casino.vehicle.everon", value = 5 },
	},
	hackers = {
		{ label_key = "casino.hacker.rickie", value = 1 },
		{ label_key = "casino.hacker.yohan", value = 3 },
		{ label_key = "casino.hacker.christian", value = 2 },
		{ label_key = "casino.hacker.paige", value = 5 },
		{ label_key = "casino.hacker.avi", value = 4 },
	},
	masks = {
		{ label_key = "casino.mask.none", value = 0 },
		{ label_key = "casino.mask.geometric", value = 1 },
		{ label_key = "casino.mask.hunter", value = 2 },
		{ label_key = "casino.mask.oni_half", value = 3 },
		{ label_key = "casino.mask.emoji", value = 4 },
		{ label_key = "casino.mask.ornate_skull", value = 5 },
		{ label_key = "casino.mask.lucky_fruit", value = 6 },
		{ label_key = "casino.mask.guerilla", value = 7 },
		{ label_key = "casino.mask.clown", value = 8 },
		{ label_key = "casino.mask.animal", value = 9 },
		{ label_key = "casino.mask.riot", value = 10 },
		{ label_key = "casino.mask.oni_full", value = 11 },
		{ label_key = "casino.mask.hockey", value = 12 },
	},
	guards = {
		{ label_key = "casino.guard.elite", value = 0 },
		{ label_key = "casino.guard.pro", value = 1 },
		{ label_key = "casino.guard.unit", value = 2 },
		{ label_key = "casino.guard.rookie", value = 3 },
	},
	keycards = {
		{ label_key = "casino.keycard.none", value = 0 },
		{ label_key = "casino.keycard.level1", value = 1 },
		{ label_key = "casino.keycard.level2", value = 2 },
	},
	targets = {
		{ label_key = "casino.target.cash", value = 0 },
		{ label_key = "casino.target.artwork", value = 2 },
		{ label_key = "casino.target.gold", value = 1 },
		{ label_key = "casino.target.diamonds", value = 3 },
	},
}

data.loadout_ranges_by_approach = {
	[1] = { 1, 2 },
	[2] = { 3, 4 },
	[3] = { 5, 6 },
}

data.loadout_ranges_by_gunman_and_approach = {
	[1] = { [1] = { 1, 2 }, [2] = { 3, 4 }, [3] = { 5, 6 } },
	[3] = { [1] = { 7, 8 }, [2] = { 9, 10 }, [3] = { 11, 12 } },
	[5] = { [1] = { 13, 14 }, [2] = { 15, 16 }, [3] = { 17, 18 } },
	[2] = { [1] = { 19, 20 }, [2] = { 21, 22 }, [3] = { 23, 24 } },
	[4] = { [1] = { 25, 26 }, [2] = { 27, 28 }, [3] = { 29, 30 } },
}

data.vehicle_ranges_by_driver = {
	[1] = { 1, 4 },
	[4] = { 5, 8 },
	[2] = { 9, 12 },
	[3] = { 13, 16 },
	[5] = { 17, 20 },
}

data.primary_target_payouts = {
	[0] = { 2115000, 2326500 },
	[2] = { 2350000, 2585000 },
	[1] = { 2585000, 2843500 },
	[3] = { 3290000, 3619000 },
}

data.buyer_fees = {
	[0] = 0.10,
	[3] = 0.05,
	[6] = 0.00,
}

data.gunman_cuts = {
	[1] = 0.05,
	[3] = 0.07,
	[5] = 0.08,
	[2] = 0.09,
	[4] = 0.10,
}

data.driver_cuts = {
	[1] = 0.05,
	[4] = 0.06,
	[2] = 0.07,
	[3] = 0.09,
	[5] = 0.10,
}

data.hacker_cuts = {
	[1] = 0.03,
	[3] = 0.05,
	[2] = 0.07,
	[5] = 0.09,
	[4] = 0.10,
}

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
			label_key = option.label_key,
			value = option.value,
		}
	end
	return out
end

data.option_names = option_helpers.names

data.option_names_range = option_helpers.names_range

data.option_index_by_value = option_helpers.index_by_value

data.option_value_by_name = option_helpers.value_by_name

data.resolve_option_value = option_helpers.resolve_value

data.clamp_int = number_helpers.clamp_int

function data.clamp_cut(value)
	return number_helpers.clamp_int(value, data.cuts.min, data.cuts.max, data.cuts.min)
end

function data.loadout_range(approach, gunman)
	local gunman_ranges = data.loadout_ranges_by_gunman_and_approach[gunman]
	if gunman_ranges and gunman_ranges[approach] then
		return gunman_ranges[approach]
	end
	return data.loadout_ranges_by_approach[approach] or { 1, 2 }
end

function data.vehicle_range(driver)
	return data.vehicle_ranges_by_driver[driver] or { 1, 4 }
end

return data
