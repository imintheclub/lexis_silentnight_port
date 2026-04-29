local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local data = require("ShillenSilent_core.features.heists.knoway.data")
local actions = require("ShillenSilent_core.features.heists.knoway.actions")

local click = {}

local t = i18n.t

function click.refresh()
	return true
end

local function register(heistTab)
	if type(heistTab) ~= "table" then
		return nil
	end

	local tools_group = ui.group(heistTab, t("knoway.group.tools"), nil, nil, nil, nil, data.feature_id)
	ui.button(tools_group, "knoway_instant_finish", t("knoway.action.instant_finish"), actions.instant_finish)
	ui.button(tools_group, "knoway_skip_cutscene", t("knoway.action.skip_cutscene"), actions.skip_cutscene)

	return heistTab
end

click.register = register

return click
