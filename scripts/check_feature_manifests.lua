local registry_path = "src/ShillenSilent_core/features/registry.lua"

package.path = table.concat({
	"src/?.lua",
	"src/?/init.lua",
	package.path,
}, ";")

local function read_file(path)
	local file, err = io.open(path, "r")
	if not file then
		error(("failed to read %s: %s"):format(path, tostring(err)))
	end

	local contents = file:read("*a")
	file:close()
	return contents
end

local function add_error(errors, message)
	errors[#errors + 1] = message
end

local function escape_pattern(value)
	return tostring(value):gsub("([^%w])", "%%%1")
end

local function module_path(module_name)
	return package.searchpath(module_name, package.path)
end

local function module_to_feature_id(module_name)
	return module_name:match("%.([^%.]+)%.manifest$")
end

local function module_to_kind(module_name)
	if module_name:find(".heists.", 1, true) then
		return "heist"
	end
	if module_name:find(".businesses.", 1, true) then
		return "business"
	end
	if module_name:find(".general.", 1, true) then
		return "general"
	end
	return nil
end

local function file_to_module(path)
	local normalized = path:gsub("\\", "/")
	normalized = normalized:gsub("^%./", "")
	normalized = normalized:gsub("^src/", "")
	normalized = normalized:gsub("%.lua$", "")
	return normalized:gsub("/", ".")
end

local function collect_registry_modules()
	local contents = read_file(registry_path)
	local modules = {}

	for module_name in contents:gmatch('"([^"]+)"') do
		if module_name:match("^ShillenSilent_core%.features%..+%.manifest$") then
			modules[#modules + 1] = module_name
		end
	end

	table.sort(modules)
	return modules
end

local function collect_manifest_files()
	local files = {}
	local handle = io.popen("git ls-files --cached --others --exclude-standard src/ShillenSilent_core/features")

	if not handle then
		error("failed to list feature files with git")
	end

	for path in handle:lines() do
		if path:gsub("\\", "/"):match("/manifest%.lua$") then
			files[#files + 1] = path
		end
	end

	handle:close()
	table.sort(files)
	return files
end

local function collect_module_set(modules)
	local set = {}

	for i = 1, #modules do
		set[modules[i]] = true
	end

	return set
end

local function has_function(module_name, fn_name)
	local path = module_path(module_name)
	if not path then
		return false
	end

	local contents = read_file(path)
	local escaped_fn = escape_pattern(fn_name)

	return contents:find("function%s+[%w_]+%." .. escaped_fn .. "%s*%(") ~= nil
		or contents:find("[%w_]+%." .. escaped_fn .. "%s*=%s*function%s*%(") ~= nil
		or contents:find('%["' .. escaped_fn .. '"%]%s*=%s*function%s*%(') ~= nil
end

local function validate_string(errors, owner, field, value)
	if type(value) ~= "string" or value == "" then
		add_error(errors, ("%s.%s must be a non-empty string"):format(owner, field))
	end
end

local function validate_modules(errors, manifest, manifest_module)
	local expected_prefix = manifest_module:gsub("%.manifest$", "")
	local modules = manifest.modules
	local allowed_slots = {
		actions = true,
		click = true,
		controller = true,
		data = true,
		presets = true,
		state = true,
	}

	if type(modules) ~= "table" then
		add_error(errors, ("%s.modules must be a table"):format(manifest.id or manifest_module))
		return
	end

	if type(modules.data) ~= "string" or modules.data == "" then
		add_error(errors, ("%s.modules.data must be a non-empty module path"):format(manifest.id))
	end

	if manifest.show_in_click ~= false and (type(modules.click) ~= "string" or modules.click == "") then
		add_error(
			errors,
			("%s.modules.click must be a non-empty module path when shown in click UI"):format(manifest.id)
		)
	end

	if manifest.kind ~= "general" and (type(modules.controller) ~= "string" or modules.controller == "") then
		add_error(errors, ("%s.modules.controller must be a non-empty module path"):format(manifest.id))
	end

	for slot, module_name in pairs(modules) do
		if not allowed_slots[slot] then
			add_error(errors, ("%s.modules.%s is not a recognized module slot"):format(manifest.id, tostring(slot)))
		elseif type(module_name) ~= "string" or module_name == "" then
			add_error(errors, ("%s.modules.%s must be a non-empty module path"):format(manifest.id, slot))
		else
			local expected_module = expected_prefix .. "." .. slot
			if module_name ~= expected_module then
				add_error(
					errors,
					("%s.modules.%s should be %s, got %s"):format(manifest.id, slot, expected_module, module_name)
				)
			end
			if not module_path(module_name) then
				add_error(errors, ("%s.modules.%s points to missing module %s"):format(manifest.id, slot, module_name))
			end
		end
	end
end

local function validate_jobs(errors, manifest)
	if type(manifest.jobs) ~= "table" then
		add_error(errors, ("%s.jobs must be a table"):format(manifest.id or "<unknown>"))
		return
	end

	local seen_job_ids = {}

	for i = 1, #manifest.jobs do
		local job = manifest.jobs[i]
		local owner = ("%s.jobs[%d]"):format(manifest.id, i)

		if type(job) ~= "table" then
			add_error(errors, owner .. " must be a table")
		else
			validate_string(errors, owner, "id", job.id)
			validate_string(errors, owner, "module", job.module)
			validate_string(errors, owner, "fn", job.fn)

			if type(job.id) == "string" then
				if seen_job_ids[job.id] then
					add_error(errors, ("%s duplicates job id %s"):format(owner, job.id))
				end
				seen_job_ids[job.id] = true

				if type(manifest.id) == "string" and not job.id:match("^" .. escape_pattern(manifest.id) .. "%.") then
					add_error(errors, ("%s.id should start with %s."):format(owner, manifest.id))
				end
			end

			if type(job.interval_ms) ~= "number" or job.interval_ms <= 0 then
				add_error(errors, owner .. ".interval_ms must be a positive number")
			end

			if type(job.module) == "string" then
				if not module_path(job.module) then
					add_error(errors, ("%s.module points to missing module %s"):format(owner, job.module))
				elseif type(job.fn) == "string" and not has_function(job.module, job.fn) then
					add_error(errors, ("%s.fn %s was not found in %s"):format(owner, job.fn, job.module))
				end
			end
		end
	end
end

local function validate_manifest(errors, manifest_module, english)
	local ok, manifest = pcall(require, manifest_module)

	if not ok then
		add_error(errors, ("%s failed to load: %s"):format(manifest_module, tostring(manifest)))
		return
	end

	if type(manifest) ~= "table" then
		add_error(errors, manifest_module .. " must return a table")
		return
	end

	local expected_id = module_to_feature_id(manifest_module)
	local expected_kind = module_to_kind(manifest_module)
	local owner = manifest.id or manifest_module

	validate_string(errors, owner, "id", manifest.id)
	validate_string(errors, owner, "kind", manifest.kind)
	validate_string(errors, owner, "label_key", manifest.label_key)

	if manifest.id ~= expected_id then
		add_error(errors, ("%s.id should match its directory name %s"):format(owner, tostring(expected_id)))
	end

	if manifest.kind ~= expected_kind then
		add_error(
			errors,
			("%s.kind should be %s based on its feature directory"):format(owner, tostring(expected_kind))
		)
	end

	if type(manifest.order) ~= "number" then
		add_error(errors, ("%s.order must be a number"):format(owner))
	end

	if type(manifest.support) ~= "table" then
		add_error(errors, ("%s.support must be a table"):format(owner))
	elseif type(manifest.support.current) ~= "boolean" or type(manifest.support.legacy) ~= "boolean" then
		add_error(errors, ("%s.support.current and support.legacy must be booleans"):format(owner))
	end

	if type(manifest.label_key) == "string" and not english[manifest.label_key] then
		add_error(errors, ("%s.label_key is missing from English locale: %s"):format(owner, manifest.label_key))
	end

	if type(manifest.display_group_label_key) == "string" and not english[manifest.display_group_label_key] then
		add_error(
			errors,
			("%s.display_group_label_key is missing from English locale: %s"):format(
				owner,
				manifest.display_group_label_key
			)
		)
	end

	if manifest.display_group_order ~= nil and type(manifest.display_group_order) ~= "number" then
		add_error(errors, ("%s.display_group_order must be a number when present"):format(owner))
	end

	if manifest.display_group ~= nil then
		validate_string(errors, owner, "display_group", manifest.display_group)
	end

	if manifest.show_in_click ~= nil and type(manifest.show_in_click) ~= "boolean" then
		add_error(errors, ("%s.show_in_click must be a boolean when present"):format(owner))
	end

	validate_modules(errors, manifest, manifest_module)
	validate_jobs(errors, manifest)
end

local errors = {}
local registry_modules = collect_registry_modules()
local registry_set = collect_module_set(registry_modules)
local manifest_files = collect_manifest_files()
local manifest_file_modules = {}
local file_module_set = {}
local english = require("ShillenSilent_core.i18n.locales.en")

for i = 1, #manifest_files do
	local module_name = file_to_module(manifest_files[i])
	manifest_file_modules[#manifest_file_modules + 1] = module_name
	file_module_set[module_name] = true
end

for i = 1, #registry_modules do
	local module_name = registry_modules[i]
	if not file_module_set[module_name] then
		add_error(errors, "registry points to missing manifest module " .. module_name)
	else
		validate_manifest(errors, module_name, english)
	end
end

for i = 1, #manifest_file_modules do
	local module_name = manifest_file_modules[i]
	if not registry_set[module_name] then
		add_error(errors, "manifest is not registered in features/registry.lua: " .. module_name)
	end
end

if #errors > 0 then
	for i = 1, #errors do
		io.stderr:write(errors[i] .. "\n")
	end
	os.exit(1)
end

print(("All feature manifests are valid (%d registered)."):format(#registry_modules))
