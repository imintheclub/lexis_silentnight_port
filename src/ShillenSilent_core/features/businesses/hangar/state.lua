local data = require("ShillenSilent_core.features.businesses.hangar.data")

local state = {
	config = {
		location_index = 1,
		sale_price_active = false,
		no_xp = false,
		supplier_active = false,
		pocket_active = false,
		pocket_stop_at = data.supplier.default_stop_at,
		pocket_delay = data.supplier.default_delay,
		cooldowns_active = false,
	},
	fill = {
		active = false,
	},
}

function state.set_location_index(value)
	state.config.location_index = data.clamp_location_index(value)
end

function state.set_sale_price_active(enabled)
	state.config.sale_price_active = enabled == true
end

function state.set_no_xp(enabled)
	state.config.no_xp = enabled == true
end

function state.set_supplier_active(enabled)
	state.config.supplier_active = enabled == true
end

function state.set_pocket_active(enabled)
	state.config.pocket_active = enabled == true
end

function state.set_pocket_stop_at(value)
	state.config.pocket_stop_at = data.clamp_stop_at(value)
end

function state.set_pocket_delay(value)
	state.config.pocket_delay = data.clamp_delay(value)
end

function state.set_cooldowns_active(enabled)
	state.config.cooldowns_active = enabled == true
end

function state.set_fill_active(enabled)
	state.fill.active = enabled == true
end

return state
