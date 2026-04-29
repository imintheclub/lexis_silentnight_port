local data = require("ShillenSilent_core.features.businesses.speccargo.data")

local state = {
	config = {
		location_index = 1,
		sale_price_active = false,
		no_xp = false,
		no_crateback = false,
		crate_amount = data.crates.default,
		supplier_active = false,
		cooldowns_active = false,
	},
	fill = {
		active = false,
	},
	protections = {
		raids_default = nil,
		raids_active = false,
		reminders_default = nil,
		reminders_active = false,
	},
}

function state.set_location_index(value, count)
	state.config.location_index = data.clamp_location_index(value, count)
end

function state.set_sale_price_active(enabled)
	state.config.sale_price_active = enabled == true
end

function state.set_no_xp(enabled)
	state.config.no_xp = enabled == true
end

function state.set_no_crateback(enabled)
	state.config.no_crateback = enabled == true
end

function state.set_crate_amount(value)
	state.config.crate_amount = data.clamp_crate_amount(value)
end

function state.set_supplier_active(enabled)
	state.config.supplier_active = enabled == true
end

function state.set_cooldowns_active(enabled)
	state.config.cooldowns_active = enabled == true
end

function state.set_fill_active(enabled)
	state.fill.active = enabled == true
end

function state.set_raids_active(enabled)
	state.protections.raids_active = enabled == true
end

function state.set_reminders_active(enabled)
	state.protections.reminders_active = enabled == true
end

return state
