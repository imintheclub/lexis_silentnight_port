local paths = require("ShillenSilent_core.core.paths")
local config = require("ShillenSilent_core.ui.click.config")
local state = require("ShillenSilent_core.ui.click.state")

local assets = {}

function assets.ensure_assets()
	if state.font_load_attempted then
		return
	end
	state.font_load_attempted = true
	paths.ensure()

	local font_candidates = {}
	if config.font_path and config.font_path ~= "" then
		font_candidates[#font_candidates + 1] = config.font_path
	end
	if type(config.font_fallback_paths) == "table" then
		for i = 1, #config.font_fallback_paths do
			local path = config.font_fallback_paths[i]
			if path and path ~= "" then
				font_candidates[#font_candidates + 1] = path
			end
		end
	end

	for i = 1, #font_candidates do
		local status, font = pcall(gui.load_font, font_candidates[i], 32.0)
		if status and font then
			state.fonts.regular = font
			break
		end
	end
end

return assets
