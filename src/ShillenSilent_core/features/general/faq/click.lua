local ui = require("ShillenSilent_core.ui.click.widgets")
local i18n = require("ShillenSilent_core.i18n")
local data = require("ShillenSilent_core.features.general.faq.data")

local click = {}
local t = i18n.t

function click.refresh()
	return true
end

function click.register(heist_tab)
	if type(heist_tab) ~= "table" then
		return nil
	end

	for i = 1, #data.categories do
		local category = data.categories[i]
		local group = ui.group(heist_tab, t(category.label_key), nil, nil, nil, 0, data.feature_id)
		for j = 1, #category.items do
			local item = category.items[j]
			if item.text_key then
				ui.info(group, t(item.text_key))
			else
				ui.info(
					group,
					t("faq.format.qa", {
						question = t(item.question_key),
						answer = t(item.answer_key),
					})
				)
			end
			if j < #category.items then
				ui.spacer(group, 4)
			end
		end
	end

	return heist_tab
end

return click
