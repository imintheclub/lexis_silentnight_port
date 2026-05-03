-- Manual card placement for each heist subtab, at each column count.
--
-- Format:
--   LAYOUTS[<feature_id>].cols_<N> = { col1, col2, ..., colN }
--   each column = { "i18n.key", "i18n.key", ... }      -- top to bottom
--
-- Tabs are keyed by feature id (the same string passed to ui.group's
-- heist_subtab arg in each feature's click.lua), NOT by registry index.
-- Indices shift whenever a manifest is added or reordered; ids are stable.
--
-- The strings inside each column are i18n keys. The renderer compares each
-- registered group's label against i18n.t(key, vars). For parameterized
-- labels (e.g. salvage yard slot 1/2/3) use { "key", vars } instead of a
-- bare string. The shared preset card is registered with the i18n key
-- "preset.group.json" in every feature, so list it as "preset.group.json".
--
-- Editing rules:
--   * To move a card, move its key to a different column or position.
--   * To add a card at column N, append its key to cols_<N> at the spot
--     you want (top of column = first, bottom = last).
--   * Every registered group should appear in every cols_<N> for its tab.
--     Anything missing falls into the renderer's "unmatched" bucket and
--     drops to the bottom of column 1.
--   * Canonical order I'm following: Info -> Launch -> Presets -> Preps
--     -> Cuts/Payout -> Teleport(s) -> Tools -> Popularity -> Danger.

local i18n = require("ShillenSilent_core.i18n")

local M = {}

local LAYOUTS = {
	info = {
		cols_3 = { { "info.group.settings" } },
		cols_2 = { { "info.group.settings" } },
		cols_1 = { { "info.group.settings" } },
	},

	faq = {
		cols_3 = {
			{ "faq.category.project", "faq.category.discord" },
			{ "faq.category.setup" },
			{ "faq.category.safety", "faq.category.payouts" },
		},
		cols_2 = {
			{ "faq.category.project", "faq.category.discord", "faq.category.setup" },
			{ "faq.category.safety", "faq.category.payouts" },
		},
		cols_1 = {
			{
				"faq.category.project",
				"faq.category.discord",
				"faq.category.setup",
				"faq.category.safety",
				"faq.category.payouts",
			},
		},
	},

	cayo = { -- no launch group registered
		cols_3 = {
			{ "cayo.group.info", "preset.group.json" },
			{ "cayo.group.preps", "cayo.group.cuts" },
			{
				"cayo.group.teleport_outside",
				"cayo.group.teleport_in_residence",
				"cayo.group.tools",
				"cayo.group.danger",
			},
		},
		cols_2 = {
			{ "cayo.group.info", "preset.group.json", "cayo.group.preps" },
			{
				"cayo.group.cuts",
				"cayo.group.teleport_outside",
				"cayo.group.teleport_in_residence",
				"cayo.group.tools",
				"cayo.group.danger",
			},
		},
		cols_1 = {
			{
				"cayo.group.info",
				"preset.group.json",
				"cayo.group.preps",
				"cayo.group.cuts",
				"cayo.group.teleport_outside",
				"cayo.group.teleport_in_residence",
				"cayo.group.tools",
				"cayo.group.danger",
			},
		},
	},

	casino = {
		cols_3 = {
			{ "casino.group.info", "casino.group.launch", "preset.group.json" },
			{ "casino.group.preps", "casino.group.cuts" },
			{
				"casino.group.teleport_outside",
				"casino.group.teleport_inside",
				"casino.group.tools",
				"casino.group.danger",
			},
		},
		cols_2 = {
			{
				"casino.group.info",
				"casino.group.launch",
				"preset.group.json",
				"casino.group.preps",
			},
			{
				"casino.group.cuts",
				"casino.group.teleport_outside",
				"casino.group.teleport_inside",
				"casino.group.tools",
				"casino.group.danger",
			},
		},
		cols_1 = {
			{
				"casino.group.info",
				"casino.group.launch",
				"preset.group.json",
				"casino.group.preps",
				"casino.group.cuts",
				"casino.group.teleport_outside",
				"casino.group.teleport_inside",
				"casino.group.tools",
				"casino.group.danger",
			},
		},
	},

	doomsday = { -- no danger group registered
		cols_3 = {
			{ "doomsday.group.info", "doomsday.group.launch", "preset.group.json" },
			{ "doomsday.group.preps", "doomsday.group.cuts" },
			{ "doomsday.group.teleport", "doomsday.group.tools" },
		},
		cols_2 = {
			{ "doomsday.group.info", "doomsday.group.launch", "preset.group.json", "doomsday.group.preps" },
			{ "doomsday.group.cuts", "doomsday.group.teleport", "doomsday.group.tools" },
		},
		cols_1 = {
			{
				"doomsday.group.info",
				"doomsday.group.launch",
				"preset.group.json",
				"doomsday.group.preps",
				"doomsday.group.cuts",
				"doomsday.group.teleport",
				"doomsday.group.tools",
			},
		},
	},

	apartment = {
		cols_3 = {
			{ "apartment.group.info", "apartment.group.launch", "preset.group.json" },
			{ "apartment.group.preps", "apartment.group.cuts", "apartment.group.teleport" },
			{ "apartment.group.tools", "apartment.group.danger" },
		},
		cols_2 = {
			{ "apartment.group.info", "apartment.group.launch", "preset.group.json", "apartment.group.preps" },
			{ "apartment.group.cuts", "apartment.group.teleport", "apartment.group.tools", "apartment.group.danger" },
		},
		cols_1 = {
			{
				"apartment.group.info",
				"apartment.group.launch",
				"preset.group.json",
				"apartment.group.preps",
				"apartment.group.cuts",
				"apartment.group.teleport",
				"apartment.group.tools",
				"apartment.group.danger",
			},
		},
	},

	agency = {
		cols_3 = {
			{ "agency.group.info", "preset.group.json" },
			{ "agency.group.preps", "agency.group.payout", "agency.group.teleport" },
			{ "agency.group.tools", "agency.group.danger" },
		},
		cols_2 = {
			{ "agency.group.info", "preset.group.json", "agency.group.preps" },
			{ "agency.group.payout", "agency.group.teleport", "agency.group.tools", "agency.group.danger" },
		},
		cols_1 = {
			{
				"agency.group.info",
				"preset.group.json",
				"agency.group.preps",
				"agency.group.payout",
				"agency.group.teleport",
				"agency.group.tools",
				"agency.group.danger",
			},
		},
	},

	autoshop = {
		cols_3 = {
			{ "autoshop.group.info", "preset.group.json" },
			{ "autoshop.group.preps", "autoshop.group.payout", "autoshop.group.teleport" },
			{ "autoshop.group.tools", "autoshop.group.danger" },
		},
		cols_2 = {
			{ "autoshop.group.info", "preset.group.json", "autoshop.group.preps" },
			{ "autoshop.group.payout", "autoshop.group.teleport", "autoshop.group.tools", "autoshop.group.danger" },
		},
		cols_1 = {
			{
				"autoshop.group.info",
				"preset.group.json",
				"autoshop.group.preps",
				"autoshop.group.payout",
				"autoshop.group.teleport",
				"autoshop.group.tools",
				"autoshop.group.danger",
			},
		},
	},

	salvageyard = {
		cols_3 = {
			{ "salvageyard.group.info", "preset.group.json" },
			{
				{ "salvageyard.group.slot", { slot = "1" } },
				{ "salvageyard.group.slot", { slot = "2" } },
				{ "salvageyard.group.slot", { slot = "3" } },
				"salvageyard.group.preps",
			},
			{
				"salvageyard.group.payout",
				"salvageyard.group.teleport",
				"salvageyard.group.tools",
				"salvageyard.group.popularity",
				"salvageyard.group.danger",
			},
		},
		cols_2 = {
			{
				"salvageyard.group.info",
				"preset.group.json",
				"salvageyard.group.preps",
				{ "salvageyard.group.slot", { slot = "1" } },
				{ "salvageyard.group.slot", { slot = "2" } },
				{ "salvageyard.group.slot", { slot = "3" } },
			},
			{
				"salvageyard.group.payout",
				"salvageyard.group.teleport",
				"salvageyard.group.tools",
				"salvageyard.group.popularity",
				"salvageyard.group.danger",
			},
		},
		cols_1 = {
			{
				"salvageyard.group.info",
				"preset.group.json",
				"salvageyard.group.preps",
				{ "salvageyard.group.slot", { slot = "1" } },
				{ "salvageyard.group.slot", { slot = "2" } },
				{ "salvageyard.group.slot", { slot = "3" } },
				"salvageyard.group.payout",
				"salvageyard.group.teleport",
				"salvageyard.group.tools",
				"salvageyard.group.popularity",
				"salvageyard.group.danger",
			},
		},
	},

	misc = { -- arcade, garment, bailoffice, moneyfronts (3 fronts) share this subtab
		cols_3 = {
			{ "feature.arcade.name", "feature.garment.name" },
			{ "feature.bailoffice.name", "moneyfronts.front.car_wash" },
			{ "moneyfronts.front.weed_shop", "moneyfronts.front.heli_tours" },
		},
		cols_2 = {
			{ "feature.arcade.name", "feature.garment.name", "feature.bailoffice.name" },
			{
				"moneyfronts.front.car_wash",
				"moneyfronts.front.weed_shop",
				"moneyfronts.front.heli_tours",
			},
		},
		cols_1 = {
			{
				"feature.arcade.name",
				"feature.garment.name",
				"feature.bailoffice.name",
				"moneyfronts.front.car_wash",
				"moneyfronts.front.weed_shop",
				"moneyfronts.front.heli_tours",
			},
		},
	},

	acidlab = {
		cols_3 = {
			{ "acidlab.group.info" },
			{ "acidlab.group.production" },
			{ "acidlab.group.teleport" },
		},
		cols_2 = {
			{ "acidlab.group.info", "acidlab.group.production" },
			{ "acidlab.group.teleport" },
		},
		cols_1 = {
			{ "acidlab.group.info", "acidlab.group.production", "acidlab.group.teleport" },
		},
	},

	bunker = {
		cols_3 = {
			{ "bunker.group.info" },
			{ "bunker.group.production", "bunker.group.sale" },
			{ "bunker.group.protections", "bunker.group.teleport", "bunker.group.tools" },
		},
		cols_2 = {
			{ "bunker.group.info", "bunker.group.production" },
			{
				"bunker.group.sale",
				"bunker.group.protections",
				"bunker.group.teleport",
				"bunker.group.tools",
			},
		},
		cols_1 = {
			{
				"bunker.group.info",
				"bunker.group.production",
				"bunker.group.sale",
				"bunker.group.protections",
				"bunker.group.teleport",
				"bunker.group.tools",
			},
		},
	},

	hangar = {
		cols_3 = {
			{ "hangar.group.info" },
			{ "hangar.group.stock", "hangar.group.sale" },
			{ "hangar.group.teleport", "hangar.group.danger" },
		},
		cols_2 = {
			{ "hangar.group.info", "hangar.group.stock" },
			{ "hangar.group.sale", "hangar.group.teleport", "hangar.group.danger" },
		},
		cols_1 = {
			{
				"hangar.group.info",
				"hangar.group.stock",
				"hangar.group.sale",
				"hangar.group.teleport",
				"hangar.group.danger",
			},
		},
	},

	speccargo = {
		cols_3 = {
			{ "speccargo.group.info" },
			{ "speccargo.group.source_fill", "speccargo.group.sell" },
			{ "speccargo.group.protections", "speccargo.group.teleport", "speccargo.group.danger" },
		},
		cols_2 = {
			{ "speccargo.group.info", "speccargo.group.source_fill" },
			{
				"speccargo.group.sell",
				"speccargo.group.protections",
				"speccargo.group.teleport",
				"speccargo.group.danger",
			},
		},
		cols_1 = {
			{
				"speccargo.group.info",
				"speccargo.group.source_fill",
				"speccargo.group.sell",
				"speccargo.group.protections",
				"speccargo.group.teleport",
				"speccargo.group.danger",
			},
		},
	},

	nightclub = {
		cols_3 = {
			{ "nightclub.group.info" },
			{ "nightclub.group.production", "nightclub.group.safe", "nightclub.group.popularity" },
			{
				"nightclub.group.protections",
				"nightclub.group.teleport",
				"nightclub.group.tools",
				"nightclub.group.danger",
			},
		},
		cols_2 = {
			{ "nightclub.group.info", "nightclub.group.production" },
			{
				"nightclub.group.safe",
				"nightclub.group.popularity",
				"nightclub.group.protections",
				"nightclub.group.teleport",
				"nightclub.group.tools",
				"nightclub.group.danger",
			},
		},
		cols_1 = {
			{
				"nightclub.group.info",
				"nightclub.group.production",
				"nightclub.group.safe",
				"nightclub.group.popularity",
				"nightclub.group.protections",
				"nightclub.group.teleport",
				"nightclub.group.tools",
				"nightclub.group.danger",
			},
		},
	},

	mc = {
		cols_3 = {
			{ "mc.group.info", "mc.group.all_businesses" },
			{ "mc.business.meth", "mc.business.weed", "mc.business.cocaine" },
			{ "mc.business.counterfeit", "mc.business.forgery" },
		},
		cols_2 = {
			{ "mc.group.info", "mc.group.all_businesses", "mc.business.meth", "mc.business.weed" },
			{ "mc.business.cocaine", "mc.business.counterfeit", "mc.business.forgery" },
		},
		cols_1 = {
			{
				"mc.group.info",
				"mc.group.all_businesses",
				"mc.business.meth",
				"mc.business.weed",
				"mc.business.cocaine",
				"mc.business.counterfeit",
				"mc.business.forgery",
			},
		},
	},

	cluckin = { -- only info / tools / danger registered
		cols_3 = {
			{ "cluckin.group.info" },
			{ "cluckin.group.tools" },
			{ "cluckin.group.danger" },
		},
		cols_2 = {
			{ "cluckin.group.info", "cluckin.group.tools" },
			{ "cluckin.group.danger" },
		},
		cols_1 = {
			{ "cluckin.group.info", "cluckin.group.tools", "cluckin.group.danger" },
		},
	},

	knoway = {
		cols_3 = { { "knoway.group.tools" } },
		cols_2 = { { "knoway.group.tools" } },
		cols_1 = { { "knoway.group.tools" } },
	},
}

local function item_label(item)
	if type(item) == "table" then
		return i18n.t(item[1], item[2])
	end
	return i18n.t(item)
end

-- Resolve { col, order } for a given group within a heist subtab at the
-- requested column count. `subtab_key` is the feature id string (e.g. "cayo").
-- Returns nil when the subtab is unmapped or the group label doesn't match
-- any authored entry; the renderer treats that as "drop to bottom of col 1"
-- so unmapped groups stay deterministic.
function M.lookup(subtab_key, group, column_count)
	local tab = LAYOUTS[subtab_key]
	if not tab or not group then
		return nil
	end

	local cols = tab["cols_" .. column_count]
	if not cols then
		-- Fall back to the next-smaller authored layout, then up. Only
		-- triggers if a tab is partially authored, which shouldn't happen.
		for cc = column_count - 1, 1, -1 do
			cols = tab["cols_" .. cc]
			if cols then
				break
			end
		end
		if not cols then
			for cc = column_count + 1, 3 do
				cols = tab["cols_" .. cc]
				if cols then
					break
				end
			end
		end
		if not cols then
			return nil
		end
	end

	local label = group.label
	for col_idx = 1, #cols do
		local column = cols[col_idx]
		for order_idx = 1, #column do
			if label == item_label(column[order_idx]) then
				return { col = col_idx, order = order_idx }
			end
		end
	end
	return nil
end

return M
