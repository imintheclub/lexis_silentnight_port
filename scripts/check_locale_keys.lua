local locale_init_path = "src/ShillenSilent_core/i18n/init.lua"

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

local function sorted_keys(locale)
	local keys = {}

	for key in pairs(locale) do
		keys[#keys + 1] = key
	end

	table.sort(keys)
	return keys
end

local function key_set(keys)
	local set = {}

	for i = 1, #keys do
		set[keys[i]] = true
	end

	return set
end

local function collect_missing(expected_keys, actual_set)
	local missing = {}

	for i = 1, #expected_keys do
		local key = expected_keys[i]
		if not actual_set[key] then
			missing[#missing + 1] = key
		end
	end

	return missing
end

local function collect_extra(actual_keys, expected_set)
	local extra = {}

	for i = 1, #actual_keys do
		local key = actual_keys[i]
		if not expected_set[key] then
			extra[#extra + 1] = key
		end
	end

	return extra
end

local function parse_registered_locales()
	local contents = read_file(locale_init_path)
	local locales = {}

	for value, module in
		contents:gmatch('{%s*label_key%s*=%s*"[^"]+"%s*,%s*value%s*=%s*"([^"]+)"%s*,%s*module%s*=%s*"([^"]+)"%s*}')
	do
		locales[#locales + 1] = {
			value = value,
			module = module,
		}
	end

	if #locales == 0 then
		error("no registered locales found in " .. locale_init_path)
	end

	return locales
end

local registered_locales = parse_registered_locales()
local english = require("ShillenSilent_core.i18n.locales.en")
local english_keys = sorted_keys(english)
local english_set = key_set(english_keys)
local failed = false

for i = 1, #registered_locales do
	local entry = registered_locales[i]

	if entry.value ~= "en" then
		local locale = require(entry.module)
		local locale_keys = sorted_keys(locale)
		local locale_set = key_set(locale_keys)
		local missing = collect_missing(english_keys, locale_set)
		local extra = collect_extra(locale_keys, english_set)

		if #missing > 0 or #extra > 0 then
			failed = true
			io.stderr:write(("%s locale keys differ from English\n"):format(entry.value))

			for j = 1, #missing do
				io.stderr:write(("  missing: %s\n"):format(missing[j]))
			end

			for j = 1, #extra do
				io.stderr:write(("  extra: %s\n"):format(extra[j]))
			end
		end
	end
end

if failed then
	os.exit(1)
end

print(("All registered locales match English (%d keys)."):format(#english_keys))
