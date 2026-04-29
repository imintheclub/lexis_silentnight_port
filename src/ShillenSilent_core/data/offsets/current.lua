return {
	info = {
		globals = {
			gta_plus = 1965683,
		},
		gta_plus = {
			rank_offset = 3,
			rank_value = 10,
		},
	},
	apartment = {
		globals = {
			ready = {
				player2 = 2659033,
				player3 = 2659501,
				player4 = 2659969,
			},
			cooldown = {
				step1 = 1877303 + 1 + 76,
				step2 = 2635125 + 1,
				player_stride = 77,
			},
			reload = {
				step1 = 2635124,
				step2 = 1937981 + 2768,
			},
			root_content = {
				step1 = 1941591 + 10,
				step2 = 2635125 + 2,
				step3 = 1936048 + 1787,
			},
			world_apartment_id = {
				ee = 1845299 + 1 + 260 + 37,
				legacy = 1845250 + 1 + 260 + 37,
				ee_stride = 883,
				legacy_stride = 880,
			},
			cuts = {
				host_balance = 1936013 + 1 + 1,
				player2_balance = 1936013 + 1 + 2,
				player3_balance = 1936013 + 1 + 3,
				player4_balance = 1936013 + 1 + 4,
				player1 = 1937981 + 3008 + 1,
				player2 = 1937981 + 3008 + 2,
				player3 = 1937981 + 3008 + 3,
				player4 = 1937981 + 3008 + 4,
			},
		},
		stats = {
			heist_mission_rcont_id = "HEIST_MISSION_RCONT_ID_",
			heist_mission_depth_lv = "HEIST_MISSION_DEPTH_LV_",
			heist_planning_stage = "HEIST_PLANNING_STAGE",
			bitset_heist_vs_missions = "BITSET_HEIST_VS_MISSIONS",
			heist_session_id_macaddr = "HEIST_SESSION_ID_MACADDR",
			heist_leader_apart_id = "HEIST_LEADER_APART_ID",
			heist_progress_hash = "MPPLY_HEIST_PROGRESS_HASH",
			heist_total_reward_cosmetic = "HEIST_TOTAL_REWARD_COSMETIC",
			property_house = "PROPERTY_HOUSE",
			flow_order_progress = "MPPLY_HEISTFLOWORDERPROGRESS",
			flow_order_award = "MPPLY_AWD_HST_ORDER",
			team_progress = "MPPLY_HEISTTEAMPROGRESSBITSET",
			team_award = "MPPLY_AWD_HST_SAME_TEAM",
			no_death_progress = "MPPLY_HEISTNODEATHPROGREITSET",
			no_death_award = "MPPLY_AWD_HST_ULT_CHAL",
			saved_strand = "HEIST_SAVED_STRAND_",
			saved_strand_level_suffix = "_L",
		},
		scripts = {
			mission_controller = "fm_mission_controller",
			launcher = "fmmc_launcher",
			excluded_interiors = {
				"am_mp_submarine",
				"am_mp_arcade",
				"am_mp_defunct_base",
				"am_mp_fixer_hq",
				"am_mp_auto_shop",
				"am_mp_salvage_yard",
			},
		},
		locals = {
			fleeca_hack = 12223 + 24,
			fleeca_drill = 10511 + 11,
			pacific_hack = 10217,
			pacific_finish_status = 21457,
			pacific_finish_percent = 22136,
			finish_take_1 = 23081,
			finish_take_2 = 29017,
			finish_take_3 = 32541,
			other_finish_status = 20395,
			launcher_value = 20056 + 34,
			launcher_required_players = 20056 + 15,
			launcher_flags = 20297,
		},
		launcher = {
			player_count_base = 794954 + 4 + 1,
			player_count_stride = 95,
			player_count_offset = 75,
			globals = {
				player_count_1 = 4718592 + 3539,
				player_count_2 = 4718592 + 3540,
				flow = 4718592 + 3542 + 1,
				extra = 4718592 + 192451 + 1,
				flags = 4718592 + 3536,
			},
		},
	},
	cayo = {
		globals = {
			cuts = {
				host = 1980923,
				player2 = 1980924,
				player3 = 1980925,
				player4 = 1980926,
			},
			ready = {
				player2 = 1981184,
				player3 = 1981212,
				player4 = 1981240,
			},
			kosatka_request = {
				2733138 + 613,
				2733002 + 613,
			},
		},
		stats = {
			bs_gen = "H4CNF_BS_GEN",
			bs_entr = "H4CNF_BS_ENTR",
			bs_abil = "H4CNF_BS_ABIL",
			approach = "H4CNF_APPROACH",
			playthrough_status = "H4_PLAYTHROUGH_STATUS",
			progress = "H4_PROGRESS",
			missions = "H4_MISSIONS",
			weapons = "H4CNF_WEAPONS",
			target = "H4CNF_TARGET",
			uniform = "H4CNF_UNIFORM",
			grappel = "H4CNF_GRAPPEL",
			trojan = "H4CNF_TROJAN",
			weapon_disruption = "H4CNF_WEP_DISRP",
			armor_disruption = "H4CNF_ARM_DISRP",
			heli_disruption = "H4CNF_HEL_DISRP",
			loot_paint = "H4LOOT_PAINT",
			loot_paint_scoped = "H4LOOT_PAINT_SCOPED",
			loot_paint_value = "H4LOOT_PAINT_V",
			target_posix = "H4_TARGET_POSIX",
			cooldown = "H4_COOLDOWN",
			cooldown_hard = "H4_COOLDOWN_HARD",
		},
		tunables = {
			bag_max_capacity = "HEIST_BAG_MAX_CAPACITY",
			pavel_cut = "IH_DEDUCTION_PAVEL_CUT",
			fencing_fee = "IH_DEDUCTION_FENCING_FEE",
		},
		scripts = {
			planning = "heist_island_planning",
			content = "fm_content_island_heist",
			controller = "fm_mission_controller_2020",
		},
		locals = {
			planning_reload = 1570,
			voltlab_complete = 10166 + 24,
			password_complete = 26486,
			plasma_cutter = 32589 + 3,
			drainage_pipe = 31349,
			finish_status = 56223,
			finish_cash_take = 58000,
		},
		blips = {
			kosatka = 760,
			heist = 428,
		},
		coords = {
			mazebank = { x = -75.146, y = -818.687, z = 326.175, heading = 357.531 },
			kosatka_interior = { x = 1561.087, y = 386.61, z = -49.685, heading = 179.884 },
			residence = { x = 5010.0, y = -5753.0, z = 30.0 },
			main_target = { x = 5006.0, y = -5754.0, z = 16.0 },
			gate = { x = 4992.0, y = -5720.0, z = 21.0 },
			center = { x = 4971.0, y = -5136.0, z = 4.0 },
			loot1 = { x = 5002.0, y = -5751.0, z = 16.0 },
			loot2 = { x = 5031.0, y = -5737.0, z = 19.0 },
			loot3 = { x = 5081.0, y = -5756.0, z = 17.0 },
			gate_outside = { x = 4977.0, y = -5706.0, z = 20.0 },
			airport = { x = 4443.0, y = -4510.0, z = 5.0 },
			escape = { x = 3698.0, y = -6133.0, z = -5.0 },
		},
		natives = {
			get_first_blip_info_id = 0x1BEDE233E6CD2A1F,
			get_closest_blip_info_id = 0xD484BF71050CA1EE,
			freeze_entity_position = 0x428CA6DBD1094446,
			set_entity_coords_no_offset = 0x239A3351AC1DA385,
			set_entity_heading = 0x8E2530AA8ADA980E,
		},
	},
	casino = {
		blips = {
			arcade = 740,
		},
		globals = {
			buyer = 1975747,
			finale_flag = 2685153 + 21,
			finale_target = 1973198,
			big_con_approach = 1973219,
			cuts = {
				host = 1975557,
				player2 = 1975558,
				player3 = 1975559,
				player4 = 1975560,
			},
			ready = {
				player2 = 1977672,
				player3 = 1977741,
				player4 = 1977810,
			},
		},
		stats = {
			disrupt_shipments = "H3OPT_DISRUPTSHIP",
			body_armor_level = "H3OPT_BODYARMORLVL",
			crew_weapon = "H3OPT_CREWWEAP",
			crew_driver = "H3OPT_CREWDRIVER",
			crew_hacker = "H3OPT_CREWHACKER",
			key_levels = "H3OPT_KEYLEVELS",
			mod_vehicle = "H3OPT_MODVEH",
			masks = "H3OPT_MASKS",
			weapons = "H3OPT_WEAPS",
			vehicles = "H3OPT_VEHS",
			approach = "H3OPT_APPROACH",
			bitset0 = "H3OPT_BITSET0",
			access_points = "H3OPT_ACCESSPOINTS",
			target = "H3OPT_TARGET",
			poi = "H3OPT_POI",
			bitset1 = "H3OPT_BITSET1",
			partial_pass = "H3_PARTIALPASS",
			notes = "CAS_HEIST_NOTS",
			flow = "CAS_HEIST_FLOW",
			last_approach = "H3_LAST_APPROACH",
			hard_approach = "H3_HARD_APPROACH",
			skip_count = "H3_SKIPCOUNT",
			missions_skipped = "H3_MISSIONSKIPPED",
			board_dialogue0 = "H3_BOARD_DIALOGUE0",
			board_dialogue1 = "H3_BOARD_DIALOGUE1",
			board_dialogue2 = "H3_BOARD_DIALOGUE2",
			vehicles_used = "H3_VEHICLESUSED",
			completed_posix = "H3_COMPLETEDPOSIX",
			cooldown = "MPPLY_H3_COOLDOWN",
			arcade_setup_done = 27227,
		},
		scripts = {
			controller = "fm_mission_controller",
			planning = "gb_casino_heist_planning",
			launcher = "fmmc_launcher",
		},
		locals = {
			planning_reload = { 210, 212 },
			planning_reload_value = 2,
			autograbber_grab = 10697,
			autograbber_speed = 10697 + 14,
			keycards_fix = 63638,
			objective_flags = 20397,
			fingerprint_hack = 54042,
			keypad_hack = 55108,
			vault_drill_base = 10551,
			vault_drill_first = 7,
			vault_drill_second = 37,
			team_lives = 22126,
		},
		preps = {
			poi_unlock_pairs = {
				{ "H3OPT_POI", -1 },
				{ "H3OPT_ACCESSPOINTS", -1 },
				{ "CAS_HEIST_NOTS", -1 },
				{ "CAS_HEIST_FLOW", -1 },
			},
			reset_pairs = {
				{ "H3OPT_DISRUPTSHIP", 0 },
				{ "H3OPT_BODYARMORLVL", 0 },
				{ "H3OPT_CREWWEAP", 0 },
				{ "H3OPT_CREWDRIVER", 0 },
				{ "H3OPT_CREWHACKER", 0 },
				{ "H3OPT_KEYLEVELS", 0 },
				{ "H3OPT_MODVEH", 0 },
				{ "H3OPT_MASKS", 0 },
				{ "H3OPT_WEAPS", 0 },
				{ "H3OPT_VEHS", 0 },
				{ "H3OPT_APPROACH", 0 },
				{ "H3OPT_BITSET0", 0 },
				{ "H3OPT_ACCESSPOINTS", 0 },
				{ "H3OPT_TARGET", 0 },
				{ "H3OPT_POI", 0 },
				{ "H3OPT_BITSET1", 0 },
				{ "H3_PARTIALPASS", 0 },
				{ "CAS_HEIST_NOTS", 0 },
				{ "CAS_HEIST_FLOW", -1 },
				{ "H3_LAST_APPROACH", 0 },
				{ "H3_HARD_APPROACH", 0 },
				{ "H3_SKIPCOUNT", 0 },
				{ "H3_MISSIONSKIPPED", 0 },
				{ "H3_BOARD_DIALOGUE0", 0 },
				{ "H3_BOARD_DIALOGUE1", 0 },
				{ "H3_BOARD_DIALOGUE2", 0 },
				{ "H3_VEHICLESUSED", 0 },
				{ "H3_COMPLETEDPOSIX", 0 },
			},
		},
		payout = {
			vault_bonus = 819000,
		},
		tunables = {
			crew_cuts = {
				{ name = "CH_LESTER_CUT", default = 5 },
				{ name = "HEIST3_PREPBOARD_GUNMEN_KARL_CUT", default = 5 },
				{ name = "HEIST3_PREPBOARD_GUNMEN_GUSTAVO_CUT", default = 9 },
				{ name = "HEIST3_PREPBOARD_GUNMEN_CHARLIE_CUT", default = 7 },
				{ name = "HEIST3_PREPBOARD_GUNMEN_CHESTER_CUT", default = 10 },
				{ name = "HEIST3_PREPBOARD_GUNMEN_PATRICK_CUT", default = 8 },
				{ name = "HEIST3_DRIVERS_KARIM_CUT", default = 5 },
				{ name = "HEIST3_DRIVERS_TALIANA_CUT", default = 7 },
				{ name = "HEIST3_DRIVERS_EDDIE_CUT", default = 9 },
				{ name = "HEIST3_DRIVERS_ZACH_CUT", default = 6 },
				{ name = "HEIST3_DRIVERS_CHESTER_CUT", default = 10 },
				{ name = "HEIST3_HACKERS_RICKIE_CUT", default = 3 },
				{ name = "HEIST3_HACKERS_CHRISTIAN_CUT", default = 7 },
				{ name = "HEIST3_HACKERS_YOHAN_CUT", default = 5 },
				{ name = "HEIST3_HACKERS_AVI_CUT", default = 10 },
				{ name = "HEIST3_HACKERS_PAIGE_CUT", default = 9 },
			},
			buyer_multipliers = {
				"CH_BUYER_MOD_SHORT",
				"CH_BUYER_MOD_MED",
				"CH_BUYER_MOD_LONG",
			},
		},
		finish = {
			aggressive_step1 = 20395,
			silent_step2 = 20395 + 1062,
			step3 = 20395 + 1740 + 1,
			step4_money = 20395 + 2686,
			step5 = 29016 + 1,
			step6 = 32472 + 1 + 68,
		},
		launcher = {
			value_offset = 20056 + 34,
			required_players_offset = 20056 + 15,
			flags_offset = 20297,
			player_count_base = 794954 + 4 + 1,
			player_count_stride = 95,
			player_count_offset = 75,
			globals = {
				player_count_1 = 4718592 + 3539,
				player_count_2 = 4718592 + 3540,
				flow = 4718592 + 3542 + 1,
				extra = 4718592 + 192451 + 1,
				flags = 4718592 + 3536,
			},
		},
		coords = {
			tunnel = { x = 968.0, y = -73.0, z = 75.0 },
			staff_lobby = { x = 982.0, y = 16.0, z = 82.0 },
			staff_lobby_inside = { x = 2547.0, y = -270.0, z = -58.0 },
			side_safe = { x = 2522.0, y = -287.0, z = -58.0 },
			tunnel_door = { x = 2469.0, y = -279.0, z = -70.0 },
		},
	},
	agency = {
		blips = {
			entrance = 826,
			franklin = 88,
		},
		computer = {
			coords = { x = -578.981, y = -711.381, z = 116.805, heading = 123.687 },
			fallback_radius = 35.0,
		},
		tunables = {
			payout = "FIXER_FINALE_LEADER_CASH_REWARD",
			story_cooldown_posix = "FIXER_STORY_COOLDOWN_POSIX",
			security_contract_cooldown = "FIXER_SECURITY_CONTRACT_COOLDOWN_TIME",
			payphone_cooldown = "REQUEST_FRANKLIN_PAYPHONE_HIT_COOLDOWN",
		},
		stats = {
			story_bs = "FIXER_STORY_BS",
			story_strand = "FIXER_STORY_STRAND",
			general_bs = "FIXER_GENERAL_BS",
			completed_bs = "FIXER_COMPLETED_BS",
			story_cooldown = "FIXER_STORY_COOLDOWN",
			safe_cash_value = "FIXER_SAFE_CASH_VALUE",
		},
		globals = {
			safe_collect_bool = 2708850,
		},
		finish = {
			fm_mission_controller = {
				step1_offset = 20395 + 1062,
				step2_offset = 20395 + 1232 + 1,
				step3_offset = 20395 + 1,
			},
			fm_mission_controller_2020 = {
				step1_offset = 56223 + 1589,
				step2_offset = 56223 + 1776 + 1,
				step3_offset = 56223 + 1,
			},
		},
	},
	salvageyard = {
		blips = {
			entrance = 867,
		},
		coords = {
			board = { x = 1074.720, y = -2275.502, z = -48.999, heading = 84.481 },
			sell = { x = 1169.749, y = -2973.535, z = 5.902, heading = 271.204 },
		},
		scripts = {
			interior = "am_mp_salvage_yard",
			planning = "vehrob_planning",
			planning_force_offsets = { 418, 416 },
			planning_reload_offsets = { 537, 535 },
			missions = {
				{
					id = "cargo_ship",
					script = "fm_content_vehrob_cargo_ship",
					offsets = { { step1 = 7187 + 1, step2 = 7332 + 1249 }, { step1 = 7185 + 1, step2 = 7330 + 1249 } },
				},
				{
					id = "police",
					script = "fm_content_vehrob_police",
					offsets = { { step1 = 9013 + 1, step2 = 9146 + 1305 }, { step1 = 9011 + 1, step2 = 9144 + 1305 } },
				},
				{
					id = "arena",
					script = "fm_content_vehrob_arena",
					offsets = { { step1 = 7914 + 1, step2 = 8034 + 1314 }, { step1 = 7912 + 1, step2 = 8032 + 1314 } },
				},
				{
					id = "casino_prize",
					script = "fm_content_vehrob_casino_prize",
					offsets = { { step1 = 9193 + 1, step2 = 9330 + 1258 }, { step1 = 9191 + 1, step2 = 9328 + 1258 } },
				},
				{
					id = "submarine",
					script = "fm_content_vehrob_submarine",
					offsets = { { step1 = 6220 + 1, step2 = 6358 + 1159 }, { step1 = 6218 + 1, step2 = 6356 + 1159 } },
				},
			},
			tow_truck = {
				script = "fm_content_tow_truck_work",
				veh_bases = { 1783, 1781 },
				mission_bases = { 1840, 1838 },
			},
		},
		stats = {
			gen_bs = "SALV23_GEN_BS",
			scope_bs = "SALV23_SCOPE_BS",
			fm_prog = "SALV23_FM_PROG",
			inst_prog = "SALV23_INST_PROG",
			week_sync = "SALV23_WEEK_SYNC",
			safe_cash_value = "SALVAGE_SAFE_CASH_VALUE",
		},
		globals = {
			safe_collect_bool = 2708859,
		},
		natives = {
			stat_set_packed_int = 0x1581503AE529CD2E,
			stat_get_packed_int = 0x0BC900A27CBBAC55,
			set_entity_heading = 0x8E2530AA8ADA980E,
		},
		packed_stats = {
			popularity = 51051,
		},
		tunables = {
			setup_price = 71522671,
			claim_price_standard = "SALV23_VEHICLE_CLAIM_PRICE",
			claim_price_discounted = "SALV23_VEHICLE_CLAIM_PRICE_FORGERY_DISCOUNT",
			weekly_cooldown = "SALV23_VEH_ROBBERY_WEEK_ID",
			salvage_multiplier = 1601153005,
		},
		defaults = {
			setup_price = 20000,
			claim_price_standard = 20000,
			claim_price_discounted = 10000,
		},
		slot_tunables = {
			[1] = {
				robbery = 1152433341,
				vehicle = -1012732012,
				keep = -1700733442,
				value = -1699398139,
				status_stat = "SALV23_VEHROB_STATUS0",
			},
			[2] = {
				robbery = 852564222,
				vehicle = 1366330161,
				keep = -1547046832,
				value = -1997104504,
				status_stat = "SALV23_VEHROB_STATUS1",
			},
			[3] = {
				robbery = 552662330,
				vehicle = 1806057372,
				keep = 1830093543,
				value = -1704051341,
				status_stat = "SALV23_VEHROB_STATUS2",
			},
		},
	},
	arcade = {
		stats = {
			safe_cash_value = "ARCADE_SAFE_CASH_VALUE",
		},
		globals = {
			safe_collect = 2708841,
		},
	},
	garment = {
		blips = {
			entrance = 900,
		},
		globals = {
			safe_collect = 2708883,
		},
		stats = {
			safe_cash_value = "HDEN24_SAFE_CASH_VALUE",
		},
	},
	bailoffice = {
		blips = {
			entrance = 893,
		},
		globals = {
			safe_collect = 2708868,
		},
		stats = {
			safe_cash_value = "BAIL_SAFE_CASH_VALUE",
		},
	},
	moneyfronts = {
		stats = {
			owned = {
				car_wash = "SB_CAR_WASH_OWNED",
				heli_tours = "SB_HELI_TOURS_OWNED",
				weed_shop = "SB_WEED_SHOP_OWNED",
			},
			car_wash_safe_cash_value = "CWASH_SAFE_CASH_VALUE",
		},
		globals = {
			car_wash_safe_collect = 2708890,
		},
		natives = {
			stat_set_packed_int = 0x1581503AE529CD2E,
			stat_get_packed_int = 0x0BC900A27CBBAC55,
		},
		packed_stats = {
			heat_indices = { 24924, 24925, 24926 },
			character_slots = { 0, 1 },
		},
	},
	acidlab = {
		stats = {
			stock = "PRODTOTALFORFACTORY6",
		},
		limits = {
			max_capacity = 160,
		},
		supply = {
			base = 1673814,
			slot = 7,
			fill_repeats = 7,
			fill_yield_ms = 5,
		},
		production = {
			timer_root = 2708936 - ((6 - 1) * 2) - 1,
		},
		scripts = {
			freemode = "freemode",
			sell = {
				name = "fm_content_acid_lab_sell",
				state_offset = 7050,
				state_value = 1,
				flags_offset = 7059,
				win_bit = 11,
			},
		},
	},
	bunker = {
		blips = {
			entrance = 557,
		},
		stats = {
			stock = "PRODTOTALFORFACTORY5",
			owned = "FACTORYSLOT5",
		},
		limits = {
			max_capacity = 100,
		},
		supply = {
			base = 1673814,
			slot = 6,
			fill_repeats = 7,
			fill_yield_ms = 5,
		},
		production = {
			timer_root = 2708936 - ((6 - 1) * 2) - 1,
		},
		scripts = {
			sell = {
				name = "gb_gunrunning",
				offset = 1268 + 774,
				value = 0,
			},
		},
		tunables = {
			disable_raids = "BIKER_DISABLE_DEFEND_POLICE_RAID",
			reminders = "BIKER_PRODUCT_REMINDER_COOLDOWN",
		},
		defaults = {
			raids_default = 0,
			raids_disabled = 1,
			reminder_cooldown_disabled = 86400000,
			reminder_cooldown_default = 300000,
		},
	},
	hangar = {
		blips = {
			entrance = 569,
		},
		stats = {
			owned = "HANGAR_OWNED",
			stock = "HANGAR_CONTRABAND_TOTAL",
		},
		limits = {
			max_cargo = 50,
		},
		natives = {
			stat_set_packed_bool = 0xDB8A58AEAA67CD07,
		},
		packed_stats = {
			cargo_available = 36828,
			character_slots = { 0, 1 },
		},
	},
	speccargo = {
		stats = {
			warehouse_slot_prefix = "PROP_WHOUSE_SLOT",
			crate_total_prefix = "CONTOTALFORWHOUSE",
		},
		natives = {
			stat_set_packed_bool = 0xDB8A58AEAA67CD07,
		},
		packed_stats = {
			supply_first = 32359,
			supply_last = 32363,
			character_slots = { 0, 1 },
		},
		scripts = {
			sell = {
				name = "gb_contraband_sell",
				timer_offset = 569 + 1,
				timer_value = 67230,
				state_offset = 569 + 7,
				state_value = 7,
			},
		},
		tunables = {
			disable_raids = "BIKER_DISABLE_DEFEND_POLICE_RAID",
			reminders = "BIKER_PRODUCT_REMINDER_COOLDOWN",
		},
		defaults = {
			raids_default = 0,
			raids_disabled = 1,
			reminder_cooldown_disabled = 86400000,
			reminder_cooldown_default = 300000,
		},
	},
	nightclub = {
		blips = {
			entrance = 614,
		},
		stats = {
			owned = "NIGHTCLUB_OWNED",
			product_base = "HUB_PROD_TOTAL_",
			popularity = "CLUB_POPULARITY",
			safe_cash_value = "CLUB_SAFE_CASH_VALUE",
			safe_pay_time_left = "CLUB_PAY_TIME_LEFT",
		},
		limits = {
			safe_max = 250000,
		},
		globals = {
			safe_collect = 2708832,
			safe_top_range = {
				first = 262145 + 23750,
				last = 262145 + 23769,
			},
		},
		tunables = {
			disable_raids = "BIKER_DISABLE_DEFEND_POLICE_RAID",
			reminders = "BIKER_PRODUCT_REMINDER_COOLDOWN",
			accrue_by_target = {
				cargo = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_CARGO",
				weapons = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_WEAPONS",
				coke = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_COKE",
				meth = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_METH",
				weed = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_WEED",
				docs = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_FORGED_DOCUMENTS",
				cash = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_COUNTERFEIT_CASH",
			},
			accrue_times = {
				{ name = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_CARGO", default = 8400000 },
				{ name = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_WEAPONS", default = 4800000 },
				{ name = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_COKE", default = 14400000 },
				{ name = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_METH", default = 7200000 },
				{ name = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_WEED", default = 2400000 },
				{ name = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_FORGED_DOCUMENTS", default = 1800000 },
				{ name = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_COUNTERFEIT_CASH", default = 3600000 },
			},
		},
		defaults = {
			fast_accrue_time = 1000,
			raids_default = 0,
			raids_disabled = 1,
			reminder_cooldown_disabled = 86400000,
			reminder_cooldown_default = 300000,
		},
	},
	mc = {
		blips = {
			meth = 499,
			weed = 496,
			cocaine = 497,
			counterfeit = 500,
			forgery = 498,
		},
		stats = {
			factory_slot_prefix = "FACTORYSLOT",
			sub_stock = {
				meth = "PRODTOTALFORFACTORY3",
				weed = "PRODTOTALFORFACTORY1",
				cocaine = "PRODTOTALFORFACTORY4",
				counterfeit = "PRODTOTALFORFACTORY2",
				forgery = "PRODTOTALFORFACTORY0",
			},
		},
		supply = {
			base = 1673814,
			fill_repeats = 7,
			fill_yield_ms = 5,
		},
		production = {
			timer_root = 2708936 - ((6 - 1) * 2) - 1,
		},
		scripts = {
			sell = {
				name = "gb_biker_contraband_sell",
				offset = 731 + 122,
				value = 15,
			},
		},
		tunables = {
			reminders = "BIKER_PRODUCT_REMINDER_COOLDOWN",
			disable_raids = "BIKER_DEFEND_MISSIONS_RAND",
		},
		defaults = {
			reminder_cooldown_disabled = 86400000,
			reminder_cooldown_default = 300000,
			raids_default = 5,
		},
		natives = {
			get_first_blip_info_id = 0x1BEDE233E6CD2A1F,
			does_blip_exist = 0xA6DB27D19ECBB7DA,
			get_blip_coords = 0x586AFE3FF72D996E,
			do_screen_fade_in = 0xD4E8E24955024033,
			display_hud = 0xA6294919E56FF02A,
			display_radar = 0xA0EBB943C300E693,
		},
	},
	autoshop = {
		blips = {
			entrance = 779,
		},
		scripts = {
			interior = "am_mp_auto_shop",
			board_reload = "tuner_planning",
			finish = "fm_mission_controller_2020",
		},
		board = {
			coords = { x = -1349.024, y = 138.381, z = -95.121, heading = 194.202 },
			reload_offsets = { 406, 408 },
			reload_value = 2,
		},
		stats = {
			current = "TUNER_CURRENT",
			gen_bs = "TUNER_GEN_BS",
		},
		tunables = {
			cooldown = "TUNER_ROBBERY_COOLDOWN_TIME",
			cooldown_legacy = "TUNER_ROBBERY_COOLDOWN",
			contact_fee = "TUNER_ROBBERY_CONTACT_FEE",
			leader_rewards = {
				"TUNER_ROBBERY_LEADER_CASH_REWARD0",
				"TUNER_ROBBERY_LEADER_CASH_REWARD1",
				"TUNER_ROBBERY_LEADER_CASH_REWARD2",
				"TUNER_ROBBERY_LEADER_CASH_REWARD3",
				"TUNER_ROBBERY_LEADER_CASH_REWARD4",
				"TUNER_ROBBERY_LEADER_CASH_REWARD5",
				"TUNER_ROBBERY_LEADER_CASH_REWARD6",
				"TUNER_ROBBERY_LEADER_CASH_REWARD7",
			},
		},
		finish = {
			old = {
				step1_offset = 56223 + 1,
				step2_offset = 56223 + 1776 + 1,
				step1_value = 51338977,
				step2_value = 101,
			},
			current = {
				step1_offset = 56223 + 1589,
				step2_offset = 56223 + 1776 + 1,
				step3_offset = 56223 + 1,
			},
		},
	},
	doomsday = {
		blips = {
			facility = 590,
			heist_board = 428,
		},
		scripts = {
			interior = "am_mp_defunct_base",
			planning = "gb_gang_ops_planning",
			mission_controller = "fm_mission_controller",
		},
		planning = {
			reload_offset = 211,
		},
		screen = {
			heading = 325.726,
		},
		stats = {
			flow_mission_prog = "GANGOPS_FLOW_MISSION_PROG",
			heist_status = "GANGOPS_HEIST_STATUS",
			flow_notifications = "GANGOPS_FLOW_NOTIFICATIONS",
		},
		globals = {
			difficulty = 4718592 + 3538,
			ready_players = { 1883089, 1883405, 1883721 },
			cuts = { 1969406, 1969407, 1969408, 1969409 },
		},
		payouts = {
			[503] = { 975000, 1218750 },
			[240] = { 1425000, 1771250 },
			[16368] = { 1800000, 2250000 },
		},
		hacks = {
			data = {
				offset = 1541,
			},
			doomsday = {
				offset = 1298 + 135,
			},
		},
		finish = {
			controllers = {
				["fm_mission_controller"] = {
					status_offset = 20395 + 1062,
					cash_take_offset = 20395 + 1232 + 1,
					flags_offset = 20395 + 1,
				},
				["fm_mission_controller_2020"] = {
					status_offset = 56223 + 1589,
					cash_take_offset = 56223 + 1776 + 1,
					flags_offset = 56223 + 1,
				},
			},
		},
	},
	knoway = {
		hacks = {
			circuit = {
				script = "circuitblockhack",
				result_offset = 62,
			},
			word = {
				script = "word_hack",
				result_offset = 106,
			},
		},
		finish = {
			script = "fm_mission_controller_2020",
			base = 48794,
			cash_take_offset_1 = 1777,
			cash_take_offset_2 = 1778,
			status_offset = 1062,
			flags_offset = 0,
			win_flags_offset = 1,
		},
	},
	cluckin = {
		stats = {
			instance_progress = "SALV23_INST_PROG",
			completion_bitsets = {
				"SALV23_GEN_BS",
				"SALV23_SCOPE_BS",
				"SALV23_FM_PROG",
			},
			cooldown = "SALV23_CFR_COOLDOWN",
		},
		finish = {
			script = "fm_mission_controller_2020",
			base = 56223,
			cash_take_offset = 55173,
			mission_cash_take_offset = 1777,
			status_offset = 1062,
			flags_offset = 48794,
			win_flags_offset = 1,
		},
	},
}
