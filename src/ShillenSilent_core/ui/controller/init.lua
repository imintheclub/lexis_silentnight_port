local registry = require("ShillenSilent_core.features.registry")
local runtime_services = require("ShillenSilent_core.runtime.services")
local i18n = require("ShillenSilent_core.i18n")
local notify_core = require("ShillenSilent_core.core.notify")

local controller = {
	started = false,
}

local function register_menu_group(register_fn, root)
	local ok, err = pcall(register_fn, root)
	if not ok then
		notify_core.push("app.name", "notify.menu_register_failed", 3500, { error = tostring(err) })
	end
end

local function business_display_order(manifest)
	return manifest.display_group_order or manifest.order or 0
end

local function register_businesses(root)
	local businesses = registry.list("business")
	if #businesses <= 0 then
		return false
	end

	local biz_root = root:submenu(i18n.t("menu.business_manager"))
	biz_root:breaker(i18n.t("menu.business_manager"))

	local entries = {}
	local grouped = {}
	for i = 1, #businesses do
		local manifest = businesses[i]
		local group_id = manifest.display_group
		if group_id then
			if not grouped[group_id] then
				grouped[group_id] = {
					id = group_id,
					label_key = manifest.display_group_label_key,
					order = business_display_order(manifest),
					manifests = {},
				}
				entries[#entries + 1] = grouped[group_id]
			end
			grouped[group_id].manifests[#grouped[group_id].manifests + 1] = manifest
		else
			entries[#entries + 1] = {
				order = business_display_order(manifest),
				manifest = manifest,
			}
		end
	end

	table.sort(entries, function(a, b)
		return (a.order or 0) < (b.order or 0)
	end)

	for i = 1, #entries do
		local entry = entries[i]
		if entry.manifest then
			local controller_module = registry.load_module(entry.manifest, "controller")
			if controller_module and type(controller_module.register) == "function" then
				register_menu_group(controller_module.register, biz_root)
			end
		else
			local label = i18n.t(entry.label_key or entry.id)
			local group_root = biz_root:submenu(label)
			group_root:breaker(label)
			for j = 1, #entry.manifests do
				local controller_module = registry.load_module(entry.manifests[j], "controller")
				if controller_module and type(controller_module.register) == "function" then
					register_menu_group(controller_module.register, group_root)
				end
			end
		end
	end

	return true
end

function controller.register_all(root)
	local heists = registry.list("heist")
	for i = 1, #heists do
		local manifest = heists[i]
		local controller_module = registry.load_module(manifest, "controller")
		if controller_module and type(controller_module.register) == "function" then
			register_menu_group(controller_module.register, root)
		end
	end

	register_businesses(root)
	return true
end

function controller.start()
	if controller.started then
		return false
	end

	_G.ShillenSilent_ForceStop = true

	local root = menu.root()
	if not root then
		notify_core.push("app.name", "notify.controller_root_missing", 2500)
		return false
	end

	root:breaker(i18n.t("app.version"))
	controller.register_all(root)

	pcall(runtime_services.start)
	controller.started = true
	notify_core.push("app.name", "notify.controller_loaded", 2500)
	return true
end

return controller
