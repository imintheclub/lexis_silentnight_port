local model = require("ShillenSilent_core.ui.click.model")
local frame = require("ShillenSilent_core.ui.click.frame")

model.ensure_assets = frame.ensure_assets
model.set_heist_subtabs = frame.set_heist_subtabs
model.set_heist_subtab_loader = frame.set_heist_subtab_loader
model.render = frame.render

return model
