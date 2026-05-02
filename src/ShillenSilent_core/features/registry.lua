local i18n = require("ShillenSilent_core.i18n")
local notify_core = require("ShillenSilent_core.core.notify")

local manifest_modules = {
	"ShillenSilent_core.features.heists.info.manifest",
	"ShillenSilent_core.features.general.faq.manifest",
	"ShillenSilent_core.features.heists.cayo.manifest",
	"ShillenSilent_core.features.heists.casino.manifest",
	"ShillenSilent_core.features.heists.doomsday.manifest",
	"ShillenSilent_core.features.heists.apartment.manifest",
	"ShillenSilent_core.features.heists.agency.manifest",
	"ShillenSilent_core.features.heists.autoshop.manifest",
	"ShillenSilent_core.features.heists.salvageyard.manifest",
	"ShillenSilent_core.features.heists.cluckin.manifest",
	"ShillenSilent_core.features.heists.knoway.manifest",
	"ShillenSilent_core.features.businesses.arcade.manifest",
	"ShillenSilent_core.features.businesses.garment.manifest",
	"ShillenSilent_core.features.businesses.bailoffice.manifest",
	"ShillenSilent_core.features.businesses.moneyfronts.manifest",
	"ShillenSilent_core.features.businesses.acidlab.manifest",
	"ShillenSilent_core.features.businesses.bunker.manifest",
	"ShillenSilent_core.features.businesses.hangar.manifest",
	"ShillenSilent_core.features.businesses.speccargo.manifest",
	"ShillenSilent_core.features.businesses.nightclub.manifest",
	"ShillenSilent_core.features.businesses.mc.manifest",
}

local registry = {
	loaded = nil,
	by_id = {},
}

local function load_manifests()
	if registry.loaded then
		return registry.loaded
	end
	local out = {}
	for i = 1, #manifest_modules do
		local ok, manifest = pcall(require, manifest_modules[i])
		if ok and type(manifest) == "table" then
			out[#out + 1] = manifest
			registry.by_id[manifest.id] = manifest
		else
			notify_core.push("app.name", "notify.manifest_failed", 3000, { module = tostring(manifest_modules[i]) })
		end
	end
	table.sort(out, function(a, b)
		if (a.kind or "") == (b.kind or "") then
			return (a.order or 0) < (b.order or 0)
		end
		if a.id == "info" then
			return true
		end
		if b.id == "info" then
			return false
		end
		if a.kind == "general" then
			return true
		end
		if b.kind == "general" then
			return false
		end
		if a.kind == "heist" then
			return true
		end
		if b.kind == "heist" then
			return false
		end
		return (a.order or 0) < (b.order or 0)
	end)
	registry.loaded = out
	return out
end

function registry.list(kind)
	local loaded = load_manifests()
	if kind == nil then
		return loaded
	end
	local out = {}
	for i = 1, #loaded do
		if loaded[i].kind == kind then
			out[#out + 1] = loaded[i]
		end
	end
	return out
end

function registry.get(feature_id)
	load_manifests()
	return registry.by_id[feature_id]
end

function registry.label(manifest)
	if not manifest then
		return ""
	end
	return i18n.t(manifest.label_key or manifest.id)
end

function registry.load_module(manifest, slot)
	if not manifest or not manifest.modules then
		return nil
	end
	local module_name = manifest.modules[slot]
	if not module_name then
		return nil
	end
	local ok, module = pcall(require, module_name)
	if ok then
		return module
	end
	notify_core.push("app.name", "notify.module_failed", 3000, { module = tostring(module_name) })
	return nil
end

return registry
